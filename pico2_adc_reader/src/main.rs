#![no_std]
#![no_main]

use cortex_m::delay::Delay;
use cortex_m_rt::entry;
use panic_halt as _;
use rp2040_hal::{
    self as hal,
    clocks::{init_clocks_and_plls, Clock},
    pac,
    sio::Sio,
    usb::UsbBus,
    watchdog::Watchdog,
    Adc,
};
use usb_device::{class_prelude::*, prelude::*};
use usbd_serial::SerialPort;
use heapless::String;
use core::fmt::Write;

#[link_section = ".boot2"]
#[used]
pub static BOOT2: [u8; 256] = rp2040_boot2::BOOT_LOADER_GENERIC_03H;

#[entry]
fn main() -> ! {
    // Grab our singleton objects
    let mut pac = pac::Peripherals::take().unwrap();
    let core = pac::CorePeripherals::take().unwrap();

    // Set up the watchdog driver
    let mut watchdog = Watchdog::new(pac.WATCHDOG);

    // Configure the clocks
    let clocks = init_clocks_and_plls(
        12_000_000u32,
        pac.XOSC,
        pac.CLOCKS,
        pac.PLL_SYS,
        pac.PLL_USB,
        &mut pac.RESETS,
        &mut watchdog,
    )
    .ok()
    .unwrap();

    // Set up the USB driver
    let usb_bus = UsbBusAllocator::new(UsbBus::new(
        pac.USBCTRL_REGS,
        pac.USBCTRL_DPRAM,
        clocks.usb_clock,
        true,
        &mut pac.RESETS,
    ));

    // Set up the USB serial port
    let mut serial = SerialPort::new(&usb_bus);

    // Create a USB device
    let mut usb_dev = UsbDeviceBuilder::new(&usb_bus, UsbVidPid(0x16c0, 0x27dd))
        .manufacturer("Raspberry Pi")
        .product("Pico 2 ADC Reader")
        .serial_number("ADC001")
        .device_class(2) // CDC class
        .build();

    // The single-cycle I/O block controls our GPIO pins
    let sio = Sio::new(pac.SIO);

    // Set the pins to their default state
    let pins = hal::gpio::Pins::new(
        pac.IO_BANK0,
        pac.PADS_BANK0,
        sio.gpio_bank0,
        &mut pac.RESETS,
    );

    // Enable ADC
    let mut adc = Adc::new(pac.ADC, &mut pac.RESETS);

    // Enable the temperature sensor
    let mut temperature_sensor = adc.enable_temp_sensor();

    // Configure ADC pins (GPIO26-GPIO29 are ADC0-ADC3 on Pico)
    let mut adc_pin_0 = pins.gpio26.into_floating_input();
    let mut adc_pin_1 = pins.gpio27.into_floating_input();
    let mut adc_pin_2 = pins.gpio28.into_floating_input();
    let mut adc_pin_3 = pins.gpio29.into_floating_input();

    // Create a delay handle
    let mut delay = Delay::new(core.SYST, clocks.system_clock.freq().to_Hz());

    let mut counter: u32 = 0;

    loop {
        // Poll the USB device
        if usb_dev.poll(&mut [&mut serial]) {
            let mut buf = [0u8; 64];
            match serial.read(&mut buf) {
                Ok(_) | Err(UsbError::WouldBlock) => {}
                Err(_e) => {}
            }
        }

        // Read all 4 ADC channels
        let adc0: u16 = adc.read(&mut adc_pin_0).unwrap();
        let adc1: u16 = adc.read(&mut adc_pin_1).unwrap();
        let adc2: u16 = adc.read(&mut adc_pin_2).unwrap();
        let adc3: u16 = adc.read(&mut adc_pin_3).unwrap();

        // Convert ADC values to voltage (ADC is 12-bit, reference is 3.3V)
        let voltage0 = (adc0 as f32 * 3.3) / 4096.0;
        let voltage1 = (adc1 as f32 * 3.3) / 4096.0;
        let voltage2 = (adc2 as f32 * 3.3) / 4096.0;
        let voltage3 = (adc3 as f32 * 3.3) / 4096.0;

        // Format the data as a string
        let mut text: String<256> = String::new();
        write!(
            &mut text,
            "Sample: {} | ADC0: {} ({:.3}V) | ADC1: {} ({:.3}V) | ADC2: {} ({:.3}V) | ADC3: {} ({:.3}V)\r\n",
            counter, adc0, voltage0, adc1, voltage1, adc2, voltage2, adc3, voltage3
        )
        .ok();

        // Send the data over USB serial
        let _ = serial.write(text.as_bytes());

        counter = counter.wrapping_add(1);

        // Wait a bit before reading again (100ms)
        delay.delay_ms(100);
    }
}
