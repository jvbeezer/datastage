# exit on failure
set -e


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Source DataStage environment
#
if [ -f "/.dshome" ]
then
    DSHOME=`cat /.dshome`
    . $DSHOME/dsenv
else
    echo "ERROR: .dshome is missing on server - is $SERVERNAME a valid datastage engine?"
    exit -1
fi

DS_PROJECT="${PROJECTNAME}_${ENVIRONMENTID}"
BUILDHOME=`pwd`/${DS_PROJECT}
PROJECTHOME=`$DSHOME/bin/dsjob -projectinfo $DS_PROJECT | tail -1 | awk -F ": " '{print $2}'`
#------------------------------------------------------------------------------


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Deploy DataStage configurations
#

# DSParams
if [ -f "$BUILDHOME/config/DSParams" ]
then
    cp $BUILDHOME/config/DSParams $PROJECTHOME/
fi

# Projects APT Config files
set -- $BUILDHOME/config/*.apt
if [ -f "$1" ]
then
    #mkdir -p ${bamboo_DatastageConfigPath}

    # TODO: Find a better approach for this
    #rm -f ${bamboo_DatastageConfigPath}/*.apt
    #cp $BUILDHOME/*.apt ${bamboo_DatastageConfigPath}

    grep -e "resource disk" -e "resource scratchdisk" $BUILDHOME/*.apt | awk -F "[\"']" '{print $2}' | sort -u | xargs -n1 mkdir -p
fi
#------------------------------------------------------------------------------



#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Defer to filesystem deployment script
#

if [ -f "$BUILDHOME/filesystem/deploy.sh" ]
then
    #cd $BUILDHOME/filesystem
     
    chmod u+x $BUILDHOME/filesystem/deploy.sh
    $BUILDHOME/filesystem/deploy.sh -p $DS_PROJECT -e ${ENVIRONMENTID}
else
    echo "$BUILDHOME/filesystem/deploy.sh"
    echo "ERROR: filesystem/deploy.sh script not found, skipping"
    exit -1
fi
#------------------------------------------------------------------------------
