#!/bin/sh
CWD=$(pwd)
set -e

FRR_SRC=frr

if [ ! -d ${FRR_SRC} ]; then
    echo "FRR source directory does not exists, please 'git clone'"
    exit 1
fi

# VyOS requires some small FRR Patches - apply them here
# It's easier to habe them here and make use of the upstream
# repository instead of maintaining a full Fork.
# Saving time/resources is essential :-)
cd ${FRR_SRC}

PATCH_DIR=${CWD}/patches
if [ -d $PATCH_DIR ]; then
    echo "I: Apply FRRouting patches not in main repository:"
    for patch in $(ls ${PATCH_DIR})
    do
        if [ -z "$(git config --list | grep -e user.name -e user.email)" ]; then
            # if git user.name and user.email is not set, -c sets temorary user.name and
            # user.email variables as these is not set in the build container by default.
            OPTS="-c user.name=VyOS-CI -c user.email=maintainers@vyos.io"
        fi
        git $OPTS am --committer-date-is-author-date ${PATCH_DIR}/${patch}
    done
fi

echo "I: Ensure Debian build dependencies are met"
sudo apt-get -y install chrpath gawk install-info libcap-dev libjson-c-dev librtr-dev
sudo apt-get -y install libpam-dev libprotobuf-c-dev libpython3-dev:native python3-sphinx:native libsnmp-dev protobuf-c-compiler python3-dev:native texinfo lua5.3

# Build Debian FRR package
echo "I: Build Debian FRR Package"
# extract "real" git commit for FRR version identifier
dch -v "$(git describe | cut -c5-)" "VyOS build - FRR"
dpkg-buildpackage -us -uc -tc -b -Zgzip -Ppkg.frr.rtrlib,pkg.frr.lua
