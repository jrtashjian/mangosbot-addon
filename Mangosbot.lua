if CreateBotRoster == nil or CreateBotDebugPanel == nil or CreateDropDownMenu == nil then
	DEFAULT_CHAT_FRAME:AddMessage("Mangosbot: Mangosbot_UI.lua did not load")
	return
end

CurrentBot = nil
BotRoster = CreateBotRoster()
BotDebugPanel = CreateBotDebugPanel()
DropDownMenu = CreateDropDownMenu(BotRoster)

do
	local ok, result = pcall(CreateBotPanel)
	if ok and result ~= nil then
		MangosbotBotFrame = result
	else
		local err = result
		local frame = nil
		if getglobal ~= nil then
			frame = getglobal("MangosbotBotFrame")
		end
		if frame == nil then
			frame = CreateFrame("Frame", "MangosbotBotFrame", UIParent)
		end
		if frame ~= nil then
			MangosbotBotFrame = frame
			frame:Hide()
		end
		if err ~= nil then
			print("Mangosbot: BotPanel create failed: " .. tostring(err))
		end
	end
end

do
	local missing = {}
	if BotRoster == nil then
		table.insert(missing, "BotRoster")
	end
	if BotDebugPanel == nil then
		table.insert(missing, "BotDebugPanel")
	end
	if MangosbotBotFrame == nil then
		table.insert(missing, "MangosbotBotFrame")
	end
	if table.getn(missing) > 0 then
		print("Mangosbot: UI init incomplete (" .. table.concat(missing, ", ") .. ")")
	end
end

local Mangosbot_EventFrame = CreateFrame("Frame")
Mangosbot_EventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
Mangosbot_EventFrame:RegisterEvent("CHAT_MSG_WHISPER")
Mangosbot_EventFrame:RegisterEvent("CHAT_MSG_ADDON")
Mangosbot_EventFrame:RegisterEvent("CHAT_MSG_PARTY")
Mangosbot_EventFrame:RegisterEvent("CHAT_MSG_PARTY_LEADER")
Mangosbot_EventFrame:RegisterEvent("CHAT_MSG_RAID")
Mangosbot_EventFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
Mangosbot_EventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
Mangosbot_EventFrame:Hide()

local function IsGroupChatEvent(eventName)
	return eventName == "CHAT_MSG_PARTY"
		or eventName == "CHAT_MSG_PARTY_LEADER"
		or eventName == "CHAT_MSG_RAID"
		or eventName == "CHAT_MSG_RAID_LEADER"
end

local function IsBotChatEvent(eventName)
	return eventName == "CHAT_MSG_WHISPER"
		or eventName == "CHAT_MSG_ADDON"
		or IsGroupChatEvent(eventName)
end

local function ShouldHideBotControls()
	if CurrentBot ~= nil then
		return false
	end
	local name = MB_UnitName("target")
	local selfName = MB_UnitName("player")
	return name == nil
		or not UnitExists("target")
		or UnitIsEnemy("target", "player")
		or not UnitIsPlayer("target")
		or name == selfName
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
	local name = MB_UnitName("target")
	if IsBotPanelTarget and IsBotPanelTarget() then
		if ShowBotPanelFor then
			ShowBotPanelFor(name)
		end
	elseif HideBotPanel then
		HideBotPanel()
	end
end

local function OnSystemChat(message)
	if not OnSystemMessage(message) then
		return
	end
	if BotDebugPanel:IsVisible() then
		BotDebugLogMessage("sys", message, "SYSTEM")
	end
	RefreshBotRoster()
end

local function OnBotChat(eventName, message, sender)
	-- Strategy replies from grouped bots often arrive as party/raid chat
	-- (TellPlayer isPrivate=false). Ignore non-bot group chatter.
	if IsGroupChatEvent(eventName) then
		if botTable[sender] == nil and not IsBotProtocolMessage(message) then
			return
		end
	end

	local dirty = OnWhisper(message, sender)

	if BotDebugPanel:IsVisible() then
		UpdateBotDebugPanel(message, sender)
	end

	local rosterOpen = BotRoster:IsVisible()
	local panelOpen = MangosbotBotFrame and MangosbotBotFrame:IsVisible()
	if rosterOpen or panelOpen then
		HandleBotStatusMessage(message, sender)
		if dirty then
			UpdateGroupToolBar()
		end
	end

	if dirty and RefreshBotPanel and panelOpen then
		RefreshBotPanel()
	end
end

Mangosbot_EventFrame:SetScript("OnEvent", function(self, eventName, a1, a2, a3, a4)
	eventName, a1, a2, a3, a4 = MB_EventArgs(self, eventName, a1, a2, a3, a4)

	if eventName == "PLAYER_TARGET_CHANGED" then
		OnTargetChanged()
		return
	end

	if eventName == "CHAT_MSG_SYSTEM" then
		OnSystemChat(a1)
		return
	end

	if IsBotChatEvent(eventName) then
		local message, sender = GetChatEventPayload(eventName, a1, a2, a3, a4)
		if message == nil or sender == nil then
			return
		end
		OnBotChat(eventName, message, sender)
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
