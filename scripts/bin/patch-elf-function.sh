#!/bin/bash
set -e

USAGE="usage: patch-elf-function.sh <elf-file> <function substring> <patch> <patched-elf-file>"

SOURCE="$1"
FUNCTION="$2"
PATCH="$3"
OUTPUT="$4"

[ ! "$#" == "4" ] && echo $USAGE && exit 1

[ -z "$SOURCE" ] && echo $USAGE && exit 2
[ -z "$OUTPUT" ] && echo $USAGE && exit 3

[ ! -f "$SOURCE" ] && echo "$SOURCE does not exist" && exit 4
[ -d "$OUTPUT" ] && echo "$OUTPUT is a directory" && exit 5

# Get the offset of function
hex_offset=$(nm "$SOURCE" | grep "$FUNCTION" | awk '{ if ( $2 == "t") print $1 }')

if [ -z "$hex_offset" ]; then
    echo "Could not find method $FUNCTION!"
    exit 6
fi

decimal_offset="$((16#${hex_offset}))"

echo "Patching 0x$hex_offset ($decimal_offset) with \"$PATCH\""

cp "$SOURCE" "$OUTPUT"

# Patch
echo -ne "$PATCH" | dd of="$OUTPUT" "seek=$decimal_offset" bs=1 conv=notrunc 2>/dev/null
echo "Success!"

