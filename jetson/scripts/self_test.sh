#! /bin/bash

BOOTLOADERUSBDEVICE="/dev/serial/by-id/usb-ARK_ARK_BL_FMU_v6X.x_0-if00"
APPUSBDEVICE="/dev/serial/by-id/usb-ARK_ARK_FMU_v6X.x_0-if00"

TEST_FLIGHT_CONTROLLER_INTERFACES=false
TEST_JETSONINTERFACES=false

# Parse command line arguments
while [ "$1" != "" ]; do
    case $1 in
        -f | --flightcontroller )   shift
                                    TEST_FLIGHT_CONTROLLER_INTERFACES=true
                                    ;;
        -j | --jetson )             shift
                                    TEST_JETSONINTERFACES=true
                                    ;;
        -h | --help )               echo "Usage: flash_and_test_jetson.sh [options]"
                                    echo "Options:"
                                    echo "  -f, --flightcontroller         Run flight cotnroller tests"
                                    echo "  -j, --jetson                   Run jetson tests"
                                    echo "  -h, --help         Display this help and exit"
                                    exit
                                    ;;
        * )                         echo "Usage: flash_and_test_jetson.sh [options]"
                                    echo "Try 'flash_and_test_jetson.sh --help' for more information."
                                    exit 1
    esac
done

FAILURES=0

start=$(date +%s)

# function to check if the timer has been running for x seconds and sleep until it has
check_timer_and_sleep() {
    # get current time
    now=$(date +%s)
    # calculate time difference
    diff=$((now-$1))
    echo "now=$now start=$1 diff=$diff wait=$2"
    # if the time difference is less than the time we want to wait
    if [ $diff -lt $2 ]; then
        # sleep for the difference between the time we want to wait and the time we have waited
        time_to_sleep=$(($2-$diff))
        echo "sleeping for $time_to_sleep seconds"
        sleep $time_to_sleep
    fi
}

# Returns 0 on success or 1 on failure and reports which cameras have succeeded/failed
function check_cameras {
    local total_cameras=4  # Modify this if you have more or fewer cameras
    local stream_count=25  # Number of frames to capture for the test
    local status=0 #default success

    for ((i=0; i<total_cameras; i++))
    do
        echo "Testing /dev/video$i:" | $PRINTANDLOG
        # Capture frames and direct output to a temporary file to analyze
        output=$(v4l2-ctl --device=/dev/video$i --stream-mmap --stream-count=$stream_count --stream-to=/dev/null 2>&1)

        if [[ $output == *'VIDIOC_STREAMON returned -1'* ]]; then
            echo "Camera /dev/video$i: ERROR detected." | $PRINTANDLOG
            echo "$output" | grep -i error  # Display error messages from output
            status=1

        elif [[ $output == *'fps'* ]]; then
            # Extract and display the fps from the output
            echo "Camera /dev/video$i: SUCCESS - $(echo $output | grep -o '[0-9]*\.[0-9]* fps')"
        else
            echo "Camera /dev/video$i: FAILED to confirm status."
            status=1
        fi
    done

    return $status
}

# print the time and date to the log file
echo "Date: $(date)"

jetson_serial=$(./get_serial_number.py)
# strip all but the final string and store to a variable
jetson_serial=$(echo $jetson_serial | awk '{print $NF}')
echo "Jetson Carrier Serial = $jetson_serial"

if [ "$TEST_FLIGHT_CONTROLLER_INTERFACES" = true ]; then
    echo "Running flight controller tests"

    echo ""
    echo ""

fi

if [ "$TEST_JETSONINTERFACES" = true ]; then
    echo "Running jetson tests"

    echo ""
    echo ""

    while true; do
        read -p "Test M.2 2230 Key E? Requires Intel 9260 Connected: " yesno
        case $yesno in
            [Yy]* )

                if [ $(lsusb -t | grep -i "Class=Wireless, Driver=btusb, 12M" | wc -l) -ge 2 ]; then
                    echo -e "\e[32mUSB 2.0 on M.2 Key E port tests PASSED\e[0m" 
                else
                    echo -e "\e[31mUSB 2.0 on M.2 Key E port tests FAILED\e[0m" 
                    FAILURES=$((FAILURES+1))
                fi

                if [ $(lspci | grep -i "Network controller: Intel Corporation Wireless-AC 9260" | wc -l) -ge 1 ]; then
                    echo -e "\e[32mPCIE M.2 Key E port tests PASSED\e[0m" 
                else
                    echo -e "\e[31mPCIE on M.2 Key E port tests FAILED\e[0m" 
                    FAILURES=$((FAILURES+1))
                fi

                break
            ;;
            [Nn]* ) 
                echo "Not testing M.2 2230 Key E"
                break
            ;;
            * ) echo "Answer either yes or no!";;
        esac
    done

    while true; do
        read -p "Do you want to test USB 2.0? Requires 3 USB 2.0 Flash Drives Connected: " yesno
        case $yesno in
            [Yy]* )

                # if [ $(lsusb -t | grep -i "Driver=usbhid, 12M" | wc -l) -ne 2 ]; then
                #     echo -e "\e[31mUSB 2.0 single test FAILED\e[0m"
                # # print USB 2.0 passed if equal to 3
                # else
                #     echo -e "\e[32mUSB 2.0 single test PASSED\e[0m"
                # fi

                # count the number of "Driver=usb-storage, 480M" in the lsusb -t. if not 3 then print USB 2.0 port failure in RED all caps without the -e at the begining
                if [ $(lsusb -t | grep -i "Driver=usb-storage, 480M" | wc -l) -ge 4 ]; then
                    echo -e "\e[32mUSB 2.0 on USB 3 ports tests PASSED\e[0m" 
                else
                    echo -e "\e[31mUSB 2.0 on USB 3 ports tests FAILED\e[0m" 
                    FAILURES=$((FAILURES+1))
                fi

                break
            ;;
            [Nn]* ) 
                echo "Not testing USB 2.0"
                break
            ;;
            * ) echo "Answer either yes or no!";;
        esac
    done

    while true; do
        read -p "Do you want to test USB 3.0? Requires 3 USB 3.0 Flash Drives Connected: " yesno
        case $yesno in
            [Yy]* )

                # count the number of " Driver=usb-storage, 5000M" in the lsusb -t. if not 3 then print USB 2.0 port failure in RED all caps without the -e at the begining
                if [ $(lsusb -t | grep -i " Driver=usb-storage, 5000M" | wc -l) -ne 3 ]; then
                    echo -e "\e[31mUSB 3.0 on USB 3 ports tests FAILED\e[0m" 
                    FAILURES=$((FAILURES+1))
                # print USB 2.0 passed if equal to 3
                else
                    echo -e "\e[32mUSB 3.0 on USB 3 ports tests PASSED\e[0m" 
                fi

                break
            ;;
            [Nn]* ) 
                echo "Not testing USB 3.0"
                break
            ;;
            * ) echo "Answer either yes or no!";;
        esac
    done

    while true; do
        read -p "Do you want to test MIPI CSI? Requires 4 MIPI CSI cameras connected: " yesno
        case $yesno in
            [Yy]* )

                if check_cameras; then
                    echo -e "\e[32mCSI Test PASSED\e[0m"

                else
                    FAILURES=$((FAILURES+1))
                    echo -e "\e[31mCSI Test FAILED\e[0m"
                fi

                break
            ;;
            [Nn]* ) 
                echo "Not testing CSI"
                break
            ;;
            * ) echo "Answer either yes or no!";;
        esac
    done
fi

if [ $FAILURES -ne 0 ]; then
#print newline
    echo "$FAILURES tests FAILED"

    echo ""
    echo ""
    echo ""

    if [ "$TEST_FLIGHT_CONTROLLER_INTERFACES" = true ]; then
        ./reset_fmu_fast.py
    fi

    echo -e "\e[31m$FAILURES tests FAILED\e[0m"

    exit 1
else
    echo "All tests passed"

    echo ""
    echo ""
    echo ""

    if [ "$TEST_FLIGHT_CONTROLLER_INTERFACES" = true ]; then
        ./reset_fmu_fast.py
    fi

    echo -e "\e[32mAll tests passed\e[0m"

    exit 0
fi

echo "exiting"
exit 0
