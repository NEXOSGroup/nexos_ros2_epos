#!/usr/bin/env bash
#
# Installs the PROPRIETARY maxon EPOS Command Library (libEposCmd) and the
# FTDI D2XX library (libftd2xx) system-wide, using maxon's own installer.
#
# These libraries are NOT bundled in this repository for license reasons.
# Obtain the "EPOS Command Library" for Linux from maxon:
#   https://www.maxongroup.com  (Downloads -> Software/Firmware -> EPOS Command Library)
#
# Usage:
#   scripts/install_maxon_epos_library.sh /path/to/EPOS-Linux-Library-En.zip
#   scripts/install_maxon_epos_library.sh /path/to/EPOS_Linux_Library   (extracted dir)
#
set -euo pipefail

SRC="${1:-}"
if [[ -z "$SRC" ]]; then
  echo "Usage: $0 <EPOS-Linux-Library ZIP | extracted directory>" >&2
  exit 1
fi

WORK="$(mktemp -d)"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

if [[ "$SRC" == *.zip ]]; then
  echo "Extracting $SRC ..."
  unzip -q "$SRC" -d "$WORK"
  DIR="$(find "$WORK" -maxdepth 3 -name install.sh -printf '%h\n' | head -1)"
else
  DIR="$SRC"
fi

if [[ -z "${DIR:-}" || ! -f "$DIR/install.sh" ]]; then
  echo "ERROR: could not find install.sh under '$SRC'." >&2
  exit 1
fi

echo "Running the official maxon installer from: $DIR"
# /tmp is often mounted noexec -> invoke via 'bash <file>' instead of './install.sh'
sudo bash "$DIR/install.sh"

echo
echo "Verifying system integration:"
ls -l /usr/lib/libEposCmd.so /usr/lib/libftd2xx.so
echo "Done. You may need to re-plug the USB device (udev) and re-login (group access)."
