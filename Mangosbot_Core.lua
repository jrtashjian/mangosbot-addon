-- Client detection + shared utilities (Lua 5.0-safe)

local VERSION = 0
local CLIENT = {
	expansion = "classic",
	interface = 11000,
	hasAddonWhisper = false,
	invite = nil,
}

local function detectClient()
	local version, _, _, tocversion = nil, nil, nil, nil
	if GetBuildInfo then
		version, _, _, tocversion = GetBuildInfo()
	end

	local interface = tocversion
	if interface == nil and type(version) == "string" then
		local major = tonumber(string.sub(version, 1, 1))
		if major == 1 then
			interface = 11000
		elseif major == 2 then
			interface = 20400
		elseif major == 3 then
			interface = 30300
		end
	end
	if interface == nil then
		interface = 11000
	end

	CLIENT.interface = interface
	if interface >= 30000 then
		CLIENT.expansion = "wotlk"
		VERSION = 2
	elseif interface >= 20000 then
		CLIENT.expansion = "tbc"
		VERSION = 1
	else
		CLIENT.expansion = "classic"
		VERSION = 0
	end

	-- SendAddonMessage WHISPER exists from TBC onward
	CLIENT.hasAddonWhisper = (interface >= 20000)

	if InviteUnit then
		CLIENT.invite = InviteUnit
	elseif InviteByName then
		CLIENT.invite = InviteByName
	else
		CLIENT.invite = function() end
	end
end

detectClient()

function GetMangosbotVersion()
	return VERSION
end
function GetMangosbotClient()
	return CLIENT
end

function MB_Invite(name)
	if name == nil or name == "" then
		return
	end
	CLIENT.invite(name)
end

function MB_HasDeathKnight()
	return CLIENT.interface >= 30000
end

function print(s)
	if s ~= nil then
		DEFAULT_CHAT_FRAME:AddMessage(s)
	else
		DEFAULT_CHAT_FRAME:AddMessage("nil")
	end
end

ToolBars = {}
GroupToolBars = {}
CommandSeparator = "\\\\"
DropDownMenu = {}
botTable = {}

function fmod(a, b)
	return a - math.floor(a / b) * b
end

function trim2(s)
	if s == nil then
		return ""
	end
	local find = string.find
	local sub = string.sub
	local function trim8(str)
		local i1, i2 = find(str, "^%s*")
		if i2 >= i1 then
			str = sub(str, i2 + 1)
		end
		i1, i2 = find(str, "%s*$")
		if i2 >= i1 then
			str = sub(str, 1, i1 - 1)
		end
		return str
	end
	return trim8(s)
end

-- Strip WoW UI escape codes: |cAARRGGBB ... |r and || literal pipe
function StripColors(s)
	if s == nil then
		return ""
	end
	s = string.gsub(s, "|c[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]", "")
	s = string.gsub(s, "|r", "")
	s = string.gsub(s, "|H.-|h(.-)|h", "%1")
	-- Dangling link terminators (playerbots stats replies embed bare |h around numbers)
	s = string.gsub(s, "|h", "")
	s = string.gsub(s, "||", "|")
	return s
end

function NormalizeMessage(s)
	return trim2(StripColors(s))
end

function splitString2(self, inSplitPattern, outResults)
	if not inSplitPattern then
		return
	end
	if not outResults then
		outResults = {}
	end
	local theStart = 1
	local theSplitStart, theSplitEnd = string.find(self, inSplitPattern, theStart)
	while theSplitStart do
		table.insert(outResults, string.sub(self, theStart, theSplitStart - 1))
		theStart = theSplitEnd + 1
		theSplitStart, theSplitEnd = string.find(self, inSplitPattern, theStart)
	end
	table.insert(outResults, string.sub(self, theStart))
	return outResults
end

function StartsWith(s, prefix)
	if s == nil or prefix == nil then
		return false
	end
	return string.sub(s, 1, string.len(prefix)) == prefix
end

function AfterPrefix(s, prefix)
	if not StartsWith(s, prefix) then
		return nil
	end
	return trim2(string.sub(s, string.len(prefix) + 1))
end

local waitTable = {}
local waitFrame = nil

function tablelength(T)
	local count = 0
	for _ in pairs(T) do
		count = count + 1
	end
	return count
end

function wait(delay, func, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
	if type(delay) ~= "number" or type(func) ~= "function" then
		return false
	end
	if waitFrame == nil then
		waitFrame = CreateFrame("Frame", "WaitFrame", UIParent)
		waitFrame:SetScript("OnUpdate", function()
			local elapse = 0.1
			local count = tablelength(waitTable)
			local i = 1
			while i <= count do
				local waitRecord = tremove(waitTable, i)
				local d = tremove(waitRecord, 1)
				local f = tremove(waitRecord, 1)
				local p = tremove(waitRecord, 1)
				if d > elapse then
					tinsert(waitTable, i, { d - elapse, f, p })
					i = i + 1
				else
					count = count - 1
					f(unpack(p))
				end
			end
		end)
	end
	tinsert(waitTable, { delay, func, { arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9 } })
	return true
end

function partyName(i)
	local p = UnitName("party" .. i)
	local r = UnitName("raid" .. i)
	if r == nil then
		return p
	end
	return r
end

function partySize()
	local p = GetNumPartyMembers()
	local r = GetNumRaidMembers()
	if r == 0 then
		return p
	end
	return r
end

function botCount()
	local count = 0
	for _ in pairs(botTable) do
		count = count + 1
	end
	return count
end

function ClassToken(class)
	if class == nil then
		return "UNKNOWN"
	end
	local upper = string.upper(class)
	upper = string.gsub(upper, " ", "")
	return upper
end

function __genOrderedIndex(t)
	local orderedIndex = {}
	for key in pairs(t) do
		table.insert(orderedIndex, key)
	end
	table.sort(orderedIndex)
	return orderedIndex
end

function orderedNext(t, state)
	local key = nil
	if state == nil then
		t.__orderedIndex = __genOrderedIndex(t)
		key = t.__orderedIndex[1]
	else
		for i = 1, table.getn(t.__orderedIndex) do
			if t.__orderedIndex[i] == state then
				key = t.__orderedIndex[i + 1]
			end
		end
	end

	if key then
		return key, t[key]
	end

	t.__orderedIndex = nil
	return
end

function orderedPairs(t)
	return orderedNext, t, nil
end
