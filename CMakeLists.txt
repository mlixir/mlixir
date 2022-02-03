#
# cmake project
#
cmake_minimum_required(VERSION 3.16)
project(
  mlixir
  VERSION 0.1.0
  DESCRIPTION "${PROJECT_NAME} Project"
  LANGUAGES CXX)
string(TOLOWER ${PROJECT_NAME} PROJECT_NAME_LOWERCASE)
string(TOUPPER ${PROJECT_NAME} PROJECT_NAME_UPPERCASE)
configure_file(${PROJECT_SOURCE_DIR}/version.h.in ${PROJECT_SOURCE_DIR}/include/${PROJECT_NAME}/version.h)
message(STATUS "Start CMake ... Generate ${PROJECT_NAME} v${PROJECT_VERSION}")

# set target cxx standard
set(CMAKE_CXX_STANDARD 17) # <- change to wanted standard version [14, 17, 20, Latest)

# include program_options
include(${PROJECT_SOURCE_DIR}/cmake/program_options/index.cmake)

# select options
project_options(
  WARNINGS_AS_ERRORS # Treat compiler warnings as errors
  # ENABLE_CPPCHECK # Enable static analysis with cppcheck
  # ENABLE_CLANG_TIDY # Enable static analysis with clang-tidy
  # ENABLE_COVERAGE # Enable coverage reporting for gcc/clang
  # ENABLE_CACHE # Enable cache if available
  ENABLE_DOXYGEN # Enable doxygen doc builds of source
  # ENABLE_IPO # Enable Interprocedural Optimization, aka Link Time Optimization
  # ENABLE_BUILD_WITH_TIME_TRACE # Enable -ftime-trace to generate time tracing .json files on clang
  # ENABLE_SANITIZER_ADDRESS # Enable address sanitizer
  # ENABLE_SANITIZER_LEAK # Enable leak sanitizer
  # ENABLE_SANITIZER_UNDEFINED_BEHAVIOR # Enable undefined behavior sanitizer
  # ENABLE_SANITIZER_THREAD # Enable thread sanitizer
  # ENABLE_SANITIZER_MEMORY # Enable memory sanitizer
  ENABLE_UNIT_TEST_CATCH2 # Enable Catch2
)

# include dependency_options
include(${PROJECT_SOURCE_DIR}/cmake/dependency_options/index.cmake)
dependency_options(
  BOOST
  SPDLOG
  FFMPEG
)

# create libary
add_subdirectory(lib)

# create app
add_subdirectory(app)

# create test
add_subdirectory(tests)
