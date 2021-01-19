#!/bin/bash

BASEFOLDER=$(pwd)

function CountFiles(){
	local DIRECTORY=$1
	local COUNTER=0
	local TOTALSIZE=0
	
	cd $DIRECTORY
	for FILE in *
	do
		echo $FILE
		COUNTER=$[COUNTER + 1]
		TOTALSIZE=$[TOTALSIZE + $(stat -c%s "$FILE")]
	done
	cd $BASEFOLDER
	
	echo "Directory: $DIRECTORY"
	echo "Files to copy" $COUNTER
	echo "Total size $TOTALSIZE bytes"
}

function GetListOfFiles(){
	local DIRECTORY=$1
	
	FILEPATH=()
	FILENAMES=()
	cd $DIRECTORY
	for FILE in *
	do
		FILEPATH+=("$(realpath ${FILE})")
		FILENAMES+=("${FILE}")
	done
	cd $BASEFOLDER
	
	echo "${#FILEPATH[@]} files to copy."
}

function PrintHelp(){
	echo "Copy All Files"
	echo "Usage: caf -s <SOURCE_DIRECTORY> -t <TARGET_DIRECTORY>"
	echo "Usage: caf -s <SOURCE_DIRECTORY> -t <TARGET_DIRECTORY> -n <SECOND_TARGET_DIRECTORY>"
	echo "This will coppy all files and directoris to the target."
	echo ""
	echo "-s (source): The sorce directory to copy all files from."
	echo ""
	echo "-t (target): The target directory to copy file to."
	echo ""
	echo "-n <Directory> (new target): This option can be add after -t, after the file will be copied to target directory it will be copy the file again to second diractory."
	echo ""
	echo "-rm (remove):  This option can be add after -n, after the file will be copied to second target it will be removed from first target."
	echo ""
	echo "-c <Directory> :count	Show how many files is need to copy and the total size of them."
	echo "-va : explain what is being done"
}

function AskUserIfCreateDirectory(){
	local DIRECTORY=$1
	VALID=0
	while [ $VALID -eq 0 ]
	do
		read -p "Did you whant to create directory ${OPTARG}? (yes/no): " ANS
		if [[ ( $ANS = "yes") ]]
		then
			VALID=1
			mkdir -p ${OPTARG} || VALID=2
		elif [[ $ANS = "no" ]]
		then
			VALID=2
		fi
	done
}

while getopts ":b:h:c:s:t:n:r:v:" option; do
	case "${option}" in
		h)
			# print usage and options information
			PrintHelp
			;;
		c)
			[ -d ${OPTARG} ] && CountFiles ${OPTARG} || echo "The parameter ${OPTARG} is not directory."
			exit 0
			;;
		s)
			[ -d ${OPTARG} ] && SOURCEDIRECTORY=${OPTARG} || echo "The parameter ${OPTARG} is not directory."
			;;
		t)
			[ -d ${OPTARG} ] && TARGETDIRECTORY=${OPTARG} || echo "The parameter ${OPTARG} is not directory."
			if [ -z "${TARGETDIRECTORY}" ] ; then
				echo "Directory ${OPTARG} not found."
				AskUserIfCreateDirectory ${OPTARG}
				TARGETDIRECTORY=${OPTARG}
			fi
			;;
		n)
			if [ -z "${SOURCEDIRECTORY}" ] || [ -z "${TARGETDIRECTORY}" ]
			then
				echo "This option can be used only after -s and -t options"
				exit 0
			fi
			[ -d ${OPTARG} ] && SECONDTARGETDIRECTORY=${OPTARG} || echo "The parameter ${OPTARG} is not directory."
			# ask the user if he want to try create this directory
			if [ -z "${SECONDTARGETDIRECTORY}" ] ; then
				echo "Directory ${OPTARG} not found."
				AskUserIfCreateDirectory ${OPTARG}
				SECONDTARGETDIRECTORY=${OPTARG}
			fi
			;;
		r)
			if [ -z "${SECONDTARGETDIRECTORY}" ]
			then
				echo "-r option can be used only with -n option, use -h to get more info."
				exit 0
			else 
				REMOVE=true
			fi
			;;
		v) 
			EWBD=1
			;;
		*)
			echo "option: ${option}, param: ${OPTARG} not found, for more information use -h option."
			exit 0
			;;
	esac
done
			
if [ ! -z "${VALID}" ] && [ $VALID = 2 ]
then
	echo "Target directory not found or failed to create."
	echo "For more information use -h option."
	exit 0
fi

if [ -z "${SOURCEDIRECTORY}" ] || [ -z "${TARGETDIRECTORY}" ]
then
	echo "Missing critical parameters."
	echo "For more information use -help option."
	exit 0
fi

function CopyFiles(){
	local LOCALTARGETDIRECTORY=$1
	
	for ((count=0; count<${#FILEPATH[@]}; count++))
	do
		# copy file, -v:explain what is being done, -r:copy directories recursively
		if [ ! -z "${EWBD}" ] 
		then
			cp -v -r "${FILEPATH[$count]}"  "$LOCALTARGETDIRECTORY${FILENAMES[$count]}"
		else
			cp -r "${FILEPATH[$count]}"  "$LOCALTARGETDIRECTORY${FILENAMES[$count]}"
		fi
	done
	
	echo "Files ${#FILEPATH[@]} copied to $LOCALTARGETDIRECTORY."
}

function RemoveFiles(){
	local LOCALFILESTOCOPY=$@
	local COUNTER=0
	
	for FILE in ${LOCALFILESTOCOPY[@]}
	do
		rm -r -d "$TARGETDIRECTORY$FILE" ||:
		COUNTER=$[COUNTER + 1]
	done 
	
	echo $COUNTER " temp files removed."
}

# Get list of files in the sorce directory (absolute path)
GetListOfFiles $SOURCEDIRECTORY

# Copy files from source directory to target directory.
if [[ ! -z "${SECONDTARGETDIRECTORY}" ]]
then
	CopyFiles $TARGETDIRECTORY
	echo "Files from the source copied."
fi

# if nt option selected, copy from terget directory to second target directory
if [ ! -z "${SECONDTARGETDIRECTORY}" ] 
then
	CopyFiles $SECONDTARGETDIRECTORY
fi

# If r option selected remove all copied files from first target directory
if [ "$REMOVE" = true ] && [ ! -z "${SECONDTARGETDIRECTORY}" ] 
then
	RemoveFiles ${FILENAMES[@]}
fi

unset VALID SOURCEDIRECTORY TARGETDIRECTORY SECONDTARGETDIRECTORY FILEPATH FILENAMES BASEFOLDER EWBD

shift $(($OPTIND -1))
