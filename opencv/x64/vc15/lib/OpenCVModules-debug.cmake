#----------------------------------------------------------------
# Generated CMake target import file for configuration "Debug".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "opencv_core" for configuration "Debug"
set_property(TARGET opencv_core APPEND PROPERTY IMPORTED_CONFIGURATIONS DEBUG)
set_target_properties(opencv_core PROPERTIES
  IMPORTED_IMPLIB_DEBUG "${_IMPORT_PREFIX}/x64/vc15/lib/opencv_core331d.lib"
  IMPORTED_LOCATION_DEBUG "${_IMPORT_PREFIX}/x64/vc15/bin/opencv_core331d.dll"
  )

list(APPEND _IMPORT_CHECK_TARGETS opencv_core )
list(APPEND _IMPORT_CHECK_FILES_FOR_opencv_core "${_IMPORT_PREFIX}/x64/vc15/lib/opencv_core331d.lib" "${_IMPORT_PREFIX}/x64/vc15/bin/opencv_core331d.dll" )

# Import target "opencv_imgproc" for configuration "Debug"
set_property(TARGET opencv_imgproc APPEND PROPERTY IMPORTED_CONFIGURATIONS DEBUG)
set_target_properties(opencv_imgproc PROPERTIES
  IMPORTED_IMPLIB_DEBUG "${_IMPORT_PREFIX}/x64/vc15/lib/opencv_imgproc331d.lib"
  IMPORTED_LOCATION_DEBUG "${_IMPORT_PREFIX}/x64/vc15/bin/opencv_imgproc331d.dll"
  )

list(APPEND _IMPORT_CHECK_TARGETS opencv_imgproc )
list(APPEND _IMPORT_CHECK_FILES_FOR_opencv_imgproc "${_IMPORT_PREFIX}/x64/vc15/lib/opencv_imgproc331d.lib" "${_IMPORT_PREFIX}/x64/vc15/bin/opencv_imgproc331d.dll" )

# Import target "opencv_ml" for configuration "Debug"
set_property(TARGET opencv_ml APPEND PROPERTY IMPORTED_CONFIGURATIONS DEBUG)
set_target_properties(opencv_ml PROPERTIES
  IMPORTED_IMPLIB_DEBUG "${_IMPORT_PREFIX}/x64/vc15/lib/opencv_ml331d.lib"
  IMPORTED_LOCATION_DEBUG "${_IMPORT_PREFIX}/x64/vc15/bin/opencv_ml331d.dll"
  )

list(APPEND _IMPORT_CHECK_TARGETS opencv_ml )
list(APPEND _IMPORT_CHECK_FILES_FOR_opencv_ml "${_IMPORT_PREFIX}/x64/vc15/lib/opencv_ml331d.lib" "${_IMPORT_PREFIX}/x64/vc15/bin/opencv_ml331d.dll" )

# Import target "opencv_photo" for configuration "Debug"
set_property(TARGET opencv_photo APPEND PROPERTY IMPORTED_CONFIGURATIONS DEBUG)
set_target_properties(opencv_photo PROPERTIES
  IMPORTED_IMPLIB_DEBUG "${_IMPORT_PREFIX}/x64/vc15/lib/opencv_photo331d.lib"
  IMPORTED_LOCATION_DEBUG "${_IMPORT_PREFIX}/x64/vc15/bin/opencv_photo331d.dll"
  )

list(APPEND _IMPORT_CHECK_TARGETS opencv_photo )
list(APPEND _IMPORT_CHECK_FILES_FOR_opencv_photo "${_IMPORT_PREFIX}/x64/vc15/lib/opencv_photo331d.lib" "${_IMPORT_PREFIX}/x64/vc15/bin/opencv_photo331d.dll" )

# Import target "opencv_imgcodecs" for configuration "Debug"
set_property(TARGET opencv_imgcodecs APPEND PROPERTY IMPORTED_CONFIGURATIONS DEBUG)
set_target_properties(opencv_imgcodecs PROPERTIES
  IMPORTED_IMPLIB_DEBUG "${_IMPORT_PREFIX}/x64/vc15/lib/opencv_imgcodecs331d.lib"
  IMPORTED_LOCATION_DEBUG "${_IMPORT_PREFIX}/x64/vc15/bin/opencv_imgcodecs331d.dll"
  )

list(APPEND _IMPORT_CHECK_TARGETS opencv_imgcodecs )
list(APPEND _IMPORT_CHECK_FILES_FOR_opencv_imgcodecs "${_IMPORT_PREFIX}/x64/vc15/lib/opencv_imgcodecs331d.lib" "${_IMPORT_PREFIX}/x64/vc15/bin/opencv_imgcodecs331d.dll" )

# Import target "opencv_highgui" for configuration "Debug"
set_property(TARGET opencv_highgui APPEND PROPERTY IMPORTED_CONFIGURATIONS DEBUG)
set_target_properties(opencv_highgui PROPERTIES
  IMPORTED_IMPLIB_DEBUG "${_IMPORT_PREFIX}/x64/vc15/lib/opencv_highgui331d.lib"
  IMPORTED_LOCATION_DEBUG "${_IMPORT_PREFIX}/x64/vc15/bin/opencv_highgui331d.dll"
  )

list(APPEND _IMPORT_CHECK_TARGETS opencv_highgui )
list(APPEND _IMPORT_CHECK_FILES_FOR_opencv_highgui "${_IMPORT_PREFIX}/x64/vc15/lib/opencv_highgui331d.lib" "${_IMPORT_PREFIX}/x64/vc15/bin/opencv_highgui331d.dll" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
