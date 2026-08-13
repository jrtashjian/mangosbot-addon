-- Addon <-> playerbots messaging and reply parsers

local ADDON_PREFIX = "BOT"

-- Ensure AI commands request silent addon replies (#a). Idempotent.
function EnsureAddonPrefix(cmd)
	if cmd == nil or cmd == "" then
		return cmd
	end
	local c = trim2(cmd)
	if string.sub(c, 1, 1) == "." then
		return c
	end
	if
		StartsWith(c, "#a ")
		or StartsWith(c, "#w ")
		or StartsWith(c, "#p ")
		or StartsWith(c, "#r ")
		or StartsWith(c, "#g ")
	then
		return c
	end
	return "#a " .. c
end

function CombineBotCommands(commands)
	local combined = ""
	for _, command in orderedPairs(commands) do
		combined = combined .. EnsureAddonPrefix(command) .. CommandSeparator
	end
	if string.len(combined) >= 2 then
		combined = string.sub(combined, 1, string.len(combined) - 2)
	end
	return combined
end

-- Server accepts BOT\t over real chat channels (whisper/party/raid).
-- type==CHAT_MSG_ADDON is ignored server-side; do not SendAddonMessage for whispers.
-- Party/raid SendAddonMessage("BOT", text) arrives as PARTY/RAID + LANG_ADDON + "BOT\ttext".
function SendBotCommand(text, chat, lang, channel)
	if chat == "PARTY" and partySize() == 0 then
		return
	end

	if BotDebugLogMessage and BotDebugPanel and BotDebugPanel:IsVisible() then
		local peer = channel
		if peer == nil or peer == "" then
			peer = chat
		end
		BotDebugLogMessage(">>", text, peer)
	end

	if chat == "SAY" or chat == "GUILD" then
		SendChatMessage(text, chat, lang, channel)
		return
	end

	if chat == "WHISPER" then
		-- Always whisper with BOT\t so the server strips the marker and honors #a reply routing
		SendChatMessage(ADDON_PREFIX .. "\t" .. text, "WHISPER", lang, channel)
		return
	end

	if chat == "PARTY" then
		if GetNumRaidMembers() > 0 then
			chat = "RAID"
		end
	end
	SendAddonMessage(ADDON_PREFIX, text, chat, channel)
end

function SendBotAddonCommand(text, chat, lang, channel)
	SendBotCommand(EnsureAddonPrefix(text), chat, lang, channel)
end

function QueryBotParty()
	wait(0.1, function()
		SendBotCommand(
			EnsureAddonPrefix("ll ?")
				.. CommandSeparator
				.. EnsureAddonPrefix("formation ?")
				.. CommandSeparator
				.. EnsureAddonPrefix("stance ?")
				.. CommandSeparator
				.. EnsureAddonPrefix("co ?")
				.. CommandSeparator
				.. EnsureAddonPrefix("nc ?")
				.. CommandSeparator
				.. EnsureAddonPrefix("react ?")
				.. CommandSeparator
				.. EnsureAddonPrefix("save mana ?"),
			"PARTY"
		)
	end)
end

function QuerySelectedBot(name)
	wait(0.1, function()
		SendBotCommand(
			EnsureAddonPrefix("formation ?")
				.. CommandSeparator
				.. EnsureAddonPrefix("stance ?")
				.. CommandSeparator
				.. EnsureAddonPrefix("ll ?")
				.. CommandSeparator
				.. EnsureAddonPrefix("co ?")
				.. CommandSeparator
				.. EnsureAddonPrefix("nc ?")
				.. CommandSeparator
				.. EnsureAddonPrefix("react ?")
				.. CommandSeparator
				.. EnsureAddonPrefix("save mana ?")
				.. CommandSeparator
				.. EnsureAddonPrefix("rti ?"),
			"WHISPER",
			nil,
			name
		)
	end)
end

-- ---------------------------------------------------------------------------
-- Hide protocol chatter from the default chat frames (safety net + outgoing)
-- ---------------------------------------------------------------------------

-- Prefixes from playerbots replies the UI parses or triggers on.
-- Sources: Formations/Stances/Rti/LootStrategy/SaveMana/Engine::PrintStrategies,
-- PlayerbotMgr::ListBots/ProcessBotCommand, ChatShortcutActions BOT_TEXT defaults.
local HIDE_PREFIXES = {
	-- Roster / .bot holder commands (CHAT_MSG_SYSTEM)
	"Bot roster:",
	"add:",
	"login:",
	"rm:",
	"remove:",
	"logout:",
	-- Formation
	"Formation:",
	"Formation set to",
	"Formation reset to",
	"Invalid formation:",
	"Please set to any of:",
	-- Stance
	"Stance:",
	"Stance set to",
	"Invalid stance:",
	-- Strategies (BotStateToString + short engine names + legacy)
	"Combat Strategies:",
	"Non Combat Strategies:",
	"Reaction Strategies:",
	"Dead Strategies:",
	"co Strategies:",
	"nc Strategies:",
	"react Strategies:",
	"dead Strategies:",
	"Strategies:",
	-- Loot (ll)
	"Loot strategy:",
	"Loot strategy set to",
	"My loot list is now empty",
	"My always loot list:",
	"My skip loot list:",
	"My skip go loot list:",
	"Will loot ",
	"Won't loot ",
	-- Mana save
	"Mana save level:",
	"Mana save level set:",
	-- RTI
	"rti:",
	"rti cc:",
	"rti set to",
	"rti cc set to",
	-- Movement shortcut acks (English BOT_TEXT defaults; UI re-queries on these)
	"Following",
	"Staying",
	"Fleeing",
	"Free moving",
	"Guarding",
	"Grinding",
	"Attacking",
	"Running away",
	"Max DPS!",
	-- Silent frame marker
	"BOT\t",
}

local function IsStatsReplyMessage(message)
	return string.find(message, "%d+/%d+ Bag") ~= nil
end

function IsBotProtocolMessage(message)
	if message == nil then
		return false
	end
	local msg = NormalizeMessage(message)
	if msg == "" then
		return false
	end
	if StartsWith(msg, "BOT\t") or string.find(msg, "BOT\t") == 1 then
		return true
	end

	local lower = string.lower(msg)
	for i = 1, table.getn(HIDE_PREFIXES) do
		local prefix = HIDE_PREFIXES[i]
		if StartsWith(msg, prefix) then
			return true
		end
		if StartsWith(lower, string.lower(prefix)) then
			return true
		end
	end
	if IsStatsReplyMessage(msg) then
		return true
	end
	return false
end

local function ChatFilter(_self, _event, msg, ...)
	if IsBotProtocolMessage(msg) then
		return true
	end
	return false, msg, ...
end

local chatFilterInstalled = false
function InstallBotChatFilters()
	if chatFilterInstalled then
		return
	end
	chatFilterInstalled = true

	if ChatFrame_AddMessageEventFilter then
		ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", ChatFilter)
		ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", ChatFilter)
		ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", ChatFilter)
		ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", ChatFilter)
		ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", ChatFilter)
		ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", ChatFilter)
		ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", ChatFilter)
		ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_WARNING", ChatFilter)
		return
	end

	-- Classic / early TBC: hook ChatFrame_MessageEventHandler
	if ChatFrame_MessageEventHandler then
		local orig = ChatFrame_MessageEventHandler
		ChatFrame_MessageEventHandler = function(event)
			if
				event == "CHAT_MSG_WHISPER"
				or event == "CHAT_MSG_WHISPER_INFORM"
				or event == "CHAT_MSG_SYSTEM"
				or event == "CHAT_MSG_PARTY"
				or event == "CHAT_MSG_PARTY_LEADER"
				or event == "CHAT_MSG_RAID"
				or event == "CHAT_MSG_RAID_LEADER"
				or event == "CHAT_MSG_RAID_WARNING"
			then
				if IsBotProtocolMessage(arg1) then
					return
				end
			end
			return orig(event)
		end
	end
end

InstallBotChatFilters()

-- ---------------------------------------------------------------------------
-- Parsers
-- ---------------------------------------------------------------------------

local function EnsureStrategyTable(bot)
	if bot["strategy"] == nil then
		bot["strategy"] = { nc = {}, co = {}, react = {}, dead = {} }
	end
	if bot["strategy"]["react"] == nil then
		bot["strategy"]["react"] = {}
	end
	if bot["strategy"]["dead"] == nil then
		bot["strategy"]["dead"] = {}
	end
end

local function ParseStrategyList(bot, type, text)
	local list = {}
	local role = "dps"
	local splitted = splitString2(text, ", ")
	for i = 1, tablelength(splitted) do
		local name = trim2(splitted[i])
		if name ~= "" then
			table.insert(list, name)
		end
		if name == "heal" then
			role = "heal"
		end
		if name == "tank" or name == "bear" or name == "blood" then
			role = "tank"
		end
	end
	EnsureStrategyTable(bot)
	if type == "co" then
		bot["role"] = role
	end
	bot["strategy"][type] = list
end

-- Parse a playerbots "stats" reply: money, free/total bag slots, durability, xp.
-- Reply shape (after color strip): "12g 34s 5c, 20/56 Bag, 100% (0) Dur, 78/200% XP, 214 Pwr".
-- Returns nil when the message is not a stats reply.
function ParseStatsReply(message)
	if message == nil then
		return nil
	end
	local bagFree, bagTotal = MB_Match(message, "(%d+)/(%d+) Bag")
	if bagFree == nil then
		return nil
	end
	local money = MB_Match(message, "^([^,]*)")
	local durability = MB_Match(message, "(%d+%%[^,]-)%s*Dur")
	local xp = MB_Match(message, "([^,]+)%s*XP")
	return {
		money = trim2(money),
		bagFree = tonumber(bagFree),
		bagTotal = tonumber(bagTotal),
		durability = durability and trim2(durability) or nil,
		xp = xp and trim2(xp) or nil,
	}
end

-- First matching prefix wins. Longer labels must precede "Strategies:".
local STRATEGY_PREFIXES = {
	{ prefix = "Combat Strategies:", type = "co" },
	{ prefix = "Non Combat Strategies:", type = "nc" },
	{ prefix = "Reaction Strategies:", type = "react" },
	{ prefix = "Dead Strategies:", type = "dead" },
	{ prefix = "co Strategies:", type = "co" },
	{ prefix = "nc Strategies:", type = "nc" },
	{ prefix = "react Strategies:", type = "react" },
	{ prefix = "dead Strategies:", type = "dead" },
	{ prefix = "Strategies:", type = "co", ncIfBodyHasNc = true },
}

-- Longer prefixes first so "rti cc set to" wins over "rti:".
local FIELD_PREFIXES = {
	{ prefix = "Formation:", field = "formation", lower = true },
	{ prefix = "Stance:", field = "stance", lower = true },
	{ prefix = "Mana save level set:", field = "savemana" },
	{ prefix = "Mana save level:", field = "savemana" },
	{ prefix = "Loot strategy set to", field = "loot" },
	{ prefix = "Loot strategy:", field = "loot" },
	{ prefix = "rti cc set to", field = "rti_cc" },
	{ prefix = "rti set to", field = "rti" },
	{ prefix = "rti cc:", field = "rti_cc" },
	{ prefix = "rti:", field = "rti" },
}

function OnWhisper(message, sender)
	if message == nil or sender == nil then
		return false
	end
	message = NormalizeMessage(message)

	if StartsWith(message, "BOT\t") then
		message = string.sub(message, 5)
		message = NormalizeMessage(message)
	end

	if botTable[sender] == nil then
		botTable[sender] = {}
	end
	local bot = botTable[sender]
	local dirty = false

	local strategyType, body
	for si = 1, table.getn(STRATEGY_PREFIXES) do
		local spec = STRATEGY_PREFIXES[si]
		body = AfterPrefix(message, spec.prefix)
		if body ~= nil then
			strategyType = spec.type
			if spec.ncIfBodyHasNc and string.find(body, "nc") ~= nil then
				strategyType = "nc"
			end
			break
		end
	end
	if strategyType ~= nil and body ~= nil then
		ParseStrategyList(bot, strategyType, body)
		dirty = true
	end

	for fi = 1, table.getn(FIELD_PREFIXES) do
		local spec = FIELD_PREFIXES[fi]
		local value = AfterPrefix(message, spec.prefix)
		if value ~= nil then
			if spec.lower then
				value = string.lower(value)
			end
			bot[spec.field] = value
			dirty = true
			break
		end
	end

	local stats = ParseStatsReply(message)
	if stats ~= nil then
		bot["money"] = stats.money
		bot["bagFree"] = stats.bagFree
		bot["bagTotal"] = stats.bagTotal
		bot["durability"] = stats.durability
		bot["xp"] = stats.xp
		dirty = true
	end
	return dirty
end

function OnSystemMessage(message)
	if message == nil then
		return false
	end
	message = NormalizeMessage(message)

	if StartsWith(message, "Bot roster:") then
		local previous = botTable
		botTable = {}
		local text = AfterPrefix(message, "Bot roster:")
		local splitted = splitString2(text, ", ")
		for i = 1, tablelength(splitted) do
			local line = trim2(splitted[i])
			if line ~= "" and string.len(line) >= 2 then
				local on = string.sub(line, 1, 1)
				local pos = string.find(line, " ")
				if pos ~= nil then
					local name = string.sub(line, 2, pos - 1)
					local cls = trim2(string.sub(line, pos + 1))

					if botTable[name] == nil then
						botTable[name] = {}
					end
					botTable[name]["class"] = cls
					botTable[name]["online"] = (on == "+")

					-- Keep cached role/stats across roster rebuilds (control panel).
					local prior = previous[name]
					if prior ~= nil then
						local keep = {
							"role",
							"money",
							"bagFree",
							"bagTotal",
							"durability",
							"xp",
							"strategy",
							"formation",
							"stance",
							"savemana",
							"loot",
							"rti",
							"rti_cc",
						}
						for k = 1, table.getn(keep) do
							local key = keep[k]
							if prior[key] ~= nil then
								botTable[name][key] = prior[key]
							end
						end
					end
				end
			end
		end
		return true
	end
	return false
end

function GetChatEventPayload(event, a1, a2, _a3, a4)
	if event == "CHAT_MSG_ADDON" then
		if a1 ~= nil and a1 ~= ADDON_PREFIX and a1 ~= "" then
			if a2 ~= nil and StartsWith(NormalizeMessage(a2), "BOT\t") then
				return string.sub(NormalizeMessage(a2), 5), a4
			end
			if a1 ~= ADDON_PREFIX then
				return nil, nil
			end
		end
		local msg = a2
		if msg == nil and a1 ~= nil then
			msg = a1
		end
		return msg, a4
	end
	return a1, a2
end
