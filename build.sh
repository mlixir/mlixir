#!/bin/bash -e

set -eo pipefail
# set -x # <- for debug

# ThirdParty Version
FMT_VERSION=8.1.1
SPDLOG_VERSION=1.9.2
BOOST_VERSION=1_78_0
CATCH2_VERSION=2.13.8
OPENSSL_VERSION=3.0.0
X264_VERSION=164 #x264.h -> X264_BUILD
X265_VERSION=3.4
VPX_VERSION=1.11.0
FDKAAC_VERSION=2.0.2
OPUS_VERSION=1.3.1
FFMPEG_VERSION=4.4.1

# variable setting
NCPU=""
OSNAME=""
OSVERSION=""
OSMINORVERSION=""
SUDO=""
CURRENT_DIR="${PWD}"
PREFIX="/usr/local"
SRC_DIR="${CURRENT_DIR}/libdeps/src"
MAKEFLAG=""
BUILD_TYPE="Release"
INCR_INSTALL="true"

# fail exit
function fail_exit() {
	echo "$1"
	cd "${CURRENT_DIR}"
	exit 1
}

function validate_os() {
	# MacOS
	if [[ "$OSTYPE" == "darwin"* ]]; then
		NCPU=$(sysctl -n hw.ncpu)
		OSNAME=$(sw_vers -ProductName)
		OSVERSION=$(sw_vers -ProductVersion)
  else
    NCPU=$(nproc)

    # CentOS, Fedora
    if [ -f /etc/redhat-release ]; then
      OSNAME=$(cat /etc/redhat-release |awk '{print $1}')
      OSVERSION=$(cat /etc/redhat-release |sed s/.*release\ // |sed s/\ .*// | cut -d"." -f1)
    # Ubuntu, Amazon
    elif [ -f /etc/os-release ]; then
      OSNAME=$(cat /etc/os-release | grep "^NAME" | tr -d "\"" | cut -d"=" -f2)
      OSVERSION=$(cat /etc/os-release | grep ^VERSION= | tr -d "\"" | cut -d"=" -f2 | cut -d"." -f1 | awk '{print $s1}')
      OSMINORVERSION=$(cat /etc/os-release | grep ^VERSION= | tr -d "\"" | cut -d"=" -f2 | cut -d"." -f2 | awk '{print $1}')
    fi
	fi

  # validate OS [Ubuntu20.04, macOS]
  if [[ "${OSNAME}" == "Ubuntu" && "${OSVERSION}.${OSMINORVERSION}" != "20.04" ]]; then
  		fail_exit "	${OSNAME} ${OSVERSION}.${OSMINORVERSION} not supproted"
  	elif [[ "${OSNAME}" == "CentOS" ]]; then
  		fail_exit "${OSNAME} ${OSVERSION}.${OSMINORVERSION} not supproted"
  	elif [[ "${OSNAME}" != "macOS" && "${OSNAME}" != "Ubuntu" ]]; then
  		fail_exit "	${OSNAME} ${OSVERSION}.${OSMINORVERSION} not supproted"
  fi

	echo "- ${OSNAME}-${OSVERSION}.${OSMINORVERSION} Supported"
}

# parse args
function parse_args() {
	while [ "$1" != "" ]; do
		case $1 in
			"--debug")
				BUILD_TYPE="debug"
				;;
		esac
		shift
	done
}

# get sudo privilege
function get_privilege() {
	# for no password
	# echo '${user_name} ALL=NOPASSWD: ALL' >> /etc/sudoers
	if [[ ${EUID} -ne 0 ]]; then
		SUDO="sudo -E"
	fi
}

function create_make_flag() {
  MAKEFLAG="${MAKEFLAG} -j${NCPU}" # memory shortage -> set available value
}

# mac install for develop
function install_mac_deps_by_brew() {
  brew update
  brew upgrade

  brew install golang python # for go-task/tap/go-task, pip
  brew install go-task/tap/go-task

  brew install pkg-config automake libtool cmake make # default build tools
  brew install clang-format cppcheck
  brew install doxygen graphviz

  brew install nasm yasm
}

# ubuntu20.04 install
function install_ubuntu_deps_by_apt() {
  ${SUDO} apt update -y
  ${SUDO} apt upgrade -y

  ${SUDO} apt install golang python -y

  ${SUDO} apt install build-essential pkg-config automake libtool cmake make -y
  ${SUDO} apt install clang-format cppcheck clang-tidy -y
  ${SUDO} apt install doxygen xdot -y

  ${SUDO} apt install nasm yasm -y
}

# install pkg from os pkg-manager <- customize package for project
function install_deps_by_pkg_manager() {
	if [ "${OSNAME}" == "Ubuntu" ]; then
		install_ubuntu_deps_by_apt
	elif [ "${OSNAME}" == "macOS" ]; then
		install_mac_deps_by_brew
	else
		fail_exit "Unknown Error"
	fi
}

# ----------------------------------------
# build from source

# openssl -> after build, symlink or export link path need
function install_openssl() {
	echo "- Install OpenSSL"

	local LIST_LIBS=`ls ${PREFIX}/lib/libssl* ${PREFIX}/lib64/libssl* 2>/dev/null`
  $INCR_INSTALL && [[ ! -z ${LIST_LIBS} ]] && echo "- Install OpenSSL - already installed." && return 0

	(DIR=${SRC_DIR}/openssl && \
	mkdir -p ${DIR} && \
	cd ${DIR} && \
	curl -sLf https://github.com/openssl/openssl/archive/refs/tags/openssl-${OPENSSL_VERSION}.tar.gz | tar -xz --strip-components=1 && \
	./config --prefix="${PREFIX}" --openssldir="${PREFIX}" -fPIC -Wl,-rpath,"${PREFIX}/lib" && \
	make ${MAKEFLAG} && \
	${SUDO} make install_sw) || fail_exit "- Install OpenSSL - Failed"
	echo "- Install OpenSSL - Success"
}

# install x264
function install_x264() {
	echo "- Install x264"

	local LIST_LIBS=`ls ${PREFIX}/lib/libx264* ${PREFIX}/lib64/libx264* 2>/dev/null`
	${INCR_INSTALL} && [[ ! -z ${LIST_LIBS} ]] && echo "- Install x264 - already installed." && return 0

	(DIR=${SRC_DIR}/x264 && \
	git clone https://github.com/mirror/x264.git ${DIR} && \
	cd ${DIR} && \
	./configure --prefix="${PREFIX}" --enable-shared --enable-pic --disable-cli && \
	make ${MAKEFLAG} && \
	${SUDO} make install) || fail_exit "- Install x264 - Failed"

	echo "- Install x264 - Success"
}

# install X265
function install_x265() {
	echo "- Install x265"

	local LIST_LIBS=`ls ${PREFIX}/lib/libx265* ${PREFIX}/lib64/libx265* 2>/dev/null`
	${INCR_INSTALL} && [[ ! -z ${LIST_LIBS} ]] && echo "- Install x265 - already installed." && return 0

	(DIR=${SRC_DIR}/x265 && \
	mkdir -p ${DIR} && \
	cd ${DIR} && \
	curl -sLf https://github.com/videolan/x265/archive/${X265_VERSION}.tar.gz | tar -xz --strip-components=1 && \
	cd ${DIR}/build/linux && \
	cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="${PREFIX}" -DENABLE_SHARED:bool=on ../../source && \
	make ${MAKEFLAG} && \
	${SUDO} make install) || fail_exit "- Install x265 - Failed"

	echo "- Install x265 - Success"
}

# install VPX
function install_vpx() {
	echo "- Install vpx"

	if [[ "${OSNAME}" == "macOS" ]]; then
		local ADDITIONAL_FLAG=--target=arm64-darwin20-gcc #x86_64-darwin16-gcc # <- solve ld: --no-undefined error
	fi

	local LIST_LIBS=`ls ${PREFIX}/lib/libvpx* ${PREFIX}/lib64/libvpx* 2>/dev/null`
	${INCR_INSTALL} && [[ ! -z ${LIST_LIBS} ]] && echo "- Install vpx - already installed." && return 0

	(DIR=${SRC_DIR}/vpx && \
	mkdir -p ${DIR} && \
	cd ${DIR} && \
	curl -sLf https://github.com/webmproject/libvpx/archive/refs/tags/v${VPX_VERSION}.tar.gz | tar -xz --strip-components=1 && \
	./configure --prefix="${PREFIX}" --enable-pic --enable-shared --disable-static --disable-debug \
							--disable-examples --disable-docs --disable-install-bins \
							--enable-vp8 --enable-vp9 ${ADDITIONAL_FLAG} && \
	make ${MAKEFLAG} && \
	${SUDO} make install) || fail_exit "- Install vpx - Failed"

	echo "- Install vpx - Success"
}

# install fdkaac
function install_fdkaac() {
	echo "- Install fdkaac"

	local LIST_LIBS=`ls ${PREFIX}/lib/libfdk-aac* ${PREFIX}/lib64/libfdk-aad* 2>/dev/null`
	${INCR_INSTALL} && [[ ! -z ${LIST_LIBS} ]] && echo "- Install fdkaac - already installed." && return 0

	(DIR=${SRC_DIR}/fdkaac && \
	mkdir -p ${DIR} && \
	cd ${DIR} && \
	curl -sLf https://github.com/mstorsjo/fdk-aac/archive/refs/tags/v${FDKAAC_VERSION}.tar.gz | tar -xz --strip-components=1 && \
	autoreconf -fiv && \
	./configure --prefix="${PREFIX}" --enable-shared --disable-static --datadir=/tmp/fdkaac && \
	make ${MAKEFLAG} && \
	${SUDO} make install) || fail_exit "- Install fdkaac - Failed"

	echo "- Install fdkaac - Success"
}

# install opus
function install_opus() {
	echo "- Install opus"

	local LIST_LIBS=`ls ${PREFIX}/lib/libopus* ${PREFIX}/lib64/libopus* 2>/dev/null`
	${INCR_INSTALL} && [[ ! -z ${LIST_LIBS} ]] && echo "- Install opus - already installed." && return 0

	(DIR=${SRC_DIR}/opus && \
	mkdir -p ${DIR} && \
	cd ${DIR} && \
	curl -sLf https://github.com/xiph/opus/archive/refs/tags/v${OPUS_VERSION}.tar.gz | tar -xz --strip-components=1 && \
	autoreconf -fiv && \
	./configure --prefix="${PREFIX}" --enable-shared --disable-static && \
	make ${MAKEFLAG} && \
	${SUDO} make install) || fail_exit "- Install opus - Failed"

  echo "- Install opus - Success"
}

# install FFmpeg
function install_ffmpeg() {
	echo "- Install FFmpeg"

	#	flag save: --enable-libaom --enable-libmp3lame

	local LIST_LIBS=`ls ${PREFIX}/lib/libavformat* ${PREFIX}/lib64/libavformat* 2>/dev/null`
	${INCR_INSTALL} && [[ ! -z ${LIST_LIBS} ]] && echo "- Install FFmpeg - already installed." && return 0

  local	DEBUG_FLAGS=""
	if [ "${BUILD_TYPE}" == "debug" ]; then
		DEBUG_FLAGS+= " --enable-debug=3  --disable-optimizations --disable-mmx --disable-stripping"
	fi

	(DIR=${SRC_DIR}/ffmpeg && \
	mkdir -p ${DIR} && \
	cd ${DIR} && \
	curl -sLf https://github.com/FFmpeg/FFmpeg/archive/refs/tags/n${FFMPEG_VERSION}.tar.gz | tar -xz --strip-components=1 && \
	PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig:${PREFIX}/lib64/pkgconfig:/${PREFIX}/usr/local/lib/pkgconfig:${PKG_CONFIG_PATH} ./configure \
	--prefix="${PREFIX}" \
	--enable-gpl --enable-nonfree --enable-version3 \
	--extra-cflags="-I${PREFIX}/include" \
	--extra-ldflags="-L${PREFIX}/lib -Wl,-rpath,${PREFIX}/lib" \
	--enable-shared --disable-static \
	--enable-openssl \
	--enable-libx264 --enable-libx265 --enable-libvpx \
	--enable-libfdk-aac --enable-libopus \
  ${DEBUG_FLAGS} && \
	make ${MAKEFLAG} && \
	${SUDO} make install) || fail_exit "i- Install FFmpeg - Failed"

	echo "- Install FFmpeg - Success"
}

# install fmtlib/fmt
function install_fmt() {
	echo "- Install fmt"

	local LIST_LIBS=`ls ${PREFIX}/lib/libfmt*  2>/dev/null`
	${INCR_INSTALL} && [[ ! -z ${LIST_LIBS} ]] && echo "- Install fmt - already installed." && return 0

	(DIR=${SRC_DIR}/fmt && \
	mkdir -p ${DIR} && \
	cd ${DIR} && \
	curl -sLf https://github.com/fmtlib/fmt/archive/refs/tags/${FMT_VERSION}.tar.gz | tar -xz --strip-components=1 && \
  mkdir build && cd build && \
  cmake .. -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="${PREFIX}" && \
	make ${MAKEFLAG} && \
	${SUDO} make install) || fail_exit "- Install fmt - Failed"

	echo "- Install fmt - Success"
}

# install spdlog
function install_spdlog() {
	echo "- Install spdlog"

	local LIST_LIBS=`ls ${PREFIX}/lib/libspdlog*  2>/dev/null`
	${INCR_INSTALL} && [[ ! -z ${LIST_LIBS} ]] && echo "- Install spdlog - already installed." && return 0

	(DIR=${SRC_DIR}/spdlog && \
	mkdir -p ${DIR} && \
	cd ${DIR} && \
	curl -sLf https://github.com/gabime/spdlog/archive/refs/tags/v${SPDLOG_VERSION}.tar.gz | tar -xz --strip-components=1 && \
  mkdir build && cd build && \
  cmake .. -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="${PREFIX}" && \
	make ${MAKEFLAG} && \
	${SUDO} make install) || fail_exit "- Install spdlog - Failed"

	echo "- Install spdlog - Success"
}

# install boost
function install_boost() {
	echo "- Install boost"

	local LIST_LIBS=`ls ${PREFIX}/lib/libboost* 2>/dev/null`
	${INCR_INSTALL} && [[ ! -z ${LIST_LIBS} ]] && echo "- Install boost - already installed." && return 0

  #@options: 빌드가 필요한 라이브러리 중 사용할 라이브러리만 선택 -> ./b2 --show-libraries
  local BOOST_LIBRARIES="--with-program_options --with-coroutine"

	(DIR=${SRC_DIR}/boost && \
	mkdir -p ${DIR} && \
	cd ${DIR} && \
	curl -sLf https://boostorg.jfrog.io/artifactory/main/release/1.78.0/source/boost_${BOOST_VERSION}.tar.gz | tar -xz --strip-components=1 && \
  ./bootstrap.sh --prefix=${PREFIX} && \
  ${SUDO} ./b2 ${BOOST_LIBRARIES} install) || fail_exit "-Install boost - Failed"

  echo "- Install boost - Success"
}

# install catch2
function install_catch2() {
	echo "- Install catch2"

	local LIST_LIBS=`ls ${PREFIX}/include/catch2/catch* 2>/dev/null`
	${INCR_INSTALL} && [[ ! -z ${LIST_LIBS} ]] && echo "- Install catch2 - already installed." && return 0

	(DIR=${SRC_DIR}/Catch2 && \
	mkdir -p ${DIR} && \
	cd ${DIR} && \
	curl -sLf https://github.com/catchorg/Catch2/archive/refs/tags/v${CATCH2_VERSION}.tar.gz | tar -xz --strip-components=1 && \
  cmake -S. -Bbuild -DBUILD_TESTING=OFF -DCMAKE_INSTALL_PREFIX=${PREFIX} && \
  ${SUDO} cmake --build build --target install) || fail_exit "-Install catch2 - Failed"

  echo "- Install catch2 - Success"
}

# ----------------------------------------

# start script
validate_os
parse_args $*
get_privilege
create_make_flag

install_deps_by_pkg_manager

# added
install_boost
install_fmt # <- use spdlog bundled fmt
install_spdlog
install_catch2

install_openssl
install_x264
install_x265
install_vpx
install_fdkaac
install_opus
install_ffmpeg
