### CMakeLists automatically created with AutoVala
### Do not edit

set (DATADIR "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_DATAROOTDIR}")
set (PKGDATADIR "${DATADIR}/rss_vala")
set (GETTEXT_PACKAGE "rss_vala")
set (RELEASE_NAME "rss_vala")
set (CMAKE_C_FLAGS "")
set (PREFIX ${CMAKE_INSTALL_PREFIX})
set (VERSION "0.1")
set (TESTSRCDIR "${CMAKE_SOURCE_DIR}")
set (DOLLAR "$")

configure_file (${CMAKE_SOURCE_DIR}/src/Config.vala.cmake ${CMAKE_BINARY_DIR}/src/Config.vala)
add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")
set (VERSION "0.1")
add_definitions (${DEPS_CFLAGS})
link_libraries ( ${DEPS_LIBRARIES} )
link_directories ( ${DEPS_LIBRARY_DIRS} )
find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.24" MINIMUM)
include (ValaPrecompile)

set (VALA_PACKAGES ${VALA_PACKAGES} posix)
set (VALA_PACKAGES ${VALA_PACKAGES} gee-0.8)
set (VALA_PACKAGES ${VALA_PACKAGES} gio-2.0)
set (VALA_PACKAGES ${VALA_PACKAGES} glib-2.0)
set (VALA_PACKAGES ${VALA_PACKAGES} gobject-2.0)
set (VALA_PACKAGES ${VALA_PACKAGES} libsoup-2.4)

set (APP_SOURCES ${APP_SOURCES} ${CMAKE_CURRENT_BINARY_DIR}/Config.vala)
set (APP_SOURCES ${APP_SOURCES} configuration.vala)
set (APP_SOURCES ${APP_SOURCES} nameparser.vala)
set (APP_SOURCES ${APP_SOURCES} rss_file.vala)
set (APP_SOURCES ${APP_SOURCES} rss_vala.vala)
set (APP_SOURCES ${APP_SOURCES} transmission_control.vala)
set (APP_SOURCES ${APP_SOURCES} xml.vala)

if (DEBUG)
	set (COMPILE_OPTIONS ${COMPILE_OPTIONS} -D DEBUG)
endif ()
if (DEBUG)
	set (COMPILE_OPTIONS ${COMPILE_OPTIONS} -g )
endif ()


if (DEBUG)
	set (CMAKE_C_FLAGS ${CMAKE_C_FLAGS} " -g " )
endif ()


vala_precompile(VALA_C rss_vala
	${APP_SOURCES}
PACKAGES
	${VALA_PACKAGES}
OPTIONS
	${COMPILE_OPTIONS}
)

add_executable(rss_vala ${VALA_C})

install(TARGETS
	rss_vala
RUNTIME DESTINATION
	${CMAKE_INSTALL_BINDIR}/
)

if(HAVE_VALADOC)
	valadoc(rss_vala
		${CMAKE_BINARY_DIR}/valadoc/rss_vala
		${APP_SOURCES}
	PACKAGES
		${VALA_PACKAGES}
	CUSTOM_VAPIS
		${CUSTOM_VAPIS_LIST}
	)
	install(DIRECTORY
		${CMAKE_BINARY_DIR}/valadoc
	DESTINATION
		${CMAKE_INSTALL_DATAROOTDIR}/doc/rss_vala
	)
endif()
