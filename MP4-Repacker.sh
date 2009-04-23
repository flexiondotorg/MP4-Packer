#!/bin/bash
#
# License
#
# Extracts audio and video from MPEG-4 container and repacks it.
# Copyright (c) 2009 Flexion.Org, http://flexion.org/
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.


IFS=$'\n'
VER="1.0"

echo "MP4-Repacker v${VER} - Extracts audio and video from MPEG-4 container and repacks it."
echo "Copyright (c) 2009 Flexion.Org, http://flexion.org. MIT License" 
echo

function usage {
    echo
    echo "Usage"
    echo "  ${0} file.mp4 [--help]"
    echo ""
    echo "You can also pass the following optional parameter"
    echo "  --split : If required, the MPEG-4 output will be split at a boundary less than"
    echo "            4GB for FAT32 compatibility"    
    echo "  --help  : This help."
    echo
    exit 1
}


# Remove the temporary files
function clean_up {
	rm ${TMP_TRACKS} 2>/dev/null			
	rm "${VIDEO_FILENAME}" 2>/dev/null			
	rm "${AUDIO_FILENAME}" 2>/dev/null			
}	

# Define the commands we will be using. If you don't have them, get them! ;-)
REQUIRED_TOOLS=`cat << EOF
cut
file
grep
mkfifo
mktemp
mp4info
rm
sed
stat
MP4Box
EOF`

for REQUIRED_TOOL in ${REQUIRED_TOOLS}
do
    # Is the required tool in the path?
    which ${REQUIRED_TOOL} >/dev/null  
         
    if [ $? -eq 1 ]; then
        echo "ERROR! \"${REQUIRED_TOOL}\" is missing. ${0} requires it to operate."
        echo "       Please install \"${REQUIRED_TOOL}\"."
        exit 1      
    fi        
done

# Get the first parameter passed in and validate it.
if [ $# -lt 1 ]; then
    echo "ERROR! ${0} requires a .mp4 file as input"	
	usage
elif [ "${1}" == "-h" ] || [ "${1}" == "--h" ] || [ "${1}" == "-help" ] || [ "${1}" == "--help" ] || [ "${1}" == "-?" ]; then
    usage
else    
    MP4_FILENAME=${1}
        
	# Is the .mp4 a real MPEG-4 file?
	MP4_VALID=`file "${MP4_FILENAME}" | grep "MPEG v4"`
	MOV_VALID=`file "${MP4_FILENAME}" | grep "ISO Media, Apple QuickTime movie"`
	if [ -z "${MP4_VALID}" ] && [ -z "${MOV_VALID}" ]; then
	    echo "ERROR! ${0} requires valid a MPEG-4 file as input."
    	exit 1 
	fi
    shift
fi

# Check for optional parameters
while [ $# -gt 0 ]; 
do	
	case "${1}" in
		-s|--split|-split)
			#Check the file size to see if wee need to split.
			# Get the size of the .mp4 file in bytes (b)
			MP4_SIZE=`stat -c%s "${MP4_FILENAME}"`            

			# The PS3 can't play MP4 files which are bigger than 4GB and FAT32 doesn't like files bigger than 4GB.
			# Lets figure out if we need to split the MP4 we are muxing and if so what the split size should be in kilo-bytes (kb)
			if [ ${MP4_SIZE} -ge 12884901888 ]; then    
				# >= 12gb : Split into 3.5GB chunks ensuring PS3 and FAT32 compatibility
				SPLIT_SIZE="-split-size 3670016"		
			elif [ ${MP4_SIZE} -ge 9663676416 ]; then   
				# >= 9gb  : Divide filesize by 3 and split by that amount
				SPLIT_SIZE="-split-size "$(((${MP4_SIZE} / 3) / 1024))
			elif [ ${MP4_SIZE} -ge 4294967296 ]; then   
				# >= 4gb  : Divide filesize by 2 and split by that amount
				SPLIT_SIZE="-split-size "$(((${MP4_SIZE} / 2) / 1024))
			else										
				# File is small enough to not require splitting
				SPLIT_SIZE=""
			fi
            shift;;  
        -h|--h|-help|--help|-?)
            usage;;                  
       	*)
           echo "ERROR! \"${1}\" is not s supported parameter."
           usage;;            
	esac    
done

# Get the track details
echo "Getting MPEG-4 file details"
TMP_TRACKS=`mktemp`
mp4info "${MP4_FILENAME}" > ${TMP_TRACKS}

# Get the track ids for audio/video, this assumes one audio and one video track currently.
VIDEO_ID=`grep video ${TMP_TRACKS} | cut -f1 | sed 's/ //g'`
AUDIO_ID=`grep audio ${TMP_TRACKS} | cut -f1 | sed 's/ //g'`

# Get the audio/video format. Strip the V_, A_ and brackets.
VIDEO_FORMAT=`grep video ${TMP_TRACKS} | cut -f3 | cut -d' ' -f1 | sed 's/ //g'`
AUDIO_FORMAT=`grep audio ${TMP_TRACKS} | cut -f3 | cut -d',' -f1 | sed 's/MPEG-4\|LC\| //g'`

VIDEO_FPS=`grep video ${TMP_TRACKS} | cut -d'@' -f3 | sed 's/ \|fps//g'`

# What did we find?
echo " - Video is on Track ${VIDEO_ID} and of format ${VIDEO_FORMAT} @ ${VIDEO_FPS}fps"
echo " - Audio is on Track ${AUDIO_ID} and of format ${AUDIO_FORMAT}"

FILENAME=`echo "${MP4_FILENAME}" | sed 's/.mp4//' | sed 's/.mov//'`

VIDEO_FILENAME="${FILENAME}".${VIDEO_FORMAT}
AUDIO_FILENAME="${FILENAME}".${AUDIO_FORMAT}
NEW_FILENAME="${FILENAME}"_repacked.mp4

#Extract the video
rm "${VIDEO_FILENAME}" 2>/dev/null
MP4Box -raw ${VIDEO_ID} "${MP4_FILENAME}" -out "${VIDEO_FILENAME}"

#Extract the audio
rm "${AUDIO_FILENAME}" 2>/dev/null
MP4Box -raw ${AUDIO_ID} "${MP4_FILENAME}" -out "${AUDIO_FILENAME}"

#Remux the MPEG-4
echo "Re-packing the new MPEG-4"
MP4Box -fps ${VIDEO_FPS} ${SPLIT_SIZE} -add "${VIDEO_FILENAME}" -add "${AUDIO_FILENAME}" -new "${NEW_FILENAME}"

# Clean up
clean_up
echo "All Done!"
