local M = {}

M.ntp = require("chrono.ntp")

M.time_now = 0 -- the current time, check if chrono.isconnected is true to trust this or not
M.time_offset = 0 -- a time offset option which is applied to time_now whenever syncing happens - mostly only useful to control timezone offset for midnight/noon

M.use_ntp = true
M.use_http = true
M.use_http_for_html5 = true
M.sysinfo = sys.get_sys_info()

M.use_server_time = true -- if true then NTP servers will be used to sync the current time with, if not then local time will be used only
M.allow_local_time = false -- if true then if NTP servers can't be reached then local time will be synced (could have BAD results)

M.disconnected = true -- if disconnected is true then you should not trust synced time / temp disable time based features
M.retry_counter = 0 -- current counter value of disconnected retry timer
M.retry_timer = 0.5 -- total time in seconds between disconnected retry attemps
M.retry_attempts = 0 -- current counter value of number of retry attempts
M.retry_attempts_max = -1 -- maximum retry attempts allow (currently not used)
M.verbose = true -- if true then successful connection events will be printed, if false only errors
M.initialized = false

local function http_result(self, _, response)
	if response.status == 200 then
		M.time_now = response.response
		print(response.response)
		M.disconnected = false
		M.retry_counter = 0
		M.retry_attempts = 0    	
	else
		M.disconnected = true
	end
end

local function round(x)
	local a = x % 1
	x = x - a
	if a < 0.5 then a = 0
	else a = 1 end
	return x + a
end

local function sync_http()
	http.request("https://www.timestampnow.com/", "GET", http_result)
end

local function sync_ntp()
	if not pcall(M.ntp.update_time) then
		print("Chrono: Warning cannot sync with NTP servers")
		M.disconnected = true
		return false
	else
		M.time_now = M.ntp.time_now + M.time_offset
		if M.verbose then print("Chrono: Time synced - " .. tostring(M.time_now)) end
		M.disconnected = false
		if M.retry_counter > 0 then
			print("Chrono: NTP servers have successfully synced after a disconnect")
		end
		M.retry_counter = 0
		M.retry_attempts = 0
		return true
	end
end

function M.init()
	M.sync_time()
	M.initialized = true
end

function M.sync_time()
	if M.sysinfo.system_name ~= "HTML5" then
		sync_ntp()
	else
		sync_http()
	end	
end

function M.get_time()
	if M.initialized == false then
		M.init()
	end	
	return M.time_now
end



function M.difference_from_now(seconds)
	return seconds - M.time_now
end

function M.format_time(total_seconds)

	if total_seconds <= 0 then
		 M.check_timer_counter = M.check_timer
		return "0m 0s"
	elseif total_seconds < 60 * 60 then -- less than an hour
		local seconds = round(total_seconds % 60)
		local minutes = math.floor(total_seconds / 60)
		return tostring(minutes) .. "m " .. tostring(seconds) .. "s"
	elseif total_seconds < 60 * 60 * 24 then -- less than a day
		local seconds = round(total_seconds % 60)
		local minutes = math.floor(total_seconds / 60) % 60
		local hours = math.floor(total_seconds / 3600)
		return tostring(hours) .. "h " .. tostring(minutes) .. "m " .. tostring(seconds) .. "s"		
	elseif total_seconds < 60 * 60 * 24 * 365 then -- less than a year
		local seconds = round(total_seconds % 60)
		local minutes = math.floor(total_seconds / 60) % 60
		local hours = math.floor(total_seconds / 3600) % 24
		local days = math.floor(total_seconds / (3600 * 24))
		return tostring(days) .. "d " .. tostring(hours) .. "h " .. tostring(minutes) .. "m " .. tostring(seconds) .. "s"		
	else
		local seconds = round(total_seconds % 60)
		local minutes = math.floor(total_seconds / 60) % 60
		local hours = math.floor(total_seconds / 3600) % 24 
		local days = math.floor(total_seconds / (3600 * 24)) % 365 
		local years = math.floor(total_seconds / (3600 * 24 * 365))
		return tostring(years) .. "y " .. tostring(days) .. "d " .. tostring(hours) .. "h " .. tostring(minutes) .. "m " .. tostring(seconds) .. "s"				
	end
end


function M.update(dt)

	if M.initialized == false then
		M.init()
	end

	if M.disconnected == false then
		M.time_now = M.time_now + dt
	end
	
	if M.disconnected == true then
		M.retry_counter = M.retry_counter + dt
	end
	if M.retry_counter >= M.retry_timer then
		M.retry_counter = M.retry_counter - M.retry_timer
		if not M.sync_time() then
			M.retry_attempts = M.retry_attempts + 1
			if M.sysinfo.system_name ~= "HTML5" then
				print("Chrono: NTP sync retry attempt " .. tostring(M.retry_attempts) .. " failed")
			else
				print("Chrono: HTTP sync retry attempt " .. tostring(M.retry_attempts) .. " failed")
			end
		end
	end
end



return M