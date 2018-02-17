-- Most of this came from the blog article here:
-- https://lettier.github.io/posts/2016-04-26-lets-make-a-ntp-client-in-c.html
-- For reference, the packet structure looks like:
--[[
	typedef struct
	{
	  unsigned li   : 2;       // Only two bits. Leap indicator.
	  unsigned vn   : 3;       // Only three bits. Version number of the protocol.
	  unsigned mode : 3;       // Only three bits. Mode. Client will pick mode 3 for client.

	  uint8_t stratum;         // Eight bits. Stratum level of the local clock.
	  uint8_t poll;            // Eight bits. Maximum interval between successive messages.
	  uint8_t precision;       // Eight bits. Precision of the local clock.

	  uint32_t rootDelay;      // 32 bits. Total round trip delay time.
	  uint32_t rootDispersion; // 32 bits. Max error aloud from primary clock source.
	  uint32_t refId;          // 32 bits. Reference clock identifier.

	  uint32_t refTm_s;        // 32 bits. Reference time-stamp seconds.
	  uint32_t refTm_f;        // 32 bits. Reference time-stamp fraction of a second.

	  uint32_t origTm_s;       // 32 bits. Originate time-stamp seconds.
	  uint32_t origTm_f;       // 32 bits. Originate time-stamp fraction of a second.

	  uint32_t rxTm_s;         // 32 bits. Received time-stamp seconds.
	  uint32_t rxTm_f;         // 32 bits. Received time-stamp fraction of a second.

	  uint32_t txTm_s;         // 32 bits and the most important field the client cares about. Transmit time-stamp seconds.
	  uint32_t txTm_f;         // 32 bits. Transmit time-stamp fraction of a second.

	} ntp_packet;              // Total: 384 bits or 48 bytes.
--]]

local M = {}

M.time_now = 0

local DEFAULT_NTP_HOSTS = {
	'time1.google.com',
	'time2.google.com',
	'time3.google.com',
	'time4.google.com',
}
local DEFAULT_NTP_PORT = 123

-- The seconds from Jan 1, 1900 to Jan 1, 1970
local SHIFT_TO_UNIX_EPOCH = 0x83AA7E80

-- Build a message.  Set the first byte's bits to 00,011,011 for li = 0, vn = 3, and mode = 3
local NTP_TIME_QUERY = string.char(0x1b,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)

local function read_uint32(s, offset)
	local v = s:byte(offset + 1)
	v = v * 256 + s:byte(offset + 2)
	v = v * 256 + s:byte(offset + 3)
	v = v * 256 + s:byte(offset + 4)
	return v
end

local time_check_prototype = {
	__gc = function(self)
		self.s:close()
	end,

	-- timeout: Pass nil to block until ready, or a max number of seconds to wait
	get = function(self, timeout)
		if self.ts then
			return self.ts
		end
		self.s:settimeout(timeout)
		local packet, timed_out = self.s:receive()
		if not timed_out and #packet >= 48 then
			-- Get the txTm_s field (transmit time, in seconds)
			-- Add the txTm_f value, converted to a fraction
			local seconds = read_uint32(packet, 40) - SHIFT_TO_UNIX_EPOCH
			local fraction = read_uint32(packet, 44) / 0xffffffff
			self.ts = seconds + fraction
			self.s:close()
		end
		return self.ts
	end,
}

function M.start_time_check(hosts, port)
	port = port or DEFAULT_NTP_PORT
	hosts = hosts or DEFAULT_NTP_HOSTS
	if type(hosts) == 'string' then
		hosts = {hosts}
	end

	local s = socket.udp()
	if not s then
		return nil, 'NTP: Failed to create UDP socket'
	end

	-- Resolve ip addresses
	local ips = {}
	for _, host in ipairs(hosts) do
		local ip = socket.dns.toip(host)
		if ip then
			table.insert(ips, ip)
		end
	end

	if #ips == 0 then
		return nil, 'NTP: Address resolution failed for all hosts in list'
	end

	-- Send a time request to each ip
	local any_sent = false
	for _, ip in ipairs(ips) do
		if s:sendto(NTP_TIME_QUERY, ip, port) then
			any_sent = true
		end
	end

	if not any_sent then
		return nil, 'NTP: sendto() failed'
	end
	
	return setmetatable({s = s}, {__index = time_check_prototype})
end

function M.test()
	local t = assert(M.start_time_check())
	local ts = assert(t:get(10), 'NTP: Check failed')
	assert(type(ts == 'number') and ts > 1483228800)
	print('NTP time:', ts)
	print('TEST: ntp OK')
end

function M.get_time()
	local t = assert(M.start_time_check())
	local ts = assert(t:get(10), 'NTP: Check failed')
	assert(type(ts == 'number') and ts > 1483228800)
	return ts	
end

function M.update_time()
	local t = assert(M.start_time_check())
	local ts = assert(t:get(10), 'NTP: Check failed')
	assert(type(ts == 'number') and ts > 1483228800)
	M.time_now = ts	
end

return M