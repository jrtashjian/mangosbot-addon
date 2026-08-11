function CreateToolBar(frame, y, name, buttons, x, spacing, register)
	if x == nil then
		x = 5
	end
	if spacing == nil then
		spacing = 5
	end
	if register == nil then
		register = true
	end

	if frame.toolbar == nil then
		frame.toolbar = {}
	end

	local tb = CreateFrame("Frame", "Toolbar" .. name, frame)
	tb:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
	tb:SetWidth(frame:GetWidth() - x - 5)
	tb:SetHeight(22)
	tb:SetBackdropColor(0, 0, 0, 1.0)
	tb:SetBackdrop({
		edgeFile = "Interface/ChatFrame/ChatFrameBackground",
		tile = false,
		tileSize = 16,
		edgeSize = 0,
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
	})
	tb:SetBackdropBorderColor(0, 0, 0, 1.0)

	tb.buttons = {}
	for key, button in pairs(buttons) do
		local btn = CreateFrame("Button", "Toolbar" .. name .. key, tb)
		btn:SetPoint("TOPLEFT", tb, "TOPLEFT", button["index"] * (22 + spacing), 0)
		btn:SetWidth(20)
		btn:SetHeight(20)
		btn:SetBackdrop({
			edgeFile = "Interface/ChatFrame/ChatFrameBackground",
			tile = false,
			tileSize = 16,
			edgeSize = 2,
			insets = { left = 0, right = 0, top = 0, bottom = 0 },
		})
		btn:SetBackdropBorderColor(0, 0, 0, 0.0)
		btn:EnableMouse(true)
		btn:RegisterForClicks("LeftButtonDown")
		btn["tooltip"] = button["tooltip"]
		btn:SetScript("OnEnter", function()
			GameTooltip:SetOwner(frame, "ANCHOR_TOPLEFT", 0, -frame:GetHeight() - 40)
			GameTooltip:SetText(btn["tooltip"])
			GameTooltip:Show()
		end)
		btn:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
		btn["command"] = button["command"]
		btn["emote"] = button["emote"]
		btn["group"] = button["group"]
		btn["handler"] = button["handler"]
		btn["ToolBarButtonOnClick"] = ToolBarButtonOnClick
		btn:SetScript("OnClick", function()
			btn["ToolBarButtonOnClick"](btn, true)
		end)

		local image = CreateFrame("Frame", "Toolbar" .. name .. key .. "Image", btn)
		image:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
		image:SetWidth(16)
		image:SetHeight(16)
		image.texture = image:CreateTexture(nil, "BACKGROUND")
		local filename = "Interface\\Addons\\Mangosbot\\Images\\" .. button["icon"] .. ".tga"
		image.texture:SetTexture(filename)
		image.texture:SetAllPoints()
		btn.image = image

		tb.buttons[key] = btn
	end

	frame.toolbar[name] = tb
	if register then
		ToolBars[name] = buttons
	end
	return buttons
end

function CreateRtiToolBar(frame, y, name, group, x, spacing, register)
	return CreateToolBar(frame, -y, name, {
		["rti_skull"] = {
			icon = "rti_skull",
			command = { [0] = "rti skull" },
			rti = "skull",
			tooltip = "Attack the skull-marked target",
			index = 0,
			group = group,
		},
		["rti_cross"] = {
			icon = "rti_cross",
			command = { [0] = "rti cross" },
			rti = "cross",
			tooltip = "Attack the cross-marked target",
			index = 1,
			group = group,
		},
		["rti_circle"] = {
			icon = "rti_circle",
			command = { [0] = "rti circle" },
			rti = "circle",
			tooltip = "Attack the circle-marked target",
			index = 2,
			group = group,
		},
		["rti_star"] = {
			icon = "rti_star",
			command = { [0] = "rti star" },
			rti = "star",
			tooltip = "Attack the star-marked target",
			index = 3,
			group = group,
		},
		["rti_square"] = {
			icon = "rti_square",
			command = { [0] = "rti square" },
			rti = "square",
			tooltip = "Attack the square-marked target",
			index = 4,
			group = group,
		},
		["rti_triangle"] = {
			icon = "rti_triangle",
			command = { [0] = "rti triangle" },
			rti = "triangle",
			tooltip = "Attack the triangle-marked target",
			index = 5,
			group = group,
		},
		["rti_diamond"] = {
			icon = "rti_diamond",
			command = { [0] = "rti diamond" },
			rti = "diamond",
			tooltip = "Attack the diamond-marked target",
			index = 6,
			group = group,
		},
		["rti_moon"] = {
			icon = "rti_moon",
			command = { [0] = "rti moon" },
			rti = "moon",
			tooltip = "Attack the moon-marked target",
			index = 7,
			group = group,
		},
	}, x, spacing, register)
end

function CreateRtiCcToolBar(frame, y, name, group, x, spacing, register)
	return CreateToolBar(frame, -y, name, {
		["rti_skull"] = {
			icon = "cc_skull",
			command = { [0] = "rti cc skull" },
			rti_cc = "skull",
			tooltip = "Crowd control the skull-marked target",
			index = 0,
			group = group,
		},
		["rti_cross"] = {
			icon = "cc_cross",
			command = { [0] = "rti cc cross" },
			rti_cc = "cross",
			tooltip = "Crowd control the cross-marked target",
			index = 1,
			group = group,
		},
		["rti_circle"] = {
			icon = "cc_circle",
			command = { [0] = "rti cc circle" },
			rti_cc = "circle",
			tooltip = "Crowd control the circle-marked target",
			index = 2,
			group = group,
		},
		["rti_star"] = {
			icon = "cc_star",
			command = { [0] = "rti cc star" },
			rti_cc = "star",
			tooltip = "Crowd control the star-marked target",
			index = 3,
			group = group,
		},
		["rti_square"] = {
			icon = "cc_square",
			command = { [0] = "rti cc square" },
			rti_cc = "square",
			tooltip = "Crowd control the square-marked target",
			index = 4,
			group = group,
		},
		["rti_triangle"] = {
			icon = "cc_triangle",
			command = { [0] = "rti cc triangle" },
			rti_cc = "triangle",
			tooltip = "Crowd control the triangle-marked target",
			index = 5,
			group = group,
		},
		["rti_diamond"] = {
			icon = "cc_diamond",
			command = { [0] = "rti cc diamond" },
			rti_cc = "diamond",
			tooltip = "Crowd control the diamond-marked target",
			index = 6,
			group = group,
		},
		["rti_moon"] = {
			icon = "cc_moon",
			command = { [0] = "rti cc moon" },
			rti_cc = "moon",
			tooltip = "Crowd control the moon-marked target",
			index = 7,
			group = group,
		},
	}, x, spacing, register)
end

function CreateMovementToolBar(frame, y, name, group, x, spacing, register)
	local tb = {
		["follow_master"] = {
			icon = "follow_master",
			command = { [0] = "#a follow", [1] = "#a nc ?", [2] = "#a co ?" },
			strategy = "follow",
			tooltip = "Follow me",
			index = 0,
			group = group,
			emote = "follow",
		},
		["stay"] = {
			icon = "stay",
			command = { [0] = "#a stay", [1] = "#a nc ?", [2] = "#a co ?" },
			strategy = "stay",
			tooltip = "Stay in place",
			index = 1,
			group = group,
			emote = "wait",
		},
	}
	local index = 2
	if not group then
		tb["runaway"] = {
			icon = "flee",
			command = { [0] = "#a co ~runaway,?" },
			strategy = "runaway",
			tooltip = "Run away from mobs",
			index = index,
			group = group,
		}
		index = index + 1
	end

	tb["flee_passive"] = {
		icon = "flee_passive",
		command = { [0] = "#a flee", [1] = "#a nc ?", [2] = "#a co ?" },
		strategy = "",
		tooltip = "Ignore everything and follow master",
		index = index,
		group = group,
		emote = "flee",
	}
	index = index + 1

	tb["passive"] = {
		icon = "passive",
		command = { [0] = "nc +passive,?", [1] = "co +passive,?" },
		strategy = "passive",
		tooltip = "Passive: don't rush into combat",
		index = index,
		group = group,
	}
	index = index + 1

	if group then
		tb["loot"] = {
			icon = "loot",
			command = { [0] = "d add all loot", [1] = "d loot" },
			strategy = "",
			tooltip = "Loot everything",
			index = index,
			group = group,
		}
		index = index + 1
		tb["attack"] = {
			icon = "dps",
			command = { [0] = "d attack my target" },
			strategy = "",
			tooltip = "Attack my target",
			index = index,
			group = group,
		}
		index = index + 1
		tb["pull"] = {
			icon = "tank_assist",
			command = { [0] = "#a @dps flee", [1] = "#a @heal flee", [2] = "#a @tank d attack my target" },
			strategy = "",
			tooltip = "Pull",
			index = index,
			group = group,
		}
		index = index + 1
		tb["summon"] = {
			icon = "summon",
			command = { [0] = "summon" },
			strategy = "",
			tooltip = "Summon at meeting stone",
			index = index,
			group = group,
		}
	end

	return CreateToolBar(frame, -y, name, tb, x, spacing, register)
end

function CreateFormationToolBar(frame, y, name, group, x, spacing, register)
	return CreateToolBar(frame, -y, name, {
		["near"] = {
			icon = "formation_near",
			command = { [0] = "formation near" },
			formation = "near",
			tooltip = "Near (default half-circle)",
			index = 0,
			group = group,
		},
		["queue"] = {
			icon = "formation_queue",
			command = { [0] = "formation queue" },
			formation = "queue",
			tooltip = "Queue / follow in line",
			index = 1,
			group = group,
		},
		["melee"] = {
			icon = "formation_melee",
			command = { [0] = "formation melee" },
			formation = "melee",
			tooltip = "Group up close, like a pet",
			index = 2,
			group = group,
		},
		["arrow"] = {
			icon = "formation_arrow",
			command = { [0] = "formation arrow" },
			formation = "arrow",
			tooltip = "Tank first, dps/healer last",
			index = 3,
			group = group,
		},
		["far"] = {
			icon = "formation_far",
			command = { [0] = "formation far" },
			formation = "far",
			tooltip = "Maintain a distance",
			index = 4,
			group = group,
		},
		["circle"] = {
			icon = "formation_circle",
			command = { [0] = "formation circle" },
			formation = "circle",
			tooltip = "Circle around target",
			index = 5,
			group = group,
		},
		["line"] = {
			icon = "formation_line",
			command = { [0] = "formation line" },
			formation = "line",
			tooltip = "Line formation",
			index = 6,
			group = group,
		},
		["shield"] = {
			icon = "barmor",
			command = { [0] = "formation shield" },
			formation = "shield",
			tooltip = "Shield wall in front",
			index = 7,
			group = group,
		},
		["chaos"] = {
			icon = "formation_chaos",
			command = { [0] = "formation chaos" },
			formation = "chaos",
			tooltip = "Move freely",
			index = 8,
			group = group,
		},
	}, x, spacing, register)
end

function CreateStanceToolBar(frame, y, name, group, x, spacing, register)
	return CreateToolBar(frame, -y, name, {
		["near"] = {
			icon = "stance_near",
			command = { [0] = "stance near" },
			stance = "near",
			tooltip = "Default stance",
			index = 0,
			group = group,
		},
		["tank"] = {
			icon = "stance_tank",
			command = { [0] = "stance tank" },
			stance = "tank",
			tooltip = "Off-tank stance",
			index = 1,
			group = group,
		},
		["turnback"] = {
			icon = "stance_turnback",
			command = { [0] = "stance turnback" },
			stance = "turnback",
			tooltip = "Tank the enemy away from party",
			index = 2,
			group = group,
		},
		["behind"] = {
			icon = "stance_behind",
			command = { [0] = "stance behind" },
			stance = "behind",
			tooltip = "Attack from behind (melee)",
			index = 3,
			group = group,
		},
	}, x, spacing, register)
end

function CreateGenericNonCombatToolBar(frame, y, name, group, x, spacing, register)
	return CreateToolBar(frame, -y, name, {
		["food"] = {
			icon = "food",
			command = { [0] = "nc ~food,?" },
			strategy = "food",
			tooltip = "Use food and drinks",
			index = 0,
			group = group,
		},
		["buff"] = {
			icon = "bdps",
			command = { [0] = "nc ~buff,?" },
			strategy = "buff",
			tooltip = "Buff party members",
			index = 1,
			group = group,
		},
		["loot"] = {
			icon = "loot",
			command = { [0] = "nc ~loot,?" },
			strategy = "loot",
			tooltip = "Enable looting",
			index = 2,
			group = group,
		},
		["gather"] = {
			icon = "gather",
			command = { [0] = "nc ~gather,?" },
			strategy = "gather",
			tooltip = "Gather herbs, ore, etc.",
			index = 3,
			group = group,
		},
	}, x, spacing, register)
end

function CreateGenericCombatToolBar(frame, y, name, group, x, spacing, register)
	return CreateToolBar(frame, -y, name, {
		["potions"] = {
			icon = "potions",
			command = { [0] = "co ~potions,?" },
			strategy = "potions",
			tooltip = "Use health and mana potions",
			index = 0,
			group = group,
		},
		["cast_time"] = {
			icon = "cast_time",
			command = { [0] = "co ~cast time,?" },
			strategy = "cast time",
			tooltip = "Do not cast long spells on almost dead targets",
			index = 1,
			group = group,
		},
		["mark_rti"] = {
			icon = "mark_rti",
			command = { [0] = "co ~mark rti,?" },
			strategy = "mark rti",
			tooltip = "Mark current target with raid icon",
			index = 2,
			group = group,
		},
		["ads"] = {
			icon = "ads",
			command = { [0] = "co ~ads,?", [1] = "nc ~ads,?" },
			strategy = "ads",
			tooltip = "Flee if extra mobs might be pulled",
			index = 3,
			group = group,
		},
		["boost"] = {
			icon = "boost",
			command = { [0] = "co ~boost,?" },
			strategy = "boost",
			tooltip = "Boost dps by using cooldowns",
			index = 4,
			group = group,
		},
		["conserve_mana"] = {
			icon = "conserve_mana",
			command = { [0] = "co ~conserve mana,?" },
			strategy = "conserve mana",
			tooltip = "Reduce mana usage at cost of DPS",
			index = 5,
			group = group,
		},
		["cc"] = {
			icon = "cc",
			command = { [0] = "co ~cc,?" },
			strategy = "cc",
			tooltip = "Use crowd control abilities",
			index = 6,
			group = group,
		},
	}, x, spacing, register)
end

function CreateSaveManaToolBar(frame, y, name, group, x, spacing, register)
	local buttons = {}
	local levels = {
		[1] = "Off (use mana freely)",
		[2] = "Light (skip expensive spells)",
		[3] = "Balanced (core spells only)",
		[4] = "Strict (essential spells only)",
		[5] = "Maximum (rarely cast spells)",
	}
	for i = 1, 5 do
		buttons["savemana" .. i] = {
			icon = "savemana" .. i,
			command = { [0] = "save mana " .. i },
			tooltip = "Mana saving: " .. levels[i],
			index = i - 1,
			group = group,
			savemana = i,
		}
	end
	return CreateToolBar(frame, -y, name, buttons, x, spacing, register)
end
