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

short_help_text=$(cat << EOF
USAGE: $0 [options]
EOF
)

help_text=$(cat << EOF
Interactive reconfiguration script for Autotools
$short_help_text

Available options:
	-h, --help
                Displays this help and exits.

	-r, --reconfigure
                Reconfigures the project, keeping its current configuration
                options, without opening the editor.
EOF
)

configure_command='./configure'
reconfigure=0

set +e
getopt=$(getopt \
	--options     'hr'\
	--longoptions 'help,reconfigure'\
	--name        'autoedit'\
	-- "$@")

if [ $? -ne 0 ]; then
	>&2 echo "$short_help_text"
	>&2 echo 'Use --help for more information'
	exit 1
fi
set -e

eval set -- "$getopt"
unset getopt

while true; do
	case "$1" in
		'-h'|'--help')
			echo "$help_text"
			exit 0
			;;
		'-r'|'--reconfigure')
			reconfigure=1
			shift
			continue
			;;
		'--')
			shift
			break
			;;
		*)
			>&2 echo 'Internal error!'
			exit 1
			;;
	esac
done

if [ ! -x "$configure_command" ]; then
	>&2 echo "'$configure_command' does not exist or it is not executable"
	>&2 echo "HINT: did you forget to generate it with GNU Autotools?"
	exit 1
fi

if [ "$reconfigure" -eq 0 ]; then
	if [ -z "$EDITOR" ]; then
		>&2 echo 'No $EDITOR specified.'
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
else
	if [ -x "./config.status" ]; then
		args="$(./config.status --config)"
		echo $'\'config.status\' loaded - reconfiguring using the provided options'
	else
		args=''
		echo $'\'config.status\' not found - reconfiguring with no options'
	fi
fi

eval "$configure_command $args"

if [ "$reconfigure" -ne 0 ]; then
	rm -f "$tmpfile"
fi
