### CppStater

# mlixir project

## Getting Started

## Dependencies
./build.sh

#### Todo
* git hooks
  * add hook to ${PROJECT_SOURCE_DIR}/hooks}
* git workflow

## Issue
*Ubuntu20.04
	* openssl 설치 경로가 /usr/local/lib64로 Link 실패 현상
		* 1. export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/lib64
		* 2. ln -s /usr/local/lib64/libssl.so.3 /usr/local/lib/libssl.so.3
         ln -s /usr/local/lib64/libcrypto.so.3 /usr/local/lib/libcrypto.so.3
