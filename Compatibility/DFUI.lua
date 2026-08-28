-- Compatibility: DragonUI_NewEra (DFUI) world map quest panel.
--
-- DragonUI_NewEra rebuilds retail's Quest Log side-panel on top of the world map
-- (NE.questlogpanel) and SQUELCHES the client's own WorldMapQuestFrame list, so the
-- native ArWoW_Quests world-map hooks never see anything to translate. This file drives
-- the DragonUI panel instead, exactly the way the other Compatibility files drive Questie,
-- Immersion, etc: it hooks DragonUI's own render passes and reshapes the text they produce.
-- No DragonUI code is touched.
--
--   * Quest LIST rows (P.Refresh)      -> translate the quest title in place, keeping the
--                                         [level] prefix and (Complete) suffix DragonUI adds.
--   * Quest DETAIL pane (P._BuildDetail)-> hook SetText on the title / objectives / description
--                                         font strings. Reshaping inside SetText keeps the
--                                         pane's own height-measuring layout correct, because
--                                         DragonUI reads GetHeight() straight after SetText.

local QTR_DFUIHooked = false;
local QTR_DFUIDetailHooked = false;
-- Re-appliable reshapers for chrome whose text DragonUI sets only once (headers, footer buttons),
-- so a translation on/off toggle can restore or re-translate them without a DragonUI rebuild.
local QTR_DFUIChromeAppliers = {};
local QTR_DFUIToggleButton = nil;
-- World-map-only translation switch, kept separate from the global QTR_PS["active"] so toggling it
-- never disables translation in the other frames (during this session or after a reload).
local QTR_DFUIWorldMapOff = false;
-- Non-empty while the search box holds an Arabic query DragonUI's English filter can't match.
local QTR_DFUISearchQuery = nil;

-- This 3.3.5 client delivers Arabic keystrokes as Windows-1252 bytes (stored UTF-8-encoded),
-- not real Arabic, so an edit box shows "ÓÖÕ..." and AS_ContainsArabic never fires. The same map
-- ArWoW_Chat uses turns each mojibake code unit back into its Arabic UTF-8 letter.
local QTR_ARABIC_MOJIBAKE_MAP = {
   ["\194\129"]="\217\190", ["\194\138"]="\217\185", ["\194\141"]="\218\134", ["\194\142"]="\218\152", ["\194\143"]="\218\136", ["\194\144"]="\218\175",
   ["\194\152"]="\218\169", ["\194\154"]="\218\145", ["\194\159"]="\218\186", ["\194\161"]="\216\140", ["\194\170"]="\218\190", ["\194\186"]="\216\155",
   ["\194\191"]="\216\159", ["\195\128"]="\219\129", ["\195\129"]="\216\161", ["\195\130"]="\216\162", ["\195\131"]="\216\163", ["\195\132"]="\216\164",
   ["\195\133"]="\216\165", ["\195\134"]="\216\166", ["\195\135"]="\216\167", ["\195\136"]="\216\168", ["\195\137"]="\216\169", ["\195\138"]="\216\170",
   ["\195\139"]="\216\171", ["\195\140"]="\216\172", ["\195\141"]="\216\173", ["\195\142"]="\216\174", ["\195\143"]="\216\175", ["\195\144"]="\216\176",
   ["\195\145"]="\216\177", ["\195\146"]="\216\178", ["\195\147"]="\216\179", ["\195\148"]="\216\180", ["\195\149"]="\216\181", ["\195\150"]="\216\182",
   ["\195\152"]="\216\183", ["\195\153"]="\216\184", ["\195\154"]="\216\185", ["\195\155"]="\216\186", ["\195\156"]="\217\128", ["\195\157"]="\217\129",
   ["\195\158"]="\217\130", ["\195\159"]="\217\131", ["\195\161"]="\217\132", ["\195\163"]="\217\133", ["\195\164"]="\217\134", ["\195\165"]="\217\135",
   ["\195\166"]="\217\136", ["\195\172"]="\217\137", ["\195\173"]="\217\138", ["\195\176"]="\217\139", ["\195\177"]="\217\140", ["\195\178"]="\217\141",
   ["\195\179"]="\217\142", ["\195\181"]="\217\143", ["\195\182"]="\217\144", ["\195\184"]="\217\145", ["\195\186"]="\217\146", ["\195\191"]="\219\146",
};


-- Map a run of Windows-1252 keystrokes to their Arabic UTF-8 letters; leaves real text untouched.
local function QTR_DecodeArabicInput(text)
   if (not text or text == "") then
      return text or "";
   end
   local out, pos, bytes = {}, 1, string.len(text);
   while (pos <= bytes) do
      local ok, charbytes = pcall(AS_UTF8charbytes, text, pos);
      if (not ok or not charbytes or charbytes < 1) then
         charbytes = 1;
      end
      local char = string.sub(text, pos, pos + charbytes - 1);
      out[#out + 1] = QTR_ARABIC_MOJIBAKE_MAP[char] or char;
      pos = pos + charbytes;
   end
   return table.concat(out);
end


-- The DragonUI quest-log panel table, or nil when the addon is absent/disabled.
local function QTR_GetDFUIPanel()
   local NE = _G.DragonUI_NewEra;
   if (type(NE) ~= "table" or NE.disabled) then
      return nil;
   end
   local panel = NE.questlogpanel;
   if (type(panel) ~= "table") then
      return nil;
   end
   return panel;
end


-- Translated body text (Objectives / Description) for a quest id, or nil when unavailable.
local function QTR_GetDFUIQuestBody(questId, fieldName)
   if (not questId or not QTR_PS or QTR_PS["active"] ~= "1") then
      return nil;
   end
   local idStr = tostring(questId);
   local questData = QTR_QuestData and QTR_QuestData[idStr];
   if (questData and questData[fieldName]) then
      return QTR_ExpandUnitInfo(questData[fieldName]);
   end
   return nil;
end


-- Escape Lua pattern magic characters so a client label can be matched literally.
local function QTR_EscapeDFUIPattern(text)
   return (string.gsub(text or "", "(%W)", "%%%1"));
end


-- Replace DragonUI's English "(Complete)" / "(Failed)" status suffix with reshaped Arabic.
local function QTR_TranslateDFUIStatusSuffix(text, fontName, fontSize)
   if (not text or text == "" or not QTR_PS or QTR_PS["active"] ~= "1") then
      return text;
   end
   local complete = _G.QUEST_COMPLETE;
   if (complete and complete ~= "") then
      local arabic = QTR_PrepareWrappedArabicText("مكتملة", nil, fontName, fontSize);
      text = string.gsub(text, "%(" .. QTR_EscapeDFUIPattern(complete) .. "%)", "(" .. arabic .. ")");
   end
   local failed = _G.FAILED;
   if (failed and failed ~= "") then
      local arabic = QTR_PrepareWrappedArabicText("فشلت", nil, fontName, fontSize);
      text = string.gsub(text, "%(" .. QTR_EscapeDFUIPattern(failed) .. "%)", "(" .. arabic .. ")");
   end
   return text;
end


-- Reshape one detail-pane font string when its text is (re)set by DragonUI.
--   kind: "title" -> QTR_PS.transtitle gated; "Objectives"/"Description" -> QTR_PS.active gated.
local function QTR_ApplyDFUIDetailField(fontString, kind, originalText)
   local panel = QTR_GetDFUIPanel();
   if (not panel) then
      return;
   end

   local questId = panel.selectedIndex and panel.QuestIDAt and panel.QuestIDAt(panel.selectedIndex);
   local translatedText = nil;
   if (not QTR_DFUIWorldMapOff) then
      if (kind == "title") then
         if (questId and QTR_PS and QTR_PS["active"] == "1" and QTR_PS["transtitle"] == "1") then
            translatedText = QTR_GetTranslatedQuestTitleById(tostring(questId));
         end
      else
         translatedText = QTR_GetDFUIQuestBody(questId, kind);
      end
   end

   local origFont = fontString.qtrDFUIOrigFont;
   local fontSize = (origFont and origFont[2]) or 13;

   fontString.qtrDFUIBusy = true;
   if (translatedText and translatedText ~= "") then
      -- Wrap a few pixels short of the real width: the reshaper builds lines up to this width,
      -- and this margin keeps rounding from tipping a full line over so DragonUI's own word-wrap
      -- never re-breaks it (which would drop the visually-first word onto a second row).
      local wrapWidth = fontString:GetWidth();
      if (wrapWidth and wrapWidth > 24) then
         wrapWidth = wrapWidth - 16;
      end
      QTR_SetShapedTitleText(fontString, translatedText, QTR_Font1 or QTR_Font2, fontSize, wrapWidth);
   elseif (origFont) then
      fontString:SetFont(origFont[1], origFont[2], origFont[3]);
      fontString:SetJustifyH("LEFT");
      fontString:SetText(originalText or "");
   end
   fontString.qtrDFUIBusy = false;
end


local function QTR_HookDFUIDetailField(fontString, kind)
   if (not fontString or fontString.qtrDFUIFieldHooked) then
      return;
   end
   fontString.qtrDFUIFieldHooked = true;
   fontString.qtrDFUIOrigFont = { fontString:GetFont() };

   hooksecurefunc(fontString, "SetText", function(self, text)
      if (self.qtrDFUIBusy) then
         return;
      end
      QTR_ApplyDFUIDetailField(self, kind, text);
   end);
end


-- Reshape a fixed section label (Objectives / Description / reward headers) into Arabic.
local function QTR_ApplyDFUIHeader(fontString)
   if (fontString.qtrDFUIBusy) then
      return;
   end
   local origFont = fontString.qtrDFUIOrigFont;
   local fontSize = (origFont and origFont[2]) or 13;
   fontString.qtrDFUIBusy = true;
   if (not QTR_DFUIWorldMapOff and QTR_PS and QTR_PS["active"] == "1" and fontString.qtrDFUIHeaderAR and fontString.qtrDFUIHeaderAR ~= "") then
      QTR_SetShapedTitleText(fontString, fontString.qtrDFUIHeaderAR, QTR_Font1 or QTR_Font2, fontSize, fontString:GetWidth());
   elseif (origFont) then
      fontString:SetFont(origFont[1], origFont[2], origFont[3]);
      fontString:SetJustifyH("LEFT");
      fontString:SetText(fontString.qtrDFUIHeaderEN or fontString:GetText() or "");
   end
   fontString.qtrDFUIBusy = false;
end


local function QTR_HookDFUIHeader(fontString, arabicText)
   if (not fontString or fontString.qtrDFUIHeaderHooked) then
      return;
   end
   fontString.qtrDFUIHeaderHooked = true;
   fontString.qtrDFUIOrigFont = { fontString:GetFont() };
   fontString.qtrDFUIHeaderAR = arabicText;
   fontString.qtrDFUIHeaderEN = fontString:GetText();

   hooksecurefunc(fontString, "SetText", function(self, text)
      if (self.qtrDFUIBusy) then
         return;
      end
      self.qtrDFUIHeaderEN = text;
      QTR_ApplyDFUIHeader(self);
   end);

   QTR_DFUIChromeAppliers[#QTR_DFUIChromeAppliers + 1] = function() QTR_ApplyDFUIHeader(fontString) end;

   -- Objectives/Description headers are set once at build time, before this hook exists.
   QTR_ApplyDFUIHeader(fontString);
end


-- Map DragonUI's footer/back button labels to Arabic (handles the Track<->Untrack swap).
local function QTR_TranslateDFUIButtonText(text)
   if (not text or text == "") then
      return nil;
   end
   local back = _G.BACK or "Back";
   if (text == back or text == ("< " .. back)) then
      return "< رجوع";
   elseif (text == (_G.TRACK_QUEST_ABBREV or "Track")) then
      return (QTR_Messages and QTR_Messages.track) or "تتبع";
   elseif (text == (_G.UNTRACK_QUEST_ABBREV or "Untrack")) then
      return "إلغاء التتبع";
   elseif (text == (_G.ABANDON_QUEST_ABBREV or "Abandon")) then
      return (QTR_Messages and QTR_Messages.abandon) or "حذف";
   elseif (text == (_G.SHARE_QUEST_ABBREV or "Share")) then
      return (QTR_Messages and QTR_Messages.share) or "مشاركة";
   end
   return nil;
end


local function QTR_ApplyDFUIButton(button)
   if (button.qtrDFUIBusy) then
      return;
   end
   local label = button.GetFontString and button:GetFontString();
   if (not label) then
      return;
   end
   local origFont = button.qtrDFUIOrigFont;
   local fontSize = (origFont and origFont[2]) or 12;
   local arabic = nil;
   if (not QTR_DFUIWorldMapOff and QTR_PS and QTR_PS["active"] == "1") then
      arabic = QTR_TranslateDFUIButtonText(button.qtrDFUITextEN);
   end
   button.qtrDFUIBusy = true;
   if (arabic and arabic ~= "") then
      label:SetFont(QTR_Font1 or QTR_Font2, fontSize);
      button:SetText(QTR_PrepareWrappedArabicText(arabic, nil, QTR_Font1 or QTR_Font2, fontSize));
   elseif (origFont) then
      label:SetFont(origFont[1], origFont[2], origFont[3]);
      button:SetText(button.qtrDFUITextEN or "");
   end
   button.qtrDFUIBusy = false;
end


local function QTR_HookDFUIButton(button)
   if (not button or button.qtrDFUIButtonHooked or type(button.SetText) ~= "function") then
      return;
   end
   button.qtrDFUIButtonHooked = true;
   local label = button.GetFontString and button:GetFontString();
   button.qtrDFUIOrigFont = label and { label:GetFont() } or nil;
   button.qtrDFUITextEN = button.GetText and button:GetText() or nil;

   hooksecurefunc(button, "SetText", function(self, text)
      if (self.qtrDFUIBusy) then
         return;
      end
      self.qtrDFUITextEN = text;
      QTR_ApplyDFUIButton(self);
   end);

   QTR_DFUIChromeAppliers[#QTR_DFUIChromeAppliers + 1] = function() QTR_ApplyDFUIButton(button) end;
   QTR_ApplyDFUIButton(button);
end


local function QTR_RefreshDFUIChrome()
   for _, apply in ipairs(QTR_DFUIChromeAppliers) do
      apply();
   end
end


local function QTR_UpdateDFUIToggleButton()
   local button = QTR_DFUIToggleButton;
   if (not button) then
      return;
   end
   local active = not QTR_DFUIWorldMapOff;
   local label = button.GetFontString and button:GetFontString();
   -- Off -> offer to turn translation off; inactive -> offer to translate.
   local text = active and "AR OFF" or "ترجمة";
   if (AS_ContainsArabic and AS_ContainsArabic(text)) then
      local fontSize = 12;
      if (label and label.GetFont) then
         local _, s = label:GetFont();
         fontSize = s or 12;
         label:SetFont(QTR_Font1 or QTR_Font2, fontSize);
      end
      button:SetText(QTR_PrepareWrappedArabicText(text, nil, QTR_Font1 or QTR_Font2, fontSize));
   else
      if (label and button.qtrDFUIOrigFont) then
         label:SetFont(button.qtrDFUIOrigFont[1], button.qtrDFUIOrigFont[2], button.qtrDFUIOrigFont[3]);
      end
      button:SetText(text);
   end
end


local function QTR_EnsureDFUIToggleButton(panel)
   if (QTR_DFUIToggleButton or not panel or not panel.frame) then
      return;
   end
   local button = CreateFrame("Button", "QTR_DFUIToggleButton", panel.frame, "UIPanelButtonTemplate");
   button:SetSize(80, 22);
   -- Sits left of the panel, over the map's top edge, so it never fights the search box or cog.
   button:SetPoint("TOPRIGHT", panel.frame, "TOPLEFT", -40, -2);
   button:SetFrameLevel((panel.frame:GetFrameLevel() or 1) + 5);
   local toggleLabel = button.GetFontString and button:GetFontString();
   button.qtrDFUIOrigFont = toggleLabel and { toggleLabel:GetFont() } or nil;
   button:SetScript("OnClick", function()
      QTR_DFUIWorldMapOff = not QTR_DFUIWorldMapOff;
      QTR_UpdateDFUIToggleButton();
      QTR_RefreshDFUIChrome();
      QTR_RefreshDFUIWorldMap();
   end);
   QTR_DFUIToggleButton = button;
   QTR_UpdateDFUIToggleButton();
end


local function QTR_HookDFUIDetail(detailFrame)
   if (not detailFrame or QTR_DFUIDetailHooked) then
      return;
   end
   QTR_DFUIDetailHooked = true;
   QTR_HookDFUIDetailField(detailFrame.title, "title");
   QTR_HookDFUIDetailField(detailFrame.objText, "Objectives");
   QTR_HookDFUIDetailField(detailFrame.descText, "Description");
   QTR_HookDFUIHeader(detailFrame.objHeader, (QTR_Messages and QTR_Messages.objectives) or "المهام");
   QTR_HookDFUIHeader(detailFrame.descHeader, (QTR_Messages and QTR_Messages.details) or "التفاصيل");
   QTR_HookDFUIHeader(detailFrame.rewardHeader, (QTR_Messages and QTR_Messages.rewards) or "المكافأة");
   QTR_HookDFUIHeader(detailFrame.choiceHeader, "اختر مكافأتك:");
   QTR_HookDFUIButton(detailFrame.back);
   QTR_HookDFUIButton(detailFrame.trackBtn);
   QTR_HookDFUIButton(detailFrame.abandonBtn);
   QTR_HookDFUIButton(detailFrame.shareBtn);
end


-- Filter the (already fully shown) list to quests whose Arabic title contains the query, keeping
-- each surviving quest's zone header, then re-stack the survivors so there are no gaps.
local function QTR_ApplyDFUIArabicSearch(panel, query)
   local content = panel.frame and panel.frame.content;
   if (not content) then
      return;
   end

   local rows = {};
   for _, row in ipairs({ content:GetChildren() }) do
      if (row and row.IsShown and row:IsShown() and row.GetHeight) then
         rows[#rows + 1] = row;
      end
   end
   -- Visual (top-to-bottom) order, so a header keeps the quests that follow it.
   table.sort(rows, function(a, b)
      return ((a.GetTop and a:GetTop()) or 0) > ((b.GetTop and b:GetTop()) or 0);
   end);

   local keep = {};
   local lastHeader = nil;
   for i = 1, #rows do
      local row = rows[i];
      local questId = (row._index and panel.QuestIDAt) and panel.QuestIDAt(row._index) or nil;
      if (questId) then
         local title = QTR_GetTranslatedQuestTitleById(tostring(questId)) or "";
         keep[i] = (title ~= "" and string.find(title, query, 1, true)) and true or false;
         if (keep[i] and lastHeader) then
            keep[lastHeader] = true;
         end
      elseif (row._index) then
         lastHeader = i;
         keep[i] = false;
      else
         keep[i] = false;
      end
   end

   local y = 0;
   for i = 1, #rows do
      local row = rows[i];
      if (keep[i]) then
         row:ClearAllPoints();
         row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y);
         row:Show();
         y = y + (row:GetHeight() or 0);
      else
         row:Hide();
      end
   end
   content:SetHeight(math.max(y, 1));
end


-- Draw the typed Arabic as shaped right-to-left text. The real edit box keeps the logical-order
-- text (for correct input + matching) but is hidden (alpha 0) whenever the overlay is showing.
local function QTR_UpdateDFUISearchPreview(search, text)
   local preview = search.qtrDFUIPreview;
   if (not preview) then
      return;
   end
   local fontSize = 14;
   if (search.GetFont) then
      local _, s = search:GetFont();
      fontSize = s or 14;
   end
   if (text and text ~= "" and AS_ContainsArabic and AS_ContainsArabic(text)) then
      -- No wrap width: a single shaped line. Passing a width made the reshaper break short text
      -- across lines the one-line box can't hold, which rendered as "...".
      preview:SetFont(QTR_Font1 or QTR_Font2, fontSize);
      preview:SetText(QTR_PrepareWrappedArabicText(text, nil, QTR_Font1 or QTR_Font2, fontSize));
      preview:Show();
      search:SetTextColor(1, 1, 1, 0);
   else
      preview:Hide();
      search:SetTextColor(1, 1, 1, 1);
   end
end


local function QTR_EnsureDFUISearch(panel)
   local search = panel.frame and panel.frame.search;
   if (not search or search.qtrDFUISearchHooked) then
      return;
   end
   search.qtrDFUISearchHooked = true;

   local fontSize = 14;
   -- The client's default input font has no Arabic glyphs, so typed Arabic would be invisible.
   if (search.SetFont) then
      local _, size = search:GetFont();
      fontSize = size or 14;
      search:SetFont(QTR_Font1 or QTR_Font2, fontSize);
   end

   local overlay = CreateFrame("Frame", nil, search);
   overlay:SetPoint("TOPLEFT", search, "TOPLEFT", 6, 0);
   overlay:SetPoint("BOTTOMRIGHT", search, "BOTTOMRIGHT", -6, 0);
   overlay:SetFrameLevel((search:GetFrameLevel() or 1) + 5);
   local preview = overlay:CreateFontString(nil, "OVERLAY");
   preview:SetAllPoints(overlay);
   preview:SetFont(QTR_Font1 or QTR_Font2, fontSize);
   preview:SetJustifyH("RIGHT");
   preview:SetJustifyV("MIDDLE");
   preview:Hide();
   search.qtrDFUIPreview = preview;

   -- Hidden string used only to measure the shaped prefix width, so the fake caret can sit exactly
   -- where the next letter will land (the real caret is invisible while the real text is transparent).
   local measure = overlay:CreateFontString(nil, "ARTWORK");
   measure:Hide();
   measure:SetWidth(4096);
   measure:SetFont(QTR_Font1 or QTR_Font2, fontSize);
   search.qtrDFUIMeasure = measure;

   local caret = overlay:CreateTexture(nil, "OVERLAY");
   caret:SetTexture("Interface\\Buttons\\WHITE8X8");
   caret:SetWidth(1);
   caret:SetHeight(fontSize + 2);
   caret:Hide();
   search.qtrDFUICaret = caret;

   overlay:SetScript("OnUpdate", function(self, elapsed)
      local previewFS, caretTex, measureFS = search.qtrDFUIPreview, search.qtrDFUICaret, search.qtrDFUIMeasure;
      if (not caretTex or not previewFS or not previewFS:IsShown() or not (search.HasFocus and search:HasFocus())) then
         if (caretTex) then caretTex:Hide(); end
         self.qtrBlink, self.qtrLastPos = 0, nil;
         return;
      end

      -- GetCursorPosition returns a number (no garbage); only fetch the text when the caret moves.
      local pos = (search.GetCursorPosition and search:GetCursorPosition()) or 0;
      if (pos ~= self.qtrLastPos) then
         self.qtrLastPos = pos;
         local prefix = string.sub(search:GetText() or "", 1, pos);
         -- Drop a dangling partial UTF-8 char (a cursor can land mid-character) to avoid a crash.
         for bIndex = string.len(prefix), math.max(1, string.len(prefix) - 3), -1 do
            local b = string.byte(prefix, bIndex);
            if (b and b >= 192 and b <= 247) then
               local expected = (b >= 240 and 4) or (b >= 224 and 3) or 2;
               if ((string.len(prefix) - bIndex + 1) < expected) then
                  prefix = string.sub(prefix, 1, bIndex - 1);
               end
               break;
            elseif (b and b < 128) then
               break;
            end
         end
         local offset = 0;
         if (measureFS) then
            measureFS:SetText(QTR_PrepareWrappedArabicText(prefix, nil, QTR_Font1 or QTR_Font2, fontSize));
            offset = measureFS:GetStringWidth() or 0;
         end
         caretTex:ClearAllPoints();
         caretTex:SetPoint("RIGHT", previewFS, "RIGHT", -offset, 0);
      end

      self.qtrBlink = (self.qtrBlink or 0) + elapsed;
      if (self.qtrBlink > 0.5) then
         self.qtrBlink = 0;
         if (caretTex:IsShown()) then caretTex:Hide(); else caretTex:Show(); end
      end
   end);

   search:HookScript("OnTextChanged", function(self)
      if (self.qtrDFUINormalizing) then
         return;
      end
      -- Turn the client's Windows-1252 keystrokes into real Arabic and write it back, so the box
      -- shows Arabic letters and the query can be matched against the Arabic titles.
      local rawText = self:GetText() or "";
      local decoded = QTR_DecodeArabicInput(rawText);
      if (decoded ~= rawText) then
         self.qtrDFUINormalizing = true;
         self:SetText(decoded);
         if (self.SetCursorPosition) then
            self:SetCursorPosition(string.len(decoded));
         end
         self.qtrDFUINormalizing = false;
      end

      QTR_UpdateDFUISearchPreview(self, decoded);

      if (AS_ContainsArabic and AS_ContainsArabic(decoded)) then
         -- DragonUI's own filter matches English titles only; take over with the Arabic query.
         QTR_DFUISearchQuery = decoded;
         panel.filter = nil;
         if (panel.Refresh) then panel.Refresh(); end
      elseif (QTR_DFUISearchQuery) then
         QTR_DFUISearchQuery = nil;
         if (panel.Refresh) then panel.Refresh(); end
      end
   end);
end


-- Reshape every visible quest-title row after DragonUI rebuilds the list.
local function QTR_UpdateDFUIQuestList()
   local panel = QTR_GetDFUIPanel();
   if (not panel or not panel.frame or not panel.frame:IsShown() or not panel.frame.content) then
      return;
   end
   QTR_EnsureDFUIToggleButton(panel);
   QTR_EnsureDFUISearch(panel);
   if (panel.detailShown) then
      return;
   end

   for _, row in ipairs({ panel.frame.content:GetChildren() }) do
      local label = row.text;
      if (label and row:IsShown() and row._index) then
         if (not label.qtrDFUIOrigFont) then
            label.qtrDFUIOrigFont = { label:GetFont() };
         end

         local questId = panel.QuestIDAt and panel.QuestIDAt(row._index);
         local displayText = label:GetText() or "";
         local fontSize = (label.qtrDFUIOrigFont and label.qtrDFUIOrigFont[2]) or 13;

         -- Compare cache fields directly (no key string) so a cache hit allocates nothing.
         local width = math.floor((label:GetWidth() or 0) + 0.5);
         local active = (QTR_PS and QTR_PS["active"]) or "0";
         local transtitle = (QTR_PS and QTR_PS["transtitle"]) or "0";

         local translatedText;
         if (label.qtrCQuest == questId and label.qtrCDisplay == displayText and label.qtrCWidth == width
             and label.qtrCActive == active and label.qtrCTrans == transtitle and label.qtrCOff == QTR_DFUIWorldMapOff) then
            translatedText = label.qtrCResult;
         else
            if (questId and not QTR_DFUIWorldMapOff) then
               local originalTitle = select(1, GetQuestLogTitle(row._index));
               translatedText = QTR_PrepareExternalQuestTitleDisplay(questId, displayText, originalTitle,
                  label:GetWidth(), QTR_Font1 or QTR_Font2, fontSize, QTR_Font2);
            end
            if (translatedText and translatedText ~= "") then
               translatedText = QTR_TranslateDFUIStatusSuffix(translatedText, QTR_Font1 or QTR_Font2, fontSize);
            else
               translatedText = false;
            end
            label.qtrCQuest, label.qtrCDisplay, label.qtrCWidth = questId, displayText, width;
            label.qtrCActive, label.qtrCTrans, label.qtrCOff = active, transtitle, QTR_DFUIWorldMapOff;
            label.qtrCResult = translatedText;
         end

         if (translatedText and translatedText ~= "") then
            label:SetFont(QTR_Font1 or QTR_Font2, fontSize);
            if (AS_ContainsArabic and AS_ContainsArabic(translatedText)) then
               label:SetJustifyH("RIGHT");
            else
               label:SetJustifyH("LEFT");
            end
            label:SetText(translatedText);
         elseif (label.qtrDFUIOrigFont) then
            label:SetFont(label.qtrDFUIOrigFont[1], label.qtrDFUIOrigFont[2], label.qtrDFUIOrigFont[3]);
            label:SetJustifyH("LEFT");
         end
      end
   end

   if (QTR_DFUISearchQuery and QTR_DFUISearchQuery ~= "") then
      QTR_ApplyDFUIArabicSearch(panel, QTR_DFUISearchQuery);
   end
end


function QTR_TryHookDFUI()
   if (QTR_DFUIHooked) then
      -- Detail pane may be built after the first hook pass; pick it up when it appears.
      local panel = QTR_GetDFUIPanel();
      if (panel and panel.detail) then
         QTR_HookDFUIDetail(panel.detail);
      end
      return true;
   end

   local panel = QTR_GetDFUIPanel();
   if (not panel or type(panel.Refresh) ~= "function") then
      return false;
   end

   QTR_DFUIHooked = true;

   hooksecurefunc(panel, "Refresh", QTR_UpdateDFUIQuestList);

   if (type(panel._BuildDetail) == "function") then
      hooksecurefunc(panel, "_BuildDetail", function(hostFrame)
         if (hostFrame and hostFrame._neDetail) then
            QTR_HookDFUIDetail(hostFrame._neDetail);
         end
      end);
   end

   -- The panel may already exist if the map was opened before ArWoW_Quests finished loading.
   if (panel.detail) then
      QTR_HookDFUIDetail(panel.detail);
   end

   return true;
end


function QTR_RefreshDFUIWorldMap()
   local panel = QTR_GetDFUIPanel();
   if (not panel or not panel.frame or not panel.frame:IsShown()) then
      return;
   end
   QTR_UpdateDFUIToggleButton();
   QTR_RefreshDFUIChrome();
   if (panel.detailShown) then
      if (type(panel.RefreshDetail) == "function") then
         panel.RefreshDetail();
      end
   elseif (type(panel.Refresh) == "function") then
      panel.Refresh();
   end
end
