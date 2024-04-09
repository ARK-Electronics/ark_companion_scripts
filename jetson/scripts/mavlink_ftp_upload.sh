#!/bin/bash

FILE=$1

ftp_client udp://:14569 1 put $FILE /fs/microsd