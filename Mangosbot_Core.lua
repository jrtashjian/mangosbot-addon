-- Client detection + shared utilities (Lua 5.0-safe)

local VERSION = 0
local CLIENT = {
	expansion = "classic",
	interface = 11000,
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

function MB_UnitName(unit)
	if GetUnitName then
		return GetUnitName(unit)
	end
	if UnitName then
		return UnitName(unit)
	end
	return nil
end

function MB_Match(s, pattern)
	if s == nil or pattern == nil then
		return nil
	end
	local _, _, a, b, c, d = string.find(s, pattern)
	return a, b, c, d
end

function MB_ChatEditBox()
	local box = getglobal("ChatFrameEditBox")
	if box == nil then
		box = getglobal("ChatFrame1EditBox")
	end
	if box == nil and DEFAULT_CHAT_FRAME ~= nil then
		box = DEFAULT_CHAT_FRAME.editBox
	end
	return box
end

-- Arg order flips between Classic (width, frame) and TBC+ (frame, width).
function MB_DropDownSetWidth(frame, width)
	if not UIDropDownMenu_SetWidth or frame == nil or width == nil then
		return
	end
	if CLIENT.interface < 20000 then
		UIDropDownMenu_SetWidth(width, frame)
	else
		UIDropDownMenu_SetWidth(frame, width)
	end
end

-- Classic handlers read global event/argN; newer clients pass args explicitly.
function MB_EventArgs(_self, eventName, a1, a2, a3, a4)
	if eventName == nil then
		eventName = event
	end
	if a1 == nil then
		a1 = arg1
	end
	if a2 == nil then
		a2 = arg2
	end
	if a3 == nil then
		a3 = arg3
	end
	if a4 == nil then
		a4 = arg4
	end
	return eventName, a1, a2, a3, a4
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

-- Config fields survive reload. Live stats (money/xp/bags/dur/online) do not.
local BOT_CACHE_FIELDS = {
	"class",
	"role",
	"strategy",
	"formation",
	"stance",
	"savemana",
	"loot",
	"rti",
	"rti_cc",
}

local function CopyTable(src)
	if src == nil then
		return nil
	end
	local dst = {}
	for k, v in pairs(src) do
		if type(v) == "table" then
			dst[k] = CopyTable(v)
		else
			dst[k] = v
		end
	end
	return dst
end

local function EnsureBotCache()
	if MangosbotDB == nil then
		MangosbotDB = {}
	end
	if MangosbotDB.bots == nil then
		MangosbotDB.bots = {}
	end
	return MangosbotDB.bots
end

function PersistBotCache()
	local bots = {}
	for name, bot in pairs(botTable) do
		local snap = {}
		for i = 1, table.getn(BOT_CACHE_FIELDS) do
			local key = BOT_CACHE_FIELDS[i]
			if bot[key] ~= nil then
				if type(bot[key]) == "table" then
					snap[key] = CopyTable(bot[key])
				else
					snap[key] = bot[key]
				end
			end
		end
		bots[name] = snap
	end
	EnsureBotCache()
	MangosbotDB.bots = bots
end

function RestoreBotCache()
	local bots = EnsureBotCache()
	for name, cached in pairs(bots) do
		if botTable[name] == nil then
			botTable[name] = {}
		end
		local bot = botTable[name]
		for i = 1, table.getn(BOT_CACHE_FIELDS) do
			local key = BOT_CACHE_FIELDS[i]
			if cached[key] ~= nil and bot[key] == nil then
				if type(cached[key]) == "table" then
					bot[key] = CopyTable(cached[key])
				else
					bot[key] = cached[key]
				end
			end
		end
	end
end

function BotHasGroupState(bot)
	return bot ~= nil
		and bot.formation ~= nil
		and bot.savemana ~= nil
		and bot.strategy ~= nil
		and bot.strategy.co ~= nil
		and bot.strategy.nc ~= nil
end

function BotHasPanelState(bot)
	return BotHasGroupState(bot)
		and bot.stance ~= nil
		and bot.loot ~= nil
		and bot.rti ~= nil
		and bot.strategy.react ~= nil
end

function PartyNeedsStateQuery()
	for name, bot in pairs(botTable) do
		if BotIsInParty(name) and not BotHasGroupState(bot) then
			return true
		end
	end
	return false
end

-- math.fmod is missing on Classic (Lua 5.0); emulate it.
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

-- Canonical comma-list: trim entries, drop duplicates, sort. Server replies echo
-- strategy sets reordered/duplicated (e.g. loot strategy); this makes them
-- comparable to the UI option sets.
function CanonicalSet(s)
	if s == nil then
		return nil
	end
	local parts = splitString2(s, ",")
	local seen = {}
	local out = {}
	for i = 1, table.getn(parts) do
		local p = trim2(parts[i])
		if p ~= "" and seen[p] == nil then
			seen[p] = true
			table.insert(out, p)
		end
	end
	table.sort(out)
	return table.concat(out, ",")
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

-- Run func after delay seconds on a hidden OnUpdate frame; re-queues on each tick.
function wait(delay, func, a1, a2, a3, a4, a5, a6, a7, a8, a9)
	if type(delay) ~= "number" or type(func) ~= "function" then
		return false
	end
	if waitFrame == nil then
		waitFrame = CreateFrame("Frame", "WaitFrame", UIParent)
		waitFrame:Hide()
		waitFrame:SetScript("OnUpdate", function(_self, elapsed)
			elapsed = elapsed or arg1
			if elapsed == nil or elapsed <= 0 then
				elapsed = 0.1
			end
			local count = table.getn(waitTable)
			local i = 1
			while i <= count do
				local waitRecord = tremove(waitTable, i)
				local d = tremove(waitRecord, 1)
				local f = tremove(waitRecord, 1)
				local p = tremove(waitRecord, 1)
				if d > elapsed then
					tinsert(waitTable, i, { d - elapsed, f, p })
					i = i + 1
				else
					count = count - 1
					f(unpack(p))
				end
			end
			if table.getn(waitTable) == 0 then
				waitFrame:Hide()
			end
		end)
	end
	tinsert(waitTable, { delay, func, { a1, a2, a3, a4, a5, a6, a7, a8, a9 } })
	waitFrame:Show()
	return true
end

-- Raid slot wins when the same index also exists in the raid.
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

-- Uppercase, space-free class key used for lookups and image filenames.
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

-- Iterate keys in sorted order (pairs() order is unspecified).
function orderedPairs(t)
	return orderedNext, t, nil
end
