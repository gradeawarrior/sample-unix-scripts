#!/usr/bin/env bash

DEBUG_ENABLED=1
script_name=$0

#===============================================================================
#========================== Functions ==========================================
#===============================================================================

printUsage() {
    cat <<EOF
    
Usage: $script_name [options]

DETAILS:
    -v          Returns the current version of the application (Default)
    
    -n          Returns the next version of the application
    
    -h|--help   Print this help screen
    
EOF
}

getLatestVersion() {
    MAJOR=$(git tag -l | awk -F '.' '{print $1}' | sort -n | tail -n1)
    MINOR=$(git tag -l | egrep "^$MAJOR\\." | awk -F '.' '{print $2}' | sort -n | tail -n1)
    PATCH=$(git tag -l | egrep "^$MAJOR\\.$MINOR" | awk -F '.' '{print $3}' | sort -n | tail -n1)
    
    if [ "$MAJOR" != "" -a "$MINOR" != "" -a "$PATCH" != "" ]
    then
        LATEST_VERSION="$MAJOR.$MINOR.$PATCH";
    elif [ "$MAJOR" != "" -a "$MINOR" != "" ]
    then
        LATEST_VERSION="$MAJOR.$MINOR";
    else
        echo "[ERROR] Invalid tag in git. Expected tags with format \$MAJOR.\$MINOR.\$PATCH";
        exit 1;
    fi
    
    echo $LATEST_VERSION;
}

getNextVersion() {
    LATEST_VERSION=$1
    
    if [ "$LATEST_VERSION" == "" ]
    then
        echo "[ERROR] Latest version was not specified";
        exit 1;
    fi
    
    MAJOR=$(echo $LATEST_VERSION | awk -F '.' '{print $1}')
    MINOR=$(echo $LATEST_VERSION | awk -F '.' '{print $2}')
    PATCH=$(echo $LATEST_VERSION | awk -F '.' '{print $3}')
    
    
    if [ "$MAJOR" != "" -a "$MINOR" != "" -a "$PATCH" != "" ]
    then
        PATCH=`expr $PATCH + 1`;
        NEXT_VERSION="$MAJOR.$MINOR.$PATCH";
    elif [ "$MAJOR" != "" -a "$MINOR" != "" ]
    then
        MINOR=`expr $MINOR + 1`;
        NEXT_VERSION="$MAJOR.$MINOR";
    else
        echo "[ERROR] Invalid tag in git. Expected tags with format \$MAJOR.\$MINOR.\$PATCH";
        exit 1;
    fi
    
    echo $NEXT_VERSION;
}

debug() {
    if [ $DEBUG_ENABLED -eq 1 ]
    then
        echo "$1";
    fi
}

#===============================================================================
#=============================== Main ==========================================
#===============================================================================

# Check that there are required number of arguments
if (test $# -eq 0)
then
    LATEST_VERSION=$(getLatestVersion)
    echo $LATEST_VERSION
else
	while [ "$1" != '' ]
	do
		case $1
		in
		-v)
                        LATEST_VERSION=$(getLatestVersion)
			echo $LATEST_VERSION;
			shift 1;;
		-n)
                        LATEST_VERSION=$(getLatestVersion)
                        NEXT_VERSION=$(getNextVersion $LATEST_VERSION)
			echo $NEXT_VERSION;
			shift 1;;
		-h)
			printUsage;
			shift 1;;
		--help)
			printUsage;
			shift 1;;
		*)
			echo "[ERROR] Unknown Parameter: '$1'";
			printUsage;
			exit 1;;
		esac
	done
fi
