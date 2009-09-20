#!/bin/bash

function build {
    RELEASE_NAME="MP4-Repacker"
    RELEASE_VER="1.0"
    RELEASE_DESC="Extracts audio and video from MPEG-4 container and repacks it."
    RELEASE_KEYWORDS="MP4, MPEG-4, Quicktime, container, repack, fix, repair"

    rm ${RELEASE_NAME}-v${RELEASE_VER}.tar* 2>/dev/null
    bzr export ${RELEASE_NAME}-v${RELEASE_VER}.tar
    tar --delete -f ${RELEASE_NAME}-v${RELEASE_VER}.tar ${RELEASE_NAME}-v${RELEASE_VER}/build.sh
    gzip ${RELEASE_NAME}-v${RELEASE_VER}.tar
}
