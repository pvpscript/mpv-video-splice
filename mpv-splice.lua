-- -----------------------------------------------------------------------------
--
-- MPV Splice
-- URL: https://github.com/teawhydee/mpv-yt-splice
--
-- Read README.md for usage
--
-- -----------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Importing the mpv libraries

local mp = require 'mp'
local msg = require 'mp.msg'
local opt = require 'mp.options'

--------------------------------------------------------------------------------
-- Default variables

local SCRIPT_NAME = "mpv-splice"
local default_tmp_location = "~/tmpXXX"
local default_output_location = mp.get_property("working-directory")
local do_encode = "no"

--------------------------------------------------------------------------------

local splice_options = {
	bind_put_time = 'Alt+t',
	bind_show_times = 'Alt+p',
	bind_process_video = 'Alt+c',
	bind_reset_current_slice = 'Alt+r',
	bind_delete_slice = 'Alt+d',
	bind_toggle_do_encode = 'Alt+e',
	bind_toggle_do_upload = 'Alt+u',

	tmp_location = os.getenv("MPV_SPLICE_TEMP") and os.getenv("MPV_SPLICE_TEMP") or default_tmp_location,
	output_location = os.getenv("MPV_SPLICE_OUTPUT") and os.getenv("MPV_SPLICE_OUTPUT") or default_output_location,
	output_format = "mp4",
	do_encode = "no",
	do_upload = "no",

	online_upload_url = "",
	online_resulting_url = "",
	online_secret = "",
	online_pattern = "",
	online_do_copy_to_clipboard = "no",
}
opt.read_options(splice_options, SCRIPT_NAME)

local ffmpeg = "ffmpeg -hide_banner -loglevel warning"

local times = {}
local start_time = nil
local remove_val = ""

local exit_time = 0

--------------------------------------------------------------------------------

local function notify_without_stdout(duration, ...)
	local args = {...}
	local text = ""

	for i, v in ipairs(args) do
		text = text .. tostring(v)
	end

	mp.command(string.format("show-text \"%s\" %d 1",
	text, duration))
	return text
end

local function notify(duration, ...)
	local text = notify_without_stdout(duration, ...)
	msg.info(text)
end

local function get_time()
	local time_in_secs = mp.get_property_number('time-pos')

	local hours = math.floor(time_in_secs / 3600)
	local mins = math.floor((time_in_secs - hours * 3600) / 60)
	local secs = time_in_secs - hours * 3600 - mins * 60

	local fmt_time = string.format('%02d:%02d:%05.2f', hours, mins, secs)

	return fmt_time
end

local function put_time()
	print(splice_options.output_location)
	local time = get_time()
	local message = ""

	if not start_time then
		start_time = time
		message = "[START TIMESTAMP]"
	else
		--times[#times+1] = {
		table.insert(times, {
			t_start = start_time,
			t_end = time
		})
		start_time = nil

		message = "[END TIMESTAMP]"
	end

	notify(2000, message, ": ", time)
end

local function toggle_do_encode()
	if (do_encode == "yes") then
		do_encode = "no"
		notify(500, "Reencode: False")
	else
		do_encode = "yes"
		notify(500, "Reencode: True")
	end
end

local function toggle_do_upload()
	if (do_upload == "yes") then
		do_upload = "no"
		notify(500, "Upload: False")
	else
		do_upload = "yes"
		notify(500, "Upload: True")
	end
end

local function show_times()
	local notify_text = "Reencode: "
	if (do_encode == "yes") then
		notify_text = notify_text .. "True"
	else
		notify_text = notify_text .. "False"
	end
	notify_text = notify_text .. "; Upload: "
	if (do_upload == "yes") then
		notify_text = notify_text .. "True\n"
	else
		notify_text = notify_text .. "False\n"
	end
	notify_text = notify_text .. "Total cuts: " .. #times .. "\n"
	local print_limit = 10

	for i, obj in ipairs(times) do
		local temp = i .. ": " .. obj.t_start .. " -> " .. obj.t_end
		msg.info(temp)
		if i < print_limit then
			notify_text = notify_text .. temp .. "\n"
		end
	end

	if start_time then
		local temp = "" .. #times+1 .. ": " .. start_time .. " -> in progress..."
		msg.info(temp)
		notify_text = notify_text .. temp .. "\n"
	end

	if #times >= print_limit then
		notify_text = notify_text .. "see rest in stdout.."
	end
	notify_without_stdout(4000, notify_text)
end

local function reset_current_slice()
	if start_time then
		notify(2000, "Slice ", #times+1, " reseted.")

		start_time = nil
	end
end

local function delete_slice()
	if remove_val == "" then
		notify(2000, "Entered slice deletion mode.")

		-- Add shortcut keys to the interval {0..9}.
		for i=0,9,1 do
			mp.add_key_binding("Alt+" .. i, "num_key_" .. i,
			function()
				remove_val = remove_val .. i
				notify(1000, "Slice to remove: " .. remove_val)
			end
			)
		end
	else
		-- Remove previously added shortcut keys.
		for i=0,9,1 do
			mp.remove_key_binding("num_key_" .. i)
		end

		local remove_num = tonumber(remove_val)
		if #times >= remove_num and remove_num > 0 then
			table.remove(times, remove_num)
			notify(2000, "Removed slice ", remove_num)
		else
			notify(2000, "Specified slice doesn't exist")
		end

		remove_val = ""

		msg.info("Exited slice deletion mode.")
	end
end

local function prevent_quit(name)
	if start_time then
		if os.time() - exit_time <= 2 then
			mp.command(name)
		else
			exit_time = os.time()
		end
		notify(3000, "Slice has been marked. Press again to quit")
	else
		mp.command(name)
	end
end

local function process_video()
	local alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	local rnd_size = 10

	-- Better seed randomization
	math.randomseed(os.time())
	math.random(); math.random(); math.random()

	if not times[#times] then
		return
	end
	local tmp_dir = io.popen(string.format("mktemp -d %s",
	splice_options.tmp_location)):read("*l")
	local input_file = mp.get_property("path")
	-- local ext = string.gmatch(input_file, ".*%.(.*)$")()

	local rnd_str = ""
	for i=1,rnd_size,1 do
		local rnd_index = math.floor(math.random() * #alphabet + 0.5)
		rnd_str = rnd_str .. alphabet:sub(rnd_index, rnd_index)
	end

	local output_file = string.format("%s/%s_%s_cut.%s", splice_options.output_location,
			mp.get_property("filename/no-ext"), rnd_str, splice_options.output_format)

	local cat_file_name = string.format("%s/%s", tmp_dir, "concat.txt")
	local cat_file_ptr = io.open(cat_file_name, "w")

	notify(2000, "Process started!")

	-- Getting the individual clips before concating them.
	for i, obj in ipairs(times) do
		local path = string.format("%s/%s_%d.%s",
		tmp_dir, rnd_str, i, splice_options.output_format)
		if (string.find(input_file, "https://")) then
			print ("ONLINE VIDEO DETECTED")
			path = string.format("%s/%s_%d." .. splice_options.output_format,
			tmp_dir, rnd_str, i)
			output_file = string.format("%s/%s_cut." .. splice_options.output_format,
			splice_options.output_location, mp.get_property("media-title"))
			local youtubedl = "youtube-dl --external-downloader ffmpeg --external-downloader-args "
			cat_file_ptr:write(string.format("file '%s'\n", path))
			os.execute(string.format("%s \"-ss %s -to %s\" -f best \"%s\" -o %s",
			youtubedl, obj.t_start, obj.t_end, input_file, path))
		else
			cat_file_ptr:write(string.format("file '%s'\n", path))
			if (do_encode == "yes") then
				os.execute(string.format("%s -ss %s -i \"%s\" -to %s \"%s\"",
				ffmpeg, obj.t_start, input_file, obj.t_end, path))
			else
				os.execute(string.format("%s -ss %s -i \"%s\" -to %s " ..
				"-c copy -copyts -avoid_negative_ts make_zero \"%s\"",
				ffmpeg, obj.t_start, input_file, obj.t_end, path))
			end
			notify( 2000, "Download complete" )
		end

		cat_file_ptr:close()

		output_file = output_file:gsub("\"", "\\\"")
		output_file = output_file:gsub(" ", "_")
		local cmd = string.format("%s -f concat -safe 0 -i \"%s\" " .. "-c copy %s", ffmpeg, cat_file_name, output_file )
		print(cmd)
		os.execute(cmd)
		if (do_upload ~= "yes") then
      notify(10000, "Local file saved as: ", output_file)
		else
			notify(10000, "Local file saved as: ", output_file .. "\nUploading video...")
			print("Uploading video...")
			local cmd_online = "%s"
			if (splice_options.online_do_copy_to_clipboard) then
				cmd_online = "printf \"" .. splice_options.online_resulting_url .. "\" $(%s\" | jq -r \" " ..
				splice_options.online_pattern .. "\") | xclip -selection clipboard"
			end
			cmd_online = string.format(cmd_online, "curl --progress-bar -u \"" ..
			splice_options.online_secret .. "\" -F \"file=@" .. output_file ..
			"\" \"" .. splice_options.online_upload_url)
			print("Command to execute: " .. cmd_online)
			os.execute(cmd_online);
			if (splice_options.online_do_copy_to_clipboard == "yes") then
				notify(10000, "Upload complete, link copied to clipboard")
			else
				notify(10000, "Upload complete")
			end
		end

		os.execute(string.format("rm -rf %s", tmp_dir))
		-- msg.info("Temporary directory removed!")
	end
end

do_upload = splice_options.do_upload
do_encode = splice_options.do_encode

mp.set_property("keep-open", "yes") -- Prevent mpv from exiting when the video ends
mp.set_property("quiet", "yes") -- Silence terminal.

mp.add_key_binding('q', "quit", function()
	prevent_quit("quit")
end)
mp.add_key_binding('Shift+q', "quit-watch-later", function()
	prevent_quit("quit-watch-later")
end)

mp.add_key_binding(splice_options.bind_toggle_do_encode, "toggle_do_encode", toggle_do_encode)
mp.add_key_binding(splice_options.bind_toggle_do_upload, "toggle_do_upload", toggle_do_upload)
mp.add_key_binding(splice_options.bind_put_time, "put_time", put_time)
mp.add_key_binding(splice_options.bind_show_times, "show_times", show_times)
mp.add_key_binding(splice_options.bind_process_video, "process_video", process_video)
mp.add_key_binding(splice_options.bind_reset_current_slice, "reset_current_slice", reset_current_slice)
mp.add_key_binding(splice_options.bind_delete_slice, "delete_slice", delete_slice)

-- vim: set tabstop=2 softtabstop=2 shiftwidth=2 noexpandtab :
