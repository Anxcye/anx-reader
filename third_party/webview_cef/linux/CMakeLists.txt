# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

#supass warning
cmake_policy(SET CMP0074 NEW)

# Project-level configuration.
set(PROJECT_NAME "webview_cef")
project(${PROJECT_NAME} LANGUAGES CXX C)
# CEF 149 public headers require C++20.
set(CMAKE_CXX_STANDARD 20)

# Auto setup Linux target
execute_process(
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/target_modifier/modify_target.sh"
  OUTPUT_VARIABLE patch_output
)
message(WARNING "${patch_output}")

# Setup CEF
include(${CMAKE_CURRENT_SOURCE_DIR}/../third/download.cmake)
prepare_prebuilt_files(${CMAKE_CURRENT_SOURCE_DIR}/../third/cef)

set(CEF_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../third/cef")
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CEF_ROOT}/cmake")
find_package(CEF REQUIRED)

# This value is used when generating builds using this plugin, so it must
# not be changed.
set(PLUGIN_NAME "webview_cef_plugin")

# Define the plugin library target. Its name must not be changed (see comment
# on PLUGIN_NAME above).
#
# Any new source files that you add to the plugin should be added here.
add_library(${PLUGIN_NAME} SHARED
  "webview_cef_plugin.cc"
  "webview_cef_keyevent.h"
  "webview_cef_texture.h"
  "${CMAKE_CURRENT_SOURCE_DIR}/../common/webview_app.cc"
  "${CMAKE_CURRENT_SOURCE_DIR}/../common/webview_app.h"
  "${CMAKE_CURRENT_SOURCE_DIR}/../common/webview_handler.cc"
  "${CMAKE_CURRENT_SOURCE_DIR}/../common/webview_handler.h"
  "${CMAKE_CURRENT_SOURCE_DIR}/../common/webview_plugin.cc"
  "${CMAKE_CURRENT_SOURCE_DIR}/../common/webview_plugin.h"
  "${CMAKE_CURRENT_SOURCE_DIR}/../common/webview_value.cc"
  "${CMAKE_CURRENT_SOURCE_DIR}/../common/webview_value.h"
  "${CMAKE_CURRENT_SOURCE_DIR}/../common/webview_js_handler.cc"
  "${CMAKE_CURRENT_SOURCE_DIR}/../common/webview_js_handler.h"
  "${CMAKE_CURRENT_SOURCE_DIR}/../common/webview_cookieVisitor.cc"
  "${CMAKE_CURRENT_SOURCE_DIR}/../common/webview_cookieVisitor.h"
)

# Apply a standard set of build settings that are configured in the
# application-level CMakeLists.txt. This can be removed for plugins that want
# full control over build settings.
apply_standard_settings(${PLUGIN_NAME})

# Symbols are hidden by default to reduce the chance of accidental conflicts
# between plugins. This should not be removed; any symbols that should be
# exported should be explicitly exported with the FLUTTER_PLUGIN_EXPORT macro.
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

# Source include directories and library dependencies. Add any plugin-specific
# dependencies here.
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GTK)

target_include_directories(${PLUGIN_NAME} PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/../common")

#########################################cef#########################################
set(CEF_TARGET ${PLUGIN_NAME})
ADD_LOGICAL_TARGET("libcef_lib" "${CEF_LIB_DEBUG}" "${CEF_LIB_RELEASE}")
SET_CEF_TARGET_OUT_DIR()
add_subdirectory(${CEF_LIBCEF_DLL_WRAPPER_PATH} libcef_dll_wrapper)

# Find required libraries and update compiler/linker variables.
FIND_LINUX_LIBRARIES("gmodule-2.0 gtk+-3.0 gthread-2.0 gtk+-unix-print-3.0 xi")

find_program(XCLIP_EXECUTABLE xclip)
if(NOT XCLIP_EXECUTABLE)
  message(AUTHOR_WARNING "xclip executable not found. Users need it to paste text into CEF Area.")
endif()

# Executable target.
# add_executable(${CEF_TARGET} ${CEFCLIENT_SRCS})
SET_EXECUTABLE_TARGET_PROPERTIES(${CEF_TARGET})
add_dependencies(${CEF_TARGET} libcef_dll_wrapper)
target_link_libraries(${CEF_TARGET} PUBLIC libcef_lib libcef_dll_wrapper "GL" ${CEF_STANDARD_LIBS})

# Set rpath so that libraries can be placed next to the executable.
set_target_properties(${CEF_TARGET} PROPERTIES INSTALL_RPATH "$ORIGIN")
set_target_properties(${CEF_TARGET} PROPERTIES BUILD_WITH_INSTALL_RPATH TRUE)
set_target_properties(${CEF_TARGET} PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CEF_TARGET_OUT_DIR})

# We don't call deprecated GTK functions, and they can cause build failures, so disable them.
add_definitions("-DGTK_DISABLE_DEPRECATED")

# Set SUID permissions on the chrome-sandbox target.
# SET_LINUX_SUID_PERMISSIONS("${CEF_TARGET}" "${CEF_TARGET_OUT_DIR}/chrome-sandbox")


# Init INSTALL_BUNDLE_APPLICATION_DIR_WEBVIEW_CEV that contains the build dir of the application
set(INSTALL_BUNDLE_APPLICATION_DIR_WEBVIEW_CEV "${PROJECT_BINARY_DIR}")
get_filename_component(INSTALL_BUNDLE_APPLICATION_DIR_WEBVIEW_CEV "${INSTALL_BUNDLE_APPLICATION_DIR_WEBVIEW_CEV}" DIRECTORY)
get_filename_component(INSTALL_BUNDLE_APPLICATION_DIR_WEBVIEW_CEV "${INSTALL_BUNDLE_APPLICATION_DIR_WEBVIEW_CEV}" DIRECTORY)
set(INSTALL_BUNDLE_APPLICATION_DIR_WEBVIEW_CEV "${INSTALL_BUNDLE_APPLICATION_DIR_WEBVIEW_CEV}/bundle/lib")


#set CEF binary and resource files which need to copy to the target output directory
set(cef_library_list "")
foreach(FILE ${CEF_BINARY_FILES})
  list(APPEND cef_library_list ${CEF_BINARY_DIR}/${FILE})
endforeach()

foreach(FILE ${CEF_RESOURCE_FILES})
  # If ${FILE} is a directory (e.g. locales), install them directly.
  # Avoids error with the Linux target CMakeList
  if(IS_DIRECTORY ${CEF_RESOURCE_DIR}/${FILE})
    file(GLOB LOCAL_FILES "${CEF_RESOURCE_DIR}/${FILE}/*")
    foreach(LOCAL_FILE ${LOCAL_FILES})
      install(FILES "${LOCAL_FILE}"
              DESTINATION "${INSTALL_BUNDLE_APPLICATION_DIR_WEBVIEW_CEV}/${FILE}"
              COMPONENT Runtime)
    endforeach()
  else()
    # If ${FILE} is not a directory, treat it normally
    list(APPEND cef_library_list ${CEF_RESOURCE_DIR}/${FILE})
  endif()
endforeach(FILE)
#######################################cef end#######################################

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(webview_cef_bundled_libraries
  ""
  ${cef_library_list}
  PARENT_SCOPE
)
