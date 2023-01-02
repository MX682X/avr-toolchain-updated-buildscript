#!/bin/bash -ex
# Copyright (c) 2014-2015 Arduino LLC
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

if [[ ! -d toolsdir  ]] ;
then
	echo "You must first build the tools: run build_tools.bash"
	exit 1
fi

while getopts "rdbc" gcc_args; do
	case ${gcc_args} in
		r) rm -rf ./avr-libc ./obj-avr-libc ./avr-libc-build  && exit 1;;
		d) cd ${DOWNLOAD_DIR} && rm -f ./avr-libc.zip ./avr8-headers.zip && cd..  && exit 1;;
		b) rm -rf ./obj-avr-libc && exit 1;;
		c) ;;
	esac
done

cd ./toolsdir/bin
TOOLS_BIN_PATH=`pwd`
cd ../../

export PATH="$TOOLS_BIN_PATH:$PATH"


if [[ ! -d ./avr-libc ]] ; then
	mkdir -p ./avr-libc
	if [[ ! -f ${DOWNLOAD_DIR}/avr-libc.zip ]] ; then
		wget "https://github.com/avrdudes/avr-libc/archive/refs/heads/main.zip" -P "${DOWNLOAD_DIR}"
		mv ${DOWNLOAD_DIR}/main.zip ${DOWNLOAD_DIR}/avr-libc.zip	# rename archive
	fi
	
	if [[ ! -d ${DOWNLOAD_DIR}/avr-libc-main ]] ; then
  		unzip -q ${DOWNLOAD_DIR}/avr-libc.zip -d ${DOWNLOAD_DIR}
  	fi
  	
  	cp -r ${DOWNLOAD_DIR}/avr-libc-main/* ./avr-libc
fi

if [[ ! -d ${DOWNLOAD_DIR}/avr8-headers ]] ; then
  	if [[ ! -f ${DOWNLOAD_DIR}/avr8-headers.zip ]] ; then
    		wget $AVR_SOURCES/avr8-headers.zip -P ${DOWNLOAD_DIR}
  	fi
  	
  	if [[ ! -d ${DOWNLOAD_DIR}/avr8-headers ]] ; then
  		unzip -q ${DOWNLOAD_DIR}/avr8-headers.zip -d ${DOWNLOAD_DIR}/avr8-headers
  	fi
  	
  	for i in ${DOWNLOAD_DIR}/avr8-headers/avr/io[0-9a-zA-Z]*.h 
  		do
    		cp -f $i ./avr-libc/include/avr/
  	done
  
  	cd ./avr-libc
    	for p in ../avr-libc-patches/*.patch 
    		do
      		echo Applying $p
      		patch -N -p1 < $p
    	done
  	cd ..
fi

cd ./avr-libc
./bootstrap
cd ..


mkdir -p ./objdir
cd ./objdir
PREFIX=`pwd`
cd ..


mkdir -p ./avr-libc-build
cd ./avr-libc-build

CONFARGS=" \
	--prefix=$PREFIX \
	--host=avr \
	--enable-device-lib \
	--libdir=$PREFIX/lib \
	--disable-doc"
	
	
AR="avr-ar" AS="avr-as" CC="avr-gcc" CXX="avr-g++" RANLIB="avr-ranlib" CFLAGS="-w -Os $CFLAGS" CXXFLAGS="-w -Os $CXXFLAGS" LDFLAGS="-s $LDFLAGS" ../avr-libc/configure $CONFARGS

make -l 3.0
make install -l 3.0


