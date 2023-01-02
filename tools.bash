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

mkdir -p toolsdir/bin
cd toolsdir
TOOLS_PATH=`pwd`
cd bin
TOOLS_BIN_PATH=`pwd`
cd ../../

export PATH="$TOOLS_BIN_PATH:$PATH"


while getopts "rdbc" tools_args; do
	case ${tools_args} in
		r) rm -rf ${DOWNLOAD_DIR}/${AUTOCONF_FOLDER} ${DOWNLOAD_DIR}/${AUTOMAKE_FOLDER} && rm -f toolsdir/bin/* && exit 1;;
		d) rm -f ${DOWNLOAD_DIR}/${AUTOCONF_FOLDER}.tar.gz ${DOWNLOAD_DIR}/${AUTOMAKE_FOLDER}.tar.gz && exit 1;;
		b) rm -f toolsdir/bin/* && exit 1;;
		c) ;;
	esac
done


if [[ ! -d ${DOWNLOAD_DIR}/${AUTOCONF_FOLDER} ]] ; then
	if [[ ! -f ${DOWNLOAD_DIR}/${AUTOCONF_FOLDER}.tar.gz ]] ; then
		wget ${AUTOCONF_SOURCE} -P ${DOWNLOAD_DIR}
	fi
  	tar -xf ${DOWNLOAD_DIR}/${AUTOCONF_FOLDER}.tar.gz -C ${DOWNLOAD_DIR}
fi

if [[ ! -f ./toolsdir/bin/autoconf ]]; then
	cd ${DOWNLOAD_DIR}/${AUTOCONF_FOLDER}
	CONFARGS="--prefix=$TOOLS_PATH"
	./configure $CONFARGS
	make -l 3.0
	make install -l 3.0
	cd ../../
fi


if [[ ! -d ${DOWNLOAD_DIR}/${AUTOMAKE_FOLDER} ]] ; then
	if [[ ! -f ${DOWNLOAD_DIR}/${AUTOMAKE_FOLDER}.tar.gz ]] ; then
		wget ${DOWNLOAD_DIR}/${AUTOMAKE_SOURCE} -P ${DOWNLOAD_DIR}
	fi
  	tar -xf ${DOWNLOAD_DIR}/${AUTOMAKE_FOLDER}.tar.gz -C ${DOWNLOAD_DIR}
  
  	cd ${DOWNLOAD_DIR}/${AUTOMAKE_FOLDER}
  	patch -N -p1 < ../../automake-patches/0001-fix-perl-522.patch
  	cd ../../
fi


if [[ ! -f toolsdir/bin/automake ]]; then
	cd ${DOWNLOAD_DIR}/${AUTOMAKE_FOLDER}
	cp ../../config.guess-am-1.11.4 lib/config.guess
	./bootstrap
	CONFARGS="--prefix=$TOOLS_PATH"
	./configure $CONFARGS

	# Prevent compilation problem with docs complaining about @itemx not following @item
	cp doc/automake.texi doc/automake.texi2
	cat doc/automake.texi2 | $SED -r 's/@itemx/@c @itemx/' >doc/automake.texi
	rm doc/automake.texi2
	make -l 3.0
	make install -l 3.0
	cd ../../
fi
