#!/bin/bash

. config.sh
. app/colors.sh 

# run as root only
if [[ $EUID -ne 0 ]] ; then
    run_error "This script must be run with root access\e[49m"
    exit 1
fi
[ $# -eq 0 ] && { run_error "Usage: openssl <version>"; exit; }
if [ -z ${ROOT+x} ];  then show_red "Error" "ROOT system variable is not set! Check config.sh";  exit 1; fi
if [ -z ${CACHE+x} ]; then show_red "Error" "CACHE system variable is not set! Check config.sh"; exit 1; fi
if [ -z ${BUILD+x} ]; then show_red "Error" "BUILD system variable is not set! Check config.sh"; exit 1; fi

# Set: vars
MAIN_DIR="openssl"
WORKDIR="${BUILD}${MAIN_DIR}/"
CACHEDIR="${CACHE}${MAIN_DIR}/"
FILENAME="${MAIN_DIR}-${1}.tar.gz"
# Clear: current install
rm -Rf ${WORKDIR} && mkdir -p ${WORKDIR}

# Workspace


show_blue "Install" "${MAIN_DIR} from source"
# Run
run_install "${MAIN_DIR}-${1}:: required by NGINX Gzip module for headers compression"

if [ ! -s "${CACHE}${FILENAME}" ] ; then
        run_download "${FILENAME}"
        wget -O ${CACHE}${FILENAME} wget http://www.openssl.org/source/${FILENAME} &> /dev/null
    else
        show_yellow "Cache" "found ${FILENAME}. Using from cache" 
fi

cd ${WORKDIR}
if [ ! -s "${CACHE}${FILENAME}" ] ; then
        rm -Rf ${WORKDIR}
        run_error "${CACHE}${FILENAME} not found"
        exit 1
    else
        cd ${WORKDIR}
        show_blue_bg "Unpack" "${MAIN_DIR}-${1}.tar.gz"
        tar -xzf "${CACHE}${FILENAME}" -C ${WORKDIR}
        cp -PR ${WORKDIR}${MAIN_DIR}-${1}/* ${WORKDIR}

        ./config --prefix=/usr --openssldir=/etc/ssl --libdir=lib shared zlib-dynamic # darwin64-x86_64-cc 
        make depend && make && make test && make install
        run_ok  
fi