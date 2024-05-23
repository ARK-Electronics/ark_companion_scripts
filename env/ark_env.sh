#!/bin/bash
if [ -f /etc/ark.env ]; then
    export $(grep -v '^#' /etc/ark.env | xargs)
fi
