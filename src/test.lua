-- Mangosbot harness: exercises Core and Protocol under stock Lua 5.1.
-- Run with: lua test.lua   (from src/)

DEFAULT_CHAT_FRAME = { AddMessage = function(_self, s) io.write("CHAT: " .. tostring(s) .. "\n") end }
UIParent = {}

frames = {}
function CreateFrame(_kind, _name, _parent, _template)
    local f = {}
    function f:SetScript(_k, fn) self.script = fn end
    frames[#frames + 1] = f
    return f
end

tinsert = table.insert
tremove = table.remove
unpack = unpack or table.unpack
table.getn = table.getn or function(t) return #t end

GetNumPartyMembers = function() return 0 end
GetNumRaidMembers = function() return 0 end
UnitName = function() return nil end
GetBuildInfo = function() return "3.3.5", "12340", "Jun 30 2010", 30300 end
InviteUnit = function() end
InviteByName = function() end
SendChatMessage = function() end
SendAddonMessage = function() end

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

check("client detects wotlk", GetMangosbotVersion() == 2)
check("client has addon whisper", GetMangosbotClient().hasAddonWhisper == true)
check("MB_HasDeathKnight on wotlk", MB_HasDeathKnight() == true)

check("fmod basic", fmod(7, 3) == 1)
check("fmod exact", fmod(9, 3) == 0)

check("trim2 strips leading/trailing spaces", trim2("  hello  ") == "hello")
check("trim2 strips tabs/newlines", trim2("\tfoo\n") == "foo")

check("StripColors removes |cAARRGGBB", StripColors("|cff00ff00near|r") == "near")
check("StripColors leaves plain text", StripColors("near") == "near")
check("NormalizeMessage strips color and trims", NormalizeMessage("  |cff00ff00behind|r  ") == "behind")

local parts = splitString2("a, b, c", ", ")
check("splitString2 splits on pattern", #parts == 3 and parts[1] == "a" and parts[2] == "b" and parts[3] == "c")

check("StartsWith positive", StartsWith("Formation: near", "Formation:") == true)
check("StartsWith negative", StartsWith("Stance: near", "Formation:") == false)
check("AfterPrefix trims value", AfterPrefix("Formation:  near  ", "Formation:") == "near")

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

OnWhisper('rti set to cross', bot)
check("rti set to", botTable[bot].rti == "cross")

OnWhisper('rti cc set to diamond', bot)
check("rti cc set to", botTable[bot].rti_cc == "diamond")

-- BOT\t framed payload
OnWhisper('BOT\tFormation: |cff00ff00arrow|r', bot)
check("BOT\\t frame stripped", botTable[bot].formation == "arrow")

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

-- Classic client detection
GetBuildInfo = function() return "1.12.1", "5875", "Sep 19 2006", 11000 end
-- re-load core detection is once at load; just unit-test helpers still ok
check("fmod still works after", fmod(5, 2) == 1)

if failures == 0 then
    print("ALL TESTS PASSED")
    os.exit(0)
else
    print(failures .. " TEST(S) FAILED")
    os.exit(1)
end
