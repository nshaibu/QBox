#!/bin/bash

: ${LIB_DIR:=$HOME/my_script/QB}

. ${LIB_DIR}/include

DEFINE INIT_SH

##global variables
: ${HD_IMG_DIR:="$HOME/.img_qemubox"}
: ${TEMP_FOLDER:="${HD_IMG_DIR}/.tmp_qbox"}
: ${QDB_FOLDER=:"${HD_IMG_DIR}/.qdb"} ##qbox database files location
: ${LOG_DIR:="${HD_IMG_DIR}/logs_dir"}
: ${BOOT_DIR:="${HD_IMG_DIR}/.qemuboot"} ## contain boot files

#Installation Directory 
: ${QBOX_DIR:="/usr/local/bin/QBox"}

export SDL_VIDEO_X11_DGAMOUSE=0 ##to prevent qemu cursor from been difficult to control

[ ! -d ${HD_IMG_DIR} ] && mkdir ${HD_IMG_DIR} ##Check and creates Harddisk image folder
[ ! -d ${BOOT_DIR} ] && mkdir ${BOOT_DIR} ##check and create boot folder
[ ! -d ${QDB_FOLDER} ] && mkdir ${QDB_FOLDER} ##check for qbox database folder
[ ! -d ${TEMP_FOLDER} ] && mkdir ${TEMP_FOLDER} ##check and creates tmp folder
[ ! -d ${LOG_DIR} ] && mkdir ${LOG_DIR} && touch ${LOG_DIR}/qboxlog ##check and create log directory
[ ! -f ${QDB_FOLDER}/pid.qdb ] && touch ${QDB_FOLDER}/pid.qdb ##check pid database vm_name|pid
[ ! -f ${QDB_FOLDER}/vms.qdb ] && touch ${QDB_FOLDER}/vms.qdb
GO="nafiu shaibu"
