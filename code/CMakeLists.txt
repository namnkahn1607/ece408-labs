# Auto-discovers code/MP<digit>*/ that contain a CMakeLists.txt. Adding a lab needs no edit here.
file(GLOB lab_dirs CONFIGURE_DEPENDS LIST_DIRECTORIES true
     RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "${CMAKE_CURRENT_SOURCE_DIR}/MP[0-9]*")
foreach(d IN LISTS lab_dirs)
  if(IS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/${d}")
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${d}/CMakeLists.txt")
      add_subdirectory(${d})
    else()
      message(WARNING "labs/${d} has no CMakeLists.txt, skipped")
    endif()
  endif()
endforeach()
