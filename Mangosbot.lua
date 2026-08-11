local Mangosbot_EventFrame = CreateFrame("Frame")
Mangosbot_EventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
Mangosbot_EventFrame:RegisterEvent("CHAT_MSG_WHISPER")
Mangosbot_EventFrame:RegisterEvent("CHAT_MSG_ADDON")
Mangosbot_EventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
Mangosbot_EventFrame:RegisterEvent("UPDATE")
Mangosbot_EventFrame:Hide()

function OnKeyBindingDown(button)
	local name = GetUnitName("target")
	local self = GetUnitName("player")
	if
		CurrentBot == nil
		and (
			name == nil
			or not UnitExists("target")
			or UnitIsEnemy("target", "player")
			or not UnitIsPlayer("target")
			or name == self
		)
	then
		ClickGroupToolBarButton("group_movement", button)
	else
		ClickToolBarButton("movement", button)
	end
end

Mangosbot_EventFrame:SetScript("OnEvent", function()
	if event == "PLAYER_TARGET_CHANGED" then
		local name = GetUnitName("target")
		local self = GetUnitName("player")
		if
			CurrentBot == nil
			and (
				name == nil
				or not UnitExists("target")
				or UnitIsEnemy("target", "player")
				or not UnitIsPlayer("target")
				or name == self
			)
		then
			SelectedBotPanel:Hide()
		else
			if CurrentBot ~= name then
				CurrentBot = nil
			end
			QuerySelectedBot(name)
		end
	end

	if event == "CHAT_MSG_SYSTEM" then
		local message = arg1
		if OnSystemMessage(message) then
			if BotDebugPanel:IsVisible() then
				BotDebugLogMessage("sys", message, "SYSTEM")
			end
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
			local allBotsLoggedIn = true
			local allBotsLoggedOut = true
			local allBotsInParty = true
			local atLeastOneBotInParty = false
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

				item.text:SetText(key)
				item.cls["key"] = key
				item.cls:SetScript("OnClick", function()
					if CurrentBot == item.cls["key"] then
						CurrentBot = nil
						SelectedBotPanel:Hide()
					else
						CurrentBot = item.cls["key"]
						QuerySelectedBot(CurrentBot)
					end
				end)

				if bot["class"] ~= nil then
					local clsKey = string.lower(bot["class"])
					local filename = "Interface\\Addons\\Mangosbot\\Images\\cls_" .. clsKey .. ".tga"
					item.cls.texture:SetTexture(filename)

					local color = RAID_CLASS_COLORS[ClassToken(bot["class"])]
					if color ~= nil then
						item.text:SetTextColor(color.r, color.g, color.b, 1.0)
					end
				end

				item:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", x, -y)

				local loginBtn = item.toolbar["quickbar" .. index].buttons["login"]
				loginBtn:Hide()
				local logoutBtn = item.toolbar["quickbar" .. index].buttons["logout"]
				logoutBtn:Hide()
				local inviteBtn = item.toolbar["quickbar" .. index].buttons["invite"]
				inviteBtn:Show()
				local leaveBtn = item.toolbar["quickbar" .. index].buttons["leave"]
				leaveBtn:Hide()
				local whisperBtn = item.toolbar["quickbar" .. index].buttons["whisper"]
				whisperBtn:Hide()
				local summonBtn = item.toolbar["quickbar" .. index].buttons["summon"]
				summonBtn:Hide()
				local menuBtn = item.toolbar["quickbar" .. index].buttons["menu"]
				menuBtn:Hide()
				if bot["online"] then
					item:SetBackdropBorderColor(0.6, 0.6, 0.2, 1.0)
					logoutBtn:Show()
					whisperBtn:Show()
					summonBtn:Show()
					menuBtn:Show()
					local inParty = false
					for i = 1, 5 do
						if partyName(i) == key then
							inviteBtn:Hide()
							leaveBtn:Show()
							atLeastOneBotInParty = true
							inParty = true
							item:SetBackdropBorderColor(0.2, 0.8, 0.8, 1.0)
						end
					end
					if not inParty then
						allBotsInParty = false
					end
					allBotsLoggedOut = false
				else
					item:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
					loginBtn:Show()
					inviteBtn:Hide()
					allBotsLoggedIn = false
				end
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
					local editBox = getglobal("ChatFrameEditBox")
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

				item:Show()

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

			local tb = BotRoster.toolbar["quickbar"]
			tb:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", 5, -y)
			local loginAllBtn = tb.buttons["login_all"]
			x = 0
			loginAllBtn:SetPoint("TOPLEFT", tb, "TOPLEFT", x, 0)
			if not allBotsLoggedIn then
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
			if not allBotsLoggedOut then
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
			if not allBotsInParty then
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
			if atLeastOneBotInParty then
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

			local formationToolBar = BotRoster.toolbar["group_formation"]
			if atLeastOneBotInParty then
				formationToolBar:Show()
				y = y + 22
				formationToolBar:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", 5, -y)
			else
				formationToolBar:Hide()
			end

			local movementToolBar = BotRoster.toolbar["group_movement"]
			if atLeastOneBotInParty then
				movementToolBar:Show()
				y = y + 22
				movementToolBar:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", 5, -y)
			else
				movementToolBar:Hide()
			end

			local savemanaToolBar = BotRoster.toolbar["group_savemana"]
			if atLeastOneBotInParty then
				savemanaToolBar:Show()
				y = y + 22
				savemanaToolBar:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", 5, -y)
			else
				savemanaToolBar:Hide()
			end

			local genericToolBar = BotRoster.toolbar["group_generic"]
			if atLeastOneBotInParty then
				genericToolBar:Show()
				y = y + 22
				genericToolBar:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", 5, -y)
			else
				genericToolBar:Hide()
			end

			local genericCombatToolBar = BotRoster.toolbar["group_generic_combat"]
			if atLeastOneBotInParty then
				genericCombatToolBar:Show()
				y = y + 22
				genericCombatToolBar:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", 5, -y)
			else
				genericCombatToolBar:Hide()
			end

			UpdateGroupToolBar()
			BotRoster:SetWidth(width)
			BotRoster:SetHeight(y + 22)
		end
	end

	if event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_ADDON" then
		local message, sender = GetChatEventPayload(event, arg1, arg2, arg3, arg4)
		if message == nil or sender == nil then
			return
		end

		OnWhisper(message, sender)

		if BotDebugPanel:IsVisible() then
			UpdateBotDebugPanel(message, sender)
		end

		if BotRoster:IsVisible() or SelectedBotPanel:IsVisible() then
			if string.find(message, "Hello") == 1 or string.find(message, "Goodbye") == 1 then
				SendBotCommand(".bot list", "SAY")
				QueryBotParty()
			end
			if
				string.find(message, "Following") == 1
				or string.find(message, "Staying") == 1
				or string.find(message, "Fleeing") == 1
			then
				wait(0.1, function()
					SendBotAddonCommand("nc ?", "WHISPER", nil, sender)
				end)
			end
			if string.find(message, "Formation set to") == 1 then
				wait(0.1, function()
					SendBotAddonCommand("formation ?", "WHISPER", nil, sender)
				end)
			end
			if string.find(message, "Stance set to") == 1 then
				wait(0.1, function()
					SendBotAddonCommand("stance ?", "WHISPER", nil, sender)
				end)
			end
			if string.find(message, "Loot strategy set to ") == 1 then
				wait(0.1, function()
					SendBotAddonCommand("ll ?", "WHISPER", nil, sender)
				end)
			end
			if string.find(message, "rti set to") == 1 then
				wait(0.1, function()
					SendBotAddonCommand("rti ?", "WHISPER", nil, sender)
				end)
			end
			if string.find(message, "rti cc set to") == 1 then
				wait(0.1, function()
					SendBotAddonCommand("rti cc ?", "WHISPER", nil, sender)
				end)
			end
			if string.find(message, "save mana") == 1 then
				wait(0.1, function()
					SendBotAddonCommand("save mana ?", "WHISPER", nil, sender)
				end)
			end
			UpdateGroupToolBar()
		end

		local bot = botTable[sender]
		if bot == nil or bot["strategy"] == nil or bot["role"] == nil then
			SelectedBotPanel:Hide()
			return
		end
		local selected = GetUnitName("target")
		if CurrentBot ~= nil then
			selected = CurrentBot
		end
		if sender == selected then
			SelectedBotPanel:Show()

			local class = "UNKNOWN"
			if bot["class"] ~= nil then
				class = ClassToken(bot["class"])
			end
			if GetUnitName("target") ~= nil then
				local _, unitClass = UnitClass("target")
				if unitClass ~= nil then
					class = unitClass
				end
			end
			SetFrameColor(SelectedBotPanel, class)

			local filename = "Interface\\Addons\\Mangosbot\\Images\\role_" .. bot["role"] .. ".tga"
			SelectedBotPanel.header.role.texture:SetTexture(filename)
			SelectedBotPanel.header.text:SetText(sender)

			local width = 0
			local height = 0
			for toolbarName, toolbar in pairs(ToolBars) do
				local panelVisible = true
				if string.find(toolbarName, "CLASS_") == 1 then
					if string.find(string.sub(toolbarName, 7), class) == 1 then
						SelectedBotPanel.toolbar[toolbarName]:Show()
					else
						SelectedBotPanel.toolbar[toolbarName]:Hide()
						panelVisible = false
					end
				end
				local numButtons = 0
				for buttonName, button in pairs(toolbar) do
					local toggle = false
					if button["strategy"] ~= nil and bot["strategy"] ~= nil then
						local engines = { "nc", "co", "react", "dead" }
						for ei = 1, 4 do
							local elist = bot["strategy"][engines[ei]]
							if elist ~= nil then
								for _, strategy in pairs(elist) do
									if strategy == button["strategy"] then
										toggle = true
										break
									end
								end
							end
							if toggle then
								break
							end
						end
					end
					if
						button["formation"] ~= nil
						and bot["formation"] ~= nil
						and string.find(bot["formation"], button["formation"]) ~= nil
					then
						toggle = true
					end
					if
						button["stance"] ~= nil
						and bot["stance"] ~= nil
						and string.find(bot["stance"], button["stance"]) ~= nil
					then
						toggle = true
					end
					if button["rti"] ~= nil and bot["rti"] ~= nil and string.find(bot["rti"], button["rti"]) ~= nil then
						toggle = true
					end
					if
						button["rti_cc"] ~= nil
						and bot["rti_cc"] ~= nil
						and string.find(bot["rti_cc"], button["rti_cc"]) ~= nil
					then
						toggle = true
					end
					if
						button["loot"] ~= nil
						and bot["loot"] ~= nil
						and string.find(bot["loot"], button["loot"]) ~= nil
					then
						toggle = true
					end
					if
						button["savemana"] ~= nil
						and bot["savemana"] ~= nil
						and string.find(bot["savemana"], button["savemana"]) ~= nil
					then
						toggle = true
					end
					ToggleButton(SelectedBotPanel, toolbarName, buttonName, toggle)
					numButtons = numButtons + 1
				end
				if panelVisible then
					height = height + 1
					if width < numButtons then
						width = numButtons
					end
				end
			end
			ResizeBotPanel(SelectedBotPanel, width * 25 + 20, height * 25 + 25)
		end
	end
end)

SLASH_MANGOSBOT1 = "/bot"
function SlashCmdList.MANGOSBOT(msg) -- 4.
	if msg == "" or msg == "roster" then
		if BotRoster:IsVisible() then
			BotRoster:Hide()
		else
			BotRoster.ShowRequest = true
			SendBotCommand(".bot list", "SAY")
			QueryBotParty()
		end
	end
	if msg == "debug" then
		if BotDebugPanel:IsVisible() then
			BotDebugPanel:Hide()
		else
			BotDebugPanel:Show()
			BotDebugLogMessage("sys", "Debug log started", nil)
		end
	end
end

print("MangosBOT Addon is loaded")
