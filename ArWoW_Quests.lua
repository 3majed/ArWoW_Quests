-- Addon: ArWoW_Quests (version: 1.0.0) 2026.05.16
-- Description: AddOn displays translated quest information in the original windows.
-- Author: Majed
-- WWW: https://github.com/3majed

-- Global Variables
local QTR_version = "1.0.0";
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
local QTR_QuestGreetingHash = 0;
local QTR_QuestGreetingState = "0";
local QTR_WorldMapRetryPending = false;
local QTR_UpdateWorldMapRewards;
local QTR_RestoreWorldMapRewards;
local QTR_MessOrig = {
      details    = "Description", 
      objectives = "Objectives", 
      rewards    = "Rewards", 
      itemchoose1= "You will be able to choose one of these rewards:", 
      itemchoose2= "Choose one of these rewards:", 
      itemreceiv1= "You will also receive:", 
      itemreceiv2= "You receiving the reward:", 
      learnspell = "Learn Spell:", 
      reqmoney   = "Required Money:", 
      reqitems   = "Required items:", 
      experience = "Experience:", 
      currquests = "Current Quests", 
      avaiquests = "Available Quests", };
local Original_Font1 = "Fonts\\MORPHEUS.ttf";
local Original_Font2 = "Fonts\\FRIZQT__.ttf";
local QTR_QuestBodyLimit = 35;
local QTR_WorldMapObjectiveLimit = 28;
local QTR_WatchFrameObjectiveLimit = 24;
local Tut_ID = 0;
local Tut_race = string.gsub(strupper(QTR_race)," ","");
local Tut_class= string.gsub(strupper(QTR_class)," ","");
if (Tut_class == "DEATHKNIGHT") then
   Tut_race = "DEATHKNIGHT";
end
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



function Spr_Gender(msg)
   msg = string.gsub(msg, "%$[gG]%s*([^:;؛]+)%s*:%s*([^;؛]+)%s*[;؛]", function(masc, fem)
      return (QTR_sex == 3) and fem or masc
   end)
   msg = string.gsub(msg, "%$[tT]%s*([^:;؛]+)%s*:%s*([^;؛]+)%s*[;؛]", function(masc, fem)
      return (QTR_sex == 3) and fem or masc
   end)
   msg = string.gsub(msg, "%$[tT]%s*([^:;؛]+)%s*[;؛]", "%1")
   -- Replace {g} masc : fem ; or ؛
   msg = string.gsub(msg, "{[gG]}%s*([^:;؛]+)%s*:%s*([^:;؛]+)%s*[;؛]?", function(masc, fem)
      return (QTR_sex == 3) and fem or masc
   end)
   -- Replace {g masc : fem} or {G masc : fem}
   msg = string.gsub(msg, "{[gG]%s*([^:}]+)%s*:%s*([^}]+)}", function(masc, fem)
      return (QTR_sex == 3) and fem or masc
   end)
   -- YOUR_GENDER(x;y)
   msg = string.gsub(msg, "YOUR_GENDER%s*%(([^;]+);([^)]+)%)", function(masc, fem)
      return (QTR_sex == 3) and fem or masc
   end)

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
  if (not AS_ContainsArabic or not AS_ContainsArabic(text)) then
     return text;
  end
  text = string.gsub(text, "\r\n", "\n");
  text = string.gsub(text, "\r", "\n");
  text = string.gsub(text, "\n", "#");
  return QTR_LineReverse(text, limit);
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
local function QTR_SetShapedText(fontString, text, fontName, fontSize, limit)
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
local function QTR_GetTranslatedQuestTitleById(questId)
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


-- Apply translated text and alignment rules to a quest or gossip title button.
local QTR_TitleButtonAnchorCache = {};
local QTR_TitleButtonFontCache = {};


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
     local isQuestTitleButton = titleButtonName and string.find(titleButtonName, "^QuestTitleButton");
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
  local isQuestTitleButton = titleButtonName and string.find(titleButtonName, "^QuestTitleButton");
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
     optionWidth = optionWidth - buttonIcon:GetWidth() - 16;
  end
  if (optionWidth < 40) then
     optionWidth = titleButton:GetWidth();
  end
  return optionWidth;
end


-- Measure the usable width for quest title buttons after icon padding.
local function QTR_GetQuestButtonWidth(titleButton)
  local optionWidth = titleButton:GetWidth();
  local buttonIcon = _G[titleButton:GetName() .. "QuestIcon"];
  if (buttonIcon) then
     optionWidth = optionWidth - buttonIcon:GetWidth() - 16;
  end
  if (optionWidth < 40) then
     optionWidth = titleButton:GetWidth();
  end
  return optionWidth;
end


-- Pick the best translated title for a quest list entry with possible duplicate IDs.
local function QTR_GetQuestTitleTranslation(titleText)
  if (not titleText or titleText == "") then
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

  if (selectedQuestId and QTR_QuestData[selectedQuestId] and QTR_QuestData[selectedQuestId]["Title"]) then
     return QTR_GetTranslatedQuestTitleById(selectedQuestId);
  end

  return nil;
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
local function QTR_GetTranslatedQuestLogButtonText(displayText, questTitle, translatedQuestTitle)
  if (not translatedQuestTitle) then
     return nil;
  end

  local translatedDisplayTitle = QTR_ReverseText(translatedQuestTitle);
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


-- Translate a single quest-log title button using its live display text.
local function QTR_UpdateQuestLogTitleButton(titleButton, displayText)
  if (not titleButton or QTR_QuestLogTitleButtonUpdateLock[titleButton]) then
     return;
  end

  if (not QTR_PS or QTR_PS["active"] ~= "1" or QTR_PS["transtitle"] ~= "1") then
     QTR_RestoreTitleButtonFont(titleButton);
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

  local translatedQuestTitle = nil;
  if (questID) then
     translatedQuestTitle = QTR_GetTranslatedQuestTitleById(tostring(questID));
  end
  if (not translatedQuestTitle) then
     translatedQuestTitle = QTR_GetQuestTitleTranslation(questTitle);
  end
  if (not translatedQuestTitle) then
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

  local translatedDisplayText = QTR_GetTranslatedQuestLogButtonText(currentDisplayText, questTitle, translatedQuestTitle);
  if (translatedDisplayText and translatedDisplayText ~= currentDisplayText) then
     QTR_QuestLogTitleButtonUpdateLock[titleButton] = true;
     QTR_SetTitleButtonText(titleButton, translatedDisplayText, QTR_Font2, 13);
     QTR_QuestLogTitleButtonUpdateLock[titleButton] = nil;
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


-- Reapply translated quest titles to the visible left quest-log rows after Blizzard redraws them.
local function QTR_UpdateQuestLogTitleButtons()
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
  -- initialize check options
  if (not QTR_PS["active"]) then
     QTR_PS["active"] = "1";   
  end
  QTR_PS["mode"] = nil;
  if (not QTR_PS["transtitle"] ) then
     QTR_PS["transtitle"] = "1";   
  end
  QTR_PS["transtitle_migrated"] = nil;
  QTR_PS["size"] = nil;
  QTR_PS["width"] = nil;
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
-- Resolve gender placeholders embedded in translated strings before display.


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
        local translatedObjective = nil;
        questFrame.qtrOriginalTitle = questFrame.title:GetText();
        if (QTR_PS and QTR_PS["active"] == "1" and questFrame.questId and questFrame.questId > 0) then
           local questId = tostring(questFrame.questId);
           local questData = QTR_QuestData and QTR_QuestData[questId];
           if (questData) then
              local _, titleSize = questFrame.title:GetFont();
              local _, objectiveSize = questFrame.objectives:GetFont();
              local _, dashesSize = questFrame.dashes:GetFont();
              local originalObjectiveText = questFrame.objectives:GetText() or "";
              local titleWidth = 240;

              if (questFrame.check and questFrame.check:IsShown()) then
                 titleWidth = 224;
              end

              questFrame.title:SetWidth(titleWidth);
              if (QTR_PS["transtitle"] == "1") then
                 QTR_SetShapedText(questFrame.title, QTR_GetTranslatedQuestTitleById(questId), QTR_Font1, titleSize or 13);
              end

              if (questData["Objectives"] and questData["Objectives"] ~= "" and not string.find(originalObjectiveText, "%d+/%d+")) then
                 translatedObjective = QTR_ExpandUnitInfo(questData["Objectives"]);
                 questFrame.objectives:SetWidth(232);
                 QTR_SetShapedText(questFrame.objectives, translatedObjective, QTR_Font2, objectiveSize or 13, QTR_WorldMapObjectiveLimit);
                 questFrame.dashes:SetFont(QTR_Font2, dashesSize or objectiveSize or 13);
                 questFrame.dashes:SetJustifyH("RIGHT");
                 questFrame.dashes:SetText("");
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

        if (translatedObjective) then
           questFrame:SetHeight(max(questFrame.title:GetHeight() + questFrame.objectives:GetHeight() + QUESTFRAME_PADDING, QUESTFRAME_MINHEIGHT));
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

  local _, titleSize = WatchFrameTitle:GetFont();
  WatchFrameHeader:ClearAllPoints();
  if (WatchFrameCollapseExpandButton) then
     WatchFrameHeader:SetPoint("TOPRIGHT", WatchFrameCollapseExpandButton, "TOPLEFT", -4, -1);
  else
     WatchFrameHeader:SetPoint("TOPRIGHT", WatchFrame, "TOPRIGHT", -28, -6);
  end
  WatchFrameTitle:ClearAllPoints();
  WatchFrameTitle:SetPoint("TOPRIGHT", WatchFrameHeader, "TOPRIGHT", 0, 0);
  WatchFrameTitle:SetWidth(WATCHFRAME_MAXLINEWIDTH or WATCHFRAME_EXPANDEDWIDTH or WatchFrame:GetWidth() or 204);
  QTR_SetShapedText(WatchFrameTitle, displayText, QTR_Font1, titleSize or 12);

  local headerWidth = max(WatchFrameTitle:GetStringWidth() + 4, 40);
  WatchFrameHeader:SetWidth(headerWidth);
  WatchFrameTitle:SetWidth(headerWidth);
end


local function QTR_ConfigureWatchFrameLineLayout(line, useArabicLayout)
  if (not line or not line.text or not line.dash) then
     return;
  end

  local dashWidth = 0;
  local dashText = line.dash:GetText();
  if (line.dash:IsShown() and dashText and dashText ~= "") then
     dashWidth = line.dash:GetWidth() or 0;
  end

  local lineWidth = WATCHFRAME_MAXLINEWIDTH or line:GetWidth() or 192;
  if (lineWidth <= dashWidth) then
     lineWidth = (WATCHFRAME_EXPANDEDWIDTH or 204) - 12;
  end

  line.dash:ClearAllPoints();
  line.text:ClearAllPoints();
  if (useArabicLayout) then
     line.dash:SetPoint("TOPRIGHT", line, "TOPRIGHT", 0, -1);
     line.dash:SetPoint("BOTTOMRIGHT", line, "BOTTOMRIGHT", 0, 0);
     line.text:SetPoint("RIGHT", line.dash, "LEFT", 0, 0);
     line.text:SetJustifyH("RIGHT");
  else
     line.dash:SetPoint("TOPLEFT", line, "TOPLEFT", 0, -1);
     line.dash:SetPoint("BOTTOMLEFT", line, "BOTTOMLEFT", 0, 0);
     line.text:SetPoint("LEFT", line.dash, "RIGHT", 0, 0);
     line.text:SetJustifyH("LEFT");
  end
  line.text:SetWidth(max(lineWidth - dashWidth, 20));
end


local function QTR_FindWatchFramePOIButton(questID)
  if (not questID or not WatchFrameLines or not WatchFrameLines.GetChildren) then
     return nil;
  end

  for _, child in ipairs({ WatchFrameLines:GetChildren() }) do
     if (child and child:IsShown() and child.questId == questID and child.parentName == "WatchFrameLines") then
        return child;
     end
  end

  return nil;
end


local function QTR_FindWatchFrameItemButton(questIndex)
  if (not questIndex or not WatchFrameLines or not WatchFrameLines.GetChildren) then
     return nil;
  end

  for _, child in ipairs({ WatchFrameLines:GetChildren() }) do
     local childName = child and child.GetName and child:GetName();
     if (child and child:IsShown() and child.GetID and child:GetID() == questIndex and childName and string.find(childName, "^WatchFrameItem")) then
        return child;
     end
  end

  return nil;
end


local function QTR_UpdateWatchFrameQuestIcons(titleLine, questIndex, questID, useArabicLayout)
  if (not titleLine or not titleLine.text) then
     return;
  end

  local poiButton = QTR_FindWatchFramePOIButton(questID);
  local itemButton = QTR_FindWatchFrameItemButton(questIndex);

  if (useArabicLayout) then
     if (itemButton) then
        itemButton:ClearAllPoints();
        itemButton:SetPoint("TOPLEFT", titleLine, "TOPLEFT", -10, -2);
     end
     if (poiButton) then
        poiButton:ClearAllPoints();
        poiButton:SetPoint("TOPLEFT", titleLine, "TOPRIGHT", 0, 5);
     end
  else
     if (itemButton) then
        itemButton:ClearAllPoints();
        itemButton:SetPoint("TOPRIGHT", titleLine, "TOPRIGHT", 10, -2);
     end
     if (poiButton) then
        poiButton:ClearAllPoints();
        poiButton:SetPoint("TOPRIGHT", titleLine, "TOPLEFT", 0, 5);
     end
  end
end


local function QTR_RestoreWatchFrameLineLayouts()
  if (not WATCHFRAME_LINKBUTTONS) then
     return;
  end

  for i = 1, #WATCHFRAME_LINKBUTTONS do
     local linkButton = WATCHFRAME_LINKBUTTONS[i];
     if (linkButton and linkButton:IsShown() and linkButton.type == "QUEST" and linkButton.lines and linkButton.startLine and linkButton.lastLine) then
        local questIndex = GetQuestIndexForWatch and GetQuestIndexForWatch(linkButton.index);
        local questID = nil;
        if (questIndex) then
           local _, _, _, _, _, _, _, _, restoreQuestID = GetQuestLogTitle(questIndex);
           questID = restoreQuestID;
        end
        QTR_ConfigureWatchFrameLineLayout(linkButton.lines[linkButton.startLine], false);
        QTR_UpdateWatchFrameQuestIcons(linkButton.lines[linkButton.startLine], questIndex, questID, false);
        if (linkButton.lastLine >= linkButton.startLine + 1) then
           QTR_ConfigureWatchFrameLineLayout(linkButton.lines[linkButton.startLine + 1], false);
        end
     end
  end
end


local function QTR_UpdateWatchFrame()
  if (not WatchFrame or not WatchFrame:IsShown()) then
     return;
  end

  if (not QTR_PS or QTR_PS["active"] ~= "1") then
     QTR_RestoreWatchFrameHeader();
     QTR_RestoreWatchFrameLineLayouts();
     return;
  end

  QTR_UpdateWatchFrameHeader();

  if (not WatchFrameLines or not WatchFrameLines:IsShown() or not WATCHFRAME_LINKBUTTONS or not GetQuestIndexForWatch) then
     return;
  end

  for i = 1, #WATCHFRAME_LINKBUTTONS do
     local linkButton = WATCHFRAME_LINKBUTTONS[i];
     if (linkButton and linkButton:IsShown() and linkButton.type == "QUEST" and linkButton.lines and linkButton.startLine and linkButton.lastLine) then
        local questIndex = GetQuestIndexForWatch(linkButton.index);
        if (questIndex) then
           local title, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(questIndex);
           if (questID and questID > 0) then
              local questId = tostring(questID);
              local questData = QTR_QuestData and QTR_QuestData[questId];
              local titleLine = linkButton.lines[linkButton.startLine];
              local useArabicWatchLayout = false;

              if (titleLine and titleLine.text) then
                 if (QTR_PS["transtitle"] == "1" and questData and questData["Title"]) then
                    useArabicWatchLayout = true;
                    QTR_ConfigureWatchFrameLineLayout(titleLine, true);
                    QTR_UpdateWatchFrameQuestIcons(titleLine, questIndex, questID, true);
                    local _, titleSize = titleLine.text:GetFont();
                    titleLine:SetHeight(WATCHFRAME_LINEHEIGHT or titleLine:GetHeight());
                    titleLine.text:SetHeight(0);
                    QTR_SetShapedText(titleLine.text, QTR_GetTranslatedQuestTitleById(questId), QTR_Font1, titleSize or 13);
                    local titleHeight = titleLine.text:GetHeight();
                    if (titleHeight > (WATCHFRAME_LINEHEIGHT or 16)) then
                       local titleLineHeight = WATCHFRAME_MULTIPLE_LINEHEIGHT or titleLine:GetHeight();
                       if (titleHeight > titleLineHeight) then
                          titleLineHeight = titleHeight;
                       end
                       titleLine:SetHeight(titleLineHeight);
                       titleLine.text:SetHeight(titleLineHeight);
                    end
                 else
                    QTR_ConfigureWatchFrameLineLayout(titleLine, false);
                    QTR_UpdateWatchFrameQuestIcons(titleLine, questIndex, questID, false);
                 end
              end

              if (questData and questData["Objectives"] and questData["Objectives"] ~= "" and linkButton.lastLine == linkButton.startLine + 1) then
                 local objectiveLine = linkButton.lines[linkButton.startLine + 1];
                 if (objectiveLine and objectiveLine.text) then
                    local objectiveText = objectiveLine.text:GetText() or "";
                    local translatedObjective = QTR_ExpandUnitInfo(questData["Objectives"]);
                    local hasDynamicProgress = string.find(objectiveText, "%d+%s*/%s*%d+") ~= nil;
                    if (objectiveText ~= "" and not hasDynamicProgress) then
                       QTR_ConfigureWatchFrameLineLayout(objectiveLine, true);
                       local _, objectiveSize = objectiveLine.text:GetFont();
                       objectiveLine:SetHeight(WATCHFRAME_LINEHEIGHT or objectiveLine:GetHeight());
                       objectiveLine.text:SetHeight(0);
                       QTR_SetShapedText(objectiveLine.text, translatedObjective, QTR_Font2, objectiveSize or 12, QTR_WatchFrameObjectiveLimit);
                       local objectiveHeight = objectiveLine.text:GetHeight();
                       if (objectiveHeight > (WATCHFRAME_LINEHEIGHT or 16)) then
                          local objectiveLineHeight = WATCHFRAME_MULTIPLE_LINEHEIGHT or objectiveLine:GetHeight();
                          if (objectiveHeight > objectiveLineHeight) then
                             objectiveLineHeight = objectiveHeight;
                          end
                          objectiveLine:SetHeight(objectiveLineHeight);
                          objectiveLine.text:SetHeight(objectiveLineHeight);
                       end
                    elseif (objectiveText ~= "" and useArabicWatchLayout) then
                       QTR_ConfigureWatchFrameLineLayout(objectiveLine, true);
                       local objectiveFont, objectiveSize = objectiveLine.text:GetFont();
                       objectiveLine:SetHeight(WATCHFRAME_LINEHEIGHT or objectiveLine:GetHeight());
                       objectiveLine.text:SetHeight(0);
                       QTR_SetShapedText(objectiveLine.text, objectiveText, objectiveFont or Original_Font2, objectiveSize or 12);
                       objectiveLine.text:SetJustifyH("RIGHT");
                       local objectiveHeight = objectiveLine.text:GetHeight();
                       if (objectiveHeight > (WATCHFRAME_LINEHEIGHT or 16)) then
                          local objectiveLineHeight = WATCHFRAME_MULTIPLE_LINEHEIGHT or objectiveLine:GetHeight();
                          if (objectiveHeight > objectiveLineHeight) then
                             objectiveLineHeight = objectiveHeight;
                          end
                          objectiveLine:SetHeight(objectiveLineHeight);
                          objectiveLine.text:SetHeight(objectiveLineHeight);
                       end
                    else
                       QTR_ConfigureWatchFrameLineLayout(objectiveLine, false);
                    end
                 end
              end
           end
        end
     end
  end
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

  local QTR_OptionsTextWidth = 360;
  local QTR_OptionsHeaderWidth = 420;
  local QTR_OptionsTextRight = -40;
  local QTR_OptionsCheckRight = QTR_OptionsTextRight + 12;

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
   QTRCheckButton0:SetScript("OnClick", function(self) if (QTR_PS["active"]=="1") then QTR_PS["active"]="0" else QTR_PS["active"]="1" end; QTR_UpdateQuestLogToggleButtonText(); QTR_RefreshWorldMapQuestList(); QTR_RefreshWatchFrame(); end);
  QTR_SetOptionsCheckButtonText(QTRCheckButton0, QTRCheckButton0Text, QTR_ReverseText(QTR_Interface.active));
  
  local QTRCheckButton3 = CreateFrame("CheckButton", "QTRCheckButton3", QTROptions, "OptionsCheckButtonTemplate");
   QTR_SetOptionsCheckButtonPoint(QTRCheckButton3, QTRCheckButton0, true, -10);
   QTRCheckButton3:SetScript("OnClick", function(self) if (QTR_PS["transtitle"]=="0") then QTR_PS["transtitle"]="1" else QTR_PS["transtitle"]="0" end; QTR_RefreshWorldMapQuestList(); QTR_RefreshWatchFrame(); end);
  QTR_SetOptionsCheckButtonText(QTRCheckButton3, QTRCheckButton3Text, QTR_ReverseText(QTR_Interface.transtitle));
  
  local QTRCheckButtonGossip = CreateFrame("CheckButton", "QTRCheckButtonGossip", QTROptions, "OptionsCheckButtonTemplate");
   QTR_SetOptionsCheckButtonPoint(QTRCheckButtonGossip, QTRCheckButton3, true, -10);
  QTRCheckButtonGossip:SetScript("OnClick", function(self) if (QTR_PS["gossip"]=="1") then QTR_PS["gossip"]="0" else QTR_PS["gossip"]="1" end; end);
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
local QTR_EventFrame = CreateFrame("Frame");
local QTR_SuppressGossipRefreshHook = false;


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
           QTR_Gossip_Show();
        end
     end);
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
  return true;
end


QTR_EventFrame:RegisterEvent("ADDON_LOADED");
QTR_EventFrame:SetScript("OnEvent", function(self, event, ...)
  if (event == "ADDON_LOADED") then
     local addon = ...;
     if (addon ~= "ArWoW_Quests") then
        return;
     end

     QTR_InitializeRuntime();
     if (QTR.ADDON_LOADED) then
        QTR:ADDON_LOADED(event, addon);
     end
     self:UnregisterEvent("ADDON_LOADED");
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
     QTR_Gossip_Show();
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
           -- DEFAULT_CHAT_FRAME:AddMessage("ArWoW_Quests - Qid: "..tostring(q_ID).." ("..QTR_Messages.missing..")");
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




-- Restore Blizzard quest fonts, headings, and reward labels.
function RestoreOriginalFonts()
  QuestInfoTitleHeader:SetFont(Original_Font1, 18);
   QuestInfoTitleHeader:SetJustifyH("LEFT");
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
  --QuestInfoItemChooseText:SetText(QTR_MessOrig.itemchoose1);
  --QuestInfoItemChooseText:SetFont(Original_Font2, 13);
  --QuestInfoItemReceiveText:SetText(QTR_MessOrig.itemreceiv1);
  --QuestInfoItemReceiveText:SetFont(Original_Font2, 13);
   QuestInfoItemChooseText:SetFont(Original_Font2, 13);
   QuestInfoItemChooseText:SetJustifyH("LEFT");
   QuestInfoItemReceiveText:SetFont(Original_Font2, 13);
   QuestInfoItemReceiveText:SetJustifyH("LEFT");
  QuestInfoXPFrameReceiveText:SetText(QTR_MessOrig.experience);
  QuestInfoXPFrameReceiveText:SetFont(Original_Font2, 13);
   QuestInfoXPFrameReceiveText:SetJustifyH("LEFT");
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
  QuestProgressRequiredMoneyText:SetText(QTR_MessOrig.reqmoney);
  QuestProgressRequiredMoneyText:SetFont(Original_Font2, 13);
   QuestProgressRequiredMoneyText:SetJustifyH("LEFT");
   QTR_RestoreWorldMapRewards();
end


-- Replace live quest dialog text inside the Blizzard quest frame.
function QTR_ChangeText_InEvent(QTR_event, str_id)
  if (QTR_PS["transtitle"]=="1") then
   QTR_SetShapedText(QuestInfoTitleHeader, QTR_GetTranslatedQuestTitleById(str_id), QTR_Font1, 18);
   QTR_SetShapedText(QuestProgressTitleText, QTR_GetTranslatedQuestTitleById(str_id), QTR_Font1, 18);
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
      QTR_SetShapedText(QuestInfoTitleHeader, QTR_GetTranslatedQuestTitleById(qid), QTR_Font1, 18);
  end
   QTR_SetShapedText(QuestInfoDescriptionHeader, QTR_Messages.details, QTR_Font1, 18);
   QTR_SetShapedText(QuestInfoDescriptionText, QTR_description, QTR_Font2, 13, QTR_QuestBodyLimit);
   QTR_SetShapedText(QuestInfoObjectivesHeader, QTR_Messages.objectives, QTR_Font1, 18);
   QTR_SetShapedText(QuestInfoObjectivesText, QTR_objectives, QTR_Font2, 13, QTR_QuestBodyLimit);
   QTR_SetShapedText(QuestInfoRewardsHeader, QTR_Messages.rewards, QTR_Font1, 18);
  --QuestInfoRewardText:SetText(QTR_ExpandUnitInfo(QTR_QuestData[qid]["Completion"]));
  --QuestInfoRewardText:SetFont(QTR_Font2, 13);
   QTR_SetShapedText(QuestInfoItemChooseText, QTR_Messages.itemchoose1, QTR_Font2, 13);
   QTR_SetShapedText(QuestInfoItemReceiveText, QTR_Messages.itemreceiv1, QTR_Font2, 13);
   QTR_SetShapedText(QuestInfoXPFrameReceiveText, QTR_Messages.experience, QTR_Font2, 13);
   QTR_SetShapedText(QuestInfoRequiredMoneyText, QTR_Messages.reqmoney, QTR_Font2, 13);
   QTR_SetShapedText(QuestInfoSpellLearnText, QTR_Messages.learnspell, QTR_Font2, 13);
end


-- Set the gossip greeting text with explicit font and alignment.
local QTR_GossipGreetingTextTargetWidth = 270;
local QTR_GossipGreetingTextOffsetX = 10;
local QTR_GossipGreetingTextOffsetY = -10;
local QTR_GossipGreetingArabicOffsetX = -2;
local QTR_GossipGreetingArabicExtraWidth = 4;


local function QTR_EnsureGossipGreetingWidth(useArabicLayout)
   if (not GossipGreetingText) then
      return nil;
   end

   local targetWidth = QTR_GossipGreetingTextTargetWidth;
   local parentFrame = GossipGreetingText:GetParent();
   if (parentFrame and parentFrame.GetWidth) then
      local parentWidth = parentFrame:GetWidth();
      if (parentWidth and parentWidth > 0) then
         local parentPadding = useArabicLayout and 15 or 20;
         targetWidth = math.min(targetWidth, parentWidth - parentPadding);
      end
   end

   if (useArabicLayout) then
      targetWidth = targetWidth + QTR_GossipGreetingArabicExtraWidth;
   end

   if (targetWidth < 220) then
      targetWidth = 220;
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
   QTR_EnsureGossipGreetingWidth(useArabicLayout);
   QTR_UpdateGossipGreetingAnchor(useArabicLayout);
   GossipGreetingText:SetFont(fontName, fontSize);
   QTR_ApplyRTLWidthAdjustment(GossipGreetingText, useArabicLayout, GossipGreetingText);
   GossipGreetingText:SetJustifyH(justify or "LEFT");
   GossipGreetingText:SetText(text or "");
end


-- Set the quest greeting text with explicit font and alignment.
local function QTR_SetQuestGreetingText(text, fontName, fontSize, justify)
   if (not GreetingText) then
      return;
   end

   GreetingText:SetText(text or "");
   GreetingText:SetFont(fontName, fontSize);
   GreetingText:SetJustifyH(justify or "LEFT");
end


local QTR_QuestGreetingTextTargetWidth = 320;


QTR_EnsureQuestGreetingWidth = function()
   if (not GreetingText) then
      return;
   end

   local targetWidth = QTR_QuestGreetingTextTargetWidth;
   local parentFrame = GreetingText:GetParent();

   if (parentFrame and parentFrame.GetWidth) then
      local parentWidth = parentFrame:GetWidth();
      if (parentWidth and parentWidth > 0) then
         targetWidth = math.min(targetWidth, parentWidth - 40);
      end
   end

   if (targetWidth < 280) then
      targetWidth = 280;
   end

   GreetingText:SetWidth(targetWidth);
end


QTR_SetQuestGreetingHeaders = function(showArabic)
   if (AvailableQuestsText) then
      AvailableQuestsText:SetWidth(280);
   end

   if (showArabic) then
      if (CurrentQuestsText) then
         QTR_SetShapedText(CurrentQuestsText, QTR_Messages.currquests, QTR_Font1, 18);
      end
      if (AvailableQuestsText) then
         QTR_SetShapedText(AvailableQuestsText, QTR_Messages.avaiquests, QTR_Font1, 18);
      end
   else
      if (CurrentQuestsText) then
         CurrentQuestsText:SetText(QTR_MessOrig.currquests);
         CurrentQuestsText:SetFont(Original_Font1, 18);
         CurrentQuestsText:SetJustifyH("LEFT");
      end
      if (AvailableQuestsText) then
         AvailableQuestsText:SetText(QTR_MessOrig.avaiquests);
         AvailableQuestsText:SetFont(Original_Font1, 18);
         AvailableQuestsText:SetJustifyH("LEFT");
      end
   end
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
   QTR_RefreshWorldMapQuestList();
   QTR_RefreshWatchFrame();
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


-- No-op kept for the QuestLogDetailScrollFrame OnHide hook.
function QTR_HideQuestInfo()
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

  local questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(questSelected);
  if (isHeader) then
     return;
  end

  local qid = tostring(questID);

  if (QTR_QuestData[qid]) then
     QTR_objectives  = QTR_ExpandUnitInfo(QTR_QuestData[qid]["Objectives"]);
     QTR_description = QTR_ExpandUnitInfo(QTR_QuestData[qid]["Description"]);
     QTR_ChangeText_OnQuestLog(qid);
  else
     RestoreOriginalFonts();
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
      QTR_SetQuestGreetingText(QTR_GS[QTR_QuestGreetingHash], Original_Font2, 13, "LEFT");
      QTR_SetQuestGreetingHeaders(false);
      QTR_RestoreGossipButtons(QTR_QuestGreetingButtonsEN, Original_Font2, 13);
      QTR_ToggleButtonQG:SetText("Gossip-Hash=["..tostring(QTR_QuestGreetingHash).."] EN");
   else
      QTR_QuestGreetingState="1";
      local Greeting_AR = QTR_PrepareShownGossipDisplayText(GS_Gossip[QTR_QuestGreetingHash], GreetingText:GetWidth(), 13, QTR_Font1);
      QTR_SetQuestGreetingText(Greeting_AR, QTR_Font1, 13, "RIGHT");
      QTR_SetQuestGreetingHeaders(true);
      QTR_RestoreGossipButtons(QTR_QuestGreetingButtonsAR, QTR_Font1, 13);
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
         local Greeting_AR = QTR_PrepareShownGossipDisplayText(GS_Gossip[Hash], GreetingText:GetWidth(), 13, QTR_Font1);
         QTR_SetQuestGreetingText(Greeting_AR, QTR_Font1, 13, "RIGHT");
         QTR_ToggleButtonQG:SetText("Gossip-Hash=["..tostring(Hash).."] AR");
         QTR_ToggleButtonQG:Enable();
      else
         QTR_QuestGreetingState = "0";
         QTR_GOSSIP[Nazwa_NPC.."@"..tostring(Hash)] = Greeting_Text.."@"..QTR_name..":"..QTR_race..":"..QTR_class;
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
               local questTitleAR = QTR_ReverseText(translatedQuestTitle);
               local translatedQuestButtonText = prefix .. questTitleAR .. suffix;
               QTR_QuestGreetingButtonsEN[questButton] = questButton:GetText();
               QTR_QuestGreetingButtonsAR[questButton] = translatedQuestButtonText;
               QTR_SetTitleButtonText(questButton, translatedQuestButtonText, QTR_Font1, 13);
            end
         end
      end
   else
      QTR_QuestGreetingState = "0";
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
      QTR_SetGossipGreetingText(originalGreetingText, Original_Font2, 13, "LEFT");
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
               QTR_SetGossipGreetingText(Greeting_Text, Original_Font2, 13, "LEFT");
               QTR_ToggleButtonGS:SetText("Gossip-Hash=["..tostring(Hash).."] EN");
            else
               curr_goss = "1";
               showArabicGossip = true;
               local Greeting_PL = GS_Gossip[Hash];
               local Greeting_AR = QTR_PrepareShownGossipDisplayText(Greeting_PL, QTR_EnsureGossipGreetingWidth(true), 13, QTR_Font1);
               QTR_SetGossipGreetingText(Greeting_AR, QTR_Font1, 13, "RIGHT");
               QTR_ToggleButtonGS:SetText("Gossip-Hash=["..tostring(Hash).."] AR");
            end
            QTR_ToggleButtonGS:Enable();
         else                               -- no translation in GOSSIP database
            curr_goss = "0";
            -- save to file
            QTR_GOSSIP[Nazwa_NPC.."@"..tostring(Hash)] = Greeting_Text.."@"..QTR_name..":"..QTR_race..":"..QTR_class;
            QTR_ToggleButtonGS:SetText("Gossip-Hash=["..tostring(Hash).."] EN");
            QTR_ToggleButtonGS:Disable();
         end
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
                  local questTitleAR = QTR_ReverseText(translatedQuestTitle);
                  local translatedQuestButtonText = prefix .. questTitleAR .. suffix;
                  QTR_GossipButtonsEN[questButton] = questButton:GetText();
                  QTR_GossipButtonsAR[questButton] = translatedQuestButtonText;
                  if (showArabicGossip) then
                     QTR_SetTitleButtonText(questButton, translatedQuestButtonText, QTR_Font1, 13);
                  end
               end
            end
         end
         if (GetNumGossipOptions()>0) then    -- there are still additional function buttons in gossip, that can be translated
            local titleButton;
            for i = 1, maxGossipButtons, 1 do 
               titleButton=getglobal("GossipTitleButton"..tostring(i));
               if (titleButton and titleButton:IsShown() and titleButton.type == "Gossip" and titleButton:GetText()) then
                  local gostxt = titleButton:GetText();
                  if (string.find(gostxt, "|cff000000") == nil) then   -- not a quest in gossip
                     local Hash = StringHash(gostxt);
                     if ( GS_Gossip[Hash] ) then   -- translation of additional text exists
                        local optionWidth = QTR_GetGossipOptionWidth(titleButton);
                        local Gossip_AR = QTR_PrepareGossipDisplayText(GS_Gossip[Hash], optionWidth, 13, QTR_Font1);
                        QTR_GossipButtonsEN[titleButton] = gostxt;
                        QTR_GossipButtonsAR[titleButton] = Gossip_AR;
                        if (showArabicGossip) then
                           QTR_SetTitleButtonText(titleButton, Gossip_AR, QTR_Font1, 13);
                        end
                     else
                        QTR_GOSSIP[Nazwa_NPC..'@'..tostring(Hash)] = gostxt.."@"..QTR_name..":"..QTR_race..":"..QTR_class;
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
      TutorialFrameText:SetWidth(tutorialTextWidth);
      if (Tut_tekst and AS_ContainsArabic and AS_ContainsArabic(Tut_tekst)) then
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
         local w = tutorialTextWidth;
         
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
   
   -- Handle all gender formatting cleanly using Spr_Gender and its gsub regexes
   msg = Spr_Gender(msg);

-- still handle NPC_GENDER(x;y)
   local nr_1, nr_2, nr_3 = 0;
   local QTR_forma = "";
   local NPC_sex = UnitSex("npc");     -- 1:neutral,  2:masculine,  3:feminine
   msg = string.gsub(msg, "NPC_GENDER%s*%(([^;]+);([^)]+)%)", function(masc, fem)
      return (NPC_sex == 3) and fem or masc
   end)

-- still handle OWN_NAME(EN;PL)
   local nr_1, nr_2, nr_3 = 0;
   local QTR_forma = "";
   local nr_poz = string.find(msg, "OWN_NAME");    -- when not found, it's: nil
   while (nr_poz and nr_poz>0) do
      nr_1 = nr_poz + 1;   
      while (string.sub(msg, nr_1, nr_1) ~= "(") do
         nr_1 = nr_1 + 1;
      end
      if (string.sub(msg, nr_1, nr_1) == "(") then
         nr_2 =  nr_1 + 1;
         while (string.sub(msg, nr_2, nr_2) ~= ";") do
            nr_2 = nr_2 + 1;
         end
         if (string.sub(msg, nr_2, nr_2) == ";") then
            nr_3 = nr_2 + 1;
            while (string.sub(msg, nr_3, nr_3) ~= ")") do
               nr_3 = nr_3 + 1;
            end
            if (string.sub(msg, nr_3, nr_3) == ")") then
--               if (QTR_PS["ownname"] == "1") then        -- Polish form
--                  QTR_forma = string.sub(msg,nr_2+1,nr_3-1);
--               else                                      -- English form
                  QTR_forma = string.sub(msg,nr_1+1,nr_2-1);
--               end
--               if ((QTR_PS["ownname_obj"] == "1") and OnObjectives) then        -- always English form in Objectives
--                  QTR_forma = string.sub(msg,nr_2+1,nr_3-1);
--               end
               msg = string.sub(msg,1,nr_poz-1) .. QTR_forma .. string.sub(msg,nr_3+1);
            end   
         end
      end
      nr_poz = string.find(msg, "OWN_NAME");
   end

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
      msg = string.gsub(msg, "ą YOUR_CLASS", "ą "..player_class.N2);            -- Instrumental (with whom, with what?)
      msg = string.gsub(msg, "esteś YOUR_CLASS", "esteś "..player_class.N2);      -- Instrumental (with whom, with what?)
      msg = string.gsub(msg, " z Ciebie YOUR_CLASS", " z Ciebie "..player_class.M2);    -- Nominative (who, what?)
      msg = string.gsub(msg, " kolejny YOUR_CLASS do ", " kolejny "..player_class.M2.." do ");   -- Nominative (who, what?)
      msg = string.gsub(msg, " taki YOUR_CLASS", " taki "..player_class.M2);      -- Nominative (who, what?)
      msg = string.gsub(msg, "ako YOUR_CLASS", "ako "..player_class.M2);          -- Nominative (who, what?)
      msg = string.gsub(msg, " co sprowadza YOUR_CLASS", " co sprowadza "..player_class.B2);     -- Accusative (whom, what?)
      msg = string.gsub(msg, " będę miał YOUR_CLASS", " będę miał "..player_class.B2);  -- Accusative (whom, what?)
      msg = string.gsub(msg, "YOUR_CLASS taki jak ", player_class.B2.." taki jak ");    -- Accusative (whom, what?)
      msg = string.gsub(msg, " jak na YOUR_CLASS", " jak na "..player_class.B2);        -- Accusative (whom, what?)
      msg = string.gsub(msg, "YOUR_CLASS", player_class.W2);                      -- Vocative - remaining occurrences
   else                    -- płeć męska
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
      msg = string.gsub(msg, "ym YOUR_RACE", "ym "..player_race.N1);              -- Instrumental (with whom, with what?)
      msg = string.gsub(msg, " jesteś YOUR_RACE", " jesteś "..player_race.N1);    -- Instrumental (with whom, with what?)
      msg = string.gsub(msg, "YOUR_RACE", player_race.W1);                        -- Vocative - remaining occurrences
      msg = string.gsub(msg, "ym YOUR_CLASS", "ym "..player_class.N1);            -- Instrumental (with whom, with what?)
      msg = string.gsub(msg, "esteś YOUR_CLASS", "esteś "..player_class.N1);      -- Instrumental (with whom, with what?)
      msg = string.gsub(msg, " z Ciebie YOUR_CLASS", " z Ciebie "..player_class.M1);    -- Nominative (who, what?)
      msg = string.gsub(msg, " kolejny YOUR_CLASS do ", " kolejny "..player_class.M1.." do ");   -- Nominative (who, what?)
      msg = string.gsub(msg, " taki YOUR_CLASS", " taki "..player_class.M1);      -- Nominative (who, what?)
      msg = string.gsub(msg, "ako YOUR_CLASS", "ako "..player_class.M1);          -- Nominative (who, what?)
      msg = string.gsub(msg, " co sprowadza YOUR_CLASS", " co sprowadza "..player_class.B1);     -- Accusative (whom, what?)
      msg = string.gsub(msg, " będę miał YOUR_CLASS", " będę miał "..player_class.B1);  -- Accusative (whom, what?)
      msg = string.gsub(msg, "ego YOUR_CLASS", "ego "..player_class.B1);                -- Accusative (whom, what?)
      msg = string.gsub(msg, "YOUR_CLASS taki jak ", player_class.B1.." taki jak ");    -- Accusative (whom, what?)
      msg = string.gsub(msg, " jak na YOUR_CLASS", " jak na "..player_class.B1);        -- Accusative (whom, what?)
      msg = string.gsub(msg, "YOUR_CLASS", player_class.W1);                      -- Vocative - remaining occurrences
   end

  return msg;
end

