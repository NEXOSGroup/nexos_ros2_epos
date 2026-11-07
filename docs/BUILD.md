# Build — nexos_ros2_epos

Target platform: **Ubuntu 26.04 "Resolute" (arm64)** + **ROS 2 Lyrical Luth**,
tested on a **Raspberry Pi 4**.

## 1. ROS 2 Lyrical + ros2_control

Install ROS 2 Lyrical (see the official docs; the apt source is the
`ros2-apt-source` package for codename `resolute`). Then:

```bash
sudo apt update
sudo apt install -y ros-lyrical-ros-base ros-lyrical-ros2-control ros-dev-tools
echo 'source /opt/ros/lyrical/setup.bash' >> ~/.bashrc
source /opt/ros/lyrical/setup.bash
```

## 2. maxon EPOS Command Library (proprietary — install yourself)

The maxon **EPOS Command Library** (`libEposCmd`) and FTDI **D2XX**
(`libftd2xx`) are **not** part of this repository (license). Obtain the
"EPOS Command Library" for Linux from maxon and install it system-wide with the
bundled wrapper around maxon's official installer:

```bash
scripts/install_maxon_epos_library.sh /path/to/EPOS-Linux-Library-En.zip
```

This runs maxon's `install.sh`, which:
- detects the architecture (`aarch64` → `lib/arm/v8`),
- installs to `/opt/EposCmdLib_<version>/`,
- creates symlinks `/usr/lib/libEposCmd.so` and `/usr/lib/libftd2xx.so`,
- installs udev rules (`99-ftdi.rules`, `99-epos4.rules`) and group access.

> `/tmp` is often mounted `noexec`; the script therefore invokes the installer
> as `sudo bash install.sh` (not `./install.sh`).

Verify:
```bash
ls -l /usr/lib/libEposCmd.so /usr/lib/libftd2xx.so
```

## 3. Build

```bash
mkdir -p ~/ros2_ws/src && cd ~/ros2_ws
git clone https://github.com/NEXOSGroup/nexos_ros2_epos.git src/nexos_ros2_epos
source /opt/ros/lyrical/setup.bash
colcon build --packages-select epos_hardware
source install/setup.bash
```

CMake locates the maxon libraries via `find_library()` in `/usr/lib`,
`/usr/local/lib` and `/opt/EposCmdLib_*`. If they are missing the configure
step fails with a clear error pointing back here.

## ROS 2 Lyrical port notes (hardware_interface 6.x)

Upstream `epos_hardware` targets Humble/Jazzy and does **not** build on Lyrical
out of the box. The changes required (and already applied here) were:

1. **`ament_target_dependencies()` was removed** from `ament_cmake` in Lyrical.
   → replaced with `target_link_libraries()` using namespaced targets
   (`hardware_interface::hardware_interface`, `rclcpp::rclcpp`,
   `transmission_interface::transmission_interface`,
   `rclcpp_lifecycle::rclcpp_lifecycle`, `${lifecycle_msgs_TARGETS}`,
   `pluginlib::pluginlib`). `cmake_minimum_required` bumped to 3.10.

2. **`on_init` signature changed** in `hardware_interface` 6.x:
   `on_init(const HardwareInfo&)` → `on_init(const HardwareComponentInterfaceParams&)`.
   The body still uses the protected `info_` member, which the base
   `SystemInterface::on_init(params)` populates.

With those two changes the package builds **warning-free** on Lyrical. The
`StateInterface(name, iface, double*)` constructors used in
`export_state_interfaces()` are **not** deprecated in 6.10.1, so no interface
model rewrite was necessary.
