# mpv-video-splice
An mpv player script that helps you create a video out of cuts made in the current playing video.

**Requires: ffmpeg**


# Description
This script provides the hability to create video slices by grabbing two
timestamps, which generate a slice from timestamp A to timestamp B,
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

**Note:** This script will also silence the terminal, so the script messages
can be seen more clearly.


# Installation

## FFMPEG
It's important to remember that `ffmpeg` **MUST** be installed in order for the script to work.

### Installing ffmpeg on Linux
On Linux systems, it's very likely that it will already be installed, since it's an `mpv` dependency,
although, in case it's not installed, it can likely be installed by using the distribution's own package manager.
Nonetheless, there are packages listed for Linux on the [ffmpeg.org](https://ffmpeg.org/download.html) website.

### Installing ffmpeg on Windows
In order to install `ffmpeg` on Windows, just go to the [official ffmpeg download page](https://ffmpeg.org/download.html) and select the Windows logo.
It should show two links on how to proceed with the installation. I personally recommend using the [gyan.dev](https://www.gyan.dev/ffmpeg/builds/) one.

## Linux
To install this script on a Linux machine, simply add it to your script folder, located at `$HOME/.config/mpv/scripts`

When the mpv player gets started up, the script will be executed and will be ready to use.

## Windows
To insall this script on a Windows machine, it must be added to a `scripts` folder that will be located in one of these directories described below:

- `%APPDATA%\mpv\scripts`

If the script doesn't work on the directory above, go to the directory where `mpv` is installed,
create a folder called `portable_config` and inside of it, create a folder called `scripts` and, finally, put the script insde of it.


# Configuring
This script uses `mp.options` to allow the user to customize some of the script usage to their own will.
To apply your own config values, you can either call `mpv` passing them as arguments, or use a config file. Below are how to use both ways of configuring.

**Script name: `mpv-splice`**
To be used in the config!

## Using arguments
To use arguments, do as shown below
```sh
mpv --script-opts=script_name-optionA=ValueA,script_name-optionB="My Value B",...
```
On windows, arguments can be passed the same way inside a shortcut properties.

Notice that, when using this method, it needs two identifiers to apply the values to the correct script, and those are the `script_name`, that refers to the name of the script, that is defined in the script code itself (in this case, the name is `mpv-splice`

## Using a config file
In order to use a config file, a `.conf` file must be created inside a directory called `script-ops`, in the same directory as the `scripts` directory is located. If it doesn't exist, create it and put the config file inside.
The config file name must match the script name, defined in the code. In this case, it will be `mpv-splice.conf` and its contents are simply `key=value` pairs, as follows:
```
optionA=valueA
optionB=My Value B
...
```

## Available config options
So far, it accepts the following values:
- **concat_file_name**: Refers to the name of the concatenation file used by ffmpeg when joining the pieces; (**default:** `concat`)
- **ffmpeg_cmd**: ffmpeg command to be ran; (**default:** `ffmpeg -hide_banner -loglevel warning`)
- **ffmpeg_filter**: ffmpeg filter; (**default:** `-c copy -copyts -avoid_negative_ts make_zero`)
- **tmp_path**: Path that will be used to temporarily store the pieces; (**default:** `/tmp` on Linux and `%LOCALAPPDATA%/Temp` on Windows)
- **output_path**: Output path for the resulting video; (**default:** [the working directory of the mpv process](https://mpv.io/manual/master/#command-interface-working-directory))

**Make sure the directories set really exist, or else the script will fail!**


# Usage
This section correspond to the shortcut keys provided by this script.

### Alt + T (Grab timestamp)
In the video screen, press `Alt + T` to grab the first timestamp and then
press `Alt + T` again to get the second timestamp. This process will generate
a time range, which represents a video slice. Repeat this process to create
more slices.

### Alt + P (Print slices)
To see all the slices made, press `Alt + P`. All of the slices will appear
in the terminal in order of creation, with their corresponding timestamps.
Incomplete slices will show up as `Slice N in progress`, where N is the
slice number.

### Alt + R (Reset unfinished slice)
To reset an incomplete slice, press `Alt + R`. If the first part of a slice
was created at the wrong time, this will reset the current slice.

### Alt + D (Delete slice)
To delete a whole slice, start the slice deletion mode by pressing `Alt + D`.
When in this mode, it's possible to press `Alt + NUM`, where `NUM` is any
number between 0 inclusive and 9 inclusive. For each `Alt + NUM` pressed, a
number will be concatenated to make the final number referring to the slice 
to be removed, then press `Alt + D` again to stop the slicing deletion mode
and delete the slice corresponding to the formed number.

Example 1: Deleting slice number 3
* `Alt + D`	# Start slice deletion mode
* `Alt + 3`	# Concatenate number 3
* `Alt + D`	# Exit slice deletion mode

Example 2: Deleting slice number 76
* `Alt + D`	# Start slice deletion mode
* `Alt + 7`	# Concatenate number 7
* `Alt + 6`	# Concatenate number 6
* `Alt + D`	# Exit slice deletion mode

### Alt + C (Compiling final video)
To fire up ffmpeg, which will slice up the video and concatenate the slices
together, press `Alt + C`. It's important that there are at least one
slice, otherwise no video will be created.

**Note:** No cut will be made unless the user presses `Alt + C`.
Also, the original video file **won't** be affected by the cutting.

## TL;DR
| Shortcut key | Action |
| ------------ | ------ |
| Alt + T      | Grab timestamp |
| Alt + P      | Print slices |
| Alt + R      | Reset unfinished slice |
| Alt + D      | Enter/Exit slice deletion mode |
| Alt + 1..9   | Pick a slice number when in slice deletion mode |
| Alt + C      | Compile the final video |

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

# How it was coded
At first, the script was all written based upon a table that would carry the timestamp intervals
inside of it, as a sort of list of pairs, which made the code look very confusing
(at least to me, when looking at it years later).

Then, inspired by a [document showing how to mimic OOP in Lua](http://lua-users.org/wiki/ObjectOrientationTutorial),
As I saw this I figure it would be easier to use this idea to keep track of important states
inside the script, and also keep them in one place, instead of let them be all scattered around like it originally was.
I decided to use this idea to also make the code, hopefully, more readable (debatable) and
maintainable (also debatable). So that's what I went for.

To summarize, take this example below
```lua
hello = {
    _private_value = "Hello, World!",

    _capitalize = function(self)
        return self._private_value:upper()
    end,

    say_hello = function(self, name)
        local message = self:_capitalize() .. " My name is: " .. name

        print(message)
    end,
}

hello:say_hello("pvpscript") -- HELLO, WORLD! My name is: pvpscript
```

# TODO
- Update "environment variables" section to reflect the new use of config [DONE]
- Describe how the code was rewritten (inspired by http://lua-users.org/wiki/ObjectOrientationTutorial) [DONE]
- Add an instalation section for windows [DONE]
- Create a TL;DR for the usage [DONE]
- **The last part of the code can still be further improved by using the table method I went for.**
- Talk about the workaround to use coroutines inside a self referencing table
- Create a template for issues
