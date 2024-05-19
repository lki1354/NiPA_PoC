# NiPA_PoC
Nonintrusive Power Analyser Proof of Concept

# Hardware 




## Main Control Board (MCB)
- [XIAO-RP2040](https://github.com/Seeed-Studio/wiki-documents/blob/31780f7dfb7438a48e944de60c9eee259ebd8c73/docs/Sensor/SeeedStudio_XIAO/SeeedStudio_XIAO_RP2040/XIAO-RP2040.md#L4)
- [XIAO-ESP32S3](https://github.com/Seeed-Studio/wiki-documents/blob/docusaurus-version/docs/Sensor/SeeedStudio_XIAO/SeeedStudio_XIAO_ESP32S3/XIAO_ESP32S3_Getting_Started.md)

## Adapter Connection Board (ACB)

## Quantify Collaboration Board (QCB) 

### Voltage Current Board (VCB)

#### Content

- Coil + Amplifier
- Compass
- Capacitor + Amplifier

#### Current Measurment Board (CMB)

##### Content

- Coil + Amplifier
- Compass 

#### Voltage Measurment Board (VMB)

##### Content

- Capacitor + Amplifier

#### Current Coil Board (CCB)

##### Content

- Coil + Amplifier

#### Current Measurment Board (CMB)

##### Content

- Compass 

## Hardware

### Microcontroller

#### RP2024

- (Documentation)(https://www.raspberrypi.com/documentation/microcontrollers/rp2040.html)

### Amplifier
select: - two times: [INA2332](https://www.ti.com/product/INA2332?keyMatch=INA2332)
[list OP ](https://www.ti.com/amplifier-circuit/instrumentation/products.html#1181typ=0.1%3B2&773max=1000%3B10000&769max=0.01%3B0.6&sort=1130;asc&)
- for Current: [INA826](https://www.ti.com/product/INA826)
- for Current: [ad8226](https://www.analog.com/en/products/ad8226.html)
- for Voltage: [INA332](https://www.ti.com/product/de-de/INA332)
- for Voltage: [max9636](https://www.analog.com/en/products/max9636.html)
- for Voltage: [max44261](https://www.analog.com/en/products/max44261.html)

- INA823 VS INA331


#### Compare Current amp

| Device | cost per 1000 | Ib | Vo | Gain @100kHz |
| ------ | ------------- | -- | -- | ---------- |
| INA826 | $1.057|    |    |            |
| AD8226 |$1.29|    |    |            |
|        |               |    |    |            |
|        |               |    |    |            |


#### Compare Voltage amp

| Device | cost per 1000 | Ib | Vo | Gain @100kHz |
| ------ | ------------- | -- | -- | ---------- |
|INA332  |$0.544|±0.5 pA| ±2mV| 400|
| MAX9636|$0.57|±0.1pA|0.3mV|10|
|MAX44261|$0.85|0.01pA|0.01mV|100|




### Magnet
- [MMC5603NJ](https://www.memsic.com/magnetometer-2)


