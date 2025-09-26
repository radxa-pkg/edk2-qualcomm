#!/usr/bin/env bash

if [[ ! -v ERROR_REQUIRE_FILE ]]; then
	readonly ERROR_REQUIRE_FILE=-3
fi
if [[ ! -v ERROR_ILLEGAL_PARAMETERS ]]; then
	readonly ERROR_ILLEGAL_PARAMETERS=-4
fi
if [[ ! -v ERROR_REQUIRE_TARGET ]]; then
	readonly ERROR_REQUIRE_TARGET=-5
fi

build_spinor() {
	mkdir -p /tmp/spinor
	cp -r "$SCRIPT_DIR"/* /tmp/spinor/
}

erase_spinor() {
	local DEVICE=${1:-/dev/mtd0}

	if [[ ! -e $DEVICE ]]; then
		echo "$DEVICE is missing." >&2
		return "$ERROR_REQUIRE_TARGET"
	fi

	flash_erase "$DEVICE" 0 0
}

update_spinor() {
	local DEVICE=${1:-/dev/mtd0}

	if [[ ! -e $DEVICE ]]; then
		echo "$DEVICE is missing." >&2
		return "$ERROR_REQUIRE_TARGET"
	fi

	build_spinor
	erase_spinor "$DEVICE"
	echo "Writing to $DEVICE..."
	pushd /tmp/spinor/
	edl-ng --hostdev-as-target "$DEVICE" rawprogram rawprogram0.xml patch0.xml
	popd
	rm -rf /tmp/spinor/
	sync
}

# https://stackoverflow.com/a/28776166
is_sourced() {
	if [ -n "$ZSH_VERSION" ]; then
		case $ZSH_EVAL_CONTEXT in
		*:file:*)
			return 0
			;;
		esac
	else # Add additional POSIX-compatible shell names here, if needed.
		case ${0##*/} in
		dash | -dash | bash | -bash | ksh | -ksh | sh | -sh)
			return 0
			;;
		esac
	fi
	return 1 # NOT sourced.
}

if ! is_sourced; then

	set -euo pipefail
	shopt -s nullglob

	SCRIPT_DIR="$(dirname "$(realpath "$0")")"

	ACTION="$1"
	shift

	if [[ $(type -t "$ACTION") == function ]]; then
		$ACTION "$@"
	else
		echo "Unsupported action: '$ACTION'" >&2
		exit "$ERROR_ILLEGAL_PARAMETERS"
	fi
fi
