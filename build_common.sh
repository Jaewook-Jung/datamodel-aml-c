###############################################################################
# Copyright 2018 Samsung Electronics All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
###############################################################################

#!/bin/bash
set +e
#Colors
RED="\033[0;31m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
NO_COLOUR="\033[0m"

PROJECT_ROOT=$(pwd)
AML_TARGET_ARCH="x86_64"
AML_WITH_DEP=false
AML_BUILD_MODE="release"
AML_LOGGING="off"

RELEASE="1"
LOGGING="0"

install_dependencies() {

    if [ -d "./dependencies" ] ; then
        echo "dependencies folder exists"
    else
        mkdir dependencies
    fi

    cd ./dependencies

    if [ -d "./datamodel-aml-cpp" ] ; then
        echo "datamodel-aml-cpp already exists"
    else
        #clone datamodel-aml-cpp
        git clone git@github.sec.samsung.net:RS7-EdgeComputing/datamodel-aml-cpp.git
    fi

    cd ./datamodel-aml-cpp
    git checkout master
    git pull

    # Build datamodel-aml-cpp
    echo -e "Installing datamodel-aml-cpp library"
    if [ "x86" = ${AML_TARGET_ARCH} ]; then
        if [ "debug" = ${AML_BUILD_MODE} ]; then
            ./build_common.sh --with_dependencies=true --target_arch=x86 --build_mode=debug
        else
            ./build_common.sh --with_dependencies=true --target_arch=x86
        fi
    elif [ "x86_64" = ${AML_TARGET_ARCH} ]; then
        if [ "debug" = ${AML_BUILD_MODE} ]; then
            ./build_common.sh --with_dependencies=true --target_arch=x86_64 --build_mode=debug
        else
            ./build_common.sh --with_dependencies=true --target_arch=x86_64
        fi
    elif [ "arm" = ${AML_TARGET_ARCH} ]; then
        if [ "debug" = ${AML_BUILD_MODE} ]; then
            ./build_common.sh --with_dependencies=true --target_arch=arm --build_mode=debug
        else
            ./build_common.sh --with_dependencies=true --target_arch=arm
        fi
    elif [ "arm64" = ${AML_TARGET_ARCH} ]; then
        if [ "debug" = ${AML_BUILD_MODE} ]; then
            ./build_common.sh --with_dependencies=true --target_arch=arm64 --build_mode=debug
        else
            ./build_common.sh --with_dependencies=true --target_arch=arm64
        fi
#    elif [ "armhf" = ${AML_TARGET_ARCH} ]; then
#        if [ "debug" = ${AML_BUILD_MODE} ]; then
#            ./build_common.sh --with_dependencies=true --target_arch=armhf --build_mode=debug
#        else
#            ./build_common.sh --with_dependencies=true --target_arch=armhf
#        fi
    elif [ "armhf" = ${AML_TARGET_ARCH} -o "armhf-qemu" = ${AML_TARGET_ARCH} ]; then
        if [ "debug" = ${AML_BUILD_MODE} ]; then
            ./build_common.sh --with_dependencies=true --target_arch=armhf --build_mode=debug
        else
            ./build_common.sh --with_dependencies=true --target_arch=armhf
        fi
    else
         echo -e "${RED}Not a supported architecture${NO_COLOUR}"
         usage; exit 1;
    fi

    if [ $? -ne 0 ]; then 
        echo -e "${RED}Build failed${NO_COLOUR}" 
        exit 1 
    fi
    echo -e "Installation of datamodel-aml-cpp library"
}

usage() {
    echo -e "${BLUE}Usage:${NO_COLOUR} ./build.sh <option>"
    echo -e "${GREEN}Options:${NO_COLOUR}"
    echo "  --build_mode=[release|debug](default: release)               :  Build aml library and samples in release or debug mode"
    echo "  --logging=[on|off](default: off)                             :  Build aml library including logs"
    echo "  --with_dependencies=[true|false](default: false)             :  Build aml along with dependencies [protobuf]"
    echo "  -c                                                           :  Clean aml repository"
    echo "  -h / --help                                                  :  Display help and exit"
}

build_x86() {
    echo -e "Building for x86"
    scons TARGET_OS=linux TARGET_ARCH=x86 RELEASE=${RELEASE} LOGGING=${LOGGING}
}

build_x86_64() {
    echo -e "Building for x86_64"
    scons TARGET_OS=linux TARGET_ARCH=x86_64 RELEASE=${RELEASE} LOGGING=${LOGGING}
}

build_arm() {
    echo -e "Building for arm"
    scons TARGET_ARCH=arm TC_PREFIX=/usr/bin/arm-linux-gnueabi- TC_PATH=/usr/bin/ RELEASE=${RELEASE} LOGGING=${LOGGING}
}

build_arm64() {
    echo -e "Building for arm64"
    scons TARGET_ARCH=arm64 TC_PREFIX=/usr/bin/aarch64-linux-gnu- TC_PATH=/usr/bin/ RELEASE=${RELEASE} LOGGING=${LOGGING}
}

build_armhf() {
    echo -e "Building for armhf"
    scons TARGET_ARCH=armhf TC_PREFIX=/usr/bin/arm-linux-gnueabihf- TC_PATH=/usr/bin/ RELEASE=${RELEASE} LOGGING=${LOGGING}
}

build_armhf_native() {
    echo -e "Building for armhf_native"
    scons TARGET_ARCH=armhf RELEASE=${RELEASE} LOGGING=${LOGGING}
}

build_armhf_qemu() {
    echo -e "Building for armhf-qemu"
    scons TARGET_ARCH=armhf RELEASE=${RELEASE} LOGGING=${LOGGING}

    if [ -x "/usr/bin/qemu-arm-static" ]; then
        echo -e "${BLUE}qemu-arm-static found, copying it to current directory${NO_COLOUR}"
        cp /usr/bin/qemu-arm-static .
    else
        echo -e "${RED}No qemu-arm-static found${NO_COLOUR}"
        echo -e "${BLUE} - Install qemu-arm-static and build again${NO_COLOUR}"
    fi
}

build() {
    if [ true = ${AML_WITH_DEP} ]; then
        install_dependencies
    fi

    if [ "debug" = ${AML_BUILD_MODE} ]; then
        RELEASE="0"
    fi
    if [ "on" = ${AML_LOGGING} ]; then
        LOGGING="1"
    fi

    cd $PROJECT_ROOT
    if [ "x86" = ${AML_TARGET_ARCH} ]; then
         build_x86;
    elif [ "x86_64" = ${AML_TARGET_ARCH} ]; then
         build_x86_64;
    elif [ "arm" = ${AML_TARGET_ARCH} ]; then
         build_arm;
    elif [ "arm64" = ${AML_TARGET_ARCH} ]; then
         build_arm64;
    elif [ "armhf" = ${AML_TARGET_ARCH} ]; then
         build_armhf;
    elif [ "armhf-qemu" = ${AML_TARGET_ARCH} ]; then
         build_armhf_qemu;
    elif [ "armhf-native" = ${AML_TARGET_ARCH} ]; then
         build_armhf_native;
    else
         echo -e "${RED}Not a supported architecture${NO_COLOUR}"
         usage; exit 1;
    fi
    if [ $? -ne 0 ]; then 
        echo -e "${RED}Build failed${NO_COLOUR}" 
        exit 1 
    fi
}

clean() {
    scons -c
    rm -r "${PROJECT_ROOT}/out/" "${PROJECT_ROOT}/.sconsign.dblite"
    find "${PROJECT_ROOT}" -name "*.memcheck" -delete -o -name "*.gcno" -delete -o -name "*.gcda" -delete -o -name "*.os" -delete -o -name "*.o" -delete
    echo -e "Finished Cleaning"
}

process_cmd_args() {
    while [ "$#" -gt 0  ]; do
        case "$1" in
            --with_dependencies=*)
                AML_WITH_DEP="${1#*=}";
                if [ ${AML_WITH_DEP} = true ]; then
                    echo -e "${GREEN}Build with depedencies${NO_COLOUR}"
                elif [ ${AML_WITH_DEP} = false ]; then
                    echo -e "${GREEN}Build without depedencies${NO_COLOUR}"
                else
                    echo -e "${RED}Unknown option for --with_dependencies${NO_COLOUR}"
                    shift 1; exit 0
                fi
                shift 1;
                ;;
            --target_arch=*)
                AML_TARGET_ARCH="${1#*=}";
                echo -e "${GREEN}Target Arch is: $AML_TARGET_ARCH${NO_COLOUR}"
                shift 1
                ;;
            --build_mode=*)
                AML_BUILD_MODE="${1#*=}";
                echo -e "${GREEN}Build mode is: $AML_BUILD_MODE${NO_COLOUR}"
                shift 1;
                ;;
            --logging=*)
                AML_LOGGING="${1#*=}";
                echo -e "${GREEN}Logging option is: $AML_LOGGING${NO_COLOUR}"
                shift 1;
                ;;
            -c)
                clean
                shift 1; exit 0
                ;;
            -h)
                usage; exit 0
                ;;
            --help)
                usage; exit 0
                ;;
            -*)
                echo -e "${RED}"
                echo "unknown option: $1" >&2;
                echo -e "${NO_COLOUR}"
                usage; exit 1
                ;;
            *)
                echo -e "${RED}"
                echo "unknown option: $1" >&2;
                echo -e "${NO_COLOUR}"
                usage; exit 1
                ;;
        esac
    done
}

process_cmd_args "$@"
install_dependencies
echo -e "Building C AML DataModel library("${AML_TARGET_ARCH}").."
build
echo -e "Done building C AML DataModel library("${AML_TARGET_ARCH}")"

exit 0
