### CMakeLists automatically created with AutoVala
### Do not edit

project (rss_vala)
cmake_minimum_required (VERSION 2.6)
cmake_policy (VERSION 2.8)
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
enable_testing ()
option(ICON_UPDATE "Update the icon cache after installing" ON)
option(BUILD_VALADOC "Build API documentation if Valadoc is available" OFF)
option(DEBUG "DEBUG" OFF)

include(GNUInstallDirs)
if( ( ${CMAKE_INSTALL_PREFIX} MATCHES "^/usr/local" ) )
	# A workaround to ensure that works 'out of the box' in Debian-based systems
	set(CMAKE_INSTALL_LIBDIR lib)
endif()

set(HAVE_VALADOC OFF)
if(BUILD_VALADOC)
	find_package(Valadoc)
	if(VALADOC_FOUND)
		set(HAVE_VALADOC ON)
		include(Valadoc)
	else()
		message("Valadoc not found, will not build documentation")
	endif()
endif()

find_package(PkgConfig)

set(MODULES_TO_CHECK ${MODULES_TO_CHECK} gee-0.8)
set(MODULES_TO_CHECK ${MODULES_TO_CHECK} gio-2.0)
set(MODULES_TO_CHECK ${MODULES_TO_CHECK} glib-2.0)
set(MODULES_TO_CHECK ${MODULES_TO_CHECK} gobject-2.0)
set(MODULES_TO_CHECK ${MODULES_TO_CHECK} libsoup-2.4)

pkg_check_modules(DEPS REQUIRED ${MODULES_TO_CHECK})

add_subdirectory(src)
add_subdirectory(po)
