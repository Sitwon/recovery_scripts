#!/bin/bash

get_type() {
	echo $1 | rev | cut -d . -f 1 | rev | grep -v '/'
}

sort_by_type() {
	local TYPE="$(get_type "$1")"
	if [ ! -z "$TYPE" ]; then
		local DESTINATION="by-type/$TYPE/$(basename "$1")"
		if [ ! -e "$DESTINATION" ]; then
			ln -s "$1" "$DESTINATION"
		else
			local COUNT=1
			local NEWDEST="${DESTINATION%$TYPE}$COUNT.$TYPE"
			while [ -e "$NEWDEST" ]; do
				(( COUNT += 1 ))
				NEWDEST="${DESTINATION%$TYPE}$COUNT.$TYPE"
			done
			echo "Renamed: $1 => $NEWDEST"
			ln -s "$1" "$NEWDEST"
		fi
	else
		echo "Unknown type for: $1"
	fi
}

recover_file() {
	local TYPE="$(get_type "$1")"
	local TARGET="$(readlink "$1")"
	local DESTINATION="$2"
	if [ -e "$DESTINATION" -a ! -d "$DESTINATION" ]; then
		local COUNT=1
		local NEWDEST="${DESTINATION%$TYPE}$COUNT.$TYPE"
		while [ -e "$NEWDEST" ]; do
			(( COUNT += 1 ))
			NEWDEST="${DESTINATION%$TYPE}$COUNT.$TYPE"
		done
		echo "Renamed: $1 => $NEWDEST"
		DESTINATION="$NEWDEST"
	fi
	mv "$TARGET" "$DESTINATION" && \
	rm "$1"
}

delete_file() {
	local TARGET="$(readlink "$1")"
	rm "$TARGET" "$1"
}

delete_files() {
	while [ $# -gt 0 ]; do
		delete_file "$1"
		shift
	done
}

list_file() {
	local TARGET="$(readlink "$1")"
	ls -l "$TARGET"
}

list_files() {
	while [ $# -gt 0 ]; do
		list_file "$1"
		shift
	done
}

# Run the selected operation
if [ "$(basename -- $0)" = "sort.sh" ]; then
	$@
fi

