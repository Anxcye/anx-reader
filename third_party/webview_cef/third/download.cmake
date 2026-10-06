# Official CEF "Standard Distribution" from the Spotify automated builds CDN
# (https://cef-builds.spotifycdn.com). All platforms are kept on the same
# CEF/Chromium version. To bump CEF, change CEF_VERSION below.
set(CEF_CDN "https://cef-builds.spotifycdn.com")
set(CEF_VERSION "149.0.4+g2f1bfd8+chromium-149.0.7827.156")

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    message(WARNING "current system is Linux")
    if(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "aarch64")
        set(cef_prebuilt_version "cef_binary_${CEF_VERSION}_linuxarm64.tar.bz2")
    else()
        set(cef_prebuilt_version "cef_binary_${CEF_VERSION}_linux64.tar.bz2")
    endif()
elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    message(WARNING "current system is Windows")
    # Use the official CEF standard distribution and build libcef_dll_wrapper
    # from source (see windows/CMakeLists.txt), the same way Linux does.
    set(cef_prebuilt_version "cef_binary_${CEF_VERSION}_windows64.tar.bz2")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    message(WARNING "current system is macOS")
    if(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "arm64")
        set(cef_prebuilt_version "cef_binary_${CEF_VERSION}_macosarm64.tar.bz2")
    else()
        set(cef_prebuilt_version "cef_binary_${CEF_VERSION}_macosx64.tar.bz2")
    endif()
endif()

# The CDN path requires '+' to be percent-encoded as %2B.
string(REPLACE "+" "%2B" cef_prebuilt_url_name "${cef_prebuilt_version}")
set(cef_prebuilt_path "${CEF_CDN}/${cef_prebuilt_url_name}")


function(extract_file filename extract_dir)
    message(WARNING "${filename} will extract to ${extract_dir} ...")

    set(temp_dir ${CMAKE_BINARY_DIR}/tmp_for_extract.dir)
    if(EXISTS ${temp_dir})
        file(REMOVE_RECURSE ${temp_dir})
    endif()
    file(MAKE_DIRECTORY ${temp_dir})
    execute_process(COMMAND ${CMAKE_COMMAND} -E tar -xf ${filename}
            WORKING_DIRECTORY ${temp_dir})

    file(GLOB contents "${temp_dir}/*")
    list(LENGTH contents n)
    if(NOT n EQUAL 1 OR NOT IS_DIRECTORY "${contents}")
        set(contents "${temp_dir}")
    endif()

    get_filename_component(contents ${contents} ABSOLUTE)

    file(INSTALL "${contents}/" DESTINATION ${extract_dir})

    file(REMOVE_RECURSE ${temp_dir})
endfunction()

function(download_file url filename)
    message(WARNING "Downloading ${filename} from ${url}")
    file(DOWNLOAD ${url} ${filename} STATUS SHOW_PROGRESS)
endfunction(download_file)

function(prepare_prebuilt_files filepath)
    set(need_download FALSE)

    if(NOT EXISTS ${filepath})
        message(WARNING "No ${filepath} found")
        set(need_download TRUE)
    else()
        if(NOT EXISTS ${filepath}/version.txt)
            message(WARNING "No ${filepath}/version.txt found")
            set(need_download TRUE)
        else()
            file(READ ${filepath}/version.txt local_version)
            if(local_version STREQUAL cef_prebuilt_version)
                message(WARNING "No need to update ${filepath}")
            else()
                set(need_download TRUE)
            endif()
            file(REMOVE_RECURSE ${filepath}/new_version.txt)
        endif()
    endif()

    if(need_download)
        message(WARNING "Need to update ${filepath}")
        file(REMOVE_RECURSE ${filepath}/cmake ${filepath}/Debug ${filepath}/Release ${filepath}/Resources ${filepath}/libcef_dll ${filepath}/libcef_dll_wrapper ${filepath}/include)
        # Also remove the legacy lower-case layout from the old custom Windows package.
        file(REMOVE_RECURSE ${filepath}/debug ${filepath}/release ${filepath}/resources)
        download_file(${cef_prebuilt_path} ${CMAKE_CURRENT_SOURCE_DIR}/prebuilt.zip)
        file(MAKE_DIRECTORY ${filepath})
        extract_file(${CMAKE_CURRENT_SOURCE_DIR}/prebuilt.zip ${filepath})

        ## Needed for making it run on arm64 Linux (makes it check for arm64 or aarch64 instead of just arm64)
        if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
            execute_process(
                COMMAND sed -i "s/\"\\\${CMAKE_HOST_SYSTEM_PROCESSOR}\" STREQUAL \"arm64\"/(\"\\\${CMAKE_HOST_SYSTEM_PROCESSOR}\" STREQUAL \"arm64\" OR \"\\\${CMAKE_HOST_SYSTEM_PROCESSOR}\" STREQUAL \"aarch64\")/" ${filepath}/cmake/cef_variables.cmake
                WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            )
        endif()

        file(WRITE "${filepath}/version.txt" "${cef_prebuilt_version}")
        file(REMOVE_RECURSE ${CMAKE_CURRENT_SOURCE_DIR}/prebuilt.zip)
    endif()
endfunction(prepare_prebuilt_files)
