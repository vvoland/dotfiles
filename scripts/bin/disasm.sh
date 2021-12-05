#!/bin/sh

echo " $1" | sed 's/\s\+/ /g' | tr -d '<>' | xxd -r -p | ndisasm -b 64 -
