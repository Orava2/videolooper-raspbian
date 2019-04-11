#!/bin/bash
# Bash script by Tim Schwartz, http://www.timschwartz.org/raspberry-pi-video-looper/ 2013
# Comments, clean up, improvements by Derek DeMoss, for Dark Horse Comics, Inc. 2015
# Added USB support, full path, support files with spaces in names, support more file formats - Tim Schwartz, 2016

# Requires: omxplayer, fbi, pqiv

# Version 0.3.4, remember position of PLAYING index after, added subtitles.
# Version 0.3.3, fix: removed -r parameter from omxplayer.
# Version 0.3.2, fix: filemane 03.jpg is displayed for default delay, not 3 seconds.
# Version 0.3.1, added html support.
# Version 0.3.0, added 'pqiv -f -i blank.png&' to open blank image. This hides desktop elements.
# Version 0.2, added fbi for displaying images
# Version 0.1, moved updating playing index to the end of the loop. Otherwise playing starts from index 1 instead of 0.


declare -A VIDS # make variable VIDS an Array

LOCAL_FILES=/var/www/html/files/ # A variable of this folder
USB_FILES=/mnt/usbdisk/ # Variable for usb mount point
VIDEO_FORMATS='mov|mp4|mpg|mkv'  # If you want o exclude files rename files eg to video.mp4.x
IMAGE_FORMATS='png|jpg|bmp|gif'
WEB_FORMATS='html|htm|php'
DEFAULT_DELAY=15 # Defaul delay for images and html pages
RESTORE_POS=0 # Set to 1 if you want script to remember playing position after restart.

CURRENT=0 # Number of videos in the folder
PLAYING=0 # Video that is currently playing

getvids () # Since I want this to run in a loop, it should be a function
{
unset VIDS # Empty the VIDS array
CURRENT=0 # Reinitializes the video count
IFS=$'\n' # Dont split up by spaces, only new lines when setting up the for loop
for f in `ls $LOCAL_FILES | grep -Ei "$VIDEO_FORMATS|$IMAGE_FORMATS|$WEB_FORMATS"` # Step through the local files
do
	if echo ${f} | rev | cut -d '.' -f 1 | rev | grep -Ei "$VIDEO_FORMATS|$IMAGE_FORMATS|$WEB_FORMATS" > /dev/null;  then # Check if file extensions is VIDEO_FORMATS
		VIDS[$CURRENT]=$LOCAL_FILES$f # add the filename found above to the VIDS array
	 	#echo Index=$CURRENT File=${VIDS[$CURRENT]} # Print the array element we just added
		let CURRENT+=1 # increment the video count
	fi
done
if [ -d "$USB_FILES" ]; then
  for f in `ls $USB_FILES |  grep -Ei "$VIDEO_FORMATS|$IMAGE_FORMATS|$WEB_FORMATS"` # Step through the usb files
	do
		if echo ${f} | rev | cut -d '.' -f 1 | rev | grep -Ei "$VIDEO_FORMATS|$IMAGE_FORMATS|$WEB_FORMATS" > /dev/null;  then
			VIDS[$CURRENT]=$USB_FILES$f # add the filename found above to the VIDS array
			#echo ${VIDS[$CURRENT]} # Print the array element we just added
			let CURRENT+=1 # increment the video count
		fi
	done
fi
}

VID_SERVICE='omxplayer' # The program to play the videos
IMG_SERVICE='fbi' # The program to display images
WEB_SERVICE='chromium-browse' # In process list last r character is not displayed.

# Let's move to the scipt's directory. This is needed if script is called from crontab etc.
# Absolute path this script is in, like /home/user/bin (no / at the end)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd ${SCRIPT_DIR}

# Kill processes if they have started before running this script.
pkill -9 "$WEB_SERVICE" # Kill chromium process.
pkill -9 "$IMG_SERVICE" # Kill omxplayer process.
pkill -9 "$VID_SERVICE" # Kill fbi process.
pkill -9 "pqiv" # Kill pqiv process.
sleep 2

# Open black image to backround.
pqiv -f -i blank.png&
sleep 2

# Remember position of PLAYING index after restart if RESTOR_POR =! 0 
if [ $RESTORE_POS -ne 0 ]
then
	BLKID=`blkid -s PARTUUID -o value /dev/sda1`
	[ -f /var/tmp/play_${BLKID} ] && PLAYING=`cat /var/tmp/play_${BLKID}`
fi

getvids # Get a list of the current videos in the folder
# check that old restored PLAYING index is not pointing outside of the array.
if [ $PLAYING -ge $CURRENT ] # if PLAYING is greater than or equal to CURRENT
then
	PLAYING=0 # Reset to 0 so we play the "first" video
fi


while true; do # Main loop for displaying videos, images and web pages.
	getvids # Get a list of the current videos in the folder
	while ps ax | grep -v grep | grep -E "$VID_SERVICE|$IMG_SERVICE" > /dev/null; do # Wait untill omxplayer or fbi stops. Search for service, print to null.
		sleep 0.1
	done
	# Save current PLAYING index to a file.
	echo $(($PLAYING)) > /var/tmp/play_`blkid -s PARTUUID -o value /dev/sda1`
	
	if [ $CURRENT -gt 0 ] #only play videos if there are more than one video
	then
	 	if [ -f ${VIDS[$PLAYING]} ]; then

			FULL_FILENAME=${VIDS[$PLAYING]}
			FILENAME=${FULL_FILENAME##*/}
			# Images
			if echo "${FILENAME##*.}" | grep -Eiq ${IMAGE_FORMATS} > /dev/null; then # grep with -i returns true if formats are found and false if not.
				DELAY="$(echo "${FILENAME}" | rev | cut -d '.' -f 2 | rev )"  # Delay for image is read from filname. image.30.jpg is displayed for 30 seconds.
				# Check if DELAY is an integer number and check if file name contains more than one dot. More than one dot is required so numbers in file names 01.jpg 02.jpg etc is not used as a delay. 
				if ! ( [[ "$DELAY" =~ ^[0-9]+$ ]] &&  [[ "$(echo "${FILENAME}" | grep -o '\.' | wc -l)" -gt 1 ]] ) #
				then
        				DELAY=${DEFAULT_DELAY}	# If not number found use default delay.
				fi
				echo "Displaying image file ${VIDS[$PLAYING]}"
				fbi -noverbose -nocomments -T 7 -1 -t ${DELAY}  ${VIDS[$PLAYING]} >/dev/null; # Image is displayed in virtual console 7.

			fi
			# Videos
			if echo "${FILENAME##*.}" | grep -Eiq ${VIDEO_FORMATS} > /dev/null;  then
				echo "Playing video file ${VIDS[$PLAYING]}"
				omxplayer -o hdmi -t 0 --align center ${VIDS[$PLAYING]} > /dev/null # Play video
				#xrefresh -display :0 

			fi
			# web pages
			if echo "${FILENAME##*.}" | grep -Eiq ${WEB_FORMATS} > /dev/null;  then
				echo "Display web page ${VIDS[$PLAYING]}"
				DELAY="$(echo "${FILENAME}" | rev | cut -d '.' -f 2 | rev )" # Delay for html pages is read from filname. weather_and_news.300.html is displayed for 300 seconds.
				# Check if DELAY is an integer number and check if file name contains more than one dot. More than one dot is required so numbers in file names 01.html 02.html etc is not used as a delay. 
				if ! ( [[ "$DELAY" =~ ^[0-9]+$ ]] &&  [[ "$(echo "${FILENAME}" | grep -o '\.' | wc -l)" -gt 1 ]] ) #
				then
        				DELAY=${DEFAULT_DELAY}	# If not number found use default delay.
				fi
				echo "Opening web page ${VIDS[$PLAYING]}"
				DISPLAY=:0 chromium-browser --no-sandbox --noerrdialogs --disable-session-crashed-bubble --disable-infobars --kiosk --incognito ${VIDS[$PLAYING]} > /dev/null & # Open web page in Chromium by using kiosk mode.
				sleep ${DELAY} # Wait for defay
				pkill -9 "$WEB_SERVICE" # Kill Chromium process.
			fi

		fi
		# Update playing index.
		let PLAYING+=1
		if [ $PLAYING -ge $CURRENT ] # if PLAYING is greater than or equal to CURRENT
		then
			PLAYING=0 # Reset to 0 so we play the "first" video
		fi

	else # if [ $CURRENT -gt 0 ] 
		echo "Insert USB with videos and restart or add videos to ${LOCAL_FILES} and run ./startvideo.sh"
		sleep 5
	fi

done


