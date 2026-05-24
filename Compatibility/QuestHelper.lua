local QTR_QuestHelperTrackerHooked = false;
local QTR_QuestHelperTrackerRelayouting = false;
local QTR_QuestHelperTrackerTextState = setmetatable({}, { __mode = "k" });
local QTR_QuestHelperTrackerFontState = setmetatable({}, { __mode = "k" });
local QTR_QuestHelperTooltipHooked = false;
local QTR_QuestHelperTooltipFontState = setmetatable({}, { __mode = "k" });
local QTR_QuestHelperWaypointHooked = false;
local QTR_QuestHelperArrowFontState = setmetatable({}, { __mode = "k" });
local QTR_QuestHelperAcquireText = "احصل على";
local QTR_QuestHelperSlayText = "اقتل";
local QTR_QuestHelperOpenText = "افتح";
local QTR_QuestHelperTalkToText = "تحدث إلى";
local QTR_QuestHelperForQuestText = "للمهمة";
local QTR_QuestHelperTurnInQuestText = "سلم المهمة";
local QTR_QuestHelperQuestLabelText = "المهمة";
local QTR_QuestHelperTravelEstimateText = "الوقت المقدر للسفر";
local QTR_QuestHelperDisplayFontSize = 14;


local function QTR_GetQuestHelperTrackerFrame()
  if (type(QuestHelper) == "table" and QuestHelper.tracker) then
     return QuestHelper.tracker;
  end

  if (_G) then
     return _G["QuestHelperQuestWatchFrame"];
  end

  return nil;
end


local function QTR_GetQuestHelperTooltipFrame()
  if (type(QuestHelper) == "table" and QuestHelper.tooltip) then
     return QuestHelper.tooltip;
  end

  if (_G) then
     return _G["QuestHelperTooltip"];
  end

  return nil;
end


local function QTR_GetQuestHelperTooltipLineWidth(fontString, tooltip)
  local lineWidth = (fontString and fontString.GetWidth and fontString:GetWidth()) or 0;
  if (lineWidth and lineWidth > 40) then
     return lineWidth;
  end

  local tooltipWidth = (tooltip and tooltip.GetWidth and tooltip:GetWidth()) or 0;
  if (tooltipWidth and tooltipWidth > 60) then
     return tooltipWidth - 30;
  end

  return 260;
end


local function QTR_GetQuestHelperTooltipFontString(tooltip, lineIndex)
  local tooltipName = tooltip and tooltip.GetName and tooltip:GetName() or nil;
  if (not tooltipName or tooltipName == "") then
     return nil;
  end

  return _G[tooltipName .. "TextLeft" .. lineIndex];
end


local function QTR_GetQuestHelperTooltipPlainText(text)
  local plainText = text or "";
  plainText = string.gsub(plainText, "|T.-|t", "");
  plainText = string.gsub(plainText, "|c%x%x%x%x%x%x%x%x", "");
  plainText = string.gsub(plainText, "|r", "");
  return plainText;
end


local function QTR_QuestHelperReverseUTF8Text(text)
  if (not text or text == "") then
     return text or "";
  end

  if (AS_UTF8reverse) then
     return AS_UTF8reverse(text);
  end

  return string.reverse(text);
end


local function QTR_QuestHelperNormalizeMixedLatinTokens(text)
  if (not text or text == "") then
     return text or "";
  end

  if (not string.find(text, "[A-Za-z]")) then
     return text;
  end

  return string.gsub(text, "[A-Za-z][A-Za-z'%-]*", function(token)
     return QTR_QuestHelperReverseUTF8Text(token);
  end);
end


local function QTR_GetQuestHelperArrowTitleLabel()
  return (QHArrowFrame and QHArrowFrame.title) or nil;
end


local function QTR_ParseQuestHelperWaypointDescription(desc)
  if (type(desc) ~= "string" or desc == "") then
     return nil, nil, nil;
  end

  local plainText = QTR_GetQuestHelperTooltipPlainText(desc);
  if (plainText == "") then
     return nil, nil, nil;
  end

  local originalTitle, questId = string.match(plainText, "^(.-)%s*%[quest #(%d+)%]%s*$");
  if (not originalTitle or originalTitle == "") then
     originalTitle, questId = string.match(plainText, "^(.-)%s*%(%s*quest #(%d+)%s*%)%s*$");
  end

  if (not originalTitle or originalTitle == "" or not questId or questId == "") then
     return nil, nil, nil;
  end

  return plainText, originalTitle, questId;
end


local function QTR_GetQuestHelperWaypointTranslatedDescription(desc, width, fontName, fontSize, measureFontName)
  if (not QTR_PS or QTR_PS["active"] ~= "1" or QTR_PS["transtitle"] ~= "1") then
     return nil;
  end

  local plainText, originalTitle, questId = QTR_ParseQuestHelperWaypointDescription(desc);
  if (not plainText or not originalTitle or not questId) then
     return nil;
  end

  if (QTR_PrepareExternalQuestTitleDisplay) then
     local translatedDisplayText = QTR_PrepareExternalQuestTitleDisplay(questId, plainText, originalTitle, width, fontName, fontSize, measureFontName, false);
     if (translatedDisplayText and translatedDisplayText ~= "" and translatedDisplayText ~= plainText) then
        return translatedDisplayText;
     end
  end

  local translatedTitle = QTR_GetTranslatedQuestTitleById(questId) or QTR_GetQuestTitleTranslation(originalTitle);
  if (not translatedTitle or translatedTitle == "" or translatedTitle == originalTitle) then
     return nil;
  end

  local titleStart, titleEnd = string.find(plainText, originalTitle, 1, true);
  if (titleStart and titleEnd) then
     return string.sub(plainText, 1, titleStart - 1) .. translatedTitle .. string.sub(plainText, titleEnd + 1);
  end

  return translatedTitle;
end


local function QTR_PatchQuestHelperArrowTitleLabel()
  local fontString = QTR_GetQuestHelperArrowTitleLabel();
  if (not fontString or fontString.qtrQuestHelperArrowPatched) then
     return false;
  end

  local arrowFrame = QHArrowFrame;
  local originalSetText = fontString.SetText;
  local originalSetFont = fontString.SetFont;
  if (type(originalSetText) ~= "function" or type(originalSetFont) ~= "function") then
     return false;
  end

  fontString.SetText = function(self, text)
     local state = self.qtrQuestHelperArrowState;
     if (not state) then
        state = {};
        self.qtrQuestHelperArrowState = state;
     end

     if (state.lock) then
        return originalSetText(self, text);
     end

     local fontState = QTR_GetExternalFontState(self, QTR_QuestHelperArrowFontState) or {};
     local arabicFont = QTR_Font2 or QTR_Font1 or fontState.font or Original_Font2;
     local width = (self.GetWidth and self:GetWidth()) or (arrowFrame and arrowFrame.GetWidth and arrowFrame:GetWidth()) or 240;
     local displayText = QTR_GetQuestHelperWaypointTranslatedDescription(text, width, arabicFont, QTR_QuestHelperDisplayFontSize, fontState.font or arabicFont) or text;
     if (displayText and displayText ~= "" and AS_ContainsArabic and AS_ContainsArabic(displayText)) then
        state.lock = true;
        originalSetFont(self, arabicFont, QTR_QuestHelperDisplayFontSize, fontState.flags);
        if (self.SetJustifyH) then
           self:SetJustifyH("LEFT");
        end
        local result = originalSetText(self, displayText);
        state.lock = false;
        return result;
     end

     QTR_RestoreExternalFontState(self, QTR_QuestHelperArrowFontState);
     return originalSetText(self, displayText);
  end;

  fontString.qtrQuestHelperArrowPatched = true;
  return true;
end


local function QTR_TryHookQuestHelperWaypoints()
  if (type(QuestHelper) ~= "table") then
     return false;
  end

  local patchedArrow = QTR_PatchQuestHelperArrowTitleLabel();
  local tooltip = QTR_GetQuestHelperTooltipFrame();

  if (not QTR_QuestHelperWaypointHooked and tooltip and type(tooltip.AddLine) == "function") then
     local originalTooltipAddLine = tooltip.AddLine;
     tooltip.AddLine = function(self, text, ...)
        local result = originalTooltipAddLine(self, text, ...);
        local lineIndex = (self and self.NumLines and self:NumLines()) or 0;
        local fontString = QTR_GetQuestHelperTooltipFontString(self, lineIndex);
        if (fontString and lineIndex > 0 and text and text ~= "") then
           local fontState = QTR_GetExternalFontState(fontString, QTR_QuestHelperTooltipFontState) or {};
           local arabicFont = QTR_Font2 or QTR_Font1 or fontState.font or Original_Font2;
           local fontSize = QTR_QuestHelperDisplayFontSize;
           local lineWidth = QTR_GetQuestHelperTooltipLineWidth(fontString, self);
           local translatedText = QTR_GetQuestHelperWaypointTranslatedDescription(text, lineWidth, arabicFont, fontSize, fontState.font or arabicFont);

           if (translatedText and translatedText ~= "" and translatedText ~= text) then
              fontString:SetFont(arabicFont, fontSize, fontState.flags);
              if (fontString.SetJustifyH) then
                 fontString:SetJustifyH("LEFT");
              end
              fontString:SetText(translatedText);
           end
        end

        return result;
     end;
     tooltip.qtrQuestHelperPoiPatched = true;
     QTR_QuestHelperWaypointHooked = true;
  end

  return patchedArrow or QTR_QuestHelperWaypointHooked;
end


local function QTR_GetQuestHelperTooltipTitleFromCandidate(candidate)
  local typeQuest = candidate and candidate.type_quest;
  if (type(typeQuest) == "table" and type(typeQuest.title) == "string" and typeQuest.title ~= "") then
     return typeQuest.title;
  end

  local deferredTitle = candidate and candidate.tooltip_defer_questname;
  if (type(deferredTitle) == "string" and deferredTitle ~= "") then
     return deferredTitle;
  end

  return nil;
end


local function QTR_GetQuestHelperTooltipQuestTitle(objective)
  return QTR_GetQuestHelperTooltipTitleFromCandidate(objective)
      or QTR_GetQuestHelperTooltipTitleFromCandidate(objective and objective.objective)
      or QTR_GetQuestHelperTooltipTitleFromCandidate(objective and objective.cluster)
      or QTR_GetQuestHelperTooltipTitleFromCandidate(objective and objective.cluster and objective.cluster.objective)
      or QTR_GetQuestHelperTooltipTitleFromCandidate(objective and objective.parent)
      or QTR_GetQuestHelperTooltipTitleFromCandidate(objective and objective.parent and objective.parent.objective);
end


local function QTR_GetQuestHelperTooltipDisplayTitle(questTitle)
  if (type(questTitle) ~= "string" or questTitle == "") then
     return nil;
  end

  if (QTR_PS and QTR_PS["transtitle"] == "1") then
     return QTR_GetQuestTitleTranslation(questTitle) or questTitle;
  end

  return questTitle;
end


local function QTR_GetQuestHelperTooltipActionParts(actionText)
  if (type(actionText) ~= "string" or actionText == "") then
     return nil, nil;
  end

  if (string.sub(actionText, 1, 8) == "Acquire ") then
     return QTR_QuestHelperAcquireText, string.sub(actionText, 9);
  end

  if (string.sub(actionText, 1, 7) == "Aquire ") then
     return QTR_QuestHelperAcquireText, string.sub(actionText, 8);
  end

  if (string.sub(actionText, 1, 5) == "Slay ") then
     return QTR_QuestHelperSlayText, string.sub(actionText, 6);
  end

  if (string.sub(actionText, 1, 5) == "Open ") then
     return QTR_QuestHelperOpenText, string.sub(actionText, 6);
  end

  if (string.sub(actionText, 1, 8) == "Talk to ") then
     return QTR_QuestHelperTalkToText, string.sub(actionText, 9);
  end

  if (actionText == "Acquire" or actionText == "Aquire") then
     return QTR_QuestHelperAcquireText, nil;
  end

  if (actionText == "Slay") then
     return QTR_QuestHelperSlayText, nil;
  end

  if (actionText == "Open") then
     return QTR_QuestHelperOpenText, nil;
  end

  return nil, nil;
end


local function QTR_FormatQuestHelperQuestActionLine(actionText, displayTitle, punctuation)
  local actionLabel, targetText = QTR_GetQuestHelperTooltipActionParts(actionText);
  if (actionLabel) then
     if (targetText and targetText ~= "") then
        return actionLabel .. " " .. targetText .. " " .. QTR_QuestHelperForQuestText .. " " .. displayTitle .. punctuation;
     end

     return actionLabel .. " " .. QTR_QuestHelperForQuestText .. " " .. displayTitle .. punctuation;
  end

  if (actionText and actionText ~= "") then
     return actionText .. " " .. QTR_QuestHelperForQuestText .. " " .. displayTitle .. punctuation;
  end

  return nil;
end


local function QTR_GetQuestHelperTooltipTranslatedLine(originalText, questTitle)
  if (type(originalText) ~= "string" or originalText == "" or type(questTitle) ~= "string" or questTitle == "") then
     return nil;
  end

  local plainText = QTR_GetQuestHelperTooltipPlainText(originalText);
  if (plainText == "") then
     return nil;
  end

  local displayTitle = QTR_GetQuestHelperTooltipDisplayTitle(questTitle);
  if (not displayTitle or displayTitle == "") then
     return nil;
  end

  local punctuation = string.match(plainText, "([%.%!%?]+)%s*$") or ".";
  local turnInPrefix = "Turn in quest ";
  if (string.sub(plainText, 1, string.len(turnInPrefix)) == turnInPrefix) then
     return QTR_QuestHelperTurnInQuestText .. " " .. displayTitle .. punctuation;
  end

  local titleStart, titleEnd = string.find(plainText, questTitle, 1, true);
  if (not titleStart or not titleEnd) then
     return nil;
  end

  local prefixText = string.sub(plainText, 1, titleStart - 1);
  local forQuestMarker = " for quest ";
  if (string.len(prefixText) >= string.len(forQuestMarker) and string.sub(prefixText, -string.len(forQuestMarker)) == forQuestMarker) then
     local actionText = string.sub(prefixText, 1, string.len(prefixText) - string.len(forQuestMarker));
     return QTR_FormatQuestHelperQuestActionLine(actionText, displayTitle, punctuation);
  end

  local forMarker = " for ";
  if (string.len(prefixText) >= string.len(forMarker) and string.sub(prefixText, -string.len(forMarker)) == forMarker) then
     local actionText = string.sub(prefixText, 1, string.len(prefixText) - string.len(forMarker));
     return QTR_FormatQuestHelperQuestActionLine(actionText, displayTitle, punctuation);
  end

  return nil;
end


local function QTR_GetQuestHelperTooltipTranslatedStandaloneLine(originalText)
  if (type(originalText) ~= "string" or originalText == "") then
     return nil;
  end

  local plainText = QTR_GetQuestHelperTooltipPlainText(originalText);
  if (plainText == "") then
     return nil;
  end

  local punctuation = string.match(plainText, "([%.%!%?]+)%s*$") or ".";
  local actionText = string.gsub(plainText, "%s*[%.%!%?]+%s*$", "");
  local actionLabel, targetText = QTR_GetQuestHelperTooltipActionParts(actionText);
  if (actionLabel and targetText and targetText ~= "") then
     return actionLabel .. " " .. targetText .. punctuation;
  end

  return nil;
end


local function QTR_GetQuestHelperTooltipTranslatedTravelLabel(originalText)
  if (type(originalText) ~= "string" or originalText == "") then
     return nil;
  end

  local plainText = QTR_GetQuestHelperTooltipPlainText(originalText);
  plainText = string.gsub(plainText, "^%s+", "");
  plainText = string.gsub(plainText, "%s+$", "");

  if (plainText == "Estimated travel time:" or plainText == "Travel estimate:") then
     return QTR_QuestHelperTravelEstimateText .. ":";
  end

  return nil;
end


local function QTR_GetQuestHelperTooltipTranslatedProgressLabel(originalText)
  if (type(originalText) ~= "string" or originalText == "") then
     return nil;
  end

  local indent = string.match(originalText, "^(%s*)") or "";
  local trimmedText = string.gsub(originalText, "^%s+", "");
  local playerName = string.match(trimmedText, "^(.-)'s progress:%s*$");
  if (not playerName or playerName == "") then
     return nil;
  end

  return indent .. ((QTR_Messages and QTR_Messages.progress) or "التقدم") .. " " .. playerName .. ":";
end


local function QTR_SetQuestHelperTooltipArabicLine(fontString, tooltip, translatedText, defaultSize)
  if (not fontString or type(translatedText) ~= "string" or translatedText == "") then
     return;
  end

  local fontState = QTR_GetExternalFontState(fontString, QTR_QuestHelperTooltipFontState) or {};
  local arabicFont = QTR_Font2 or QTR_Font1 or fontState.font or Original_Font2;
   local fontSize = QTR_QuestHelperDisplayFontSize;
  local displayText = translatedText;
  local lineWidth = QTR_GetQuestHelperTooltipLineWidth(fontString, tooltip);

  if (AS_ContainsArabic and AS_ContainsArabic(displayText)) then
     displayText = QTR_PrepareWrappedArabicText(displayText, lineWidth, arabicFont, fontSize);
     displayText = QTR_QuestHelperNormalizeMixedLatinTokens(displayText);
  end

  fontString:SetFont(arabicFont, fontSize, fontState.flags);
  if (fontString.SetJustifyH) then
     fontString:SetJustifyH("LEFT");
  end
  fontString:SetText(displayText);
end


local function QTR_UpdateQuestHelperTooltipProgressLine(tooltip, lineIndex)
  local fontString = QTR_GetQuestHelperTooltipFontString(tooltip, lineIndex);
  if (not fontString or not fontString.GetText) then
     return;
  end

  local translatedText = nil;
  if (QTR_PS and QTR_PS["active"] == "1") then
     translatedText = QTR_GetQuestHelperTooltipTranslatedProgressLabel(fontString:GetText() or "");
  end

  if (translatedText and translatedText ~= "") then
   QTR_SetQuestHelperTooltipArabicLine(fontString, tooltip, translatedText, QTR_QuestHelperDisplayFontSize);
  end
end


local function QTR_UpdateQuestHelperTooltipTravelEstimateLine(tooltip, lineIndex)
  local fontString = QTR_GetQuestHelperTooltipFontString(tooltip, lineIndex);
  if (not fontString or not fontString.GetText) then
     return;
  end

  local translatedText = nil;
  if (QTR_PS and QTR_PS["active"] == "1") then
     translatedText = QTR_GetQuestHelperTooltipTranslatedTravelLabel(fontString:GetText() or "");
  end

  if (translatedText and translatedText ~= "") then
     QTR_SetQuestHelperTooltipArabicLine(fontString, tooltip, translatedText, QTR_QuestHelperDisplayFontSize);
  end
end


local function QTR_UpdateQuestHelperTooltipLine(tooltip, objective, lineIndex, mapDescIndex)
  local fontString = QTR_GetQuestHelperTooltipFontString(tooltip, lineIndex);
  if (not fontString or not fontString.GetText or not fontString.SetText or not fontString.GetFont) then
     return;
  end

  local originalText = fontString:GetText() or "";
  if (originalText == "") then
     return;
  end

  local fontState = QTR_GetExternalFontState(fontString, QTR_QuestHelperTooltipFontState) or {};
  local arabicFont = QTR_Font2 or QTR_Font1 or fontState.font or Original_Font2;
  local lineWidth = QTR_GetQuestHelperTooltipLineWidth(fontString, tooltip);
  local questTitle = QTR_GetQuestHelperTooltipQuestTitle(objective) or QTR_GetQuestTitleFromDisplayText(originalText);
  local translatedText = nil;
  local translatedAsArabicLine = false;

  if (QTR_PS and QTR_PS["active"] == "1") then
     if (questTitle and questTitle ~= "") then
        translatedText = QTR_GetQuestHelperTooltipTranslatedLine(originalText, questTitle);
        translatedAsArabicLine = translatedText and translatedText ~= "";

        if ((not translatedText or translatedText == "") and QTR_PS["transtitle"] == "1" and QTR_PrepareExternalQuestTitleDisplay) then
           translatedText = QTR_PrepareExternalQuestTitleDisplay(nil, originalText, questTitle, lineWidth, arabicFont, QTR_QuestHelperDisplayFontSize, fontState.font or arabicFont, false);
           if (translatedText == originalText) then
              translatedText = nil;
           end
        end
     end

     if (not translatedText or translatedText == "") then
        translatedText = QTR_GetQuestHelperTooltipTranslatedStandaloneLine(originalText);
        translatedAsArabicLine = translatedText and translatedText ~= "";
     end
  end

  if (translatedText and translatedText ~= "") then
     if (translatedAsArabicLine) then
        QTR_SetQuestHelperTooltipArabicLine(fontString, tooltip, translatedText, 14);
     else
      fontString:SetFont(arabicFont, QTR_QuestHelperDisplayFontSize, fontState.flags);
        if (fontString.SetJustifyH) then
           fontString:SetJustifyH("LEFT");
        end
        fontString:SetText(translatedText);
     end
  else
     QTR_RestoreExternalFontState(fontString, QTR_QuestHelperTooltipFontState);
  end
end


local function QTR_TryHookQuestHelperTooltips()
  local tooltip = QTR_GetQuestHelperTooltipFrame();
  if (type(QuestHelper) ~= "table" or not tooltip or type(QuestHelper.AppendObjectiveToTooltip) ~= "function") then
     return false;
  end

  if (not QTR_QuestHelperTooltipHooked) then
     local originalAppendObjectiveToTooltip = QuestHelper.AppendObjectiveToTooltip;
     local originalAppendObjectiveProgressToTooltip = QuestHelper.AppendObjectiveProgressToTooltip;

     QuestHelper.AppendObjectiveToTooltip = function(self, objective)
        local tooltipFrame = self and self.tooltip;
        local startLineCount = (tooltipFrame and tooltipFrame.NumLines and tooltipFrame:NumLines()) or 0;
        local result = originalAppendObjectiveToTooltip(self, objective);
        local mapDesc = objective and objective.map_desc;
        local endLineCount = (tooltipFrame and tooltipFrame.NumLines and tooltipFrame:NumLines()) or startLineCount;

        if (tooltipFrame and type(mapDesc) == "table") then
           for mapDescIndex = 1, #mapDesc do
              QTR_UpdateQuestHelperTooltipLine(tooltipFrame, objective, startLineCount + mapDescIndex, mapDescIndex);
           end
        end

        if (tooltipFrame and endLineCount > startLineCount) then
           QTR_UpdateQuestHelperTooltipTravelEstimateLine(tooltipFrame, endLineCount);
        end

        return result;
     end;

     QuestHelper.AppendObjectiveProgressToTooltip = function(self, objective, tooltipFrame, font, depth)
        local activeTooltip = tooltipFrame or (self and self.tooltip);
        local startLineCount = (activeTooltip and activeTooltip.NumLines and activeTooltip:NumLines()) or 0;
        local result = originalAppendObjectiveProgressToTooltip(self, objective, tooltipFrame, font, depth);
        local endLineCount = (activeTooltip and activeTooltip.NumLines and activeTooltip:NumLines()) or startLineCount;

        if (activeTooltip and endLineCount > startLineCount) then
           for lineIndex = startLineCount + 1, endLineCount do
              QTR_UpdateQuestHelperTooltipProgressLine(activeTooltip, lineIndex);
           end
        end

        return result;
     end;

     QTR_QuestHelperTooltipHooked = true;
  end

  return true;
end


local function QTR_IsQuestHelperQuestTitleItem(item)
  local objective = item and item.obj;
  local typeQuest = objective and objective.type_quest;
  if (not objective or not typeQuest) then
     return false;
  end

   return not objective.cluster and objective.finish and type(objective.finish) == "table" and typeQuest.title and typeQuest.title ~= "";
end


local function QTR_GetQuestHelperTrackerTitleWidth(item)
  local tracker = item and item.GetParent and item:GetParent() or nil;
  if (not tracker or not tracker.GetWidth) then
     return nil;
  end

  local trackerWidth = tracker:GetWidth() or 0;
  if (trackerWidth <= 0) then
     return nil;
  end

  local titleWidth = trackerWidth - 8;
  if (titleWidth < 60) then
     titleWidth = trackerWidth;
  end

  return titleWidth;
end


local function QTR_PatchQuestHelperTrackerLabel(fontString)
  if (not fontString or fontString.qtrQuestHelperTrackerPatched) then
     return false;
  end

  local originalSetText = fontString.SetText;
  local originalSetFont = fontString.SetFont;
  if (type(originalSetText) ~= "function" or type(originalSetFont) ~= "function") then
     return false;
  end

  fontString.SetText = function(self, text)
     local item = self.GetParent and self:GetParent() or nil;
     local state = QTR_QuestHelperTrackerTextState[self];
     if (not state) then
        state = {
           width = (self.GetWidth and self:GetWidth()) or 0,
        };
        QTR_QuestHelperTrackerTextState[self] = state;
     end

     if (not state.lock and QTR_IsQuestHelperQuestTitleItem(item)) then
        state.originalDisplayText = text;

        local fontState = QTR_GetExternalFontState(self, QTR_QuestHelperTrackerFontState) or {};
        if (QTR_PS and QTR_PS["active"] == "1" and QTR_PS["transtitle"] == "1") then
           local originalTitle = item.obj.type_quest.title or QTR_GetQuestTitleFromDisplayText(text);
           local titleWidth = QTR_GetQuestHelperTrackerTitleWidth(item);
           local arabicFont = QTR_Font1 or QTR_Font2 or fontState.font;
           local translatedText = nil;
           if (originalTitle and QTR_PrepareExternalQuestTitleDisplay) then
              translatedText = QTR_PrepareExternalQuestTitleDisplay(nil, text, originalTitle, titleWidth, arabicFont, fontState.size or 12, fontState.font or arabicFont);
           end

           if (translatedText and translatedText ~= "" and translatedText ~= text) then
              state.lock = true;
              if (self.SetWidth) then
                 self:SetWidth(titleWidth or state.width or 0);
              end
              originalSetFont(self, arabicFont, fontState.size or 12, fontState.flags);
              if (self.SetJustifyH) then
                 self:SetJustifyH("LEFT");
              end
              local result = originalSetText(self, translatedText);
              state.lock = false;
              return result;
           end
        end

        if (self.SetWidth) then
           self:SetWidth(state.width or 0);
        end
        QTR_RestoreExternalFontState(self, QTR_QuestHelperTrackerFontState);
     end

     return originalSetText(self, text);
  end;

  fontString.qtrQuestHelperTrackerPatched = true;
  return true;
end


local function QTR_PatchQuestHelperTrackerItems()
  local tracker = QTR_GetQuestHelperTrackerFrame();
  if (not tracker or type(tracker.GetChildren) ~= "function") then
     return false;
  end

  local patchedAny = false;
  local children = { tracker:GetChildren() };
  for _, item in ipairs(children) do
     if (item and item.text and QTR_PatchQuestHelperTrackerLabel(item.text)) then
        patchedAny = true;
     end
  end

  return patchedAny;
end


function QTR_TryHookQuestHelperTracker()
   QTR_TryHookQuestHelperTooltips();
   QTR_TryHookQuestHelperWaypoints();

  local tracker = QTR_GetQuestHelperTrackerFrame();
  if (not tracker or type(QH_Tracker_Rescan) ~= "function") then
     return false;
  end

  if (not QTR_QuestHelperTrackerHooked and type(hooksecurefunc) == "function") then
     hooksecurefunc("QH_Tracker_Rescan", function()
        if (QTR_QuestHelperTrackerRelayouting) then
           return;
        end

        if (QTR_PatchQuestHelperTrackerItems()) then
           QTR_QuestHelperTrackerRelayouting = true;
           QH_Tracker_Rescan();
           QTR_QuestHelperTrackerRelayouting = false;
        end
     end);
     QTR_QuestHelperTrackerHooked = true;
  end

  return QTR_PatchQuestHelperTrackerItems();
end


function QTR_RefreshQuestHelperTracker()
  if (type(QH_Tracker_Rescan) ~= "function") then
     return;
  end

  QTR_TryHookQuestHelperTracker();
  if (QHArrowFrame and QHArrowFrame.title and QHArrowFrame.title.GetText and QHArrowFrame.title.SetText) then
     local arrowTitleText = QHArrowFrame.title:GetText() or "";
     if (arrowTitleText ~= "") then
        QHArrowFrame.title:SetText(arrowTitleText);
     end
  end
   if (type(QuestHelper_Pref) ~= "table" or type(QuestHelper_Pref.track_size) ~= "number") then
       return;
   end
  QH_Tracker_Rescan();
end