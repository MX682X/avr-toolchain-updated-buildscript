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


while getopts "rdbc" binutils_args; do
	case ${binutils_args} in
		r) rm -rf ./binutils ./binutils-build/* ./obj-binutils && exit 1;;
		d) rm -f ${DOWNLOAD_DIR}/avr-mainline.zip && exit 1;;
		b) rm -rf obj-binutils && exit 1;;
		c) find ./binutils-build -name "config.cache" -type f -delete	# this finds all config.caches and deletes them. Neccessary for reconfigure
	esac
done


if [[ x$CROSS_COMPILE != x ]] ; then
	EXTRA_CONFARGS="--host=$OUTPUT_TAG"
fi

cd ./toolsdir/bin
TOOLS_BIN_PATH=`pwd`
cd ../../

export PATH="$TOOLS_BIN_PATH:$PATH"


if [[ ! -d ./binutils ]] ; then
	#if [[ ${GCC_VERSION} = 7.*.* ]]; then #gcc Version >7 is using a new method for ISRs but requires newer binutils...
	#	if [[ ! -f ${DOWNLOAD_DIR}/avr-binutils.zip ]] ; then
	#		wget -O "${DOWNLOAD_DIR}/avr-binutils.zip" "https://github.com/embecosm/avr-binutils-gdb/archive/refs/heads/avr-mainline.zip"
	#	fi
	#  	unzip -q ${DOWNLOAD_DIR}/avr-binutils.zip -d ./binutils
	#  	mv ./binutils/avr-binutils-gdb-avr-mainline/* ./binutils
	#  
	#	cd ./binutils
#
	#    	autoconf
	#  	cd ..
	#else
		if [[ ! -f ${DOWNLOAD_DIR}/binutils-2.39.tar.bz2 ]] ; then
			wget "https://ftp.gnu.org/gnu/binutils/binutils-2.39.tar.bz2" -P ${DOWNLOAD_DIR}
		fi
		if [[ ! -d ${DOWNLOAD_DIR}/binutils-2.39 ]] ; then
			tar -xf ${DOWNLOAD_DIR}/binutils-2.39.tar.bz2 -C ${DOWNLOAD_DIR}
		fi
	  	cp -r ${DOWNLOAD_DIR}/binutils-2.39 ./binutils
		cd ./binutils
	    	autoconf
	  	cd ..
	#fi
fi

mkdir -p objdir
cd objdir
PREFIX=`pwd`
cd ..


mkdir -p binutils-build
cd binutils-build

CONFARGS=" \
	--enable-languages=c,c++ \
	--prefix=$PREFIX \
	--disable-nls \
	--disable-doc \
	--disable-werror \
	--enable-install--libiberty \
	--enable-install-libbfd \
	--enable-plugins \
	--disable-libdecnumber \
	--disable-gdb \
	--disable-readline \
	--disable-sim \
	--target=avr"

CFLAGS="-w -O2 -g0 $CFLAGS" CXXFLAGS="-w -O2 -g0 $CXXFLAGS" LDFLAGS="-s $LDFLAGS" ../binutils/configure $CONFARGS $EXTRA_CONFARGS

make all -l 3.0
make install -l 3.0

