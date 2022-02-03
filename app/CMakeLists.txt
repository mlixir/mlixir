# 현재 디렉토리에 있는 모든 파일을 SRC_FILES 변수에 추가한다.
file(
  GLOB_RECURSE
  SRC_FILES
  CONFIGURE_DEPENDS
  ${CMAKE_CURRENT_LIST_DIR}/*.cc)

set(APP_NAME "${PROJECT_NAME}_app") # mlixir_app
add_executable(${APP_NAME} ${SRC_FILES})

target_include_directories(${APP_NAME} PUBLIC ${CMAKE_SOURCE_DIR}/include)
target_link_libraries(${APP_NAME} PUBLIC ${PROJECT_NAME})

# 실행 파일은 빌드 디렉토리 안에 bin 폴더에 출력
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

add_dependencies(${APP_NAME} ${PROJECT_NAME})
