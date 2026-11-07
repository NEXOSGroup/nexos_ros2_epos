cmake_minimum_required(VERSION 3.10)
project(epos_hardware)

# Default to C++14
if(NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 14)
endif()

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# maxon EPOS Command Library + FTDI D2XX are PROPRIETARY and are NOT vendored in
# this repository. Install them system-wide first with the official maxon installer
# (EPOS_Linux_Library/install.sh -> /opt/EposCmdLib_* and symlinks in /usr/lib).
# See docs/BUILD.md and scripts/install_maxon_epos_library.sh.
find_library(EposCmd_LIBRARY NAMES EposCmd
  PATHS /usr/lib /usr/local/lib
        /opt/EposCmdLib_6.8.1.0/lib/v8
        /opt/EposCmdLib_6.8.1.0/lib/v7
        /opt/EposCmdLib_6.8.1.0/lib/v6)
find_library(ftd2xx_LIBRARY NAMES ftd2xx
  PATHS /usr/lib /usr/local/lib
        /opt/EposCmdLib_6.8.1.0/lib/v8
        /opt/EposCmdLib_6.8.1.0/lib/v7
        /opt/EposCmdLib_6.8.1.0/lib/v6)
if(NOT EposCmd_LIBRARY OR NOT ftd2xx_LIBRARY)
  message(FATAL_ERROR
    "maxon EPOS Command Library not found. Install it first (see docs/BUILD.md): "
    "run the official EPOS_Linux_Library/install.sh. "
    "Searched /usr/lib, /usr/local/lib and /opt/EposCmdLib_6.8.1.0.")
endif()
message(STATUS "EposCmd library: ${EposCmd_LIBRARY}")
message(STATUS "ftd2xx library:  ${ftd2xx_LIBRARY}")

find_package(ament_cmake REQUIRED)

find_package(controller_interface REQUIRED)
find_package(controller_manager REQUIRED)
find_package(controller_manager_msgs REQUIRED)
find_package(hardware_interface REQUIRED)
find_package(transmission_interface REQUIRED)
find_package(pluginlib REQUIRED)
find_package(rclcpp_lifecycle REQUIRED)
find_package(lifecycle_msgs REQUIRED)
find_package(rclcpp REQUIRED)

## COMPILE
add_library(EposUtils SHARED src/utils.cpp)
target_include_directories(EposUtils PRIVATE include)
target_link_libraries(EposUtils
  ${ftd2xx_LIBRARY}
  ${EposCmd_LIBRARY}
  hardware_interface::hardware_interface
  rclcpp::rclcpp
)

add_library(${PROJECT_NAME} SHARED src/epos_hardware.cpp)
target_include_directories(${PROJECT_NAME} PRIVATE include)
target_link_libraries(${PROJECT_NAME}
  EposUtils
  hardware_interface::hardware_interface
  transmission_interface::transmission_interface
  rclcpp_lifecycle::rclcpp_lifecycle
  ${lifecycle_msgs_TARGETS}
  pluginlib::pluginlib
  rclcpp::rclcpp
)

add_executable(check_single_device src/check_single_device.cpp)
target_include_directories(check_single_device PRIVATE include)
target_link_libraries(check_single_device EposUtils)

add_executable(list_available_devices src/list_available_devices.cpp)
target_include_directories(list_available_devices PRIVATE include)
target_link_libraries(list_available_devices EposUtils)

pluginlib_export_plugin_description_file(hardware_interface epos_hardware.xml)

# INSTALL
# NOTE: libEposCmd.so / libftd2xx.so are provided system-wide by the maxon
# installer (/usr/lib) and are intentionally NOT installed/redistributed here.
install(TARGETS ${PROJECT_NAME} EposUtils DESTINATION lib)
install(TARGETS check_single_device list_available_devices DESTINATION lib/${PROJECT_NAME})
install(DIRECTORY include/ DESTINATION include)
install(DIRECTORY misc/ DESTINATION lib/)
install(PROGRAMS bin/install_udev_rules DESTINATION lib/${PROJECT_NAME})

## EXPORTS
ament_export_include_directories(include)
ament_export_libraries(${PROJECT_NAME} EposUtils)
ament_export_dependencies(hardware_interface transmission_interface pluginlib rclcpp)

ament_package()
