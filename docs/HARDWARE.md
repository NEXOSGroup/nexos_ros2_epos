# Hardware & URDF — nexos_ros2_epos

## Controller & connection

- **Controller:** maxon **EPOS2 24/5** (also supports EPOS4), CiA 402 / CANopen
  profile, driven here over **USB**.
- **USB chip:** FTDI with a **non-standard PID** (VID `0403`, PID `a8b0`). The
  Linux kernel `ftdi_sio` driver does **not** bind it — access goes through
  maxon's **D2XX** userspace driver (`libftd2xx`). There is **no `/dev/ttyUSB`**.
- **udev / permissions:** maxon's installer adds `99-ftdi.rules` +
  `99-epos4.rules` and grants group access. If a device is not found, re-plug it
  and make sure your user is in the `plugdev`/`dialout` group (re-login after a
  group change).

## Finding the serial number

```bash
ros2 run epos_hardware list_available_devices
```
Prints every reachable controller with its **serial number** (hex), which you
put into the URDF below.

## URDF `ros2_control` block

```xml
<ros2_control name="epos" type="system">
  <hardware>
    <plugin>epos_hardware/EposHardware</plugin>
  </hardware>

  <joint name="pan_joint">
    <param name="device_name">EPOS2</param>
    <param name="protocol_stack_name">MAXON SERIAL V2</param>
    <param name="interface_name">USB</param>
    <param name="serial_number">0x00000000XXXXXXXX</param>
    <param name="clear_faults">true</param>
    <param name="encoder_resolution">2048</param>
    <param name="profile_position_velocity">30</param>
    <param name="profile_position_acceleration">50</param>
    <param name="profile_position_deceleration">50</param>
    <param name="profile_velocity_acceleration">50</param>
    <param name="profile_velocity_deceleration">50</param>

    <command_interface name="velocity"/>
    <state_interface name="position"/>
    <state_interface name="velocity"/>
  </joint>

  <transmission name="pan_transmission">
    <plugin>transmission_interface/SimpleTransmission</plugin>
    <actuator name="pan_motor" role="actuator"/>
    <joint name="pan_joint" role="joint">
      <mechanical_reduction>16</mechanical_reduction>
    </joint>
  </transmission>
</ros2_control>
```

### Parameters

| Param | Meaning |
|-------|---------|
| `device_name` | EPOS model string, e.g. `EPOS2` / `EPOS4` |
| `protocol_stack_name` | `MAXON SERIAL V2` (USB) |
| `interface_name` | `USB` |
| `serial_number` | hex serial from `list_available_devices` |
| `clear_faults` | clear EPOS faults on configure |
| `encoder_resolution` | encoder quad-counts per revolution (e.g. 512 CPT → **2048** qc) |
| `profile_*` | profile velocity/accel/decel limits for position & velocity modes |
| `mechanical_reduction` | gearbox ratio (sign = direction) |

## Reference test motor (NEXOS PTU25M)

- Motor: maxon **RE-max** (maxon no. 279980), brushed, GPX32 gearbox **16:1**,
  encoder **512 CPT → 2048 qc/rev**.
- EPOS2 24/5: HW `0x6220`, FW `0x2123`.

> ⚠️ Any `write()`/activation **physically moves the motor**. Ensure the axis is
> free and cleared with the operator before enabling.
