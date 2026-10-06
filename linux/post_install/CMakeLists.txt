# Runs after plugin cmake_install includes (added last from linux/CMakeLists.txt).
# libcef.so ships with debug symbols (~1.3G); strip brings it to ~250M.
# Keep locales that match Anx Reader l10n ARBs (+ en-US baseline).
install(CODE "
  set(_lib_dir \"\${CMAKE_INSTALL_PREFIX}/lib\")
  if(EXISTS \"\${_lib_dir}\")
    file(GLOB _sos \"\${_lib_dir}/*.so\" \"\${_lib_dir}/*.so.*\")
    foreach(_so \${_sos})
      execute_process(
        COMMAND strip --strip-unneeded \"\${_so}\"
        ERROR_QUIET
        RESULT_VARIABLE _strip_rc
      )
    endforeach()

    set(_locale_dir \"\${_lib_dir}/locales\")
    if(EXISTS \"\${_locale_dir}\")
      set(_keep
        en-US en-GB
        ar de es fr it ja ko pt pt-BR pt-PT ro ru tr
        zh-CN zh-TW
      )
      file(GLOB _paks \"\${_locale_dir}/*.pak\")
      foreach(_pak \${_paks})
        get_filename_component(_name \"\${_pak}\" NAME_WE)
        string(REGEX REPLACE \"_.*$\" \"\" _base \"\${_name}\")
        list(FIND _keep \"\${_base}\" _idx)
        if(_idx EQUAL -1)
          file(REMOVE \"\${_pak}\")
        endif()
      endforeach()
    endif()
  endif()
" COMPONENT Runtime)
