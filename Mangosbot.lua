local Mangosbot_EventFrame = CreateFrame("Frame")
Mangosbot_EventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
Mangosbot_EventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
Mangosbot_EventFrame:RegisterEvent("CHAT_MSG_WHISPER")
Mangosbot_EventFrame:RegisterEvent("CHAT_MSG_ADDON")
Mangosbot_EventFrame:RegisterEvent("CHAT_MSG_PARTY")
Mangosbot_EventFrame:RegisterEvent("CHAT_MSG_PARTY_LEADER")
Mangosbot_EventFrame:RegisterEvent("CHAT_MSG_RAID")
Mangosbot_EventFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
Mangosbot_EventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
Mangosbot_EventFrame:RegisterEvent("UPDATE")
Mangosbot_EventFrame:Hide()

local function IsGroupChatEvent(event)
	return event == "CHAT_MSG_PARTY"
		or event == "CHAT_MSG_PARTY_LEADER"
		or event == "CHAT_MSG_RAID"
		or event == "CHAT_MSG_RAID_LEADER"
end

local function IsBotChatEvent(event)
	return event == "CHAT_MSG_WHISPER"
		or event == "CHAT_MSG_ADDON"
		or IsGroupChatEvent(event)
end

local function HasPartyBots()
	for i = 1, partySize() do
		if botTable[partyName(i)] ~= nil then
			return true
		end
	end
	return false
end

local function ShouldHideBotControls()
	if CurrentBot ~= nil then
		return false
	end
	local name = GetUnitName("target")
	local selfName = GetUnitName("player")
	return name == nil
		or not UnitExists("target")
		or UnitIsEnemy("target", "player")
		or not UnitIsPlayer("target")
		or name == selfName
end

-- Periodic party stats requests (disabled for now; overlays that consumed them are off too).
local PARTY_STATS_LOOP_ENABLED = false

-- Real-time ticker (wait() is frame-based and unsuitable for multi-second intervals).
local partyStatsTicker = CreateFrame("Frame", "MangosbotPartyStatsTicker")
partyStatsTicker:Hide()
partyStatsTicker.elapsed = 0
partyStatsTicker:SetScript("OnUpdate", function()
	if not PARTY_STATS_LOOP_ENABLED then
		partyStatsTicker:Hide()
		partyStatsTicker.elapsed = 0
		return
	end
	local dt = arg1
	if dt == nil or dt <= 0 then
		dt = 0.05
	end
	partyStatsTicker.elapsed = partyStatsTicker.elapsed + dt
	if partyStatsTicker.elapsed < PARTY_STATS_MIN_INTERVAL then
		return
	end
	partyStatsTicker.elapsed = 0
	if HasPartyBots() then
		QueryBotPartyStats()
	else
		partyStatsTicker:Hide()
	end
end)

local function EnsurePartyStatsTicker()
	if not PARTY_STATS_LOOP_ENABLED then
		partyStatsTicker:Hide()
		partyStatsTicker.elapsed = 0
		return
	end
	if HasPartyBots() then
		partyStatsTicker:Show()
	else
		partyStatsTicker:Hide()
		partyStatsTicker.elapsed = 0
	end
end

local function RequestPartyBotStats()
	if not PARTY_STATS_LOOP_ENABLED then
		return
	end
	if not HasPartyBots() then
		EnsurePartyStatsTicker()
		return
	end
	QueryBotPartyStats()
	EnsurePartyStatsTicker()
end

-- Chat-frame filters hide protocol text but not floating bubbles (party/raid stats).
local function FontStringLooksLikeProtocol(text)
	if text == nil or text == "" then
		return false
	end
	if IsBotProtocolMessage(text) then
		return true
	end
	-- Bubble GetText() can differ slightly from the chat event payload.
	local plain = NormalizeMessage(text)
	if string.find(plain, "%d+/%d+ Bag") ~= nil then
		return true
	end
	if string.find(plain, "%%%) Dur") ~= nil then
		return true
	end
	if string.find(plain, " Pwr") ~= nil and string.find(plain, "g") ~= nil then
		return true
	end
	return false
end

local function FrameHasProtocolFontString(frame, depth)
	if frame == nil or depth > 3 then
		return false
	end
	if frame.GetRegions ~= nil then
		local ok, regions = pcall(function()
			return { frame:GetRegions() }
		end)
		if ok and regions ~= nil then
			for r = 1, table.getn(regions) do
				local region = regions[r]
				if region ~= nil and region.GetObjectType ~= nil and region:GetObjectType() == "FontString" then
					if FontStringLooksLikeProtocol(region:GetText()) then
						return true
					end
				end
			end
		end
	end
	if frame.GetChildren ~= nil then
		local ok, children = pcall(function()
			return { frame:GetChildren() }
		end)
		if ok and children ~= nil then
			for c = 1, table.getn(children) do
				if FrameHasProtocolFontString(children[c], depth + 1) then
					return true
				end
			end
		end
	end
	return false
end

local function HideMatchingChatBubbles()
	if WorldFrame == nil or WorldFrame.GetChildren == nil then
		return
	end
	local ok, children = pcall(function()
		return { WorldFrame:GetChildren() }
	end)
	if not ok or children == nil then
		return
	end
	for i = 1, table.getn(children) do
		local frame = children[i]
		if frame ~= nil and frame.IsVisible ~= nil and frame:IsVisible() then
			if FrameHasProtocolFontString(frame, 0) then
				frame:Hide()
			end
		end
	end
end

-- Scan continuously for a short real-time window; bubbles spawn after the chat event.
local bubbleScanFrame = CreateFrame("Frame", "MangosbotBubbleScan")
bubbleScanFrame:Hide()
bubbleScanFrame.remaining = 0
bubbleScanFrame:SetScript("OnUpdate", function()
	local dt = arg1
	if dt == nil or dt <= 0 then
		dt = 0.03
	end
	bubbleScanFrame.remaining = bubbleScanFrame.remaining - dt
	HideMatchingChatBubbles()
	if bubbleScanFrame.remaining <= 0 then
		bubbleScanFrame:Hide()
	end
end)

local function SuppressProtocolChatBubbles()
	-- Cover staggered multi-bot stats replies (0.5s apart, up to 5 bots).
	bubbleScanFrame.remaining = 4
	bubbleScanFrame:Show()
	HideMatchingChatBubbles()
end

local function QueueBotStateQuery(command, sender)
	wait(0.1, function()
		SendBotAddonCommand(command, "WHISPER", nil, sender)
	end)
end

local function HandleBotStatusMessage(message, sender)
	if string.find(message, "Hello") == 1 or string.find(message, "Goodbye") == 1 then
		SendBotCommand(".bot list", "SAY")
		QueryBotParty()
	end
	if
		string.find(message, "Following") == 1
		or string.find(message, "Staying") == 1
		or string.find(message, "Fleeing") == 1
	then
		QueueBotStateQuery("nc ?", sender)
	end
	if string.find(message, "Formation set to") == 1 then
		QueueBotStateQuery("formation ?", sender)
	end
	if string.find(message, "Stance set to") == 1 then
		QueueBotStateQuery("stance ?", sender)
	end
	if string.find(message, "Loot strategy set to ") == 1 then
		QueueBotStateQuery("ll ?", sender)
	end
	if string.find(message, "rti set to") == 1 then
		QueueBotStateQuery("rti ?", sender)
	end
	if string.find(message, "rti cc set to") == 1 then
		QueueBotStateQuery("rti cc ?", sender)
	end
	if string.find(message, "save mana") == 1 then
		QueueBotStateQuery("save mana ?", sender)
	end
end

function OnKeyBindingDown(button)
	if ShouldHideBotControls() then
		ClickGroupToolBarButton("group_movement", button)
	else
		ClickToolBarButton("movement", button)
	end
end

local function OnTargetChanged()
	if ShouldHideBotControls() then
		SelectedBotPanel:Hide()
		return
	end
	local name = GetUnitName("target")
	if CurrentBot ~= name then
		CurrentBot = nil
	end
	QuerySelectedBot(name)
end

local function OnSystemChat(message)
	if not OnSystemMessage(message) then
		return
	end
	if BotDebugPanel:IsVisible() then
		BotDebugLogMessage("sys", message, "SYSTEM")
	end
	RefreshBotRoster()
	RequestPartyBotStats()
end

local function OnBotChat(event, message, sender)
	-- Stats/strategy replies from grouped bots often arrive as party/raid chat
	-- (TellPlayer isPrivate=false). Ignore non-bot group chatter.
	if IsGroupChatEvent(event) then
		if botTable[sender] == nil and not IsBotProtocolMessage(message) then
			return
		end
		if IsBotProtocolMessage(message) then
			SuppressProtocolChatBubbles()
		end
	end

	OnWhisper(message, sender)
	UpdatePartyBotOverlays()

	if BotDebugPanel:IsVisible() then
		UpdateBotDebugPanel(message, sender)
	end

	if BotRoster:IsVisible() or SelectedBotPanel:IsVisible() then
		HandleBotStatusMessage(message, sender)
		UpdateGroupToolBar()
	end

	RefreshSelectedBotPanel(sender)
end

Mangosbot_EventFrame:SetScript("OnEvent", function()
	if event == "PLAYER_TARGET_CHANGED" then
		OnTargetChanged()
		return
	end

	if event == "CHAT_MSG_SYSTEM" then
		OnSystemChat(arg1)
		return
	end

	if event == "PARTY_MEMBERS_CHANGED" then
		UpdatePartyBotOverlays()
		RequestPartyBotStats()
		return
	end

	if IsBotChatEvent(event) then
		local message, sender = GetChatEventPayload(event, arg1, arg2, arg3, arg4)
		if message == nil or sender == nil then
			return
		end
		OnBotChat(event, message, sender)
	end
end)

SLASH_MANGOSBOT1 = "/bot"
function SlashCmdList.MANGOSBOT(msg)
	msg = trim2(msg or "")
	if msg == "" or msg == "roster" then
		if BotRoster == nil then
			print("Mangosbot: roster UI failed to load")
			return
		end
		if BotRoster:IsVisible() then
			BotRoster:Hide()
		else
			BotRoster.ShowRequest = true
			SendBotCommand(".bot list", "SAY")
			QueryBotParty()
		end
		return
	end
	if msg == "debug" then
		if BotDebugPanel == nil then
			print("Mangosbot: debug UI failed to load")
			return
		end
		if BotDebugPanel:IsVisible() then
			BotDebugPanel:Hide()
		else
			BotDebugPanel:Show()
			BotDebugLogMessage("sys", "Debug log started", nil)
		end
	end
end

print("MangosBOT Addon is loaded")
