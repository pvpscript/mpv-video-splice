# mpv-video-splice
An mpv player script that helps you create a video out of cuts made in the current playing video.

**Requires: ffmpeg**

## Description
This script provides the hability to create video slices by grabbing two
timestamps, which generate a slice from timestamp A[i] to timestamp B[i],
e.g.:
	
	-> Slice 1: 00:10:34.25 -> 00:15:00.00;
	-> Slice 2: 00:23:00.84 -> 00:24:10.00;
	...
	-> Slice n: 01:44:22.47 -> 01:56:00.00;
	

Then, all the slices from 1 to n are joined together, creating a new
video.

**The output file will appear at the directory that the mpv command was ran.**

**Note:** This script prevents the mpv player from closing when the video ends,
so that the slices don't get lost. Keep this in mind if there's the option
`keep-open=no` in the current config file.

## Usage
In the video screen, press `Alt + T` to grab the first timestamp and then
press `Alt + T` again to get the second timestamp. This process will generate
a time range, which represents a video slice. Repeat this process to create
more slices.

To see all the slices made, press `Alt + P`. All of the slices will appear
in the terminal in order of creation, with their corresponding timestamps.

To fire up ffmpeg, which will slice up the video and concatenate the slices
together, press `Alt + C`. It's important that there are at least one
slice, otherwise no video will be created.

**Note:** No cut will be made unless the user presses `Alt + C`.
Also, the original video file **won't** be affected by the cutting.

## Log Level
Everytime a timestamp is grabbed, a text will appear on the screen showing
the selected time.
When `Alt + P` is pressed, besides showing the slices in the terminal, 
it will also show on the screen the total number of cuts (or slices)
that were made.
When the actual cutting and joining process begins, a message will be shown
on the screen and the terminal telling that it began. When the process ends,
a message will appear on the screen and the terminal displaying the full path
of the generated video. It will also appear a message in the terminal telling
that the process ended.

**Note:** Every message that appears on the terminal has the **log level of 'info'**.

## Environment Variables:
This script uses environment variables to allow the user to
set the temporary location of the video cuts and for setting the location for
the resulting video.

To set the temporary directory, set the variable MPV\_SPLICE\_TEMP;
e.g.: `export MPV\_SPLICE\_TEMP="$HOME/temporary\_location"`

To set the video output directory, set the variable MPV\_SPLICE\_OUTPUT;
e.g.: `export MPV\_SPLICE\_OUTPUT="$HOME/output\_location"`

**Make sure the directories set in the variables really exist, or else the
script might fail.**



# Installation

To install this script, simply add it to your script folder, located at
`$HOME/.config/mpv/scripts`

When the mpv player gets started up, the script will be executed and will be ready to use.
