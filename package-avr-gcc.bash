#!/bin/bash -ex
# Copyright (c) 2014-2016 Arduino LLC
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

source build.conf

OUTPUT_VERSION=${GCC_VERSION}-atmel${AVR_VERSION}-${BUILD_NUMBER}

export OS=`uname -o || uname`
export TARGET_OS=$OS

usage() {
	echo "Usage: $(basename $0) [-option]" 2>&1
	echo "Host system (build.conf overwrites this option. Only first letter matters)"
	echo "a - compile for Arm 32-bit"
	echo "l - Compile for Linux 64-bit"
	echo "m - compile for Mac 64-bit"
	echo "w - compile for Windows 64-bit"
	echo "ToBeNamed Options:"
	echo "d - force a redownload of all sources"
	echo "c - force a reconfig (if compiler option change) of all sources"
	echo "r - force a reinstall of all sources"
	echo "other options:"
	echo "h - show this message and quits"
	exit 1;
}

# check if the requested System is the build system or a cross-compiling is needed
checkCross() {
	if [[ x$CROSS_COMPILE == x ]] ; then	# if no cross compiler was specified, in build.conf, or in a previous argument
		if [[ $1 != $OS ]]; then
			export CROSS_COMPILE=$1
		fi
	fi
}

# see what system the user wants to compile for
while getopts "achlmwr" host_sys; do
	case ${host_sys} in
		h) 
		   usage
		   exit 1
		   ;;
		a) checkCross "arm-cross";;
		l) checkCross "GNU/Linux";;
		m) checkCross "osxcross";;
		w) checkCross "mingw";;
		c) BUILD_ARGS="c${BUILD_ARGS}";;	#-r aint working as expected
		#r) ./tools.bash -r && ./binutils.build.bash -r && ./gcc.build.bash -r && ./avr-libc.build.bash -r && ./gdb.build.bash -r && exit 1;;
	esac
done

if [[ x$CROSS_COMPILE == x ]] ; then
	echo "Compiling for build = host"
else
	echo "Cross Compiling for "$CROSS_COMPILE
fi


if [[ x${DOWNLOAD_DIR} != x ]]; then	# check if DOWNLOAD_DIR was defined
	if [[ ! -d ${DOWNLOAD_DIR} ]]; then 	# create folder for downloads
		read -p "Download folder defined at \""${DOWNLOAD_DIR}"\" but it does not exists. Create folder [Y/n]?" create_download_folder
		if [[ $create_download_folder == "n" ]]; then
			echo "Script terminated. Can't continue without the folder"
			exit 1;
		else 
		 	mkdir -p ${DOWNLOAD_DIR}
		fi
	fi
else
	echo "Variable \"DOWNLOAD_DIR\" was not defined. Please supply a directory for downloads."
	echo "You can fix it by e.g. adding \"DOWNLOAD_DIR=./downloads\" to build.conf."
	echo "Terminating script"
	exit 1
fi

# if we are cross-compiling, make sure that avr-gcc for the build system works
if [[ x${CROSS_COMPILE} != x ]]; then
	if [[ x${AVRGCC_BUILDSYS_DIR} != x ]]; then
		cd ${AVRGCC_BUILDSYS_DIR}/bin
		if [[ ! -f ./avr-gcc ]] && [[ ! -f ./avr-g++ ]]; then
			read -p "avr-gcc executable for build system not found. Neccessary for successful cross-compiling. Continue anyway? [Y/n]" continue
			if [[ $continue == "n" ]]; then
				echo "Script terminated. Consider building avr-gcc for build system (leave out options[almw])"
				cd ../../
				exit 1;
			else 
				echo "Continuing..."
			fi
		else
			export AVR_GCC_BUILDSYS_PATH=`pwd`
			export PATH="$AVR_GCC_BUILDSYS_PATH:$PATH"
		fi
		cd ../../	
	fi
fi


if [[ $CROSS_COMPILE == "mingw" ]] ; then
  #export PATH=$PATH:~/toolchain-avr-master/avr-gcc-linux/bin
  export CFLAGS="-DWIN64 -D__USE_MINGW_ACCESS"
  export CXXFLAGS="-DWIN64"
  export LDFLAGS="-DWIN64"
  export CROSS_COMPILE_HOST="x86_64-w64-mingw32"
  export TARGET_OS="Windows"
  export OUTPUT_TAG=x86_64-w64-mingw32

elif [[ $CROSS_COMPILE == "osxcross" ]] ; then

  export CC="o32-clang"
  export CXX="o32-clang++"
  export CROSS_COMPILE_HOST="i386-apple-darwin13"
  export TARGET_OS="OSX"
  export OUTPUT_TAG=i386-apple-darwin13

elif [[ $CROSS_COMPILE == "arm-cross" ]] ; then

  export CC="arm-linux-gnueabihf-gcc"
  export CXX="arm-linux-gnueabihf-g++"
  export CROSS_COMPILE_HOST="arm-linux-gnueabihf"
  export TARGET_OS="LinuxARM"
  export OUTPUT_TAG=arm-linux-gnueabihf

elif [[ $OS == "GNU/Linux" ]] ; then

  export MACHINE=`uname -m`
  if [[ $MACHINE == "x86_64" ]] ; then
    OUTPUT_TAG=x86_64-pc-linux-gnu
  elif [[ $MACHINE == "i686" ]] ; then
    OUTPUT_TAG=i686-pc-linux-gnu
  elif [[ $MACHINE == "armv7l" ]] ; then
    OUTPUT_TAG=armhf-pc-linux-gnu
  elif [[ $MACHINE == "aarch64" ]] ; then
    OUTPUT_TAG=aarch64-pc-linux-gnu
  else
    echo Linux Machine not supported: $MACHINE
    exit 1
  fi

elif [[ $OS == "Msys" || $OS == "Cygwin" ]] ; then

  export PATH=$PATH:/c/MinGW/bin/:/c/cygwin64/bin/:/c/WinAVR-20100110/bin
  export CC="i686-w64-mingw32-gcc -m32"
  export CXX="i686-w64-mingw32-g++ -m32"
  export CFLAGS="-DWIN64 -D__USE_MINGW_ACCESS"
  export CXXFLAGS="-DWIN64"
  export LDFLAGS="-DWIN64"
  export MAKE_JOBS=4
  OUTPUT_TAG=i686-w64-mingw32

elif [[ $OS == "Darwin" ]] ; then

  export PATH=/opt/local/libexec/gnubin/:/opt/local/bin:$PATH
  export CC="gcc -arch x86_64 -mmacosx-version-min=10.8"
  export CXX="g++ -arch x86_64 -mmacosx-version-min=10.8"
  OUTPUT_TAG=x86_64-apple-darwin14

else

  echo OS Not supported: $OS
  exit 2

fi

#rm -rf gmp-${GMP_VERSION} mpc-${MPC_VERSION} mpfr-${MPFR_VERSION}
#rm -rf atpack avr8-headers
#rm -rf binutils
#rm -rf gcc avr-libc libc
#rm -rf gdb gdb-build
#rm -rf toolsdir
#mkdir -p ./objdir
#rm -rf ./objdir/*

#./tools.bash -${BUILD_ARGS}
#./binutils.build.bash -${BUILD_ARGS}
./gcc.build.bash -${BUILD_ARGS}
./avr-libc.build.bash -${BUILD_ARGS}
#./gdb.build.bash -${BUILD_ARGS}	#skip for now
#exit 1
${BASH} ./atpack.build.bash
${BASH} ./atpack.tiny.build.bash
${BASH} ./atpack.Dx.build.bash

# if producing a windows build, compress as zip and
# copy *toolchain-precompiled* content to any folder containing a .exe
if [[ ${OUTPUT_TAG} == *"mingw"* ]] ; then

  rm -f avr-gcc-${OUTPUT_VERSION}-${OUTPUT_TAG}.zip
  mv objdir avr
  BINARY_FOLDERS=`find avr -name *.exe -print0 | xargs -0 -n1 dirname | sort --unique`
  echo $BINARY_FOLDERS | xargs -n1 cp toolchain-precompiled/*
  zip -r -q avr-gcc-${OUTPUT_VERSION}-${OUTPUT_TAG}.zip avr
  mv avr objdir

else

  rm -f avr-gcc-${OUTPUT_VERSION}-${OUTPUT_TAG}.tar.bz2
  mv objdir avr
  tar -cjvf avr-gcc-${OUTPUT_VERSION}-${OUTPUT_TAG}.tar.bz2 avr
  mv avr objdir

fi

# if we compile for the building system, make sure to place a copy to the specified directory
#if [[ x${CROSS_COMPILE} == x ]]; then
#	if [[ x${AVRGCC_BUILDSYS_DIR} != x ]]; then
#		cp -r objdir ${AVRGCC_BUILDSYS_DIR}
#	fi
#fi
