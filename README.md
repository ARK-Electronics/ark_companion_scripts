# Getting started
This repository contains scripts and services for use with the ARK Jetson Carrier or the ARK Pi6X Flow. Use the **setup.sh** script to install the scripts and services. You can safely run this script multiple times.

## Scripts
All installed scripts are placed at **/usr/local/bin**.

## Services

**mavlink-router.service** <br>
This service enables mavlink-router to route mavlink packets between endpoints. The **main.conf** file defines these endpoints and is installed at **/etc/mavlink-router/**.

**dds-agent.service** <br>
This service starts the DDS agent which connects with the PX4 uXRCE-DDS-Client. `Telem1` on the flight controller is connected directly to the Jetson UART `/dev/ttyTHS0`. This service depends on the `systemd-timesyncd` service to synchronize system time with an accurate remote reference time source.

**logloader.service** <br>
This service downloads log files from the SD card of the flight controller via MAVLink and uploads them to PX4 Flight Review <br>

**rtsp-server.service** <br>
This service provides an RTSP server via gstreamer using a Pi cam at **rtsp://pi6x.local:8554/fpv** <br>

**polaris.service** <br>
This service receives RTCM corrections from the PointOne GNSS Corrections service and publishes them via MAVLink.

**ark-ui-backend.service** <br>
This service provides an express backend for the ark-ui configuration UI.

**hotspot-control.service** <br>
This service creates a hotspot after booting if the device is unable to auto connect to a network. You can then use the ark-ui configuration UI to configure your network.

### Jetson only
**jetson-can.service** <br>
This service enables the Jetson CAN interface.

**jetson-clocks.service** <br>
This service sets the Jetson clocks to their maximum rate.
