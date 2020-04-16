-- -----------------------------------------------------------------------------
--
-- MPV Splice
-- URL: https://github.com/pvpscript/mpv-video-splice
--
-- Requires: ffmpeg
--
-- Description:
--
-- This script provides the hability to create video slices by grabbing two
-- timestamps, which generate a slice from timestamp A[i] to timestamp B[i],
-- e.g.:
-- 	-> Slice 1: 00:10:34.25 -> 00:15:00.00.
-- 	-> Slice 2: 00:23:00.84 -> 00:24:10.00.
-- 	...
-- 	-> Slice n: 01:44:22.47 -> 01:56:00.00.
--
-- Then, all the slices from 1 to n are joined together, creating a new
-- video.
--
-- The output file will appear at the directory that the mpv command was ran.
--
-- Note: This script prevents the mpv player from closing when the video ends,
-- so that the slices don't get lost. Keep this in mind if there's the option
-- 'keep-open=no' in the current config file.
--
--
-- -----------------------------------------------------------------------------
--
--
-- Usage:
-- 
-- In the video screen, press Alt + T to grab the first timestamp and then
-- press Alt + T again to get the second timestamp. This process will generate
-- a time range, which represents a video slice. Repeat this process to create
-- more slices.
--
-- To see all the slices made, press Alt + P. All of the slices will appear
-- in the terminal in order of creation, with their corresponding timestamps.
--
-- To fire up ffmpeg, which will slice up the video and concatenate the slices
-- together, press Alt + C. It's important that there are at least one
-- slice, otherwise no video will be created.
--
-- Note: No cut will be made unless the user presses Alt + C.
-- Also, the original video file won't be affected by the cutting.
--
--
-- -----------------------------------------------------------------------------
--
--
-- Log level:
--
-- Everytime a timestamp is grabbed, a text will appear on the screen showing
-- the selected time.
-- When Alt + P is pressed, besides showing the slices in the terminal, 
-- it will also show on the screen the total number of cuts (or slices)
-- that were made.
-- When the actual cutting and joining process begins, a message will be shown
-- on the screen and the terminal telling that it began. When the process ends,
-- a message will appear on the screen and the terminal displaying the full path
-- of the generated video. It will also appear a message in the terminal telling
-- that the process ended.
--
-- Note: Every message that appears on the terminal has the log level of 'info'.
--
--
-- -----------------------------------------------------------------------------
--
--
-- Tweaks:
--
-- Now you, the user, can change the temporary's path location by changing the
-- content of a variable called 'tmp_location'. This is where a directory will
-- be created by the script, so each cut has a place to be put before they are
-- joined together. After this process, the directory that was created will be
-- removed. Note that the directory set by the 'tmp_location' variable won't be
-- deleted.
--
--
-- -----------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Importing the mpv libraries

local mp = require 'mp'
local msg = require 'mp.msg'

--------------------------------------------------------------------------------
-- Those variables below can be tweaked at your will, but make sure you know
-- what you are doing.

local tmp_location = "/tmp"

--------------------------------------------------------------------------------
-- Don't make changes in the variables below, unless you are ABSOLUTELY sure
-- about how they work and want to make changes to the script's code.

local concat_name = "concat.txt"
local ffmpeg = "ffmpeg -hide_banner -loglevel warning"
local times = {}
local start_time = nil

--------------------------------------------------------------------------------

function notify(duration, ...)
	local args = {...}
	local text = ""

	for i, v in ipairs(args) do
		text = text .. tostring(v)
	end

	msg.info(text)
	mp.command(string.format("show-text \"%s\" %d 1",
		text, duration))
end

local function get_time()
	local time_in_secs = mp.get_property_number('time-pos')

	local hours = math.floor(time_in_secs / 3600)
	local mins = math.floor((time_in_secs - hours * 3600) / 60)
	local secs = time_in_secs - hours * 3600 - mins * 60

	local fmt_time = string.format('%02d:%02d:%05.2f', hours, mins, secs)

	return fmt_time
end

function put_time()
	local time = get_time()

	if not start_time then
		start_time = time
	else
		times[#times+1] = {
			t_start = start_time,
			t_end = time
		}
		start_time = nil
	end

	notify(2000, "Selected time: ", time)
end

function show_times()
	notify(2000, "Total cuts: ", #times)

	for i, obj in ipairs(times) do
		msg.info(i, ": ", obj.t_start, " -> ", obj.t_end)
	end
end

function process_video()
	local alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	local rnd_size = 10

	local pieces = {}

	math.randomseed(os.time())
	math.random(); math.random(); math.random()

	if times[#times] then
		local tmp_dir = io.popen(string.format("mktemp -d -p %s",
			tmp_location)):read("*l")
		local input_file = mp.get_property("path")
		local ext = string.gmatch(input_file, ".*%.(.*)$")()

		local rnd_str = ""
		for i=1,rnd_size,1 do
			local rnd_index = math.floor(math.random() * #alphabet + 0.5)
			rnd_str = rnd_str .. alphabet:sub(rnd_index, rnd_index)
		end

		local output_file = string.format("%s/%s_%s_cut.%s",
			mp.get_property("working-directory"),
			mp.get_property("filename/no-ext"),
			rnd_str, ext)

		local cat_file_name = string.format("%s/%s", tmp_dir, "concat.txt")
		local cat_file_ptr = io.open(cat_file_name, "w")

		notify(2000, "Process started!")

		for i, obj in ipairs(times) do
			local path = string.format("%s/%s_%d.%s",
				tmp_dir, rnd_str, i, ext)
			cat_file_ptr:write(string.format("file '%s'\n", path))
			os.execute(string.format("%s -i \"%s\" -ss %s -to %s \"%s\"",
				ffmpeg, input_file,
				obj.t_start, obj.t_end,
				path))
		end

		cat_file_ptr:close()

		cmd = string.format("%s -f concat -safe 0 -i \"%s\" -c copy \"%s\"",
			ffmpeg, cat_file_name, output_file)
		os.execute(cmd)

		notify(10000, "File saved as: ", output_file)
		msg.info("Process ended!")

		os.execute(string.format("rm -rf %s", tmp_dir))
		msg.info("Temporary directory removed!")
	end
end

mp.set_property("keep-open", "yes") -- Prevent mpv from exiting when the video ends

mp.add_key_binding('Alt+t', "put_time", put_time)
mp.add_key_binding('Alt+p', "show_times", show_times)
mp.add_key_binding('Alt+c', "process_video", process_video)
