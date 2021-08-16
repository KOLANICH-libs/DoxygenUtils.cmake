#[=======================================================================[.rst:

DoxygenUtils
------------

Unlicense
^^^^^^^^^

This is free and unencumbered software released into the public domain.
Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.
In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
For more information, please refer to <https://unlicense.org/>

Upstreming
^^^^^^^^^^

https://github.com/Kitware/CMake/pull/342

Functions
^^^^^^^^^
.. command:: load_doxyfile

  .. versionadded:: 3.22

  Does crude regexp-based parsing of a Doxyfile, importing all its options as
  DOXYGEN_ variables.

  ::

    load_doxyfile(targetName)

  This function unsets some variables (``DOXYGEN_INPUT`` in example) that
  must not be set when Doxygen is used via this module.

.. command:: doxygen_use_clang_for_target

  .. versionadded:: 3.22

  Sets up CMake variables configuring Doxygen to use Clang for parsing of C++
  sources. Gives better results (i.e. better syntax highlighting and better
  graph analysis) but is slower

  ::

    doxygen_use_clang_for_target(targetName)

  It basically extracts the info about includes and flags and sets them
  into the flag for Clang options.

.. command:: doxygen_document_target

  .. versionadded:: 3.22

  Generates docs for a target. ``childTargetName`` is the name of a target
  for docs generation. ``targetName`` is the name of a target to be documented.
  ``formats`` is a list of formats to generate docs (the list of allowed
  formats can be found in ``_DOXYGEN_AVAILABLE_FORMATS``).

  ::

    doxygen_document_target(childTargetName targetName formats)

  If the compiler used for building is Clang, it also enables Clang-assisted parsing.
#]=======================================================================]


function(load_doxyfile DoxyfilePath)
	file(STRINGS "${DoxyfilePath}" f)
	foreach(line ${f})
		#message(STATUS "line ${line}")
		if(line MATCHES "^([a-zA-Z0-9_]+) *= *(.+)$")
			set(nm "${CMAKE_MATCH_1}")
			set(val "${CMAKE_MATCH_2}")
			#message(STATUS "MATCH ${nm} = ${val}")
			set("DOXYGEN_${nm}" "${val}" PARENT_SCOPE)
		endif()
	endforeach()
	unset(DOXYGEN_INPUT PARENT_SCOPE)
	unset(DOXYGEN_OUTPUT_DIRECTORY PARENT_SCOPE)
endfunction()

function(doxygen_use_clang_for_target targetName)
	set(CMAKE_EXPORT_COMPILE_COMMANDS ON PARENT_SCOPE)
	set(DOXYGEN_CLANG_ASSISTED_PARSING YES PARENT_SCOPE)

	get_target_property(tgtType "${targetName}" TYPE)
	if(tgtType STREQUAL "INTERFACE_LIBRARY")
	else()
		get_target_property(flagz "${targetName}" COMPILE_FLAGS)
		get_target_property(includes "${targetName}" INCLUDE_DIRECTORIES)
		if(includes)
			list(JOIN includes " -I" includes)
			set(includes "-I${includes}")
		endif()
	endif()

	set(DOXYGEN_CLANG_OPTIONS "${flagz} ${includes}" PARENT_SCOPE)
	set(DOXYGEN_CLANG_DATABASE_PATH "${CMAKE_CURRENT_BINARY_DIR}" PARENT_SCOPE)
endfunction()

set("_DOXYGEN_AVAILABLE_FORMATS" "HTML;DOCSET;HTMLHELP;LATEX;RTF;MAN;XML;DOCBOOK;AUTOGEN_DEF;PERLMOD")

function(doxygen_document_target childTargetName targetName formats)
	string(TOUPPER "${formats}" formats)
	foreach(f ${_DOXYGEN_AVAILABLE_FORMATS})
		if("${f}" IN_LIST formats)
			set("DOXYGEN_GENERATE_${f}" YES)
		else()
			set("DOXYGEN_GENERATE_${f}" NO)
		endif()
	endforeach()

	if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
		message(STATUS "Compiler is Clang, enabling Clang-assisted parsing in Doxygen.")
		doxygen_use_clang_for_target("${targetName}")
		set(CMAKE_EXPORT_COMPILE_COMMANDS "${CMAKE_EXPORT_COMPILE_COMMANDS}" PARENT_SCOPE)
	endif()

	set(DOXYGEN_EXAMPLE_PATH "./demo")

	get_target_property(tgtType "${targetName}" TYPE)
	if(tgtType STREQUAL "INTERFACE_LIBRARY")
	else()
		get_target_property(srcz "${targetName}" SOURCES)
		if(srcz STREQUAL "srcz-NOTFOUND")
			set(srcz "")
		endif()
		get_target_property(srcDir "${targetName}" SOURCE_DIR)
		if(srcDir STREQUAL "srcDir-NOTFOUND")
			set(srcDir "")
		endif()
	endif()

	get_target_property(includes "${targetName}" INTERFACE_INCLUDE_DIRECTORIES)
	if(includes STREQUAL "includes-NOTFOUND")
		set(includes "")
	else()
		file(GLOB_RECURSE header_files "${includes}/*")
	endif()

	get_target_property(ifc_srcs "${targetName}" INTERFACE_SOURCES)
	if(ifc_srcs STREQUAL "ifc_srcs-NOTFOUND")
		set(ifc_srcs "")
	endif()

	set(DOXYGEN_STRIP_FROM_PATH "${includes};${srcDir}")
	set(DOXYGEN_STRIP_FROM_INC_PATH "${includes};${srcDir}")

	doxygen_add_docs("${childTargetName}"
		ALL
		USE_STAMP_FILE
		"${srcz}"
		"${ifc_srcs}"
		"${header_files}"
	)
endfunction()
