# rp_adc_trial_1 — RP2350 ADC Monitor

Bare-metal Rust firmware for the **Pimoroni Tiny 2350** (RP2350A0A2) that reads
4 ADC channels and streams scaled, ASCII-formatted measurements over USB serial.

## Hardware

| Pin    | ADC Channel | Function                                          |
|--------|-------------|---------------------------------------------------|
| GPIO26 | ADC0        | Current measurement — CT220BMC-HS5 hall sensor     |
| GPIO27 | ADC1        | Current measurement — CT220BMC-HS5 hall sensor     |
| GPIO28 | ADC2        | Current measurement — CT220BMC-HS5 hall sensor     |
| GPIO29 | ADC3        | Voltage from capacitive divider                    |
| USB_DP / USB_DM | —  | USB CDC serial to PC                              |

## Building

### Prerequisites

```sh
# Install the ARM Cortex-M33 target (only needed once)
rustup target add thumbv8m.main-none-eabihf
```

### Compile

```sh
cargo build --release
```

The ELF binary is at `target/thumbv8m.main-none-eabihf/release/rp_adc_trial_1`.

### Flash

Hold the **BOOTSEL** button on the Tiny 2350 while plugging in USB, then:

```sh
cargo run --release
```

This uses `picotool` to load, verify, and execute the firmware automatically.

> Install picotool from <https://github.com/raspberrypi/picotool/releases> if
> you don't have it yet.

---

## Connecting to the Serial Port on PC

The firmware presents itself as a **USB CDC/ACM** (Communications Device Class)
virtual serial port. No external UART adapter is needed — just the USB cable.

### Connection parameters

| Parameter     | Value                          |
|---------------|--------------------------------|
| **Protocol**  | USB CDC/ACM (virtual COM port) |
| **Baud rate** | *any* — ignored by USB CDC¹    |
| **Data bits** | 8                              |
| **Parity**    | None                           |
| **Stop bits** | 1                              |
| **Flow control** | None                        |
| **Line ending** | `\r\n` (CRLF)                |
| **USB VID**   | `0x16C0`                       |
| **USB PID**   | `0x27DD`                       |

> ¹ USB CDC serial runs at full USB speed (12 Mbit/s). The baud rate setting
> in your terminal program is ignored by the device — you can set it to any
> value (e.g. 115200) and it will work. The actual transfer speed is governed
> by the USB bus, not a UART clock.

### Finding the serial port

#### Linux

The device appears as `/dev/ttyACM0` (or `/dev/ttyACM1`, etc.):

```sh
# List connected serial devices
ls /dev/ttyACM*

# Or use dmesg to see when it was plugged in
dmesg | tail
```

You may need to add your user to the `dialout` group for permission:

```sh
sudo usermod -aG dialout $USER
# Log out and log back in for the change to take effect
```

#### Windows

The device appears as a **COM port** (e.g. `COM3`, `COM4`, …):

1. Open **Device Manager**
2. Expand **Ports (COM & LPT)**
3. Look for **"ADC Monitor (COMx)"** or **"USB Serial Device (COMx)"**

> On Windows 10/11, the CDC driver is usually loaded automatically. If not,
> the VID/PID `16C0:27DD` works with the built-in `usbser.sys` driver.

#### macOS

The device appears as `/dev/tty.usbmodemXXXX`:

```sh
ls /dev/tty.usbmodem*
```

### Reading the data

#### Using `screen` (Linux / macOS)

```sh
screen /dev/ttyACM0 115200
```

Press `Ctrl-A` then `K` then `Y` to exit.

#### Using `minicom` (Linux)

```sh
minicom -D /dev/ttyACM0 -b 115200
```

Press `Ctrl-A` then `X` to exit.

#### Using `picocom` (Linux)

```sh
picocom /dev/ttyACM0 -b 115200
```

Press `Ctrl-A` then `Ctrl-X` to exit.

#### Using PuTTY (Windows)

1. Open PuTTY
2. Connection type: **Serial**
3. Serial line: `COM3` (replace with your port)
4. Speed: `115200` (any value works)
5. Click **Open**

#### Using the Arduino Serial Monitor

1. Select the correct COM port
2. Set baud rate to `115200`
3. Set line ending to **Both NL & CR**

#### Using Python (`pyserial`)

```python
import serial

ser = serial.Serial('/dev/ttyACM0', 115200, timeout=1)
# On Windows: serial.Serial('COM3', 115200, timeout=1)

while True:
    line = ser.readline().decode('ascii', errors='replace').strip()
    if line:
        print(line)
```

Install pyserial with: `pip install pyserial`

---

## Serial Output Format

Data is sent as ASCII text, one line per sample at **10 Hz** (every 100 ms).

```
I0:-0.37mA I1:12.50mA I2:-3.78mA V3:1650.00mV
I0:-0.38mA I1:12.48mA I2:-3.80mA V3:1649.50mV
...
```

| Field | Unit | Description                                  |
|-------|------|----------------------------------------------|
| `I0`  | mA   | Current on ADC0 (CT220BMC-HS5 hall sensor)   |
| `I1`  | mA   | Current on ADC1 (CT220BMC-HS5 hall sensor)   |
| `I2`  | mA   | Current on ADC2 (CT220BMC-HS5 hall sensor)   |
| `V3`  | mV   | Voltage on ADC3 (capacitive divider)         |

- Negative current values indicate reverse current direction.
- Values are formatted with 2 decimal places.
- Each line is terminated with `\r\n` (CRLF).

## ADC Specifications

| Parameter         | Value  |
|-------------------|--------|
| Resolution        | 12-bit |
| Range             | 0–4095 |
| Reference voltage | 3.3 V  |
| Sample rate       | 10 Hz (configurable via `SAMPLE_INTERVAL_MS`) |

## Calibration

The scaling constants in `src/main.rs` should be adjusted to match your
hardware:

| Constant                  | Default  | Description                                |
|---------------------------|----------|--------------------------------------------|
| `HALL_SENSOR_V_QUIESCENT` | 1.65 V   | Hall sensor zero-current output voltage    |
| `HALL_SENSOR_SENSITIVITY` | 0.0264 V/A | Hall sensor sensitivity (26.4 mV/A)     |
| `CAP_DIVIDER_RATIO`       | 1.0      | Capacitive divider ratio (Vadc / Vactual)  |
| `SAMPLE_INTERVAL_MS`      | 100 ms   | Interval between readings (100 ms = 10 Hz) |

## License

MIT OR Apache-2.0
