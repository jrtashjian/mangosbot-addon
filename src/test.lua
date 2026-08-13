-- Mangosbot harness: exercises Core and Protocol under stock Lua 5.1.
-- Run with: lua test.lua   (from src/)

DEFAULT_CHAT_FRAME = { AddMessage = function(_self, s) io.write("CHAT: " .. tostring(s) .. "\n") end }
UIParent = {}
RAID_CLASS_COLORS = {}
GameTooltip = { SetOwner = function() end, SetText = function() end, Show = function() end, Hide = function() end }
SlashCmdList = SlashCmdList or {}

	local function stubFontString()
	return {
		SetPoint = function() end,
		ClearAllPoints = function() end,
		SetWidth = function() end,
		SetHeight = function() end,
		SetFont = function() end,
		SetJustifyH = function() end,
		SetText = function() end,
		SetTextColor = function() end,
		GetStringWidth = function()
			return 40
		end,
		Hide = function() end,
		Show = function() end,
	}
end

local function stubTexture()
	return {
		SetTexture = function() end,
		SetAllPoints = function() end,
		SetPoint = function() end,
		ClearAllPoints = function() end,
		SetWidth = function() end,
		SetHeight = function() end,
		SetTexCoord = function() end,
		SetVertexColor = function() end,
		Hide = function() end,
		Show = function() end,
	}
end

frames = {}
function CreateFrame(_kind, name, _parent, template)
	local f = {
		name = name,
		toolbar = {},
		buttons = {},
		items = {},
		_vis = false,
	}
	function f:SetScript(_k, fn)
		self.script = fn
	end
	function f:Hide()
		f._vis = false
	end
	function f:Show()
		f._vis = true
	end
	function f:IsVisible()
		return f._vis
	end
	function f:GetName()
		return f.name or "anon"
	end
	function f:GetWidth()
		return 100
	end
	function f:GetHeight()
		return 40
	end
	function f:GetEffectiveScale()
		return 1
	end
	function f:GetPoint()
		return "CENTER", nil, "CENTER", 0, 0
	end
	function f:CreateFontString()
		return stubFontString()
	end
	function f:CreateTexture()
		return stubTexture()
	end
	local nop = function()
		return f
	end
	f.SetWidth = nop
	f.SetHeight = nop
	f.SetPoint = nop
	f.ClearAllPoints = nop
	f.EnableMouse = nop
	f.SetMovable = nop
	f.SetFrameStrata = nop
	f.SetBackdropColor = nop
	f.SetBackdrop = nop
	f.SetBackdropBorderColor = nop
	f.RegisterForDrag = nop
	f.RegisterForClicks = nop
	f.SetFrameLevel = nop
	f.EnableMouseWheel = nop
	f.SetFading = nop
	f.SetMaxLines = nop
	f.SetJustifyH = nop
	f.SetFont = nop
	f.SetMultiLine = nop
	f.SetAutoFocus = nop
	f.SetMaxLetters = nop
	f.UpdateScrollChildRect = nop
	f.EnableMouseWheel = nop
	f._scrollValue = 0
	f.GetVerticalScroll = function()
		return f._scrollValue
	end
	f.SetVerticalScroll = function(_self, v)
		f._scrollValue = v or 0
	end
	f.GetVerticalScrollRange = function()
		return 0
	end
	f.GetScrollChild = function()
		return f._scrollChild
	end
	f.SetScrollChild = function(_self, child)
		f._scrollChild = child
	end
	f.GetParent = function()
		return f._parent
	end
	f._minV, f._maxV, f._value = 0, 0, 0
	f.SetMinMaxValues = function(_self, minV, maxV)
		f._minV, f._maxV = minV or 0, maxV or 0
	end
	f.GetMinMaxValues = function()
		return f._minV, f._maxV
	end
	f.SetValue = function(_self, v)
		f._value = v or 0
	end
	f.GetValue = function()
		return f._value
	end
	f.SetValueStep = nop
	f.SetStatusBarTexture = nop
	f.SetStatusBarColor = nop
	f.GetFrameLevel = function()
		return 1
	end
	f.Clear = nop
	f.AddMessage = nop
	f.RegisterEvent = nop
	f.SetChecked = nop
	f.GetChecked = function()
		return false
	end
	frames[#frames + 1] = f
	if name ~= nil then
		-- WoW rejects duplicate named frames; mirror that so fallbacks stay honest.
		if _G[name] ~= nil then
			return nil
		end
		_G[name] = f
		if template == "UIDropDownMenuTemplate" then
			_G[name .. "Text"] = stubFontString()
		end
		if template == "UICheckButtonTemplate" then
			_G[name .. "Text"] = stubFontString()
		end
	end
	f._parent = _parent
	return f
end

getglobal = function(name)
	return _G[name]
end
tinsert = table.insert
tremove = table.remove
unpack = unpack or table.unpack
table.getn = table.getn or function(t)
	return #t
end
table.concat = table.concat
	or function(t, sep)
		sep = sep or ""
		local out = ""
		for i = 1, #t do
			if i > 1 then
				out = out .. sep
			end
			out = out .. tostring(t[i])
		end
		return out
	end

GetNumPartyMembers = function()
	return 0
end
GetNumRaidMembers = function()
	return 0
end
UnitName = function()
	return nil
end
GetUnitName = function()
	return nil
end
UnitClass = function()
	return nil
end
UnitExists = function()
	return false
end
UnitIsEnemy = function()
	return false
end
UnitIsPlayer = function()
	return false
end
GetBuildInfo = function()
	return "3.3.5", "12340", "Jun 30 2010", 30300
end
InviteUnit = function() end
InviteByName = function() end
SendChatMessage = function() end
SendAddonMessage = function() end
DoEmote = function() end
HideDropDownMenu = function() end
ToggleDropDownMenu = function() end
UIDropDownMenu_Initialize = function() end
UIDropDownMenu_AddButton = function() end
UIDropDownMenu_SetWidth = function() end
UIDropDownMenu_SetSelectedValue = function() end
ShowUIPanel = function(f) if f then f:Show() end end
HideUIPanel = function(f) if f then f:Hide() end end
SetPortraitTexture = function() end
UIPanelWindows = {}
GetCursorPosition = function()
	return 0, 0
end
local fakeTime = 1000
GetTime = function()
	return fakeTime
end

local failures = 0
local function check(name, cond)
    if cond then
        print("ok   " .. name)
    else
        failures = failures + 1
        print("FAIL " .. name)
    end
end

assert(loadfile("../Mangosbot_Core.lua"))()
assert(loadfile("../Mangosbot_Protocol.lua"))()
assert(loadfile("../Mangosbot_Commands.lua"))()
assert(loadfile("../Mangosbot_UI.lua"))()
assert(loadfile("../Mangosbot.lua"))()

check("MangosbotBotFrame created at load", MangosbotBotFrame ~= nil)
check("BotRoster created at load", BotRoster ~= nil)
check("BotDebugPanel created at load", BotDebugPanel ~= nil)

check("client detects wotlk", GetMangosbotVersion() == 2)
check("MB_HasDeathKnight on wotlk", MB_HasDeathKnight() == true)

check("fmod basic", fmod(7, 3) == 1)
check("fmod exact", fmod(9, 3) == 0)

check("trim2 strips leading/trailing spaces", trim2("  hello  ") == "hello")
check("trim2 strips tabs/newlines", trim2("\tfoo\n") == "foo")

check("StripColors removes |cAARRGGBB", StripColors("|cff00ff00near|r") == "near")
check("StripColors leaves plain text", StripColors("near") == "near")
check("StripColors removes dangling |h", StripColors("|h20/56|h Bag") == "20/56 Bag")
check("NormalizeMessage strips color and trims", NormalizeMessage("  |cff00ff00behind|r  ") == "behind")

local parts = splitString2("a, b, c", ", ")
check("splitString2 splits on pattern", #parts == 3 and parts[1] == "a" and parts[2] == "b" and parts[3] == "c")

check("StartsWith positive", StartsWith("Formation: near", "Formation:") == true)
check("StartsWith negative", StartsWith("Stance: near", "Formation:") == false)
check("AfterPrefix trims value", AfterPrefix("Formation:  near  ", "Formation:") == "near")

local capA, capB = MB_Match("20/56 Bag", "(%d+)/(%d+) Bag")
check("MB_Match two captures", capA == "20" and capB == "56")
check("MB_Match nil on miss", MB_Match("Formation: near", "(%d+)/(%d+) Bag") == nil)
check("MB_Match nil input", MB_Match(nil, "(%d+)") == nil)

local savedGetUnitName = GetUnitName
GetUnitName = function() return "FromGet" end
check("MB_UnitName prefers GetUnitName", MB_UnitName("target") == "FromGet")
GetUnitName = nil
UnitName = function() return "FromUnit" end
check("MB_UnitName falls back to UnitName", MB_UnitName("target") == "FromUnit")
GetUnitName = savedGetUnitName
UnitName = function() return nil end

check("tablelength counts entries", tablelength({a=1,b=2,c=3}) == 3)

local ordered = {}
for k in orderedPairs({b=1,a=2}) do ordered[#ordered + 1] = k end
check("orderedPairs iterates keys alphabetically", ordered[1] == "a" and ordered[2] == "b")

local bot = "TestBot"

OnSystemMessage('Bot roster: +WarriorBot Warrior, -MageBot Mage, +DkBot DeathKnight')
check("OnSystemMessage parses online bot", botTable["WarriorBot"] ~= nil and botTable["WarriorBot"].online == true)
check("OnSystemMessage parses offline bot", botTable["MageBot"] ~= nil and botTable["MageBot"].online == false)
check("OnSystemMessage sets class", botTable["WarriorBot"].class == "Warrior")
check("OnSystemMessage parses DeathKnight", botTable["DkBot"].class == "DeathKnight")
check("ClassToken DeathKnight", ClassToken("DeathKnight") == "DEATHKNIGHT")

OnSystemMessage('Bot roster: +A |cff00ff00Warrior|r')
check("OnSystemMessage strips colors in class", botTable["A"].class == "Warrior")

-- Modern playerbots engine labels
OnWhisper('Combat Strategies: frost, potions, boost', bot)
check("Combat Strategies stores co", botTable[bot].strategy.co[1] == "frost")
check("Combat Strategies assigns dps role", botTable[bot].role == "dps")

OnWhisper('Non Combat Strategies: food, buff, stay', bot)
check("Non Combat Strategies stores nc", botTable[bot].strategy.nc[1] == "food")
check("Non Combat keeps prior co", botTable[bot].strategy.co[1] == "frost")

OnWhisper('Reaction Strategies: potions', bot)
check("Reaction Strategies stores react", botTable[bot].strategy.react[1] == "potions")

OnWhisper('Dead Strategies: ghost', bot)
check("Dead Strategies stores dead", botTable[bot].strategy.dead[1] == "ghost")

-- Server strategy names carry spaces; checkbox lookup must use them, not tokens.
OnWhisper('Combat Strategies: conserve mana, mark rti, frost', bot)
check("spaced name matches checkbox lookup", BotHasStrategy(botTable[bot], "conserve mana") == true)
check("spaced mark rti matches checkbox lookup", BotHasStrategy(botTable[bot], "mark rti") == true)
check("underscore token does not match server name", BotHasStrategy(botTable[bot], "conserve_mana") == false)

-- Behavior checkbox items map to the engine the strategy lives in (AiFactory).
local behaviorItem = {}
for gi = 1, table.getn(BEHAVIOR_GROUPS) do
	local g = BEHAVIOR_GROUPS[gi]
	for i = 1, table.getn(g.items) do
		behaviorItem[g.items[i].token] = g.items[i]
	end
end
check("potions toggles reaction engine", behaviorItem["potions"].engines[1] == "react")
check("food toggles noncombat engine", behaviorItem["food"].engines[1] == "nc")
check("boost toggles combat engine", behaviorItem["boost"].engines[1] == "co")
check("buff toggles combat and noncombat",
    behaviorItem["buff"].engines[1] == "co" and behaviorItem["buff"].engines[2] == "nc")
check("conserve mana uses server name", behaviorItem["conserve_mana"].name == "conserve mana")
check("mark rti uses server name", behaviorItem["mark_rti"].name == "mark rti")

-- Class spec checkboxes map to real playerbots strategy names and toggle all engines.
check("druid spec uses real name", CLASS_STRATEGIES.DRUID[1].token == "tank feral")
check("druid spec toggles all engines", CLASS_STRATEGIES.DRUID[1].engines[1] == "all")
check("hunter spec beast mastery", CLASS_STRATEGIES.HUNTER[1].token == "beast mastery")
check("deathknight spec frost", CLASS_STRATEGIES.DEATHKNIGHT[2].token == "frost")
local classTokens = {}
for _, list in pairs(CLASS_STRATEGIES) do
	for i = 1, table.getn(list) do
		classTokens[list[i].token] = true
	end
end
check("no dead class tokens remain", classTokens["bear"] == nil and classTokens["dps"] == nil
    and classTokens["bdeath"] == nil and classTokens["caster"] == nil)

-- An `all ±spec,?` toggle updates every engine list; display stays consistent.
OnWhisper('Combat Strategies: tank feral, frost', bot)
OnWhisper('Non Combat Strategies: tank feral, food', bot)
OnWhisper('Reaction Strategies: tank feral, react', bot)
OnWhisper('Dead Strategies: tank feral, ghost', bot)
check("spec in any engine shows checked", BotHasStrategy(botTable[bot], "tank feral") == true)
OnWhisper('Combat Strategies: frost', bot)
OnWhisper('Non Combat Strategies: food', bot)
OnWhisper('Reaction Strategies: react', bot)
OnWhisper('Dead Strategies: ghost', bot)
check("all toggle removes spec everywhere", BotHasStrategy(botTable[bot], "tank feral") == false)

-- Short engine prefixes
OnWhisper('co Strategies: blood, tank', bot)
check("co Strategies: short prefix", botTable[bot].strategy.co[1] == "blood")
check("blood strategy sets tank role", botTable[bot].role == "tank")

-- Legacy bare Strategies: with nc marker
OnWhisper('Strategies: nc, attack weak, food', bot)
check("legacy Strategies: nc list",
    botTable[bot].strategy.nc[1] == "nc" or botTable[bot].strategy.nc[2] == "attack weak")

-- Colored formation / stance (server format)
OnWhisper('Formation: |cff00ff00near|r', bot)
check("Formation strips color", botTable[bot].formation == "near")

OnWhisper('Stance: |cff00ff00behind|r', bot)
check("Stance strips color and full value", botTable[bot].stance == "behind")

OnWhisper('Mana save level set: 3', bot)
check("Mana save level set", botTable[bot].savemana == "3")

OnWhisper('Mana save level: 0', bot)
check("Mana save level query", botTable[bot].savemana == "0")

OnWhisper('Loot strategy: all', bot)
check("Loot strategy", botTable[bot].loot == "all")

OnWhisper('Loot strategy set to gray', bot)
check("Loot strategy set to", botTable[bot].loot == "gray")

OnWhisper('rti: skull', bot)
check("rti parse", botTable[bot].rti == "skull")

OnWhisper('rti cc: moon', bot)
check("rti cc parse", botTable[bot].rti_cc == "moon")

OnWhisper('rti set to: cross', bot)
check("rti set to", botTable[bot].rti == "cross")

OnWhisper('rti cc set to: diamond', bot)
check("rti cc set to", botTable[bot].rti_cc == "diamond")

-- Set-to acks carry the new value, so they parse directly (no re-query needed).
OnWhisper('Formation set to: arrow', bot)
check("Formation set to parsed", botTable[bot].formation == "arrow")

OnWhisper('Stance set to: tank', bot)
check("Stance set to parsed", botTable[bot].stance == "tank")

-- BOT\t framed payload
OnWhisper('BOT\tFormation: |cff00ff00arrow|r', bot)
check("BOT\\t frame stripped", botTable[bot].formation == "arrow")

-- Stats replies (playerbots StatsAction format)
OnWhisper(
    '12g 34s 5c, |h|cff00ff0020/56|h|cffffffff Bag, |cff00ff00100% (0)|cffffffff Dur, '
        .. '|cff00ff0078|cffffd333/|cff00ff00200%|cffffffff XP, |h|cff1eff00214|h|cffffffff|h Pwr',
    bot
)
	check("stats parses money", botTable[bot].money == "12g 34s 5c")
	check("stats parses bag free", botTable[bot].bagFree == 20)
	check("stats parses bag total", botTable[bot].bagTotal == 56)
	check("stats parses durability", botTable[bot].durability == "100% (0)")
	check("stats parses xp", botTable[bot].xp == "78/200%")
	check("stats keeps strategy cache", botTable[bot].role == "tank")

OnWhisper('0, |cff00ff00|h16/16|h|cffffffff Bag', bot)
check("stats zero money", botTable[bot].money == "0")
check("stats zero money bags", botTable[bot].bagFree == 16 and botTable[bot].bagTotal == 16)

	local stats = ParseStatsReply('5g 20s, 30/40 Bag, 80% (0) Dur')
	check("ParseStatsReply plain line", stats.money == "5g 20s" and stats.bagFree == 30 and stats.bagTotal == 40 and stats.durability == "80% (0)")
check("ParseStatsReply nil on non-stats", ParseStatsReply('Formation: near') == nil)
check("ParseStatsReply nil on nil", ParseStatsReply(nil) == nil)
check("ParseMoneyToCopper g/s/c", ParseMoneyToCopper("12g 34s 5c") == 123405)
check("ParseMoneyToCopper zero", ParseMoneyToCopper("0") == 0)
local xpCur, xpMax = ParseXpProgress("78/200%")
check("ParseXpProgress percent pair", xpCur == 78 and xpMax == 100)
local xp2, xp2m = ParseXpProgress("45%")
check("ParseXpProgress bare percent", xp2 == 45 and xp2m == 100)

check("IsBotProtocolMessage stats reply",
    IsBotProtocolMessage('12g 34s 5c, |h|cff00ff0020/56|h|cffffffff Bag, 100% (0) Dur') == true)
check("IsBotProtocolMessage normal chat not stats", IsBotProtocolMessage('How many bags do you want?') == false)

-- CHAT_MSG_ADDON payload helper
local m, s = GetChatEventPayload("CHAT_MSG_ADDON", "BOT", "Stance: tank", "PARTY", "BotA")
check("GetChatEventPayload addon", m == "Stance: tank" and s == "BotA")
local m2 = GetChatEventPayload("CHAT_MSG_ADDON", "OTHER", "nope", "PARTY", "X")
check("GetChatEventPayload ignores other prefix", m2 == nil)
local m3, s3 = GetChatEventPayload("CHAT_MSG_WHISPER", "hello", "BotB", nil, nil)
check("GetChatEventPayload whisper", m3 == "hello" and s3 == "BotB")

check("EnsureAddonPrefix adds #a", EnsureAddonPrefix("formation ?") == "#a formation ?")
check("EnsureAddonPrefix idempotent", EnsureAddonPrefix("#a formation ?") == "#a formation ?")
check("EnsureAddonPrefix leaves .bot", EnsureAddonPrefix(".bot list") == ".bot list")
check("IsBotProtocolMessage Formation", IsBotProtocolMessage("Formation: |cff00ff00near|r") == true)
check("IsBotProtocolMessage Stance", IsBotProtocolMessage("Stance: Near") == true)
check("IsBotProtocolMessage Bot roster", IsBotProtocolMessage("Bot roster: +A Warrior, -B Mage") == true)
check("IsBotProtocolMessage add cmd", IsBotProtocolMessage("add: Bob - ok") == true)
check("IsBotProtocolMessage Following", IsBotProtocolMessage("Following") == true)
check("IsBotProtocolMessage Combat Strategies", IsBotProtocolMessage("Combat Strategies: frost, potions") == true)
check("IsBotProtocolMessage rti set", IsBotProtocolMessage("rti set to: skull") == true)
check("IsBotProtocolMessage Please set formation", IsBotProtocolMessage("Please set to any of: near, queue") == true)
check("IsBotProtocolMessage normal chat", IsBotProtocolMessage("Hello there") == false)
check("IsBotProtocolMessage mid-sentence following", IsBotProtocolMessage("I am following the quest path") == false)
check("IsBotProtocolMessage BOT frame", IsBotProtocolMessage("BOT\t#a formation ?") == true)

check("partySize() with no party", partySize() == 0)
check("botCount() after roster+TestBot", botCount() == 2) -- A + TestBot from later whispers; roster replaced twice

-- Re-seed roster for botCount
OnSystemMessage('Bot roster: +W Warrior, -M Mage')
OnWhisper('Combat Strategies: frost', bot)
check("botCount roster plus TestBot", botCount() == 3)

-- Roster rebuild must keep cached role/stats for party badges
OnWhisper('9g, 11/22 Bag', bot)
OnSystemMessage('Bot roster: +' .. bot .. ' Warrior, +W Warrior, -M Mage')
check("roster rebuild keeps money", botTable[bot].money == "9g")
check("roster rebuild keeps bags", botTable[bot].bagFree == 11 and botTable[bot].bagTotal == 22)
check("roster rebuild keeps role", botTable[bot].role == "dps")
check("roster rebuild sets class/online", botTable[bot].class == "Warrior" and botTable[bot].online == true)

local immediate = 0
check("wait accepts valid args", wait(0.05, function() immediate = immediate + 1 end) == true)
check("wait rejects non-number delay", wait("x", function() end) == false)
check("wait rejects non-function", wait(0.5, 42) == false)

local waitFrame
for _, f in ipairs(frames) do
    if f.script then waitFrame = f end
end

waitFrame.script()
check("wait runs callback once delay elapses", immediate == 1)

local delayed = 0
wait(0.5, function() delayed = delayed + 1 end)
for _ = 1, 5 do waitFrame.script() end
check("wait defers while delay remains", delayed == 0)
waitFrame.script()
check("wait runs callback after enough ticks", delayed == 1)

check("OnWhisper dirty on formation", OnWhisper("Formation: near", bot) == true)
check("OnWhisper clean on hello", OnWhisper("Hello there", bot) == false)
check("OnWhisper clean on nil", OnWhisper(nil, bot) == false)

-- Button state matching (shared by roster group bar + selected panel)
local matchBot = {
	strategy = { nc = { "food", "buff" }, co = { "frost", "potions" } },
	formation = "near",
	stance = "behind",
	rti = "skull",
	rti_cc = "moon",
	loot = "gray",
	savemana = "3",
}
check("BotHasStrategy finds nc entry", BotHasStrategy(matchBot, "food") == true)
check("BotHasStrategy finds co entry", BotHasStrategy(matchBot, "frost") == true)
check("BotHasStrategy misses unknown", BotHasStrategy(matchBot, "tank") == false)
check("BotButtonIsActive strategy", BotButtonIsActive(matchBot, { strategy = "potions" }) == true)
check("BotButtonIsActive formation", BotButtonIsActive(matchBot, { formation = "near" }) == true)
check("BotButtonIsActive stance", BotButtonIsActive(matchBot, { stance = "behind" }) == true)
check("BotButtonIsActive rti", BotButtonIsActive(matchBot, { rti = "skull" }) == true)
check("BotButtonIsActive inactive", BotButtonIsActive(matchBot, { strategy = "bear" }) == false)
check("BotIsInParty false when empty", BotIsInParty("Nobody") == false)

local rtiHost = CreateFrame("Frame", "TestRtiHost")
local rtiBtns = CreateRtiToolBar(rtiHost, 0, "test_rti", false, 0, 0, false)
check("generated rti skull command", rtiBtns["rti_skull"].command[0] == "rti skull")
check("generated rti skull field", rtiBtns["rti_skull"].rti == "skull")
check("generated rti moon last index", rtiBtns["rti_moon"].index == 7)
local rtiCcBtns = CreateRtiCcToolBar(rtiHost, 0, "test_rti_cc", false, 0, 0, false)
check("generated rti cc moon command", rtiCcBtns["rti_moon"].command[0] == "rti cc moon")
check("generated rti cc moon field", rtiCcBtns["rti_moon"].rti_cc == "moon")

-- Persist last-known config; live stats stay session-only.
botTable["CacheBot"] = {
	class = "Warrior",
	role = "tank",
	formation = "near",
	stance = "behind",
	savemana = "3",
	loot = "gray",
	rti = "skull",
	rti_cc = "moon",
	strategy = { co = { "frost" }, nc = { "food" }, react = { "potions" } },
	online = true,
	money = "12g",
	bagFree = 4,
	bagTotal = 16,
	xp = "1/2%",
}
PersistBotCache()
check("persist writes formation", MangosbotDB.bots.CacheBot.formation == "near")
check("persist writes strategy", MangosbotDB.bots.CacheBot.strategy.co[1] == "frost")
check("persist skips money", MangosbotDB.bots.CacheBot.money == nil)
check("persist skips online", MangosbotDB.bots.CacheBot.online == nil)
check("group state complete", BotHasGroupState(botTable["CacheBot"]) == true)
check("panel state complete", BotHasPanelState(botTable["CacheBot"]) == true)
check("group state incomplete", BotHasGroupState({ formation = "near" }) == false)
check("party query skipped when not grouped", PartyNeedsStateQuery() == false)

botTable = {}
RestoreBotCache()
check("restore formation", botTable["CacheBot"].formation == "near")
check("restore class", botTable["CacheBot"].class == "Warrior")
check("restore strategy", botTable["CacheBot"].strategy.nc[1] == "food")
check("restore leaves online unset", botTable["CacheBot"].online == nil)
check("restore leaves money unset", botTable["CacheBot"].money == nil)

OnWhisper("Formation set to: arrow", "CacheBot")
check("whisper persist updates cache", MangosbotDB.bots.CacheBot.formation == "arrow")

-- Classic client detection
GetBuildInfo = function() return "1.12.1", "5875", "Sep 19 2006", 11000 end
-- re-load core detection is once at load; just unit-test helpers still ok
check("fmod still works after", fmod(5, 2) == 1)

-- CanonicalSet compares reordered/duplicated server strategy echoes.
check("CanonicalSet dedupes and sorts",
    CanonicalSet("equip,vendor,disenchant,quest,skill,use,vendor") == "disenchant,equip,quest,skill,use,vendor")
check("CanonicalSet single token", CanonicalSet("  gray ") == "gray")
check("CanonicalSet nil", CanonicalSet(nil) == nil)

-- Loot dropdown round-trips the server's expanded echo back to an option.
check("loot label matches expanded all",
    BotLootLabel("equip,vendor,disenchant,quest,skill,use,vendor,trash") == "Everything")
check("loot label matches default strategy",
    BotLootLabel("equip,quest,skill,disenchant,use,vendor") == "Gray items")
check("loot label matches keyword", BotLootLabel("gray") == "Gray items")
check("loot label matches trade skills",
    BotLootLabel("equip,vendor,quest,skill,use") == "Trade skills")

-- SendStrategyToggle sends a bare toggle, then re-queries the engine after the
-- AI settles (no ",?" on the toggle: the delayed query wins over any stale
-- panel-open reply and reflects post-settle strategy state).
for _ = 1, 12 do waitFrame.script() end -- drain any leftover wait records
local sentCommands = {}
local realSendChatMessage = SendChatMessage
SendChatMessage = function(text, _chat, _lang, _channel)
	table.insert(sentCommands, text)
end
CurrentBot = "ToggleBot"
botTable["ToggleBot"] = { strategy = { nc = {}, co = {}, react = {}, dead = {} } }
local foodCheckbox = MangosbotBotFrame.checkboxes["food"]
this = foodCheckbox
foodCheckbox.script()
check("toggle sends bare engine command", sentCommands[1] == "BOT\tnc -food")
check("toggle sends no query on the toggle", #sentCommands == 1)
-- 12 ticks = 1.2s > the 0.6s re-query delay; generous to absorb the harness's
-- exact-0.1s float drift (0.6-0.1*5 == 0.10000000000000003 > 0.1).
for _ = 1, 12 do waitFrame.script() end
check("toggle re-queries engine after settle", sentCommands[2] == "BOT\tnc ?")
check("toggle re-query only its engine", #sentCommands == 2)
this = nil
SendChatMessage = realSendChatMessage

if failures == 0 then
    print("ALL TESTS PASSED")
    os.exit(0)
else
    print(failures .. " TEST(S) FAILED")
    os.exit(1)
end
