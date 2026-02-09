//! RP2350 ADC + USB Serial Application
//!
//! Reads 4 ADC channels on the Pimoroni Tiny 2350 (RP2350A0A2):
//!   - ADC0 (GPIO26): Current measurement via CT220BMC-HS5 hall sensor
//!   - ADC1 (GPIO27): Current measurement via CT220BMC-HS5 hall sensor
//!   - ADC2 (GPIO28): Current measurement via CT220BMC-HS5 hall sensor
//!   - ADC3 (GPIO29): Voltage from capacitive divider
//!
//! Sends scaled ASCII-formatted readings over USB CDC serial.

#![no_std]
#![no_main]

// Ensure we halt the program on panic
use panic_halt as _;

// Alias for our HAL crate
use rp235x_hal as hal;

// Traits and types we need
use core::fmt::Write;
use embedded_hal::delay::DelayNs;
use heapless::String;

// USB Device support
use usb_device::{class_prelude::*, prelude::*};

// USB Communications Class Device support
use usbd_serial::SerialPort;

/// Tell the Boot ROM about our application
#[link_section = ".start_block"]
#[used]
pub static IMAGE_DEF: hal::block::ImageDef = hal::block::ImageDef::secure_exe();

/// External high-speed crystal on the Tiny 2350 board is 12 MHz.
const XTAL_FREQ_HZ: u32 = 12_000_000u32;

/// ADC reference voltage (3.3V)
const ADC_VREF: f32 = 3.3;

/// ADC resolution (12-bit: 0–4095)
const ADC_MAX: f32 = 4095.0;

/// Interval between ADC readings in milliseconds
const SAMPLE_INTERVAL_MS: u32 = 100;

// ============================================================================
// CT220BMC-HS5 Hall Sensor Scaling
// ============================================================================
//
// The CT220BMC-HS5 is a hall-effect current sensor that outputs a voltage
// proportional to the measured current.
//
// Typical specs (adjust these to match your specific sensor variant):
//   - Supply voltage: 5V (but output is typically 0–3.3V compatible)
//   - Quiescent output (zero current): Vref/2 = 1.65V
//   - Sensitivity: e.g. 26.4 mV/A (adjust for your specific part)
//
// Current = (Vadc - V_quiescent) / Sensitivity
//
// Adjust these constants to match your CT220BMC-HS5 configuration:

/// Quiescent (zero-current) output voltage of the hall sensor [V]
const HALL_SENSOR_V_QUIESCENT: f32 = 1.65;

/// Sensitivity of the hall sensor [V/A] (e.g., 0.0264 V/A = 26.4 mV/A)
const HALL_SENSOR_SENSITIVITY: f32 = 0.0264;

// ============================================================================
// Capacitive Divider Scaling (ADC3)
// ============================================================================
//
// ADC3 reads the voltage from a capacitive divider.
// The actual measured voltage = Vadc * divider_ratio
//
// Adjust this ratio based on your capacitor divider network:
//   ratio = (C_bottom) / (C_top + C_bottom)  — note inverted for cap dividers
//   measured_voltage = Vadc / ratio

/// Capacitive divider ratio (Vadc/Vactual). Adjust for your circuit.
/// e.g. if divider is 1:10, then ratio = 0.1 and Vactual = Vadc / 0.1
const CAP_DIVIDER_RATIO: f32 = 1.0;

/// Convert raw 12-bit ADC value to voltage
fn adc_to_voltage(raw: u16) -> f32 {
    (raw as f32 / ADC_MAX) * ADC_VREF
}

/// Convert ADC voltage to current using hall sensor parameters
fn voltage_to_current(voltage: f32) -> f32 {
    (voltage - HALL_SENSOR_V_QUIESCENT) / HALL_SENSOR_SENSITIVITY
}

/// Convert ADC voltage to actual voltage through capacitive divider
fn voltage_through_cap_divider(voltage: f32) -> f32 {
    voltage / CAP_DIVIDER_RATIO
}

#[hal::entry]
fn main() -> ! {
    // Grab our singleton objects
    let mut pac = hal::pac::Peripherals::take().unwrap();

    // Set up the watchdog driver - needed by the clock setup code
    let mut watchdog = hal::Watchdog::new(pac.WATCHDOG);

    // Configure the clocks — default is 125 MHz system clock
    let clocks = hal::clocks::init_clocks_and_plls(
        XTAL_FREQ_HZ,
        pac.XOSC,
        pac.CLOCKS,
        pac.PLL_SYS,
        pac.PLL_USB,
        &mut pac.RESETS,
        &mut watchdog,
    )
    .unwrap();

    // A timer for delays
    let mut timer = hal::Timer::new_timer0(pac.TIMER0, &mut pac.RESETS, &clocks);

    // The single-cycle I/O block controls our GPIO pins
    let sio = hal::Sio::new(pac.SIO);

    // Set the pins to their default state
    let pins = hal::gpio::Pins::new(
        pac.IO_BANK0,
        pac.PADS_BANK0,
        sio.gpio_bank0,
        &mut pac.RESETS,
    );

    // ========================================================================
    // ADC Setup
    // ========================================================================
    let mut adc = hal::Adc::new(pac.ADC, &mut pac.RESETS);

    // Configure ADC pins (GPIO26–GPIO29 → ADC0–ADC3)
    let mut adc_pin_0 = hal::adc::AdcPin::new(pins.gpio26.into_floating_input()).unwrap();
    let mut adc_pin_1 = hal::adc::AdcPin::new(pins.gpio27.into_floating_input()).unwrap();
    let mut adc_pin_2 = hal::adc::AdcPin::new(pins.gpio28.into_floating_input()).unwrap();
    let mut adc_pin_3 = hal::adc::AdcPin::new(pins.gpio29.into_floating_input()).unwrap();

    // ========================================================================
    // USB Serial Setup
    // ========================================================================
    let usb_bus = UsbBusAllocator::new(hal::usb::UsbBus::new(
        pac.USB,
        pac.USB_DPRAM,
        clocks.usb_clock,
        true,
        &mut pac.RESETS,
    ));

    let mut serial = SerialPort::new(&usb_bus);

    let mut usb_dev = UsbDeviceBuilder::new(&usb_bus, UsbVidPid(0x16c0, 0x27dd))
        .strings(&[StringDescriptors::default()
            .manufacturer("rp_adc_trial_1")
            .product("ADC Monitor")
            .serial_number("001")])
        .unwrap()
        .max_packet_size_0(64)
        .unwrap()
        .device_class(2) // CDC class
        .build();

    // Wait a bit for USB to enumerate
    let mut startup_polls: u32 = 0;

    loop {
        // Poll USB — must be done frequently
        usb_dev.poll(&mut [&mut serial]);

        // Give the host some time to enumerate before we start sending data
        if startup_polls < 1000 {
            startup_polls += 1;
            timer.delay_ms(1);
            continue;
        }

        // ====================================================================
        // Read all 4 ADC channels
        // ====================================================================
        let raw0: u16 = adc.read(&mut adc_pin_0).unwrap_or(0);
        let raw1: u16 = adc.read(&mut adc_pin_1).unwrap_or(0);
        let raw2: u16 = adc.read(&mut adc_pin_2).unwrap_or(0);
        let raw3: u16 = adc.read(&mut adc_pin_3).unwrap_or(0);

        // ====================================================================
        // Convert to voltages
        // ====================================================================
        let v0 = adc_to_voltage(raw0);
        let v1 = adc_to_voltage(raw1);
        let v2 = adc_to_voltage(raw2);
        let v3 = adc_to_voltage(raw3);

        // ====================================================================
        // Scale to physical values
        // ====================================================================
        // ADC0–ADC2: current from hall sensors
        let i0 = voltage_to_current(v0);
        let i1 = voltage_to_current(v1);
        let i2 = voltage_to_current(v2);

        // ADC3: voltage through capacitive divider
        let v3_actual = voltage_through_cap_divider(v3);

        // ====================================================================
        // Format as ASCII and send over USB serial
        // ====================================================================
        // We use integer + fractional formatting since no_std doesn't have
        // float formatting by default. We'll show 3 decimal places.
        let mut text: String<256> = String::new();

        // Format current values (mA for better readability)
        let i0_ma = i0 * 1000.0;
        let i1_ma = i1 * 1000.0;
        let i2_ma = i2 * 1000.0;

        // Format voltage (mV for better readability)
        let v3_mv = v3_actual * 1000.0;

        // Integer and fractional parts (2 decimal places)
        let (i0_int, i0_frac) = split_float(i0_ma);
        let (i1_int, i1_frac) = split_float(i1_ma);
        let (i2_int, i2_frac) = split_float(i2_ma);
        let (v3_int, v3_frac) = split_float(v3_mv);

        let _ = write!(
            &mut text,
            "I0:{}{}.{:02}mA I1:{}{}.{:02}mA I2:{}{}.{:02}mA V3:{}{}.{:02}mV\r\n",
            if i0_ma < 0.0 { "-" } else { "" },
            i0_int,
            i0_frac,
            if i1_ma < 0.0 { "-" } else { "" },
            i1_int,
            i1_frac,
            if i2_ma < 0.0 { "-" } else { "" },
            i2_int,
            i2_frac,
            if v3_mv < 0.0 { "-" } else { "" },
            v3_int,
            v3_frac,
        );

        // Write to USB serial
        let text_bytes = text.as_bytes();
        let mut wr_ptr = text_bytes;
        while !wr_ptr.is_empty() {
            // Keep polling USB while writing
            usb_dev.poll(&mut [&mut serial]);
            match serial.write(wr_ptr) {
                Ok(len) => wr_ptr = &wr_ptr[len..],
                Err(_) => break,
            }
        }

        // Wait before next sample
        // Keep polling USB during the delay (in small increments)
        for _ in 0..(SAMPLE_INTERVAL_MS / 10) {
            timer.delay_ms(10);
            usb_dev.poll(&mut [&mut serial]);
            // Drain any incoming data
            let mut buf = [0u8; 64];
            let _ = serial.read(&mut buf);
        }
    }
}

/// Split a float into integer and fractional parts (2 decimal places).
/// Returns (abs_integer_part, fractional_part_as_u32).
fn split_float(val: f32) -> (i32, u32) {
    let abs_val = if val < 0.0 { -val } else { val };
    let int_part = abs_val as i32;
    let frac_part = ((abs_val - int_part as f32) * 100.0) as u32;
    (int_part, frac_part)
}

/// Program metadata for `picotool info`
#[link_section = ".bi_entries"]
#[used]
pub static PICOTOOL_ENTRIES: [hal::binary_info::EntryAddr; 5] = [
    hal::binary_info::rp_cargo_bin_name!(),
    hal::binary_info::rp_cargo_version!(),
    hal::binary_info::rp_program_description!(c"ADC Monitor - Tiny 2350"),
    hal::binary_info::rp_cargo_homepage_url!(),
    hal::binary_info::rp_program_build_attribute!(),
];

// End of file
