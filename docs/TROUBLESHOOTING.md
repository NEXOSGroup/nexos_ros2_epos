# Troubleshooting — nexos_ros2_epos

Problems encountered while porting/running on ROS 2 Lyrical, with fixes.

## Build

### `Unknown CMake command "ament_target_dependencies"`
`ament_target_dependencies()` was removed in Lyrical's `ament_cmake`.
Use `target_link_libraries()` with namespaced targets instead
(see [BUILD.md](BUILD.md)). Already fixed in this repo.

### `on_init` does not override / wrong signature
In `hardware_interface` 6.x the signature is
`on_init(const hardware_interface::HardwareComponentInterfaceParams&)`,
not `(const HardwareInfo&)`. Already fixed here.

### `maxon EPOS Command Library not found` (CMake configure error)
The proprietary library is not installed. Run
`scripts/install_maxon_epos_library.sh <zip>` and confirm
`/usr/lib/libEposCmd.so` exists.

### `dpkg was interrupted`
Left over from a killed apt run:
```bash
sudo dpkg --configure -a && sudo apt-get -f install -y
```

### apt lock held by `unattended-upgrades`
Wait for it, or use `apt-get -o DPkg::Lock::Timeout=600 ...`.

## Runtime

### `list_available_devices` prints `No devices found!`
Expected when **no EPOS is connected**. With hardware attached but still not
found:
- Re-plug the USB cable (udev).
- Ensure your user is in `plugdev`/`dialout` (re-login after adding).
- Confirm the serial number via the same tool and match it in the URDF.

### `libEposCmd.so: cannot open shared object file`
The maxon library isn't on the loader path. Re-run the installer; verify
`ldd $(ros2 pkg prefix epos_hardware)/lib/epos_hardware/list_available_devices`
resolves `libEposCmd.so` to `/usr/lib/...`.

### Motor does not move / faults
- Set `clear_faults: true` for first bring-up.
- Check the active command mode matches your controller
  (`perform_command_mode_switch`).
- Verify `encoder_resolution` and `mechanical_reduction` — wrong values give
  wrong scaling/direction.

## Platform notes

- `/tmp` is mounted `noexec` on Ubuntu Server — run shell scripts as
  `bash script.sh`, not `./script.sh`.
- After a cloud-init re-run (changed `instance-id`) the Pi **regenerates its SSH
  host keys** — clear the old key with `ssh-keygen -R <ip>` before reconnecting.
