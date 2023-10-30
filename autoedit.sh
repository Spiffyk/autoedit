#!/usr/bin/env bash
# vim: noet:ts=8:sw=8
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


configure_command='./configure'
status_exec='./config.status'
fail_file='./.autoedit-failed'

short_help_text=$(cat << EOF
USAGE: $0 [options]
EOF
)

help_text=$(cat << EOF
Interactive reconfiguration script for Autotools
$short_help_text

Available options:
	-f, --no-failed
		Do not write into '$fail_file' on configuration failure and do
		not take it into account while loading the current
		configuration. May be used in conjunction with the
		-r/--reconfigure option.

	-h, --help
		Displays this help and exits.

	-r, --reconfigure
		Reconfigures the project, keeping its current configuration
		options, without opening the editor. Takes the '$fail_file' into
		account, if it exists.

	-q, --query
		Print the current configuration, that would be taken into
		account by -r/--reconfigure, print it into stdout, and exit
		without reconfiguring.
EOF
)

reconfigure=0
query=0
fail_journalling=1

getopt=$(getopt \
	--options     'fhqr'\
	--longoptions 'no-failed,help,query,reconfigure'\
	--name        'autoedit'\
	-- "$@")

if [ $? -ne 0 ]; then
	>&2 echo "$short_help_text"
	>&2 echo 'Use --help for more information'
	exit 1
fi

eval set -- "$getopt"
unset getopt

while true; do
	case "$1" in
		'-f'|'--no-failed')
			fail_journalling=0
			shift
			continue
			;;
		'-h'|'--help')
			echo "$help_text"
			exit 0
			;;
		'-r'|'--reconfigure')
			reconfigure=1
			shift
			continue
			;;
		'-q'|'--query')
			query=1
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

curr_config_avail=0
fail_file_config_avail=0

if [ -x "$status_exec" ]; then
	curr_config="$("$status_exec" --config)"
	curr_config_avail=1
fi
if [ \( $fail_journalling -ne 0 \) -a \( -f "$fail_file" \) ]; then
	fail_file_config="$(cat "$fail_file")"
	fail_file_config_avail=1
fi

if [ "$query" -ne 0 ]; then
	if [ $fail_file_config_avail -ne 0 ]; then
		echo "$fail_file_config"
	elif [ $curr_config_avail -ne 0 ]; then
		echo "$curr_config"
	else
		>&2 echo "'$status_exec' or '$fail_file' not found - no configuration available"
		exit 1
	fi

	exit 0
elif [ "$reconfigure" -ne 0 ]; then
	if [ $fail_file_config_avail -ne 0 ]; then
		args="$fail_file_config"
		>&2 echo "'$fail_file' loaded - reconfiguring using the last saved options"
	elif [ $curr_config_avail -ne 0 ]; then
		args="$curr_config"
		>&2 echo "'$status_exec' loaded - reconfiguring using the last saved options"
	else
		args=''
		>&2 echo "'$status_exec' or '$fail_file' not found - reconfiguring with no options"
	fi
else
	if [ -z "$EDITOR" ]; then
		>&2 echo 'No $EDITOR specified.'
		exit 1
	fi

	tmpfile="$(mktemp)"

	if [ $fail_file_config_avail -ne 0 ]; then
		echo "$fail_file_config" >> "$tmpfile"
		echo -e '\n' >> "$tmpfile"
		echo "# [info] '$fail_file' loaded - edit your failed configuration" >> "$tmpfile"

		if [ $curr_config_avail -ne 0 ]; then
			echo "# [info] Last successful configuration was the following:" >> "$tmpfile"
			echo '#' >> "$tmpfile"
			echo "#        $curr_config" >> "$tmpfile"
			echo '#' >> "$tmpfile"
		fi
	else
		if [ $curr_config_avail -ne 0 ]; then
			echo "$curr_config" >> "$tmpfile"
			echo -e '\n' >> "$tmpfile"
			echo "# [info] '$status_exec' loaded - edit your configuration" >> "$tmpfile"
		else
			echo -e '\n' >> "$tmpfile"
			echo "# [info] '$status_exec' not found - provide your initial configuration" >> "$tmpfile"
		fi
	fi

	echo -e $'# [hint] Put a \'@\' at the beginning of this file to cancel.' >> "$tmpfile"
	echo -e $'# [hint] Everything after the first \'#\' on a line is ignored.' >> "$tmpfile"

	"$EDITOR" "$tmpfile"
	args=$(grep --only-matching '^[^#]*' "$tmpfile")

	# Cancel if @ is found at the beginning
	stop_pattern='^[[:space:]]*@'
	if [[ $args =~ $stop_pattern ]]; then
		>&2 echo '@ found at the beginning of the temp file -- exiting'
		rm -f "$tmpfile"
		exit 0
	fi
fi

ecode=0
eval "$configure_command $args"

if [ $? -ne 0 ]; then
	if [ $fail_journalling -ne 0 ]; then
		>&2 echo "Configuration failed - writing args into '$fail_file'"
		echo "$args" > "$fail_file"
	else
		>&2 echo "Configuration failed - '$fail_file' is disabled, so not writing"
	fi
	ecode=2
fi

if [ "$reconfigure" -eq 0 ]; then
	rm -f "$tmpfile"
fi

if [ $ecode -eq 0 ]; then
	rm -f "$fail_file"
fi

exit "$ecode"
