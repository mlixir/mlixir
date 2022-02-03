#
# unit-tests
#
include(CTest)

# cmake --build build --target tests
add_custom_target(
  ctest
  COMMAND ctest
  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/tests)

# add catch2 unit-test example
add_catch2_target("catch2_group_1" "catch2_example")

# Note
# - Create test folder
# - add test target
#add_catch2_target("library_test" "fmt_test")
#add_catch2_target("library_test" "spdlog_test")
