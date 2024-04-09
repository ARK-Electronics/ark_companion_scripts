#!/bin/bash

FILE=$1

ftp_client udp://127.0.0.1:14569 1 put $FILE /fs/microsd
