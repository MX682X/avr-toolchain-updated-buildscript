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

if [[ ! -d ./toolsdir  ]] ; then
	echo "You must first build the tools: run tools.bash"
	exit 1
fi

if [[ x$CROSS_COMPILE != x ]] ; then
	if [[ ! -f ./gcc-build/gmp/gmp.h ]] ; then
		echo "gmp.h in gcc-build directory not found. Needed When Cross-Compiling. Aborting..."
		exit 1
	fi
fi

while getopts "rdbc" gdb_args; do
	case ${gdb_args} in
		r) rm -rf ./gdb ./gdb-build/* ./obj-gdb && exit 1;;
		d) rm -f ${DOWNLOAD_DIR}/${GDB_FOLDER}.tar.gz && exit 1;;
		b) rm -rf obj-gdb && exit 1;;
		c) find ./gdb-build -name "config.cache" -type f -delete;;	# this finds all config.caches and deletes them. Neccessary for reconfigure
	esac
done

cd toolsdir/bin
TOOLS_BIN_PATH=`pwd`
cd -

export PATH="$TOOLS_BIN_PATH:$PATH"


if [[ ! -d ./gdb  ]] ; then # check if we already have extracted the tar
  	if [[ ! -f ${DOWNLOAD_DIR}/${GDB_FOLDER}.tar.gz  ]] ; then 	# check if we already downloaded the tar
    		wget ${GDB_SOURCE} -P ${DOWNLOAD_DIR}
  	fi
  	
  	if [[ ! -f ${DOWNLOAD_DIR}/${GDB_FOLDER} ]] ; then 	# check if the extracted folder exists
    		tar -xf ${DOWNLOAD_DIR}/${GDB_FOLDER}.tar.gz -C ${DOWNLOAD_DIR}	# if not, extract tar
  	fi
  	
  	cp -r ${DOWNLOAD_DIR}/${GDB_FOLDER} ./gdb
fi



if [[ x$CROSS_COMPILE != x ]] ; then
	# work around for mingw32 not having gmp library and includes. Use the one already created when making gcc
	TOOLCHAIN_PATH=`pwd`
	GCC_GMP_PATH="${TOOLCHAIN_PATH}/gcc-build/gmp"
	EXTRA_DIRS="-I${GCC_GMP_PATH} -L${GCC_GMP_PATH}/.libs"
	#CFLAGS="${EXTRA_DIRS} ${CFLAGS}"
	#CXXFLAGS="${EXTRA_DIRS} ${CXXFLAGS}"
	LDFLAGS="${EXTRA_DIRS} ${LDFLAGS}"
	EXTRA_CONFARGS=" \
		--host=$OUTPUT_TAG \
		--with-gmp-include=${GCC_GMP_PATH} \
		--with-gmp-lib=${GCC_GMP_PATH}/.libs \
	"
fi

mkdir -p objdir
cd objdir
PREFIX=`pwd`
cd ..

mkdir -p gdb-build
cd gdb-build

CONFARGS=" \
	--prefix=$PREFIX \
	--disable-werror \
	--target=avr \
	--disable-doc \
	"

CFLAGS="-w -O2 -g0 ${CFLAGS}" CXXFLAGS="-w -O2 -g0 ${CXXFLAGS}" LDFLAGS="-s ${LDFLAGS}" ../gdb/configure $CONFARGS $EXTRA_CONFARGS


make MAKEINFO=true
# Thanks https://stackoverflow.com/questions/48071270/how-to-disable-automake-docs for MAKEINFO=true. texinfo has thrown errors otherwise
# New versions of gdb share the same configure/make scripts with binutils. Running make install-gdb to
# install just the gdb binaries.
make MAKEINFO=true install-gdb -l 3.0
