# Project Infos


## Hardware

* Eval board Tiny 2350 from Pimoroni with a RP2350A0A2 chip on it.
  * https://shop.pimoroni.com/products/tiny-2350?variant=42092638699603
* ADC0, ADC1, ADC2 are for current measurment. Reading the voltage output from a CT220BMC-HS5 hall sensor.
* ADC3 read the voltage from a capacitive divider.
* communication to the PC is done via the USB_DP and USB_DM pins.


## Software

* Program should be written in rust
* us the cargo package rp235x-hal
* all ADC reading should be send via USB in ASCII and scaled values.


---

# rp235x-hal Research Notes

## 1. Crate Overview

- **Crate name:** `rp235x-hal`
- **Latest version:** `0.4.0` (on crates.io)
- **Repository:** https://github.com/rp-rs/rp-hal
- **Docs:** https://docs.rs/rp235x-hal
- **License:** MIT OR Apache-2.0
- **Supported chips:** RP2350A, RP2350B, RP2354A, RP2354B
- **Dual architecture:** ARM Cortex-M33 + RISC-V Hazard3

## 2. Target Triples

| Mode     | Target Triple                      | Notes                        |
|----------|------------------------------------|------------------------------|
| ARM      | `thumbv8m.main-none-eabihf`       | Default, hard-float FPU      |
| ARM (sf) | `thumbv8m.main-none-eabi`         | Soft-float (rarely used)     |
| RISC-V   | `riscv32imac-unknown-none-elf`    | No FPU on Hazard3            |

Add the target:
```sh
rustup target add thumbv8m.main-none-eabihf
```

## 3. Boot Mechanism (NOT boot2!)

RP2350 does **NOT** use boot2 like the RP2040. Instead it uses an `ImageDef` block placed
in a `.start_block` linker section:

```rust
/// Tell the Boot ROM about our application
#[link_section = ".start_block"]
#[used]
pub static IMAGE_DEF: hal::block::ImageDef = hal::block::ImageDef::secure_exe();
```

This is required in every binary.

## 4. no_std Project Skeleton

Every rp235x-hal binary follows this pattern:

```rust
#![no_std]
#![no_main]

use panic_halt as _;
use rp235x_hal as hal;

/// Tell the Boot ROM about our application
#[link_section = ".start_block"]
#[used]
pub static IMAGE_DEF: hal::block::ImageDef = hal::block::ImageDef::secure_exe();

/// External high-speed crystal on the Raspberry Pi Pico 2 board is 12 MHz.
const XTAL_FREQ_HZ: u32 = 12_000_000u32;

#[hal::entry]
fn main() -> ! {
    let mut pac = hal::pac::Peripherals::take().unwrap();
    let mut watchdog = hal::Watchdog::new(pac.WATCHDOG);

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

    let sio = hal::Sio::new(pac.SIO);
    let pins = hal::gpio::Pins::new(
        pac.IO_BANK0,
        pac.PADS_BANK0,
        sio.gpio_bank0,
        &mut pac.RESETS,
    );

    loop {
        // application logic
    }
}

/// Program metadata for `picotool info`
#[link_section = ".bi_entries"]
#[used]
pub static PICOTOOL_ENTRIES: [hal::binary_info::EntryAddr; 5] = [
    hal::binary_info::rp_cargo_bin_name!(),
    hal::binary_info::rp_cargo_version!(),
    hal::binary_info::rp_program_description!(c"My Program"),
    hal::binary_info::rp_cargo_homepage_url!(),
    hal::binary_info::rp_program_build_attribute!(),
];
```

## 5. ADC Usage

### Key facts:
- **embedded-hal 1.0.0 has NO ADC trait** — must use `embedded_hal_0_2::adc::OneShot`
- ADC pins: GPIO26 (ch0), GPIO27 (ch1), GPIO28 (ch2), GPIO29 (ch3)
- Channel 4 = internal temperature sensor
- `adc.read(&mut pin)` returns `u16` (12-bit result, 0–4095)

### Simple OneShot ADC reading:

```rust
use embedded_hal_0_2::adc::OneShot;

// Initialize ADC
let mut adc = hal::Adc::new(pac.ADC, &mut pac.RESETS);

// Configure ADC pins (disables digital I/O on these pins)
let mut adc_pin_0 = hal::adc::AdcPin::new(pins.gpio26).unwrap(); // ADC0
let mut adc_pin_1 = hal::adc::AdcPin::new(pins.gpio27).unwrap(); // ADC1
let mut adc_pin_2 = hal::adc::AdcPin::new(pins.gpio28).unwrap(); // ADC2
let mut adc_pin_3 = hal::adc::AdcPin::new(pins.gpio29).unwrap(); // ADC3

// Optional: temperature sensor
let mut temperature_sensor = adc.take_temp_sensor().unwrap();

// Read a value (returns u16, 12-bit: 0–4095)
let adc0_value: u16 = adc.read(&mut adc_pin_0).unwrap();
let temp_value: u16 = adc.read(&mut temperature_sensor).unwrap();
```

### ADC FIFO with round-robin (continuous, polling):

```rust
// Build a free-running ADC FIFO, round-robin between multiple channels:
// Sample rate = 48MHz / (divider+1), e.g. 47999 → 1 ksps
let mut adc_fifo = adc
    .build_fifo()
    .clock_divider(47999, 0)
    .set_channel(&mut temperature_sensor)
    .round_robin((&adc_pin_0, &temperature_sensor))
    .start();

loop {
    if adc_fifo.len() > 0 {
        let raw: u16 = adc_fifo.read();
        // process raw...
    }
}
```

### ADC FIFO with DMA:

```rust
use rp235x_hal::dma::{single_buffer, DMAExt};

let dma = pac.DMA.split(&mut pac.RESETS);
let mut adc_fifo = adc
    .build_fifo()
    .clock_divider(47999, 0)
    .set_channel(&mut temperature_sensor)
    .enable_dma()
    .start_paused();

let buf = cortex_m::singleton!(: [u16; 500] = [0u16; 500]).unwrap();
let dma_transfer = single_buffer::Config::new(dma.ch0, adc_fifo.dma_read_target(), buf).start();
adc_fifo.resume();

// Wait for DMA to complete
let (ch0, adc_read_target, buf) = dma_transfer.wait();
adc_fifo.pause();
// buf now contains 500 ADC samples
```

## 6. USB CDC/ACM Serial Communication

### Required crates:
```toml
usb-device = "0.3.2"
usbd-serial = "0.2.2"
heapless = "0.8.0"
```

### USB Serial setup:

```rust
use core::fmt::Write;
use heapless::String;
use usb_device::{class_prelude::*, prelude::*};
use usbd_serial::SerialPort;

// After clock init...
let timer = hal::Timer::new_timer0(pac.TIMER0, &mut pac.RESETS, &clocks);

// Set up USB driver
let usb_bus = UsbBusAllocator::new(hal::usb::UsbBus::new(
    pac.USB,
    pac.USB_DPRAM,
    clocks.usb_clock,
    true,
    &mut pac.RESETS,
));

// Create a CDC/ACM serial port
let mut serial = SerialPort::new(&usb_bus);

// Create a USB device with VID/PID
let mut usb_dev = UsbDeviceBuilder::new(&usb_bus, UsbVidPid(0x16c0, 0x27dd))
    .strings(&[StringDescriptors::default()
        .manufacturer("My Company")
        .product("Serial port")
        .serial_number("001")])
    .unwrap()
    .max_packet_size_0(64)
    .unwrap()
    .device_class(2) // CDC class
    .build();

loop {
    // Must poll USB frequently
    if usb_dev.poll(&mut [&mut serial]) {
        let mut buf = [0u8; 64];
        match serial.read(&mut buf) {
            Ok(count) if count > 0 => {
                // Process received data...
            }
            _ => {}
        }
    }

    // Send data
    let mut text: String<128> = String::new();
    writeln!(&mut text, "ADC0: {}", adc_value).unwrap();
    let _ = serial.write(text.as_bytes());
}
```

## 7. Memory Layout (memory.x)

```ld
MEMORY {
    /*
     * The RP235x has either external or internal flash.
     * 2 MiB is a safe default here, although a Pico 2 has 4 MiB.
     */
    FLASH : ORIGIN = 0x10000000, LENGTH = 2048K
    /*
     * RAM consists of 8 banks, SRAM0-SRAM7, with a striped mapping.
     * This is usually good for performance, as it distributes load on
     * those banks evenly.
     */
    RAM : ORIGIN = 0x20000000, LENGTH = 512K
    /*
     * RAM banks 8 and 9 use a direct mapping. They can be used to have
     * memory areas dedicated for some specific job, improving predictability
     * of access times.
     * Example: Separate stacks for core0 and core1.
     */
    SRAM8 : ORIGIN = 0x20080000, LENGTH = 4K
    SRAM9 : ORIGIN = 0x20081000, LENGTH = 4K
}

EXTERN(RESET_HANDLER);

SECTIONS {
    /* ### Boot ROM info
     *
     * Goes after .vector_table, to keep it in the first 4K of flash
     * where the Boot ROM can find it
     */
    .start_block ADDR(.vector_table) + SIZEOF(.vector_table) :
    {
        __start_block_addr = .;
        KEEP(*(.start_block));
    } > FLASH

} INSERT AFTER .vector_table;

/* Move _stext after the Block */
_stext = ADDR(.start_block) + SIZEOF(.start_block);

SECTIONS {
    /* ### Picotool 'Binary Info' Entries
     *
     * Goes after .text, to keep it in flash
     */
    .bi_entries : ALIGN(4)
    {
        __bi_entries_start = .;
        KEEP(*(.bi_entries));
        __bi_entries_end = .;
    } > FLASH

} INSERT AFTER .text;

SECTIONS {
    /* ### Boot ROM End Block
     *
     * Goes after .uninit, to keep it in RAM where the Boot ROM can find it
     */
    .end_block (INFO) :
    {
        __end_block_addr = .;
        KEEP(*(.end_block));
    }

} INSERT AFTER .uninit;

PROVIDE(start_to_end = __end_block_addr - __start_block_addr);
PROVIDE(end_to_start = __start_block_addr - __end_block_addr);
```

## 8. build.rs

```rust
//! Set up linker scripts for the rp235x-hal examples

use std::fs::File;
use std::io::Write;
use std::path::PathBuf;

fn main() {
    // Put the linker script somewhere the linker can find it
    let out = PathBuf::from(std::env::var_os("OUT_DIR").unwrap());
    println!("cargo:rustc-link-search={}", out.display());

    // The file `memory.x` is loaded by cortex-m-rt's `link.x` script, which
    // is what we specify in `.cargo/config.toml` for Arm builds
    let memory_x = include_bytes!("memory.x");
    let mut f = File::create(out.join("memory.x")).unwrap();
    f.write_all(memory_x).unwrap();
    println!("cargo:rerun-if-changed=memory.x");

    println!("cargo:rerun-if-changed=build.rs");
}
```

## 9. .cargo/config.toml

```toml
[build]
# Set the default target to match the Cortex-M33 in the RP2350
target = "thumbv8m.main-none-eabihf"

[target.thumbv8m.main-none-eabihf]
rustflags = [
    "-C", "link-arg=--nmagic",
    "-C", "link-arg=-Tlink.x",
    "-C", "link-arg=-Tdefmt.x",
    "-C", "target-cpu=cortex-m33",
]
# Use picotool for loading (when board is in BOOTSEL mode)
runner = "picotool load -u -v -x -t elf"
```

## 10. Cargo.toml Dependencies (for this project)

```toml
[package]
name = "rp_adc_trial_1"
version = "0.1.0"
edition = "2021"
rust-version = "1.82"

[dependencies]
cortex-m = "0.7.2"
cortex-m-rt = "0.7"
critical-section = "1.2.0"
embedded-hal = "1.0.0"
embedded_hal_0_2 = { package = "embedded-hal", version = "0.2.5", features = ["unproven"] }
fugit = "0.3.6"
heapless = "0.8.0"
nb = "1.0"
panic-halt = "0.2.0"
rp235x-hal = { version = "0.4.0", features = ["binary-info", "critical-section-impl", "rt"] }
usb-device = "0.3.2"
usbd-serial = "0.2.2"
```

### Feature flags for rp235x-hal:
- `binary-info` — enables picotool-compatible metadata
- `critical-section-impl` — provides critical-section implementation
- `rt` — enables cortex-m-rt runtime (re-exports `#[entry]` macro via `#[hal::entry]`)
- `defmt` — enables defmt formatting support (optional, for debugging)

## 11. Key HAL Modules

| Module       | Purpose                                      |
|-------------|----------------------------------------------|
| `adc`       | Analog to Digital Converter                   |
| `block`     | Image definition for Boot ROM                 |
| `clocks`    | Clock configuration and PLLs                  |
| `dma`       | DMA controller                                |
| `gpio`      | GPIO pins (48 pins on RP2350B)                |
| `i2c`       | I²C controller                                |
| `multicore` | Dual-core support                             |
| `pio`       | Programmable I/O                              |
| `pll`       | Phase-Locked Loops                            |
| `spi`       | SPI controller                                |
| `timer`     | Hardware timers                               |
| `uart`      | UART serial                                   |
| `usb`       | USB device support                            |
| `watchdog`  | Watchdog timer                                |

## 12. Important Notes

1. **Crystal frequency:** The Tiny 2350 (like Pico 2) uses a 12 MHz external crystal.
2. **ADC reference voltage:** 3.3V by default (internal VREF).
3. **ADC resolution:** 12-bit (values 0–4095).
4. **USB VID/PID:** The examples use `0x16c0`/`0x27dd` (Van Ooijen Technische Informatica / CDC-ACM). For production, use your own registered VID/PID.
5. **USB polling:** `usb_dev.poll()` must be called frequently (in main loop or interrupt) for USB to work.
6. **No boot2:** RP2350 uses `ImageDef::secure_exe()` in `.start_block` section instead of the boot2 bootloader used by RP2040.
