#!/usr/bin/env bash
################################################################################
# A script for editing GNU Autoconf configuration.
#
# See README.md for more info
################################################################################

# Copyright (c) Oto Šťáva
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


set -e

configure_command='./configure'

if [ -z "$EDITOR" ]; then
    >&2 echo 'No $EDITOR specified.'
    exit 1
fi

if [ ! -x "$configure_command" ]; then
    >&2 echo "'$configure_command' does not exist or it is not executable"
    >&2 echo "HINT: did you forget to generate it with GNU Autotools?"
    exit 1
fi

tmpfile="$(mktemp)"

if [ -x "./config.status" ]; then
    ./config.status --config >> "$tmpfile"
    echo -e '\n' >> "$tmpfile"
    echo $'# [info] \'config.status\' loaded - edit your configuration' >> "$tmpfile"
else
    echo -e '\n' >> "$tmpfile"
    echo $'# [info] \'config.status\' not found - provide your initial configuration' >> "$tmpfile"
fi

echo -e $'# [hint] put a \'@\' at the beginning of this file to cancel' >> "$tmpfile"
echo -e $'# [hint] everything after the first \'#\' on a line is ignored' >> "$tmpfile"

"$EDITOR" "$tmpfile"
args=$(grep --only-matching '^[^#]*' "$tmpfile")

# Cancel if @ is found at the beginning
stop_pattern='^[[:space:]]*@'
if [[ $args =~ $stop_pattern ]]; then
    echo '@ found at the beginning of the temp file -- exiting'
    rm -f "$tmpfile"
    exit 0
fi

eval "$configure_command $args"

rm -f "$tmpfile"
