# Update (Orava2)
1: Added support for images. Program calls fbi for displaying images. Duration for images is given in file name. For example nature_photo.20.jpg is displayed for 20 seconds.

2: Added html support. Htm, html and php files are opened in Chromium. Duration for web page is is given in file name. Forexample web_page.300.html is displayed 300 seconds.

Notes: Use sudo to run startvideo.sh. Requires omxplayer, pqiv, fbi and chromium.

3: Added auxiliary script WegPageToImage whick can be used to take a screenshots of web pages.
```
./WebPageToImage.sh webpagelist.txt /output/dir/
```

# Video Looper for Raspbian
Automatically play and loop fullscreen videos on a Raspberry Pi 2 or 3.

This system uses a basic bash script to play videos with [omxplayer](http://elinux.org/Omxplayer), it simply checks if omxplayer isn't running and then starts it again. This simple method seems to work flawlessly for weeks on end without freezing or glitches. The only caveat of this method is that there are approximately 2-3 seconds of black between each video. If you are looking to do something with gapless looping on Raspberry Pi, try [Slooper](https://github.com/mokafolio/Slooper) by [Matthias Dörfelt](http://www.mokafolio.de/), though currently it needs a few updates to work without a remote (as of May 15, 2016).

There is a [videolooper](https://github.com/adafruit/pi_video_looper) written in python that uses omxplayer by [Adafruit](http://www.adafruit.com), but unfortunately on testing looping videos for more than a day it froze (as of May 15, 2016).

The script will look for videos either in:
* the `video` directory in the home directory of the pi user
* a usb stick plugged in before startup (this will not be remounted if you pull it out and plug it back in)

# Installation

## Grab 'n Go
Copy the [prebuilt img](http://timschwartz.org/downloads/2016-05-10-raspbian-jessie-lite-video-looper.img.zip) to a micro SD card using [these instructions](https://www.raspberrypi.org/documentation/installation/installing-images/). The img was setup using the steps below and `2016-05-10-raspbian-jessie-lite` was used as the base raspbian image.

## Roll Your Own
Start with a [raspbian img](https://www.raspberrypi.org/downloads/raspbian/), install it on the pi, and follow the steps below to install the videolooper.

### Install omxplayer
```
sudo apt-get update
sudo apt-get -y install omxplayer
```

### Setup auto mounting of usb stick
```
sudo mkdir -p /mnt/usbdisk
sudo echo \"/dev/sda1		/mnt/usbdisk	vfat	ro,nofail	0	0\" | sudo tee -a /etc/fstab
```

### Create folder for videos in home directory
`mkdir /home/pi/video`

### Download startvideo.sh and put it in /home/pi/
```
cd /home/pi
wget https://raw.githubusercontent.com/timatron/videolooper-raspbian/master/startvideo.sh
chmod uga+rwx startvideo.sh
```

### Add startvideo.sh to .bashrc so it auto starts on login
`echo \"/home/pi/startvideo.sh" | tee -a /home/pi/.bashrc`

### Make system autoboot into pi user
`sudo raspi-config`
* Select option: "3 Boot Options"
* Select option: "B2 Console Autologin"

### Expand your root partition if you want to
`sudo raspi-config`
* Select option: "1 Expand Filesystem"
