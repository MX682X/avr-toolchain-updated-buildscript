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
		r) rm -rf ./gcc ./gcc-build ./obj-gcc  && exit 1;;
		d) cd ${DOWNLOAD_DIR} && rm -f ${GCC_FOLDER}.tar.xz ${GMP_FOLDER}.tar.bz2 ${MPFR_FOLDER}.tar.bz2 ${MPC_FOLDER}.tar.gz && cd..  && exit 1;;
		b) rm -rf obj-gcc && exit 1;;
		c) find ./gcc-build -name "config.cache" -type f -delete;;	# this finds all config.caches and deletes them. Neccessary for reconfigure
	esac
done

cd ./toolsdir/bin
TOOLS_BIN_PATH=`pwd`
cd ../../

export PATH="$TOOLS_BIN_PATH:$PATH"

if [[ ! -d gcc ]] ; then
	# if there is no cached copy of a gcc tar, download it
	if [[ ! -f ${DOWNLOAD_DIR}/${GCC_FOLDER}.tar.xz ]] ; then
		wget ${GCC_SOURCE} -P ${DOWNLOAD_DIR}
	fi
	
	# if there is no cached extracted version of gcc, extract it
	if [[ ! -d ${DOWNLOAD_DIR}/gcc-${GCC_VERSION} ]]; then
		tar -xf ${DOWNLOAD_DIR}/${GCC_FOLDER}.tar.xz -C ${DOWNLOAD_DIR}
	fi
	
	# since the gcc folder did not exist. copy downloaded and cached gcc files
	cp -r ${DOWNLOAD_DIR}/gcc-${GCC_VERSION} ./gcc
	# Apply the right patchset
	cd ./gcc && patch -N -p1 < ../avr-gcc-patches/atmel-patches-gcc.${GCC_VERSION}*.patch && cd ..
	# Disable Self-Test. (Had some trouble getting things to work otherwise)
	#if [[ ${GCC_VERSION} = 7.*.0 ]]; then
	#	cd ./gcc && patch -N -p1 < ../gcc-patches/00-disable-selftest.patch && cd ..
	#fi
fi

if [[ ! -d ${DOWNLOAD_DIR}/${GMP_FOLDER} ]] ; then
	if [[ ! -f ${DOWNLOAD_DIR}/${GMP_FOLDER}.tar.bz2  ]] ;	then
		wget ${GMP_SOURCE} -P ${DOWNLOAD_DIR}
	fi
	tar -xf ${DOWNLOAD_DIR}/${GMP_FOLDER}.tar.bz2 -C ${DOWNLOAD_DIR}
fi

if [[ ! -d ./gcc/gmp ]] ; then
	cp -r ${DOWNLOAD_DIR}/${GMP_FOLDER} ./gcc/gmp
fi



if [[ ! -d ${DOWNLOAD_DIR}/${MPFR_FOLDER} ]] ; then
	if [[ ! -f ${DOWNLOAD_DIR}/${MPFR_FOLDER}.tar.bz2  ]] ;	then
		wget ${MPFR_SOURCE} -P ${DOWNLOAD_DIR}
	fi
	tar -xf ${DOWNLOAD_DIR}/${MPFR_FOLDER}.tar.bz2 -C ${DOWNLOAD_DIR}
fi

if [[ ! -d ./gcc/mpfr ]] ; then
	cp -r ${DOWNLOAD_DIR}/${MPFR_FOLDER} ./gcc/mpfr
fi
	
	
	
if [[ ! -d ${DOWNLOAD_DIR}/${MPC_FOLDER} ]] ; then
	if [[ ! -f ${MPC_FOLDER}.tar.gz  ]] ;	then
		wget ${MPC_SOURCE}
	fi
	tar -xf ${MPC_FOLDER}.tar.gz -C ${DOWNLOAD_DIR}
fi

if [[ ! -d gcc/mpc ]] ; then
	cp -r ${DOWNLOAD_DIR}/${MPC_FOLDER} ./gcc/mpc
fi

mkdir -p objdir
cd objdir
PREFIX=`pwd`
cd ..



if [[ x$CROSS_COMPILE != x ]] ; then
	EXTRA_CONFARGS="--host=$OUTPUT_TAG"
fi

mkdir -p gcc-build
cd gcc-build

CONFARGS=" \
	--enable-languages=c,c++ \
	--prefix=$PREFIX \
	--disable-libssp \
	--disable-shared \
	--with-dwarf2 \
	--disable-libada \
	--disable-doc \
	--disable-gomp \
  	--disable-checking \
  	--disable-threads \
  	--with-avrlibc \
  	--with-double=32 \
  	--with-long-double=32 \
	--target=avr"

CFLAGS="-w -O2 -g0 $CFLAGS" \
CXXFLAGS="-w -O2 -g0 $CXXFLAGS" \
LDFLAGS="-s $LDFLAGS" \
#NM_FOR_TARGET="${AVR_GCC_BUILDSYS_PATH}/avr-nm" \
#GCC_FOR_TARGET="${AVR_GCC_BUILDSYS_PATH}/avr-gcc" \
#GXX_FOR_TARGET="${AVR_GCC_BUILDSYS_PATH}/avr-g++" \
#AS_FOR_TARGET="${AVR_GCC_BUILDSYS_PATH}/avr-as" \
../gcc/configure $CONFARGS $EXTRA_CONFARGS




make -l 3.0
make install -l 3.0

