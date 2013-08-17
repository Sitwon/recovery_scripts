#!/bin/bash
set -e

BASEDIR=$(dirname $0)
source "${BASEDIR}/sort.sh"

trap '' 2

VIEWER=view
RECOVER_DIR=''
LAST_VIEWER=''
LAST_RECOVER_DIR=''

TEMP=$(getopt -n "$(basename $0)" -o hv: --long help,viewer: -- "$@")
eval set -- "$TEMP"

while true; do
	case "$1" in
		-h|--help)
			echo "Help! I need someone!"
			shift
			;;
		-v|--viewer)
			VIEWER="$2"
			shift 2
			;;
		--)
			shift
			break
			;;
		*)
			echo "Unknown option"
			exit 1
			;;
	esac
done

clear_input(){
	read -d '' -t 0.1 -n 10000 || true
}

real_file(){
	if [ -L "$1" ]; then
		readlink "$1"
	else
		echo "$1"
	fi
}

print_file_info(){
	local FILE="$(real_file "$1")"
	echo
	echo "Filename: $1"
	if [ "$1" != "$FILE" ]; then
		echo "Real filename: $FILE"
	fi
	ls -lh "$FILE"
	file "$FILE"
}

print_options(){
	echo -n "(v)iew file, (d)elete file, (s)kip file, (r)ecover file: "
}

get_action(){
	ACTION=''
	while true; do
		clear_input
		print_options
		read -d '' -n 1 ACTION
		echo
		case "$ACTION" in
			v|V|d|s|r)
				break
				;;
			q|Q)
				exit 0
				;;
			*)
				echo "Invalid selection: '$ACTION'"
				;;
		esac
	done
}

get_recover_dir(){
	RECOVER_DIR=''
	clear_input
	read -e -p "Recovery directory: " -i "${LAST_RECOVER_DIR}" RECOVER_DIR
	if [ -z "$RECOVER_DIR" ]; then
		RECOVER_DIR="$LAST_RECOVER_DIR"
	else
		LAST_RECOVER_DIR="$RECOVER_DIR"
	fi
}

custom_viewer(){
	local CUSTOM_VIEWER=''
	if [ -z "$LAST_VIEWER" ]; then
		LAST_VIEWER="$VIEWER"
	fi
	clear_input
	read -e -p "Custom viewer ($LAST_VIEWER): " CUSTOM_VIEWER
	if [ ! -z "$CUSTOM_VIEWER" ]; then
		LAST_VIEWER="$CUSTOM_VIEWER"
	fi
	"$LAST_VIEWER" "$1"
}

check_file(){
	while true; do
		print_file_info "$1"
		get_action
		case "$ACTION" in
			v)
				"$VIEWER" "$1"
				;;
			V)
				custom_viewer "$1"
				;;
			d)
				delete_file "$1"
				echo "File deleted: $1"
				break
				;;
			s)
				echo "File skipped: $1"
				break
				;;
			r)
				get_recover_dir
				recover_file "$1" "$RECOVER_DIR"
				echo "File recovered: $1 => $RECOVER_DIR"
				break
				;;
			*)
				echo "Internal error."
				exit 1
				;;
		esac
	done
}

while [ $# -gt 0 ]; do
	check_file "$1"
	shift
done

