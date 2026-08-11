function ClickToolBarButton(toolbar, button)
	local btn = ToolBars[toolbar][button]
	ToolBarButtonOnClick(btn, false)
end

function ClickGroupToolBarButton(toolbar, button)
	local btn = GroupToolBars[toolbar][button]
	ToolBarButtonOnClick(btn, false)
end

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
		local delay = 0
		local combined = CombineBotCommands(btn["command"])
		wait(0, function(cmd)
			SendBotCommand(cmd, "PARTY")
		end, combined)
		if btn["tooltip"] ~= nil then
			wait(delay + 1, function(command)
				SendBotAddonCommand(command, "PARTY")
			end, btn["tooltip"])
		end
	else
		local bot = GetUnitName("target")
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

function ResizeBotPanel(frame, width, height)
	frame:SetWidth(width)
	frame:SetHeight(height)
	frame.header:SetWidth(frame:GetWidth())
	frame.header.text:SetWidth(frame.header:GetWidth())
	for toolbarName in pairs(ToolBars) do
		frame.toolbar[toolbarName]:SetWidth(frame:GetWidth() - 10)
	end
end

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

function StartChat()
	local editBox = getglobal("ChatFrameEditBox")
	editBox:Show()
	editBox:SetFocus()
	local name = GetUnitName("target")
	if name == nil then
		name = CurrentBot
	end
	editBox:SetText("/w " .. name .. " ")
end

function CreateSelectedBotPanel()
	local frame = CreateFrame("Frame", "SelectedBotPanel", UIParent)
	frame:Hide()
	frame:SetWidth(170)
	frame:SetHeight(155)
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

	frame.header = CreateFrame("Frame", "SelectedBotPanelHeader", frame)
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

	frame.header.text = frame.header:CreateFontString("SelectedBotPanelHeaderText")
	frame.header.text:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, 0)
	frame.header.text:SetWidth(frame.header:GetWidth())
	frame.header.text:SetHeight(22)
	frame.header.text:SetFont("Fonts/FRIZQT__.TTF", 11, "OUTLINE")
	frame.header.text:SetJustifyH("LEFT")
	frame.header.text:SetText("Click!")

	frame.header.role = CreateFrame("Frame", "SelectedBotPanelHeaderRole", frame.header)
	frame.header.role:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -3)
	frame.header.role:SetWidth(16)
	frame.header.role:SetHeight(16)
	frame.header.role.texture = frame.header.role:CreateTexture(nil, "BACKGROUND")
	frame.header.role.texture:SetTexture("Interface/Addons/Mangosbot/Images/role_dps.tga")
	frame.header.role.texture:SetAllPoints()

	EnablePositionSaving(frame, "SelectedBotPanel")

	local y = 25
	CreateMovementToolBar(frame, y, "movement", false, 5, 5, true)

	y = y + 25
	CreateToolBar(frame, -y, "actions", {
		["stats"] = {
			icon = "stats",
			command = { [0] = "stats" },
			strategy = "",
			tooltip = "Tell stats (XP, money, etc.)",
			index = 0,
		},
		["whisper"] = {
			icon = "whisper",
			command = { [0] = "" },
			tooltip = "Start whisper chat",
			strategy = "",
			handler = StartChat,
			index = 1,
		},
		["loot"] = {
			icon = "loot",
			command = { [0] = "d add all loot", [1] = "d loot" },
			strategy = "",
			tooltip = "Loot everything",
			index = 2,
		},
		["release"] = {
			icon = "release",
			command = { [0] = "release" },
			strategy = "",
			tooltip = "Release spirit",
			index = 3,
		},
		["revive"] = {
			icon = "revive",
			command = { [0] = "revive", [1] = "d revive from corpse" },
			strategy = "",
			tooltip = "Revive from corpse",
			index = 4,
		},
		["sell"] = {
			icon = "sell",
			command = { [0] = "s *" },
			strategy = "",
			tooltip = "Sell vendor trash",
			index = 5,
		},
		["talk"] = {
			icon = "talk",
			command = { [0] = "accept *" },
			strategy = "",
			tooltip = "Accept all quests",
			index = 6,
		},
		["menu"] = {
			icon = "menu",
			command = { [0] = "" },
			strategy = "",
			tooltip = "More...",
			handler = OpenDropDownMenuForCurrentBot,
			index = 7,
		},
	})

	y = y + 25
	CreateToolBar(frame, -y, "inventory", {
		["los"] = {
			icon = "los",
			command = { [0] = "los gos" },
			strategy = "",
			tooltip = "Show nearby game objects",
			index = 0,
		},
		["count"] = {
			icon = "count",
			command = { [0] = "c" },
			strategy = "",
			tooltip = "Show inventory",
			index = 1,
		},
		["bank"] = {
			icon = "bank",
			command = { [0] = "bank" },
			strategy = "",
			tooltip = "Show bank",
			index = 2,
		},
		["spells"] = {
			icon = "spells",
			command = { [0] = "spells +" },
			strategy = "",
			tooltip = "Show crafting",
			index = 3,
		},
		["equip"] = {
			icon = "equip",
			command = { [0] = "e ?" },
			strategy = "",
			tooltip = "Show equipment",
			index = 4,
		},
		["mail"] = {
			icon = "mail",
			command = { [0] = "mail ?" },
			strategy = "",
			tooltip = "Show mail",
			index = 5,
		},
	})

	y = y + 25
	CreateFormationToolBar(frame, y, "formation", false, 5, 5, true)

	y = y + 25
	CreateStanceToolBar(frame, y, "stance", false, 5, 5, true)

	y = y + 25
	CreateSaveManaToolBar(frame, y, "savemana", false, 5, 5, true)

	y = y + 25
	CreateToolBar(frame, -y, "loot", {
		["ll_normal"] = {
			icon = "ll_normal",
			command = { [0] = "ll normal" },
			loot = "normal",
			tooltip = "Loot tradeskill items only",
			index = 0,
		},
		["ll_gray"] = {
			icon = "ll_gray",
			command = { [0] = "ll gray" },
			loot = "gray",
			tooltip = "Loot gray items",
			index = 1,
		},
		["ll_disenchant"] = {
			icon = "ll_disenchant",
			command = { [0] = "ll disenchant" },
			loot = "disenchant",
			tooltip = "Loot BoE items for disenchanting",
			index = 2,
		},
		["ll_all"] = {
			icon = "ll_all",
			command = { [0] = "ll all" },
			loot = "all",
			tooltip = "Loot everything",
			index = 3,
		},
		["reveal"] = {
			icon = "stats",
			command = { [0] = "nc ~reveal,?" },
			strategy = "reveal",
			tooltip = "Reveal gathering nodes",
			index = 4,
		},
	})

	y = y + 25
	CreateToolBar(frame, -y, "attack_type", {
		["tank_aoe"] = {
			icon = "tank_aoe",
			command = { [0] = "nc +tank aoe,?", [1] = "co +tank aoe,?" },
			strategy = "tank aoe",
			tooltip = "Grab all aggro",
			index = 0,
		},
		["dps_assist"] = {
			icon = "dps_assist",
			command = { [0] = "nc +dps assist,?", [1] = "co +dps assist,?" },
			strategy = "dps assist",
			tooltip = "Assist others",
			index = 1,
		},
		["defense"] = {
			icon = "tank_assist",
			command = { [0] = "nc +defense,?", [1] = "co +defense,?" },
			strategy = "defense",
			tooltip = "Defensive",
			index = 2,
		},
		["grind"] = {
			icon = "grind",
			command = { [0] = "nc +grind,?" },
			strategy = "grind",
			tooltip = "Aggressive mode (grinding)",
			index = 3,
		},
		["close"] = {
			icon = "close",
			command = { [0] = "co ~close,?" },
			strategy = "close",
			tooltip = "Melee combat",
			index = 4,
		},
		["ranged"] = {
			icon = "ranged",
			command = { [0] = "co ~ranged,?" },
			strategy = "ranged",
			tooltip = "Ranged combat",
			index = 5,
		},
		["threat"] = {
			icon = "threat",
			command = { [0] = "co ~threat,?" },
			strategy = "threat",
			tooltip = "Keep threat level low",
			index = 6,
		},
	})

	y = y + 25
	CreateRtiToolBar(frame, y, "rti", false, 5, 5, true)

	y = y + 25
	CreateRtiCcToolBar(frame, y, "rti cc", false, 5, 5, true)

	y = y + 25
	CreateGenericNonCombatToolBar(frame, y, "generic", false, 5, 5, true)

	y = y + 25
	CreateGenericCombatToolBar(frame, y, "generic_combat", false, 5, 5, true)

	y = y + 25
	CreateToolBar(frame, -y, "CLASS_DRUID", {
		["bear"] = {
			icon = "bear",
			command = { [0] = "co +bear,?" },
			strategy = "bear",
			tooltip = "Use bear form",
			index = 0,
		},
		["cat"] = {
			icon = "cat",
			command = { [0] = "co +cat,?" },
			strategy = "cat",
			tooltip = "Use cat form",
			index = 1,
		},
		["caster"] = {
			icon = "caster",
			command = { [0] = "co +caster,?" },
			strategy = "caster",
			tooltip = "Use caster form",
			index = 2,
		},
		["heal"] = {
			icon = "heal",
			command = { [0] = "co +heal,?" },
			strategy = "heal",
			tooltip = "Healer mode",
			index = 3,
		},
		["cure"] = {
			icon = "cure",
			command = { [0] = "co ~cure,?", [1] = "nc ~cure,?" },
			strategy = "cure",
			tooltip = "Cure (poison, disease, etc.)",
			index = 4,
		},
		["melee"] = {
			icon = "dps",
			command = { [0] = "co ~melee,?" },
			strategy = "melee",
			tooltip = "Melee mode",
			index = 5,
		},
	})
	CreateToolBar(frame, -y, "CLASS_HUNTER", {
		["dps"] = {
			icon = "dps",
			command = { [0] = "co +dps,?" },
			strategy = "dps",
			tooltip = "DPS mode",
			index = 0,
		},
		["aoe"] = {
			icon = "aoe",
			command = { [0] = "co ~aoe,?" },
			strategy = "aoe",
			tooltip = "Use AOE abilities",
			index = 1,
		},
		["bspeed"] = {
			icon = "bspeed",
			command = { [0] = "co ~bspeed,?", [1] = "nc ~bspeed,?" },
			strategy = "bspeed",
			tooltip = "Buff movement speed",
			index = 2,
		},
		["bdps"] = {
			icon = "bdps",
			command = { [0] = "co ~bdps,?", [1] = "nc ~bdps,?" },
			strategy = "bdps",
			tooltip = "Buff DPS",
			index = 3,
		},
		["rnature"] = {
			icon = "bmana",
			command = { [0] = "co ~rnature,?", [1] = "nc ~rnature,?" },
			strategy = "rnature",
			tooltip = "Provide nature resistance",
			index = 4,
		},
		["pet"] = {
			icon = "pet",
			command = { [0] = "co ~pet,?", [1] = "nc ~pet,?" },
			strategy = "pet",
			tooltip = "Use pet",
			index = 5,
		},
	})
	CreateToolBar(frame, -y, "CLASS_MAGE", {
		["arcane"] = {
			icon = "arcane",
			command = { [0] = "co +arcane,?" },
			strategy = "arcane",
			tooltip = "Use arcane spells",
			index = 0,
		},
		["fire"] = {
			icon = "fire",
			command = { [0] = "co +fire,?" },
			strategy = "fire",
			tooltip = "Use fire spells",
			index = 1,
		},
		["fire_aoe"] = {
			icon = "fire_aoe",
			command = { [0] = "co ~fire aoe,?" },
			strategy = "fire aoe",
			tooltip = "Use fire AOE abilities",
			index = 2,
		},
		["frost"] = {
			icon = "frost",
			command = { [0] = "co +frost,?" },
			strategy = "frost",
			tooltip = "Use frost spells",
			index = 3,
		},
		["frost_aoe"] = {
			icon = "frost_aoe",
			command = { [0] = "co ~frost aoe,?" },
			strategy = "frost aoe",
			tooltip = "Use frost AOE abilities",
			index = 4,
		},
		["bmana"] = {
			icon = "bmana",
			command = { [0] = "co ~bmana,?", [1] = "nc ~bmana,?" },
			strategy = "bmana",
			tooltip = "Buff mana regen",
			index = 5,
		},
		["bdps"] = {
			icon = "bdps",
			command = { [0] = "co ~bdps,?", [1] = "nc ~bdps,?" },
			strategy = "bdps",
			tooltip = "Buff DPS",
			index = 6,
		},
		["cure"] = {
			icon = "cure",
			command = { [0] = "co ~cure,?", [1] = "nc ~cure,?" },
			strategy = "cure",
			tooltip = "Cure (poison, disease, etc.)",
			index = 7,
		},
	})
	CreateToolBar(frame, -y, "CLASS_PALADIN", {
		["dps"] = {
			icon = "dps",
			command = { [0] = "co +dps,?" },
			strategy = "dps",
			tooltip = "DPS mode",
			index = 0,
		},
		["tank"] = {
			icon = "tank",
			command = { [0] = "co +tank,?" },
			strategy = "tank",
			tooltip = "Tank mode",
			index = 1,
		},
		["heal"] = {
			icon = "heal",
			command = { [0] = "co +heal,?" },
			strategy = "heal",
			tooltip = "Healer mode",
			index = 2,
		},
		["cure"] = {
			icon = "cure",
			command = { [0] = "co ~cure,?", [1] = "nc ~cure,?" },
			strategy = "cure",
			tooltip = "Cure (poison, disease, etc.)",
			index = 3,
		},
		["bthreat"] = {
			icon = "bthreat",
			command = { [0] = "nc ~bthreat,?" },
			strategy = "bthreat",
			tooltip = "Increase threat generation",
			index = 4,
		},
	})
	CreateToolBar(frame, -y, "CLASS_PRIEST", {
		["heal"] = {
			icon = "heal",
			command = { [0] = "co +heal,?" },
			strategy = "heal",
			tooltip = "Healer mode",
			index = 0,
		},
		["holy"] = {
			icon = "holy",
			command = { [0] = "co +holy,?" },
			strategy = "holy",
			tooltip = "Use holy spells",
			index = 1,
		},
		["shadow"] = {
			icon = "shadow",
			command = { [0] = "co +shadow,?" },
			strategy = "shadow",
			tooltip = "DPS mode: shadow",
			index = 2,
		},
		["shadow_aoe"] = {
			icon = "shadow_aoe",
			command = { [0] = "co ~shadow aoe,?" },
			strategy = "shadow aoe",
			tooltip = "Use shadow AOE abilities",
			index = 3,
		},
		["shadow_debuff"] = {
			icon = "shadow_debuff",
			command = { [0] = "co ~shadow debuff,?" },
			strategy = "shadow debuff",
			tooltip = "Use shadow debuffs",
			index = 4,
		},
		["cure"] = {
			icon = "cure",
			command = { [0] = "co ~cure,?", [1] = "nc ~cure,?" },
			strategy = "cure",
			tooltip = "Cure (poison, disease, etc.)",
			index = 5,
		},
		["rshadow"] = {
			icon = "rshadow",
			command = { [0] = "co ~rshadow,?", [1] = "nc ~rshadow,?" },
			strategy = "rshadow",
			tooltip = "Provide shadow resistance",
			index = 6,
		},
	})
	CreateToolBar(frame, -y, "CLASS_ROGUE", {
		["dps"] = {
			icon = "dps",
			command = { [0] = "co +dps,?" },
			strategy = "dps",
			tooltip = "DPS mode",
			index = 0,
		},
		["aoe"] = {
			icon = "aoe",
			command = { [0] = "co ~aoe,?" },
			strategy = "aoe",
			tooltip = "Use AOE abilities",
			index = 1,
		},
	})
	CreateToolBar(frame, -y, "CLASS_SHAMAN", {
		["caster"] = {
			icon = "caster",
			command = { [0] = "co +caster,?" },
			strategy = "caster",
			tooltip = "Caster mode",
			index = 0,
		},
		["caster_aoe"] = {
			icon = "caster_aoe",
			command = { [0] = "co ~caster aoe,?" },
			strategy = "caster aoe",
			tooltip = "Use caster AOE abilities",
			index = 1,
		},
		["heal"] = {
			icon = "heal",
			command = { [0] = "co +heal,+threat,?" },
			strategy = "heal",
			tooltip = "Healer mode",
			index = 2,
		},
		["melee"] = {
			icon = "dps",
			command = { [0] = "co +melee,?" },
			strategy = "melee",
			tooltip = "Melee mode",
			index = 3,
		},
		["melee_aoe"] = {
			icon = "aoe",
			command = { [0] = "co ~melee aoe,?" },
			strategy = "melee aoe",
			tooltip = "Use melee AOE abilities",
			index = 4,
		},
		["totems"] = {
			icon = "totems",
			command = { [0] = "co ~totems,?" },
			strategy = "totems",
			tooltip = "Use totems",
			index = 5,
		},
		["cure"] = {
			icon = "cure",
			command = { [0] = "co ~cure,?", [1] = "nc ~cure,?" },
			strategy = "cure",
			tooltip = "Cure (poison, disease, etc.)",
			index = 6,
		},
	})
	CreateToolBar(frame, -y, "CLASS_WARLOCK", {
		["dps"] = {
			icon = "dps",
			command = { [0] = "co +dps,?" },
			strategy = "dps",
			tooltip = "DPS mode",
			index = 0,
		},
		["dps_debuff"] = {
			icon = "dps_debuff",
			command = { [0] = "co ~dps debuff,?" },
			strategy = "dps debuff",
			tooltip = "Use DPS debuffs",
			index = 1,
		},
		["caster_aoe"] = {
			icon = "caster_aoe",
			command = { [0] = "co ~aoe,?" },
			strategy = "aoe",
			tooltip = "Use AOE abilities",
			index = 2,
		},
		["tank"] = {
			icon = "tank",
			command = { [0] = "co +tank,?" },
			strategy = "tank",
			tooltip = "Summon tanky demons",
			index = 3,
		},
		["pet"] = {
			icon = "pet",
			command = { [0] = "co ~pet,?", [1] = "nc ~pet,?" },
			strategy = "pet",
			tooltip = "Use pet",
			index = 4,
		},
	})
	CreateToolBar(frame, -y, "CLASS_WARRIOR", {
		["dps"] = {
			icon = "dps",
			command = { [0] = "co +dps,?" },
			strategy = "dps",
			tooltip = "DPS mode",
			index = 0,
		},
		["warrior_aoe"] = {
			icon = "warrior_aoe",
			command = { [0] = "co ~aoe,?" },
			strategy = "aoe",
			tooltip = "Use AOE abilities",
			index = 1,
		},
		["tank"] = {
			icon = "tank",
			command = { [0] = "co +tank,?" },
			strategy = "tank",
			tooltip = "Tank mode",
			index = 2,
		},
	})
	CreateToolBar(frame, -y, "CLASS_DEATHKNIGHT", {
		["blood"] = {
			icon = "tank",
			command = { [0] = "co +blood,?", [1] = "nc +blood,?" },
			strategy = "blood",
			tooltip = "Blood (tank)",
			index = 0,
		},
		["frost"] = {
			icon = "frost",
			command = { [0] = "co +frost,?", [1] = "nc +frost,?" },
			strategy = "frost",
			tooltip = "Frost DPS",
			index = 1,
		},
		["unholy"] = {
			icon = "rshadow",
			command = { [0] = "co +unholy,?", [1] = "nc +unholy,?" },
			strategy = "unholy",
			tooltip = "Unholy DPS",
			index = 2,
		},
		["dk_aoe"] = {
			icon = "aoe",
			command = { [0] = "co ~aoe,?" },
			strategy = "aoe",
			tooltip = "Use AOE abilities",
			index = 3,
		},
	})

	y = y + 25
	CreateToolBar(frame, -y, "CLASS_PALADIN_BUFF", {
		["bmana"] = {
			icon = "bmana",
			command = { [0] = "co +bmana,?", [1] = "nc +bmana,?" },
			strategy = "bmana",
			tooltip = "Buff mana regen",
			index = 0,
		},
		["bhealth"] = {
			icon = "bhealth",
			command = { [0] = "co +bhealth,?", [1] = "nc +bhealth,?" },
			strategy = "bhealth",
			tooltip = "Buff health regen",
			index = 1,
		},
		["bdps"] = {
			icon = "bdps",
			command = { [0] = "co +bdps,?", [1] = "nc +bdps,?" },
			strategy = "bdps",
			tooltip = "Buff melee DPS",
			index = 2,
		},
		["bstats"] = {
			icon = "holy",
			command = { [0] = "co +bstats,?", [1] = "nc +bstats,?" },
			strategy = "bstats",
			tooltip = "Buff stats",
			index = 3,
		},
	})
	CreateToolBar(frame, -y, "CLASS_SHAMAN_BUFF", {
		["earth"] = {
			icon = "earth",
			command = { [0] = "co +earth,?" },
			strategy = "earth",
			tooltip = "Use earth spells",
			index = 0,
		},
		["fire"] = {
			icon = "fire",
			command = { [0] = "co +fire,?" },
			strategy = "fire",
			tooltip = "Use fire spells",
			index = 1,
		},
		["frost"] = {
			icon = "frost",
			command = { [0] = "co +frost,?" },
			strategy = "frost",
			tooltip = "Use frost spells",
			index = 2,
		},
		["air"] = {
			icon = "air",
			command = { [0] = "co +air,?" },
			strategy = "air",
			tooltip = "Use air spells",
			index = 3,
		},
		["bmana"] = {
			icon = "bmana",
			command = { [0] = "co ~bmana,?", [1] = "nc ~bmana,?" },
			strategy = "bmana",
			tooltip = "Buff mana regen",
			index = 4,
		},
		["bdps"] = {
			icon = "bdps",
			command = { [0] = "co ~bdps,?", [1] = "nc ~bdps,?" },
			strategy = "bdps",
			tooltip = "Buff DPS",
			index = 5,
		},
	})

	y = y + 25
	CreateToolBar(frame, -y, "CLASS_PALADIN_AURA", {
		["baoe"] = {
			icon = "aoe",
			command = { [0] = "co +baoe,?", [1] = "nc +baoe,?" },
			strategy = "baoe",
			tooltip = "Retribution aura",
			index = 0,
		},
		["rfire"] = {
			icon = "fire",
			command = { [0] = "co +rfire,?", [1] = "nc +rfire,?" },
			strategy = "rfire",
			tooltip = "Fire resistance aura",
			index = 1,
		},
		["rfrost"] = {
			icon = "frost",
			command = { [0] = "co +rfrost,?", [1] = "nc +rfrost,?" },
			strategy = "rfrost",
			tooltip = "Frost resistance aura",
			index = 2,
		},
		["rshadow"] = {
			icon = "rshadow",
			command = { [0] = "co +rshadow,?", [1] = "nc +rshadow,?" },
			strategy = "rshadow",
			tooltip = "Shadow resistance aura",
			index = 3,
		},
		["barmor"] = {
			icon = "barmor",
			command = { [0] = "co +barmor,?", [1] = "nc +barmor,?" },
			strategy = "barmor",
			tooltip = "Devotion aura",
			index = 4,
		},
	})

	frame:SetHeight(y + 25)
	return frame
end

function SetFrameColor(frame, class)
	local color = RAID_CLASS_COLORS[class]
	if color == nil then
		color = { r = 0.5, g = 0.1, b = 0.7 }
	end
	frame:SetBackdropBorderColor(color.r, color.g, color.b, 1.0)
	frame.header:SetBackdropColor(color.r, color.g, color.b, 1.0)
	frame.header:SetBackdropBorderColor(color.r, color.g, color.b, 1.0)
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
	getglobal(dropdown:GetName() .. "Text"):SetText(default_val)
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
			local editBox = getglobal("ChatFrameEditBox")
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
	local name = GetUnitName("target")
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

function CreatePartyBotOverlays()
	local overlays = {}
	for i = 1, 4 do
		local parent = getglobal("PartyMemberFrame" .. i)
		if parent ~= nil then
			local overlay = CreateFrame("Frame", "PartyBotOverlay" .. i, parent)
			overlay:SetWidth(70)
			overlay:SetHeight(44)
			overlay:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, -2)
			overlay:SetFrameLevel(50)
			overlay:EnableMouse(false)

			local role = overlay:CreateTexture(nil, "OVERLAY")
			role:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", 0, 0)
			role:SetWidth(16)
			role:SetHeight(16)
			role:SetTexture("Interface\\Addons\\Mangosbot\\Images\\role_dps.tga")
			overlay.role = role

			local gold = overlay:CreateFontString()
			gold:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", 0, -17)
			gold:SetWidth(70)
			gold:SetFont("Fonts/FRIZQT__.TTF", 9, "OUTLINE")
			gold:SetJustifyH("RIGHT")
			overlay.gold = gold

			local bags = overlay:CreateFontString()
			bags:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", 0, -29)
			bags:SetWidth(70)
			bags:SetFont("Fonts/FRIZQT__.TTF", 9, "OUTLINE")
			bags:SetJustifyH("RIGHT")
			overlay.bags = bags

			overlay:Hide()
			overlays[i] = overlay
		end
	end
	return overlays
end

function UpdatePartyBotOverlays()
	if PartyBotOverlays == nil then
		return
	end
	for i = 1, 4 do
		local overlay = PartyBotOverlays[i]
		if overlay == nil then
			return
		end
		local bot = botTable[partyName(i)]
		-- Party members are online by definition; only hide when roster explicitly says offline.
		if GetNumRaidMembers() > 0 or bot == nil or bot["online"] == false then
			overlay:Hide()
		else
			local role = bot["role"]
			if role == nil then
				overlay.role:Hide()
			else
				overlay.role:Show()
				overlay.role:SetTexture("Interface\\Addons\\Mangosbot\\Images\\role_" .. role .. ".tga")
			end

			local money = bot["money"]
			if money == nil or money == "" then
				overlay.gold:SetText("-")
			else
				overlay.gold:SetText(money)
			end

			local bagFree = bot["bagFree"]
			local bagTotal = bot["bagTotal"]
			if bagFree == nil or bagTotal == nil then
				overlay.bags:SetText("-")
			else
				overlay.bags:SetText(bagFree .. "/" .. bagTotal)
			end

			overlay:Show()
		end
	end
end

SelectedBotPanel = CreateSelectedBotPanel()
BotRoster = CreateBotRoster()
BotDebugPanel = CreateBotDebugPanel()
DropDownMenu = CreateDropDownMenu(BotRoster)
PartyBotOverlays = CreatePartyBotOverlays()
CurrentBot = nil

function UpdateGroupToolBar()
	for toolbarName, toolbar in pairs(GroupToolBars) do
		for buttonName, button in pairs(toolbar) do
			local toggleCount = 0
			for botName, bot in pairs(botTable) do
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
				if button["loot"] ~= nil and bot["loot"] ~= nil and string.find(bot["loot"], button["loot"]) ~= nil then
					toggle = true
				end
				if
					button["savemana"] ~= nil
					and bot["savemana"] ~= nil
					and string.find(bot["savemana"], button["savemana"]) ~= nil
				then
					toggle = true
				end

				if toggle then
					for i = 1, 5 do
						if partyName(i) == botName then
							toggleCount = toggleCount + 1
						end
					end
				end
			end
			ToggleButton(BotRoster, toolbarName, buttonName, toggleCount > 0, toggleCount < partySize())
		end
	end
end
