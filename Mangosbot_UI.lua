-- UI: shared chrome, toolbar state, debug panel

function ClickToolBarButton(toolbar, button)
	local btn = ToolBars[toolbar][button]
	ToolBarButtonOnClick(btn, false)
end

function ClickGroupToolBarButton(toolbar, button)
	local btn = GroupToolBars[toolbar][button]
	ToolBarButtonOnClick(btn, false)
end

-- Send a button's commands: group=true broadcasts to party, else whispers the target bot.
function ToolBarButtonOnClick(btn, visual)
	if btn["handler"] ~= nil then
		btn["handler"]()
		return
	end

	if visual then
		btn:SetBackdropBorderColor(0.8, 0.2, 0.2, 1.0)
	end

	if btn["emote"] ~= nil then
		DoEmote(btn["emote"])
	end

	if btn["group"] then
		local combined = CombineBotCommands(btn["command"])
		wait(0, function(cmd)
			SendBotCommand(cmd, "PARTY")
		end, combined)
	else
		local bot = MB_UnitName("target")
		if bot == nil then
			bot = CurrentBot
		end
		local combined = CombineBotCommands(btn["command"])
		wait(0, function(cmd, target)
			SendBotCommand(cmd, "WHISPER", nil, target)
		end, combined, bot)
	end
end

function ToggleButton(frame, toolbar, button, toggle, mixed)
	local btn = frame.toolbar[toolbar].buttons[button]
	if toggle and mixed then
		btn:SetBackdropBorderColor(0.2, 0.4, 0.2, 1.0)
	elseif toggle then
		btn:SetBackdropBorderColor(0.2, 1.0, 0.2, 1.0)
	else
		btn:SetBackdropBorderColor(0, 0, 0, 0.0)
	end
end

-- Persist drag position into the frameopts saved variable; restore it on Show.
function EnablePositionSaving(frame, frameName)
	frame:SetScript("OnMouseDown", function()
		this:StartMoving()
	end)
	frame:SetScript("OnMouseUp", function()
		local self = frame
		self:StopMovingOrSizing()

		if frameopts == nil then
			frameopts = {}
		end
		if frameopts[frameName] == nil then
			frameopts[frameName] = {}
		end

		local opts = frameopts[frameName]
		local from, _, to, x, y = self:GetPoint()

		opts.anchorFrom = from
		opts.anchorTo = to

		if self.is_expanded then
			if opts.anchorFrom == "TOPLEFT" or opts.anchorFrom == "LEFT" or opts.anchorFrom == "BOTTOMLEFT" then
				opts.offsetx = x
			elseif opts.anchorFrom == "TOP" or opts.anchorFrom == "CENTER" or opts.anchorFrom == "BOTTOM" then
				opts.offsetx = x - 151 / 2
			elseif opts.anchorFrom == "TOPRIGHT" or opts.anchorFrom == "RIGHT" or opts.anchorFrom == "BOTTOMRIGHT" then
				opts.offsetx = x - 151
			end
		else
			opts.offsetx = x
		end
		opts.offsety = y
	end)

	do
		-------------------------------------------------------------------------------
		-- Restore the panel's position on the screen.
		-------------------------------------------------------------------------------
		local function Reset_Position()
			local self = frame
			if frameopts == nil then
				frameopts = {}
			end
			if frameopts[frameName] == nil then
				frameopts[frameName] = {}
			end
			local opts = frameopts[frameName]

			self:ClearAllPoints()

			if opts.anchorTo == nil then
				self:SetPoint("CENTER", UIParent, "CENTER")
			else
				self:SetPoint(opts.anchorFrom, UIParent, opts.anchorTo, opts.offsetx, opts.offsety)
			end
		end

		frame:SetScript("OnShow", Reset_Position)
	end -- do-block
end


function StartChat()
	local editBox = MB_ChatEditBox()
	if editBox == nil then
		return
	end
	editBox:Show()
	editBox:SetFocus()
	local name = MB_UnitName("target")
	if name == nil then
		name = CurrentBot
	end
	editBox:SetText("/w " .. name .. " ")
end

local STRATEGY_ENGINES = { "nc", "co", "react", "dead" }

local function BotFieldContains(bot, field, value)
	return value ~= nil and bot[field] ~= nil and string.find(bot[field], value) ~= nil
end

function BotHasStrategy(bot, strategyName)
	if bot == nil or strategyName == nil or bot["strategy"] == nil then
		return false
	end
	for ei = 1, 4 do
		local elist = bot["strategy"][STRATEGY_ENGINES[ei]]
		if elist ~= nil then
			for _, strategy in pairs(elist) do
				if strategy == strategyName then
					return true
				end
			end
		end
	end
	return false
end

-- True when reported bot state matches the button (drives toggle highlighting).
function BotButtonIsActive(bot, button)
	if bot == nil or button == nil then
		return false
	end
	if button["strategy"] ~= nil and BotHasStrategy(bot, button["strategy"]) then
		return true
	end
	if BotFieldContains(bot, "formation", button["formation"]) then
		return true
	end
	if BotFieldContains(bot, "stance", button["stance"]) then
		return true
	end
	if BotFieldContains(bot, "rti", button["rti"]) then
		return true
	end
	if BotFieldContains(bot, "rti_cc", button["rti_cc"]) then
		return true
	end
	if BotFieldContains(bot, "loot", button["loot"]) then
		return true
	end
	if BotFieldContains(bot, "savemana", button["savemana"]) then
		return true
	end
	return false
end

function BotIsInParty(botName)
	for i = 1, 5 do
		if partyName(i) == botName then
			return true
		end
	end
	return false
end

-- Solid green when all party bots match a button; green outline when only some do.
function UpdateGroupToolBar()
	for toolbarName, toolbar in pairs(GroupToolBars) do
		for buttonName, button in pairs(toolbar) do
			local toggleCount = 0
			for botName, bot in pairs(botTable) do
				if BotButtonIsActive(bot, button) and BotIsInParty(botName) then
					toggleCount = toggleCount + 1
				end
			end
			ToggleButton(BotRoster, toolbarName, buttonName, toggleCount > 0, toggleCount < partySize())
		end
	end
end

local MAX_BOT_DEBUG_LINES = 500
local BotDebugLog = {}

local function CreateDebugTextButton(parent, name, label, width)
	local btn = CreateFrame("Button", name, parent)
	btn:SetWidth(width)
	btn:SetHeight(18)
	btn:SetBackdrop({
		bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
		edgeFile = "Interface/ChatFrame/ChatFrameBackground",
		tile = true,
		tileSize = 16,
		edgeSize = 1,
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
	})
	btn:SetBackdropColor(0.1, 0.1, 0.1, 1)
	btn:SetBackdropBorderColor(0.5, 0.1, 0.7, 1)
	btn:EnableMouse(true)
	btn:RegisterForClicks("LeftButtonDown")
	btn.text = btn:CreateFontString(nil, "OVERLAY")
	btn.text:SetFont("Fonts/FRIZQT__.TTF", 10, "OUTLINE")
	btn.text:SetPoint("CENTER", btn, "CENTER", 0, 0)
	btn.text:SetText(label)
	return btn
end

local function RefreshBotDebugHeader()
	if BotDebugPanel == nil or BotDebugPanel.header == nil then
		return
	end
	BotDebugPanel.header.text:SetText("Debug Log (" .. table.getn(BotDebugLog) .. ")  >> send  << recv")
end

function ClearBotDebugLog()
	BotDebugLog = {}
	if BotDebugPanel ~= nil and BotDebugPanel.scroll ~= nil then
		BotDebugPanel.scroll:Clear()
	end
	RefreshBotDebugHeader()
end

function ShowBotDebugCopyFrame()
	local f = BotDebugCopyFrame
	if f == nil then
		f = CreateFrame("Frame", "BotDebugCopyFrame", UIParent)
		f:SetWidth(520)
		f:SetHeight(360)
		f:SetPoint("CENTER", UIParent, "CENTER")
		f:SetFrameStrata("FULLSCREEN_DIALOG")
		f:EnableMouse(true)
		f:SetMovable(true)
		f:RegisterForDrag("LeftButton")
		f:SetScript("OnMouseDown", function()
			this:StartMoving()
		end)
		f:SetScript("OnMouseUp", function()
			this:StopMovingOrSizing()
		end)
		f:SetBackdrop({
			bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
			edgeFile = "Interface/ChatFrame/ChatFrameBackground",
			tile = true,
			tileSize = 16,
			edgeSize = 2,
			insets = { left = 0, right = 0, top = 0, bottom = 0 },
		})
		f:SetBackdropColor(0, 0, 0, 1)
		f:SetBackdropBorderColor(0.5, 0.1, 0.7, 1)

		f.title = f:CreateFontString(nil, "OVERLAY")
		f.title:SetFont("Fonts/FRIZQT__.TTF", 11, "OUTLINE")
		f.title:SetPoint("TOP", f, "TOP", 0, -8)
		f.title:SetText("Press Ctrl+C to copy, Escape to close")

		local scroll = CreateFrame("ScrollFrame", "BotDebugCopyScroll", f)
		scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -28)
		scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)

		local edit = CreateFrame("EditBox", "BotDebugCopyEdit", scroll)
		edit:SetMultiLine(true)
		edit:SetAutoFocus(true)
		edit:SetFont("Fonts/FRIZQT__.TTF", 11)
		edit:SetWidth(500)
		edit:SetMaxLetters(999999)
		edit:SetScript("OnEscapePressed", function()
			this:ClearFocus()
			f:Hide()
		end)
		edit:SetScript("OnTextChanged", function()
			scroll:UpdateScrollChildRect()
		end)
		scroll:SetScrollChild(edit)
		f.edit = edit
		f.scroll = scroll
		BotDebugCopyFrame = f
	end

	local text = table.concat(BotDebugLog, "\n")
	if text == nil or text == "" then
		text = "(no messages yet)"
	end
	f.edit:SetText(text)
	f.edit:SetFocus()
	f.edit:HighlightText()
	f:Show()
end

function BotDebugLogMessage(direction, message, peer)
	if BotDebugPanel == nil or not BotDebugPanel:IsVisible() then
		return
	end
	if message == nil then
		message = ""
	end

	local ts = ""
	if date then
		ts = date("%H:%M:%S") .. " "
	end

	local peerPart = ""
	if peer ~= nil and peer ~= "" then
		peerPart = " [" .. tostring(peer) .. "]"
	end

	local line = ts .. direction .. peerPart .. " " .. tostring(message)
	table.insert(BotDebugLog, line)
	while table.getn(BotDebugLog) > MAX_BOT_DEBUG_LINES do
		tremove(BotDebugLog, 1)
	end

	if BotDebugPanel.scroll ~= nil then
		-- Direction colors: >> gold (sent), << blue (received), sys green.
		local r, g, b = 0.9, 0.9, 0.9
		if direction == ">>" then
			r, g, b = 1.0, 0.82, 0.0
		elseif direction == "<<" then
			r, g, b = 0.55, 0.8, 1.0
		elseif direction == "sys" then
			r, g, b = 0.4, 1.0, 0.4
		end
		BotDebugPanel.scroll:AddMessage(line, r, g, b)
	end
	RefreshBotDebugHeader()
end

function CreateBotDebugPanel()
	local frame = CreateFrame("Frame", "BotDebugPanel", UIParent)
	frame:Hide()
	frame:SetWidth(480)
	frame:SetHeight(320)
	frame:SetPoint("CENTER", UIParent, "CENTER")
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetFrameStrata("DIALOG")
	frame:SetBackdropColor(0, 0, 0, 1.0)
	frame:SetBackdrop({
		bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
		edgeFile = "Interface/ChatFrame/ChatFrameBackground",
		tile = true,
		tileSize = 16,
		edgeSize = 2,
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
	})
	frame:SetBackdropBorderColor(0.5, 0.1, 0.7, 1)
	frame:RegisterForDrag("LeftButton")

	frame.header = CreateFrame("Frame", "BotDebugPanelHeader", frame)
	frame.header:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
	frame.header:SetWidth(frame:GetWidth())
	frame.header:SetHeight(22)
	frame.header:SetBackdropColor(0.5, 0.1, 0.7, 1)
	frame.header:SetBackdrop({
		bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
		edgeFile = "Interface/ChatFrame/ChatFrameBackground",
		tile = true,
		tileSize = 16,
		edgeSize = 0,
		insets = { left = 2, right = 2, top = 2, bottom = 0 },
	})
	frame.header:SetBackdropBorderColor(0.5, 0.1, 0.7, 1)

	frame.header.text = frame.header:CreateFontString("BotDebugPanelHeaderText")
	frame.header.text:SetPoint("TOPLEFT", frame.header, "TOPLEFT", 6, 0)
	frame.header.text:SetWidth(frame.header:GetWidth() - 200)
	frame.header.text:SetHeight(22)
	frame.header.text:SetFont("Fonts/FRIZQT__.TTF", 11, "OUTLINE")
	frame.header.text:SetJustifyH("LEFT")
	frame.header.text:SetText("Debug Log")

	local copyBtn = CreateDebugTextButton(frame.header, "BotDebugCopyBtn", "Copy", 50)
	copyBtn:SetPoint("TOPRIGHT", frame.header, "TOPRIGHT", -58, -2)
	copyBtn:SetScript("OnClick", function()
		ShowBotDebugCopyFrame()
	end)

	local clearBtn = CreateDebugTextButton(frame.header, "BotDebugClearBtn", "Clear", 50)
	clearBtn:SetPoint("TOPRIGHT", frame.header, "TOPRIGHT", -4, -2)
	clearBtn:SetScript("OnClick", function()
		ClearBotDebugLog()
	end)

	local scroll = CreateFrame("ScrollingMessageFrame", "BotDebugScroll", frame)
	scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -26)
	scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 6)
	scroll:SetFont("Fonts/FRIZQT__.TTF", 11)
	scroll:SetJustifyH("LEFT")
	scroll:SetFading(false)
	scroll:SetMaxLines(MAX_BOT_DEBUG_LINES)
	scroll:EnableMouseWheel(true)
	scroll:SetScript("OnMouseWheel", function()
		if arg1 > 0 then
			this:ScrollUp()
		elseif arg1 < 0 then
			this:ScrollDown()
		end
	end)
	frame.scroll = scroll

	EnablePositionSaving(frame, "BotDebugPanel")

	return frame
end

function UpdateBotDebugPanel(message, sender)
	BotDebugLogMessage("<<", message, sender)

end

-- Bot panel: UIPanel opened when a bot is targeted

local BP_WIDTH = 384
local BP_HEIGHT = 512
local BP_PAD = 16
local BP_HEADER_H = 80
local BP_XP_H = 16
local BP_TOP_CHROME = 36
local BP_ROW_H = 32
local BP_CHECK_H = 26
local BP_SECTION_GAP = 14
local BP_COL2_X = 178
local BP_LABEL_W = 110
local BP_CONTENT_W = BP_WIDTH - 48
local BP_DROPDOWN_SEQ = 0

local function BpScrollTopOffset()
	return BP_TOP_CHROME + BP_HEADER_H + 8 + BP_XP_H + 8
end

local function BpCapitalize(s)
	if s == nil or s == "" then
		return "-"
	end
	return string.upper(string.sub(s, 1, 1)) .. string.sub(s, 2)
end

-- value = command token, label = UI text
local FORMATION_OPTS = {
	{ value = "near", label = "Near" },
	{ value = "queue", label = "Queue" },
	{ value = "melee", label = "Melee" },
	{ value = "arrow", label = "Arrow" },
	{ value = "far", label = "Far" },
	{ value = "circle", label = "Circle" },
	{ value = "line", label = "Line" },
	{ value = "shield", label = "Shield" },
	{ value = "chaos", label = "Chaos" },
}
local STANCE_OPTS = {
	{ value = "near", label = "Near" },
	{ value = "tank", label = "Tank" },
	{ value = "turnback", label = "Turn back" },
	{ value = "behind", label = "Behind" },
}
-- `set` is the canonical (sorted, deduped) expansion the server echoes for each
-- keyword (LootStrategyValue::Set backwards-compat mapping). "gray" and
-- "disenchant" expand to the same set server-side.
local LOOT_OPTS = {
	{ value = "normal", label = "Trade skills", set = "equip,quest,skill,use,vendor" },
	{ value = "gray", label = "Gray items", set = "disenchant,equip,quest,skill,use,vendor" },
	{ value = "disenchant", label = "Disenchant", set = "disenchant,equip,quest,skill,use,vendor" },
	{ value = "all", label = "Everything", set = "disenchant,equip,quest,skill,trash,use,vendor" },
}
local SAVEMANA_OPTS = {
	{ value = "1", label = "1 - Always cast" },
	{ value = "2", label = "2 - Low" },
	{ value = "3", label = "3 - Medium" },
	{ value = "4", label = "4 - High" },
	{ value = "5", label = "5 - Very high" },
}
local MARK_OPTS = {
	{ value = "skull", label = "Skull" },
	{ value = "cross", label = "Cross" },
	{ value = "circle", label = "Circle" },
	{ value = "star", label = "Star" },
	{ value = "square", label = "Square" },
	{ value = "triangle", label = "Triangle" },
	{ value = "diamond", label = "Diamond" },
	{ value = "moon", label = "Moon" },
}

-- Behavior toggles grouped for layout (two columns within each group).
-- `engines` target the playerbots engine(s) the strategy actually lives in
-- (see playerbot/AiFactory.cpp); `name` is the server strategy name when it
-- differs from the UI token (e.g. "conserve mana" vs. "conserve_mana").
BEHAVIOR_GROUPS = {
	{
		title = "Survival",
		items = {
			{ label = "Eat and drink", token = "food", engines = { "nc" } },
			{ label = "Use potions", token = "potions", engines = { "react" } },
			{ label = "Conserve mana", token = "conserve_mana", name = "conserve mana", engines = { "co" } },
		},
	},
	{
		title = "Activity",
		items = {
			{ label = "Buff allies", token = "buff", engines = { "co", "nc" } },
			{ label = "Loot corpses", token = "loot", engines = { "nc" } },
			{ label = "Gather nodes", token = "gather", engines = { "nc" } },
			{ label = "Grind mobs", token = "grind", engines = { "nc" } },
			{ label = "Combat boosts", token = "boost", engines = { "co" } },
			{ label = "Mark targets", token = "mark_rti", name = "mark rti", engines = { "co" } },
		},
	},
}

-- Class strategies: real playerbots strategy names + readable label.
-- Spec strategies live in all four engines (combat/noncombat/dead/reaction) so
-- they toggle via `all`; class-generic ones (cure, aoe, pet, totems) default to
-- co+nc. Names match getName() in playerbot/strategy/<class>/*Strategy.h.
CLASS_STRATEGIES = {
	DRUID = {
		{ token = "tank feral", label = "Bear form", engines = { "all" } },
		{ token = "dps feral", label = "Cat form", engines = { "all" } },
		{ token = "balance", label = "Caster", engines = { "all" } },
		{ token = "restoration", label = "Healing", engines = { "all" } },
		{ token = "cure", label = "Dispels" },
	},
	HUNTER = {
		{ token = "beast mastery", label = "Beast Mastery", engines = { "all" } },
		{ token = "marksmanship", label = "Marksmanship", engines = { "all" } },
		{ token = "survival", label = "Survival", engines = { "all" } },
		{ token = "pet", label = "Pet" },
		{ token = "aoe", label = "Area damage" },
	},
	MAGE = {
		{ token = "arcane", label = "Arcane", engines = { "all" } },
		{ token = "fire", label = "Fire", engines = { "all" } },
		{ token = "frost", label = "Frost", engines = { "all" } },
		{ token = "aoe", label = "Area damage" },
	},
	PALADIN = {
		{ token = "protection", label = "Tank", engines = { "all" } },
		{ token = "holy", label = "Healing", engines = { "all" } },
		{ token = "retribution", label = "Damage", engines = { "all" } },
		{ token = "cure", label = "Dispels" },
	},
	PRIEST = {
		{ token = "discipline", label = "Discipline", engines = { "all" } },
		{ token = "holy", label = "Healing", engines = { "all" } },
		{ token = "shadow", label = "Damage", engines = { "all" } },
		{ token = "cure", label = "Dispels" },
	},
	ROGUE = {
		{ token = "assassination", label = "Assassination", engines = { "all" } },
		{ token = "combat", label = "Combat", engines = { "all" } },
		{ token = "subtlety", label = "Subtlety", engines = { "all" } },
		{ token = "aoe", label = "Area damage" },
	},
	SHAMAN = {
		{ token = "elemental", label = "Elemental", engines = { "all" } },
		{ token = "enhancement", label = "Enhancement", engines = { "all" } },
		{ token = "restoration", label = "Healing", engines = { "all" } },
		{ token = "totems", label = "Totems" },
		{ token = "cure", label = "Dispels" },
	},
	WARLOCK = {
		{ token = "affliction", label = "Affliction", engines = { "all" } },
		{ token = "demonology", label = "Demonology", engines = { "all" } },
		{ token = "destruction", label = "Destruction", engines = { "all" } },
		{ token = "pet", label = "Pet" },
	},
	WARRIOR = {
		{ token = "arms", label = "Arms", engines = { "all" } },
		{ token = "fury", label = "Fury", engines = { "all" } },
		{ token = "protection", label = "Tank", engines = { "all" } },
		{ token = "aoe", label = "Area damage" },
	},
	DEATHKNIGHT = {
		{ token = "blood", label = "Tank", engines = { "all" } },
		{ token = "frost", label = "Damage", engines = { "all" } },
		{ token = "unholy", label = "Unholy", engines = { "all" } },
		{ token = "aoe", label = "Area damage" },
	},
}

local function SendToCurrentBot(cmd)
	if CurrentBot == nil or cmd == nil or cmd == "" then
		return
	end
	SendBotCommand(cmd, "WHISPER", nil, CurrentBot)
end

-- Buffers strategy toggles per engine during a click burst and flushes them as
-- one combined command per engine after a short quiet period (the server splits
-- engine strategy lists on commas, so "nc +food,-loot" toggles both in a single
-- message). A single "all ?" re-query runs after the AI settles: it lists every
-- state at once (combat, non combat, dead, react), refreshing the whole panel,
-- and lands after any stale panel-open replies so the new state wins. The delay
-- also absorbs the situation-strategy lag ("boost shadow pve" is dropped one AI
-- tick after the generic "boost" it depends on).
local ToggleDebounce = nil -- { token, bot, order = {}, toggles = {} }

local function SendStrategyToggle(name, on, engines)
	local target = CurrentBot
	if target == nil then
		return
	end
	if engines == nil then
		engines = { "co", "nc" }
	end
	local prefix = "+"
	if not on then
		prefix = "-"
	end
	if ToggleDebounce == nil then
		ToggleDebounce = { token = 0, bot = nil, order = {}, toggles = {} }
	end
	for i = 1, table.getn(engines) do
		local e = engines[i]
		if ToggleDebounce.toggles[e] == nil then
			ToggleDebounce.toggles[e] = {}
			table.insert(ToggleDebounce.order, e)
		end
		table.insert(ToggleDebounce.toggles[e], prefix .. name)
	end
	ToggleDebounce.bot = target
	ToggleDebounce.token = ToggleDebounce.token + 1
	local token = ToggleDebounce.token

	wait(0.3, function()
		if ToggleDebounce.token ~= token then
			return
		end
		local bot = ToggleDebounce.bot
		for i = 1, table.getn(ToggleDebounce.order) do
			local e = ToggleDebounce.order[i]
			local list = ToggleDebounce.toggles[e]
			if table.getn(list) > 0 then
				SendBotCommand(e .. " " .. table.concat(list, ","), "WHISPER", nil, bot)
			end
		end
		wait(0.6, function()
			if ToggleDebounce.token ~= token then
				return
			end
			ToggleDebounce.toggles = {}
			ToggleDebounce.order = {}
			SendBotCommand("all ?", "WHISPER", nil, bot)
		end)
	end)
end

function QueryBotPanelState(name)
	if name == nil then
		return
	end
	if not BotHasPanelState(botTable[name]) then
		QuerySelectedBot(name)
	end
	wait(0.05, function()
		SendBotCommand(EnsureAddonPrefix("stats"), "WHISPER", nil, name)
	end)
end


local function CreateMoneyDisplay(parent)
	local f = CreateFrame("Frame", nil, parent)
	f:SetHeight(14)

	local function makeCoin()
		local t = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		t:SetJustifyH("LEFT")
		local icon = f:CreateTexture(nil, "OVERLAY")
		icon:SetTexture("Interface\\MoneyFrame\\UI-MoneyIcons")
		icon:SetWidth(13)
		icon:SetHeight(13)
		return t, icon
	end

	f.goldText, f.goldIcon = makeCoin()
	f.goldIcon:SetTexCoord(0, 0.25, 0, 1)
	f.silverText, f.silverIcon = makeCoin()
	f.silverIcon:SetTexCoord(0.25, 0.5, 0, 1)
	f.copperText, f.copperIcon = makeCoin()
	f.copperIcon:SetTexCoord(0.5, 0.75, 0, 1)

	function f.SetCopper(moneyFrame, copper)
		if copper == nil or copper < 0 then
			copper = 0
		end
		local g = math.floor(copper / 10000)
		local s = math.floor((copper - g * 10000) / 100)
		local c = math.floor(copper - g * 10000 - s * 100)

		local x = 0
		local function place(text, icon, amount, always)
			if amount > 0 or always then
				text:SetText(tostring(amount))
				text:Show()
				icon:Show()
				text:ClearAllPoints()
				icon:ClearAllPoints()
				text:SetPoint("LEFT", f, "LEFT", x, 0)
				local tw = 12
				if text.GetStringWidth then
					tw = text:GetStringWidth() or tw
				end
				icon:SetPoint("LEFT", text, "RIGHT", 1, 0)
				x = x + tw + 13 + 6
			else
				text:Hide()
				icon:Hide()
			end
		end

		place(moneyFrame.goldText, moneyFrame.goldIcon, g, false)
		place(moneyFrame.silverText, moneyFrame.silverIcon, s, g > 0)
		place(moneyFrame.copperText, moneyFrame.copperIcon, c, true)
		moneyFrame:SetWidth(x)
	end

	f:SetCopper(0)
	return f
end

local function CreateXpBar(parent)
	local bar = CreateFrame("StatusBar", nil, parent)
	bar:SetHeight(BP_XP_H)
	bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	if bar.SetStatusBarColor then
		bar:SetStatusBarColor(0.58, 0.0, 0.55)
	end
	bar:SetMinMaxValues(0, 100)
	bar:SetValue(0)

	local bg = bar:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
	bg:SetVertexColor(0.0, 0.0, 0.0, 0.85)

	local border = CreateFrame("Frame", nil, bar)
	border:SetPoint("TOPLEFT", bar, "TOPLEFT", -2, 2)
	border:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 2, -2)
	if border.SetBackdrop then
		border:SetBackdrop({
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			edgeSize = 10,
			insets = { left = 2, right = 2, top = 2, bottom = 2 },
		})
		border:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
	end
	if border.SetFrameLevel and bar.GetFrameLevel then
		border:SetFrameLevel(bar:GetFrameLevel() + 2)
	end

	bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	bar.text:SetPoint("CENTER", bar, "CENTER", 0, 0)
	bar.text:SetText("Experience")

	function bar.SetXp(statusBar, xpStr)
		local cur, maxv, label = ParseXpProgress(xpStr)
		if cur == nil or maxv == nil then
			statusBar:SetMinMaxValues(0, 100)
			statusBar:SetValue(0)
			statusBar.text:SetText("Experience: -")
			return
		end
		statusBar:SetMinMaxValues(0, maxv)
		statusBar:SetValue(cur)
		if label ~= nil and label ~= "" then
			statusBar.text:SetText(label)
		else
			statusBar.text:SetText(tostring(cur) .. " / " .. tostring(maxv))
		end
	end

	return bar
end

local function GetBotRoleText(bot)
	if bot.role == "tank" then
		return "Tank"
	end
	if bot.role == "heal" then
		return "Healer"
	end
	if bot.role ~= nil then
		return "Damage"
	end
	return "Role unknown"
end

local function GetClassForBot(bot)
	if bot.class ~= nil then
		return bot.class
	end
	return "Unknown"
end

local function OptionLabel(opts, value)
	if value == nil or value == "" then
		return "-"
	end
	for i = 1, table.getn(opts) do
		if opts[i].value == value then
			return opts[i].label
		end
	end
	-- Server echoes loot strategy reordered/deduped; match option `set` by
	-- canonical form so the dropdown reflects the actual server value.
	for i = 1, table.getn(opts) do
		if opts[i].set ~= nil then
			local v = CanonicalSet(value)
			if v ~= nil and CanonicalSet(opts[i].set) == v then
				return opts[i].label
			end
		end
	end
	return BpCapitalize(value)
end

-- Dropdown label for a loot strategy value (server echo or keyword).
function BotLootLabel(value)
	return OptionLabel(LOOT_OPTS, value)
end

local function CreateSectionHeader(parent, text)
	local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	fs:SetText(text)
	fs:SetTextColor(1.0, 0.82, 0.0)
	fs:SetJustifyH("LEFT")
	return fs
end

local function CreateDivider(parent, width)
	-- 1px rule (not a 9-slice border atlas — those stretch badly).
	local tex = parent:CreateTexture(nil, "ARTWORK")
	tex:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
	tex:SetHeight(1)
	tex:SetWidth(width)
	tex:SetVertexColor(0.5, 0.5, 0.5, 0.7)
	return tex
end

-- Named dropdown (required on 1.12/TBC/WotLK). opts = { {value=, label=}, ... }
local function CreateSettingDropdown(parent, label, opts, onSelect)
	local title = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	title:SetText(label)
	title:SetWidth(BP_LABEL_W)
	title:SetJustifyH("LEFT")

	BP_DROPDOWN_SEQ = BP_DROPDOWN_SEQ + 1
	local ddName = "MangosbotDD" .. BP_DROPDOWN_SEQ
	local dd = CreateFrame("Frame", ddName, parent, "UIDropDownMenuTemplate")
	MB_DropDownSetWidth(dd, 160)

	local currentValue = nil

	local function DisplayFor(val)
		return OptionLabel(opts, val)
	end

	local function RefreshMenu()
		if not UIDropDownMenu_Initialize then
			return
		end
		UIDropDownMenu_Initialize(dd, function()
			for oi = 1, table.getn(opts) do
				local opt = opts[oi]
				local info = {}
				info.text = opt.label
				info.value = opt.value
				info.checked = (opt.value == currentValue)
				info.func = function()
					currentValue = opt.value
					if UIDropDownMenu_SetSelectedValue then
						UIDropDownMenu_SetSelectedValue(dd, currentValue)
					end
					local textFS = getglobal(ddName .. "Text")
					if textFS ~= nil and textFS.SetText then
						textFS:SetText(opt.label)
					end
					if onSelect ~= nil then
						onSelect(currentValue)
					end
				end
				UIDropDownMenu_AddButton(info)
			end
		end)
	end

	RefreshMenu()

	local function SetValue(val)
		currentValue = val
		if UIDropDownMenu_SetSelectedValue then
			UIDropDownMenu_SetSelectedValue(dd, val or "")
		end
		local textFS = getglobal(ddName .. "Text")
		if textFS ~= nil and textFS.SetText then
			textFS:SetText(DisplayFor(val))
		end
	end

	return dd, title, SetValue
end

local function CreateToggleCheckbox(parent, label, token, strategyName, engines)
	BP_DROPDOWN_SEQ = BP_DROPDOWN_SEQ + 1
	local name = "MangosbotCB" .. BP_DROPDOWN_SEQ
	local cb = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
	if cb.SetWidth then
		cb:SetWidth(24)
		cb:SetHeight(24)
	end
	local textFS = getglobal(name .. "Text")
	if textFS == nil then
		textFS = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		textFS:SetPoint("LEFT", cb, "RIGHT", 2, 1)
	end
	textFS:SetText(label)
	cb.text = textFS
	cb.token = token
	cb.strategyName = strategyName
	cb.engines = engines

	cb:SetScript("OnClick", function()
		local self = this
		local on = false
		if self.GetChecked then
			on = self:GetChecked() and true or false
		end
		SendStrategyToggle(self.strategyName, on, self.engines)
	end)

	return cb
end

local function UpdateBotPanelScrollRange(frame)
	local scroll = frame.scroll
	local content = frame.content
	local bar = frame.scrollbar
	if scroll == nil or content == nil then
		return
	end
	if scroll.UpdateScrollChildRect then
		scroll:UpdateScrollChildRect()
	end
	if bar == nil then
		return
	end
	local viewH = 0
	local contentH = frame.contentHeight or 0
	if scroll.GetHeight then
		viewH = scroll:GetHeight() or 0
	end
	if content.GetHeight then
		local ch = content:GetHeight()
		if ch and ch > contentH then
			contentH = ch
		end
	end
	local range = contentH - viewH
	if range < 0 then
		range = 0
	end
	if bar.SetMinMaxValues then
		bar:SetMinMaxValues(0, range)
	end
	if bar.SetValueStep then
		bar:SetValueStep(1)
	end
	local cur = 0
	if bar.GetValue then
		cur = bar:GetValue() or 0
	end
	if cur > range then
		cur = range
	end
	if cur < 0 then
		cur = 0
	end
	if bar.SetValue then
		bar:SetValue(cur)
	end
	if range <= 0 then
		bar:Hide()
		if scroll.SetVerticalScroll then
			scroll:SetVerticalScroll(0)
		end
	else
		bar:Show()
	end
end

local function LayoutContentHeight(frame)
	local content = frame.content
	if content == nil then
		return
	end
	local h = frame.contentHeight or 100
	if h < 100 then
		h = 100
	end
	content:SetHeight(h)
	UpdateBotPanelScrollRange(frame)
end

local function ScrollBotPanelBy(scroll, delta)
	if scroll == nil then
		return
	end
	local bar = nil
	if scroll.GetName then
		bar = getglobal(scroll:GetName() .. "ScrollBar")
	end
	local maxScroll = 0
	local cur = 0
	if bar and bar.GetMinMaxValues then
		local _, maxV = bar:GetMinMaxValues()
		if maxV ~= nil then
			maxScroll = maxV
		end
		if bar.GetValue then
			cur = bar:GetValue() or 0
		end
		local nextScroll = cur + delta
		if nextScroll < 0 then
			nextScroll = 0
		end
		if nextScroll > maxScroll then
			nextScroll = maxScroll
		end
		bar:SetValue(nextScroll)
		return
	end
	if scroll.GetVerticalScrollRange then
		maxScroll = scroll:GetVerticalScrollRange() or 0
	end
	if scroll.GetVerticalScroll then
		cur = scroll:GetVerticalScroll() or 0
	end
	local nextScroll = cur + delta
	if nextScroll < 0 then
		nextScroll = 0
	end
	if nextScroll > maxScroll then
		nextScroll = maxScroll
	end
	if scroll.SetVerticalScroll then
		scroll:SetVerticalScroll(nextScroll)
	end
end

local function PlaceDropdownRow(content, y, label, opts, cmdPrefix)
	local row = CreateFrame("Frame", nil, content)
	row:SetWidth(BP_CONTENT_W)
	row:SetHeight(BP_ROW_H)
	row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
	local dd, title, setter = CreateSettingDropdown(row, label, opts, function(v)
		SendToCurrentBot(cmdPrefix .. v)
	end)
	title:SetPoint("LEFT", row, "LEFT", 0, 0)
	dd:SetPoint("LEFT", row, "LEFT", BP_LABEL_W - 12, -2)
	return setter, y + BP_ROW_H
end

local function PlaceCheckboxGrid(content, y, items, store)
	local col = 0
	local rowY = y
	for i = 1, table.getn(items) do
		local t = items[i]
		local cb = CreateToggleCheckbox(content, t.label, t.token, t.name or t.token, t.engines)
		local x = 0
		if col == 1 then
			x = BP_COL2_X
		end
		cb:SetPoint("TOPLEFT", content, "TOPLEFT", x, -rowY)
		store[t.token] = cb
		col = col + 1
		if col > 1 then
			col = 0
			rowY = rowY + BP_CHECK_H
		end
	end
	if col == 1 then
		rowY = rowY + BP_CHECK_H
	end
	return rowY
end

function CreateBotPanel()
	local frame = CreateFrame("Frame", "MangosbotBotFrame", UIParent)
	frame:Hide()
	frame:SetWidth(BP_WIDTH)
	frame:SetHeight(BP_HEIGHT)
	frame:SetPoint("CENTER", UIParent, "CENTER")
	frame:SetFrameStrata("MEDIUM")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function()
		this:StartMoving()
	end)
	frame:SetScript("OnDragStop", function()
		this:StopMovingOrSizing()
	end)

	-- Opaque panel (dialog bg alone is often see-through on custom UIs)
	frame:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 32,
		insets = { left = 11, right = 12, top = 12, bottom = 11 },
	})
	frame:SetBackdropColor(0.05, 0.05, 0.08, 1.0)
	frame:SetBackdropBorderColor(0.8, 0.8, 0.8, 1.0)
	local solidBg = frame:CreateTexture(nil, "BACKGROUND")
	solidBg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
	solidBg:SetVertexColor(0.05, 0.05, 0.08, 1.0)
	solidBg:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -12)
	solidBg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 12)

	-- Title bar (dialog header style)
	local titleBg = frame:CreateTexture(nil, "ARTWORK")
	titleBg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
	titleBg:SetWidth(300)
	titleBg:SetHeight(64)
	titleBg:SetPoint("TOP", frame, "TOP", 0, 12)
	frame.titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frame.titleText:SetPoint("TOP", titleBg, "TOP", 0, -14)
	frame.titleText:SetText("Bot")

	local close = CreateFrame("Button", "MangosbotBotFrameClose", frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
	close:SetScript("OnClick", function()
		HideBotPanel()
	end)

	-- Summary header
	local header = CreateFrame("Frame", nil, frame)
	header:SetPoint("TOPLEFT", frame, "TOPLEFT", BP_PAD, -BP_TOP_CHROME)
	header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -BP_PAD, -BP_TOP_CHROME)
	header:SetHeight(BP_HEADER_H)
	frame.header = header

	local portrait = CreateFrame("Frame", nil, header)
	portrait:SetWidth(64)
	portrait:SetHeight(64)
	portrait:SetPoint("TOPLEFT", header, "TOPLEFT", 4, -2)
	portrait.texture = portrait:CreateTexture(nil, "ARTWORK")
	portrait.texture:SetWidth(60)
	portrait.texture:SetHeight(60)
	portrait.texture:SetPoint("CENTER", portrait, "CENTER", 0, 0)
	portrait.texture:SetTexture("Interface\\CharacterFrame\\TempPortrait")
	if portrait.SetBackdrop then
		portrait:SetBackdrop({
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			edgeSize = 12,
			insets = { left = 2, right = 2, top = 2, bottom = 2 },
		})
		portrait:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
	end
	frame.portrait = portrait

	frame.nameText = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frame.nameText:SetPoint("TOPLEFT", portrait, "TOPRIGHT", 12, -4)
	frame.nameText:SetPoint("TOPRIGHT", header, "TOPRIGHT", -4, -4)
	frame.nameText:SetJustifyH("LEFT")
	frame.nameText:SetText("Bot")

	frame.subText = header:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	frame.subText:SetPoint("TOPLEFT", frame.nameText, "BOTTOMLEFT", 0, -4)
	frame.subText:SetPoint("TOPRIGHT", header, "TOPRIGHT", -4, -4)
	frame.subText:SetJustifyH("LEFT")
	frame.subText:SetText("-")

	frame.moneyDisplay = CreateMoneyDisplay(header)
	frame.moneyDisplay:SetPoint("TOPLEFT", frame.subText, "BOTTOMLEFT", 0, -6)

	-- Keep legacy fields for any external refs
	frame.classText = frame.subText
	frame.roleText = frame.subText
	frame.statsText = frame.subText

	-- Experience bar under header, above scroll body
	frame.xpBar = CreateXpBar(frame)
	frame.xpBar:SetPoint("TOPLEFT", frame, "TOPLEFT", BP_PAD + 4, -(BP_TOP_CHROME + BP_HEADER_H + 6))
	frame.xpBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -(BP_PAD + 20), -(BP_TOP_CHROME + BP_HEADER_H + 6))
	frame.xpBar:SetXp(nil)

	-- Scroll body + Blizzard scrollbar (UIPanelScrollBarTemplate)
	local scroll = CreateFrame("ScrollFrame", "MangosbotBotFrameScroll", frame)
	scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", BP_PAD, -BpScrollTopOffset())
	scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -36, 18)
	frame.scroll = scroll

	local scrollbar = CreateFrame("Slider", "MangosbotBotFrameScrollScrollBar", scroll, "UIPanelScrollBarTemplate")
	scrollbar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 6, -16)
	scrollbar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 6, 16)
	scrollbar:SetMinMaxValues(0, 0)
	scrollbar:SetValueStep(28)
	scrollbar:SetValue(0)
	-- Track fill behind thumb (template has no opaque trough on all clients)
	local track = scrollbar:CreateTexture(nil, "BACKGROUND")
	track:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
	track:SetVertexColor(0.08, 0.08, 0.1, 0.95)
	track:SetPoint("TOPLEFT", scrollbar, "TOPLEFT", 0, -2)
	track:SetPoint("BOTTOMRIGHT", scrollbar, "BOTTOMRIGHT", 0, 2)
	scrollbar.track = track
	scrollbar:SetScript("OnValueChanged", function()
		local self = this
		local parent = self:GetParent()
		local value = 0
		if self.GetValue then
			value = self:GetValue() or 0
		end
		if parent and parent.SetVerticalScroll then
			local cur = 0
			if parent.GetVerticalScroll then
				cur = parent:GetVerticalScroll() or 0
			end
			if cur ~= value then
				parent:SetVerticalScroll(value)
			end
		end
	end)
	frame.scrollbar = scrollbar

	scroll:EnableMouseWheel(true)
	scroll:SetScript("OnMouseWheel", function()
		local delta = 28
		if arg1 and arg1 > 0 then
			delta = -28
		end
		ScrollBotPanelBy(this, delta)
	end)
	scroll:SetScript("OnVerticalScroll", function()
		local offset = arg1 or 0
		local bar = getglobal(this:GetName() .. "ScrollBar")
		if bar and bar.GetValue and bar.SetValue then
			if (bar:GetValue() or 0) ~= offset then
				bar:SetValue(offset)
			end
		end
	end)
	scroll:SetScript("OnScrollRangeChanged", function()
		local f = this:GetParent()
		if f then
			UpdateBotPanelScrollRange(f)
		end
	end)
	scroll:SetScript("OnSizeChanged", function()
		local f = this:GetParent()
		if f then
			UpdateBotPanelScrollRange(f)
		end
	end)

	local content = CreateFrame("Frame", "MangosbotBotFrameContent", scroll)
	content:SetWidth(BP_CONTENT_W)
	content:SetHeight(400)
	scroll:SetScrollChild(content)
	frame.content = content

	local y = 4

	-- Movement
	local hMove = CreateSectionHeader(content, "Movement")
	hMove:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
	y = y + 18
	local div1 = CreateDivider(content, BP_CONTENT_W)
	div1:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
	y = y + 10

	frame.setters = {}
	local setter
	setter, y = PlaceDropdownRow(content, y, "Formation", FORMATION_OPTS, "formation ")
	frame.setters.formation = setter
	setter, y = PlaceDropdownRow(content, y, "Stance", STANCE_OPTS, "stance ")
	frame.setters.stance = setter
	y = y + BP_SECTION_GAP

	-- Looting
	local hLoot = CreateSectionHeader(content, "Looting")
	hLoot:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
	y = y + 18
	local div2 = CreateDivider(content, BP_CONTENT_W)
	div2:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
	y = y + 10

	setter, y = PlaceDropdownRow(content, y, "Loot filter", LOOT_OPTS, "ll ")
	frame.setters.loot = setter
	setter, y = PlaceDropdownRow(content, y, "Save mana", SAVEMANA_OPTS, "save mana ")
	frame.setters.savemana = setter
	y = y + BP_SECTION_GAP

	-- Targeting marks
	local hMark = CreateSectionHeader(content, "Target marks")
	hMark:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
	y = y + 18
	local div3 = CreateDivider(content, BP_CONTENT_W)
	div3:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
	y = y + 10

	setter, y = PlaceDropdownRow(content, y, "Attack mark", MARK_OPTS, "rti ")
	frame.setters.rti = setter
	setter, y = PlaceDropdownRow(content, y, "Crowd control", MARK_OPTS, "rti cc ")
	frame.setters.rti_cc = setter
	y = y + BP_SECTION_GAP

	-- Behavior
	frame.checkboxes = {}
	for gi = 1, table.getn(BEHAVIOR_GROUPS) do
		local g = BEHAVIOR_GROUPS[gi]
		local hs = CreateSectionHeader(content, g.title)
		hs:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
		y = y + 18
		local dg = CreateDivider(content, BP_CONTENT_W)
		dg:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
		y = y + 8
		y = PlaceCheckboxGrid(content, y, g.items, frame.checkboxes)
		y = y + BP_SECTION_GAP
	end

	-- Class section (filled on refresh)
	frame.classHeader = CreateSectionHeader(content, "Class")
	frame.classHeader:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
	frame.classHeader:Hide()
	frame.classDivider = CreateDivider(content, BP_CONTENT_W)
	frame.classDivider:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(y + 18))
	frame.classDivider:Hide()
	frame.classSectionY = y
	frame.classCheckboxes = {}
	frame.currentClass = nil
	frame.contentHeight = y + 8
	LayoutContentHeight(frame)

	if UIPanelWindows ~= nil then
		UIPanelWindows["MangosbotBotFrame"] = { area = "left", pushable = 3, whileDead = 1 }
	end

	frame:SetScript("OnShow", function()
		if CurrentBot == nil then
			if HideUIPanel then
				HideUIPanel(this)
			else
				this:Hide()
			end
		else
			RefreshBotPanel()
		end
	end)

	return frame
end

-- Open the panel for known bots or group members; never self, enemies, or NPCs.
function IsBotPanelTarget()
	local name = MB_UnitName("target")
	if name == nil then
		return false
	end
	local selfName = MB_UnitName("player")
	if name == selfName then
		return false
	end
	if not UnitExists("target") then
		return false
	end
	if UnitIsEnemy("target", "player") then
		return false
	end
	if not UnitIsPlayer("target") then
		return false
	end
	if botTable[name] ~= nil then
		return true
	end
	if UnitInParty("target") or UnitInRaid("target") then
		return true
	end
	return false
end

function ShowBotPanelFor(name)
	if name == nil or name == "" then
		return
	end
	CurrentBot = name
	QueryBotPanelState(name)
	local f = MangosbotBotFrame
	if f == nil then
		return
	end
	if ShowUIPanel then
		ShowUIPanel(f)
	else
		f:Show()
	end
	RefreshBotPanel()
end

function HideBotPanel()
	CurrentBot = nil
	local f = MangosbotBotFrame
	if f == nil then
		return
	end
	if HideUIPanel then
		HideUIPanel(f)
	else
		f:Hide()
	end
end

local function RebuildClassSection(f, clsKey)
	for _, box in pairs(f.classCheckboxes) do
		box:Hide()
	end
	f.classCheckboxes = {}
	f.currentClass = clsKey

	local classList = CLASS_STRATEGIES[clsKey]
	local y = f.classSectionY
	if classList == nil or table.getn(classList) == 0 then
		f.classHeader:Hide()
		f.classDivider:Hide()
		f.contentHeight = y + 8
		LayoutContentHeight(f)
		return
	end

	f.classHeader:Show()
	if f.classHeader.ClearAllPoints then
		f.classHeader:ClearAllPoints()
	end
	f.classHeader:SetPoint("TOPLEFT", f.content, "TOPLEFT", 0, -y)
	y = y + 18
	f.classDivider:Show()
	if f.classDivider.ClearAllPoints then
		f.classDivider:ClearAllPoints()
	end
	f.classDivider:SetPoint("TOPLEFT", f.content, "TOPLEFT", 0, -y)
	y = y + 8
	y = PlaceCheckboxGrid(f.content, y, classList, f.classCheckboxes)
	f.contentHeight = y + 12
	LayoutContentHeight(f)
end

-- Repaint the header, dropdowns, and checkboxes from botTable[CurrentBot].
function RefreshBotPanel()
	local f = MangosbotBotFrame
	if f == nil or f.portrait == nil or f.nameText == nil then
		return
	end
	if not f:IsVisible() then
		return
	end
	if CurrentBot == nil then
		f:Hide()
		return
	end
	local bot = botTable[CurrentBot]
	if bot == nil then
		bot = {}
	end

	local targetName = MB_UnitName("target")
	if targetName == CurrentBot and UnitExists("target") and SetPortraitTexture then
		SetPortraitTexture(f.portrait.texture, "target")
	else
		local cls = bot.class or "Unknown"
		local clsKey = string.lower(ClassToken(cls))
		f.portrait.texture:SetTexture("Interface\\Addons\\Mangosbot\\Images\\cls_" .. clsKey .. ".tga")
	end

	f.nameText:SetText(CurrentBot or "Bot")
	if f.titleText then
		f.titleText:SetText(CurrentBot or "Bot")
	end
	local cls = GetClassForBot(bot)
	local clsToken = ClassToken(cls)
	local color = RAID_CLASS_COLORS[clsToken]
	if color ~= nil then
		f.nameText:SetTextColor(color.r, color.g, color.b)
	else
		f.nameText:SetTextColor(1, 0.82, 0)
	end
	f.subText:SetText(cls .. " - " .. GetBotRoleText(bot))
	if f.moneyDisplay and f.moneyDisplay.SetCopper then
		f.moneyDisplay:SetCopper(ParseMoneyToCopper(bot.money))
	end
	if f.xpBar and f.xpBar.SetXp then
		f.xpBar:SetXp(bot.xp)
	end

	if f.setters ~= nil then
		if f.setters.formation then
			f.setters.formation(bot.formation)
		end
		if f.setters.stance then
			f.setters.stance(bot.stance)
		end
		if f.setters.loot then
			f.setters.loot(bot.loot)
		end
		if f.setters.savemana then
			f.setters.savemana(bot.savemana)
		end
		if f.setters.rti then
			f.setters.rti(bot.rti)
		end
		if f.setters.rti_cc then
			f.setters.rti_cc(bot.rti_cc)
		end
	end

	for _, box in pairs(f.checkboxes) do
		local on = false
		if BotHasStrategy then
			on = BotHasStrategy(bot, box.strategyName) and true or false
		end
		box:SetChecked(on)
	end

	local clsKey = string.upper(ClassToken(cls or ""))
	if f.currentClass ~= clsKey then
		RebuildClassSection(f, clsKey)
	end

	for _, box in pairs(f.classCheckboxes) do
		local on = false
		if BotHasStrategy then
			on = BotHasStrategy(bot, box.strategyName) and true or false
		end
		box:SetChecked(on)
	end
end

-- Roster window and More-menu dropdown

function CreateBotRoster()
	local frame = CreateFrame("Frame", "BotRoster", UIParent)
	frame:Hide()
	frame:SetWidth(186)
	frame:SetHeight(175)
	frame:SetPoint("CENTER", UIParent, "CENTER")
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetFrameStrata("DIALOG")
	frame:SetBackdropColor(0, 0, 0, 1.0)
	frame:SetBackdrop({
		bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
		tile = true,
		tileSize = 16,
		edgeSize = 0,
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
	})
	frame:SetBackdropBorderColor(0, 0, 0, 1)
	frame:RegisterForDrag("LeftButton")

	EnablePositionSaving(frame, "BotRoster")

	frame.items = {}
	-- Pre-build a fixed pool of item slots that RefreshBotRoster reuses.
	for i = 1, 10 do
		local item = CreateFrame("Frame", "BotRoster_Item" .. i, frame)
		item:SetPoint("TOPLEFT", frame, "TOPLEFT", i * 100, 0)
		item:SetWidth(112)
		item:SetHeight(40)
		item:SetBackdropColor(0, 0, 0, 1)
		item:SetBackdrop({
			bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
			edgeFile = "Interface/ChatFrame/ChatFrameBackground",
			tile = true,
			tileSize = 16,
			edgeSize = 2,
			insets = { left = 2, right = 2, top = 2, bottom = 0 },
		})
		item:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)

		item.text = item:CreateFontString("BotRoster_ItemHeader" .. i)
		item.text:SetPoint("TOPLEFT", item, "TOPLEFT", 20, 1)
		item.text:SetWidth(item:GetWidth())
		item.text:SetHeight(22)
		item.text:SetFont("Fonts/FRIZQT__.TTF", 11, "OUTLINE")
		item.text:SetJustifyH("LEFT")
		item.text:SetText("Click!")

		local cls = CreateFrame("Button", "BotRoster_ItemHeader" .. i .. "Image", item)
		cls:SetPoint("TOPLEFT", item, "TOPLEFT", 3, -3)
		cls:SetWidth(16)
		cls:SetHeight(16)
		cls:EnableMouse(true)
		cls:RegisterForClicks("LeftButtonDown")
		cls.texture = cls:CreateTexture(nil, "BACKGROUND")
		cls.texture:SetTexture("Interface\\Addons\\Mangosbot\\Images\\role_dps.tga")
		cls.texture:SetAllPoints()
		cls:SetScript("OnEnter", function(_self)
			GameTooltip:SetOwner(item, "ANCHOR_TOPLEFT", 0, -item:GetHeight() - 40)
			GameTooltip:SetText("Bot Control Panel")
			GameTooltip:Show()
		end)
		cls:SetScript("OnLeave", function(_self)
			GameTooltip:Hide()
		end)
		item.cls = cls

		CreateToolBar(item, -18, "quickbar" .. i, {
			["login"] = {
				icon = "login",
				command = { [0] = "" },
				strategy = "",
				tooltip = "Bring bot online",
				index = 0,
			},
			["logout"] = {
				icon = "logout",
				command = { [0] = "" },
				tooltip = "Logout bot",
				strategy = "",
				index = 0,
			},
			["invite"] = {
				icon = "invite",
				command = { [0] = "" },
				tooltip = "Invite to your group",
				strategy = "",
				index = 1,
			},
			["leave"] = {
				icon = "leave",
				command = { [0] = "" },
				tooltip = "Remove from group",
				strategy = "",
				index = 1,
			},
			["whisper"] = {
				icon = "whisper",
				command = { [0] = "" },
				tooltip = "Start whisper chat",
				strategy = "",
				index = 2,
			},
			["summon"] = {
				icon = "summon",
				command = { [0] = "" },
				tooltip = "Summon at meeting stone",
				strategy = "",
				index = 3,
			},
			["menu"] = {
				icon = "menu",
				command = { [0] = "" },
				tooltip = "More...",
				strategy = "",
				index = 4,
			},
		}, 20, 0, false)
		local tb = item.toolbar["quickbar" .. i]
		tb:SetBackdropBorderColor(0, 0, 0, 0.0)
		tb.buttons["login"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 0, 0)
		tb.buttons["logout"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 0, 0)
		tb.buttons["invite"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 16, 0)
		tb.buttons["leave"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 16, 0)
		tb.buttons["whisper"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 48, 0)
		tb.buttons["summon"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 32, 0)
		tb.buttons["menu"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 64, 0)

		item:Hide()
		item.rosterIndex = i
		frame.items[i] = item
		frame.ShowRequest = false
	end

	CreateToolBar(frame, 0, "quickbar", {
		["login_all"] = {
			icon = "login",
			command = { [0] = "" },
			strategy = "",
			tooltip = "Bring all bots online",
			index = 0,
		},
		["logout_all"] = {
			icon = "logout",
			command = { [0] = "" },
			tooltip = "Logout all bots",
			strategy = "",
			index = 1,
		},
		["invite_all"] = {
			icon = "invite",
			command = { [0] = "" },
			tooltip = "Invite all bots to your group",
			strategy = "",
			index = 2,
		},
		["leave_all"] = {
			icon = "leave",
			command = { [0] = "" },
			tooltip = "Remove all bots from group",
			strategy = "",
			index = 3,
		},
	}, 5, 0, false)
	frame.toolbar["quickbar"]:SetBackdropBorderColor(0, 0, 0, 0.0)

	GroupToolBars["group_movement"] = CreateMovementToolBar(frame, 0, "group_movement", true, 5, 0, false)
	frame.toolbar["group_movement"]:SetBackdropBorderColor(0, 0, 0, 0.0)

	GroupToolBars["group_formation"] = CreateFormationToolBar(frame, 0, "group_formation", true, 5, 0, false)
	frame.toolbar["group_formation"]:SetBackdropBorderColor(0, 0, 0, 0.0)

	GroupToolBars["group_savemana"] = CreateSaveManaToolBar(frame, 0, "group_savemana", true, 5, 0, false)
	frame.toolbar["group_savemana"]:SetBackdropBorderColor(0, 0, 0, 0.0)

	GroupToolBars["group_generic"] = CreateGenericNonCombatToolBar(frame, 0, "group_generic", true, 5, 0, false)
	frame.toolbar["group_generic"]:SetBackdropBorderColor(0, 0, 0, 0.0)

	GroupToolBars["group_generic_combat"] =
		CreateGenericCombatToolBar(frame, 0, "group_generic_combat", true, 5, 0, false)
	frame.toolbar["group_generic_combat"]:SetBackdropBorderColor(0, 0, 0, 0.0)

	return frame
end

local function SetRosterItemHandlers(item, key)
	local quickbar = item.toolbar["quickbar" .. item.rosterIndex]
	local loginBtn = quickbar.buttons["login"]
	local logoutBtn = quickbar.buttons["logout"]
	local inviteBtn = quickbar.buttons["invite"]
	local leaveBtn = quickbar.buttons["leave"]
	local whisperBtn = quickbar.buttons["whisper"]
	local summonBtn = quickbar.buttons["summon"]
	local menuBtn = quickbar.buttons["menu"]

	item.cls["key"] = key
	-- BotPanel (UIPanel) opens on target; roster click does not open it.

	loginBtn["key"] = key
	loginBtn:SetScript("OnClick", function()
		SendBotCommand(".bot add " .. loginBtn["key"], "SAY")
	end)
	logoutBtn["key"] = key
	logoutBtn:SetScript("OnClick", function()
		SendBotCommand(".bot rm " .. logoutBtn["key"], "SAY")
	end)
	inviteBtn["key"] = key
	inviteBtn:SetScript("OnClick", function()
		MB_Invite(inviteBtn["key"])
	end)
	leaveBtn["key"] = key
	leaveBtn:SetScript("OnClick", function()
		SendBotCommand("leave", "WHISPER", nil, leaveBtn["key"])
	end)
	whisperBtn["key"] = key
	whisperBtn:SetScript("OnClick", function()
		local editBox = MB_ChatEditBox()
		if editBox == nil then
			return
		end
		editBox:Show()
		editBox:SetFocus()
		editBox:SetText("/w " .. whisperBtn["key"] .. " ")
	end)
	summonBtn["key"] = key
	summonBtn:SetScript("OnClick", function()
		SendBotCommand("summon", "WHISPER", nil, summonBtn["key"])
	end)
	menuBtn["key"] = key
	menuBtn:SetScript("OnClick", function()
		OpenDropDownMenu(menuBtn["key"])
	end)
end

-- Show/hide per-bot buttons by state: offline -> login, online -> whisper/menu, in party -> leave.
local function ApplyRosterItemState(item, key, bot)
	local quickbar = item.toolbar["quickbar" .. item.rosterIndex]
	local loginBtn = quickbar.buttons["login"]
	local logoutBtn = quickbar.buttons["logout"]
	local inviteBtn = quickbar.buttons["invite"]
	local leaveBtn = quickbar.buttons["leave"]
	local whisperBtn = quickbar.buttons["whisper"]
	local summonBtn = quickbar.buttons["summon"]
	local menuBtn = quickbar.buttons["menu"]

	item.text:SetText(key)

	if bot["class"] ~= nil then
		local clsKey = string.lower(bot["class"])
		item.cls.texture:SetTexture("Interface\\Addons\\Mangosbot\\Images\\cls_" .. clsKey .. ".tga")
		local color = RAID_CLASS_COLORS[ClassToken(bot["class"])]
		if color ~= nil then
			item.text:SetTextColor(color.r, color.g, color.b, 1.0)
		end
	end

	loginBtn:Hide()
	logoutBtn:Hide()
	inviteBtn:Show()
	leaveBtn:Hide()
	whisperBtn:Hide()
	summonBtn:Hide()
	menuBtn:Hide()

	local inParty = false
	if bot["online"] then
		item:SetBackdropBorderColor(0.6, 0.6, 0.2, 1.0)
		logoutBtn:Show()
		whisperBtn:Show()
		summonBtn:Show()
		menuBtn:Show()
		if BotIsInParty(key) then
			inviteBtn:Hide()
			leaveBtn:Show()
			inParty = true
			item:SetBackdropBorderColor(0.2, 0.8, 0.8, 1.0)
		end
	else
		item:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
		loginBtn:Show()
		inviteBtn:Hide()
	end

	SetRosterItemHandlers(item, key)
	item:Show()
	return inParty, bot["online"] == true
end

-- Show a bulk action only when not everyone already matches its target state.
local function LayoutRosterBulkActions(y, allBots, flags)
	local tb = BotRoster.toolbar["quickbar"]
	tb:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", 5, -y)
	local x = 0

	local loginAllBtn = tb.buttons["login_all"]
	loginAllBtn:SetPoint("TOPLEFT", tb, "TOPLEFT", x, 0)
	if not flags.allLoggedIn then
		loginAllBtn:Show()
		x = x + 16
	else
		loginAllBtn:Hide()
	end
	loginAllBtn["allBots"] = allBots
	loginAllBtn:SetScript("OnClick", function()
		SendBotCommand(".bot add " .. loginAllBtn["allBots"], "SAY")
	end)

	local logoutAllBtn = tb.buttons["logout_all"]
	logoutAllBtn:SetPoint("TOPLEFT", tb, "TOPLEFT", x, 0)
	if not flags.allLoggedOut then
		logoutAllBtn:Show()
		x = x + 16
	else
		logoutAllBtn:Hide()
	end
	logoutAllBtn["allBots"] = allBots
	logoutAllBtn:SetScript("OnClick", function()
		SendBotCommand(".bot rm " .. logoutAllBtn["allBots"], "SAY")
	end)

	local inviteAllBtn = tb.buttons["invite_all"]
	inviteAllBtn:SetPoint("TOPLEFT", tb, "TOPLEFT", x, 0)
	if not flags.allInParty then
		inviteAllBtn:Show()
		x = x + 16
	else
		inviteAllBtn:Hide()
	end
	inviteAllBtn:SetScript("OnClick", function()
		local timeout = 0.1
		for key in pairs(botTable) do
			wait(timeout, function(botName)
				MB_Invite(botName)
			end, key)
			timeout = timeout + 0.1
		end
		wait(1, function()
			SendBotCommand(".bot list", "SAY")
		end)
	end)

	local leaveAllBtn = tb.buttons["leave_all"]
	leaveAllBtn:SetPoint("TOPLEFT", tb, "TOPLEFT", x, 0)
	if flags.anyInParty then
		leaveAllBtn:Show()
	else
		leaveAllBtn:Hide()
	end
	leaveAllBtn:SetScript("OnClick", function()
		local timeout = 0.1
		for key in pairs(botTable) do
			wait(timeout, function(botName)
				SendBotCommand("leave", "WHISPER", nil, botName)
			end, key)
			timeout = timeout + 0.1
		end
	end)
end

local GROUP_TOOLBAR_NAMES = {
	"group_formation",
	"group_movement",
	"group_savemana",
	"group_generic",
	"group_generic_combat",
}

local function LayoutRosterGroupToolBars(y, show)
	for i = 1, 5 do
		local tb = BotRoster.toolbar[GROUP_TOOLBAR_NAMES[i]]
		if show then
			tb:Show()
			y = y + 22
			tb:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", 5, -y)
		else
			tb:Hide()
		end
	end
	return y
end

-- Reflow the pooled item slots into a grid, then lay out bulk and group bars.
function RefreshBotRoster()
	if BotRoster.ShowRequest then
		BotRoster:Show()
		BotRoster.ShowRequest = false
	end

	for i = 1, 10 do
		BotRoster.items[i]:Hide()
	end

	local index = 1
	local x = 5
	local width = 0
	local height = 0
	local y = 5
	local colCount = 2
	local allBots = ""
	local first = true
	local flags = {
		allLoggedIn = true,
		allLoggedOut = true,
		allInParty = true,
		anyInParty = false,
	}

	for key, bot in pairs(botTable) do
		if index > 10 then
			index = 1
			y = 5
		end

		local item = BotRoster.items[index]
		if first then
			first = false
		else
			allBots = allBots .. ","
		end
		allBots = allBots .. key

		local inParty, online = ApplyRosterItemState(item, key, bot)
		if online then
			flags.allLoggedOut = false
			if inParty then
				flags.anyInParty = true
			else
				flags.allInParty = false
			end
		else
			flags.allLoggedIn = false
		end

		item:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", x, -y)
		index = index + 1
		x = x + (5 + item:GetWidth())
		height = item:GetHeight()
		if width < x then
			width = x
		end
		if fmod((index - 1), colCount) == 0 then
			y = y + (5 + height)
			x = 5
		end
	end

	if fmod((index - 1), colCount) ~= 0 then
		y = y + (5 + height)
	end
	if botCount() >= 10 then
		y = 230
	end

	LayoutRosterBulkActions(y, allBots, flags)
	y = LayoutRosterGroupToolBars(y, flags.anyInParty)
	UpdateGroupToolBar()
	if width < 186 then
		width = 186
	end
	BotRoster:SetWidth(width)
	BotRoster:SetHeight(y + 22)
end

-- Legacy dropdown builder used by the roster More... menu.
function createDropdown(opts)
	local dropdown_name = opts["name"] .. "_dropdown"
	local menu_items = opts["items"] or {}
	local title_text = opts["title"] or ""
	local dropdown_width = 0
	local default_val = opts["defaultVal"] or ""
	local change_func = opts["changeFunc"] or function() end
	local dropdown = CreateFrame("Frame", dropdown_name, opts["prnt"], "UIDropDownMenuTemplate")

	local dd_title = dropdown:CreateFontString(dropdown, "OVERLAY", "GameFontNormal")
	dd_title:SetPoint("TOPLEFT", 20, 10)

	for _, item in pairs(menu_items) do -- Sets the dropdown width to the largest item string width.
		dd_title:SetText(item)
		local text_width = dd_title:GetStringWidth() + 20
		if text_width > dropdown_width then
			dropdown_width = text_width
		end
	end

	dropdown:SetWidth(dropdown_width)
	local dropdownText = getglobal(dropdown:GetName() .. "Text")
	if dropdownText ~= nil then
		dropdownText:SetText(default_val)
	end
	dd_title:SetText(title_text)
	dd_title:Hide()
	dropdown:Hide()

	UIDropDownMenu_Initialize(dropdown, function(_self, _level, _)
		local info = {}
		for key, val in pairs(menu_items) do
			info.text = val .. "..."
			info.checked = false
			info.menuList = key
			info.hasArrow = false
			info.justifyH = "LEFT"
			info.func = change_func
			UIDropDownMenu_AddButton(info)
		end
	end, "MENU")

	return dropdown
end

local MenuForBot = nil
BotMenuItems = {
	[1] = "Accept quest",
	[2] = "Complete quest",
	[3] = "Choose quest reward [item]",
	[4] = "Fly to",
	[5] = "Bind to innkeeper",
	[6] = "Trainer [spell] learn",
	[7] = "Send me an [item]",
	[8] = "Toggle loot +/-[item]",
	[9] = "Toggle +/-[spell]",
	[10] = "Make me party leader",
}
BotMenuChatTable = {
	[1] = "accept *",
	[2] = "d talk to quest giver",
	[3] = "r ",
	[4] = "taxi ?",
	[5] = "home",
	[6] = "trainer learn",
	[7] = "sendmail ",
	[8] = "ll ",
	[9] = "ss ",
	[10] = "d leader",
}
function CreateDropDownMenu(parent)
	local opts = {
		["name"] = "more",
		["prnt"] = parent,
		["title"] = "More",
		["items"] = BotMenuItems,
		["defaultVal"] = "",
		["changeFunc"] = function()
			local editBox = MB_ChatEditBox()
			if editBox == nil then
				return
			end
			local id = this:GetID()
			editBox:Show()
			editBox:SetFocus()
			editBox:SetText("/w " .. MenuForBot .. " " .. BotMenuChatTable[id])
		end,
	}
	local menu = createDropdown(opts)
	HideDropDownMenu(1)
	return menu
end

function OpenDropDownMenuForCurrentBot()
	local name = MB_UnitName("target")
	if name == nil then
		name = CurrentBot
	end
	OpenDropDownMenu(name)
end

function OpenDropDownMenu(bot)
	local scale, x, y = BotRoster:GetEffectiveScale(), GetCursorPosition()
	DropDownMenu:SetPoint("CENTER", nil, "BOTTOMLEFT", x / scale, y / scale)
	MenuForBot = bot
	ToggleDropDownMenu(1, nil, DropDownMenu, "cursor")

end
