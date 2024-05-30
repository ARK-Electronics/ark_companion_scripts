## Getting started
This repository contains scripts and services for use with the ARK Jetson Carrier or the ARK Pi6X Flow. Use the **setup.sh** script to install the scripts and services. You can safely run this script as many times as needed.

### Connecting
```
ssh pi@ARK-Pi6X.local
```

## Services

**mavlink-router.service** <br>
This service enables mavlink-router to route mavlink packets between endpoints. The **main.conf** file defines these endpoints and is installed at **/etc/mavlink-router/**.

**dds-agent.service** <br>
This service starts the DDS agent which connects with the PX4 uXRCE-DDS-Client. `Telem1` on the flight controller is connected directly to the Jetson UART `/dev/ttyTHS0`. This service depends on the `systemd-timesyncd` service to synchronize system time with an accurate remote reference time source.

**logloader.service** <br>
This service downloads log files from the SD card of the flight controller and uploads them to PX4 Flight Review
<br> https://github.com/ARK-Electronics/logloader/blob/main/README.md

**polaris.service** <br>
This service receives RTCM corrections from the PointOne GNSS Corrections service and publishes them via MAVLink.

**jetson-can.service** <br>
This service enables the Jetson CAN interface.

**jetson-clocks.service** <br>
This service sets the Jetson clocks to their maximum rate.


## Scripts
The files in the scripts directory get installed at **/usr/local/bin**.
