.git/hooks 참조

이전 파일 백업
#
# pre-commit: auto formatting
#

# color define
RED="\e[0;31m"
END="\e[0m"

# ---- cmake-format ----
CMAKE_FORMAT=`which cmake-format`
if [ "${CMAKE_FORMAT}" = "" ]
then
echo -n "${RED} Can't find cmake-format ${END}.\n"
exit 1
fi
CMAKE_FILES=$(git diff --cached --name-only | grep -e CMakeLists.txt -e *cmake)
if [ "${CMAKE_FILES}" != "" ]
then
${CMAKE_FORMAT} -i ${CMAKE_FILES}
git add ${CMAKE_FILES}
fi

# ---- clang-format ----
CLANG_FORMAT=`which clang-format`
if [ "$CLANG_FORMAT" = "" ]
then
echo -n "${RED} Can't find clang-format ${END}.\n"
exit 1
fi
CXX_FILES_FILTER="\.([chi](pp|xx)|(cc|hh|ii)|[CHI])$"
CXX_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -Ee "${CXX_FILES_FILTER}")
if [ "${CXX_FILES}" != "" ]
then
$CLANG_FORMAT -i -style=file ${CXX_FILES}
git add ${CXX_FILES}
fi