-- Addon: WoWpoPolsku-Quests (version: 3.07) 2022.10.14
-- Description: AddOn displays translated quest information in original or separete window.
-- Autor: Platine  (e-mail: platine.wow@gmail.com)
-- WWW: https://wowpopolsku.pl

-- Global Variables
local QTR_version = "3.06";
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
local QTR_QuestBodyLimit = 37;
local QTR_FrameBodyLimit = 45;
local QTR_Interface2 = {
	mode1a     = "استبدل الترجمة مباشرة في النافذة",
	mode1b     = "التي تحتوي على النص الأصلي",
	mode2a     = "اعرض الترجمة في نافذة منفصلة",
	mode2b     = "بجانب النص الأصلي",
      };
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
   DEFAULT_CHAT_FRAME:AddMessage("|cff55ff00QTR - فئة جديدة: "..QTR_class);
end



function Spr_Gender(msg)
   local nr_1, nr_2, nr_3 = 0;
   local QTR_forma = "";
   local nr_poz = string.find(msg, "YOUR_GENDER");    -- gdy nie znalazł, jest: nil; liczy od 1
   while (nr_poz and nr_poz>0) do
      nr_1 = nr_poz + 1;   
      while (string.sub(msg, nr_1, nr_1) ~= "(") do   -- szukaj nawiasu otwierającego
         nr_1 = nr_1 + 1;
      end
      if (string.sub(msg, nr_1, nr_1) == "(") then
         nr_2 =  nr_1 + 1;
         while (string.sub(msg, nr_2, nr_2) ~= ";") do   -- szukaj średnika oddzielającego
            nr_2 = nr_2 + 1;
         end
         if (string.sub(msg, nr_2, nr_2) == ";") then
            nr_3 = nr_2 + 1;
            while (string.sub(msg, nr_3, nr_3) ~= ")") do   -- szykaj nawiasu zamykającego
               nr_3 = nr_3 + 1;
            end
            if (string.sub(msg, nr_3, nr_3) == ")") then
               if (QTR_sex==3) then        -- feminine form
                  QTR_forma = string.sub(msg,nr_2+1,nr_3-1);
               else                        -- masculine form
                  QTR_forma = string.sub(msg,nr_1+1,nr_2-1);
               end
               msg = string.sub(msg,1,nr_poz-1) .. QTR_forma .. string.sub(msg,nr_3+1);
            end   
         end
      end
      nr_poz = string.find(msg, "YOUR_GENDER");
   end
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


-- Wrap and reverse a text block line by line for right-to-left rendering.
local function QTR_LineReverse(text, limit)
  local retstr = "";
  if (text and limit) then
     local bytes = strlen(text);
     local pos = 1;
     local newstr = "";
     local counter = 0;
     while (pos <= bytes) do
        local charbytes = AS_UTF8charbytes(text, pos);
        local char1 = strsub(text, pos, pos + charbytes - 1);
        newstr = newstr .. char1;
        pos = pos + charbytes;

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


-- Apply fonts, alignment, and Arabic shaping through one shared display helper.
local function QTR_SetShapedText(fontString, text, fontName, fontSize, limit)
  fontString:SetFont(fontName, fontSize);
  if (text and AS_ContainsArabic and AS_ContainsArabic(text)) then
     fontString:SetJustifyH("RIGHT");
     if (limit) then
        fontString:SetText(QTR_ReverseBodyText(text, limit));
     else
        fontString:SetText(QTR_ReverseText(text));
     end
  else
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


-- Expand player, race, class, and gender placeholders inside gossip text.
local function QTR_ExpandGossipInfo(msg)
  if (not msg or msg == "") then
     return msg or "";
  end

  msg = string.gsub(msg, "{B}", "#");
  msg = string.gsub(msg, "NEW_LINE", "#");
  msg = string.gsub(msg, "\r\n", "#");
  msg = string.gsub(msg, "\r", "#");
  msg = string.gsub(msg, "\n", "#");

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

  if (QTR_sex == 3) then
     msg = string.gsub(msg, "{C}", player_class.M2);
     msg = string.gsub(msg, "{R}", player_race.M2);
     msg = string.gsub(msg, "YOUR_CLASS", player_class.M2);
     msg = string.gsub(msg, "YOUR_RACE", player_race.M2);
  else
     msg = string.gsub(msg, "{C}", player_class.M1);
     msg = string.gsub(msg, "{R}", player_race.M1);
     msg = string.gsub(msg, "YOUR_CLASS", player_class.M1);
     msg = string.gsub(msg, "YOUR_RACE", player_race.M1);
  end

  return Spr_Gender(msg);
end


-- Prepare gossip text for display, including wrapping for Arabic buttons.
local function QTR_PrepareGossipDisplayText(msg, width, fontSize)
  local expanded = QTR_ExpandGossipInfo(msg);
  if (expanded == "") then
     return expanded;
  end

  if (AS_ContainsArabic and AS_ContainsArabic(expanded) and width and width > 0) then
     return AS_ReverseAndPrepareLineText(expanded, width, fontSize);
  end

  return string.gsub(expanded, "#", "\n");
end


local QTR_GossipWrapWarmupDone = false;


local function QTR_PrepareShownGossipDisplayText(msg, width, fontSize)
   if (not QTR_GossipWrapWarmupDone) then
       QTR_GossipWrapWarmupDone = true;
       QTR_PrepareGossipDisplayText(msg, width, fontSize);
   end

   return QTR_PrepareGossipDisplayText(msg, width, fontSize);
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
   hashText = string.gsub(hashText, '$R', '');
   hashText = string.gsub(hashText, '$C', '');
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
     local isQuestTitleButton = titleButton:GetName() and string.find(titleButton:GetName(), "^QuestTitleButton");

     if (isQuestTitleButton and not QTR_TitleButtonAnchorCache[titleButton]) then
        local pointCount = fontString:GetNumPoints();
        local savedPoints = {};
        for index = 1, pointCount do
           savedPoints[index] = { fontString:GetPoint(index) };
        end
        QTR_TitleButtonAnchorCache[titleButton] = savedPoints;
     end

     if (text and AS_ContainsArabic and AS_ContainsArabic(text)) then
        fontString:SetJustifyH("RIGHT");
        if (isQuestTitleButton) then
           fontString:ClearAllPoints();
           fontString:SetPoint("TOPLEFT", titleButton, "TOPLEFT", 0, 0);
           fontString:SetPoint("TOPRIGHT", titleButton, "TOPRIGHT", -10, 0);
        end
     else
        fontString:SetJustifyH("LEFT");
        if (isQuestTitleButton and QTR_TitleButtonAnchorCache[titleButton]) then
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

  local isQuestTitleButton = titleButton:GetName() and string.find(titleButton:GetName(), "^QuestTitleButton");
  if (isQuestTitleButton and QTR_TitleButtonAnchorCache[titleButton]) then
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
  if (not QTR_PS["mode"] ) then
     QTR_PS["mode"] = "1";   
  end
  if (not QTR_PS["transtitle"] ) then
     QTR_PS["transtitle"] = "1";   
  end
  if (not QTR_PS["transtitle_migrated"]) then
     QTR_PS["transtitle"] = "1";
     QTR_PS["transtitle_migrated"] = "1";
  end
  if (not QTR_PS["size"] ) then
     QTR_PS["size"] = "1";   
  end
  if (not QTR_PS["width"] ) then
     QTR_PS["width"] = "1";   
  end

  -- set check buttons 
  if (QTR_PS["size"] == "1") then
     QTR_SizeH = 1;
  else 
     QTR_SizeH = 2;     
     QTRFrame1:SetHeight(525);
     QTR_QuestDetail:SetHeight(430);
     QTR_ToggleButton2:SetText("^");
  end
  if (QTR_PS["width"] == "1") then
     QTR_SizeW = 1;
  else 
     QTR_SizeW = 2;     
     QTRFrame1:SetWidth(525);
     QTR_QuestDetail:SetWidth(495);
     QTR_QuestTitle:SetWidth(495);
     QTR_ToggleButton3:SetText("<");
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
-- Resolve gender placeholders embedded in translated strings before display.


function QTR_SetCheckButtonState()
  QTRCheckButton0:SetChecked(QTR_PS["active"]=="1");
  QTRCheckButton1:SetChecked(QTR_PS["mode"]=="1");
  QTRCheckButton2:SetChecked(QTR_PS["mode"]=="2");
  QTRCheckButton3:SetChecked(QTR_PS["transtitle"]=="1");
  QTRCheckButton4:SetChecked(QTR_PS["size"]=="1");
  QTRCheckButton5:SetChecked(QTR_PS["size"]=="2");
  QTRCheckButton6:SetChecked(QTR_PS["width"]=="1");
  QTRCheckButton7:SetChecked(QTR_PS["width"]=="2");
  QTRCheckButtonGossip:SetChecked(QTR_PS["gossip"]=="1");
  QTRCheckButtonTutorial:SetChecked(QTR_PS["tutorial"]=="1");
end


-- Build the Blizzard Interface Options panel for this addon.
function QTR_BlizzardOptions()
  -- Create main frame for information text
  local QTROptions = CreateFrame("FRAME", "QTROptions");
  QTROptions:SetScript("OnShow", function(self) QTR_SetCheckButtonState() end);
  QTROptions.name = "Arabic WoW-Quests";
  InterfaceOptions_AddCategory(QTROptions);

  local QTROptionsHeader = QTROptions:CreateFontString(nil, "ARTWORK");
  QTROptionsHeader:SetFontObject(GameFontNormalLarge);
  QTROptionsHeader:SetJustifyH("LEFT"); 
  QTROptionsHeader:SetJustifyV("TOP");
  QTROptionsHeader:ClearAllPoints();
  QTROptionsHeader:SetPoint("TOPLEFT", 16, -16);
  QTROptionsHeader:SetText("Arabic WoW-Quests, ver. "..QTR_version.." ("..QTR_base..")");

  local QTRCheckButton0 = CreateFrame("CheckButton", "QTRCheckButton0", QTROptions, "OptionsCheckButtonTemplate");
  QTRCheckButton0:SetPoint("TOPLEFT", QTROptionsHeader, "BOTTOMLEFT", 0, -10);
  QTRCheckButton0:SetScript("OnClick", function(self) if (QTR_PS["active"]=="1") then QTR_PS["active"]="0" else QTR_PS["active"]="1" end; end);
  QTRCheckButton0Text:SetFont(QTR_Font2, 13);
   QTRCheckButton0Text:SetText(QTR_ReverseText(QTR_Interface.active));

  local QTROptionsMode0 = QTROptions:CreateFontString(nil, "ARTWORK");
  QTROptionsMode0:SetFontObject(GameFontWhite);
  QTROptionsMode0:SetJustifyH("LEFT");
  QTROptionsMode0:SetJustifyV("TOP");
  QTROptionsMode0:ClearAllPoints();
  QTROptionsMode0:SetPoint("TOPLEFT", QTRCheckButton0, "BOTTOMLEFT", 20, -5);
  QTROptionsMode0:SetFont(QTR_Font2, 13);
   QTROptionsMode0:SetText(QTR_ReverseText(QTR_Interface.mode));

  local QTRCheckButton1 = CreateFrame("CheckButton", "QTRCheckButton1", QTROptions, "OptionsCheckButtonTemplate");
  QTRCheckButton1:SetPoint("TOPLEFT", QTROptionsMode0, "BOTTOMLEFT", 0, -5);
  QTRCheckButton1:SetScript("OnClick", function(self) if (QTR_PS["mode"]=="2") then QTR_PS["mode"]="1" else QTR_PS["mode"]="2" end; QTRCheckButton2:SetChecked(QTR_PS["mode"]=="2"); end);
  QTRCheckButton1Text:SetFont(QTR_Font2, 13);
   QTRCheckButton1Text:SetText(QTR_ReverseText(QTR_Interface2.mode1a));

  local QTROptionsText1b = QTROptions:CreateFontString(nil, "ARTWORK");
  QTROptionsText1b:SetFontObject(GameFontNormal);
  QTROptionsText1b:SetJustifyH("LEFT");
  QTROptionsText1b:SetJustifyV("TOP");
  QTROptionsText1b:ClearAllPoints();
  QTROptionsText1b:SetPoint("TOPLEFT", QTRCheckButton1, "BOTTOMLEFT", 30, 5);
  QTROptionsText1b:SetFont(QTR_Font2, 13);
   QTROptionsText1b:SetText(QTR_ReverseText(QTR_Interface2.mode1b));

  local QTROptionsMode1 = QTROptions:CreateFontString(nil, "ARTWORK");
  QTROptionsMode1:SetFontObject(GameFontWhite);
  QTROptionsMode1:SetJustifyH("LEFT");
  QTROptionsMode1:SetJustifyV("TOP");
  QTROptionsMode1:ClearAllPoints();
  QTROptionsMode1:SetPoint("TOPLEFT", QTROptionsText1b, "BOTTOMLEFT", 0, -10);
  QTROptionsMode1:SetFont(QTR_Font2, 13);
   QTROptionsMode1:SetText(QTR_ReverseText(QTR_Interface.options1));
  
  local QTRCheckButton3 = CreateFrame("CheckButton", "QTRCheckButton3", QTROptions, "OptionsCheckButtonTemplate");
  QTRCheckButton3:SetPoint("TOPLEFT", QTROptionsMode1, "BOTTOMLEFT", 0, 0);
  QTRCheckButton3:SetScript("OnClick", function(self) if (QTR_PS["transtitle"]=="0") then QTR_PS["transtitle"]="1" else QTR_PS["transtitle"]="0" end; end);
  QTRCheckButton3Text:SetFont(QTR_Font2, 13);
   QTRCheckButton3Text:SetText(QTR_ReverseText(QTR_Interface.transtitle));

  local QTRCheckButton2 = CreateFrame("CheckButton", "QTRCheckButton2", QTROptions, "OptionsCheckButtonTemplate");
  QTRCheckButton2:SetPoint("TOPLEFT", QTRCheckButton3, "BOTTOMLEFT", -30, -5);
  QTRCheckButton2:SetScript("OnClick", function(self) if (QTR_PS["mode"]=="1") then QTR_PS["mode"]="2" else QTR_PS["mode"]="1" end; QTRCheckButton1:SetChecked(QTR_PS["mode"]=="1"); end);
  QTRCheckButton2Text:SetFont(QTR_Font2, 13);
   QTRCheckButton2Text:SetText(QTR_ReverseText(QTR_Interface2.mode2a));

  local QTROptionsText2b = QTROptions:CreateFontString(nil, "ARTWORK");
  QTROptionsText2b:SetFontObject(GameFontNormal);
  QTROptionsText2b:SetJustifyH("LEFT");
  QTROptionsText2b:SetJustifyV("TOP");
  QTROptionsText2b:ClearAllPoints();
  QTROptionsText2b:SetPoint("TOPLEFT", QTRCheckButton2, "BOTTOMLEFT", 30, 5);
  QTROptionsText2b:SetFont(QTR_Font2, 13);
   QTROptionsText2b:SetText(QTR_ReverseText(QTR_Interface2.mode2b));

  local QTROptionsMode2 = QTROptions:CreateFontString(nil, "ARTWORK");
  QTROptionsMode2:SetFontObject(GameFontWhite);
  QTROptionsMode2:SetJustifyH("LEFT");
  QTROptionsMode2:SetJustifyV("TOP");
  QTROptionsMode2:ClearAllPoints();
  QTROptionsMode2:SetPoint("TOPLEFT", QTROptionsText2b, "BOTTOMLEFT", 0, -10);
  QTROptionsMode2:SetFont(QTR_Font2, 13);
   QTROptionsMode2:SetText(QTR_ReverseText(QTR_Interface.options2));
  
  local QTRCheckButton4 = CreateFrame("CheckButton", "QTRCheckButton4", QTROptions, "OptionsCheckButtonTemplate");
  QTRCheckButton4:SetPoint("TOPLEFT", QTROptionsMode2, "BOTTOMLEFT", 0, 0);
  QTRCheckButton4:SetScript("OnClick", function(self) QTR_ChangeFrameHeight(); QTRCheckButton5:SetChecked(QTR_PS["size"]=="2"); end);
  QTRCheckButton4Text:SetFont(QTR_Font2, 13);
   QTRCheckButton4Text:SetText(QTR_ReverseText(QTR_Interface.height1));
  
  local QTRCheckButton5 = CreateFrame("CheckButton", "QTRCheckButton5", QTROptions, "OptionsCheckButtonTemplate");
  QTRCheckButton5:SetPoint("TOPLEFT", QTRCheckButton4, "BOTTOMLEFT", 0, 8);
  QTRCheckButton5:SetScript("OnClick", function(self) QTR_ChangeFrameHeight(); QTRCheckButton4:SetChecked(QTR_PS["size"]=="1"); end);
  QTRCheckButton5Text:SetFont(QTR_Font2, 13);
   QTRCheckButton5Text:SetText(QTR_ReverseText(QTR_Interface.height2));
  
  local QTRCheckButton6 = CreateFrame("CheckButton", "QTRCheckButton6", QTROptions, "OptionsCheckButtonTemplate");
  QTRCheckButton6:SetPoint("TOPLEFT", QTRCheckButton5, "BOTTOMLEFT", 0, 0);
  QTRCheckButton6:SetScript("OnClick", function(self) QTR_ChangeFrameWidth(); QTRCheckButton7:SetChecked(QTR_PS["width"]=="2"); end);
  QTRCheckButton6Text:SetFont(QTR_Font2, 13);
   QTRCheckButton6Text:SetText(QTR_ReverseText(QTR_Interface.width1));
  
  local QTRCheckButton7 = CreateFrame("CheckButton", "QTRCheckButton7", QTROptions, "OptionsCheckButtonTemplate");
  QTRCheckButton7:SetPoint("TOPLEFT", QTRCheckButton6, "BOTTOMLEFT", 0, 8);
  QTRCheckButton7:SetScript("OnClick", function(self) QTR_ChangeFrameWidth(); QTRCheckButton6:SetChecked(QTR_PS["width"]=="1"); end);
  QTRCheckButton7Text:SetFont(QTR_Font2, 13);
   QTRCheckButton7Text:SetText(QTR_ReverseText(QTR_Interface.width2));
  
  local QTRCheckButtonGossip = CreateFrame("CheckButton", "QTRCheckButtonGossip", QTROptions, "OptionsCheckButtonTemplate");
  QTRCheckButtonGossip:SetPoint("TOPLEFT", QTRCheckButton7, "BOTTOMLEFT", -50, -10);
  QTRCheckButtonGossip:SetScript("OnClick", function(self) if (QTR_PS["gossip"]=="1") then QTR_PS["gossip"]="0" else QTR_PS["gossip"]="1" end; end);
  QTRCheckButtonGossipText:SetFont(QTR_Font2, 13);
   QTRCheckButtonGossipText:SetText(QTR_ReverseText("اعرض ترجمات نصوص الحوار"));
  
  local QTRCheckButtonTutorial = CreateFrame("CheckButton", "QTRCheckButtonTutorial", QTROptions, "OptionsCheckButtonTemplate");
  QTRCheckButtonTutorial:SetPoint("TOPLEFT", QTRCheckButtonGossip, "BOTTOMLEFT", 0, -5);
  QTRCheckButtonTutorial:SetScript("OnClick", function(self) if (QTR_PS["tutorial"]=="1") then QTR_PS["tutorial"]="0" else QTR_PS["tutorial"]="1" end; end);
  QTRCheckButtonTutorialText:SetFont(QTR_Font2, 13);
   QTRCheckButtonTutorialText:SetText(QTR_ReverseText("اعرض ترجمات النصوص التعليمية")); 
  
  local QTRWWW1 = QTROptions:CreateFontString(nil, "ARTWORK");
  QTRWWW1:SetFontObject(GameFontWhite);
  QTRWWW1:SetJustifyH("LEFT");
  QTRWWW1:SetJustifyV("TOP");
  QTRWWW1:ClearAllPoints();
  QTRWWW1:SetPoint("BOTTOMLEFT", 16, 16);
  QTRWWW1:SetFont(QTR_Font2, 13);
   QTRWWW1:SetText(QTR_ReverseText("زيارة موقع الإضافة:"));
  
  local QTRWWW2 = CreateFrame("EditBox", "QTRWWW2", QTROptions, "InputBoxTemplate");
  QTRWWW2:ClearAllPoints();
  QTRWWW2:SetPoint("TOPLEFT", QTRWWW1, "TOPRIGHT", 10, 4);
  QTRWWW2:SetHeight(20);
  QTRWWW2:SetWidth(170);
  QTRWWW2:SetAutoFocus(false);
  QTRWWW2:SetFontObject(GameFontGreen);
  QTRWWW2:SetText("https://wowpopolsku.pl");
  QTRWWW2:SetCursorPosition(0);
  QTRWWW2:SetScript("OnEnter", function(self)
	  GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
      getglobal("GameTooltipTextLeft1"):SetFont(QTR_Font2, 13);
	  GameTooltip:SetText(QTR_ReverseText("اضغط ثم استخدم اختصار النسخ لنسخ الرابط إلى الحافظة"), nil, nil, nil, nil, true)
	  GameTooltip:Show() --Show the tooltip
     end);
  QTRWWW2:SetScript("OnLeave", function(self)
      getglobal("GameTooltipTextLeft1"):SetFont(Original_Font2, 13);
	  GameTooltip:Hide() --Hide the tooltip
     end);
  QTRWWW2:SetScript("OnTextChanged", function(self) QTRWWW2:SetText("https://wowpopolsku.pl"); end);
end


-- Initialize the quest log side panel, buttons, and quest log hooks.
function QTR_OnLoad1()
  QTR.frame1 = CreateFrame("Frame");
  QTR.frame1:RegisterEvent("ADDON_LOADED");
  QTR.frame1:RegisterEvent("QUEST_LOG_UPDATE");
  QTR.frame1:SetScript("OnEvent", function(self, event, ...) return QTR[event] and QTR[event](QTR, event, ...) end);
  QuestLogDetailScrollFrame:SetScript("OnShow", QTR_ShowAndUpdateQuestInfo);
  QuestLogDetailScrollFrame:SetScript("OnHide", QTR_HideQuestInfo);

  QTR_QuestTitle:SetFont(QTR_Font2, 17);
  QTR_QuestDetail:SetFont(QTR_Font2, 14);
  QTRFrame1:ClearAllPoints();
  QTRFrame1:SetPoint("TOPLEFT", QuestLogFrame, "TOPRIGHT", -3, -12);

  -- small button in QuestLogFrame
  QTR_ToggleButton1 = CreateFrame("Button",nil, QuestLogFrame, "UIPanelButtonTemplate");
  QTR_ToggleButton1:SetWidth(35);
  QTR_ToggleButton1:SetHeight(18);
  QTR_ToggleButton1:SetText("QTR");
  QTR_ToggleButton1:Show();
  QTR_ToggleButton1:ClearAllPoints();
  QTR_ToggleButton1:SetPoint("TOPLEFT", QuestLogFrame, "TOPLEFT", 620, -15);
  QTR_ToggleButton1:SetScript("OnClick", QTR_ToggleVisibility);

  -- button for ChangeFrameHeight
  QTR_ToggleButton2 = CreateFrame("Button",nil, QTRFrame1, "UIPanelButtonTemplate");
  QTR_ToggleButton2:SetWidth(15);
  QTR_ToggleButton2:SetHeight(22);
  QTR_ToggleButton2:SetText("v");
  QTR_ToggleButton2:Show();
  QTR_ToggleButton2:ClearAllPoints();
  QTR_ToggleButton2:SetPoint("BOTTOMLEFT", QTRFrame1, "BOTTOMRIGHT", -40, 9);
  QTR_ToggleButton2:SetScript("OnClick", QTR_ChangeFrameHeight);

  -- button for ChangeFrameWidth
  QTR_ToggleButton3 = CreateFrame("Button",nil, QTRFrame1, "UIPanelButtonTemplate");
  QTR_ToggleButton3:SetWidth(15);
  QTR_ToggleButton3:SetHeight(22);
  QTR_ToggleButton3:SetText(">");
  QTR_ToggleButton3:Show();
  QTR_ToggleButton3:ClearAllPoints();
  QTR_ToggleButton3:SetPoint("BOTTOMLEFT", QTRFrame1, "BOTTOMRIGHT", -25, 9);
  QTR_ToggleButton3:SetScript("OnClick", QTR_ChangeFrameWidth);

  hooksecurefunc("QuestLogTitleButton_OnClick", function() QTR_UpdateQuestInfo() end);
   hooksecurefunc("QuestLog_Update", QTR_UpdateQuestLogTitleButtons);
  
   -- button with no HASH gossip in QuestMapDetailsScrollFrame
   QTR_ToggleButtonGS = CreateFrame("Button",nil, GossipFrame, "UIPanelButtonTemplate");
   QTR_ToggleButtonGS:SetWidth(230);
   QTR_ToggleButtonGS:SetHeight(20);
   QTR_ToggleButtonGS:SetText("Gossip-Hash=?");
   QTR_ToggleButtonGS:Show();
   QTR_ToggleButtonGS:ClearAllPoints();
   QTR_ToggleButtonGS:SetPoint("TOPLEFT", GossipFrame, "TOPLEFT", 70, -50);
   QTR_ToggleButtonGS:SetScript("OnClick", GS_ON_OFF);

   -- button with HASH gossip in QuestFrame greeting view
   QTR_ToggleButtonQG = CreateFrame("Button",nil, QuestFrame, "UIPanelButtonTemplate");
   QTR_ToggleButtonQG:SetWidth(230);
   QTR_ToggleButtonQG:SetHeight(20);
   QTR_ToggleButtonQG:SetText("Gossip-Hash=?");
   QTR_ToggleButtonQG:ClearAllPoints();
   QTR_ToggleButtonQG:SetPoint("TOPLEFT", QuestFrame, "TOPLEFT", 95, -32);
   QTR_ToggleButtonQG:SetScript("OnClick", GS_ON_OFF_QUEST);
   QTR_ToggleButtonQG:Disable();
   QTR_ToggleButtonQG:Hide();
end


-- Initialize quest dialog, world map, gossip, and tutorial event hooks.
function QTR_OnLoad2()
  QTR.frame2 = CreateFrame("Frame");
  QTR.frame2:RegisterEvent("QUEST_GREETING");
  QTR.frame2:RegisterEvent("QUEST_DETAIL");
  QTR.frame2:RegisterEvent("QUEST_PROGRESS");
  QTR.frame2:RegisterEvent("QUEST_COMPLETE");
  QTR.frame2:RegisterEvent("WORLD_MAP_UPDATE");
  QTR.frame2:RegisterEvent("GOSSIP_SHOW");
  QTR.frame2:SetScript("OnEvent", function(self, event, ...) return QTR[event] and QTR[event](QTR, event, ...) end);
  QTR_QuestTitle2:SetFont(QTR_Font2, 17);
  QTR_QuestDetail2:SetFont(QTR_Font2, 14);
  QTR_QuestWarning2:SetFont(QTR_Font2, 12);
  QTRFrame2:ClearAllPoints();
  QTRFrame2:SetPoint("TOPLEFT", QuestFrame, "TOPRIGHT", -31, -19);
  QuestFrame:SetScript("OnHide", QTR_Frame2Close);
  hooksecurefunc("WorldMapQuestFrame_OnMouseUp", function() QTR_WorldMapQuestFrameOnMouseUp() end);
  TutorialFrame:HookScript("OnShow", Tut_onTutorialShow);
  TutorialFrameNextButton:HookScript("OnClick", Tut_onTutorialShow);
  TutorialFramePrevButton:HookScript("OnClick", Tut_onTutorialShow);
end


-- Refresh translated world map quest text after the selected quest changes.
function QTR_WorldMapQuestFrameOnMouseUp()
  QTR_event = "WORLD_MAP_OnMouseUp";
  QTR_OnEvent2();
  if (not QTR_WorldMapRetryPending) then
     QTR_WorldMapRetryPending = true;
     if (not QTR_wait(0.2, function(eventName)
        QTR_WorldMapRetryPending = false;
        if (WorldMapFrame and WorldMapFrame:IsVisible() and QTR_PS and QTR_PS["active"]=="1" and QTR_PS["mode"]=="1") then
           QTR_event = eventName;
           QTR_OnEvent2();
        end
     end, "WORLD_MAP_OnMouseUp")) then
        QTR_WorldMapRetryPending = false;
     end
  end
end


-- Open the addon options panel from the registered slash commands.
function QTR_SlashCommand(msg)
  InterfaceOptionsFrame_OpenToCategory(QTROptions);
  RestoreOriginalFonts();
end


-- Finish addon startup once this addon has been loaded by the client.
function QTR:ADDON_LOADED(_, addon)
   if (addon == "ArWoW_Quests") then
     SlashCmdList["WOWPOPOLSKU_QUESTS"] = function(msg) QTR_SlashCommand(msg); end
     SLASH_WOWPOPOLSKU_QUESTS1 = "/arwow-quests";
     SLASH_WOWPOPOLSKU_QUESTS2 = "/qtr";
     QTR_CheckVars();
     QTR_BlizzardOptions();
     if (DEFAULT_CHAT_FRAME) then
         DEFAULT_CHAT_FRAME:AddMessage("|cffffff00ArWoW-Quests ver. "..QTR_version.." - " .. QTR_Messages.loaded);
     else
         UIErrorsFrame:AddMessage("|cffffff00ArWoW-Quests ver. "..QTR_version.." - " .. QTR_Messages.loaded, 1.0, 1.0, 1.0, 1.0, UIERRORS_HOLD_TIME);
     end
     self.frame1:UnregisterEvent("ADDON_LOADED");
     self.ADDON_LOADED = nil;
     QTR_Messages.itemchoose1 = Spr_Gender(QTR_Messages.itemchoose1);
     DetectEmuServer();
  end
end


-- Refresh the quest log translation pane when the quest log changes.
function QTR:QUEST_LOG_UPDATE()
  if (QTRFrame1:IsVisible()) then
     QTR_UpdateQuestInfo();
  end
end


-- Re-apply quest translations when the world map quest detail panel refreshes.
function QTR:WORLD_MAP_UPDATE()
  if ( WorldMapFrame:IsVisible() ) then
     if (QTR_PS["active"]=="1") then
        if (QTR_PS["mode"]=="1") then
           if ( WorldMapQuestShowObjectives:GetChecked() ) then
              QTR_event = "WORLD_MAP_UPDATE";
              QTR_OnEvent2();
              if (not QTR_WorldMapRetryPending) then
                 QTR_WorldMapRetryPending = true;
                 if (not QTR_wait(0.2, function(eventName)
                    QTR_WorldMapRetryPending = false;
                    if (WorldMapFrame and WorldMapFrame:IsVisible() and WorldMapQuestShowObjectives and WorldMapQuestShowObjectives:GetChecked() and QTR_PS and QTR_PS["active"]=="1" and QTR_PS["mode"]=="1") then
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

   if (QTR_PS["active"]=="1" and QTR_PS["mode"]=="1") then
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
        q_title=questFrame.title:GetText();
        break;
      end
    end
  end

  -- search in QuestLog
  while GetQuestLogTitle(q_i) do
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
     QTR_QuestID2:SetText("");
     QTR_SetShapedText(QTR_QuestTitle2, q_title, QTR_Font1, 17);
     QTR_SetShapedText(QTR_QuestDetail2, QTR_Messages.missing, QTR_Font2, 14, QTR_FrameBodyLimit);
     QTR_QuestWarning2:SetText("");
     QTR_QuestWarning2:SetFont(QTR_Font2, 12);
     QTR_QuestWarning2:SetJustifyH("LEFT");
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
              q_i=string.find(q_lists, ",");
              if ( string.find(q_lists, ",")==nil ) then
                 -- only 1 questID to this title
                 q_ID=tonumber(q_lists);
              else
                 -- multiple questIDs - get first, available (not completed) questID from QuestLists
                 local QTR_table=QTR_split(q_lists, ",");
                 local QTR_multiple = "";
                 local QTR_Center="";
                 for ii,vv in ipairs(QTR_table) do
                    if (not QTR_PC[vv]) then
                       if (QTR_Center=="") then
                           QTR_Center=vv;
                       else
                           QTR_multiple = QTR_multiple .. ", " .. vv;
                       end
                    end
                 end
                 if ( string.len(QTR_Center)>0 ) then
                    q_ID=tonumber(QTR_Center);
                    if ( string.len(QTR_multiple)>0 ) then
                       QTR_multiple = " (" .. string.sub(QTR_multiple, 3) .. ")";
                       QTR_SetShapedText(QTR_QuestWarning2, QTR_Messages.multipleID .. QTR_multiple, QTR_Font2, 12);
                    end
                 end
              end
           end
        end
     end
     if ( q_ID > 0 ) then
        local str_id = tostring(q_ID);
        QTR_QuestID2:SetText("QuestID: " .. str_id);
        QTR_SetShapedText(QTR_QuestTitle2, q_title, QTR_Font1, 17);
        if (QTR_QuestData[str_id]) then
           -- display only, if translation exists
	   if (QTR_PS["mode"]=="2") then
              QTR_ShowFrame2(QTR_event, str_id);
	   else
              QTR_ChangeText_InEvent(QTR_event, str_id);
           end
        else
           -- DEFAULT_CHAT_FRAME:AddMessage("WoWpoPolsku-Quests - Qid: "..tostring(q_ID).." ("..QTR_Messages.missing..")");
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
           QTRFrame2:Hide();
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


-- Fill and show the separate translated quest dialog window.
function QTR_ShowFrame2(eventStr, qid)
  QTR_QuestID2:SetText("QuestID: " .. qid);
  QTR_SetShapedText(QTR_QuestDetail2, QTR_Messages.missing, QTR_Font2, 14, QTR_FrameBodyLimit);
  if (QTR_QuestData[qid]) then
   QTR_SetShapedText(QTR_QuestTitle2, QTR_GetTranslatedQuestTitleById(qid), QTR_Font1, 17);
     local QTR_text = "";
     if (eventStr == "QUEST_DETAIL") then
        if (QTR_QuestData[qid]["Description"]) then
           QTR_text = QTR_ExpandUnitInfo(QTR_QuestData[qid]["Description"]);
        end
        local QTR_text2 = "";
        if (QTR_QuestData[qid]["Objectives"]) then
           QTR_text2 = QTR_ExpandUnitInfo(QTR_QuestData[qid]["Objectives"]);
        end
        QTR_text = QTR_text .. "\n\n" .. QTR_Messages.objectives .. "\n" .. QTR_text2;
     end
     if (eventStr == "QUEST_PROGRESS") then
        if (QTR_QuestData[qid]["Progress"]) then
           QTR_text = QTR_ExpandUnitInfo(QTR_QuestData[qid]["Progress"]);
        end
     end
     if (eventStr == "QUEST_COMPLETE") then
        if (QTR_QuestData[qid]["Completion"]) then
           QTR_text = QTR_ExpandUnitInfo(QTR_QuestData[qid]["Completion"]);
        end
     end
     QTR_SetShapedText(QTR_QuestDetail2, QTR_text, QTR_Font2, 14, QTR_FrameBodyLimit);
     QTRFrame2:ClearAllPoints();
     QTRFrame2:SetPoint("TOPLEFT", QuestFrame, "TOPRIGHT", -31, -19);
     if ( QuestNPCModel ) then
        if ( QuestNPCModel:IsVisible() ) then
           QTRFrame2:SetPoint("TOPLEFT", QuestNPCModel, "TOPRIGHT", 0, 42);
        end
     end
     QTRFrame2:Show();
  end
end


-- Hide the separate quest dialog window and run the default cleanup.
function QTR_Frame2Close()
  QTRFrame2:Hide();
   if (QTR_ToggleButtonQG) then
       QTR_ToggleButtonQG:Hide();
   end
  QuestFrame_OnHide();
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


-- Find the last occurrence of a character inside a string.
function QTR_findlast(source, char)
  if (not source) then
     return 0;
  end
  local lastpos = 0;
  local byte_char = string.byte(char);
  for i=1, #source do
     if (string.byte(source,i)==byte_char) then
        lastpos = i;
     end
  end
  return lastpos;
end


-- Toggle the translation pane between compact and tall layouts.
function QTR_ChangeFrameHeight()
  -- normal height of Frame = 425, quest detail = 350
  if (QTR_SizeH == 1) then
     QTRFrame1:SetHeight(525);
     QTR_QuestDetail:SetHeight(430);
     QTR_ToggleButton2:SetText("^");
     QTR_SizeH = 2;
     QTR_PS["size"] = "2";
  else
     QTRFrame1:SetHeight(425);
     QTR_QuestDetail:SetHeight(350);
     QTR_ToggleButton2:SetText("v");
     QTR_SizeH = 1;
     QTR_PS["size"] = "1";
  end
end


-- Toggle the translation pane between narrow and wide layouts.
function QTR_ChangeFrameWidth()
  -- normal width of Frame = 350, quest detail = 320
  if (QTR_SizeW == 1) then
     QTRFrame1:SetWidth(525);
     QTR_QuestDetail:SetWidth(495);
     QTR_QuestTitle:SetWidth(495);
     QTR_ToggleButton3:SetText("<");
     QTR_SizeW = 2;
     QTR_PS["width"] = "2";
  else
     QTRFrame1:SetWidth(350);
     QTR_QuestDetail:SetWidth(320);
     QTR_QuestTitle:SetWidth(320);
     QTR_ToggleButton3:SetText(">");
     QTR_SizeW = 1;
     QTR_PS["width"] = "1";
  end
end


-- Start dragging the quest log translation pane.
function QTR_OnMouseDown1()
  -- start moving the window
  QTRFrame1:StartMoving();
end
  

-- Stop dragging the quest log translation pane.
function QTR_OnMouseUp1()
  -- stop moving the window
  QTRFrame1:StopMovingOrSizing();
end


-- Start dragging the separate quest dialog pane.
function QTR_OnMouseDown2()
  -- start moving the window
  QTRFrame2:StartMoving();
end
  

-- Stop dragging the separate quest dialog pane.
function QTR_OnMouseUp2()
  -- stop moving the window
  QTRFrame2:StopMovingOrSizing();
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
  QuestProgressRequiredItemsText:SetText(QTR_MessOrig.reqitems);
  QuestProgressRequiredItemsText:SetFont(Original_Font1, 18);
   QuestProgressRequiredItemsText:SetJustifyH("LEFT");
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
  QTR_SetShapedText(QuestInfoDescriptionText, QTR_ExpandUnitInfo(QTR_QuestData[str_id]["Description"]), QTR_Font2, 13, QTR_QuestBodyLimit);
  QTR_SetShapedText(QuestInfoObjectivesHeader, QTR_Messages.objectives, QTR_Font1, 18);
  QTR_SetShapedText(QuestInfoObjectivesText, QTR_ExpandUnitInfo(QTR_QuestData[str_id]["Objectives"]), QTR_Font2, 13, QTR_QuestBodyLimit);
  QTR_SetShapedText(QuestInfoRewardsHeader, QTR_Messages.rewards, QTR_Font1, 18);
  QTR_SetShapedText(QuestInfoRewardText, QTR_ExpandUnitInfo(QTR_QuestData[str_id]["Completion"]), QTR_Font2, 13, QTR_QuestBodyLimit);
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
  QTR_SetShapedText(QuestProgressText, QTR_ExpandUnitInfo(QTR_QuestData[str_id]["Progress"]), QTR_Font2, 13, QTR_QuestBodyLimit);
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
local function QTR_SetGossipGreetingText(text, fontName, fontSize, justify)
   GossipGreetingText:SetText(text or "");
   GossipGreetingText:SetFont(fontName, fontSize);
   GossipGreetingText:SetJustifyH(justify or "LEFT");
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
     if (DEFAULT_CHAT_FRAME) then
         DEFAULT_CHAT_FRAME:AddMessage("|cffffff00ArWoW-Quests "..QTR_Messages.isactive);
     else
         UIErrorsFrame:AddMessage("|cffffff00ArWoW-Quests "..QTR_Messages.isactive, 1.0, 1.0, 1.0, 1.0, UIERRORS_HOLD_TIME);
     end
  else
     QTR_PS["active"] = "0";
     QTR_HideQuestInfo();
     if (DEFAULT_CHAT_FRAME) then
         DEFAULT_CHAT_FRAME:AddMessage("|cffffff00ArWoW-Quests "..QTR_Messages.isinactive);
     else
         UIErrorsFrame:AddMessage("|cffffff00ArWoW-Quests "..QTR_Messages.isinactive, 1.0, 1.0, 1.0, 1.0, UIERRORS_HOLD_TIME);
     end
     RestoreOriginalFonts();
     if (QTR_PS["mode"]=="1") then
        QTR_RestoreQuestLogEnglish();
     end
  end
end


-- Show the side pane if needed and refresh its selected quest content.
function QTR_ShowAndUpdateQuestInfo()
  if (not QTR_PS) then
     QTR_CheckVars();
  end
  if (QTR_PS["active"]=="0") then
     return;
  end
  if (QTR_PS["mode"]=="2") then
     QTRFrame1:Show();
  end;
  QTR_UpdateQuestInfo();
   QTR_UpdateQuestLogTitleButtons();
end


-- Hide the quest log translation pane.
function QTR_HideQuestInfo()
  QTRFrame1:Hide();
end


-- Load the selected quest into the side translation pane.
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
  QTR_QuestID:SetText("QuestID: " .. qid);

  if (QTR_QuestData[qid]) then
     QTR_objectives  = QTR_ExpandUnitInfo(QTR_QuestData[qid]["Objectives"]);
     QTR_description = QTR_ExpandUnitInfo(QTR_QuestData[qid]["Description"]);
     QTR_descripFull = QTR_Messages.details .. "\n" .. QTR_description;
     QTR_translator = "";
     if (QTR_QuestData[qid]["Translator"]) then
        if (QTR_QuestData[qid]["Translator"]>"") then
            QTR_translator = "\n\n" .. QTR_Messages.translator .. " " .. QTR_ExpandUnitInfo(QTR_QuestData[qid]["Translator"]);
        end
     end
   QTR_SetShapedText(QTR_QuestTitle, QTR_GetTranslatedQuestTitleById(qid), QTR_Font1, 17);
     QTR_SetShapedText(QTR_QuestDetail, QTR_objectives .. "\n\n" .. QTR_descripFull .. QTR_translator, QTR_Font2, 14, QTR_FrameBodyLimit);
     if (QTR_PS["mode"]=="1") then		       -- translation direct into original QuestLog frame
        QTR_ChangeText_OnQuestLog(qid);
     end
  else
     QTR_SetShapedText(QTR_QuestTitle, questTitle, QTR_Font1, 17);
     QTR_SetShapedText(QTR_QuestDetail, QTR_Messages.missing, QTR_Font2, 14, QTR_FrameBodyLimit);
     if (QTR_PS["mode"]=="1") then
	RestoreOriginalFonts();
     end;
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
      local Greeting_AR = QTR_PrepareShownGossipDisplayText(GS_Gossip[QTR_QuestGreetingHash], GreetingText:GetWidth(), 13);
      QTR_SetQuestGreetingText(Greeting_AR, QTR_Font2, 13, "RIGHT");
      QTR_SetQuestGreetingHeaders(true);
      QTR_RestoreGossipButtons(QTR_QuestGreetingButtonsAR, QTR_Font2, 13);
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
         local Greeting_AR = QTR_PrepareShownGossipDisplayText(GS_Gossip[Hash], GreetingText:GetWidth(), 13);
         QTR_SetQuestGreetingText(Greeting_AR, QTR_Font2, 13, "RIGHT");
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
               QTR_SetTitleButtonText(questButton, translatedQuestButtonText, QTR_Font2, 13);
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
   if (curr_goss=="1") then         -- turn off translation - show original text
      curr_goss="0";
      QTR_SetGossipGreetingText(QTR_GS[curr_hash], Original_Font2, 13, "LEFT");
      QTR_RestoreGossipButtons(QTR_GossipButtonsEN, Original_Font2, 13);
      QTR_ToggleButtonGS:SetText("Gossip-Hash=["..tostring(curr_hash).."] EN");
   else                             -- show translation AR
      curr_goss="1";
      local Greeting_PL = GS_Gossip[curr_hash];
      local Greeting_AR = QTR_PrepareShownGossipDisplayText(Greeting_PL, GossipGreetingText:GetWidth(), 13);
      QTR_SetGossipGreetingText(Greeting_AR, QTR_Font2, 13, "RIGHT");
      QTR_RestoreGossipButtons(QTR_GossipButtonsAR, QTR_Font2, 13);
      QTR_ToggleButtonGS:SetText("Gossip-Hash=["..tostring(curr_hash).."] AR");
   end
end


-- Hash, look up, save, and apply gossip translations for the current NPC window.
function QTR_Gossip_Show()
   local Nazwa_NPC = GossipFrameNpcNameText:GetText();
   curr_hash = 0;
   QTR_GossipButtonsEN = {};
   QTR_GossipButtonsAR = {};
   if (Nazwa_NPC) then
      local Greeting_Text = GossipGreetingText:GetText();
      if (string.find(Greeting_Text," ")==nil) then         -- not Polish text (no non-breaking space)
         Nazwa_NPC = string.gsub(Nazwa_NPC, '"', '\"');
         Greeting_Text = string.gsub(Greeting_Text, '"', '\"');
         local Czysty_Text = QTR_NormalizeGossipHashText(Greeting_Text);
         local Hash = StringHash(Czysty_Text);
         curr_hash = Hash;
         QTR_GS[Hash] = Greeting_Text;                      -- save original text
         if ( GS_Gossip[Hash] ) then   -- translation of this NPC's GOSSIP text exists
            curr_goss = "1";
            local Greeting_PL = GS_Gossip[Hash];
            local Greeting_AR = QTR_PrepareShownGossipDisplayText(Greeting_PL, GossipGreetingText:GetWidth(), 13);
            QTR_SetGossipGreetingText(Greeting_AR, QTR_Font2, 13, "RIGHT");
            QTR_ToggleButtonGS:SetText("Gossip-Hash=["..tostring(Hash).."] AR");
            QTR_ToggleButtonGS:Enable();
         else                               -- no translation in GOSSIP database
            curr_goss = "0";
            -- save to file
            QTR_GOSSIP[Nazwa_NPC.."@"..tostring(Hash)] = Greeting_Text.."@"..QTR_name..":"..QTR_race..":"..QTR_class;
            QTR_ToggleButtonGS:SetText("Gossip-Hash=["..tostring(Hash).."] EN");
            QTR_ToggleButtonGS:Disable();
         end
         local numQuestButtons = GetNumGossipActiveQuests() + GetNumGossipAvailableQuests();
         local questButton;
         for i = 1, numQuestButtons, 1 do
            questButton = getglobal("GossipTitleButton"..tostring(i));
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
                  QTR_GossipButtonsEN[questButton] = questButton:GetText();
                  QTR_GossipButtonsAR[questButton] = translatedQuestButtonText;
                  QTR_SetTitleButtonText(questButton, translatedQuestButtonText, QTR_Font2, 13);
               end
            end
         end
         if (GetNumGossipOptions()>0) then    -- there are still additional function buttons in gossip, that can be translated
            local pozycja=numQuestButtons;
            local titleButton;
            for i = 1, GetNumGossipOptions(), 1 do 
               titleButton=getglobal("GossipTitleButton"..tostring(pozycja+i));
               if (titleButton:GetText()) then
                  local gostxt = titleButton:GetText();
                  if (string.find(gostxt, "|cff000000") == nil) then   -- not a quest in gossip
                     Hash = StringHash(gostxt);
                     if ( GS_Gossip[Hash] ) then   -- translation of additional text exists
                        local optionWidth = QTR_GetGossipOptionWidth(titleButton);
                        local Gossip_AR = QTR_PrepareGossipDisplayText(GS_Gossip[Hash], optionWidth, 13);
                        QTR_GossipButtonsEN[titleButton] = gostxt;
                        QTR_GossipButtonsAR[titleButton] = Gossip_AR;
                        QTR_SetTitleButtonText(titleButton, Gossip_AR, QTR_Font2, 13);
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
      if (not QTR_wait(0.1,Tut_TutorialShowDelayed)) then  -- delay 0.1 sec
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
      TutorialFrameTitle:SetText(Tut_tytul);
      local _font1, _size1, _1 = TutorialFrameTitle:GetFont();
      TutorialFrameTitle:SetFont(QTR_Font2, _size1);
      TutorialFrameText:SetText(Tut_tekst);
      local _font2, _size2, _2 = TutorialFrameText:GetFont();
      TutorialFrameText:SetFont(QTR_Font2, _size2);  
   end
   TutorialFrameOkayButton:SetText("Zamknij");
end


-- Expand quest placeholders for names, gender, class, and race tokens.
function QTR_ExpandUnitInfo(msg)
   msg = string.gsub(msg, "NEW_LINE", "\n");
   msg = string.gsub(msg, "YOUR_NAME0", AS_UTF8reverse(string.upper(QTR_name)));
   msg = string.gsub(msg, "YOUR_NAME1", AS_UTF8reverse(QTR_name));
   msg = string.gsub(msg, "YOUR_NAME2", AS_UTF8reverse(QTR_name));
   msg = string.gsub(msg, "YOUR_NAME3", AS_UTF8reverse(QTR_name));
   msg = string.gsub(msg, "YOUR_NAME4", AS_UTF8reverse(QTR_name));
   msg = string.gsub(msg, "YOUR_NAME5", AS_UTF8reverse(QTR_name));
   msg = string.gsub(msg, "YOUR_NAME6", AS_UTF8reverse(QTR_name));
   msg = string.gsub(msg, "YOUR_NAME7", AS_UTF8reverse(QTR_name));
   msg = string.gsub(msg, "YOUR_NAME", AS_UTF8reverse(QTR_name));
   
-- still handle YOUR_GENDER(x;y)
   local nr_1, nr_2, nr_3 = 0;
   local QTR_forma = "";
   local nr_poz = string.find(msg, "YOUR_GENDER");    -- when not found, it's: nil
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
               if (QTR_sex==3) then        -- feminine form
                  QTR_forma = string.sub(msg,nr_2+1,nr_3-1);
               else                        -- masculine form
                  QTR_forma = string.sub(msg,nr_1+1,nr_2-1);
               end
               msg = string.sub(msg,1,nr_poz-1) .. QTR_forma .. string.sub(msg,nr_3+1);
            end   
         end
      end
      nr_poz = string.find(msg, "YOUR_GENDER");
   end

-- still handle YOUR_GENDER(x;y)
   local nr_1, nr_2, nr_3 = 0;
   local QTR_forma = "";
   local nr_poz = string.find(msg, "YOUR_GENDER");    -- when not found, it's: nil
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
               if (QTR_sex==3) then        -- feminine form
                  QTR_forma = string.sub(msg,nr_2+1,nr_3-1);
               else                        -- masculine form
                  QTR_forma = string.sub(msg,nr_1+1,nr_2-1);
               end
               msg = string.sub(msg,1,nr_poz-1) .. QTR_forma .. string.sub(msg,nr_3+1);
            end   
         end
      end
      nr_poz = string.find(msg, "YOUR_GENDER");
   end

-- still handle NPC_GENDER(x;y)
   local nr_1, nr_2, nr_3 = 0;
   local QTR_forma = "";
   local NPC_sex = UnitSex("npc");     -- 1:neutral,  2:masculine,  3:feminine
   local nr_poz = string.find(msg, "NPC_GENDER");    -- when not found, it's: nil
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
               if (NPC_sex==3) then        -- feminine form
                  QTR_forma = string.sub(msg,nr_2+1,nr_3-1);
               else                        -- masculine form
                  QTR_forma = string.sub(msg,nr_1+1,nr_2-1);
               end
               msg = string.sub(msg,1,nr_poz-1) .. QTR_forma .. string.sub(msg,nr_3+1);
            end   
         end
      end
      nr_poz = string.find(msg, "NPC_GENDER");
   end

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

