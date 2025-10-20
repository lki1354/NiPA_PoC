# Raspberry Pi Pico 2 ADC Reader

This project reads all 4 ADC inputs on the Raspberry Pi Pico 2 and sends the data via USB serial.

## Hardware

- Raspberry Pi Pico 2
- ADC inputs on GPIO26 (ADC0), GPIO27 (ADC1), GPIO28 (ADC2), GPIO29 (ADC3)
- Input voltage range: 0-3.3V

## Features

- Reads all 4 ADC channels (12-bit resolution)
- Converts raw ADC values to voltage
- Sends formatted data via USB serial at 100ms intervals
- Sample output format: `Sample: 123 | ADC0: 2048 (1.650V) | ADC1: 1024 (0.825V) | ADC2: 3072 (2.475V) | ADC3: 512 (0.413V)`

## Prerequisites

1. Install Rust: https://rustup.rs/
2. Add ARM Cortex-M target:
   ```
   rustup target add thumbv6m-none-eabi
   ```
3. Install probe-rs (for flashing):
   ```
   cargo install probe-rs --features cli
   ```
4. Install flip-link:
   ```
   cargo install flip-link
   ```

## Building

```bash
cargo build --release
```

## Flashing

```bash
cargo run --release
```

Or manually:
```bash
probe-rs run --chip RP2040 target/thumbv6m-none-eabi/release/pico2_adc_reader
```

## Using UF2 Bootloader (Alternative)

1. Install elf2uf2-rs:
   ```
   cargo install elf2uf2-rs
   ```

2. Build and convert to UF2:
   ```
   cargo build --release
   elf2uf2-rs target/thumbv6m-none-eabi/release/pico2_adc_reader pico2_adc_reader.uf2
   ```

3. Hold BOOTSEL button while connecting Pico to USB
4. Copy the UF2 file to the mounted drive

## Monitoring Serial Output

Use a serial terminal program to view the output:
- **Windows**: PuTTY, TeraTerm, or Arduino Serial Monitor
- **Linux/Mac**: `screen /dev/ttyACM0 115200` or `minicom`
- **VS Code**: Serial Monitor extension

The Pico will appear as a USB CDC serial device.

## Pin Connections

| GPIO Pin | ADC Channel | Function |
|----------|-------------|----------|
| GPIO26   | ADC0        | Analog Input 0 |
| GPIO27   | ADC1        | Analog Input 1 |
| GPIO28   | ADC2        | Analog Input 2 |
| GPIO29   | ADC3        | Analog Input 3 |

**Warning**: Do not exceed 3.3V on any ADC input!

## License

This project is open source and available under the MIT License.
