#!/bin/bash
# Extracts the audio and video from an existing MPEG-4 and repacks them into a 
# PS3 compatible MPEG-4	

# Remove the temporary files
function clean_up {
	${CMD_RM} ${TMP_TRACKS} 2>/dev/null			
	${CMD_RM} "${VIDEO_FILENAME}" 2>/dev/null			
	${CMD_RM} "${AUDIO_FILENAME}" 2>/dev/null			
}	

# Check that the required tools are available.
# One parameters taken as input
#  - $1 : The unpathed tool name.
#  - $2 : Specify that the tool is "required" or "optional"
function validate_tool {
	local TOOL=${1}
	local REQUIREMENT=${2}	
	local TOOL_PATH=`which ${TOOL}`
	
	# If the tool is required, how do we handle that?
	if [ "${REQUIREMENT}" == "required" ]; then
		if [ -z ${TOOL_PATH} ]; then
			echo " - ERROR! '${TOOL}' was not found in the path."
			echo "   Please install the package that contains '${TOOL}' or compile it or put it in the path."
			clean_up
			exit 1
		else
			echo ${TOOL_PATH}
		fi		
	else # The tool is option, what do we do?
		if [ -z ${TOOL_PATH} ]; then
			echo #return nothing
		else
			echo ${TOOL_PATH}
		fi	
	fi
}

# Have we got enough parameters?
if [ $# -lt 1 ]; then
    echo "ERROR! ${0} requires a .mp4 file as input, for example:"
    echo "  ${0} movie.mp4"
	clean_up    
    exit 1
else
    MP4_FILENAME=${1}
fi

# Define the commands we will be using. If you don't have them, get them! ;-)
# TODO! These need validating and we need to prompt the user if any are missing from their system.
CMD_FILE=`validate_tool file required`
CMD_STAT=`validate_tool stat required`
CMD_GREP=`validate_tool grep required`
CMD_CUT=`validate_tool cut required`
CMD_SED=`validate_tool sed required`
CMD_RM=`validate_tool rm required`
CMD_MKTEMP=`validate_tool mktemp required`
CMD_MP4INFO=`validate_tool mp4info required`
CMD_MP4BOX=`validate_tool MP4Box required`

# Is the .mkv a real Matroska file?
MP4_VALID=`${CMD_FILE} "${MP4_FILENAME}" | ${CMD_GREP} "MPEG v4"`
MOV_VALID=`${CMD_FILE} "${MP4_FILENAME}" | ${CMD_GREP} "ISO Media, Apple QuickTime movie"`
if [ -z "${MP4_VALID}" ] && [ -z "${MOV_VALID}" ]; then
    echo "ERROR! ${0} requires valid a MPEG-4 file as input."
    exit 1 
fi

# Get the track details
echo "Getting MPEG-4 file details"
TMP_TRACKS=`${CMD_MKTEMP}`
${CMD_MP4INFO} "${MP4_FILENAME}" > ${TMP_TRACKS}

# Get the track ids for audio/video, this assumes one audio and one video track currently.
VIDEO_ID=`${CMD_GREP} video ${TMP_TRACKS} | ${CMD_CUT} -f1 | ${CMD_SED} 's/ //g'`
AUDIO_ID=`${CMD_GREP} audio ${TMP_TRACKS} | ${CMD_CUT} -f1 | ${CMD_SED} 's/ //g'`

# Get the audio/video format. Strip the V_, A_ and brackets.
VIDEO_FORMAT=`${CMD_GREP} video ${TMP_TRACKS} | ${CMD_CUT} -f3 | ${CMD_CUT} -d' ' -f1 | ${CMD_SED} 's/ //g'`
AUDIO_FORMAT=`${CMD_GREP} audio ${TMP_TRACKS} | ${CMD_CUT} -f3 | ${CMD_CUT} -d',' -f1 | ${CMD_SED} 's/MPEG-4\|LC\| //g'`

VIDEO_FPS=`${CMD_GREP} video ${TMP_TRACKS} | ${CMD_CUT} -d'@' -f3 | ${CMD_SED} 's/ \|fps//g'`

# What did we find?
echo " - Video is on Track ${VIDEO_ID} and of format ${VIDEO_FORMAT} @ ${VIDEO_FPS}fps"
echo " - Audio is on Track ${AUDIO_ID} and of format ${AUDIO_FORMAT}"

FILENAME=`echo "${MP4_FILENAME}" | ${CMD_SED} 's/.mp4//' | ${CMD_SED} 's/.mov//'`

VIDEO_FILENAME="${FILENAME}".${VIDEO_FORMAT}
AUDIO_FILENAME="${FILENAME}".${AUDIO_FORMAT}
NEW_FILENAME="${FILENAME}"_repacked.mp4

# If the extracted video file already exists, prompt the user if we should re-extract
if [ -e "${VIDEO_FILENAME}" ] && [ -e "${AUDIO_FILENAME}" ]; then
    read -n 1 -s -p " - WARNING! Detected extracted audio/video. Do you want to re-extract the audio/video? (y/n) : " EXTRACT        
    echo
else
    EXTRACT="y"
fi

# Extract the tracks, if required.
if [ "${EXTRACT}" == "y" ]; then
	#Extract the video
	${CMD_RM} "${VIDEO_FILENAME}" 2>/dev/null
	${CMD_MP4BOX} -raw ${VIDEO_ID} "${MP4_FILENAME}" -out "${VIDEO_FILENAME}"

	#Extract the audio
	${CMD_RM} "${AUDIO_FILENAME}" 2>/dev/null
	${CMD_MP4BOX} -raw ${AUDIO_ID} "${MP4_FILENAME}" -out "${AUDIO_FILENAME}"
fi

#Check the file size to see if wee need to split.
# Get the size of the .mkv file in bytes (b)
MP4_SIZE=`${CMD_STAT} "${MP4_FILENAME}" | ${CMD_GREP} Size | ${CMD_CUT} -f1 | ${CMD_SED} 's/ \|Size://g'`

# The PS3 can't play MP4 files which are bigger than 4GB and FAT32 doesn't like files bigger than 4GB.
# Lets figure out if we need to split the MP4 we are muxing and if so what the split size should be in kilo-bytes (kb)
if [ ${MP4_SIZE} -ge 12884901888 ]; then    
	# >= 12gb : Split into 3.5GB chunks ensuring PS3 and FAT32 compatibility
	SPLIT_SIZE="-split-size 3670016"		
elif [ ${MP4_SIZE} -ge 9663676416 ]; then   
	# >= 9gb  : Divide .mkv filesize by 3 and split by that amount
	SPLIT_SIZE="-split-size "$(((${MKV_SIZE} / 3) / 1024))
elif [ ${MP4_SIZE} -ge 4294967296 ]; then   
	# >= 4gb  : Divide .mkv filesize by 2 and split by that amount
	SPLIT_SIZE="-split-size "$(((${MKV_SIZE} / 2) / 1024))
else										
	# File is small enough to not require splitting
	SPLIT_SIZE=""
fi

#Remux the MPEG-4
echo "Re-packing the new MPEG-4"
${CMD_MP4BOX} -fps ${VIDEO_FPS} ${SPLIT_SIZE} -add "${VIDEO_FILENAME}" -add "${AUDIO_FILENAME}" -new "${NEW_FILENAME}"

# Clean up
clean_up
echo "All Done!"
