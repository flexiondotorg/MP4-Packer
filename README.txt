License

Extracts audio and video from MPEG-4 container and repacks it.
Copyright (c) 2009 Flexion.Org, http://flexion.org/

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

Introduction

Some of my mobile phones have been able to record video clips in MPEG-4 format.
Sadly some of these clips don't play on the PS3 and those that do stutter 
terribly. I use 'iplayer-dl' to download content from BBC iPlayer. Sadly the 
files are in a Quicktime container and are not playable on the PS3. 

In order to address both these issues I created this script which extracts the 
audio and video from an existing MPEG-4 or ISO Media Apple QuickTime container 
and repacks them in a new MPEG-4 container. The new MPEG-4 files play back just
fine on my PS3 :-)

Optionally splits the resulting MPEG-4, if it will be greater than 4GB, to 
maintain FAT32 compatibility. 

This script works on Ubuntu Linux, should work on any other Linux/Unix flavour 
and possibly Mac OS X providing you have the required tools installed.

Usage

  ./MP4-Repacker.sh file.mp4 [--split] [--help]

You can also pass several optional parameters
  --split : If required, the MPEG-4 output will be split at a boundary less than
            4GB for FAT32 compatibility
  --help  : This help.

Requirements

 - bash, cat, cut, file, grep, mkfifo, mktemp, mp4info, rm, sed, stat, which, 
   MP4Box.
    
Known Limitations

 - Subtitles in the original MPEG-4 or Quicktime container are not preserved.
 
Source Code

You can grab the source from Launchpad. Contributions are welcome :-)

 - https://code.launchpad.net/~flexiondotorg

References

 - n/a

v1.0 2009, 23rd April.
 - Initial release
