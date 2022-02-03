#
# enable cache if available
#   mac: ccache, sccache install need
#
function(enable_cache)
  set(CACHE_OPTION
      "ccache"
      CACHE STRING "Compiler cache to be used")
  set(CACHE_OPTION_VALUES "ccache" "sccache")
  set_property(CACHE CACHE_OPTION PROPERTY STRINGS ${CACHE_OPTION_VALUES})
  list(
    FIND
    CACHE_OPTION_VALUES
    ${CACHE_OPTION}
    CACHE_OPTION_INDEX)

  if(${CACHE_OPTION_INDEX} EQUAL -1)
    message(
      STATUS
        "Using custom compiler cache system: '${CACHE_OPTION}', explicitly supported entries are ${CACHE_OPTION_VALUES}"
    )
  endif()

  #XXX find_program(CACHE_BINARY ${CACHE_OPTION})
  find_program(CACHE_BINARY NAMES ${CACHE_OPTION_VALUES})
  if(CACHE_BINARY)
    message(STATUS "${CACHE_BINARY} found and enabled")
    set(CMAKE_CXX_COMPILER_LAUNCHER
        ${CACHE_BINARY}
        CACHE FILEPATH "compiler cache used")
  else()
    message(WARNING "${CACHE_OPTION} is enabled but was not found. Not using it")
  endif()
endfunction()
