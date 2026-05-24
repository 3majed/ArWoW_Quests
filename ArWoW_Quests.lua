-- Addon: ArWoW_Quests (version: 1.0.0) 2026.05.16
-- Description: AddOn displays translated quest information in the original windows.
-- Author: Majed
-- WWW: https://github.com/3majed

-- Global Variables
local QTR_version = "1.1.0";
local QTR_name = UnitName("player");
local QTR_class= UnitClass("player");
local QTR_race = UnitRace("player");
local QTR_sex = UnitSex("player");     -- 1:neutral, 2:male, 3:female
local QTR_event="";
local QTR_waitTable = {};
local QTR_waitFrame = nil;
local QTR_GossipButtonsEN = {};
local QTR_GossipButtonsAR = {};
local QTR_QuestGreetingButtonsEN = {};
local QTR_QuestGreetingButtonsAR = {};
local QTR_ToggleButtonGR = nil;
local QTR_QuestGreetingHash = 0;
local QTR_QuestGreetingState = "0";
local QTR_WorldMapRetryPending = false;
local QTR_UpdateWorldMapRewards;
local QTR_RestoreWorldMapRewards;
local QTR_UpdateGuildRegistrarFrame;
local QTR_MessOrig = {
      details    = "Description", 
      objectives = "Objectives", 
      rewards    = "Rewards", 
   bonustalents = "Bonus talents:", 
      itemchoose1= "You will be able to choose one of these rewards:", 
      itemchoose2= "Choose one of these rewards:", 
      itemreceiv1= "You will also receive:", 
      itemreceiv2= "You receiving the reward:", 
      learnspell = "Learn Spell:", 
      reqmoney   = "Required Money:", 
      reqitems   = "Required items:", 
      experience = "Experience:", 
      currquests = "Current Quests", 
      avaiquests = "Available Quests", 
      guildservices = "Available Services",
      guildcharterpurchase = "Purchase a Guild Charter",
      guildcharterregister = "Register a Guild Charter",
      guildpurchaseinfo = "To create a guild you must purchase this charter, get 9 unique player signatures, and return the charter to me.  Please enter the desired name for your guild.",
         arenacharterpurchase = "Purchase a Team Charter",
         arenacharterturnin = "Turn in your Team Charter",
         arenapurchaseinfo = "To create an arena team you must purchase this charter, get the same number of unique player signatures as the size of your team, and return the charter to me.  Please enter the desired name for your arena team.",
         arenateam2v2 = "2v2 Arena Team",
         arenateam3v3 = "3v3 Arena Team",
         arenateam5v5 = "5v5 Arena Team",
        costlabel = "Cost:",
         purchase = "Purchase",
                accept = ACCEPT or "Accept",
               decline = DECLINE or "Decline",
                     continue = CONTINUE or "Continue",
                   complete = COMPLETE or "Complete",
             completequest = COMPLETE_QUEST or "Complete Quest",
                cancel = "Cancel",
            questlogtitle = "Quest Log",
          questlogquests = "Quests",
       noactivequests = "No Active Quests",
                     abandon = "Abandon",
                        share = "Share",
                        track = "Track",
                     showmap = SHOW_MAP or "Show Map",
                        close = "Close",
               goodbye = "Goodbye", };
local Original_Font1 = "Fonts\\MORPHEUS.ttf";
local Original_Font2 = "Fonts\\FRIZQT__.ttf";

-- Safe tuning block: edit these values to adjust translated layout without touching logic.
-- Keep them non-local on purpose, because WoW's Lua chunk limit is 200 locals.

-- Body wrapping. QTR_QuestBodyLimit is the manual line-break limit for classic quest text.
local QTR_QuestBodyLimit = 32; -- line-wrap limit for classic quest body reshaping

-- Maximum wrap width used by translated gossip bodies in external dialogue panes.
QTR_ImmersionGossipBodyTargetWidth = 360; -- cap for external gossip body width

-- Button/title spacing for translated quest and gossip rows.
QTR_GossipOptionIconPadding = 16; -- space reserved for gossip row icons
QTR_GossipOptionMinWidth = 40; -- minimum usable gossip row width
QTR_QuestTitleIconPadding = 16; -- space reserved for quest row icons
QTR_QuestTitleMinWidth = 40; -- minimum usable quest row width
QTR_QuestLogTitleBasePadding = 20; -- base padding inside quest log rows
QTR_QuestLogTitleTagPadding = 4; -- extra space after quest tag text
QTR_QuestLogTitleCheckPadding = 2; -- extra space after quest completion check
QTR_QuestLogTitleMinWidth = 40; -- minimum usable quest log row width

-- Gossip greeting text box size, anchor offsets, and wrap padding.
-- Parent padding values clamp the text box when the frame is narrower than the target width.
QTR_GossipGreetingTextTargetWidth = 265; -- preferred gossip greeting width
QTR_GossipGreetingTextOffsetX = 10; -- default greeting anchor X offset
QTR_GossipGreetingTextOffsetY = -10; -- default greeting anchor Y offset
QTR_GossipGreetingArabicOffsetX = -2; -- extra X shift for Arabic layout
QTR_GossipGreetingArabicExtraWidth = 4; -- extra width granted to Arabic text
QTR_GossipGreetingWrapPadding = 18; -- wrap padding removed before shaping
QTR_GossipGreetingArabicParentPadding = 15; -- frame-edge padding in Arabic mode
QTR_GossipGreetingDefaultParentPadding = 20; -- frame-edge padding in original mode
QTR_GossipGreetingMinWidth = 220; -- smallest allowed greeting text width

-- Quest greeting text area width and header width.
QTR_QuestGreetingTextTargetWidth = 320; -- preferred quest greeting width
QTR_QuestGreetingParentPadding = 40; -- frame-edge padding for quest greetings
QTR_QuestGreetingMinWidth = 280; -- smallest allowed quest greeting width
QTR_QuestGreetingHeaderWidth = 280; -- width for greeting section headers

-- Addon options panel layout in Interface Options.
QTR_OptionsTextWidth = 360; -- width for option description text
QTR_OptionsHeaderWidth = 420; -- width for the options panel header
QTR_OptionsTextRight = -40; -- right offset for option text anchors
QTR_OptionsCheckRight = QTR_OptionsTextRight + 12; -- right offset for option checkboxes

-- Font sizes for translated quest log, greetings, and button rows.
QTR_QuestLogEntryFontSize = 13; -- quest log list entry size
QTR_QuestLogHeaderFontSize = 18; -- quest log title size
QTR_QuestLogCountFontSize = 11; -- quest count text size
QTR_QuestLogEmptyFontSize = 13; -- no-active-quests text size
QTR_QuestLogActionButtonFontSize = 13; -- quest log button text size
QTR_QuestLogShowMapFontSize = 13; -- Show Map label size
QTR_GossipGreetingFontSize = 13; -- gossip greeting body text size
QTR_QuestGreetingFontSize = 13; -- quest greeting body text size
QTR_QuestGreetingHeaderFontSize = 18; -- quest greeting header size
QTR_GreetingGoodbyeFontSize = 13; -- goodbye button text size
QTR_QuestOfferButtonFontSize = 13; -- accept/decline button text size
QTR_QuestButtonFontSize = 13; -- translated quest choice button size
QTR_GossipButtonFontSize = 13; -- translated gossip option button size
local Tut_ID = 0;
if not QTR then
   QTR = { };
end

local p_race = {
      ["Blood Elf"] = { M1="بلود إلف", D1="بلود إلف", C1="بلود إلف", B1="بلود إلف", N1="بلود إلف", K1="بلود إلف", W1="بلود إلف", M2="بلود إلف", D2="بلود إلف", C2="بلود إلف", B2="بلود إلف", N2="بلود إلف", K2="بلود إلف", W2="بلود إلف" }, 
      ["Dark Iron Dwarf"] = { M1="دارك آيرون دوارف", D1="دارك آيرون دوارف", C1="دارك آيرون دوارف", B1="دارك آيرون دوارف", N1="دارك آيرون دوارف", K1="دارك آيرون دوارف", W1="دارك آيرون دوارف", M2="دارك آيرون دوارف", D2="دارك آيرون دوارف", C2="دارك آيرون دوارف", B2="دارك آيرون دوارف", N2="دارك آيرون دوارف", K2="دارك آيرون دوارف", W2="دارك آيرون دوارف" },
      ["Draenei"] = { M1="دراني", D1="دراني", C1="دراني", B1="دراني", N1="دراني", K1="دراني", W1="دراني", M2="دراني", D2="دراني", C2="دراني", B2="دراني", N2="دراني", K2="دراني", W2="دراني" },
      ["Dwarf"] = { M1="دوارف", D1="دوارف", C1="دوارف", B1="دوارف", N1="دوارف", K1="دوارف", W1="دوارف", M2="دوارف", D2="دوارف", C2="دوارف", B2="دوارف", N2="دوارف", K2="دوارف", W2="دوارف" },
      ["Gnome"] = { M1="نوم", D1="نوم", C1="نوم", B1="نوم", N1="نوم", K1="نوم", W1="نوم", M2="نوم", D2="نوم", C2="نوم", B2="نوم", N2="نوم", K2="نوم", W2="نوم" },
      ["Goblin"] = { M1="غوبلن", D1="غوبلن", C1="غوبلن", B1="غوبلن", N1="غوبلن", K1="غوبلن", W1="غوبلن", M2="غوبلن", D2="غوبلن", C2="غوبلن", B2="غوبلن", N2="غوبلن", K2="غوبلن", W2="غوبلن" },
      ["Highmountain Tauren"] = { M1="هاي ماونتن تاورن", D1="هاي ماونتن تاورن", C1="هاي ماونتن تاورن", B1="هاي ماونتن تاورن", N1="هاي ماونتن تاورن", K1="هاي ماونتن تاورن", W1="هاي ماونتن تاورن", M2="هاي ماونتن تاورن", D2="هاي ماونتن تاورن", C2="هاي ماونتن تاورن", B2="هاي ماونتن تاورن", N2="هاي ماونتن تاورن", K2="هاي ماونتن تاورن", W2="هاي ماونتن تاورن" },
      ["Human"] = { M1="هيومن", D1="هيومن", C1="هيومن", B1="هيومن", N1="هيومن", K1="هيومن", W1="هيومن", M2="هيومن", D2="هيومن", C2="هيومن", B2="هيومن", N2="هيومن", K2="هيومن", W2="هيومن" },
      ["Kul Tiran"] = { M1="كول تيران", D1="كول تيران", C1="كول تيران", B1="كول تيران", N1="كول تيران", K1="كول تيران", W1="كول تيران", M2="كول تيران", D2="كول تيران", C2="كول تيران", B2="كول تيران", N2="كول تيران", K2="كول تيران", W2="كول تيران" },
      ["Lightforged Draenei"] = { M1="لايت فورجد دراني", D1="لايت فورجد دراني", C1="لايت فورجد دراني", B1="لايت فورجد دراني", N1="لايت فورجد دراني", K1="لايت فورجد دراني", W1="لايت فورجد دراني", M2="لايت فورجد دراني", D2="لايت فورجد دراني", C2="لايت فورجد دراني", B2="لايت فورجد دراني", N2="لايت فورجد دراني", K2="لايت فورجد دراني", W2="لايت فورجد دراني" },
      ["Mag'har Orc"] = { M1="ماغهار أورك", D1="ماغهار أورك", C1="ماغهار أورك", B1="ماغهار أورك", N1="ماغهار أورك", K1="ماغهار أورك", W1="ماغهار أورك", M2="ماغهار أورك", D2="ماغهار أورك", C2="ماغهار أورك", B2="ماغهار أورك", N2="ماغهار أورك", K2="ماغهار أورك", W2="ماغهار أورك" },
      ["Nightborne"] = { M1="نايت بورن", D1="نايت بورن", C1="نايت بورن", B1="نايت بورن", N1="نايت بورن", K1="نايت بورن", W1="نايت بورن", M2="نايت بورن", D2="نايت بورن", C2="نايت بورن", B2="نايت بورن", N2="نايت بورن", K2="نايت بورن", W2="نايت بورن" },
      ["Night Elf"] = { M1="نايت إلف", D1="نايت إلف", C1="نايت إلف", B1="نايت إلف", N1="نايت إلف", K1="نايت إلف", W1="نايت إلف", M2="نايت إلف", D2="نايت إلف", C2="نايت إلف", B2="نايت إلف", N2="نايت إلف", K2="نايت إلف", W2="نايت إلف" },
      ["Orc"] = { M1="أورك", D1="أورك", C1="أورك", B1="أورك", N1="أورك", K1="أورك", W1="أورك", M2="أورك", D2="أورك", C2="أورك", B2="أورك", N2="أورك", K2="أورك", W2="أورك" },
      ["Pandaren"] = { M1="باندارن", D1="باندارن", C1="باندارن", B1="باندارن", N1="باندارن", K1="باندارن", W1="باندارن", M2="باندارن", D2="باندارن", C2="باندارن", B2="باندارن", N2="باندارن", K2="باندارن", W2="باندارن" },
      ["Tauren"] = { M1="تاورن", D1="تاورن", C1="تاورن", B1="تاورن", N1="تاورن", K1="تاورن", W1="تاورن", M2="تاورن", D2="تاورن", C2="تاورن", B2="تاورن", N2="تاورن", K2="تاورن", W2="تاورن" },
      ["Troll"] = { M1="ترول", D1="ترول", C1="ترول", B1="ترول", N1="ترول", K1="ترول", W1="ترول", M2="ترول", D2="ترول", C2="ترول", B2="ترول", N2="ترول", K2="ترول", W2="ترول" },
      ["Undead"] = { M1="أنديد", D1="أنديد", C1="أنديد", B1="أنديد", N1="أنديد", K1="أنديد", W1="أنديد", M2="أنديد", D2="أنديد", C2="أنديد", B2="أنديد", N2="أنديد", K2="أنديد", W2="أنديد" },
      ["Void Elf"] = { M1="فويد إلف", D1="فويد إلف", C1="فويد إلف", B1="فويد إلف", N1="فويد إلف", K1="فويد إلف", W1="فويد إلف", M2="فويد إلف", D2="فويد إلف", C2="فويد إلف", B2="فويد إلف", N2="فويد إلف", K2="فويد إلف", W2="فويد إلف" },
      ["Worgen"] = { M1="وورغن", D1="وورغن", C1="وورغن", B1="وورغن", N1="وورغن", K1="وورغن", W1="وورغن", M2="وورغن", D2="وورغن", C2="وورغن", B2="وورغن", N2="وورغن", K2="وورغن", W2="وورغن" },
      ["Zandalari Troll"] = { M1="زاندالاري ترول", D1="زاندالاري ترول", C1="زاندالاري ترول", B1="زاندالاري ترول", N1="زاندالاري ترول", K1="زاندالاري ترول", W1="زاندالاري ترول", M2="زاندالاري ترول", D2="زاندالاري ترول", C2="زاندالاري ترول", B2="زاندالاري ترول", N2="زاندالاري ترول", K2="زاندالاري ترول", W2="زاندالاري ترول" }, }

local p_class = {
      ["Death Knight"] = { M1="ديث نايت", D1="ديث نايت", C1="ديث نايت", B1="ديث نايت", N1="ديث نايت", K1="ديث نايت", W1="ديث نايت", M2="ديث نايت", D2="ديث نايت", C2="ديث نايت", B2="ديث نايت", N2="ديث نايت", K2="ديث نايت", W2="ديث نايت" },
      ["Demon Hunter"] = { M1="ديمون هنتر", D1="ديمون هنتر", C1="ديمون هنتر", B1="ديمون هنتر", N1="ديمون هنتر", K1="ديمون هنتر", W1="ديمون هنتر", M2="ديمون هنتر", D2="ديمون هنتر", C2="ديمون هنتر", B2="ديمون هنتر", N2="ديمون هنتر", K2="ديمون هنتر", W2="ديمون هنتر" },
      ["Druid"] = { M1="درويد", D1="درويد", C1="درويد", B1="درويد", N1="درويد", K1="درويد", W1="درويد", M2="درويد", D2="درويد", C2="درويد", B2="درويد", N2="درويد", K2="درويد", W2="درويد" },
      ["Hunter"] = { M1="هنتر", D1="هنتر", C1="هنتر", B1="هنتر", N1="هنتر", K1="هنتر", W1="هنتر", M2="هنتر", D2="هنتر", C2="هنتر", B2="هنتر", N2="هنتر", K2="هنتر", W2="هنتر" },
      ["Mage"] = { M1="ميج", D1="ميج", C1="ميج", B1="ميج", N1="ميج", K1="ميج", W1="ميج", M2="ميج", D2="ميج", C2="ميج", B2="ميج", N2="ميج", K2="ميج", W2="ميج" },
      ["Monk"] = { M1="مونك", D1="مونك", C1="مونك", B1="مونك", N1="مونك", K1="مونك", W1="مونك", M2="مونك", D2="مونك", C2="مونك", B2="مونك", N2="مونك", K2="مونك", W2="مونك" },
      ["Paladin"] = { M1="بالادن", D1="بالادن", C1="بالادن", B1="بالادن", N1="بالادن", K1="بالادن", W1="بالادن", M2="بالادن", D2="بالادن", C2="بالادن", B2="بالادن", N2="بالادن", K2="بالادن", W2="بالادن" },
      ["Priest"] = { M1="بريست", D1="بريست", C1="بريست", B1="بريست", N1="بريست", K1="بريست", W1="بريست", M2="بريست", D2="بريست", C2="بريست", B2="بريست", N2="بريست", K2="بريست", W2="بريست" },
      ["Rogue"] = { M1="روغ", D1="روغ", C1="روغ", B1="روغ", N1="روغ", K1="روغ", W1="روغ", M2="روغ", D2="روغ", C2="روغ", B2="روغ", N2="روغ", K2="روغ", W2="روغ" },
      ["Shaman"] = { M1="شامان", D1="شامان", C1="شامان", B1="شامان", N1="شامان", K1="شامان", W1="شامان", M2="شامان", D2="شامان", C2="شامان", B2="شامان", N2="شامان", K2="شامان", W2="شامان" },
      ["Warlock"] = { M1="وارلوك", D1="وارلوك", C1="وارلوك", B1="وارلوك", N1="وارلوك", K1="وارلوك", W1="وارلوك", M2="وارلوك", D2="وارلوك", C2="وارلوك", B2="وارلوك", N2="وارلوك", K2="وارلوك", W2="وارلوك" },
      ["Warrior"] = { M1="واريور", D1="واريور", C1="واريور", B1="واريور", N1="واريور", K1="واريور", W1="واريور", M2="واريور", D2="واريور", C2="واريور", B2="واريور", N2="واريور", K2="واريور", W2="واريور" }, }
	  
	  
if (p_race[QTR_race]) then      
   player_race = { M1=p_race[QTR_race].M1, D1=p_race[QTR_race].D1, C1=p_race[QTR_race].C1, B1=p_race[QTR_race].B1, N1=p_race[QTR_race].N1, K1=p_race[QTR_race].K1, W1=p_race[QTR_race].W1, M2=p_race[QTR_race].M2, D2=p_race[QTR_race].D2, C2=p_race[QTR_race].C2, B2=p_race[QTR_race].B2, N2=p_race[QTR_race].N2, K2=p_race[QTR_race].K2, W2=p_race[QTR_race].W2 };
else   
   player_race = { M1=QTR_race, D1=QTR_race, C1=QTR_race, B1=QTR_race, N1=QTR_race, K1=QTR_race, W1=QTR_race, M2=QTR_race, D2=QTR_race, C2=QTR_race, B2=QTR_race, N2=QTR_race, K2=QTR_race, W2=QTR_race };
   DEFAULT_CHAT_FRAME:AddMessage("|cff55ff00QTR - عرق جديد: "..QTR_race);
end
if (p_class[QTR_class]) then
   player_class = { M1=p_class[QTR_class].M1, D1=p_class[QTR_class].D1, C1=p_class[QTR_class].C1, B1=p_class[QTR_class].B1, N1=p_class[QTR_class].N1, K1=p_class[QTR_class].K1, W1=p_class[QTR_class].W1, M2=p_class[QTR_class].M2, D2=p_class[QTR_class].D2, C2=p_class[QTR_class].C2, B2=p_class[QTR_class].B2, N2=p_class[QTR_class].N2, K2=p_class[QTR_class].K2, W2=p_class[QTR_class].W2 };
else
   player_class = { M1=QTR_class, D1=QTR_class, C1=QTR_class, B1=QTR_class, N1=QTR_class, K1=QTR_class, W1=QTR_class, M2=QTR_class, D2=QTR_class, C2=QTR_class, B2=QTR_class, N2=QTR_class, K2=QTR_class, W2=QTR_class };
   DEFAULT_CHAT_FRAME:AddMessage("|cff55ff00QTR - كلاس جديد: "..QTR_class);
end



local function QTR_TrimPlaceholderText(text)
   return string.gsub(text or "", "^%s*(.-)%s*$", "%1")
end


local function QTR_SelectGenderText(sex, masc, fem)
   masc = QTR_TrimPlaceholderText(masc)
   fem = QTR_TrimPlaceholderText(fem)
   return (sex == 3) and fem or masc
end


   local function QTR_ResolveGenderPlaceholders(text, npcSex)
      if (not text or text == "") then
         return text or "";
      end

      npcSex = npcSex or UnitSex("npc")
      text = Spr_Gender(text);
      text = string.gsub(text, "NPC_GENDER%s*%(([^;]*);([^)]*)%)", function(masc, fem)
         return QTR_SelectGenderText(npcSex, masc, fem)
      end)
      return text;
   end


function Spr_Gender(msg)
   local function replaceGenderToken(patternPrefix, terminator)
      msg = string.gsub(msg, patternPrefix.."%s*(.-)%s*:%s*(.-)%s*"..terminator, function(masc, fem)
         return QTR_SelectGenderText(QTR_sex, masc, fem)
      end)
   end

   replaceGenderToken("%$[gG]", ";")
   replaceGenderToken("%$[gG]", "؛")
   replaceGenderToken("%$[tT]", ";")
   replaceGenderToken("%$[tT]", "؛")

   msg = string.gsub(msg, "%$[tT]%s*(.-)%s*;", "%1")
   msg = string.gsub(msg, "%$[tT]%s*(.-)%s*؛", "%1")

   -- Replace {g} masc : fem ; or ؛
   msg = string.gsub(msg, "{[gG]}%s*(.-)%s*:%s*(.-)%s*;", function(masc, fem)
      return QTR_SelectGenderText(QTR_sex, masc, fem)
   end)
   msg = string.gsub(msg, "{[gG]}%s*(.-)%s*:%s*(.-)%s*؛", function(masc, fem)
      return QTR_SelectGenderText(QTR_sex, masc, fem)
   end)
   -- Replace {g masc : fem} or {G masc : fem}
   msg = string.gsub(msg, "{[gG]%s*([^:}]*)%s*:%s*([^}]*)}", function(masc, fem)
      return QTR_SelectGenderText(QTR_sex, masc, fem)
   end)
   -- YOUR_GENDER(x;y)
   msg = string.gsub(msg, "YOUR_GENDER%s*%(([^;]*);([^)]*)%)", function(masc, fem)
      return QTR_SelectGenderText(QTR_sex, masc, fem)
   end)
   msg = string.gsub(msg, "%s+%$[gG]%s*([%.!,%?:])", "%1")
   msg = string.gsub(msg, "%$[gG]%s*([%.!,%?:])", "%1")
   msg = string.gsub(msg, "%s+%$[gG]%s*،", "،")
   msg = string.gsub(msg, "%$[gG]%s*،", "،")
   msg = string.gsub(msg, "%s+%$[gG]%s*؛", "؛")
   msg = string.gsub(msg, "%$[gG]%s*؛", "؛")
   msg = string.gsub(msg, "%s+%$[gG]%s*$", "")
   msg = string.gsub(msg, "  +", " ")

   return msg;
end


-- Compute a stable text hash used for gossip and lookup caches.
local function StringHash(text)           -- a function that creates a Hash (32-bit number) of the given text
  local counter = 1;
  local pomoc = 0;
  local dlug = string.len(text);
  for i = 1, dlug, 3 do 
    counter = math.fmod(counter*8161, 4294967279);  -- 2^32 - 17: Prime!
    pomoc = (string.byte(text,i)*16776193);
    counter = counter + pomoc;
    pomoc = ((string.byte(text,i+1) or (dlug-i+256))*8372226);
    counter = counter + pomoc;
    pomoc = ((string.byte(text,i+2) or (dlug-i+256))*3932164);
    counter = counter + pomoc;
  end
  return math.fmod(counter, 4294967291) -- 2^32 - 5: Prime (and different from the prime in the loop)
end


-- Reverse Arabic text only when the content actually needs RTL shaping.
local function QTR_ReverseText(text)
  if (not text or text == "") then
     return text or "";
  end
  if (AS_ContainsArabic and AS_ContainsArabic(text)) then
     return AS_UTF8reverse(text);
  end
  return text;
end


-- Show addon status text in a dedicated Arabic-font overlay so the main chat keeps its own font.
local QTR_SystemMessageFrame = nil;
local QTR_SystemMessageText = nil;
local QTR_SystemMessageSerial = 0;


local function QTR_EnsureSystemMessageFrame()
  if (QTR_SystemMessageFrame and QTR_SystemMessageText) then
     return true;
  end

  local parentFrame = DEFAULT_CHAT_FRAME or UIParent;
  if (not parentFrame) then
     return false;
  end

  QTR_SystemMessageFrame = CreateFrame("Frame", "QTR_SystemMessageFrame", parentFrame);
  QTR_SystemMessageFrame:SetFrameStrata("HIGH");
  QTR_SystemMessageFrame:SetClampedToScreen(true);
  QTR_SystemMessageFrame:ClearAllPoints();
  if (DEFAULT_CHAT_FRAME) then
     QTR_SystemMessageFrame:SetPoint("BOTTOMLEFT", DEFAULT_CHAT_FRAME, "TOPLEFT", 0, 6);
  else
     QTR_SystemMessageFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 32, 220);
  end
  QTR_SystemMessageFrame:SetWidth((DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME:GetWidth() and DEFAULT_CHAT_FRAME:GetWidth() > 0 and DEFAULT_CHAT_FRAME:GetWidth()) or 360);
  QTR_SystemMessageFrame:SetHeight(24);
  QTR_SystemMessageFrame:Hide();

  QTR_SystemMessageText = QTR_SystemMessageFrame:CreateFontString(nil, "OVERLAY");
  QTR_SystemMessageText:ClearAllPoints();
  QTR_SystemMessageText:SetPoint("TOPLEFT", QTR_SystemMessageFrame, "TOPLEFT", 0, 0);
  QTR_SystemMessageText:SetPoint("BOTTOMRIGHT", QTR_SystemMessageFrame, "BOTTOMRIGHT", 0, 0);
   QTR_SystemMessageText:SetFont(QTR_Font2, 13);
  QTR_SystemMessageText:SetJustifyH("LEFT");
  QTR_SystemMessageText:SetJustifyV("MIDDLE");
  QTR_SystemMessageText:SetText("");
  return true;
end


local function QTR_ShowSystemOverlayMessage(message)
  if (not QTR_EnsureSystemMessageFrame()) then
     return false;
  end

  local fontSize = 13;
  local fontFlags = "";
  if (DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.GetFont) then
     local _, currentSize, currentFlags = DEFAULT_CHAT_FRAME:GetFont();
     if (currentSize) then
        fontSize = currentSize;
     end
     fontFlags = currentFlags or "";
  end

  if (DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.GetWidth) then
     local chatWidth = DEFAULT_CHAT_FRAME:GetWidth();
     if (chatWidth and chatWidth > 0) then
        QTR_SystemMessageFrame:SetWidth(chatWidth);
     end
  end

  QTR_SystemMessageText:SetFont(QTR_Font2, fontSize, fontFlags);
  QTR_SystemMessageText:SetJustifyH("LEFT");
  QTR_SystemMessageText:SetText(message or "");
  QTR_SystemMessageFrame:Show();

  QTR_SystemMessageSerial = QTR_SystemMessageSerial + 1;
  local currentSerial = QTR_SystemMessageSerial;
  if (QTR_wait) then
     QTR_wait(4, function(serial)
        if (QTR_SystemMessageFrame and serial == QTR_SystemMessageSerial) then
           QTR_SystemMessageFrame:Hide();
        end
     end, currentSerial);
  end

  return true;
end


-- Send addon status text without changing the font of the user's main chat frame.
local function QTR_AddLocalizedSystemMessage(prefixText, localizedText)
  local message = prefixText or "";
  local displayText = localizedText or "";

  if (displayText ~= "" and AS_ContainsArabic and AS_ContainsArabic(displayText)) then
     displayText = QTR_ReverseText(displayText);
  end

  message = message .. displayText;

  if (displayText ~= "" and AS_ContainsArabic and AS_ContainsArabic(localizedText or "")) then
     if (QTR_ShowSystemOverlayMessage(message)) then
        return;
     end
  end

  if (DEFAULT_CHAT_FRAME) then
     DEFAULT_CHAT_FRAME:AddMessage(message);
     return;
  end

  if (UIErrorsFrame) then
     UIErrorsFrame:AddMessage(message, 1.0, 1.0, 1.0, 1.0, UIERRORS_HOLD_TIME);
  end
end


-- Tolerant UTF-8 reader shared by quest text shaping.
local function QTR_GetSafeUtf8Char(text, pos)
  if (not text or text == "") then
     return "", 1, false;
  end

  local c = strbyte(text, pos);
  if (not c) then
     return "", 1, false;
  end

  local charbytes = 1;
  local isValid = true;

  if (c > 0 and c <= 127) then
     charbytes = 1;
  elseif (c >= 194 and c <= 223) then
     local c2 = strbyte(text, pos + 1);
     if (c2 and c2 >= 128 and c2 <= 191) then
        charbytes = 2;
     else
        isValid = false;
     end
  elseif (c >= 224 and c <= 239) then
     local c2 = strbyte(text, pos + 1);
     local c3 = strbyte(text, pos + 2);

     if (not c2 or not c3) then
        isValid = false;
     elseif (c == 224 and (c2 < 160 or c2 > 191)) then
        isValid = false;
     elseif (c == 237 and (c2 < 128 or c2 > 159)) then
        isValid = false;
     elseif (c2 < 128 or c2 > 191) then
        isValid = false;
     elseif (c3 < 128 or c3 > 191) then
        isValid = false;
     else
        charbytes = 3;
     end
  elseif (c >= 240 and c <= 244) then
     local c2 = strbyte(text, pos + 1);
     local c3 = strbyte(text, pos + 2);
     local c4 = strbyte(text, pos + 3);

     if (not c2 or not c3 or not c4) then
        isValid = false;
     elseif (c == 240 and (c2 < 144 or c2 > 191)) then
        isValid = false;
     elseif (c == 244 and (c2 < 128 or c2 > 143)) then
        isValid = false;
     elseif (c2 < 128 or c2 > 191) then
        isValid = false;
     elseif (c3 < 128 or c3 > 191) then
        isValid = false;
     elseif (c4 < 128 or c4 > 191) then
        isValid = false;
     else
        charbytes = 4;
     end
  else
     isValid = false;
  end

  if (not isValid) then
     return "", 1, false;
  end

  return string.sub(text, pos, pos + charbytes - 1), charbytes, true;
end


-- Wrap and reverse a text block line by line for right-to-left rendering.
local function QTR_LineReverse(text, limit)
  local retstr = "";
  if (text and limit) then
     local bytes = strlen(text);
     local pos = 1;
     local newstr = "";
     local counter = 0;
     while (pos <= bytes) do
        local char1, charbytes = QTR_GetSafeUtf8Char(text, pos);
        pos = pos + charbytes;

        if (char1 == "") then
           if (pos > bytes) then
              break;
           end
        else
           newstr = newstr .. char1;

           counter = counter + 1;
           if ((char1 >= "A") and (char1 <= "z")) then
              counter = counter + 1;
           end
           if ((char1 == "#") or ((char1 == " ") and (counter > limit))) then
              newstr = string.gsub(newstr, "#", "");
              retstr = retstr .. AS_UTF8reverse(newstr) .. "\n";
              newstr = "";
              counter = 0;
           end
        end
     end
     retstr = retstr .. AS_UTF8reverse(newstr);
     retstr = string.gsub(retstr, "#", "");
     retstr = string.gsub(retstr, "\n ", "\n");
     retstr = string.gsub(retstr, "\n\n\n", "\n\n");
  end
  return retstr;
end


-- Normalize multiline quest text before feeding it into the RTL line shaper.
local function QTR_ReverseBodyText(text, limit)
  if (not text or text == "") then
     return text or "";
  end
  text = QTR_ResolveGenderPlaceholders(text);
  if (not AS_ContainsArabic or not AS_ContainsArabic(text)) then
     return text;
  end
  text = string.gsub(text, "\r\n", "\n");
  text = string.gsub(text, "\r", "\n");
  text = string.gsub(text, "\n", "#");
  return QTR_LineReverse(text, limit);
end


function QTR_PrepareWrappedArabicText(text, width, fontName, fontSize)
  if (not text or text == "") then
     return text or "";
  end

  if (not AS_ContainsArabic or not AS_ContainsArabic(text)) then
     return text;
  end

  if (width and width > 0 and AS_ReverseAndPrepareLineText) then
     local wrappedText = string.gsub(text, "\r\n", "#");
     wrappedText = string.gsub(wrappedText, "\r", "#");
     wrappedText = string.gsub(wrappedText, "\n", "#");
     return AS_ReverseAndPrepareLineText(wrappedText, width, fontName or QTR_Font2, fontSize or 13);
  end

  return QTR_ReverseText(text);
end


local QTR_FontStringWidthCache = {};
local QTR_RTLWidthAdjustments = {
   GossipGreetingText = 0,
   QuestProgressText = 10,
   QuestProgressRequiredItemsText = -10,
};


local function QTR_GetRTLWidthAdjustment(fontString, ownerFrame)
  if (not fontString) then
     return nil;
  end

  local fontStringName = fontString.GetName and fontString:GetName();
  if (fontStringName and QTR_RTLWidthAdjustments[fontStringName]) then
     return QTR_RTLWidthAdjustments[fontStringName];
  end

  return nil;
end


local function QTR_ApplyRTLWidthAdjustment(fontString, useArabicLayout, ownerFrame)
  if (not fontString or not fontString.GetName) then
     return;
  end

  local widthAdjustment = QTR_GetRTLWidthAdjustment(fontString, ownerFrame);
  if (not widthAdjustment) then
     return;
  end

  local baseWidth = QTR_FontStringWidthCache[fontString];
  local currentWidth = fontString:GetWidth();
  if ((not baseWidth or baseWidth <= 0) and currentWidth and currentWidth > 0) then
     baseWidth = currentWidth;
     QTR_FontStringWidthCache[fontString] = currentWidth;
  end

  if (not baseWidth or baseWidth <= 0) then
     return;
  end

  if (useArabicLayout) then
     fontString:SetWidth(baseWidth + widthAdjustment);
  else
     fontString:SetWidth(baseWidth);
  end
end


-- Apply fonts, alignment, and Arabic shaping through one shared display helper.
function QTR_SetShapedText(fontString, text, fontName, fontSize, limit)
  fontString:SetFont(fontName, fontSize);
  if (text and AS_ContainsArabic and AS_ContainsArabic(text)) then
     QTR_ApplyRTLWidthAdjustment(fontString, true);
     fontString:SetJustifyH("RIGHT");
     if (limit) then
        fontString:SetText(QTR_ReverseBodyText(text, limit));
     else
        fontString:SetText(QTR_ReverseText(text));
     end
  else
     QTR_ApplyRTLWidthAdjustment(fontString, false);
     fontString:SetJustifyH("LEFT");
     fontString:SetText(text or "");
  end
end


function QTR_SetShapedTitleText(fontString, text, fontName, fontSize, width)
  fontString:SetFont(fontName, fontSize);
  if (text and AS_ContainsArabic and AS_ContainsArabic(text)) then
     QTR_ApplyRTLWidthAdjustment(fontString, true);
     fontString:SetJustifyH("RIGHT");
     local wrapWidth = width;
     if ((not wrapWidth or wrapWidth <= 0) and fontString.GetWidth) then
        wrapWidth = fontString:GetWidth();
     end
     fontString:SetText(QTR_PrepareWrappedArabicText(text, wrapWidth, fontName, fontSize));
  else
     QTR_ApplyRTLWidthAdjustment(fontString, false);
     fontString:SetJustifyH("LEFT");
     fontString:SetText(text or "");
  end
end


-- Reverse UTF-8 text with the reshaper helper, or fall back to raw reversal.
local function QTR_ReverseUTF8Text(text)
  if (not text or text == "") then
     return text or "";
  end
  if (AS_UTF8reverse) then
     return AS_UTF8reverse(text);
  end
  return string.reverse(text);
end


-- Detect legacy reversed Latin words so mixed titles do not get flipped twice.
local function QTR_IsLegacyReversedLatinTitle(text)
  if (not text or text == "") then
     return false;
  end
  if (string.find(text, "[A-Za-z]") == nil) then
     return false;
  end

  for word in string.gmatch(text, "%S+") do
     local firstLetter = string.match(word, "[A-Za-z]");
     local lastLetter = string.match(word, ".*([A-Za-z])");
     if (firstLetter and lastLetter and string.find(firstLetter, "%l") and string.find(lastLetter, "%u")) then
        return true;
     end
  end

  return false;
end


-- Normalize translated quest titles that mix Arabic with Latin tokens.
local function QTR_NormalizeTranslatedTitle(text)
  if (not text or text == "") then
     return text or "";
  end

  if (AS_ContainsArabic and AS_ContainsArabic(text)) then
     return string.gsub(text, "[A-Za-z][A-Za-z'%-]*", function(token)
        if (QTR_IsLegacyReversedLatinTitle(token)) then
           return token;
        end
        return QTR_ReverseUTF8Text(token);
     end);
  end

  if (QTR_IsLegacyReversedLatinTitle(text)) then
     return QTR_ReverseUTF8Text(text);
  end
  return text or "";
end


-- Fetch, expand, and normalize a translated quest title by quest ID.
function QTR_GetTranslatedQuestTitleById(questId)
  if (questId and QTR_QuestData[questId] and QTR_QuestData[questId]["Title"]) then
     return QTR_NormalizeTranslatedTitle(QTR_ExpandUnitInfo(QTR_QuestData[questId]["Title"]));
  end
  return nil;
end


-- Expand gossip placeholders through the shared text placeholder engine.
local function QTR_ExpandGossipInfo(msg)
  if (not msg or msg == "") then
     return msg or "";
  end

  msg = string.gsub(msg, "^@DI", "");
  msg = string.gsub(msg, "^@OP", "");

  msg = QTR_ExpandUnitInfo(msg);
  msg = string.gsub(msg, "\r\n", "#");
  msg = string.gsub(msg, "\r", "#");
  msg = string.gsub(msg, "\n", "#");
  return msg;
end


-- Prepare gossip text for display, including wrapping for Arabic buttons.
local function QTR_PrepareGossipDisplayText(msg, width, fontSize, fontName)
  local expanded = QTR_ExpandGossipInfo(msg);
  if (expanded == "") then
     return expanded;
  end

  if (AS_ContainsArabic and AS_ContainsArabic(expanded) and width and width > 0) then
     return AS_ReverseAndPrepareLineText(expanded, width, fontName or QTR_Font1 or QTR_Font2, fontSize);
  end

  return string.gsub(expanded, "#", "\n");
end


local QTR_GossipWrapWarmupDone = false;


local function QTR_PrepareShownGossipDisplayText(msg, width, fontSize, fontName)
   if (not QTR_GossipWrapWarmupDone) then
       QTR_GossipWrapWarmupDone = true;
      QTR_PrepareGossipDisplayText(msg, width, fontSize, fontName);
   end

   return QTR_PrepareGossipDisplayText(msg, width, fontSize, fontName);
end


-- Normalize live gossip text into the same hash source used by the database.
local function QTR_NormalizeGossipHashText(text)
   local hashText = text or "";
   hashText = string.gsub(hashText, '\r', '');
   hashText = string.gsub(hashText, '\n', '$B');
   hashText = string.gsub(hashText, QTR_name, '$N');
   hashText = string.gsub(hashText, string.upper(QTR_name), '$N$');
   hashText = string.gsub(hashText, QTR_race, '$R');
   hashText = string.gsub(hashText, string.lower(QTR_race), '$R');
   hashText = string.gsub(hashText, QTR_class, '$C');
   hashText = string.gsub(hashText, string.lower(QTR_class), '$C');
   hashText = string.gsub(hashText, '$N$', '');
   hashText = string.gsub(hashText, '$N', '');
   hashText = string.gsub(hashText, '$B', '');
   hashText = string.gsub(hashText, '$b', '');
   hashText = string.gsub(hashText, '$R', '');
   hashText = string.gsub(hashText, '$C', '');
   -- Collapse runs of whitespace to a single space and trim ends so that
   -- spacing differences (e.g. 2 vs 4 spaces around line-breaks) never
   -- produce different hash values for the same NPC greeting text.
   hashText = string.gsub(hashText, '%s+', ' ');
   hashText = string.gsub(hashText, '^%s+', '');
   hashText = string.gsub(hashText, '%s+$', '');
   return hashText;
end


local function QTR_IsArabicGossipText(text)
   return (type(text) == "string" and text ~= "" and AS_ContainsArabic and AS_ContainsArabic(text));
end


local function QTR_ExtractSavedGossipSourceText(value)
   if (type(value) ~= "string" or value == "") then
      return nil;
   end

   local sourceText = string.match(value, "^(.*)@[^@]*:[^:]*:[^:]*$");
   if (sourceText and sourceText ~= "") then
      return sourceText;
   end

   return value;
end


local function QTR_SanitizeSavedGossipEntries()
   if (not QTR_GOSSIP) then
      return 0;
   end

   local staleKeys = {};
   for gossipKey, gossipValue in pairs(QTR_GOSSIP) do
      local sourceText = QTR_ExtractSavedGossipSourceText(gossipValue);
      if (QTR_IsArabicGossipText(sourceText)) then
         table.insert(staleKeys, gossipKey);
      end
   end

   for _, gossipKey in ipairs(staleKeys) do
      QTR_GOSSIP[gossipKey] = nil;
   end

   return #staleKeys;
end


local function QTR_SaveHarvestedGossipText(npcName, hash, gossipText)
   if (not QTR_GOSSIP or not npcName or not hash) then
      return false;
   end
   if (type(gossipText) ~= "string" or gossipText == "" or QTR_IsArabicGossipText(gossipText)) then
      return false;
   end

   QTR_GOSSIP[npcName.."@"..tostring(hash)] = gossipText.."@"..QTR_name..":"..QTR_race..":"..QTR_class;
   return true;
end


local function QTR_GetOriginalGossipOptionText(titleButton)
   if (not titleButton) then
      return nil;
   end

   if (type(GetGossipOptions) == "function" and titleButton.GetID) then
      local optionIndex = titleButton:GetID();
      if (optionIndex and optionIndex > 0) then
         local optionText = select(((optionIndex - 1) * 2) + 1, GetGossipOptions());
         if (type(optionText) == "string" and optionText ~= "") then
            return optionText;
         end
      end
   end

   local buttonText = titleButton:GetText();
   if (type(buttonText) == "string" and buttonText ~= "" and not QTR_IsArabicGossipText(buttonText)) then
      return buttonText;
   end

   return nil;
end


-- Apply translated text and alignment rules to a quest or gossip title button.
local QTR_TitleButtonAnchorCache = {};
local QTR_TitleButtonFontCache = {};


local function QTR_IsQuestTitleButtonName(titleButtonName)
   return (titleButtonName and (string.find(titleButtonName, "^QuestTitleButton") or string.find(titleButtonName, "^GuildRegistrarButton") or string.find(titleButtonName, "^ArenaRegistrarButton")));
end


local function QTR_SetTitleButtonText(titleButton, text, fontName, fontSize)
  titleButton:SetText(text or "");

  local fontString = titleButton:GetFontString();
  if (fontString) then
     if (not QTR_TitleButtonFontCache[titleButton]) then
        local originalFont, originalSize, originalFlags = fontString:GetFont();
        QTR_TitleButtonFontCache[titleButton] = {
           font = originalFont,
           size = originalSize,
           flags = originalFlags,
           justify = fontString:GetJustifyH(),
        };
     end

     fontString:SetFont(fontName, fontSize);
     local titleButtonName = titleButton:GetName();
   local isQuestTitleButton = QTR_IsQuestTitleButtonName(titleButtonName);
     local isGossipTitleButton = titleButtonName and string.find(titleButtonName, "^GossipTitleButton");

     if ((isQuestTitleButton or isGossipTitleButton) and not QTR_TitleButtonAnchorCache[titleButton]) then
        local pointCount = fontString:GetNumPoints();
        local savedPoints = {};
        for index = 1, pointCount do
           savedPoints[index] = { fontString:GetPoint(index) };
        end
        QTR_TitleButtonAnchorCache[titleButton] = savedPoints;
     end

     if (text and AS_ContainsArabic and AS_ContainsArabic(text)) then
        QTR_ApplyRTLWidthAdjustment(fontString, true, titleButton);
        fontString:SetJustifyH("RIGHT");
        if (isQuestTitleButton) then
           fontString:ClearAllPoints();
           fontString:SetPoint("TOPLEFT", titleButton, "TOPLEFT", 0, 0);
           fontString:SetPoint("TOPRIGHT", titleButton, "TOPRIGHT", -10, 0);
        elseif (isGossipTitleButton) then
           fontString:ClearAllPoints();
           fontString:SetPoint("LEFT", titleButton, "LEFT", 10, 0);
        end
     else
        QTR_ApplyRTLWidthAdjustment(fontString, false, titleButton);
        fontString:SetJustifyH("LEFT");
        if ((isQuestTitleButton or isGossipTitleButton) and QTR_TitleButtonAnchorCache[titleButton]) then
           fontString:ClearAllPoints();
           for _, pointData in ipairs(QTR_TitleButtonAnchorCache[titleButton]) do
              fontString:SetPoint(unpack(pointData));
           end
        end
     end
  end
end


local function QTR_RestoreTitleButtonFont(titleButton)
  if (not titleButton) then
     return;
  end

  local fontString = titleButton:GetFontString();
  if (not fontString) then
     return;
  end

  local fontData = QTR_TitleButtonFontCache[titleButton];
  if (fontData and fontData.font and fontData.size) then
     fontString:SetFont(fontData.font, fontData.size, fontData.flags);
     fontString:SetJustifyH(fontData.justify or "LEFT");
  else
     fontString:SetFont(Original_Font2, 13);
     fontString:SetJustifyH("LEFT");
  end

  QTR_ApplyRTLWidthAdjustment(fontString, false, titleButton);

  local titleButtonName = titleButton:GetName();
  local isQuestTitleButton = QTR_IsQuestTitleButtonName(titleButtonName);
  local isGossipTitleButton = titleButtonName and string.find(titleButtonName, "^GossipTitleButton");
  if ((isQuestTitleButton or isGossipTitleButton) and QTR_TitleButtonAnchorCache[titleButton]) then
     fontString:ClearAllPoints();
     for _, pointData in ipairs(QTR_TitleButtonAnchorCache[titleButton]) do
        fontString:SetPoint(unpack(pointData));
     end
  end
end


-- Measure the usable width for wrapped gossip options after icon padding.
local function QTR_GetGossipOptionWidth(titleButton)
  local optionWidth = titleButton:GetWidth();
  local buttonIcon = _G[titleButton:GetName() .. "GossipIcon"];
  if (buttonIcon) then
     optionWidth = optionWidth - buttonIcon:GetWidth() - QTR_GossipOptionIconPadding;
  end
  if (optionWidth < QTR_GossipOptionMinWidth) then
     optionWidth = titleButton:GetWidth();
  end
  return optionWidth;
end


local function QTR_GetQuestLogTitleWidth(titleButton)
  local optionWidth = (titleButton:GetWidth() or 0) - QTR_QuestLogTitleBasePadding;
  local questTitleTag = titleButton.tag;
  local questCheck = titleButton.check;

  if (questTitleTag and questTitleTag:IsShown()) then
     optionWidth = optionWidth - questTitleTag:GetWidth() - QTR_QuestLogTitleTagPadding;
  end
  if (questCheck and questCheck:IsShown()) then
     optionWidth = optionWidth - questCheck:GetWidth() - QTR_QuestLogTitleCheckPadding;
  end

  if (optionWidth < QTR_QuestLogTitleMinWidth) then
     optionWidth = titleButton:GetWidth();
  end
  return optionWidth;
end


-- Measure the usable width for quest title buttons after icon padding.
local function QTR_GetQuestButtonWidth(titleButton)
  local optionWidth = titleButton:GetWidth();
  local buttonIcon = _G[titleButton:GetName() .. "QuestIcon"];
  if (buttonIcon) then
     optionWidth = optionWidth - buttonIcon:GetWidth() - QTR_QuestTitleIconPadding;
  end
  if (optionWidth < QTR_QuestTitleMinWidth) then
     optionWidth = titleButton:GetWidth();
  end
  return optionWidth;
end


local function QTR_PrepareTitleButtonArabicText(titleButton, text, fontName, fontSize)
  if (not titleButton) then
     return text or "";
  end

  local titleButtonName = titleButton:GetName();
  local optionWidth = nil;
  if (titleButtonName and string.find(titleButtonName, "^QuestLogScrollFrameButton")) then
     optionWidth = QTR_GetQuestLogTitleWidth(titleButton);
  elseif (QTR_IsQuestTitleButtonName(titleButtonName)) then
     optionWidth = QTR_GetQuestButtonWidth(titleButton);
  elseif (titleButtonName and string.find(titleButtonName, "^GossipTitleButton")) then
     optionWidth = QTR_GetGossipOptionWidth(titleButton);
  end

  if ((not optionWidth or optionWidth <= 0) and titleButton.GetFontString) then
     local fontString = titleButton:GetFontString();
     if (fontString and fontString.GetWidth) then
        optionWidth = fontString:GetWidth();
     end
  end

  return QTR_PrepareWrappedArabicText(text, optionWidth, fontName, fontSize);
end


-- Pick the best translated title for a quest list entry with possible duplicate IDs.
function QTR_GetQuestTitleTranslation(titleText)
  if (not titleText or titleText == "") then
     return nil;
  end

  local lookupTitle = QTR_GetQuestTitleFromDisplayText(titleText) or titleText;
  local questIds = QTR_QuestList[lookupTitle];
  if (not questIds) then
     return nil;
  end

  local selectedQuestId = nil;
  if (string.find(questIds, ",") == nil) then
     selectedQuestId = questIds;
  else
     for questId in string.gmatch(questIds, "[^,]+") do
        if (not QTR_PC[questId]) then
           selectedQuestId = questId;
           break;
        end
        if (not selectedQuestId) then
           selectedQuestId = questId;
        end
     end
  end

  if (selectedQuestId and QTR_QuestData[selectedQuestId] and QTR_QuestData[selectedQuestId]["Title"]) then
     return QTR_GetTranslatedQuestTitleById(selectedQuestId);
  end

  return nil;
end
function QTR_GetQuestTitleFromDisplayText(displayText)
  if (not displayText or displayText == "") then
     return nil;
  end

  local plainText = string.gsub(displayText, "|c%x%x%x%x%x%x%x%x", "");
  plainText = string.gsub(plainText, "|r", "");

  if (QTR_QuestList[plainText]) then
     return plainText;
  end

  local strippedText = string.gsub(plainText, "^%[[^%]]+%]%s*", "");
  if (QTR_QuestList[strippedText]) then
     return strippedText;
  end

  local trivialText = string.gsub(strippedText, "%s*%([Ll]ow [Ll]evel%)%s*$", "");
  if (QTR_QuestList[trivialText]) then
     return trivialText;
  end

  return nil;
end


local function QTR_ExtractLeadingDisplayControlCodes(text)
  local controlPrefix = "";
  local visibleText = text or "";

  while (visibleText ~= "") do
     local colorCode = string.match(visibleText, "^(|c%x%x%x%x%x%x%x%x)");
     if (colorCode and colorCode ~= "") then
        controlPrefix = controlPrefix .. colorCode;
        visibleText = string.sub(visibleText, string.len(colorCode) + 1);
     else
        break;
     end
  end

  return controlPrefix, visibleText;
end


function QTR_PrepareExternalQuestTitleDisplay(questId, displayText, originalTitle, width, fontName, fontSize, measureFontName, rtlTitleFirst)
  if (not QTR_PS or QTR_PS["active"] ~= "1" or QTR_PS["transtitle"] ~= "1") then
     return nil;
  end

   local shapedFontName = fontName or QTR_Font1 or QTR_Font2;
   local measuredFontName = measureFontName or fontName or QTR_Font1 or QTR_Font2;

  local translatedQuestTitle = nil;
  if (questId) then
     translatedQuestTitle = QTR_GetTranslatedQuestTitleById(tostring(questId));
  end
  if (not translatedQuestTitle and originalTitle and originalTitle ~= "") then
     translatedQuestTitle = QTR_GetQuestTitleTranslation(originalTitle);
  end
  if (not translatedQuestTitle) then
     return nil;
  end

  local translatedDisplayTitle = translatedQuestTitle;
  if (width and width > 0) then
     local titleWidth = width;
     if (displayText and originalTitle and originalTitle ~= "") then
        local titleStart, titleEnd = string.find(displayText, originalTitle, 1, true);
        if (titleStart and titleEnd) then
           if (AS_TestLine == nil and AS_CreateTestLine) then
              AS_CreateTestLine();
           end
           if (AS_TestLine and AS_TestLine.text) then
              AS_TestLine.text:SetFont(measuredFontName, fontSize or 13);
              AS_TestLine.text:SetText(string.sub(displayText, 1, titleStart - 1));
              titleWidth = titleWidth - (AS_TestLine.text:GetStringWidth() or 0);
              AS_TestLine.text:SetText(string.sub(displayText, titleEnd + 1));
              titleWidth = titleWidth - (AS_TestLine.text:GetStringWidth() or 0);
           end
        end
     end
     if (titleWidth < 40) then
        titleWidth = width;
     end
     translatedDisplayTitle = QTR_PrepareWrappedArabicText(translatedQuestTitle, titleWidth, shapedFontName, fontSize or 13);
  end

  if (not displayText or displayText == "" or not originalTitle or originalTitle == "") then
     return translatedDisplayTitle;
  end

  local titleStart, titleEnd = string.find(displayText, originalTitle, 1, true);
  if (titleStart and titleEnd) then
     local prefixText = string.sub(displayText, 1, titleStart - 1);
     local suffixText = string.sub(displayText, titleEnd + 1);

     if (rtlTitleFirst and AS_ContainsArabic and AS_ContainsArabic(translatedQuestTitle)) then
        local controlPrefix, visiblePrefix = QTR_ExtractLeadingDisplayControlCodes(prefixText);
        return controlPrefix .. translatedDisplayTitle .. visiblePrefix .. suffixText;
     end

     return prefixText .. translatedDisplayTitle .. suffixText;
  end

  return translatedDisplayTitle;
end


function QTR_SelectQuestIdFromTitle(titleText)
  if (not titleText or titleText == "" or not QTR_QuestList) then
     return nil;
  end

  local questIds = QTR_QuestList[titleText];
  if (not questIds) then
     return nil;
  end

  local selectedQuestId = nil;
  if (string.find(questIds, ",") == nil) then
     selectedQuestId = questIds;
  else
     for questId in string.gmatch(questIds, "[^,]+") do
        if (not QTR_PC[questId]) then
           selectedQuestId = questId;
           break;
        end
        if (not selectedQuestId) then
           selectedQuestId = questId;
        end
     end
  end

  if (selectedQuestId and selectedQuestId ~= "") then
     return tostring(selectedQuestId);
  end

  return nil;
end


local function QTR_GetQuestDataFromTitle(titleText)
  local questId = QTR_SelectQuestIdFromTitle(titleText);
  if (questId and QTR_QuestData and QTR_QuestData[questId]) then
     return questId, QTR_QuestData[questId];
  end
  return nil, nil;
end


local function QTR_GetExternalQuestTextTranslation(eventName, titleText)
  if (not QTR_PS or QTR_PS["active"] ~= "1") then
     return nil, nil;
  end

  local fieldByEvent = {
     QUEST_DETAIL = "Description",
     QUEST_PROGRESS = "Progress",
     QUEST_COMPLETE = "Completion",
  };
  local fieldName = fieldByEvent[eventName];
  if (not fieldName) then
     return nil, nil;
  end

  local questId, questData = QTR_GetQuestDataFromTitle(titleText or "");
  if (questData and questData[fieldName]) then
     return QTR_ExpandUnitInfo(questData[fieldName]), questId;
  end

  return nil, questId;
end


function QTR_GetExternalQuestTextTranslationFromSource(titleText, sourceText)
  if (type(sourceText) ~= "string" or sourceText == "") then
     return nil, nil, nil;
  end

  if (type(GetQuestText) == "function") then
     local currentQuestText = GetQuestText();
     if (currentQuestText and currentQuestText ~= "" and currentQuestText == sourceText) then
        local translatedText, questId = QTR_GetExternalQuestTextTranslation("QUEST_DETAIL", titleText);
        return translatedText, questId, "QUEST_DETAIL";
     end
  end

  if (type(GetProgressText) == "function") then
     local currentProgressText = GetProgressText();
     if (currentProgressText and currentProgressText ~= "" and currentProgressText == sourceText) then
        local translatedText, questId = QTR_GetExternalQuestTextTranslation("QUEST_PROGRESS", titleText);
        return translatedText, questId, "QUEST_PROGRESS";
     end
  end

  if (type(GetRewardText) == "function") then
     local currentRewardText = GetRewardText();
     if (currentRewardText and currentRewardText ~= "" and currentRewardText == sourceText) then
        local translatedText, questId = QTR_GetExternalQuestTextTranslation("QUEST_COMPLETE", titleText);
        return translatedText, questId, "QUEST_COMPLETE";
     end
  end

  return nil, QTR_SelectQuestIdFromTitle(titleText), nil;
end


function QTR_GetExternalQuestObjectivesTranslation(titleText)
  if (not QTR_PS or QTR_PS["active"] ~= "1") then
     return nil, nil;
  end

  local questId, questData = QTR_GetQuestDataFromTitle(titleText or "");
  if (questData and questData["Objectives"]) then
     return QTR_ExpandUnitInfo(questData["Objectives"]), questId;
  end

  return nil, questId;
end


local function QTR_GetRawGossipTranslation(originalText, useNormalizedHash)
  if (not QTR_PS or QTR_PS["gossip"] ~= "1") then
     return nil, nil;
  end
  if (type(originalText) ~= "string" or originalText == "") then
     return nil, nil;
  end

  local hashSource = originalText;
  if (useNormalizedHash) then
     hashSource = QTR_NormalizeGossipHashText(originalText);
  end

  local hash = StringHash(hashSource);
  if (GS_Gossip and GS_Gossip[hash]) then
     local translatedText = QTR_ExpandGossipInfo(GS_Gossip[hash]);
     translatedText = string.gsub(translatedText, "#", "\n");
     return translatedText, hash;
  end

  return nil, hash;
end


function QTR_GetExternalGossipBodyTranslation(originalText, useNormalizedHash)
  local translatedText, hash = QTR_GetRawGossipTranslation(originalText, useNormalizedHash);
  if (translatedText and translatedText ~= "") then
     return translatedText, hash;
  end

  if (hash and type(originalText) == "string" and originalText ~= "" and not QTR_IsArabicGossipText(originalText)) then
     local npcName = nil;
     if (type(UnitName) == "function") then
        npcName = UnitName("npc") or UnitName("questnpc");
     end
     if (npcName and npcName ~= "") then
        QTR_SaveHarvestedGossipText(npcName, hash, originalText);
     end
  end

  return nil, hash;
end


function QTR_GetExternalChoiceTranslatedText(displayText, width, fontName, fontSize)
  if (type(displayText) ~= "string" or displayText == "") then
     return nil, nil;
  end

  local originalTitle = QTR_GetQuestTitleFromDisplayText(displayText);
  if (originalTitle) then
     local translatedQuestText = QTR_PrepareExternalQuestTitleDisplay(nil, displayText, originalTitle, width, fontName, fontSize, fontName, false);
     if (translatedQuestText and translatedQuestText ~= "" and translatedQuestText ~= displayText) then
        return translatedQuestText, "quest";
     end
  end

  local translatedGossipText, hash = QTR_GetExternalGossipBodyTranslation(displayText, false);
  if (translatedGossipText and translatedGossipText ~= "") then
     if (AS_ContainsArabic and AS_ContainsArabic(translatedGossipText)) then
        translatedGossipText = QTR_PrepareWrappedArabicText(translatedGossipText, width, fontName, fontSize);
     end
     return translatedGossipText, "gossip";
  end

  return nil, nil;
end


function QTR_GetExternalFontState(fontString, stateMap)
  if (not fontString or not stateMap or not fontString.GetFont or not fontString.SetFont) then
     return nil;
  end

  local fontState = stateMap[fontString];
  if (not fontState) then
     local originalFont, originalSize, originalFlags = fontString:GetFont();
     fontState = {
        font = originalFont or Original_Font2,
        size = originalSize or 13,
        flags = originalFlags,
        justify = fontString.GetJustifyH and fontString:GetJustifyH(),
     };
     stateMap[fontString] = fontState;
  end

  return fontState;
end


function QTR_RestoreExternalFontState(fontString, stateMap)
  local fontState = QTR_GetExternalFontState(fontString, stateMap);
  if (not fontState) then
     return;
  end

  fontString:SetFont(fontState.font or Original_Font2, fontState.size or 13, fontState.flags);
  if (fontString.SetJustifyH) then
     fontString:SetJustifyH(fontState.justify or "LEFT");
  end
end


function QTR_ApplyWatchFrameQuestTitle(titleLine, questId, originalTitle, displayText)
  if (not titleLine or not titleLine.text or not displayText or displayText == "") then
     return false;
  end

  local defaultFont, defaultFontSize, defaultFontFlags = titleLine.text:GetFont();
  local arabicFont = QTR_Font1 or QTR_Font2 or defaultFont;
  local translatedDisplayText = QTR_PrepareExternalQuestTitleDisplay(questId, displayText, originalTitle, titleLine.text:GetWidth(), arabicFont, defaultFontSize or 13, defaultFont or arabicFont);
  if (not translatedDisplayText or translatedDisplayText == "" or translatedDisplayText == displayText) then
     return false;
  end

  titleLine:SetHeight(WATCHFRAME_LINEHEIGHT or titleLine:GetHeight());
  titleLine.text:SetHeight(0);
  titleLine.text:SetFont(arabicFont, defaultFontSize or 13, defaultFontFlags);
  titleLine.text:SetJustifyH("LEFT");
  titleLine.text:SetText(translatedDisplayText);

  local titleHeight = titleLine.text:GetHeight();
  if (titleHeight > (WATCHFRAME_LINEHEIGHT or 16)) then
     local titleLineHeight = WATCHFRAME_MULTIPLE_LINEHEIGHT or titleLine:GetHeight();
     if (titleHeight > titleLineHeight) then
        titleLineHeight = titleHeight;
     end
     titleLine:SetHeight(titleLineHeight);
     titleLine.text:SetHeight(titleLineHeight);
  end

  return true;
end
function QTR_ExtractLeadingTextureTags(text)
  local texturePrefix = "";
  local visibleText = text or "";

  while (visibleText ~= "") do
     local textureTag = string.match(visibleText, "^(|T.-|t%s*)");
     if (textureTag and textureTag ~= "") then
        texturePrefix = texturePrefix .. textureTag;
        visibleText = string.sub(visibleText, string.len(textureTag) + 1);
     else
        break;
     end
  end

  return texturePrefix, visibleText;
end


function QTR_SplitMultilineText(text)
  local lines = {};
  if (not text or text == "") then
     return lines;
  end

  text = string.gsub(text, "\r\n", "\n");
  text = string.gsub(text, "\r", "\n");
  for line in string.gmatch(text .. "\n", "(.-)\n") do
     lines[#lines + 1] = line;
  end

  while (#lines > 0 and lines[#lines] == "") do
     table.remove(lines);
  end

  return lines;
end


local QTR_QuestLogTitleButtonHooks = {};
local QTR_QuestLogTitleButtonUpdateLock = {};


-- Resize the quest log title font string after swapping in translated text.
local function QTR_ResizeQuestLogTitleButton(titleButton)
  if (not titleButton or not titleButton.normalText) then
     return;
  end

  local questNormalText = titleButton.normalText;
  local questTitleTag = titleButton.tag;
  local questCheck = titleButton.check;

  questNormalText:SetWidth(0);

  local rightEdge;
  if (questTitleTag and questTitleTag:IsShown()) then
     if (questCheck and questCheck:IsShown()) then
        rightEdge = titleButton:GetLeft() + titleButton:GetWidth() - questTitleTag:GetWidth() - 4 - questCheck:GetWidth() - 2;
     else
        rightEdge = titleButton:GetLeft() + titleButton:GetWidth() - questTitleTag:GetWidth() - 4;
     end
  else
     if (questCheck and questCheck:IsShown()) then
        rightEdge = titleButton:GetLeft() + titleButton:GetWidth() - questCheck:GetWidth() - 2;
     else
        rightEdge = titleButton:GetLeft() + titleButton:GetWidth();
     end
  end

  local questNormalTextWidth = questNormalText:GetWidth() - max(questNormalText:GetRight() - rightEdge, 0);
  questNormalText:SetWidth(questNormalTextWidth);
end


-- Replace only the English quest-title segment so custom row prefixes/suffixes stay intact.
local function QTR_GetTranslatedQuestLogButtonText(displayText, questTitle, translatedDisplayTitle)
  if (not translatedDisplayTitle) then
     return nil;
  end

  if (not displayText or displayText == "") then
     return translatedDisplayTitle;
  end
  if (AS_ContainsArabic and AS_ContainsArabic(displayText)) then
     return displayText;
  end
  if (not questTitle or questTitle == "") then
     return translatedDisplayTitle;
  end

  local titleStart, titleEnd = string.find(displayText, questTitle, 1, true);
  if (titleStart and titleEnd) then
     return string.sub(displayText, 1, titleStart - 1) .. translatedDisplayTitle .. string.sub(displayText, titleEnd + 1);
  end

  return nil;
end


local QTR_QuestLogTagFontState = setmetatable({}, { __mode = "k" });
local QTR_QuestLogTagOriginalText = setmetatable({}, { __mode = "k" });
local QTR_QuestLogObjectiveFontState = setmetatable({}, { __mode = "k" });
local QTR_QuestLogObjectiveOriginalText = setmetatable({}, { __mode = "k" });


local function QTR_GetQuestCompleteStatusText()
  local completeText = (QTR_Messages and QTR_Messages.complete) or nil;
  if (not completeText or completeText == "") then
     return nil;
  end

  return QTR_ReverseText(completeText);
end


local function QTR_ReplaceQuestCompleteToken(text, replacement)
  if (type(text) ~= "string" or text == "" or not replacement or replacement == "") then
     return nil;
  end

  local completeToken = "(" .. (QTR_MessOrig.complete or "Complete") .. ")";
  local tokenStart, tokenEnd = string.find(text, completeToken, 1, true);
  if (not tokenStart or not tokenEnd) then
     return nil;
  end

  return string.sub(text, 1, tokenStart - 1) .. "(" .. replacement .. ")" .. string.sub(text, tokenEnd + 1);
end


local function QTR_UpdateQuestLogTitleTag(titleButton, isComplete)
  if (not titleButton or not titleButton.tag) then
     return false;
  end

  local tagFontString = titleButton.tag;
  local translatedCompleteText = QTR_GetQuestCompleteStatusText();
  local translatedTagText = translatedCompleteText and ("(" .. translatedCompleteText .. ")") or nil;
  if (QTR_PS and QTR_PS["active"] == "1" and isComplete and isComplete > 0 and translatedCompleteText) then
     local currentText = tagFontString:GetText();
     if (currentText and currentText ~= "" and not QTR_QuestLogTagOriginalText[tagFontString]) then
        QTR_QuestLogTagOriginalText[tagFontString] = currentText;
     end

     QTR_GetExternalFontState(tagFontString, QTR_QuestLogTagFontState);
     local originalState = QTR_QuestLogTagFontState[tagFontString] or {};
     tagFontString:SetFont(QTR_Font2 or originalState.font or Original_Font2, originalState.size or QTR_QuestLogEntryFontSize or 13, originalState.flags);
     tagFontString:SetJustifyH(originalState.justify or "LEFT");
     tagFontString:SetText(translatedTagText);
     tagFontString:Show();
     return true;
  end

  QTR_RestoreExternalFontState(tagFontString, QTR_QuestLogTagFontState);
  if (QTR_QuestLogTagOriginalText[tagFontString]) then
     if (tagFontString:GetText() == translatedTagText) then
        tagFontString:SetText(QTR_QuestLogTagOriginalText[tagFontString]);
     end
     QTR_QuestLogTagOriginalText[tagFontString] = nil;
     return true;
  end

  return false;
end


local function QTR_UpdateQuestLogObjectiveFrames()
  local translatedCompleteText = QTR_GetQuestCompleteStatusText();
  local objectiveIndex = 1;

  while (true) do
     local objectiveFrame = _G["QuestInfoObjective" .. objectiveIndex];
     if (not objectiveFrame) then
        break;
     end

     if (objectiveFrame.IsShown and objectiveFrame:IsShown()) then
        local liveText = (objectiveFrame.GetText and objectiveFrame:GetText()) or "";
        local cachedOriginalText = QTR_QuestLogObjectiveOriginalText[objectiveFrame];
        local originalText = liveText;
        local cachedTranslatedText = nil;

        if (cachedOriginalText) then
           cachedTranslatedText = QTR_ReplaceQuestCompleteToken(cachedOriginalText, translatedCompleteText);
           if (cachedTranslatedText and liveText == cachedTranslatedText) then
              originalText = cachedOriginalText;
           else
              QTR_QuestLogObjectiveOriginalText[objectiveFrame] = nil;
              cachedOriginalText = nil;
              cachedTranslatedText = nil;
           end
        end

        local translatedText = nil;
        if (QTR_PS and QTR_PS["active"] == "1" and translatedCompleteText) then
          translatedText = QTR_ReplaceQuestCompleteToken(originalText, translatedCompleteText);
        end

        if (translatedText) then
           if (not cachedOriginalText) then
              QTR_QuestLogObjectiveOriginalText[objectiveFrame] = originalText;
           end
           QTR_GetExternalFontState(objectiveFrame, QTR_QuestLogObjectiveFontState);
           local originalState = QTR_QuestLogObjectiveFontState[objectiveFrame] or {};
           objectiveFrame:SetFont(QTR_Font2 or originalState.font or Original_Font2, originalState.size or 13, originalState.flags);
           objectiveFrame:SetJustifyH(originalState.justify or "LEFT");
           objectiveFrame:SetText(translatedText);
        else
           QTR_RestoreExternalFontState(objectiveFrame, QTR_QuestLogObjectiveFontState);
           if (cachedOriginalText) then
              if (objectiveFrame:GetText() == cachedTranslatedText) then
                 objectiveFrame:SetText(cachedOriginalText);
              end
              QTR_QuestLogObjectiveOriginalText[objectiveFrame] = nil;
           end
        end
     else
        QTR_RestoreExternalFontState(objectiveFrame, QTR_QuestLogObjectiveFontState);
        QTR_QuestLogObjectiveOriginalText[objectiveFrame] = nil;
     end

     objectiveIndex = objectiveIndex + 1;
  end
end


-- Translate a single quest-log title button using its live display text.
local function QTR_UpdateQuestLogTitleButton(titleButton, displayText)
  if (not titleButton or QTR_QuestLogTitleButtonUpdateLock[titleButton]) then
     return;
  end

  if (not QTR_PS or QTR_PS["active"] ~= "1" or QTR_PS["transtitle"] ~= "1") then
     QTR_RestoreTitleButtonFont(titleButton);
     QTR_UpdateQuestLogTitleTag(titleButton, nil);
     QTR_ResizeQuestLogTitleButton(titleButton);
     return;
  end

  local questIndex = titleButton:GetID();
  if (not questIndex or questIndex <= 0) then
     return;
  end

  local questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(questIndex);
  if (not questTitle or isHeader) then
     return;
  end

  local tagChanged = QTR_UpdateQuestLogTitleTag(titleButton, isComplete);

  local translatedQuestTitle = nil;
  if (questID) then
     translatedQuestTitle = QTR_GetTranslatedQuestTitleById(tostring(questID));
  end
  if (not translatedQuestTitle) then
     translatedQuestTitle = QTR_GetQuestTitleTranslation(questTitle);
  end
  if (not translatedQuestTitle) then
     if (tagChanged) then
        QTR_ResizeQuestLogTitleButton(titleButton);
     end
     return;
  end

  local currentDisplayText = displayText;
  if (currentDisplayText == nil) then
     if (titleButton.normalText and titleButton.normalText.GetText) then
        currentDisplayText = titleButton.normalText:GetText();
     else
        currentDisplayText = titleButton:GetText();
     end
  end

  local translatedDisplayTitle = QTR_PrepareTitleButtonArabicText(titleButton, translatedQuestTitle, QTR_Font2, QTR_QuestLogEntryFontSize);
  local translatedDisplayText = QTR_GetTranslatedQuestLogButtonText(currentDisplayText, questTitle, translatedDisplayTitle);
  if (translatedDisplayText and translatedDisplayText ~= currentDisplayText) then
     QTR_QuestLogTitleButtonUpdateLock[titleButton] = true;
     QTR_SetTitleButtonText(titleButton, translatedDisplayText, QTR_Font2, QTR_QuestLogEntryFontSize);
     QTR_QuestLogTitleButtonUpdateLock[titleButton] = nil;
     tagChanged = true;
  end

  if (tagChanged) then
     QTR_ResizeQuestLogTitleButton(titleButton);
  end
end


local function QTR_RestoreQuestLogTitleButtons()
  if (not QuestLogScrollFrame or not QuestLogScrollFrame.buttons) then
     return;
  end

  for _, titleButton in ipairs(QuestLogScrollFrame.buttons) do
     if (titleButton and titleButton:IsShown() and not titleButton.isHeader) then
        QTR_RestoreTitleButtonFont(titleButton);
        QTR_UpdateQuestLogTitleTag(titleButton, nil);
        QTR_ResizeQuestLogTitleButton(titleButton);
     end
  end
end


-- Install per-button SetText hooks so later quest-log repaints still pass through translation.
local function QTR_HookQuestLogTitleButtons()
  if (not QuestLogScrollFrame or not QuestLogScrollFrame.buttons) then
     return;
  end

  for _, titleButton in ipairs(QuestLogScrollFrame.buttons) do
     if (titleButton and not QTR_QuestLogTitleButtonHooks[titleButton]) then
        QTR_QuestLogTitleButtonHooks[titleButton] = true;
        hooksecurefunc(titleButton, "SetText", function(self, text)
           QTR_UpdateQuestLogTitleButton(self, text);
        end);
        if (titleButton.normalText) then
           hooksecurefunc(titleButton.normalText, "SetText", function(_, text)
              QTR_UpdateQuestLogTitleButton(titleButton, text);
           end);
        end
     end
  end
end


local QTR_QuestLogFontState = setmetatable({}, { __mode = "k" });


local function QTR_UpdateQuestLogInlineLabel(fontString, translatedText, originalText, fontName, fallbackSize)
  if (not fontString) then
     return;
  end

  QTR_GetExternalFontState(fontString, QTR_QuestLogFontState);

  local _, fontSize = fontString:GetFont();
  local appliedSize = fallbackSize or fontSize or QTR_QuestLogActionButtonFontSize;
  if (translatedText and translatedText ~= "") then
     QTR_SetShapedText(fontString, translatedText, fontName or QTR_Font2 or QTR_Font1 or Original_Font2, appliedSize);
  else
     QTR_RestoreExternalFontState(fontString, QTR_QuestLogFontState);
     if (originalText ~= nil) then
        fontString:SetText(originalText);
     end
  end
end


local function QTR_UpdateQuestLogCenteredLabel(fontString, translatedText, originalText, fontName, fallbackSize)
  if (not fontString) then
     return;
  end

  local fontState = QTR_GetExternalFontState(fontString, QTR_QuestLogFontState);
  local _, fontSize = fontString:GetFont();

  if (translatedText and translatedText ~= "") then
     local appliedFont = fontName or QTR_Font1 or QTR_Font2 or Original_Font1;
     local appliedSize = fallbackSize or fontSize or QTR_QuestLogHeaderFontSize;
     local wrapWidth = (fontString.GetWidth and fontString:GetWidth()) or 0;

     fontString:SetFont(appliedFont, appliedSize, fontState and fontState.flags);
     QTR_ApplyRTLWidthAdjustment(fontString, true);
     if (fontString.SetJustifyH) then
        fontString:SetJustifyH((fontState and fontState.justify) or "CENTER");
     end

     if (AS_ContainsArabic and AS_ContainsArabic(translatedText)) then
        fontString:SetText(QTR_PrepareWrappedArabicText(translatedText, wrapWidth, appliedFont, appliedSize));
     else
        fontString:SetText(translatedText);
     end
  else
     QTR_RestoreExternalFontState(fontString, QTR_QuestLogFontState);
     fontString:SetText(originalText or "");
  end
end


local function QTR_UpdateQuestLogButtonText(button, translatedText, originalText)
  if (not button or not button.GetFontString) then
     return;
  end

  local fontString = button:GetFontString();
  if (not fontString) then
     return;
  end

  QTR_GetExternalFontState(fontString, QTR_QuestLogFontState);

  if (translatedText and translatedText ~= "") then
     button:SetText(translatedText);
     QTR_SetShapedText(fontString, translatedText, QTR_Font2 or QTR_Font1 or Original_Font2, QTR_QuestLogActionButtonFontSize);
  else
     QTR_RestoreExternalFontState(fontString, QTR_QuestLogFontState);
     button:SetText(originalText or "");
  end
end


local function QTR_UpdateQuestLogShowMapButton(button, translatedText, originalText)
  if (not button or not button.text) then
     return;
  end

  local fontString = button.text;
   QTR_UpdateQuestLogInlineLabel(fontString, translatedText, originalText, QTR_Font2 or QTR_Font1 or Original_Font2, QTR_QuestLogShowMapFontSize);

  if (button.texture and button.SetWidth and fontString.GetStringWidth and button.texture.GetWidth) then
     button:SetWidth(fontString:GetStringWidth() + button.texture:GetWidth());
  end
end


local function QTR_UpdateQuestLogFrameLabels()
  if (not QTR_PS or not QuestLogFrame or not QuestLogFrame:IsVisible()) then
     return;
  end

  local showArabic = (QTR_PS["active"] == "1");
  local _, numQuests = GetNumQuestLogEntries();
  local maxQuests = MAX_QUESTLOG_QUESTS or MAX_QUESTS or 25;
  local translatedCountText = nil;

  if (showArabic and QTR_Messages and QTR_Messages.questlogquests) then
     translatedCountText = string.format("%s: %d/%d", QTR_Messages.questlogquests, numQuests or 0, maxQuests);
  end

   QTR_UpdateQuestLogCenteredLabel(QuestLogTitleText, (showArabic and QTR_Messages and QTR_Messages.questlogtitle) or nil, QTR_MessOrig.questlogtitle, QTR_Font1 or QTR_Font2 or Original_Font1, QTR_QuestLogHeaderFontSize);
   QTR_UpdateQuestLogInlineLabel(QuestLogQuestCount, translatedCountText, nil, QTR_Font2 or QTR_Font1 or Original_Font2, QTR_QuestLogCountFontSize);
   QTR_UpdateQuestLogCenteredLabel(QuestLogNoQuestsText, (showArabic and QTR_Messages and QTR_Messages.noactivequests) or nil, QTR_MessOrig.noactivequests, QTR_Font2 or QTR_Font1 or Original_Font2, QTR_QuestLogEmptyFontSize);
  QTR_UpdateQuestLogButtonText(QuestLogFrameAbandonButton, (showArabic and QTR_Messages and QTR_Messages.abandon) or nil, QTR_MessOrig.abandon);
  QTR_UpdateQuestLogButtonText(QuestLogFramePushQuestButton, (showArabic and QTR_Messages and QTR_Messages.share) or nil, QTR_MessOrig.share);
  QTR_UpdateQuestLogButtonText(QuestLogFrameTrackButton, (showArabic and QTR_Messages and QTR_Messages.track) or nil, QTR_MessOrig.track);
   QTR_UpdateQuestLogShowMapButton(QuestLogFrameShowMapButton, (showArabic and QTR_Messages and QTR_Messages.showmap) or nil, QTR_MessOrig.showmap);
  QTR_UpdateQuestLogButtonText(QuestLogFrameCancelButton, (showArabic and QTR_Messages and QTR_Messages.close) or nil, QTR_MessOrig.close);
end


-- Reapply translated quest titles to the visible left quest-log rows after Blizzard redraws them.
function QTR_UpdateQuestLogTitleButtons()
  QTR_UpdateQuestLogFrameLabels();

  if (not QTR_PS or QTR_PS["active"] ~= "1" or QTR_PS["transtitle"] ~= "1") then
     return;
  end
  if (not QuestLogFrame or not QuestLogFrame:IsVisible() or not QuestLogScrollFrame or not QuestLogScrollFrame.buttons) then
     return;
  end

  QTR_HookQuestLogTitleButtons();

  local buttons = QuestLogScrollFrame.buttons;
  for _, titleButton in ipairs(buttons) do
     if (titleButton and titleButton:IsShown() and not titleButton.isHeader) then
        QTR_UpdateQuestLogTitleButton(titleButton);
     end
  end
end


local QTR_LegacySavedVarKeys = {
   "mode",
   "transtitle_migrated",
   "size",
   "width",
}


-- Initialize saved variables and restore persisted addon settings.
function QTR_CheckVars()
  if (not QTR_PS) then
     QTR_PS = {};
  end
  if (not QTR_PC) then
     QTR_PC = {};
  end
  if (not QTR_SAVED) then
     QTR_SAVED = {};
  end
  if (not QTR_GOSSIP) then
     QTR_GOSSIP = {};
  end
  QTR_SanitizeSavedGossipEntries();
  -- initialize check options
  if (not QTR_PS["active"]) then
     QTR_PS["active"] = "1";   
  end
  if (not QTR_PS["transtitle"] ) then
     QTR_PS["transtitle"] = "1";   
  end
  for _, key in ipairs(QTR_LegacySavedVarKeys) do
     QTR_PS[key] = nil;
  end
  if (not QTR_PS["gossip"] ) then
     QTR_PS["gossip"] = "1";   
  end
  if (not QTR_PS["tutorial"] ) then
     QTR_PS["tutorial"] = "1";   
  end
  if ( QTR_PS["isGetQuestID"] ) then
     isGetQuestID=QTR_PS["isGetQuestID"];
  end;
  QTR_GS = {};       -- board for original texts
end
-- Sync the options UI checkboxes with the current saved settings.

function QTR_SetCheckButtonState()
  QTRCheckButton0:SetChecked(QTR_PS["active"]=="1");
  QTRCheckButton3:SetChecked(QTR_PS["transtitle"]=="1");
  QTRCheckButtonGossip:SetChecked(QTR_PS["gossip"]=="1");
  QTRCheckButtonTutorial:SetChecked(QTR_PS["tutorial"]=="1");
end


local function QTR_UpdateQuestLogToggleButtonText()
  if (not QTR_ToggleButton1) then
     return;
  end

  if (QTR_PS and QTR_PS["active"] == "0") then
     QTR_ToggleButton1:SetText("OG");
  else
     QTR_ToggleButton1:SetText("AR");
  end
end


local function QTR_UpdateWorldMapQuestList()
  if (not WorldMapFrame or not WorldMapFrame:IsVisible() or not WorldMapQuestShowObjectives or not WorldMapQuestShowObjectives:GetChecked()) then
     return;
  end

  local lastFrame = nil;
  for i = 1, MAX_NUM_QUESTS do
     local questFrame = _G["WorldMapQuestFrame"..i];
     if (not questFrame) then
        break;
     end

     if (questFrame:IsShown()) then
        questFrame.qtrOriginalTitle = questFrame.title:GetText();
        if (QTR_PS and QTR_PS["active"] == "1" and questFrame.questId and questFrame.questId > 0) then
           local questId = tostring(questFrame.questId);
           local questData = QTR_QuestData and QTR_QuestData[questId];
           if (questData) then
              local _, titleSize = questFrame.title:GetFont();
              local titleWidth = 240;

              if (questFrame.check and questFrame.check:IsShown()) then
                 titleWidth = 224;
              end

              questFrame.title:SetWidth(titleWidth);
              if (QTR_PS["transtitle"] == "1") then
                 QTR_SetShapedTitleText(questFrame.title, QTR_GetTranslatedQuestTitleById(questId), QTR_Font1, titleSize or 13, titleWidth);
              end
           end
        end

        if (lastFrame) then
           questFrame:ClearAllPoints();
           questFrame:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", 0, 0);
        else
           questFrame:ClearAllPoints();
           questFrame:SetPoint("TOPLEFT", WorldMapQuestScrollChildFrame, "TOPLEFT", 2, 0);
        end
        lastFrame = questFrame;
     end
  end
end


local function QTR_RefreshWorldMapQuestList()
  if (type(WorldMapFrame_UpdateQuests) ~= "function") then
     return;
  end

  if (WorldMapFrame and WorldMapFrame:IsVisible() and WorldMapQuestShowObjectives and WorldMapQuestShowObjectives:GetChecked()) then
     WorldMapFrame_UpdateQuests();
  end
end


local function QTR_RestoreWatchFrameHeader()
  if (not WatchFrame or not WatchFrameHeader or not WatchFrameTitle) then
     return;
  end

  if (not WatchFrame.qtrBaseCollapsedWidth or WatchFrame.qtrBaseCollapsedWidth <= 0) then
     WatchFrame.qtrBaseCollapsedWidth = WATCHFRAME_COLLAPSEDWIDTH;
  end
  if (WatchFrame.qtrBaseCollapsedWidth and WatchFrame.qtrBaseCollapsedWidth > 0) then
     WATCHFRAME_COLLAPSEDWIDTH = WatchFrame.qtrBaseCollapsedWidth;
  end

  WatchFrameHeader:ClearAllPoints();
  WatchFrameHeader:SetPoint("TOPLEFT", WatchFrame, "TOPLEFT", 0, -6);
  WatchFrameTitle:ClearAllPoints();
  WatchFrameTitle:SetPoint("TOPLEFT", WatchFrameHeader, "TOPLEFT", 0, 0);
  if (GameFontNormal) then
     WatchFrameTitle:SetFontObject(GameFontNormal);
  end
  WatchFrameTitle:SetJustifyH("LEFT");

  local titleWidth = WatchFrameTitle:GetStringWidth() or 0;
  if (titleWidth > 0) then
     WatchFrameTitle:SetWidth(titleWidth);
     WatchFrameHeader:SetWidth(titleWidth + 4);
  else
     WatchFrameTitle:SetWidth(0);
  end

  if (WatchFrame.collapsed and WATCHFRAME_COLLAPSEDWIDTH and WATCHFRAME_COLLAPSEDWIDTH > 0) then
     WatchFrame:SetWidth(WATCHFRAME_COLLAPSEDWIDTH);
  end
end


local function QTR_UpdateWatchFrameHeader()
  if (not WatchFrame or not WatchFrameHeader or not WatchFrameTitle) then
     return;
  end

  local displayText = (QTR_Messages and QTR_Messages.objectives) or "المهام";
  local objectiveCount = string.match(WatchFrameTitle:GetText() or "", "%((%d+)%)");
  if (objectiveCount) then
     displayText = displayText .. " (" .. objectiveCount .. ")";
  end

  if (not WatchFrame.qtrBaseCollapsedWidth or WatchFrame.qtrBaseCollapsedWidth <= 0) then
     WatchFrame.qtrBaseCollapsedWidth = WATCHFRAME_COLLAPSEDWIDTH;
  end

  local _, titleSize = WatchFrameTitle:GetFont();
  local maxHeaderWidth = (WATCHFRAME_EXPANDEDWIDTH or WatchFrame:GetWidth() or 204) - 32;
  if (maxHeaderWidth < 40) then
     maxHeaderWidth = 40;
  end

  WatchFrameHeader:ClearAllPoints();
  WatchFrameHeader:SetPoint("TOPLEFT", WatchFrame, "TOPLEFT", 0, -6);
  WatchFrameTitle:ClearAllPoints();
  WatchFrameTitle:SetPoint("TOPLEFT", WatchFrameHeader, "TOPLEFT", 0, 0);
  WatchFrameTitle:SetWidth(maxHeaderWidth);
  QTR_SetShapedText(WatchFrameTitle, displayText, QTR_Font1, titleSize or 12);

  local headerWidth = min(max(WatchFrameTitle:GetStringWidth() + 4, 40), maxHeaderWidth);
  WatchFrameHeader:SetWidth(headerWidth);
  WatchFrameTitle:SetWidth(headerWidth);
  WATCHFRAME_COLLAPSEDWIDTH = headerWidth + 70;

  if (WatchFrame.collapsed) then
     WatchFrame:SetWidth(WATCHFRAME_COLLAPSEDWIDTH);
  end
end


local QTR_WatchFrameRetitlePending = false;


local function QTR_ApplyTrackedWatchFrameQuestTitles()
  if (not WatchFrame or not WatchFrame:IsShown() or not WatchFrameLines or not WATCHFRAME_LINKBUTTONS or type(GetQuestIndexForWatch) ~= "function") then
     return;
  end
  if (not QTR_PS or QTR_PS["active"] ~= "1" or QTR_PS["transtitle"] ~= "1") then
     return;
  end

  for i = 1, #WATCHFRAME_LINKBUTTONS do
     local linkButton = WATCHFRAME_LINKBUTTONS[i];
     if (linkButton and linkButton:IsShown() and linkButton.type == "QUEST" and linkButton.lines and linkButton.startLine and linkButton.lastLine) then
        local questIndex = GetQuestIndexForWatch(linkButton.index);
        if (questIndex) then
           local title, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(questIndex);
           local titleLine = linkButton.lines[linkButton.startLine];
           if (titleLine and titleLine.text and title and title ~= "") then
              local questId = nil;
              if (questID and questID > 0) then
                 questId = tostring(questID);
              end
              QTR_ApplyWatchFrameQuestTitle(titleLine, questId, title, titleLine.text:GetText() or title);
           end
        end
     end
  end
end


local function QTR_RequestWatchFrameTitleRefresh()
  if (QTR_WatchFrameRetitlePending or not QTR_wait) then
     return;
  end
  if (not WatchFrame or not WatchFrame:IsShown()) then
     return;
  end
  if (not QTR_PS or QTR_PS["active"] ~= "1" or QTR_PS["transtitle"] ~= "1") then
     return;
  end

  QTR_WatchFrameRetitlePending = true;
  if (not QTR_wait(0, function()
     QTR_WatchFrameRetitlePending = false;
     QTR_ApplyTrackedWatchFrameQuestTitles();
  end)) then
     QTR_WatchFrameRetitlePending = false;
  end
end


local function QTR_UpdateWatchFrame()
  if (not WatchFrame or not WatchFrame:IsShown()) then
     return;
  end

  if (not QTR_PS or QTR_PS["active"] ~= "1") then
     QTR_RestoreWatchFrameHeader();
     return;
  end

  QTR_UpdateWatchFrameHeader();
  QTR_ApplyTrackedWatchFrameQuestTitles();
  QTR_RequestWatchFrameTitleRefresh();
end


local function QTR_RefreshWatchFrame()
  if (type(WatchFrame_Update) ~= "function" or not WatchFrame) then
     return;
  end

  WatchFrame_Update(WatchFrame);
end


-- Build the Blizzard Interface Options panel for this addon.
function QTR_BlizzardOptions()
  -- Create main frame for information text
  local QTROptions = CreateFrame("FRAME", "QTROptions");
  QTROptions:SetScript("OnShow", function(self) QTR_SetCheckButtonState() end);
  QTROptions.name = "Arabic WoW-Quests";
  InterfaceOptions_AddCategory(QTROptions);

  local function QTR_SetOptionsCheckButtonText(checkButton, textRegion, text)
     textRegion:SetFont(QTR_Font2, 13);
     textRegion:ClearAllPoints();
     textRegion:SetPoint("RIGHT", checkButton, "LEFT", -8, 0);
     textRegion:SetWidth(QTR_OptionsTextWidth);
     textRegion:SetJustifyH("RIGHT");
     textRegion:SetText(text);
  end

  local function QTR_SetOptionsText(fontString, text, relativeTo, relativeIsCheckButton, yOffset, fontObject)
     fontString:SetFontObject(fontObject or GameFontNormal);
     fontString:SetJustifyH("RIGHT");
     fontString:SetJustifyV("TOP");
     fontString:ClearAllPoints();
     fontString:SetWidth(QTR_OptionsTextWidth);
     if (relativeIsCheckButton) then
        fontString:SetPoint("TOPRIGHT", relativeTo, "BOTTOMRIGHT", QTR_OptionsTextRight - QTR_OptionsCheckRight, yOffset);
     else
        fontString:SetPoint("TOPRIGHT", relativeTo, "BOTTOMRIGHT", 0, yOffset);
     end
     fontString:SetFont(QTR_Font2, 13);
     fontString:SetText(text);
  end

  local function QTR_SetOptionsCheckButtonPoint(checkButton, relativeTo, relativeIsCheckButton, yOffset)
     checkButton:ClearAllPoints();
     if (relativeIsCheckButton) then
        checkButton:SetPoint("TOPRIGHT", relativeTo, "BOTTOMRIGHT", 0, yOffset);
     else
        checkButton:SetPoint("TOPRIGHT", relativeTo, "BOTTOMRIGHT", QTR_OptionsCheckRight - QTR_OptionsTextRight, yOffset);
     end
  end

  local QTROptionsHeader = QTROptions:CreateFontString(nil, "ARTWORK");
  QTROptionsHeader:SetFontObject(GameFontNormalLarge);
  QTROptionsHeader:SetJustifyH("RIGHT"); 
  QTROptionsHeader:SetJustifyV("TOP");
  QTROptionsHeader:ClearAllPoints();
  QTROptionsHeader:SetWidth(QTR_OptionsHeaderWidth);
  QTROptionsHeader:SetPoint("TOPRIGHT", QTROptions, "TOPRIGHT", QTR_OptionsTextRight, -16);
  QTROptionsHeader:SetText("Arabic WoW-Quests, ver. "..QTR_version.." ("..QTR_base..")");

   local QTROptionsModeInfo = QTROptions:CreateFontString(nil, "ARTWORK");
   QTR_SetOptionsText(QTROptionsModeInfo, QTR_ReverseText("تعرض الترجمة الآن مباشرة داخل النوافذ الأصلية فقط"), QTROptionsHeader, false, -18, GameFontWhite);

  local QTRCheckButton0 = CreateFrame("CheckButton", "QTRCheckButton0", QTROptions, "OptionsCheckButtonTemplate");
   QTR_SetOptionsCheckButtonPoint(QTRCheckButton0, QTROptionsModeInfo, false, -10);
   QTRCheckButton0:SetScript("OnClick", function(self) if (QTR_PS["active"]=="1") then QTR_PS["active"]="0" else QTR_PS["active"]="1" end; QTR_UpdateQuestLogToggleButtonText(); QTR_RefreshWorldMapQuestList(); QTR_RefreshWatchFrame(); QTR_RefreshQuestieTracker(); QTR_RefreshQuestieArrow(); QTR_RefreshQuestHelperTracker(); QTR_RefreshImmersionLiveView(); QTR_RefreshStorylineLiveView(); end);
  QTR_SetOptionsCheckButtonText(QTRCheckButton0, QTRCheckButton0Text, QTR_ReverseText(QTR_Interface.active));
  
  local QTRCheckButton3 = CreateFrame("CheckButton", "QTRCheckButton3", QTROptions, "OptionsCheckButtonTemplate");
   QTR_SetOptionsCheckButtonPoint(QTRCheckButton3, QTRCheckButton0, true, -10);
   QTRCheckButton3:SetScript("OnClick", function(self) if (QTR_PS["transtitle"]=="0") then QTR_PS["transtitle"]="1" else QTR_PS["transtitle"]="0" end; QTR_RefreshWorldMapQuestList(); QTR_RefreshWatchFrame(); QTR_RefreshQuestieTracker(); QTR_RefreshQuestieArrow(); QTR_RefreshQuestHelperTracker(); QTR_RefreshImmersionLiveView(); QTR_RefreshStorylineLiveView(); end);
  QTR_SetOptionsCheckButtonText(QTRCheckButton3, QTRCheckButton3Text, QTR_ReverseText(QTR_Interface.transtitle));
  
  local QTRCheckButtonGossip = CreateFrame("CheckButton", "QTRCheckButtonGossip", QTROptions, "OptionsCheckButtonTemplate");
   QTR_SetOptionsCheckButtonPoint(QTRCheckButtonGossip, QTRCheckButton3, true, -10);
   QTRCheckButtonGossip:SetScript("OnClick", function(self) if (QTR_PS["gossip"]=="1") then QTR_PS["gossip"]="0" else QTR_PS["gossip"]="1" end; QTR_RefreshImmersionLiveView(); QTR_RefreshStorylineLiveView(); end);
  QTR_SetOptionsCheckButtonText(QTRCheckButtonGossip, QTRCheckButtonGossipText, QTR_ReverseText("اعرض ترجمات نصوص الحوار"));
  
  local QTRCheckButtonTutorial = CreateFrame("CheckButton", "QTRCheckButtonTutorial", QTROptions, "OptionsCheckButtonTemplate");
  QTR_SetOptionsCheckButtonPoint(QTRCheckButtonTutorial, QTRCheckButtonGossip, true, -5);
  QTRCheckButtonTutorial:SetScript("OnClick", function(self) if (QTR_PS["tutorial"]=="1") then QTR_PS["tutorial"]="0" else QTR_PS["tutorial"]="1" end; end);
  QTR_SetOptionsCheckButtonText(QTRCheckButtonTutorial, QTRCheckButtonTutorialText, QTR_ReverseText("اعرض ترجمات النصوص التعليمية")); 

  
  local QTRWWW1 = QTROptions:CreateFontString(nil, "ARTWORK");
  QTRWWW1:SetFontObject(GameFontWhite);
  QTRWWW1:SetJustifyH("RIGHT");
  QTRWWW1:SetJustifyV("TOP");
  QTRWWW1:ClearAllPoints();
  QTRWWW1:SetWidth(200);
  QTRWWW1:SetPoint("BOTTOMRIGHT", QTROptions, "BOTTOMRIGHT", -16, 16);
  QTRWWW1:SetFont(QTR_Font2, 13);
   QTRWWW1:SetText(QTR_ReverseText("زيارة موقع الإضافة:"));
  
  local QTRWWW2 = CreateFrame("EditBox", "QTRWWW2", QTROptions, "InputBoxTemplate");
  QTRWWW2:ClearAllPoints();
  QTRWWW2:SetPoint("TOPRIGHT", QTRWWW1, "TOPLEFT", -10, 4);
  QTRWWW2:SetHeight(20);
  QTRWWW2:SetWidth(170);
  QTRWWW2:SetAutoFocus(false);
  QTRWWW2:SetFontObject(GameFontGreen);
  QTRWWW2:SetText("https://github.com/3majed");
  QTRWWW2:SetCursorPosition(0);
  QTRWWW2:SetScript("OnEnter", function(self)
	  GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
      getglobal("GameTooltipTextLeft1"):SetFont(QTR_Font2, 13);
	  GameTooltip:SetText(QTR_ReverseText("اضغط ثم استخدم Ctrl+C لنسخ الرابط إلى الحافظة"), nil, nil, nil, nil, true)
	  GameTooltip:Show() --Show the tooltip
     end);
  QTRWWW2:SetScript("OnLeave", function(self)
      getglobal("GameTooltipTextLeft1"):SetFont(Original_Font2, 13);
	  GameTooltip:Hide() --Hide the tooltip
     end);
  QTRWWW2:SetScript("OnTextChanged", function(self) QTRWWW2:SetText("https://github.com/3majed"); end);
end


local QTR_RuntimeInitialized = false;
QTR_ArenaRegistrarHooksInitialized = false;
local QTR_EventFrame = CreateFrame("Frame");
local QTR_SuppressGossipRefreshHook = false;
local QTR_GossipRefreshPending = false;


local function QTR_RequestGossipRefresh()
  if (QTR_GossipRefreshPending) then
     return;
  end

  QTR_GossipRefreshPending = true;

  local function QTR_RunQueuedGossipRefresh()
     QTR_GossipRefreshPending = false;
     if (QTR_SuppressGossipRefreshHook or not QTR_PS or QTR_PS["gossip"] ~= "1") then
        return;
     end
     if (not GossipFrame or not GossipFrame:IsVisible() or not GossipGreetingText or not GossipGreetingText:IsShown()) then
        return;
     end
     QTR_Gossip_Show();
  end

  if (not QTR_wait(0, QTR_RunQueuedGossipRefresh)) then
     QTR_RunQueuedGossipRefresh();
  end
end


local QTR_QuestLogDetailRefreshLock = false;


function QTR_RequestArenaRegistrarRefresh()
  if (not QTR_wait(0, QTR_UpdateArenaRegistrarFrame)) then
     QTR_UpdateArenaRegistrarFrame();
  end
end


function QTR_InitializeArenaRegistrarHooks()
  if (QTR_ArenaRegistrarHooksInitialized) then
     if (ArenaRegistrarFrame and ArenaRegistrarFrame.IsShown and ArenaRegistrarFrame:IsShown()) then
        QTR_RequestArenaRegistrarRefresh();
     end
     return true;
  end

  if (not ArenaRegistrarFrame and type(ArenaRegistrar_OnShow) ~= "function") then
     return false;
  end

  QTR_ArenaRegistrarHooksInitialized = true;

  if (type(ArenaRegistrar_OnShow) == "function") then
     hooksecurefunc("ArenaRegistrar_OnShow", function()
        if (ArenaRegistrarFrame) then
           ArenaRegistrarFrame.qtrShowOriginalText = nil;
        end
        QTR_RequestArenaRegistrarRefresh();
     end);
  end
  if (type(ArenaRegistrar_ShowPurchaseFrame) == "function") then
     hooksecurefunc("ArenaRegistrar_ShowPurchaseFrame", function()
        QTR_RequestArenaRegistrarRefresh();
     end);
  end
  if (type(ArenaRegistrar_UpdatePrice) == "function") then
     hooksecurefunc("ArenaRegistrar_UpdatePrice", function()
        QTR_RequestArenaRegistrarRefresh();
     end);
  end
  if (type(ArenaRegistrar_OnEvent) == "function") then
     hooksecurefunc("ArenaRegistrar_OnEvent", function(_, event)
        if (event == "PETITION_VENDOR_UPDATE" and ArenaRegistrarFrame and ArenaRegistrarFrame:IsShown()) then
           QTR_RequestArenaRegistrarRefresh();
        end
     end);
  end
  if (ArenaRegistrarFrame and ArenaRegistrarFrame.HookScript) then
     ArenaRegistrarFrame:HookScript("OnShow", QTR_RequestArenaRegistrarRefresh);
     ArenaRegistrarFrame:HookScript("OnEvent", function(_, event)
        if (event == "PETITION_VENDOR_UPDATE") then
           QTR_RequestArenaRegistrarRefresh();
        end
     end);
  end
  if (ArenaRegistrarGreetingFrame and ArenaRegistrarGreetingFrame.HookScript) then
     ArenaRegistrarGreetingFrame:HookScript("OnShow", QTR_RequestArenaRegistrarRefresh);
  end
  if (ArenaRegistrarPurchaseFrame and ArenaRegistrarPurchaseFrame.HookScript) then
     ArenaRegistrarPurchaseFrame:HookScript("OnShow", QTR_RequestArenaRegistrarRefresh);
  end

  if (ArenaRegistrarFrame and ArenaRegistrarFrame.IsShown and ArenaRegistrarFrame:IsShown()) then
     QTR_RequestArenaRegistrarRefresh();
  end

  return true;
end


local function QTR_InitializeRuntime()
  if (QTR_RuntimeInitialized) then
     return true;
  end

  QTR_RuntimeInitialized = true;

  if (QuestLogDetailScrollFrame and QuestLogDetailScrollFrame.HookScript) then
     QuestLogDetailScrollFrame:HookScript("OnShow", QTR_ShowAndUpdateQuestInfo);
     QuestLogDetailScrollFrame:HookScript("OnHide", QTR_HideQuestInfo);
  end

  if (QuestLogFrame) then
     QTR_ToggleButton1 = CreateFrame("Button", nil, QuestLogFrame, "UIPanelButtonTemplate");
     QTR_ToggleButton1:SetWidth(35);
     QTR_ToggleButton1:SetHeight(18);
     QTR_ToggleButton1:SetText("AR");
     QTR_ToggleButton1:Show();
     QTR_ToggleButton1:ClearAllPoints();
     QTR_ToggleButton1:SetPoint("TOPLEFT", QuestLogFrame, "TOPLEFT", 620, -15);
     QTR_ToggleButton1:SetScript("OnClick", QTR_ToggleVisibility);
     QTR_UpdateQuestLogToggleButtonText();
  end

  if (type(QuestLogTitleButton_OnClick) == "function") then
     hooksecurefunc("QuestLogTitleButton_OnClick", function() QTR_UpdateQuestInfo() end);
  end
  if (type(QuestLog_OpenToQuest) == "function") then
     hooksecurefunc("QuestLog_OpenToQuest", function()
        if (not QTR_wait(0, QTR_UpdateQuestInfo)) then
           QTR_UpdateQuestInfo();
        end
     end);
  end
  if (type(QuestLog_UpdateQuestDetails) == "function") then
     hooksecurefunc("QuestLog_UpdateQuestDetails", function()
        if (QTR_QuestLogDetailRefreshLock) then
           return;
        end
        if (not QTR_wait(0, QTR_UpdateQuestInfo)) then
           QTR_UpdateQuestInfo();
        end
     end);
  end
  if (type(QuestLog_Update) == "function") then
     hooksecurefunc("QuestLog_Update", QTR_UpdateQuestLogTitleButtons);
  end

  if (GossipFrame) then
     QTR_ToggleButtonGS = CreateFrame("Button", nil, GossipFrame, "UIPanelButtonTemplate");
     QTR_ToggleButtonGS:SetWidth(230);
     QTR_ToggleButtonGS:SetHeight(20);
     QTR_ToggleButtonGS:SetText("Gossip-Hash=?");
     QTR_ToggleButtonGS:Show();
     QTR_ToggleButtonGS:ClearAllPoints();
     QTR_ToggleButtonGS:SetPoint("TOPLEFT", GossipFrame, "TOPLEFT", 70, -50);
     QTR_ToggleButtonGS:SetScript("OnClick", GS_ON_OFF);
  end
  if (type(GossipFrameUpdate) == "function") then
     hooksecurefunc("GossipFrameUpdate", function()
        if (not QTR_SuppressGossipRefreshHook and QTR_PS and QTR_PS["gossip"] == "1" and GossipFrame and GossipFrame:IsVisible() and GossipGreetingText and GossipGreetingText:IsShown()) then
           QTR_RequestGossipRefresh();
        end
     end);
  end
  if (type(GuildRegistrar_OnShow) == "function") then
     hooksecurefunc("GuildRegistrar_OnShow", function()
        if (GuildRegistrarFrame) then
           GuildRegistrarFrame.qtrShowOriginalText = nil;
        end
        if (not QTR_wait(0, QTR_UpdateGuildRegistrarFrame)) then
           QTR_UpdateGuildRegistrarFrame();
        end
     end);
  end
  if (type(GuildRegistrar_ShowPurchaseFrame) == "function") then
     hooksecurefunc("GuildRegistrar_ShowPurchaseFrame", function()
        if (not QTR_wait(0, QTR_UpdateGuildRegistrarFrame)) then
           QTR_UpdateGuildRegistrarFrame();
        end
     end);
  end
  QTR_InitializeArenaRegistrarHooks();
  if (GuildRegistrarFrame) then
     QTR_ToggleButtonGR = CreateFrame("Button", nil, GuildRegistrarFrame, "UIPanelButtonTemplate");
     QTR_ToggleButtonGR:SetWidth(52);
     QTR_ToggleButtonGR:SetHeight(20);
     QTR_ToggleButtonGR:SetText("EN");
     QTR_ToggleButtonGR:ClearAllPoints();
     QTR_ToggleButtonGR:SetPoint("TOPLEFT", GuildRegistrarFrame, "TOPLEFT", 78, -50);
     QTR_ToggleButtonGR:SetScript("OnClick", function()
        GuildRegistrarFrame.qtrShowOriginalText = not GuildRegistrarFrame.qtrShowOriginalText;
        QTR_UpdateGuildRegistrarFrame();
     end);
     QTR_ToggleButtonGR:Hide();
  end

  if (QuestFrame) then
     QTR_ToggleButtonQG = CreateFrame("Button", nil, QuestFrame, "UIPanelButtonTemplate");
     QTR_ToggleButtonQG:SetWidth(230);
     QTR_ToggleButtonQG:SetHeight(20);
     QTR_ToggleButtonQG:SetText("Gossip-Hash=?");
     QTR_ToggleButtonQG:ClearAllPoints();
     QTR_ToggleButtonQG:SetPoint("TOPLEFT", QuestFrame, "TOPLEFT", 95, -32);
     QTR_ToggleButtonQG:SetScript("OnClick", GS_ON_OFF_QUEST);
     QTR_ToggleButtonQG:Disable();
     QTR_ToggleButtonQG:Hide();
  end

  if (type(WorldMapQuestFrame_OnMouseUp) == "function") then
     hooksecurefunc("WorldMapQuestFrame_OnMouseUp", function() QTR_WorldMapQuestFrameOnMouseUp() end);
  end
  if (type(WorldMapFrame_SelectQuestFrame) == "function") then
     hooksecurefunc("WorldMapFrame_SelectQuestFrame", function() QTR_WorldMapQuestFrameOnMouseUp("WORLD_MAP_SelectQuestFrame") end);
  end
  if (type(WorldMapFrame_UpdateQuests) == "function") then
     hooksecurefunc("WorldMapFrame_UpdateQuests", QTR_UpdateWorldMapQuestList);
  end
  if (type(WatchFrame_Update) == "function") then
     hooksecurefunc("WatchFrame_Update", QTR_UpdateWatchFrame);
  end
  QTR_TryHookElvUITracker();
  QTR_TryHookLeatrixPlus();
  QTR_TryHookQuestieArrow();
   QTR_TryHookQuestHelperTracker();
  QTR_TryHookImmersion();
  QTR_TryHookStoryline();
  QTR_TryHookQuestieMapTooltips();
  QTR_TryHookQuestieUnitTooltips();
  if (TutorialFrame) then
     TutorialFrame:HookScript("OnShow", Tut_onTutorialShow);
     TutorialFrameNextButton:HookScript("OnClick", Tut_onTutorialShow);
     TutorialFramePrevButton:HookScript("OnClick", Tut_onTutorialShow);
  end

  QTR_EventFrame:RegisterEvent("QUEST_LOG_UPDATE");
  QTR_EventFrame:RegisterEvent("QUEST_GREETING");
  QTR_EventFrame:RegisterEvent("QUEST_DETAIL");
  QTR_EventFrame:RegisterEvent("QUEST_PROGRESS");
  QTR_EventFrame:RegisterEvent("QUEST_COMPLETE");
  QTR_EventFrame:RegisterEvent("WORLD_MAP_UPDATE");
  QTR_EventFrame:RegisterEvent("GOSSIP_SHOW");
   QTR_TryHookQuestieTracker();
    QTR_TryHookQuestieArrow();
  return true;
end


QTR_EventFrame:RegisterEvent("ADDON_LOADED");
QTR_EventFrame:SetScript("OnEvent", function(self, event, ...)
  if (event == "ADDON_LOADED") then
     local addon = ...;
     if (addon == "ArWoW_Quests" and QTR.ADDON_LOADED) then
        QTR:ADDON_LOADED(event, addon);
     end
     if (addon == "Blizzard_ArenaUI") then
        QTR_InitializeArenaRegistrarHooks();
     end
     QTR_TryHookQuestieMapTooltips();
     QTR_TryHookQuestieUnitTooltips();
     QTR_TryHookQuestieTracker();
     QTR_TryHookQuestieArrow();
   QTR_TryHookQuestHelperTracker();
     QTR_TryHookElvUITracker();
     QTR_TryHookLeatrixPlus();
     QTR_TryHookImmersion();
     QTR_TryHookStoryline();
     if (addon and string.find(addon, "^Questie")) then
        QTR_TryHookQuestieMapTooltips();
        QTR_TryHookQuestieUnitTooltips();
        QTR_RefreshQuestieTracker();
        QTR_RefreshQuestieArrow();
     elseif (addon == "ElvUI") then
        QTR_RefreshWatchFrame();
     elseif (addon == "Leatrix_Plus") then
        QTR_RefreshLeatrixPlusQuestLog();
     elseif (addon == "QuestHelper") then
        QTR_RefreshQuestHelperTracker();
     elseif (addon == "Immersion") then
        QTR_TryHookImmersion();
     elseif (addon == "Storyline") then
        QTR_TryHookStoryline();
     end
     return;
  end

  if (QTR[event]) then
     QTR[event](QTR, event, ...);
  end
end);


-- Refresh translated world map quest text after the selected quest changes.
function QTR_WorldMapQuestFrameOnMouseUp(eventName)
  eventName = eventName or "WORLD_MAP_OnMouseUp";
  QTR_event = eventName;
  QTR_OnEvent2();
  if (not QTR_WorldMapRetryPending) then
     QTR_WorldMapRetryPending = true;
     if (not QTR_wait(0.2, function(eventName)
        QTR_WorldMapRetryPending = false;
        if (WorldMapFrame and WorldMapFrame:IsVisible() and QTR_PS and QTR_PS["active"]=="1") then
           QTR_event = eventName;
           QTR_OnEvent2();
        end
     end, eventName)) then
        QTR_WorldMapRetryPending = false;
     end
  end
end


local function QTR_ClearSavedTranslationCaches()
   QTR_SAVED = {};
   QTR_GOSSIP = {};
   QTR_AddLocalizedSystemMessage("|cffffff00ArWoW-Quests - ", "Cleared QTR_SAVED and QTR_GOSSIP. Use /reload to persist the change.");
end


-- Open the addon options panel from the registered slash commands.
function QTR_SlashCommand(msg)
   local command = string.lower(string.match(msg or "", "^%s*(.-)%s*$") or "");
   if (command == "clear") then
       QTR_ClearSavedTranslationCaches();
       return;
   end

  InterfaceOptionsFrame_OpenToCategory(QTROptions);
  RestoreOriginalFonts();
end


-- Finish addon startup once this addon has been loaded by the client.
function QTR:ADDON_LOADED(_, addon)
   if (addon == "ArWoW_Quests") then
       QTR_InitializeRuntime();
     SlashCmdList["ArWoW_QUESTS"] = function(msg) QTR_SlashCommand(msg); end
     SLASH_ArWoW_QUESTS1 = "/arwow-quests";
     SLASH_ArWoW_QUESTS2 = "/qtr";
     QTR_CheckVars();
             QTR_TryHookElvUITracker();
            QTR_TryHookLeatrixPlus();
         QTR_TryHookQuestieArrow();
         QTR_TryHookQuestHelperTracker();
       QTR_TryHookImmersion();
       QTR_TryHookStoryline();
         QTR_TryHookQuestieTracker();
             QTR_TryHookQuestieMapTooltips();
         QTR_RefreshQuestieTracker();
             QTR_RefreshQuestieArrow();
             QTR_RefreshQuestHelperTracker();
            QTR_RefreshLeatrixPlusQuestLog();
       QTR_UpdateQuestLogToggleButtonText();
          QTR_RefreshWatchFrame();
     QTR_BlizzardOptions();
       QTR_AddLocalizedSystemMessage("|cffffff00ArWoW-Quests ver. "..QTR_version.." - ", QTR_Messages.loaded);
     self.ADDON_LOADED = nil;
     QTR_Messages.itemchoose1 = Spr_Gender(QTR_Messages.itemchoose1);
     DetectEmuServer();
  end
end


-- Refresh translated quest log details when the quest log changes.
function QTR:QUEST_LOG_UPDATE()
   if (QTR_PS and QTR_PS["active"]=="1" and QuestLogFrame and QuestLogFrame:IsVisible()) then
     QTR_UpdateQuestInfo();
       QTR_UpdateQuestLogTitleButtons();
  end
end


-- Re-apply quest translations when the world map quest detail panel refreshes.
function QTR:WORLD_MAP_UPDATE()
  if ( WorldMapFrame:IsVisible() ) then
     if (QTR_PS["active"]=="1") then
        if ( WorldMapQuestShowObjectives:GetChecked() ) then
           QTR_event = "WORLD_MAP_UPDATE";
           QTR_OnEvent2();
           if (not QTR_WorldMapRetryPending) then
              QTR_WorldMapRetryPending = true;
              if (not QTR_wait(0.2, function(eventName)
                 QTR_WorldMapRetryPending = false;
                 if (WorldMapFrame and WorldMapFrame:IsVisible() and WorldMapQuestShowObjectives and WorldMapQuestShowObjectives:GetChecked() and QTR_PS and QTR_PS["active"]=="1") then
                    QTR_event = eventName;
                    QTR_OnEvent2();
                 end
              end, "WORLD_MAP_UPDATE")) then
                 QTR_WorldMapRetryPending = false;
              end
           end
        end
     end
  end
end


-- Detect whether GetQuestID can be used safely on this client or server.
function DetectEmuServer()
  QTR_PS["isGetQuestID"]="0";
  isGetQuestID="0";
  -- Some clients do not expose GetQuestID(), and some servers can error when it is called.
  if ( type(GetQuestID) == "function" ) then
     local ok, questID = pcall(GetQuestID);
     if (ok and questID) then
        QTR_PS["isGetQuestID"]="1";
        isGetQuestID="1";
     end
  end
end


-- Queue a delayed callback on a shared frame timer.
function QTR_wait(delay, func, ...)
  if(type(delay)~="number" or type(func)~="function") then
    return false;
  end
  if(QTR_waitFrame == nil) then
    QTR_waitFrame = CreateFrame("Frame","QTR_WaitFrame", UIParent);
    QTR_waitFrame:SetScript("onUpdate",function (self,elapse)
      local count = #QTR_waitTable;
      local i = 1;
      while(i<=count) do
        local waitRecord = tremove(QTR_waitTable,i);
        local d = tremove(waitRecord,1);
        local f = tremove(waitRecord,1);
        local p = tremove(waitRecord,1);
        if(d>elapse) then
          tinsert(QTR_waitTable,i,{d-elapse,f,p});
          i = i + 1;
        else
          count = count - 1;
          f(unpack(p));
        end
      end
    end);
  end
  tinsert(QTR_waitTable,{delay,func,{...}});
  return true;
end


-- Translate the quest greeting section headers in the NPC dialog view.
local QTR_EnsureQuestGreetingWidth;
local QTR_SetQuestGreetingHeaders;


function QTR:QUEST_GREETING()
   QTR_EnsureQuestGreetingWidth();

   if (QTR_PS["active"]=="1") then
      QTR_SetQuestGreetingHeaders(true);
   else
      QTR_SetQuestGreetingHeaders(false);
   end

  if (QTR_PS["gossip"] == "1") then
     QTR_QuestGreeting_Show();
  elseif (QTR_ToggleButtonQG) then
     QTR_UpdateGreetingGoodbyeButton(QuestFrameGreetingGoodbyeButton, false);
     QTR_ToggleButtonQG:Hide();
  end
end


-- Route quest detail events into the addon translation pipeline.
function QTR:QUEST_DETAIL()
  if (QTR_ToggleButtonQG) then
     QTR_ToggleButtonQG:Hide();
  end
  QTR_event = "QUEST_DETAIL";
  if (isGetQuestID=="0") then
     if ( not QTR_wait(0.5,QTR_OnEvent2) ) then
        QTR_OnEvent2();
     end
  else
     QTR_OnEvent2();
  end
end


-- Route quest progress events into the addon translation pipeline.
function QTR:QUEST_PROGRESS()
   if (QTR_ToggleButtonQG) then
       QTR_ToggleButtonQG:Hide();
   end
  QTR_event = "QUEST_PROGRESS";
  QTR_OnEvent2();
end


-- Route quest completion events into the addon translation pipeline.
function QTR:QUEST_COMPLETE()
   if (QTR_ToggleButtonQG) then
       QTR_ToggleButtonQG:Hide();
   end
  QTR_event = "QUEST_COMPLETE";
  QTR_OnEvent2();
end


-- Translate NPC gossip content when gossip mode is enabled.
function QTR:GOSSIP_SHOW()
  if (QTR_PS["gossip"] == "1") then
       QTR_RequestGossipRefresh();
   else
       QTR_UpdateGreetingGoodbyeButton(GossipFrameGreetingGoodbyeButton, false);
  end
end  
    

-- Resolve the active quest ID and apply the correct translated content for the event.
function QTR_OnEvent2()
  local q_ID = 0;
  local q_title = GetTitleText();
  local q_i = 1;

  if ( WorldMapFrame:IsVisible() ) then
    for i = 1, MAX_NUM_QUESTS do
      questFrame = _G["WorldMapQuestFrame"..i];
      if ( not questFrame ) then
        break
      elseif ( WORLDMAP_SETTINGS.selectedQuest==questFrame ) then
            q_title = questFrame.qtrOriginalTitle or questFrame.title:GetText();
            if (questFrame.questId and questFrame.questId > 0) then
                q_ID = questFrame.questId;
            end
        break;
      end
    end
  end

  -- search in QuestLog
   while (q_ID == 0 and GetQuestLogTitle(q_i)) do
    local questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(q_i)
    if ( not isHeader ) then
       if ( q_title == questTitle ) then
          q_ID=questID;
          break;
       end
    end
    q_i = q_i + 1;
  end
  RestoreOriginalFonts();
  if ( QTR_PS["active"]=="1" )then
     -- not exist in QuestLog ?
     if ( q_ID == 0 ) then
        if ( isGetQuestID=="1" and type(GetQuestID) == "function" ) then
           local ok, questID = pcall(GetQuestID);
           if (ok and questID) then
              q_ID = questID;
           else
              DetectEmuServer();
           end
        end
        if ( q_ID == 0 ) then
           if (QTR_QuestList[q_title]) then
              local q_lists=QTR_QuestList[q_title];
              if ( string.find(q_lists, ",")==nil ) then
                 -- only 1 questID to this title
                 q_ID=tonumber(q_lists);
              else
                 -- multiple questIDs - get first, available (not completed) questID from QuestLists
                 local QTR_table=QTR_split(q_lists, ",");
                 local QTR_Center="";
                 for ii,vv in ipairs(QTR_table) do
                    if (not QTR_PC[vv]) then
                       QTR_Center=vv;
                       break;
                    elseif (QTR_Center=="") then
                       QTR_Center=vv;
                    end
                 end
                 if ( string.len(QTR_Center)>0 ) then
                    q_ID=tonumber(QTR_Center);
                 end
              end
           end
        end
     end
     if ( q_ID > 0 ) then
        local str_id = tostring(q_ID);
        if (QTR_QuestData[str_id]) then
           QTR_ChangeText_InEvent(QTR_event, str_id);
        else
           QTR_SAVED[str_id.." TITLE"]=GetTitleText();               -- save original title to future translation
           if (QTR_event=="QUEST_DETAIL") then
              QTR_SAVED[str_id.." DESCRIPTION"]=GetQuestText();      -- save original text to future translation
              QTR_SAVED[str_id.." OBJECTIVE"]=GetObjectiveText();    -- save original text to future translation
           end
           if (QTR_event=="QUEST_PROGRESS") then
              QTR_SAVED[str_id.." PROGRESS"]=GetProgressText();      -- save original text to future translation
           end
           if (QTR_event=="QUEST_COMPLETE") then
              QTR_SAVED[str_id.." COMPLETE"]=GetRewardText();        -- save original text to future translation
           end
        end
     end
  end
  if (QTR_event == "QUEST_COMPLETE") then
     if ( q_ID > 0) then
        local str_id = tostring(q_ID);
        QTR_PC[str_id]="OK";
     end
  end
end


-- Split a simple delimiter-separated string for legacy quest ID lists.
function QTR_split(str, c)
  local aCount = 0;
  local array = {};
  local a = string.find(str, c);
  while a do
     aCount = aCount + 1;
     array[aCount] = string.sub(str, 1, a-1);
     str=string.sub(str, a+1);
     a = string.find(str, c);
  end
  aCount = aCount + 1;
  array[aCount] = str;
  return array;
end


local QTR_QuestOfferButtonFontState = setmetatable({}, { __mode = "k" });


local function QTR_UpdateQuestOfferButton(button, translatedText, originalText)
  if (not button or not button.GetFontString) then
     return;
  end

  local fontString = button:GetFontString();
  if (not fontString) then
     return;
  end

  QTR_GetExternalFontState(fontString, QTR_QuestOfferButtonFontState);

  if (translatedText and translatedText ~= "") then
     button:SetText(translatedText);
     QTR_SetShapedText(fontString, translatedText, QTR_Font2 or QTR_Font1 or Original_Font2, QTR_QuestOfferButtonFontSize);
  else
     QTR_RestoreExternalFontState(fontString, QTR_QuestOfferButtonFontState);
     button:SetText(originalText or "");
  end
end


local function QTR_UpdateQuestOfferButtons(activeEvent)
   local showDetailButtons = (activeEvent == "QUEST_DETAIL");
   local showProgressButtons = (activeEvent == "QUEST_PROGRESS");
   local showRewardButtons = (activeEvent == "QUEST_COMPLETE");

   QTR_UpdateQuestOfferButton(QuestFrameAcceptButton, (showDetailButtons and QTR_Messages and QTR_Messages.accept) or nil, QTR_MessOrig.accept);
   QTR_UpdateQuestOfferButton(QuestFrameDeclineButton, (showDetailButtons and QTR_Messages and QTR_Messages.decline) or nil, QTR_MessOrig.decline);
   QTR_UpdateQuestOfferButton(QuestFrameCompleteButton, (showProgressButtons and QTR_Messages and QTR_Messages.continue) or nil, QTR_MessOrig.continue);
   QTR_UpdateQuestOfferButton(QuestFrameGoodbyeButton, (showProgressButtons and QTR_Messages and QTR_Messages.cancel) or nil, QTR_MessOrig.cancel);
   QTR_UpdateQuestOfferButton(QuestFrameCompleteQuestButton, (showRewardButtons and QTR_Messages and QTR_Messages.completequest) or nil, QTR_MessOrig.completequest);
   QTR_UpdateQuestOfferButton(QuestFrameCancelButton, (showRewardButtons and QTR_Messages and QTR_Messages.cancel) or nil, QTR_MessOrig.cancel);
end




-- Restore Blizzard quest fonts, headings, and reward labels.
function RestoreOriginalFonts()
  QuestInfoTitleHeader:SetFont(Original_Font1, 18);
   QuestInfoTitleHeader:SetJustifyH("LEFT");
   QTR_UpdateQuestOfferButtons(nil);
  QuestInfoDescriptionHeader:SetText(QTR_MessOrig.details);
  QuestInfoDescriptionHeader:SetFont(Original_Font1, 18);
   QuestInfoDescriptionHeader:SetJustifyH("LEFT");
  QuestInfoDescriptionText:SetFont(Original_Font2, 13);
   QuestInfoDescriptionText:SetJustifyH("LEFT");
  QuestInfoObjectivesHeader:SetText(QTR_MessOrig.objectives);
  QuestInfoObjectivesHeader:SetFont(Original_Font1, 18);
   QuestInfoObjectivesHeader:SetJustifyH("LEFT");
  QuestInfoObjectivesText:SetFont(Original_Font2, 13);
   QuestInfoObjectivesText:SetJustifyH("LEFT");
  QuestInfoRewardsHeader:SetText(QTR_MessOrig.rewards);
  QuestInfoRewardsHeader:SetFont(Original_Font1, 18);
   QuestInfoRewardsHeader:SetJustifyH("LEFT");
  QuestInfoRewardText:SetFont(Original_Font2, 13);
   QuestInfoRewardText:SetJustifyH("LEFT");
   QuestInfoItemChooseText:SetFont(Original_Font2, 13);
   QuestInfoItemChooseText:SetJustifyH("LEFT");
   QuestInfoItemReceiveText:SetFont(Original_Font2, 13);
   QuestInfoItemReceiveText:SetJustifyH("LEFT");
  QuestInfoXPFrameReceiveText:SetText(QTR_MessOrig.experience);
  QuestInfoXPFrameReceiveText:SetFont(Original_Font2, 13);
   QuestInfoXPFrameReceiveText:SetJustifyH("LEFT");
  if (QuestInfoTalentFrameReceiveText) then
     QuestInfoTalentFrameReceiveText:SetText(QTR_MessOrig.bonustalents);
     QuestInfoTalentFrameReceiveText:SetFont(Original_Font2, 13);
     QuestInfoTalentFrameReceiveText:SetJustifyH("LEFT");
  end
  QuestInfoRequiredMoneyText:SetText(QTR_MessOrig.reqmoney);
  QuestInfoRequiredMoneyText:SetFont(Original_Font2, 13);
   QuestInfoRequiredMoneyText:SetJustifyH("LEFT");
  QuestInfoSpellLearnText:SetText(QTR_MessOrig.learnspell);
  QuestInfoSpellLearnText:SetFont(Original_Font2, 13);
   QuestInfoSpellLearnText:SetJustifyH("LEFT");
  QuestProgressTitleText:SetFont(Original_Font1, 18);
   QuestProgressTitleText:SetJustifyH("LEFT");
  QuestProgressText:SetFont(Original_Font2, 13);
   QuestProgressText:SetJustifyH("LEFT");
   QTR_ApplyRTLWidthAdjustment(QuestProgressText, false);
  QuestProgressRequiredItemsText:SetText(QTR_MessOrig.reqitems);
  QuestProgressRequiredItemsText:SetFont(Original_Font1, 18);
   QuestProgressRequiredItemsText:SetJustifyH("LEFT");
   QTR_ApplyRTLWidthAdjustment(QuestProgressRequiredItemsText, false);
   QTR_UpdateQuestLogObjectiveFrames();
  QuestProgressRequiredMoneyText:SetText(QTR_MessOrig.reqmoney);
  QuestProgressRequiredMoneyText:SetFont(Original_Font2, 13);
   QuestProgressRequiredMoneyText:SetJustifyH("LEFT");
   QTR_RestoreWorldMapRewards();
end


-- Replace live quest dialog text inside the Blizzard quest frame.
function QTR_ChangeText_InEvent(QTR_event, str_id)
   QTR_UpdateQuestOfferButtons(QTR_event);
  if (QTR_PS["transtitle"]=="1") then
   QTR_SetShapedTitleText(QuestInfoTitleHeader, QTR_GetTranslatedQuestTitleById(str_id), QTR_Font1, 18, QuestInfoTitleHeader:GetWidth());
   QTR_SetShapedTitleText(QuestProgressTitleText, QTR_GetTranslatedQuestTitleById(str_id), QTR_Font1, 18, QuestProgressTitleText:GetWidth());
  end
  QTR_SetShapedText(QuestInfoDescriptionHeader, QTR_Messages.details, QTR_Font1, 18);
   QTR_SetShapedText(QuestInfoDescriptionText, QTR_ExpandUnitInfo(QTR_QuestData[str_id]["Description"]), QTR_Font1, 13, QTR_QuestBodyLimit);
  QTR_SetShapedText(QuestInfoObjectivesHeader, QTR_Messages.objectives, QTR_Font1, 18);
   QTR_SetShapedText(QuestInfoObjectivesText, QTR_ExpandUnitInfo(QTR_QuestData[str_id]["Objectives"]), QTR_Font1, 13, QTR_QuestBodyLimit);
  QTR_SetShapedText(QuestInfoRewardsHeader, QTR_Messages.rewards, QTR_Font1, 18);
   QTR_SetShapedText(QuestInfoRewardText, QTR_ExpandUnitInfo(QTR_QuestData[str_id]["Completion"]), QTR_Font1, 13, QTR_QuestBodyLimit);
  if (QTR_event=="QUEST_COMPLETE") then
     QTR_SetShapedText(QuestInfoItemChooseText, QTR_Messages.itemchoose2, QTR_Font2, 13);
     QTR_SetShapedText(QuestInfoItemReceiveText, QTR_Messages.itemreceiv2, QTR_Font2, 13);
  else
     QTR_SetShapedText(QuestInfoItemChooseText, QTR_Messages.itemchoose1, QTR_Font2, 13);
     QTR_SetShapedText(QuestInfoItemReceiveText, QTR_Messages.itemreceiv1, QTR_Font2, 13);
  end
  QTR_SetShapedText(QuestInfoXPFrameReceiveText, QTR_Messages.experience, QTR_Font2, 13);
  if (QuestInfoTalentFrameReceiveText and QTR_Messages.bonustalents) then
     QTR_SetShapedText(QuestInfoTalentFrameReceiveText, QTR_Messages.bonustalents, QTR_Font2, 13);
  end
  QTR_SetShapedText(QuestInfoRequiredMoneyText, QTR_Messages.reqmoney, QTR_Font2, 13);
  QTR_SetShapedText(QuestInfoSpellLearnText, QTR_Messages.learnspell, QTR_Font2, 13);
   QTR_SetShapedText(QuestProgressText, QTR_ExpandUnitInfo(QTR_QuestData[str_id]["Progress"]), QTR_Font1, 13, QTR_QuestBodyLimit);
  QTR_SetShapedText(QuestProgressRequiredMoneyText, QTR_Messages.reqmoney, QTR_Font2, 13);
  QTR_SetShapedText(QuestProgressRequiredItemsText, QTR_Messages.reqitems, QTR_Font1, 18);
  if (WorldMapFrame and WorldMapFrame:IsVisible()) then
     local itemChooseText = QTR_Messages.itemchoose1;
     local itemReceiveText = QTR_Messages.itemreceiv1;
     if (QTR_event=="QUEST_COMPLETE") then
        itemChooseText = QTR_Messages.itemchoose2;
        itemReceiveText = QTR_Messages.itemreceiv2;
     end
     QTR_UpdateWorldMapRewards(itemChooseText, itemReceiveText);
  end
end


-- Replace quest log detail text when a translated quest is selected.
function QTR_ChangeText_OnQuestLog(qid)
  if (QTR_PS["transtitle"]=="1") then
         QTR_SetShapedTitleText(QuestInfoTitleHeader, QTR_GetTranslatedQuestTitleById(qid), QTR_Font1, 18, QuestInfoTitleHeader:GetWidth());
  end
   QTR_SetShapedText(QuestInfoDescriptionHeader, QTR_Messages.details, QTR_Font1, 18);
   QTR_SetShapedText(QuestInfoDescriptionText, QTR_description, QTR_Font2, 13, QTR_QuestBodyLimit);
   QTR_SetShapedText(QuestInfoObjectivesHeader, QTR_Messages.objectives, QTR_Font1, 18);
   QTR_SetShapedText(QuestInfoObjectivesText, QTR_objectives, QTR_Font2, 13, QTR_QuestBodyLimit);
   QTR_UpdateQuestLogObjectiveFrames();
   QTR_SetShapedText(QuestInfoRequiredMoneyText, QTR_Messages.reqmoney, QTR_Font2, 13);
end


-- Set the gossip greeting text with explicit font and alignment.
local QTR_GreetingButtonFontState = setmetatable({}, { __mode = "k" });


local function QTR_EnsureGossipGreetingWidth(useArabicLayout)
   if (not GossipGreetingText) then
      return nil;
   end

   local targetWidth = QTR_GossipGreetingTextTargetWidth;
   local parentFrame = GossipGreetingText:GetParent();
   if (parentFrame and parentFrame.GetWidth) then
      local parentWidth = parentFrame:GetWidth();
      if (parentWidth and parentWidth > 0) then
         local parentPadding = useArabicLayout and QTR_GossipGreetingArabicParentPadding or QTR_GossipGreetingDefaultParentPadding;
         targetWidth = math.min(targetWidth, parentWidth - parentPadding);
      end
   end

   if (useArabicLayout) then
      targetWidth = targetWidth + QTR_GossipGreetingArabicExtraWidth;
   end

   if (targetWidth < QTR_GossipGreetingMinWidth) then
      targetWidth = QTR_GossipGreetingMinWidth;
   end

   GossipGreetingText:SetWidth(targetWidth);
   QTR_FontStringWidthCache[GossipGreetingText] = targetWidth;

   if (useArabicLayout) then
      return targetWidth + (QTR_GetRTLWidthAdjustment(GossipGreetingText, GossipGreetingText) or 0);
   end

   return targetWidth;
end


local function QTR_UpdateGossipGreetingAnchor(useArabicLayout)
   if (not GossipGreetingText) then
      return;
   end

   local parentFrame = GossipGreetingText:GetParent();
   if (not parentFrame) then
      return;
   end

   local offsetX = QTR_GossipGreetingTextOffsetX;
   if (useArabicLayout) then
      offsetX = offsetX + QTR_GossipGreetingArabicOffsetX;
   end

   GossipGreetingText:ClearAllPoints();
   GossipGreetingText:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", offsetX, QTR_GossipGreetingTextOffsetY);
end


local function QTR_SetGossipGreetingText(text, fontName, fontSize, justify)
   local useArabicLayout = text and AS_ContainsArabic and AS_ContainsArabic(text);
   fontName = fontName or ((useArabicLayout and QTR_Font1) or Original_Font2);
   fontSize = fontSize or QTR_GossipGreetingFontSize;
   QTR_EnsureGossipGreetingWidth(useArabicLayout);
   QTR_UpdateGossipGreetingAnchor(useArabicLayout);
   GossipGreetingText:SetFont(fontName, fontSize);
   QTR_ApplyRTLWidthAdjustment(GossipGreetingText, useArabicLayout, GossipGreetingText);
   GossipGreetingText:SetJustifyH(justify or "LEFT");
   GossipGreetingText:SetText(text or "");
end


local function QTR_GetGossipGreetingWrapWidth()
   local wrapWidth = QTR_EnsureGossipGreetingWidth(true);
   if ((not wrapWidth or wrapWidth <= 0) and GossipGreetingText and GossipGreetingText.GetWidth) then
      wrapWidth = GossipGreetingText:GetWidth();
   end
   if (not wrapWidth or wrapWidth <= 0) then
      wrapWidth = QTR_GossipGreetingTextTargetWidth;
   end

   wrapWidth = wrapWidth - QTR_GossipGreetingWrapPadding;
   if (wrapWidth < QTR_GossipGreetingMinWidth) then
      wrapWidth = QTR_GossipGreetingMinWidth;
   end

   return wrapWidth;
end


local function QTR_UpdateGreetingGoodbyeButton(button, showArabic)
   if (not button or not button.GetFontString) then
      return;
   end

   local fontString = button:GetFontString();
   if (not fontString) then
      return;
   end

   QTR_GetExternalFontState(fontString, QTR_GreetingButtonFontState);

   if (showArabic and QTR_Messages and QTR_Messages.goodbye) then
      button:SetText(QTR_Messages.goodbye);
      QTR_SetShapedText(fontString, QTR_Messages.goodbye, QTR_Font2 or QTR_Font1 or Original_Font2, QTR_GreetingGoodbyeFontSize);
   else
      QTR_RestoreExternalFontState(fontString, QTR_GreetingButtonFontState);
      button:SetText(QTR_MessOrig.goodbye or GOODBYE or "Goodbye");
   end
end


-- Set the quest greeting text with explicit font and alignment.
local function QTR_SetQuestGreetingText(text, fontName, fontSize, justify)
   if (not GreetingText) then
      return;
   end

   fontSize = fontSize or QTR_QuestGreetingFontSize;
   GreetingText:SetText(text or "");
   GreetingText:SetFont(fontName, fontSize);
   GreetingText:SetJustifyH(justify or "LEFT");
end

QTR_EnsureQuestGreetingWidth = function()
   if (not GreetingText) then
      return;
   end

   local targetWidth = QTR_QuestGreetingTextTargetWidth;
   local parentFrame = GreetingText:GetParent();

   if (parentFrame and parentFrame.GetWidth) then
      local parentWidth = parentFrame:GetWidth();
      if (parentWidth and parentWidth > 0) then
         targetWidth = math.min(targetWidth, parentWidth - QTR_QuestGreetingParentPadding);
      end
   end

   if (targetWidth < QTR_QuestGreetingMinWidth) then
      targetWidth = QTR_QuestGreetingMinWidth;
   end

   GreetingText:SetWidth(targetWidth);
end


QTR_SetQuestGreetingHeaders = function(showArabic)
   if (CurrentQuestsText) then
      CurrentQuestsText:SetWidth(QTR_QuestGreetingHeaderWidth);
   end

   if (AvailableQuestsText) then
      AvailableQuestsText:SetWidth(QTR_QuestGreetingHeaderWidth);
   end

   if (showArabic) then
      if (CurrentQuestsText) then
         QTR_SetShapedText(CurrentQuestsText, QTR_Messages.currquests, QTR_Font1, QTR_QuestGreetingHeaderFontSize);
      end
      if (AvailableQuestsText) then
         QTR_SetShapedText(AvailableQuestsText, QTR_Messages.avaiquests, QTR_Font1, QTR_QuestGreetingHeaderFontSize);
      end
   else
      if (CurrentQuestsText) then
         CurrentQuestsText:SetText(QTR_MessOrig.currquests);
         CurrentQuestsText:SetFont(Original_Font1, QTR_QuestGreetingHeaderFontSize);
         CurrentQuestsText:SetJustifyH("LEFT");
      end
      if (AvailableQuestsText) then
         AvailableQuestsText:SetText(QTR_MessOrig.avaiquests);
         AvailableQuestsText:SetFont(Original_Font1, QTR_QuestGreetingHeaderFontSize);
         AvailableQuestsText:SetJustifyH("LEFT");
      end
   end
end


local QTR_GuildRegistrarFontState = setmetatable({}, { __mode = "k" });


local function QTR_UpdateGuildRegistrarWrappedText(fontString, translatedText, originalText, fontName, fallbackSize)
   if (not fontString) then
      return;
   end

   QTR_GetExternalFontState(fontString, QTR_GuildRegistrarFontState);
   local _, fontSize = fontString:GetFont();
   if (translatedText and translatedText ~= "") then
      local wrapWidth = (fontString.GetWidth and fontString:GetWidth()) or 0;
      QTR_SetShapedTitleText(fontString, translatedText, fontName or QTR_Font1 or QTR_Font2 or Original_Font2, fontSize or fallbackSize or 13, wrapWidth);
   else
      QTR_RestoreExternalFontState(fontString, QTR_GuildRegistrarFontState);
      fontString:SetText(originalText or "");
   end
end


local function QTR_UpdateGuildRegistrarInlineText(fontString, translatedText, originalText, fontName, fallbackSize)
   if (not fontString) then
      return;
   end

   QTR_GetExternalFontState(fontString, QTR_GuildRegistrarFontState);
   local _, fontSize = fontString:GetFont();
   if (translatedText and translatedText ~= "") then
      QTR_SetShapedText(fontString, translatedText, fontName or QTR_Font2 or QTR_Font1 or Original_Font2, fontSize or fallbackSize or 13);
   else
      QTR_RestoreExternalFontState(fontString, QTR_GuildRegistrarFontState);
      fontString:SetText(originalText or "");
   end
end


local function QTR_UpdateGuildRegistrarOptionButton(titleButton, translatedText, originalText)
   if (not titleButton) then
      return;
   end

   if (translatedText and translatedText ~= "") then
      local displayText = QTR_PrepareTitleButtonArabicText(titleButton, translatedText, QTR_Font1 or QTR_Font2 or Original_Font2, 13);
      QTR_SetTitleButtonText(titleButton, displayText, QTR_Font1 or QTR_Font2 or Original_Font2, 13);
   else
      QTR_RestoreTitleButtonFont(titleButton);
      titleButton:SetText(originalText or "");
   end
end


function QTR_FindFrameFontStringByText(frame, ...)
   if (not frame or not frame.GetRegions) then
      return nil;
   end

   local candidates = { ... };
   local regions = { frame:GetRegions() };
   for _, region in ipairs(regions) do
      if (region and region.GetObjectType and region:GetObjectType() == "FontString") then
         local regionText = region:GetText() or "";
         for _, candidateText in ipairs(candidates) do
            if (candidateText and candidateText ~= "" and regionText == candidateText) then
               return region;
            end
         end
      end
   end

   return nil;
end


function QTR_GetArenaRegistrarGreetingLabels()
   if (not ArenaRegistrarGreetingFrame) then
      return nil, nil;
   end

   local purchaseLabel = ArenaRegistrarGreetingFrame.qtrPurchaseLabel;
   local registrationLabel = ArenaRegistrarGreetingFrame.qtrRegistrationLabel;

   if (purchaseLabel and purchaseLabel.GetParent and purchaseLabel:GetParent() ~= ArenaRegistrarGreetingFrame) then
      purchaseLabel = nil;
      ArenaRegistrarGreetingFrame.qtrPurchaseLabel = nil;
   end
   if (registrationLabel and registrationLabel.GetParent and registrationLabel:GetParent() ~= ArenaRegistrarGreetingFrame) then
      registrationLabel = nil;
      ArenaRegistrarGreetingFrame.qtrRegistrationLabel = nil;
   end

   if (not purchaseLabel) then
      purchaseLabel = QTR_FindFrameFontStringByText(ArenaRegistrarGreetingFrame, QTR_MessOrig.arenacharterpurchase, ARENA_CHARTER_PURCHASE);
   end
   if (not registrationLabel) then
      registrationLabel = QTR_FindFrameFontStringByText(ArenaRegistrarGreetingFrame, QTR_MessOrig.arenacharterturnin, ARENA_CHARTER_TURN_IN);
   end

   if (not purchaseLabel and AvailableServicesText and AvailableServicesText.GetParent and AvailableServicesText:GetParent() == ArenaRegistrarGreetingFrame) then
      purchaseLabel = AvailableServicesText;
   end
   if (not registrationLabel and RegistrationText and RegistrationText.GetParent and RegistrationText:GetParent() == ArenaRegistrarGreetingFrame) then
      registrationLabel = RegistrationText;
   end

   if (purchaseLabel) then
      ArenaRegistrarGreetingFrame.qtrPurchaseLabel = purchaseLabel;
   end
   if (registrationLabel) then
      ArenaRegistrarGreetingFrame.qtrRegistrationLabel = registrationLabel;
   end

   return purchaseLabel, registrationLabel;
end


-- Translate the guild registrar's special greeting and purchase frames.
QTR_UpdateGuildRegistrarFrame = function()
   if (not GuildRegistrarFrame) then
      return;
   end

   local showArabic = (QTR_PS and QTR_PS["active"] == "1");
   local showArabicGossip = (QTR_PS and QTR_PS["gossip"] == "1");
   local showOriginalText = (GuildRegistrarFrame.qtrShowOriginalText == true);
   local showArabicHeader = (showArabic and not showOriginalText);
   local showArabicGossipText = (showArabicGossip and not showOriginalText);

   if (QTR_ToggleButtonGR) then
      if ((showArabic or showArabicGossip) and GuildRegistrarFrame.IsShown and GuildRegistrarFrame:IsShown()) then
         QTR_ToggleButtonGR:SetText(showOriginalText and "AR" or "OG");
         QTR_ToggleButtonGR:Show();
      else
         QTR_ToggleButtonGR:Hide();
      end
   end

   if (GuildRegistrarText and GuildRegistrarText.GetText) then
      local currentText = GuildRegistrarText:GetText() or "";
      if (currentText ~= "" and not QTR_IsArabicGossipText(currentText)) then
         GuildRegistrarText.qtrOriginalDisplayText = currentText;
      end

      local originalText = GuildRegistrarText.qtrOriginalDisplayText or currentText;
      local translatedText = nil;
      if (showArabicGossipText and originalText ~= "") then
         translatedText = QTR_GetExternalGossipBodyTranslation(originalText, true);
      end

      QTR_UpdateGuildRegistrarWrappedText(GuildRegistrarText, translatedText, originalText, QTR_Font1 or QTR_Font2 or Original_Font2, 13);
   end

   local translatedServicesText = (showArabicHeader and QTR_Messages and QTR_Messages.guildservices) or nil;
   if (AvailableServicesText) then
      AvailableServicesText:SetWidth((translatedServicesText and translatedServicesText ~= "") and 280 or 300);
   end
   QTR_UpdateGuildRegistrarWrappedText(AvailableServicesText, translatedServicesText, QTR_MessOrig.guildservices, QTR_Font1 or QTR_Font2 or Original_Font1, 18);

   local translatedPurchaseButton = (showArabicGossipText and QTR_Messages and QTR_Messages.guildcharterpurchase) or nil;
   local translatedRegisterButton = (showArabicGossipText and QTR_Messages and QTR_Messages.guildcharterregister) or nil;
   QTR_UpdateGuildRegistrarOptionButton(GuildRegistrarButton1, translatedPurchaseButton, QTR_MessOrig.guildcharterpurchase);
   QTR_UpdateGuildRegistrarOptionButton(GuildRegistrarButton2, translatedRegisterButton, QTR_MessOrig.guildcharterregister);

   local translatedPurchaseText = (showArabicGossipText and QTR_Messages and QTR_Messages.guildpurchaseinfo) or nil;
   local translatedCostLabel = (showArabicHeader and QTR_Messages and QTR_Messages.costlabel) or nil;
   local translatedPurchaseAction = (showArabicHeader and QTR_Messages and QTR_Messages.purchase) or nil;
   local translatedCancelAction = (showArabicHeader and QTR_Messages and QTR_Messages.cancel) or nil;

   QTR_UpdateGuildRegistrarWrappedText(GuildRegistrarPurchaseText, translatedPurchaseText, QTR_MessOrig.guildpurchaseinfo, QTR_Font2 or QTR_Font1 or Original_Font2, 13);
   QTR_UpdateGuildRegistrarInlineText(GuildRegistrarCostLabel, translatedCostLabel, QTR_MessOrig.costlabel, QTR_Font2 or QTR_Font1 or Original_Font2, 13);
   QTR_UpdateGuildRegistrarInlineText((GuildRegistrarFramePurchaseButton and GuildRegistrarFramePurchaseButton:GetFontString()) or nil, translatedPurchaseAction, QTR_MessOrig.purchase, QTR_Font2 or QTR_Font1 or Original_Font2, 13);
   QTR_UpdateGuildRegistrarInlineText((GuildRegistrarFrameCancelButton and GuildRegistrarFrameCancelButton:GetFontString()) or nil, translatedCancelAction, QTR_MessOrig.cancel, QTR_Font2 or QTR_Font1 or Original_Font2, 13);
   QTR_UpdateGuildRegistrarInlineText((GuildRegistrarFrameGoodbyeButton and GuildRegistrarFrameGoodbyeButton:GetFontString()) or nil, translatedCancelAction, QTR_MessOrig.cancel, QTR_Font2 or QTR_Font1 or Original_Font2, 13);
end


QTR_UpdateArenaRegistrarFrame = function()
   if (not ArenaRegistrarFrame) then
      return;
   end

   if (not ArenaRegistrarFrame.qtrToggleButton) then
      ArenaRegistrarFrame.qtrToggleButton = CreateFrame("Button", nil, ArenaRegistrarFrame, "UIPanelButtonTemplate");
      ArenaRegistrarFrame.qtrToggleButton:SetWidth(52);
      ArenaRegistrarFrame.qtrToggleButton:SetHeight(20);
      ArenaRegistrarFrame.qtrToggleButton:SetText("EN");
      ArenaRegistrarFrame.qtrToggleButton:ClearAllPoints();
      ArenaRegistrarFrame.qtrToggleButton:SetPoint("TOPLEFT", ArenaRegistrarFrame, "TOPLEFT", 78, -50);
      ArenaRegistrarFrame.qtrToggleButton:SetScript("OnClick", function()
         ArenaRegistrarFrame.qtrShowOriginalText = not ArenaRegistrarFrame.qtrShowOriginalText;
         QTR_UpdateArenaRegistrarFrame();
      end);
      ArenaRegistrarFrame.qtrToggleButton:Hide();
   end

   local showArabic = (QTR_PS and QTR_PS["active"] == "1");
   local showArabicGossip = (QTR_PS and QTR_PS["gossip"] == "1");
   local showOriginalText = (ArenaRegistrarFrame.qtrShowOriginalText == true);
   local showArabicHeader = (showArabic and not showOriginalText);
   local showArabicGossipText = (showArabicGossip and showArabic and not showOriginalText);

   if (ArenaRegistrarFrame.qtrToggleButton) then
      if ((showArabic or showArabicGossipText) and ArenaRegistrarFrame.IsShown and ArenaRegistrarFrame:IsShown()) then
         ArenaRegistrarFrame.qtrToggleButton:SetText(showOriginalText and "AR" or "OG");
         ArenaRegistrarFrame.qtrToggleButton:Show();
      else
         ArenaRegistrarFrame.qtrToggleButton:Hide();
      end
   end

   if (ArenaRegistrarText and ArenaRegistrarText.GetText) then
      local currentText = ArenaRegistrarText:GetText() or "";
      if (currentText ~= "" and not QTR_IsArabicGossipText(currentText)) then
         ArenaRegistrarText.qtrOriginalDisplayText = currentText;
      end

      local originalText = ArenaRegistrarText.qtrOriginalDisplayText or currentText;
      local translatedText = nil;
      if (showArabicGossipText and originalText ~= "") then
         translatedText = QTR_GetExternalGossipBodyTranslation(originalText, true);
      end

      QTR_UpdateGuildRegistrarWrappedText(ArenaRegistrarText, translatedText, originalText, QTR_Font1 or QTR_Font2 or Original_Font2, 13);
   end

   local arenaPurchaseLabel, arenaRegistrationLabel = QTR_GetArenaRegistrarGreetingLabels();
   if (arenaPurchaseLabel) then
      arenaPurchaseLabel:SetWidth(((showArabicHeader and QTR_Messages and QTR_Messages.arenacharterpurchase) and 280) or 300);
   end

   QTR_UpdateGuildRegistrarWrappedText(arenaPurchaseLabel, (showArabicHeader and QTR_Messages and QTR_Messages.arenacharterpurchase) or nil, QTR_MessOrig.arenacharterpurchase, QTR_Font1 or QTR_Font2 or Original_Font1, 18);
   QTR_UpdateGuildRegistrarWrappedText(arenaRegistrationLabel, (showArabicHeader and QTR_Messages and QTR_Messages.arenacharterturnin) or nil, QTR_MessOrig.arenacharterturnin, QTR_Font1 or QTR_Font2 or Original_Font1, 18);

   local translatedTeam2v2 = (showArabicGossipText and QTR_Messages and QTR_Messages.arenateam2v2) or nil;
   local translatedTeam3v3 = (showArabicGossipText and QTR_Messages and QTR_Messages.arenateam3v3) or nil;
   local translatedTeam5v5 = (showArabicGossipText and QTR_Messages and QTR_Messages.arenateam5v5) or nil;

   QTR_UpdateGuildRegistrarOptionButton(ArenaRegistrarButton1, translatedTeam2v2, QTR_MessOrig.arenateam2v2);
   QTR_UpdateGuildRegistrarOptionButton(ArenaRegistrarButton2, translatedTeam3v3, QTR_MessOrig.arenateam3v3);
   QTR_UpdateGuildRegistrarOptionButton(ArenaRegistrarButton3, translatedTeam5v5, QTR_MessOrig.arenateam5v5);
   QTR_UpdateGuildRegistrarOptionButton(ArenaRegistrarButton4, translatedTeam2v2, QTR_MessOrig.arenateam2v2);
   QTR_UpdateGuildRegistrarOptionButton(ArenaRegistrarButton5, translatedTeam3v3, QTR_MessOrig.arenateam3v3);
   QTR_UpdateGuildRegistrarOptionButton(ArenaRegistrarButton6, translatedTeam5v5, QTR_MessOrig.arenateam5v5);

   if (ArenaRegistrarPurchaseText) then
      ArenaRegistrarPurchaseText:SetWidth(((showArabicGossipText and QTR_Messages and QTR_Messages.arenapurchaseinfo) and 280) or 270);
   end

   QTR_UpdateGuildRegistrarWrappedText(ArenaRegistrarPurchaseText, (showArabicGossipText and QTR_Messages and QTR_Messages.arenapurchaseinfo) or nil, QTR_MessOrig.arenapurchaseinfo, QTR_Font2 or QTR_Font1 or Original_Font2, 13);
   QTR_UpdateGuildRegistrarInlineText(ArenaRegistrarCostLabel, (showArabicHeader and QTR_Messages and QTR_Messages.costlabel) or nil, QTR_MessOrig.costlabel, QTR_Font2 or QTR_Font1 or Original_Font2, 13);
   QTR_UpdateGuildRegistrarInlineText((ArenaRegistrarFramePurchaseButton and ArenaRegistrarFramePurchaseButton:GetFontString()) or nil, (showArabicHeader and QTR_Messages and QTR_Messages.purchase) or nil, QTR_MessOrig.purchase, QTR_Font2 or QTR_Font1 or Original_Font2, 13);
   QTR_UpdateGuildRegistrarInlineText((ArenaRegistrarFrameCancelButton and ArenaRegistrarFrameCancelButton:GetFontString()) or nil, (showArabicHeader and QTR_Messages and QTR_Messages.cancel) or nil, QTR_MessOrig.cancel, QTR_Font2 or QTR_Font1 or Original_Font2, 13);
   QTR_UpdateGuildRegistrarInlineText((ArenaRegistrarFrameGoodbyeButton and ArenaRegistrarFrameGoodbyeButton:GetFontString()) or nil, (showArabicHeader and QTR_Messages and QTR_Messages.cancel) or nil, QTR_MessOrig.cancel, QTR_Font2 or QTR_Font1 or Original_Font2, 13);
end


-- Translate reward labels inside the world map quest detail panel.
QTR_UpdateWorldMapRewards = function(itemChooseText, itemReceiveText)
   if (QuestMapFrame and QuestMapFrame.DetailsFrame and QuestMapFrame.DetailsFrame.RewardsFrame) then
      local regions = { QuestMapFrame.DetailsFrame.RewardsFrame:GetRegions() };
      for index = 1, #regions do
         local region = regions[index];
         if ((region:GetObjectType() == "FontString") and (region:GetText() == QUEST_REWARDS or region:GetText() == QTR_Messages.rewards or region:GetText() == QTR_MessOrig.rewards)) then
            local _, size = region:GetFont();
            QTR_SetShapedText(region, QTR_Messages.rewards, QTR_Font1, size or 18);
         end
      end
   end

   if (MapQuestInfoRewardsFrame and MapQuestInfoRewardsFrame.ItemChooseText) then
      local lineSize = MapQuestInfoRewardsFrame.ItemChooseText:GetWidth();
      QTR_SetShapedText(MapQuestInfoRewardsFrame.ItemChooseText, itemChooseText, QTR_Font2, 11);
      if (MapQuestInfoRewardsFrame.ItemReceiveText) then
         MapQuestInfoRewardsFrame.ItemReceiveText:SetWidth(lineSize);
         QTR_SetShapedText(MapQuestInfoRewardsFrame.ItemReceiveText, itemReceiveText, QTR_Font2, 11);
      end
   end

   if (QuestInfoTalentFrameReceiveText and QTR_Messages and QTR_Messages.bonustalents) then
      local _, talentSize = QuestInfoTalentFrameReceiveText:GetFont();
      QTR_SetShapedText(QuestInfoTalentFrameReceiveText, QTR_Messages.bonustalents, QTR_Font2, talentSize or 13);
   end
end


-- Restore original reward labels inside the world map quest detail panel.
QTR_RestoreWorldMapRewards = function()
   if (QuestMapFrame and QuestMapFrame.DetailsFrame and QuestMapFrame.DetailsFrame.RewardsFrame) then
      local regions = { QuestMapFrame.DetailsFrame.RewardsFrame:GetRegions() };
      for index = 1, #regions do
         local region = regions[index];
         if ((region:GetObjectType() == "FontString") and (region:GetText() == QTR_Messages.rewards or region:GetText() == QTR_MessOrig.rewards)) then
            local _, size = region:GetFont();
            region:SetFont(Original_Font1, size or 18);
            region:SetJustifyH("LEFT");
            region:SetText(QUEST_REWARDS);
         end
      end
   end

   if (MapQuestInfoRewardsFrame and MapQuestInfoRewardsFrame.ItemChooseText) then
      MapQuestInfoRewardsFrame.ItemChooseText:SetFont(Original_Font2, 11);
      MapQuestInfoRewardsFrame.ItemChooseText:SetJustifyH("LEFT");
      MapQuestInfoRewardsFrame.ItemChooseText:SetText(QTR_MessOrig.itemchoose1);
      if (MapQuestInfoRewardsFrame.ItemReceiveText) then
         MapQuestInfoRewardsFrame.ItemReceiveText:SetFont(Original_Font2, 11);
         MapQuestInfoRewardsFrame.ItemReceiveText:SetJustifyH("LEFT");
         MapQuestInfoRewardsFrame.ItemReceiveText:SetText(QTR_MessOrig.itemreceiv1);
      end
   end

   if (QuestInfoTalentFrameReceiveText) then
      local _, talentSize = QuestInfoTalentFrameReceiveText:GetFont();
      QuestInfoTalentFrameReceiveText:SetFont(Original_Font2, talentSize or 13);
      QuestInfoTalentFrameReceiveText:SetJustifyH("LEFT");
      QuestInfoTalentFrameReceiveText:SetText(QTR_MessOrig.bonustalents);
   end
end


-- Restore a saved set of gossip or quest button texts.
local function QTR_RestoreGossipButtons(savedTexts, fontName, fontSize)
   for titleButton, buttonText in pairs(savedTexts) do
      if (titleButton) then
         QTR_SetTitleButtonText(titleButton, buttonText, fontName, fontSize);
      end
   end
end


local function QTR_RestoreVisibleGossipTitleButtons()
   local maxGossipButtons = NUMGOSSIPBUTTONS or 32;
   for i = 1, maxGossipButtons do
      local titleButton = _G["GossipTitleButton"..tostring(i)];
      if (titleButton and titleButton:IsShown()) then
         QTR_RestoreTitleButtonFont(titleButton);
      end
   end
end


-- Force the quest log to redraw its original Blizzard text.
local function QTR_RestoreQuestLogEnglish()
  if (not QuestLogFrame or not QuestLogFrame:IsVisible()) then
     return;
  end

  if (QuestLog_UpdateQuestDetails) then
     QuestLog_UpdateQuestDetails();
  end

  if (QuestLog_Update) then
     QuestLog_Update();
  end

   QTR_RestoreQuestLogTitleButtons();
end


-- Toggle the addon on or off from the quest log button.
function QTR_ToggleVisibility()
  -- click on QTR button in QuestLogFrame
  if (QTR_PS["active"]=="0") then
     QTR_PS["active"] = "1";
     QTR_ShowAndUpdateQuestInfo();
    QTR_AddLocalizedSystemMessage("|cffffff00ArWoW-Quests ", QTR_Messages.isactive);
  else
     QTR_PS["active"] = "0";
     QTR_HideQuestInfo();
    QTR_AddLocalizedSystemMessage("|cffffff00ArWoW-Quests ", QTR_Messages.isinactive);
     RestoreOriginalFonts();
     QTR_RestoreQuestLogEnglish();
  end
   QTR_UpdateQuestLogToggleButtonText();
   QTR_UpdateGuildRegistrarFrame();
   QTR_UpdateArenaRegistrarFrame();
   QTR_RefreshWorldMapQuestList();
   QTR_RefreshWatchFrame();
   QTR_RefreshQuestieTracker();
   QTR_RefreshQuestieArrow();
   QTR_RefreshImmersionLiveView();
   QTR_RefreshStorylineLiveView();
end


-- Refresh translated quest details for the currently selected quest log entry.
function QTR_ShowAndUpdateQuestInfo()
  if (not QTR_PS) then
     QTR_CheckVars();
  end
  if (QTR_PS["active"]=="0") then
     return;
  end
  QTR_UpdateQuestInfo();
   QTR_UpdateQuestLogTitleButtons();
end


local QTR_LastQuestLogSelection = nil;
local QTR_QuestLogReflowSerial = 0;


-- Reset quest log selection tracking when the detail view closes.
function QTR_HideQuestInfo()
  QTR_LastQuestLogSelection = nil;
   QTR_QuestLogDetailRefreshLock = false;
   QTR_QuestLogReflowSerial = QTR_QuestLogReflowSerial + 1;
end


local function QTR_GetLastVisibleQuestLogObjectiveFrame()
  local lastObjective = nil;
  local objectiveIndex = 1;

  while (true) do
     local objectiveFrame = _G["QuestInfoObjective" .. objectiveIndex];
     if (not objectiveFrame) then
        break;
     end

     if (objectiveFrame.IsShown and objectiveFrame:IsShown()) then
        lastObjective = objectiveFrame;
     end

     objectiveIndex = objectiveIndex + 1;
  end

  return lastObjective or QuestInfoObjectivesFrame;
end


local function QTR_GetLastVisibleQuestLogRewardFrame()
  local lastFrame = QuestInfoRewardsFrame;
  local rewardFrames = {
     QuestInfoItemChooseText,
     QuestInfoSpellLearnText,
     QuestInfoItemReceiveText,
     QuestInfoMoneyFrame,
     QuestInfoXPFrame,
     QuestInfoHonorFrame,
     QuestInfoArenaPointsFrame,
     QuestInfoTalentFrame,
     QuestInfoPlayerTitleFrame,
     QuestInfoReputationsFrame,
  };

  for _, rewardFrame in ipairs(rewardFrames) do
     if (rewardFrame and rewardFrame.IsShown and rewardFrame:IsShown()) then
        lastFrame = rewardFrame;
     end
  end

  local rewardIndex = 1;
  while (true) do
     local rewardItem = _G["QuestInfoItem" .. rewardIndex];
     if (not rewardItem) then
        break;
     end

     if (rewardItem.IsShown and rewardItem:IsShown()) then
        local lastBottom = (lastFrame and lastFrame.GetBottom and lastFrame:GetBottom()) or nil;
        local itemBottom = (rewardItem.GetBottom and rewardItem:GetBottom()) or nil;
        if (not lastBottom or not itemBottom or itemBottom < lastBottom) then
           lastFrame = rewardItem;
        end
     end

     rewardIndex = rewardIndex + 1;
  end

  return lastFrame or QuestInfoRewardsFrame;
end


local function QTR_AnchorQuestLogDetailFrame(frame, anchorFrame, offsetX, offsetY)
  if (not frame or not QuestLogDetailScrollChildFrame) then
     return nil;
  end

  frame:SetParent(QuestLogDetailScrollChildFrame);
  frame:ClearAllPoints();
  if (anchorFrame) then
     frame:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", offsetX, offsetY);
  else
     frame:SetPoint("TOPLEFT", QuestLogDetailScrollChildFrame, "TOPLEFT", offsetX, offsetY);
  end

  return frame;
end


local function QTR_ResetQuestLogDetailScrollPosition()
  if (QuestLogDetailScrollFrame and QuestLogDetailScrollFrame.SetVerticalScroll) then
     QuestLogDetailScrollFrame:SetVerticalScroll(0);
  end

  if (QuestLogDetailScrollFrameScrollBar and QuestLogDetailScrollFrameScrollBar.SetValue) then
     QuestLogDetailScrollFrameScrollBar:SetValue(0);
  end
end


-- Reward labels are translated in a delayed follow-up pass so Blizzard refreshes
-- cannot overwrite them before the quest-log layout settles.
local function QTR_ApplyQuestLogRewardTranslations()
  if (not QTR_PS or QTR_PS["active"] == "0" or not QTR_Messages) then
     return;
  end

  if (QuestInfoRewardsHeader and QTR_Messages.rewards) then
     QTR_SetShapedText(QuestInfoRewardsHeader, QTR_Messages.rewards, QTR_Font1, 18);
  end

  if (QuestInfoItemChooseText and QuestInfoItemChooseText.IsShown and QuestInfoItemChooseText:IsShown() and QTR_Messages.itemchoose1) then
     QTR_SetShapedText(QuestInfoItemChooseText, QTR_Messages.itemchoose1, QTR_Font2, 13);
  end

  if (QuestInfoItemReceiveText and QuestInfoItemReceiveText.IsShown and QuestInfoItemReceiveText:IsShown() and QTR_Messages.itemreceiv1) then
     QTR_SetShapedText(QuestInfoItemReceiveText, QTR_Messages.itemreceiv1, QTR_Font2, 13);
  end

  if (QuestInfoXPFrameReceiveText and QuestInfoXPFrameReceiveText.IsShown and QuestInfoXPFrameReceiveText:IsShown() and QTR_Messages.experience) then
     QTR_SetShapedText(QuestInfoXPFrameReceiveText, QTR_Messages.experience, QTR_Font2, 13);
  end

  if (QuestInfoTalentFrameReceiveText and QuestInfoTalentFrameReceiveText.IsShown and QuestInfoTalentFrameReceiveText:IsShown() and QTR_Messages.bonustalents) then
     QTR_SetShapedText(QuestInfoTalentFrameReceiveText, QTR_Messages.bonustalents, QTR_Font2, 13);
  end

  if (QuestInfoSpellLearnText and QuestInfoSpellLearnText.IsShown and QuestInfoSpellLearnText:IsShown() and QTR_Messages.learnspell) then
     QTR_SetShapedText(QuestInfoSpellLearnText, QTR_Messages.learnspell, QTR_Font2, 13);
  end
end


local function QTR_ReflowQuestLogDetailLayout(resetScrollBar)
  if (not QuestLogDetailScrollChildFrame or not QuestInfoTitleHeader or not QuestInfoObjectivesText or not QuestInfoDescriptionHeader or not QuestInfoDescriptionText or not QuestInfoRewardsFrame) then
     return;
  end

  local lastFrame = QTR_AnchorQuestLogDetailFrame(QuestInfoTitleHeader, nil, 5, -5);
  lastFrame = QTR_AnchorQuestLogDetailFrame(QuestInfoObjectivesText, lastFrame, 0, -5) or lastFrame;

  if (QuestInfoTimerFrame and QuestInfoTimerFrame.IsShown and QuestInfoTimerFrame:IsShown()) then
     lastFrame = QTR_AnchorQuestLogDetailFrame(QuestInfoTimerFrame, lastFrame, 0, -10) or lastFrame;
  end

  if (QuestInfoObjectivesFrame and QuestInfoObjectivesFrame.IsShown and QuestInfoObjectivesFrame:IsShown()) then
     QTR_AnchorQuestLogDetailFrame(QuestInfoObjectivesFrame, lastFrame, 0, -10);
     lastFrame = QTR_GetLastVisibleQuestLogObjectiveFrame() or QuestInfoObjectivesFrame;
  end

  if (QuestInfoRequiredMoneyFrame and QuestInfoRequiredMoneyFrame.IsShown and QuestInfoRequiredMoneyFrame:IsShown()) then
     lastFrame = QTR_AnchorQuestLogDetailFrame(QuestInfoRequiredMoneyFrame, lastFrame, 0, 0) or lastFrame;
  end

  if (QuestInfoGroupSize and QuestInfoGroupSize.IsShown and QuestInfoGroupSize:IsShown()) then
     lastFrame = QTR_AnchorQuestLogDetailFrame(QuestInfoGroupSize, lastFrame, 0, -10) or lastFrame;
  end

  lastFrame = QTR_AnchorQuestLogDetailFrame(QuestInfoDescriptionHeader, lastFrame, 0, -10) or lastFrame;
  lastFrame = QTR_AnchorQuestLogDetailFrame(QuestInfoDescriptionText, lastFrame, 0, -5) or lastFrame;

  QTR_AnchorQuestLogDetailFrame(QuestInfoRewardsFrame, lastFrame, 0, -10);
  lastFrame = QTR_GetLastVisibleQuestLogRewardFrame() or QuestInfoRewardsFrame;

  if (QuestInfoSpacerFrame) then
     lastFrame = QTR_AnchorQuestLogDetailFrame(QuestInfoSpacerFrame, lastFrame, 0, -10) or lastFrame;
  end

  local baseHeight = (QuestLogDetailScrollFrame and QuestLogDetailScrollFrame.GetHeight and QuestLogDetailScrollFrame:GetHeight()) or (QuestLogDetailScrollChildFrame.GetHeight and QuestLogDetailScrollChildFrame:GetHeight()) or 333;
  local childTop = QuestLogDetailScrollChildFrame.GetTop and QuestLogDetailScrollChildFrame:GetTop();
  local lastBottom = lastFrame and lastFrame.GetBottom and lastFrame:GetBottom();
  if (childTop and lastBottom) then
     local contentHeight = math.ceil(math.max(baseHeight, (childTop - lastBottom) + 18));
     if (contentHeight > 0 and QuestLogDetailScrollChildFrame.SetHeight) then
        QuestLogDetailScrollChildFrame:SetHeight(contentHeight);
     end
  end

  if (QuestLogDetailScrollFrame and QuestLogDetailScrollFrame.UpdateScrollChildRect) then
     QuestLogDetailScrollFrame:UpdateScrollChildRect();
  end

  if (QuestLogDetailScrollFrame and type(ScrollFrame_OnScrollRangeChanged) == "function") then
     ScrollFrame_OnScrollRangeChanged(QuestLogDetailScrollFrame);
  end

  if (resetScrollBar) then
     QTR_ResetQuestLogDetailScrollPosition();
     if (type(QTR_wait) == "function") then
        QTR_wait(0, QTR_ResetQuestLogDetailScrollPosition);
     end
  end
end


-- Load the selected quest into the original quest log detail panel.
function QTR_UpdateQuestInfo()
  if (QTR_PS["active"]=="0") then
     return;
  end
  local questSelected = GetQuestLogSelection();
  if (GetQuestLogTitle(questSelected) == nil) then
     return;
  end

  local _, _, _, _, isHeader, _, _, _, questID = GetQuestLogTitle(questSelected);
  if (isHeader) then
     return;
  end

  local selectionChanged = (QTR_LastQuestLogSelection ~= questSelected);
  QTR_LastQuestLogSelection = questSelected;

  if (selectionChanged) then
     if (type(QuestLog_UpdateQuestDetails) == "function" and not QTR_QuestLogDetailRefreshLock) then
        QTR_QuestLogDetailRefreshLock = true;
        QuestLog_UpdateQuestDetails(true);
        QTR_QuestLogDetailRefreshLock = false;
     else
        QTR_ResetQuestLogDetailScrollPosition();
     end
  end

  local qid = tostring(questID);

  if (QTR_QuestData[qid]) then
     QTR_objectives  = QTR_ExpandUnitInfo(QTR_QuestData[qid]["Objectives"]);
     QTR_description = QTR_ExpandUnitInfo(QTR_QuestData[qid]["Description"]);
     QTR_ChangeText_OnQuestLog(qid);
  else
     RestoreOriginalFonts();
  end 

  QTR_ReflowQuestLogDetailLayout(selectionChanged);
  if (type(QTR_wait) == "function") then
     QTR_QuestLogReflowSerial = QTR_QuestLogReflowSerial + 1;
     local reflowSerial = QTR_QuestLogReflowSerial;
     local expectedSelection = questSelected;
     local resetScrollBar = selectionChanged;
     QTR_wait(0.01, function(serial, selectedQuest, shouldResetScroll)
        if (serial ~= QTR_QuestLogReflowSerial) then
           return;
        end
        if (type(GetQuestLogSelection) == "function" and GetQuestLogSelection() ~= selectedQuest) then
           return;
        end
        if (not QTR_PS or QTR_PS["active"] == "0") then
           return;
        end

        QTR_ApplyQuestLogRewardTranslations();
        QTR_ReflowQuestLogDetailLayout(shouldResetScroll);
     end, reflowSerial, expectedSelection, resetScrollBar);
  else
     QTR_ApplyQuestLogRewardTranslations();
     QTR_ReflowQuestLogDetailLayout(selectionChanged);
  end
end


-- Switch quest greeting text and buttons between original and translated versions.
function GS_ON_OFF_QUEST()
   if (QTR_QuestGreetingHash == 0) then
      return;
   end

   QTR_EnsureQuestGreetingWidth();

   if (QTR_QuestGreetingState=="1") then
      QTR_QuestGreetingState="0";
      QTR_SetQuestGreetingText(QTR_GS[QTR_QuestGreetingHash], Original_Font2, QTR_QuestGreetingFontSize, "LEFT");
      QTR_SetQuestGreetingHeaders(false);
      QTR_RestoreGossipButtons(QTR_QuestGreetingButtonsEN, Original_Font2, QTR_QuestButtonFontSize);
      QTR_UpdateGreetingGoodbyeButton(QuestFrameGreetingGoodbyeButton, false);
      QTR_ToggleButtonQG:SetText("Gossip-Hash=["..tostring(QTR_QuestGreetingHash).."] EN");
   else
      QTR_QuestGreetingState="1";
      local Greeting_AR = QTR_PrepareShownGossipDisplayText(GS_Gossip[QTR_QuestGreetingHash], GreetingText:GetWidth(), QTR_QuestGreetingFontSize, QTR_Font1);
      QTR_SetQuestGreetingText(Greeting_AR, QTR_Font1, QTR_QuestGreetingFontSize, "RIGHT");
      QTR_SetQuestGreetingHeaders(true);
      QTR_RestoreGossipButtons(QTR_QuestGreetingButtonsAR, QTR_Font1, QTR_QuestButtonFontSize);
      QTR_UpdateGreetingGoodbyeButton(QuestFrameGreetingGoodbyeButton, true);
      QTR_ToggleButtonQG:SetText("Gossip-Hash=["..tostring(QTR_QuestGreetingHash).."] AR");
   end
end


-- Hash, look up, save, and apply gossip translations for quest-only NPC greeting windows.
function QTR_QuestGreeting_Show()
   if (not QTR_ToggleButtonQG or not GreetingText or not GreetingText:IsVisible()) then
      if (QTR_ToggleButtonQG) then
         QTR_ToggleButtonQG:Hide();
      end
      return;
   end

   local Nazwa_NPC = UnitName("npc");
   local Greeting_Text = GreetingText:GetText();
   QTR_QuestGreetingHash = 0;
   QTR_QuestGreetingButtonsEN = {};
   QTR_QuestGreetingButtonsAR = {};
   QTR_ToggleButtonQG:Show();
   QTR_EnsureQuestGreetingWidth();

   if (Nazwa_NPC and Greeting_Text and (string.find(Greeting_Text," ")==nil)) then
      Nazwa_NPC = string.gsub(Nazwa_NPC, '"', '\"');
      Greeting_Text = string.gsub(Greeting_Text, '"', '\"');

      local Hash = StringHash(QTR_NormalizeGossipHashText(Greeting_Text));
      QTR_QuestGreetingHash = Hash;
      QTR_GS[Hash] = Greeting_Text;
      if ( GS_Gossip[Hash] ) then
         QTR_QuestGreetingState = "1";
         local Greeting_AR = QTR_PrepareShownGossipDisplayText(GS_Gossip[Hash], GreetingText:GetWidth(), QTR_QuestGreetingFontSize, QTR_Font1);
         QTR_SetQuestGreetingText(Greeting_AR, QTR_Font1, QTR_QuestGreetingFontSize, "RIGHT");
         QTR_UpdateGreetingGoodbyeButton(QuestFrameGreetingGoodbyeButton, true);
         QTR_ToggleButtonQG:SetText("Gossip-Hash=["..tostring(Hash).."] AR");
         QTR_ToggleButtonQG:Enable();
      else
         QTR_QuestGreetingState = "0";
         QTR_SaveHarvestedGossipText(Nazwa_NPC, Hash, Greeting_Text);
         QTR_UpdateGreetingGoodbyeButton(QuestFrameGreetingGoodbyeButton, false);
         QTR_ToggleButtonQG:SetText("Gossip-Hash=["..tostring(Hash).."] EN");
         QTR_ToggleButtonQG:Disable();
      end

      local numQuestButtons = GetNumActiveQuests() + GetNumAvailableQuests();
      local questButton;
      for i = 1, numQuestButtons, 1 do
         questButton = _G["QuestTitleButton"..tostring(i)];
         if (questButton and questButton:GetText()) then
            local questText = questButton:GetText();
            local prefix = "";
            local suffix = "";
            if (string.sub(questText, 1, 2) == "|c") then
               prefix = string.sub(questText, 1, 10);
               suffix = "|r";
               questText = string.gsub(questText, prefix, "");
               questText = string.gsub(questText, suffix, "");
            end

            local translatedQuestTitle = QTR_GetQuestTitleTranslation(questText);
            if (translatedQuestTitle) then
               local questTitleAR = QTR_PrepareTitleButtonArabicText(questButton, translatedQuestTitle, QTR_Font1, QTR_QuestButtonFontSize);
               local translatedQuestButtonText = prefix .. questTitleAR .. suffix;
               QTR_QuestGreetingButtonsEN[questButton] = questButton:GetText();
               QTR_QuestGreetingButtonsAR[questButton] = translatedQuestButtonText;
               QTR_SetTitleButtonText(questButton, translatedQuestButtonText, QTR_Font1, QTR_QuestButtonFontSize);
            end
         end
      end
   else
      QTR_QuestGreetingState = "0";
      QTR_UpdateGreetingGoodbyeButton(QuestFrameGreetingGoodbyeButton, false);
      QTR_ToggleButtonQG:SetText("Gossip-Hash=?");
      QTR_ToggleButtonQG:Disable();
   end
end


-- Switch gossip text and buttons between original and translated versions.
function GS_ON_OFF()
   if (QTR_ToggleButtonGS) then
      QTR_ToggleButtonGS:Enable();
   end

   if (curr_goss=="1") then         -- turn off translation - show original text
      curr_goss="0";
      local originalGreetingText = QTR_GS[curr_hash];
      if ((not originalGreetingText or originalGreetingText == "") and type(GetGossipText) == "function") then
         originalGreetingText = GetGossipText();
      end
      if (type(GossipFrameUpdate) == "function") then
         QTR_SuppressGossipRefreshHook = true;
         GossipFrameUpdate();
         QTR_SuppressGossipRefreshHook = false;
      end
      QTR_RestoreVisibleGossipTitleButtons();
      QTR_SetGossipGreetingText(originalGreetingText, Original_Font2, QTR_GossipGreetingFontSize, "LEFT");
      QTR_UpdateGreetingGoodbyeButton(GossipFrameGreetingGoodbyeButton, false);
      QTR_ToggleButtonGS:SetText("Gossip-Hash=["..tostring(curr_hash).."] EN");
   else                             -- show translation AR
      curr_goss="1";
      QTR_Gossip_Show();
      return;
   end
end


-- Hash, look up, save, and apply gossip translations for the current NPC window.
function QTR_Gossip_Show()
   local Nazwa_NPC = GossipFrameNpcNameText:GetText();
   local previousHash = curr_hash;
   local previousState = curr_goss;
   local showArabicGossip = true;
   curr_hash = 0;
   QTR_GossipButtonsEN = {};
   QTR_GossipButtonsAR = {};
   if (Nazwa_NPC) then
      local Greeting_Text = GossipGreetingText:GetText();
      if (type(GetGossipText) == "function") then
         Greeting_Text = GetGossipText() or Greeting_Text;
      end
      if (string.find(Greeting_Text," ")==nil) then         -- not Polish text (no non-breaking space)
         Nazwa_NPC = string.gsub(Nazwa_NPC, '"', '\"');
         Greeting_Text = string.gsub(Greeting_Text, '"', '\"');
         local Czysty_Text = QTR_NormalizeGossipHashText(Greeting_Text);
         local Hash = StringHash(Czysty_Text);
         curr_hash = Hash;
         QTR_GS[Hash] = Greeting_Text;                      -- save original text
         if ( GS_Gossip[Hash] ) then   -- translation of this NPC's GOSSIP text exists
            if (previousHash == Hash and previousState == "0") then
               curr_goss = "0";
               showArabicGossip = false;
               QTR_RestoreVisibleGossipTitleButtons();
               QTR_SetGossipGreetingText(Greeting_Text, Original_Font2, QTR_GossipGreetingFontSize, "LEFT");
               QTR_ToggleButtonGS:SetText("Gossip-Hash=["..tostring(Hash).."] EN");
            else
               curr_goss = "1";
               showArabicGossip = true;
               local Greeting_PL = GS_Gossip[Hash];
               local Greeting_AR = QTR_PrepareShownGossipDisplayText(Greeting_PL, QTR_GetGossipGreetingWrapWidth(), QTR_GossipGreetingFontSize, QTR_Font1);
               QTR_SetGossipGreetingText(Greeting_AR, QTR_Font1, QTR_GossipGreetingFontSize, "RIGHT");
               QTR_ToggleButtonGS:SetText("Gossip-Hash=["..tostring(Hash).."] AR");
            end
            QTR_ToggleButtonGS:Enable();
         else                               -- no translation in GOSSIP database
            curr_goss = "0";
            -- save to file
            QTR_SaveHarvestedGossipText(Nazwa_NPC, Hash, Greeting_Text);
            QTR_ToggleButtonGS:SetText("Gossip-Hash=["..tostring(Hash).."] EN");
            QTR_ToggleButtonGS:Disable();
         end
         QTR_UpdateGreetingGoodbyeButton(GossipFrameGreetingGoodbyeButton, showArabicGossip);
         local maxGossipButtons = NUMGOSSIPBUTTONS or 32;
         local questButton;
         for i = 1, maxGossipButtons, 1 do
            questButton = getglobal("GossipTitleButton"..tostring(i));
            if (questButton and questButton:IsShown() and (questButton.type == "Available" or questButton.type == "Active") and questButton:GetText()) then
               local questText = questButton:GetText();
               local prefix = "";
               local suffix = "";
               if (string.sub(questText, 1, 2) == "|c") then
                  prefix = string.sub(questText, 1, 10);
                  suffix = "|r";
                  questText = string.gsub(questText, prefix, "");
                  questText = string.gsub(questText, suffix, "");
               end
               local translatedQuestTitle = QTR_GetQuestTitleTranslation(questText);
               if (translatedQuestTitle) then
                  local questTitleAR = QTR_PrepareTitleButtonArabicText(questButton, translatedQuestTitle, QTR_Font1, QTR_QuestButtonFontSize);
                  local translatedQuestButtonText = prefix .. questTitleAR .. suffix;
                  QTR_GossipButtonsEN[questButton] = questButton:GetText();
                  QTR_GossipButtonsAR[questButton] = translatedQuestButtonText;
                  if (showArabicGossip) then
                     QTR_SetTitleButtonText(questButton, translatedQuestButtonText, QTR_Font1, QTR_QuestButtonFontSize);
                  end
               end
            end
         end
         if (GetNumGossipOptions()>0) then    -- there are still additional function buttons in gossip, that can be translated
            local titleButton;
            for i = 1, maxGossipButtons, 1 do 
               titleButton=getglobal("GossipTitleButton"..tostring(i));
               if (titleButton and titleButton:IsShown() and titleButton.type == "Gossip" and titleButton:GetText()) then
                  local gostxt = QTR_GetOriginalGossipOptionText(titleButton);
                  if (gostxt and string.find(gostxt, "|cff000000") == nil) then   -- not a quest in gossip
                     local Hash = StringHash(gostxt);
                     if ( GS_Gossip[Hash] ) then   -- translation of additional text exists
                        local optionWidth = QTR_GetGossipOptionWidth(titleButton);
                        local Gossip_AR = QTR_PrepareGossipDisplayText(GS_Gossip[Hash], optionWidth, QTR_GossipButtonFontSize, QTR_Font1);
                        QTR_GossipButtonsEN[titleButton] = gostxt;
                        QTR_GossipButtonsAR[titleButton] = Gossip_AR;
                        if (showArabicGossip) then
                           QTR_SetTitleButtonText(titleButton, Gossip_AR, QTR_Font1, QTR_GossipButtonFontSize);
                        end
                     else
                        QTR_SaveHarvestedGossipText(Nazwa_NPC, Hash, gostxt);
                     end
                  end
               end
            end
         end
      end
   end
end


-- Schedule tutorial translation after the frame finishes its own refresh.
function Tut_onTutorialShow()
   if (QTR_PS["tutorial"]=="1") then
      if (not QTR_wait(0.01,Tut_TutorialShowDelayed)) then  -- delay 0.01 sec for near-instant rendering
      end
   end
end


-- Apply translated tutorial text after the delayed tutorial refresh.
function Tut_TutorialShowDelayed()
   Tut_ID = TutorialFrame.id;
   local Tut_tytul, Tut_tekst = "","";
   if (Tut_Data[tostring(Tut_ID)]) then
      Tut_tytul = Tut_Data[tostring(Tut_ID)]["Title"];
      Tut_tekst = Tut_Data[tostring(Tut_ID)]["Text"];
   end    
   if (string.len(Tut_tekst)>0) then
      local _font1, _size1, _1 = TutorialFrameTitle:GetFont();
      TutorialFrameTitle:SetFont(QTR_Font2, _size1);
      if (Tut_tytul and AS_ContainsArabic and AS_ContainsArabic(Tut_tytul)) then
         Tut_tytul = string.gsub(Tut_tytul, "|n", "\n");
         Tut_tytul = string.gsub(Tut_tytul, "\n", " ");
         
         -- Protect colors natively by injecting pre-reversed tags onto every word
         Tut_tytul = string.gsub(Tut_tytul, "%|c(%x%x%x%x%x%x%x%x)(.-)%|r", function(hex, content)
             local revHex = string.reverse(hex)
             return string.gsub(content, "([^%s]+)", "r|%1" .. revHex .. "c|")
         end)

         Tut_tytul = QTR_ReverseText(Tut_tytul);

         TutorialFrameTitle:SetJustifyH("RIGHT");
      else
         TutorialFrameTitle:SetJustifyH("LEFT");
      end
      TutorialFrameTitle:SetText(Tut_tytul);

      local _font2, _size2, _2 = TutorialFrameText:GetFont();
      TutorialFrameText:SetFont(QTR_Font2, _size2);
      local tutorialTextWidth = TutorialFrameText:GetWidth();
      if (not tutorialTextWidth or tutorialTextWidth < 240 or tutorialTextWidth > 340) then
         tutorialTextWidth = 300;
      end
      local useArabicTutorialText = (Tut_tekst and AS_ContainsArabic and AS_ContainsArabic(Tut_tekst));
      TutorialFrameText:SetWidth(tutorialTextWidth);
      if (useArabicTutorialText) then
         Tut_tekst = string.gsub(Tut_tekst, "|n", "\n");
         
         -- Protect colors natively by injecting pre-reversed tags onto every word.
         -- This ensures AS_TestLine natively evaluates their exact 0-width and preserves them flawlessly across line wraps
         Tut_tekst = string.gsub(Tut_tekst, "%|c(%x%x%x%x%x%x%x%x)(.-)%|r", function(hex, content)
             local revHex = string.reverse(hex)
             return string.gsub(content, "([^%s]+)", "r|%1" .. revHex .. "c|")
         end)

         -- Pre-reverse arbitrary English tokens so the reshaper flips them back to readable syntax automatically
         Tut_tekst = string.gsub(Tut_tekst, "<([^>]+)>", function(content)
             return ">" .. string.reverse(content) .. "<"
         end)
         Tut_tekst = string.gsub(Tut_tekst, "/([a-zA-Z]+)", function(content)
             return string.reverse(content) .. "/"
         end)

         -- TutorialFrameText:GetWidth() is often wildly uninitialized (e.g., 10 or 1024) across the very first frame render,
         -- which destroys the width constraint logic. We clamp it strictly to its intended static pixel width.
         local w = tutorialTextWidth - 18;
         if (w < 200) then
            w = tutorialTextWidth;
         end
         
         local shapedText = ""
         for paragraph in string.gmatch(Tut_tekst .. "\n", "(.-)\n") do
            if paragraph ~= "" then
                local shapedPara = AS_ReverseAndPrepareLineText(paragraph, w, QTR_Font2, _size2)
                if shapedText == "" then
                    shapedText = shapedPara
                else
                    shapedText = shapedText .. "\n" .. shapedPara
                end
            else
                if shapedText ~= "" then
                    shapedText = shapedText .. "\n"
                end
            end
         end
         Tut_tekst = shapedText

         TutorialFrameText:SetJustifyH("RIGHT");
      else
         TutorialFrameText:SetJustifyH("LEFT");
      end
      TutorialFrameText:SetText(Tut_tekst);
   end
   
   local okayTextFont = TutorialFrameOkayButton:GetFontString();
   if okayTextFont then
       local _font3, _size3 = okayTextFont:GetFont();
       okayTextFont:SetFont(QTR_Font2, _size3 or 12);
   end
   TutorialFrameOkayButton:SetText(QTR_ReverseText("\216\165\216\186\217\132\216\167\217\130"));
end


-- Expand quest placeholders for names, gender, class, and race tokens.
function QTR_ExpandUnitInfo(msg)
   if (not msg or msg == "") then
      return msg or "";
   end

   msg = string.gsub(msg, "%$[bB]", "\n");
   msg = string.gsub(msg, "%$[nN]", "{N}");
   msg = string.gsub(msg, "%$[cC]", "{C}");
   msg = string.gsub(msg, "%$[rR]", "{R}");

   msg = string.gsub(msg, "{B}", "\n");
   msg = string.gsub(msg, "NEW_LINE", "\n");

   msg = string.gsub(msg, "{[cC]}", "{C}");
   msg = string.gsub(msg, "{[rR]}", "{R}");

   msg = string.gsub(msg, "{002DFFFFc}", "{cFFFFD200}");
   msg = string.gsub(msg, "{FFFF00FFc}", "{cFF00FFFF}");
   msg = string.gsub(msg, "{0000FFFFc}", "{cFFFF0000}");
   msg = string.gsub(msg, "{ffffffffc}", "{cffffffff}");
   msg = string.gsub(msg, "EU_ROLOC:", "UE_COLOR:");

   msg = string.gsub(msg, "{N}", AS_UTF8reverse(QTR_name));
   msg = string.gsub(msg, "YOUR_NAME0", AS_UTF8reverse(string.upper(QTR_name)));
   msg = string.gsub(msg, "YOUR_NAME1", AS_UTF8reverse(QTR_name));
   msg = string.gsub(msg, "YOUR_NAME2", AS_UTF8reverse(QTR_name));
   msg = string.gsub(msg, "YOUR_NAME3", AS_UTF8reverse(QTR_name));
   msg = string.gsub(msg, "YOUR_NAME4", AS_UTF8reverse(QTR_name));
   msg = string.gsub(msg, "YOUR_NAME5", AS_UTF8reverse(QTR_name));
   msg = string.gsub(msg, "YOUR_NAME6", AS_UTF8reverse(QTR_name));
   msg = string.gsub(msg, "YOUR_NAME7", AS_UTF8reverse(QTR_name));
   msg = string.gsub(msg, "YOUR_NAME", AS_UTF8reverse(QTR_name));

   msg = QTR_ResolveGenderPlaceholders(msg);

   if (QTR_sex==3) then        -- feminine form
      msg = string.gsub(msg, "{C}", player_class.M2);
      msg = string.gsub(msg, "{R}", player_race.M2);
      msg = string.gsub(msg, "YOUR_CLASS1", player_class.M2);          -- Nominative (who, what?)
      msg = string.gsub(msg, "YOUR_CLASS2", player_class.D2);          -- Genitive (of whom, of what?)
      msg = string.gsub(msg, "YOUR_CLASS3", player_class.C2);          -- Dative (to whom, to what?)
      msg = string.gsub(msg, "YOUR_CLASS4", player_class.B2);          -- Accusative (whom, what?)
      msg = string.gsub(msg, "YOUR_CLASS5", player_class.N2);          -- Instrumental (with whom, with what?)
      msg = string.gsub(msg, "YOUR_CLASS6", player_class.K2);          -- Locative (about whom, about what?)
      msg = string.gsub(msg, "YOUR_CLASS7", player_class.W2);          -- Vocative (o!)
      msg = string.gsub(msg, "YOUR_RACE1", player_race.M2);            -- Nominative (who, what?)
      msg = string.gsub(msg, "YOUR_RACE2", player_race.D2);            -- Genitive (of whom, of what?)
      msg = string.gsub(msg, "YOUR_RACE3", player_race.C2);            -- Dative (to whom, to what?)
      msg = string.gsub(msg, "YOUR_RACE4", player_race.B2);            -- Accusative (whom, what?)
      msg = string.gsub(msg, "YOUR_RACE5", player_race.N2);            -- Instrumental (with whom, with what?)
      msg = string.gsub(msg, "YOUR_RACE6", player_race.K2);            -- Locative (about whom, about what?)
      msg = string.gsub(msg, "YOUR_RACE7", player_race.W2);            -- Vocative (o!)
      msg = string.gsub(msg, "YOUR_RACE YOUR_CLASS", "YOUR_RACE "..player_class.M2);     -- Nominative (who, what?)
      msg = string.gsub(msg, "YOUR_RACE", player_race.M2);             -- Instrumental (with whom, with what?)
      msg = string.gsub(msg, "أنت YOUR_RACE", "أنت "..player_race.M2);
      msg = string.gsub(msg, "YOUR_RACE", player_race.W2);                        -- Vocative - remaining occurrences
      msg = string.gsub(msg, "YOUR_CLASS", player_class.W2);                      -- Vocative - remaining occurrences
   else                    -- masculine form
      msg = string.gsub(msg, "{C}", player_class.M1);
      msg = string.gsub(msg, "{R}", player_race.M1);
      msg = string.gsub(msg, "YOUR_CLASS1", player_class.M1);          -- Nominative (who, what?)
      msg = string.gsub(msg, "YOUR_CLASS2", player_class.D1);          -- Genitive (of whom, of what?)
      msg = string.gsub(msg, "YOUR_CLASS3", player_class.C1);          -- Dative (to whom, to what?)
      msg = string.gsub(msg, "YOUR_CLASS4", player_class.B1);          -- Accusative (whom, what?)
      msg = string.gsub(msg, "YOUR_CLASS5", player_class.N1);          -- Instrumental (with whom, with what?)
      msg = string.gsub(msg, "YOUR_CLASS6", player_class.K1);          -- Locative (about whom, about what?)
      msg = string.gsub(msg, "YOUR_CLASS7", player_class.W1);          -- Vocative (o!)
      msg = string.gsub(msg, "YOUR_RACE1", player_race.M1);            -- Nominative (who, what?)
      msg = string.gsub(msg, "YOUR_RACE2", player_race.D1);            -- Genitive (of whom, of what?)
      msg = string.gsub(msg, "YOUR_RACE3", player_race.C1);            -- Dative (to whom, to what?)
      msg = string.gsub(msg, "YOUR_RACE4", player_race.B1);            -- Accusative (whom, what?)
      msg = string.gsub(msg, "YOUR_RACE5", player_race.N1);            -- Instrumental (with whom, with what?)
      msg = string.gsub(msg, "YOUR_RACE6", player_race.K1);            -- Locative (about whom, about what?)
      msg = string.gsub(msg, "YOUR_RACE7", player_race.W1);            -- Vocative (o!)
      msg = string.gsub(msg, "YOUR_RACE YOUR_CLASS", "YOUR_RACE "..player_class.M1);     -- Nominative (who, what?)
      msg = string.gsub(msg, "YOUR_RACE", player_race.W1);                        -- Vocative - remaining occurrences
      msg = string.gsub(msg, "YOUR_CLASS", player_class.W1);                      -- Vocative - remaining occurrences
   end

  return msg;
end

