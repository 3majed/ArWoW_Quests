local QTR_QuestieTrackerHooked = false;
local QTR_QuestieTrackerLabelsPatched = false;
local QTR_QuestieTrackerLabelState = setmetatable({}, { __mode = "k" });
local QTR_QuestieArrowHooked = false;
local QTR_QuestieArrowTitleState = setmetatable({}, { __mode = "k" });
local QTR_QuestieMapTooltipHooked = false;
local QTR_QuestieUnitTooltipHooked = false;
local QTR_QuestieTooltipFontState = setmetatable({}, { __mode = "k" });


local function QTR_GetQuestieTrackerModules()
  if (type(QuestieLoader) ~= "table" or type(QuestieLoader.ImportModule) ~= "function") then
     return nil, nil;
  end

  local trackerOk, QuestieTracker = pcall(function()
     return QuestieLoader:ImportModule("QuestieTracker");
  end);
  if (not trackerOk or not QuestieTracker) then
     return nil, nil;
  end

  local linePoolOk, TrackerLinePool = pcall(function()
     return QuestieLoader:ImportModule("TrackerLinePool");
  end);
  if (not linePoolOk or not TrackerLinePool) then
     return QuestieTracker, nil;
  end

  return QuestieTracker, TrackerLinePool;
end


local function QTR_PatchQuestieTrackerLabel(label)
  if (not label or label.qtrQuestieTrackerPatched) then
     return true;
  end

  local originalSetText = label.SetText;
  local originalSetWidth = label.SetWidth;
  local originalSetFont = label.SetFont;

  if (type(originalSetText) ~= "function" or type(originalSetWidth) ~= "function" or type(originalSetFont) ~= "function") then
     return false;
  end

  label.SetText = function(self, text)
     local line = self.frame;
     local state = QTR_QuestieTrackerLabelState[self];
     if (not state) then
        state = {};
        QTR_QuestieTrackerLabelState[self] = state;
     end

     if (not state.lock and line and line.mode == "quest" and line.Quest) then
        state.displayText = text;
     else
        state.displayText = nil;
     end

     return originalSetText(self, text);
  end;

  label.SetWidth = function(self, width)
     originalSetWidth(self, width);

     local line = self.frame;
     local state = QTR_QuestieTrackerLabelState[self];
     if (not line or line.mode ~= "quest" or not line.Quest or not state or state.lock or not width or width <= 0) then
        return;
     end
     if (not state.displayText or state.displayText == "") then
        return;
     end
     if (not QTR_PS or QTR_PS["active"] ~= "1" or QTR_PS["transtitle"] ~= "1") then
        return;
     end

     local defaultFont, defaultFontSize, defaultFontOutline = self:GetFont();
     local arabicFont = QTR_Font1 or QTR_Font2 or defaultFont;
     local questTitle = line.Quest.Name;
     if ((not questTitle or questTitle == "") and type(QuestieLoader) == "table" and type(QuestieLoader.ImportModule) == "function") then
        local questDbOk, QuestieDB = pcall(function()
           return QuestieLoader:ImportModule("QuestieDB");
        end);
        if (questDbOk and QuestieDB and line.Quest.Id) then
           questTitle = QuestieDB.QueryQuestSingle(line.Quest.Id, "name");
        end
     end
     if (not questTitle or questTitle == "") then
        return;
     end

     local translatedText = nil;
     if (QTR_PrepareExternalQuestTitleDisplay) then
        translatedText = QTR_PrepareExternalQuestTitleDisplay(line.Quest.Id, state.displayText, questTitle, width, arabicFont, defaultFontSize or 13, defaultFont or arabicFont);
     end
     if (not translatedText or translatedText == "" or translatedText == state.displayText) then
        return;
     end

     state.lock = true;
     originalSetFont(self, arabicFont, defaultFontSize or 13, defaultFontOutline);
     self:SetJustifyH("LEFT");
     originalSetText(self, translatedText);
     state.lock = false;
  end;

  label.qtrQuestieTrackerPatched = true;
  return true;
end


local function QTR_PatchQuestieTrackerLines(TrackerLinePool)
  if (not TrackerLinePool or type(TrackerLinePool.GetLine) ~= "function") then
     return false;
  end

  local lineIndex = 1;
  local patchedAny = false;
  while (true) do
     local line = TrackerLinePool.GetLine(lineIndex);
     if (not line) then
        break;
     end
     if (line.label and QTR_PatchQuestieTrackerLabel(line.label)) then
        patchedAny = true;
     end
     lineIndex = lineIndex + 1;
  end

  if (patchedAny) then
     QTR_QuestieTrackerLabelsPatched = true;
  end
  return patchedAny;
end


function QTR_TryHookQuestieTracker()
  local QuestieTracker, TrackerLinePool = QTR_GetQuestieTrackerModules();
  if (not QuestieTracker or not TrackerLinePool) then
     return false;
  end

  if (not QTR_QuestieTrackerHooked and type(hooksecurefunc) == "function" and type(QuestieTracker.Initialize) == "function") then
     hooksecurefunc(QuestieTracker, "Initialize", function()
        local _, hookedLinePool = QTR_GetQuestieTrackerModules();
        QTR_QuestieTrackerLabelsPatched = false;
        if (hookedLinePool) then
           QTR_PatchQuestieTrackerLines(hookedLinePool);
        end
     end);
     QTR_QuestieTrackerHooked = true;
  end

  if (QTR_QuestieTrackerLabelsPatched and QuestieTracker.started) then
     return true;
  end

  return QTR_PatchQuestieTrackerLines(TrackerLinePool);
end


function QTR_RefreshQuestieTracker()
  local QuestieTracker = nil;
  local TrackerLinePool = nil;

  QuestieTracker, TrackerLinePool = QTR_GetQuestieTrackerModules();
  if (not QuestieTracker or not TrackerLinePool) then
     return;
  end

  QTR_TryHookQuestieTracker();
  if (not QuestieTracker.started or type(QuestieTracker.Update) ~= "function") then
     return;
  end

  if (not QTR_wait(0.15, function()
     local refreshedTracker = nil;
     refreshedTracker = select(1, QTR_GetQuestieTrackerModules());
     if (refreshedTracker and refreshedTracker.started and type(refreshedTracker.Update) == "function") then
        refreshedTracker:Update();
     end
  end)) then
     QuestieTracker:Update();
  end
end


local function QTR_GetQuestieArrowModule()
  if (type(QuestieLoader) ~= "table" or type(QuestieLoader.ImportModule) ~= "function") then
     return nil;
  end

  local arrowOk, QuestieArrow = pcall(function()
     return QuestieLoader:ImportModule("QuestieArrow");
  end);
  if (not arrowOk or not QuestieArrow) then
     return nil;
  end

  return QuestieArrow;
end


local function QTR_GetQuestieArrowFrame()
  local arrowFrame = _G and _G["QuestieArrowFrame"];
  if (not arrowFrame or not arrowFrame.title or type(arrowFrame.title.SetText) ~= "function") then
     return nil;
  end

  return arrowFrame;
end


local function QTR_GetQuestieArrowDisplayTitle(frame)
  if (not frame or not frame._lastTarget) then
     return nil;
  end

  local title = frame._lastTarget.title or "";
  if (frame._lastTarget.questLevel) then
     title = "[" .. frame._lastTarget.questLevel .. "] " .. title;
  end

  if (type(Questie) == "table" and type(Questie.Colorize) == "function") then
     return Questie:Colorize(title, "gold");
  end

  return title;
end


local function QTR_ReapplyQuestieArrowTitle(titleFontString)
  if (not titleFontString or not titleFontString.qtrQuestieArrowPatched) then
     return false;
  end

  local state = QTR_GetExternalFontState(titleFontString, QTR_QuestieArrowTitleState);
  if (not state or state.lock) then
     return false;
  end

  local rawDisplayText = state.originalDisplayText;
  local parentFrame = titleFontString.GetParent and titleFontString:GetParent() or nil;
  if ((not rawDisplayText or rawDisplayText == "") and parentFrame) then
     rawDisplayText = QTR_GetQuestieArrowDisplayTitle(parentFrame);
  end
  if ((not rawDisplayText or rawDisplayText == "") and titleFontString.GetText) then
     rawDisplayText = titleFontString:GetText();
  end
  if (not rawDisplayText or rawDisplayText == "") then
     return false;
  end

  state.originalDisplayText = rawDisplayText;
  titleFontString:SetText(rawDisplayText);
  return true;
end


local function QTR_PatchQuestieArrowTitle(titleFontString)
  if (not titleFontString or titleFontString.qtrQuestieArrowPatched) then
     return true;
  end

  local originalSetText = titleFontString.SetText;
  local originalSetFont = titleFontString.SetFont;
  if (type(originalSetText) ~= "function" or type(originalSetFont) ~= "function") then
     return false;
  end

  titleFontString.SetText = function(self, text)
     local state = QTR_GetExternalFontState(self, QTR_QuestieArrowTitleState);
     if (not state or state.lock) then
        return originalSetText(self, text);
     end

     local rawDisplayText = text or "";
     if (rawDisplayText == "") then
        state.originalDisplayText = nil;
        state.translatedDisplayText = nil;
        QTR_RestoreExternalFontState(self, QTR_QuestieArrowTitleState);
        return originalSetText(self, text);
     end

     state.originalDisplayText = rawDisplayText;

     local originalTitle = QTR_GetQuestTitleFromDisplayText(rawDisplayText);
     local translatedText = nil;
     if (originalTitle and QTR_PrepareExternalQuestTitleDisplay) then
        local fontState = QTR_GetExternalFontState(self, QTR_QuestieArrowTitleState);
        local arabicFont = QTR_Font1 or QTR_Font2 or (fontState and fontState.font) or Original_Font2;
        local titleWidth = self.GetWidth and self:GetWidth() or 0;
        if ((not titleWidth or titleWidth <= 0) and self.GetStringWidth) then
           titleWidth = self:GetStringWidth() or 0;
        end
        if ((not titleWidth or titleWidth <= 0) and self.GetParent and self:GetParent() and self:GetParent().GetWidth) then
           titleWidth = self:GetParent():GetWidth() or 0;
        end
        if (not titleWidth or titleWidth < 220) then
           titleWidth = 220;
        end
        translatedText = QTR_PrepareExternalQuestTitleDisplay(nil, rawDisplayText, originalTitle, titleWidth, arabicFont, (fontState and fontState.size) or 13, (fontState and fontState.font) or arabicFont, false);
     end

     if (translatedText and translatedText ~= "" and translatedText ~= rawDisplayText) then
        local fontState = QTR_GetExternalFontState(self, QTR_QuestieArrowTitleState);

        state.lock = true;
        originalSetFont(self, QTR_Font1 or QTR_Font2 or (fontState and fontState.font) or Original_Font2, (fontState and fontState.size) or 13, fontState and fontState.flags);
        originalSetText(self, translatedText);
        state.lock = false;
        state.translatedDisplayText = translatedText;
        return;
     end

     state.translatedDisplayText = nil;
     QTR_RestoreExternalFontState(self, QTR_QuestieArrowTitleState);
     return originalSetText(self, rawDisplayText);
  end;

  titleFontString.qtrQuestieArrowPatched = true;
  return true;
end


local function QTR_ReapplyQuestieArrowDistance(distanceFontString)
  if (not distanceFontString or not distanceFontString.qtrQuestieArrowDistancePatched) then
     return false;
  end

  local state = QTR_GetExternalFontState(distanceFontString, QTR_QuestieArrowTitleState);
  if (not state or state.lock) then
     return false;
  end

  local rawDisplayText = state.originalDisplayText;
  if ((not rawDisplayText or rawDisplayText == "") and distanceFontString.GetText) then
     rawDisplayText = distanceFontString:GetText();
  end
  if (not rawDisplayText or rawDisplayText == "") then
     return false;
  end

  state.originalDisplayText = rawDisplayText;
  distanceFontString:SetText(rawDisplayText);
  return true;
end


local function QTR_PatchQuestieArrowDistance(distanceFontString)
  if (not distanceFontString or distanceFontString.qtrQuestieArrowDistancePatched) then
     return true;
  end

  local originalSetText = distanceFontString.SetText;
  local originalSetFont = distanceFontString.SetFont;
  if (type(originalSetText) ~= "function" or type(originalSetFont) ~= "function") then
     return false;
  end

  distanceFontString.SetText = function(self, text)
     local state = QTR_GetExternalFontState(self, QTR_QuestieArrowTitleState);
     if (not state or state.lock) then
        return originalSetText(self, text);
     end

     local rawDisplayText = text or "";
     if (rawDisplayText == "") then
        state.originalDisplayText = nil;
        state.translatedDisplayText = nil;
        QTR_RestoreExternalFontState(self, QTR_QuestieArrowTitleState);
        return originalSetText(self, text);
     end

     state.originalDisplayText = rawDisplayText;

     local distanceSuffix = string.match(rawDisplayText, "^Distance:%s*(.*)$");
     local translatedText = nil;
     if (distanceSuffix and QTR_PS and QTR_PS["active"] == "1") then
        local fontState = QTR_GetExternalFontState(self, QTR_QuestieArrowTitleState);
        local arabicFont = QTR_Font2 or QTR_Font1 or (fontState and fontState.font) or Original_Font2;
        local displayText = "المسافة:";
        if (distanceSuffix ~= "") then
           displayText = displayText .. " " .. distanceSuffix;
        end
        translatedText = QTR_PrepareWrappedArabicText(displayText, 220, arabicFont, (fontState and fontState.size) or 13);
     end

     if (translatedText and translatedText ~= "" and translatedText ~= rawDisplayText) then
        local fontState = QTR_GetExternalFontState(self, QTR_QuestieArrowTitleState);

        state.lock = true;
        originalSetFont(self, QTR_Font2 or QTR_Font1 or (fontState and fontState.font) or Original_Font2, (fontState and fontState.size) or 13, fontState and fontState.flags);
        originalSetText(self, translatedText);
        state.lock = false;
        state.translatedDisplayText = translatedText;
        return;
     end

     state.translatedDisplayText = nil;
     QTR_RestoreExternalFontState(self, QTR_QuestieArrowTitleState);
     return originalSetText(self, rawDisplayText);
  end;

  distanceFontString.qtrQuestieArrowDistancePatched = true;
  return true;
end


local function QTR_PatchQuestieArrowFrame(frame)
  if (not frame or not frame.title) then
     return false;
  end

  local patchedTitle = QTR_PatchQuestieArrowTitle(frame.title);
  local patchedDistance = false;
  if (frame.distance) then
     patchedDistance = QTR_PatchQuestieArrowDistance(frame.distance);
  end
  if (patchedTitle and not frame.qtrQuestieArrowPatched and type(frame.HookScript) == "function") then
     frame:HookScript("OnHide", function(self)
        if (self.title) then
           local state = QTR_QuestieArrowTitleState[self.title];
           if (state) then
              state.originalDisplayText = nil;
              state.translatedDisplayText = nil;
              state.lock = nil;
           end
           QTR_RestoreExternalFontState(self.title, QTR_QuestieArrowTitleState);
        end
        if (self.distance) then
           local state = QTR_QuestieArrowTitleState[self.distance];
           if (state) then
              state.originalDisplayText = nil;
              state.translatedDisplayText = nil;
              state.lock = nil;
           end
           QTR_RestoreExternalFontState(self.distance, QTR_QuestieArrowTitleState);
        end
        self._lastTarget = nil;
     end);
     frame.qtrQuestieArrowPatched = true;
  end

  if (patchedTitle) then
     QTR_ReapplyQuestieArrowTitle(frame.title);
  end
  if (patchedDistance and frame.distance) then
     QTR_ReapplyQuestieArrowDistance(frame.distance);
  end

  return patchedTitle or patchedDistance;
end


function QTR_TryHookQuestieArrow()
  local QuestieArrow = QTR_GetQuestieArrowModule();
  local arrowFrame = QTR_GetQuestieArrowFrame();
  local patchedFrame = false;

  if (arrowFrame) then
     patchedFrame = QTR_PatchQuestieArrowFrame(arrowFrame);
  end

  if (not QuestieArrow) then
     return patchedFrame;
  end

  if (not QTR_QuestieArrowHooked and type(hooksecurefunc) == "function") then
     if (type(QuestieArrow.Initialize) == "function") then
        hooksecurefunc(QuestieArrow, "Initialize", function()
           local hookedFrame = QTR_GetQuestieArrowFrame();
           if (hookedFrame) then
              QTR_PatchQuestieArrowFrame(hookedFrame);
           end
        end);
     end
     if (type(QuestieArrow.SetTarget) == "function") then
        hooksecurefunc(QuestieArrow, "SetTarget", function()
           local hookedFrame = QTR_GetQuestieArrowFrame();
           if (hookedFrame) then
              QTR_PatchQuestieArrowFrame(hookedFrame);
           end
        end);
     end
     QTR_QuestieArrowHooked = true;
  end

  return patchedFrame or QTR_QuestieArrowHooked;
end


function QTR_RefreshQuestieArrow()
  local QuestieArrow = QTR_GetQuestieArrowModule();
  local arrowFrame = QTR_GetQuestieArrowFrame();

  QTR_TryHookQuestieArrow();
  if (arrowFrame) then
     QTR_PatchQuestieArrowFrame(arrowFrame);
  end

  if (QuestieArrow and type(QuestieArrow.Refresh) == "function") then
     QuestieArrow:Refresh();
  end

  arrowFrame = QTR_GetQuestieArrowFrame();
  if (arrowFrame and arrowFrame.title) then
     QTR_PatchQuestieArrowFrame(arrowFrame);
     return QTR_ReapplyQuestieArrowTitle(arrowFrame.title) or (arrowFrame.distance and QTR_ReapplyQuestieArrowDistance(arrowFrame.distance));
  end

  return false;
end


local function QTR_GetQuestieUnitTooltipModules()
  if (type(QuestieLoader) ~= "table" or type(QuestieLoader.ImportModule) ~= "function") then
     return nil, nil, nil;
  end

  local tooltipsOk, QuestieTooltips = pcall(function()
     return QuestieLoader:ImportModule("QuestieTooltips");
  end);
  if (not tooltipsOk or not QuestieTooltips) then
     return nil, nil, nil;
  end

  local dbOk, QuestieDB = pcall(function()
     return QuestieLoader:ImportModule("QuestieDB");
  end);
  local libOk, QuestieLib = pcall(function()
     return QuestieLoader:ImportModule("QuestieLib");
  end);

  return QuestieTooltips, (dbOk and QuestieDB or nil), (libOk and QuestieLib or nil);
end


local function QTR_GetQuestieMapTooltipModules()
  if (type(QuestieLoader) ~= "table" or type(QuestieLoader.ImportModule) ~= "function") then
     return nil, nil, nil;
  end

  local mapOk, MapIconTooltip = pcall(function()
     return QuestieLoader:ImportModule("MapIconTooltip");
  end);
  if (not mapOk or not MapIconTooltip) then
     return nil, nil, nil;
  end

  local dbOk, QuestieDB = pcall(function()
     return QuestieLoader:ImportModule("QuestieDB");
  end);
  local libOk, QuestieLib = pcall(function()
     return QuestieLoader:ImportModule("QuestieLib");
  end);

  return MapIconTooltip, (dbOk and QuestieDB or nil), (libOk and QuestieLib or nil);
end


local function QTR_GetQuestieTooltipWrapWidth(tooltip)
  local width = 375;
  if (tooltip and tooltip.GetWidth) then
     local tooltipWidth = tooltip:GetWidth();
     if (tooltipWidth and tooltipWidth > width) then
        width = tooltipWidth;
     end
  end
  return width;
end


local function QTR_GetQuestieQuestTitleFromDb(QuestieDB, questId)
  if (not QuestieDB or not questId) then
     return nil;
  end

  if (type(QuestieDB.QueryQuestSingle) == "function") then
     local questTitle = QuestieDB.QueryQuestSingle(questId, "name");
     if (questTitle and questTitle ~= "") then
        return questTitle;
     end
  end

  if (type(QuestieDB.GetQuest) == "function") then
     local quest = QuestieDB.GetQuest(questId);
     if (quest and quest.name and quest.name ~= "") then
        return quest.name;
     end
  end

  return nil;
end


local function QTR_GetQuestieTooltipTranslatedTitleDisplay(tooltip, questId, displayText, originalTitle)
  if (not displayText or displayText == "") then
     return nil;
  end
  if (AS_ContainsArabic and AS_ContainsArabic(displayText)) then
     return displayText;
  end

  local translatedQuestTitle = nil;
  if (questId) then
     translatedQuestTitle = QTR_GetTranslatedQuestTitleById(tostring(questId));
  end
  if (not translatedQuestTitle and originalTitle and originalTitle ~= "") then
     translatedQuestTitle = QTR_GetQuestTitleTranslation(originalTitle);
  end
  if (not translatedQuestTitle or translatedQuestTitle == "") then
     return nil;
  end

  local translatedDisplayText = QTR_PrepareExternalQuestTitleDisplay(questId, displayText, originalTitle or "", nil, QTR_Font2, 13, QTR_Font2, false);
  if (translatedDisplayText and translatedDisplayText ~= "" and tooltip) then
     tooltip.qtrQuestieTitleLineData = tooltip.qtrQuestieTitleLineData or {};
     local titleLineData = {
        questId = questId,
        displayText = displayText,
        originalTitle = originalTitle or "",
     };
     tooltip.qtrQuestieTitleLineData[displayText] = titleLineData;
     tooltip.qtrQuestieTitleLineData[translatedDisplayText] = titleLineData;
  end

  return translatedDisplayText;
end


local function QTR_RegisterQuestieTooltipTitleData(tooltip, questId, displayText, originalTitle)
  if (not tooltip or not questId or not originalTitle or originalTitle == "") then
     return nil;
  end

  tooltip.qtrQuestieTitleLineData = tooltip.qtrQuestieTitleLineData or {};
  local titleLineData = {
     questId = questId,
     displayText = displayText,
     originalTitle = originalTitle,
  };

  if (displayText and displayText ~= "") then
     tooltip.qtrQuestieTitleLineData[displayText] = titleLineData;
  end
  tooltip.qtrQuestieTitleLineData[originalTitle] = titleLineData;
  return titleLineData;
end


local function QTR_PrimeQuestieNextChainTitleData(tooltip, QuestieDB)
  if (not tooltip or type(tooltip.npcAndObjectOrder) ~= "table" or not QuestieDB or type(QuestieDB.QueryQuestSingle) ~= "function" or type(QuestieDB.GetQuest) ~= "function") then
     return;
  end

  for _, quests in pairs(tooltip.npcAndObjectOrder) do
     for _, questData in pairs(quests) do
        if (type(questData) == "table" and questData.questId) then
           local nextQuestInChain = QuestieDB.QueryQuestSingle(questData.questId, "nextQuestInChain");
           if (nextQuestInChain and nextQuestInChain > 0) then
              local nextQuest = QuestieDB.GetQuest(nextQuestInChain);
              while (nextQuest ~= nil) do
                 if (nextQuest.Id and nextQuest.name and nextQuest.name ~= "") then
                    QTR_RegisterQuestieTooltipTitleData(tooltip, nextQuest.Id, nextQuest.name, nextQuest.name);
                 end
                 nextQuest = QuestieDB.GetQuest(nextQuest.nextQuestInChain);
              end
           end
        end
     end
  end
end


local function QTR_PrimeQuestieTooltipTitleData(tooltip, QuestieDB, QuestieLib)
  if (not tooltip) then
     return;
  end

  tooltip.qtrQuestieTitleLineData = {};

  if (type(tooltip.npcAndObjectOrder) == "table") then
     for _, quests in pairs(tooltip.npcAndObjectOrder) do
        for _, questData in pairs(quests) do
           if (type(questData) == "table" and questData.questId and questData.title and questData.title ~= "") then
              local questId = tonumber(questData.questId) or questData.questId;
              local originalTitle = QTR_GetQuestieQuestTitleFromDb(QuestieDB, questId);
              QTR_GetQuestieTooltipTranslatedTitleDisplay(tooltip, questId, questData.title, originalTitle);
           end
        end
     end
  end

  QTR_PrimeQuestieNextChainTitleData(tooltip, QuestieDB);

  if (QTR_PS and QTR_PS["transtitle"] == "1" and QuestieLib and type(QuestieLib.GetColoredQuestName) == "function" and type(tooltip.questOrder) == "table") then
     for questId in pairs(tooltip.questOrder) do
        local displayText = QuestieLib:GetColoredQuestName(questId, Questie.db.profile.enableTooltipsQuestLevel, true, true);
        local originalTitle = QTR_GetQuestieQuestTitleFromDb(QuestieDB, questId);
        if (displayText and displayText ~= "") then
           QTR_GetQuestieTooltipTranslatedTitleDisplay(tooltip, questId, displayText, originalTitle);
        end
     end
  end
end


local function QTR_GetQuestieTooltipTranslatedDescription(questId)
  local questKey = questId and tostring(questId);
  if (not questKey or not QTR_QuestData or not QTR_QuestData[questKey]) then
     return nil;
  end

  local translatedDescription = QTR_QuestData[questKey]["Description"];
  if (not translatedDescription or translatedDescription == "") then
     return nil;
  end

  translatedDescription = QTR_ExpandUnitInfo(translatedDescription);
  if (not translatedDescription or translatedDescription == "") then
     return nil;
  end

  return translatedDescription;
end


local function QTR_GetQuestieTooltipTitleLineWidth(fontString, tooltip)
  local titleWidth = nil;

  if (fontString and fontString.GetWidth) then
     titleWidth = fontString:GetWidth();
  end

  if ((not titleWidth or titleWidth < 40) and fontString and fontString.GetParent) then
     local parentFrame = fontString:GetParent();
     if (parentFrame and parentFrame.GetWidth) then
        local parentWidth = parentFrame:GetWidth();
        if (parentWidth and parentWidth > 60) then
           titleWidth = parentWidth - 30;
        end
     end
  end

  if ((not titleWidth or titleWidth < 40) and tooltip and tooltip.GetWidth) then
     local tooltipWidth = tooltip:GetWidth();
     if (tooltipWidth and tooltipWidth > 60) then
        titleWidth = tooltipWidth - 30;
     end
  end

  if (not titleWidth or titleWidth < 40) then
     titleWidth = 260;
  end

  return titleWidth;
end


local function QTR_FindQuestieTitleLineData(tooltip, fontText, lookupText)
  local titleDataMap = tooltip and tooltip.qtrQuestieTitleLineData;
  if (type(titleDataMap) ~= "table") then
     return nil;
  end

  local titleLineData = titleDataMap[fontText] or titleDataMap[lookupText];
  if (titleLineData) then
     return titleLineData;
  end

  local seenEntries = {};
  for _, entry in pairs(titleDataMap) do
     if (type(entry) == "table" and entry.originalTitle and entry.originalTitle ~= "" and not seenEntries[entry]) then
        seenEntries[entry] = true;
        if (string.find(fontText or "", entry.originalTitle, 1, true) or string.find(lookupText or "", entry.originalTitle, 1, true)) then
           return entry;
        end
     end
  end

  return nil;
end


local function QTR_UpdateQuestieTooltipFontString(fontString, tooltip)
  if (not fontString or not fontString.GetText or not fontString.GetFont or not fontString.SetFont) then
     return;
  end

  local fontState = QTR_QuestieTooltipFontState[fontString];
  if (not fontState) then
     local originalFont, originalSize, originalFlags = fontString:GetFont();
     fontState = {
        font = originalFont or Original_Font2,
        size = originalSize or 13,
        flags = originalFlags,
        justify = fontString.GetJustifyH and fontString:GetJustifyH(),
     };
     QTR_QuestieTooltipFontState[fontString] = fontState;
  end

  local fontText = fontString:GetText() or "";
  local texturePrefix, lookupText = QTR_ExtractLeadingTextureTags(fontText);
  local titleLineData = QTR_FindQuestieTitleLineData(tooltip, fontText, lookupText);
  if (titleLineData) then
     local titleWidth = QTR_GetQuestieTooltipTitleLineWidth(fontString, tooltip);
     if (texturePrefix ~= "") then
        if (AS_TestLine == nil and AS_CreateTestLine) then
           AS_CreateTestLine();
        end
        if (AS_TestLine and AS_TestLine.text) then
           AS_TestLine.text:SetFont(QTR_Font2 or fontState.font or Original_Font2, fontState.size or 13, fontState.flags);
           AS_TestLine.text:SetText(texturePrefix);
           titleWidth = titleWidth - (AS_TestLine.text:GetStringWidth() or 0);
           if (titleWidth < 40) then
              titleWidth = QTR_GetQuestieTooltipTitleLineWidth(fontString, tooltip);
           end
        end
     end
     local sourceDisplayText = titleLineData.displayText or lookupText or fontText;
     if (sourceDisplayText == titleLineData.originalTitle) then
        sourceDisplayText = lookupText or fontText;
     end
     local shapedTitleText = QTR_PrepareExternalQuestTitleDisplay(titleLineData.questId, sourceDisplayText, titleLineData.originalTitle, titleWidth, QTR_Font2 or fontState.font or Original_Font2, fontState.size or 13, QTR_Font2 or fontState.font or Original_Font2, false);
     if (shapedTitleText and shapedTitleText ~= "") then
        fontString:SetFont(QTR_Font2 or fontState.font or Original_Font2, fontState.size or 13, fontState.flags);
        if (fontString.SetJustifyH) then
           fontString:SetJustifyH("RIGHT");
        end
        fontString:SetText(texturePrefix .. shapedTitleText);
        return;
     end
  end

  if (fontText ~= "" and AS_ContainsArabic and AS_ContainsArabic(fontText)) then
     fontString:SetFont(QTR_Font2 or fontState.font or Original_Font2, fontState.size or 13, fontState.flags);
     if (fontString.SetJustifyH) then
        fontString:SetJustifyH("RIGHT");
     end
  else
     fontString:SetFont(fontState.font or Original_Font2, fontState.size or 13, fontState.flags);
     if (fontString.SetJustifyH) then
        fontString:SetJustifyH(fontState.justify or "LEFT");
     end
  end
end


local function QTR_ApplyQuestieTooltipFonts(tooltip)
  if (not tooltip or not tooltip.GetName or not tooltip.NumLines) then
     return;
  end

  local tooltipName = tooltip:GetName();
  if (not tooltipName or tooltipName == "") then
     return;
  end

  for lineIndex = 1, (tooltip:NumLines() or 0) do
     QTR_UpdateQuestieTooltipFontString(_G[tooltipName .. "TextLeft" .. lineIndex], tooltip);
     QTR_UpdateQuestieTooltipFontString(_G[tooltipName .. "TextRight" .. lineIndex], tooltip);
  end
end


local function QTR_WrapQuestieMapTooltipRebuild(tooltip, QuestieDB, QuestieLib)
  if (not tooltip or type(tooltip._Rebuild) ~= "function") then
     return false;
  end
  if (tooltip.qtrQuestieWrappedFunc and tooltip._Rebuild == tooltip.qtrQuestieWrappedFunc) then
     return true;
  end

  local originalRebuild = tooltip._Rebuild;
  local wrappedRebuild = function(self)
     local savedQuestData = {};
     local originalGetColoredQuestName = nil;
     local originalTextWrap = nil;
     self.qtrQuestieTitleLineData = {};

     if (QTR_PS and QTR_PS["active"] == "1") then
        if (type(self.npcAndObjectOrder) == "table") then
          for _, quests in pairs(self.npcAndObjectOrder) do
             for _, questData in pairs(quests) do
                if (type(questData) == "table" and questData.questId) then
                   local questId = tonumber(questData.questId) or questData.questId;
                   local originalTitle = QTR_GetQuestieQuestTitleFromDb(QuestieDB, questId);

                   if (QTR_PS["transtitle"] == "1" and questData.title and questData.title ~= "") then
                      local translatedTitle = QTR_GetQuestieTooltipTranslatedTitleDisplay(self, questId, questData.title, originalTitle);
                      if (translatedTitle and translatedTitle ~= "" and translatedTitle ~= questData.title) then
                         if (not savedQuestData[questData]) then
                            savedQuestData[questData] = { title = questData.title, subData = questData.subData };
                         end
                         questData.title = translatedTitle;
                      end
                   end

                   local translatedDescription = QTR_GetQuestieTooltipTranslatedDescription(questId);
                   if (translatedDescription) then
                      if (not savedQuestData[questData]) then
                         savedQuestData[questData] = { title = questData.title, subData = questData.subData };
                      end
                      questData.subData = translatedDescription;
                   end
                end
             end
          end
        end

        QTR_PrimeQuestieNextChainTitleData(self, QuestieDB);

        if (QuestieLib and type(QuestieLib.TextWrap) == "function") then
           originalTextWrap = QuestieLib.TextWrap;
           QuestieLib.TextWrap = function(libSelf, line, prefix, combineTrailing, desiredWidth)
              if (type(line) == "string" and line ~= "" and AS_ContainsArabic and AS_ContainsArabic(line)) then
                 local wrappedText = QTR_PrepareWrappedArabicText(line, desiredWidth or QTR_GetQuestieTooltipWrapWidth(self), QTR_Font2, 13);
                 local wrappedLines = QTR_SplitMultilineText(wrappedText);
                 if (#wrappedLines == 0) then
                    return { (prefix or "") .. line };
                 end

                 local outputLines = {};
                 for _, wrappedLine in ipairs(wrappedLines) do
                    outputLines[#outputLines + 1] = (prefix or "") .. wrappedLine;
                 end
                 return outputLines;
              end

              return originalTextWrap(libSelf, line, prefix, combineTrailing, desiredWidth);
           end;
        end

        if (QTR_PS["transtitle"] == "1" and QuestieLib and type(QuestieLib.GetColoredQuestName) == "function" and type(self.questOrder) == "table") then
           local translatedQuestIds = {};
           for questId in pairs(self.questOrder) do
              translatedQuestIds[tostring(questId)] = true;
           end

           originalGetColoredQuestName = QuestieLib.GetColoredQuestName;
           QuestieLib.GetColoredQuestName = function(libSelf, questId, ...)
              local displayText = originalGetColoredQuestName(libSelf, questId, ...);
              if (not translatedQuestIds[tostring(questId)]) then
                 return displayText;
              end

              local originalTitle = QTR_GetQuestieQuestTitleFromDb(QuestieDB, questId);
              local translatedDisplayText = QTR_GetQuestieTooltipTranslatedTitleDisplay(self, questId, displayText, originalTitle);
              return translatedDisplayText or displayText;
           end;
        end
     end

     local rebuildOk, rebuildErr = pcall(originalRebuild, self);

     if (originalGetColoredQuestName) then
        QuestieLib.GetColoredQuestName = originalGetColoredQuestName;
     end
     if (originalTextWrap) then
        QuestieLib.TextWrap = originalTextWrap;
     end
     for questData, savedData in pairs(savedQuestData) do
        questData.title = savedData.title;
        questData.subData = savedData.subData;
     end

     if (rebuildOk) then
        QTR_ApplyQuestieTooltipFonts(self);
     end

     if (not rebuildOk and type(geterrorhandler) == "function") then
        geterrorhandler()(rebuildErr);
     end
  end;

  tooltip.qtrQuestieWrappedFunc = wrappedRebuild;
  tooltip._Rebuild = wrappedRebuild;
  return true;
end


local function QTR_GetQuestieTooltipFrame(ownerFrame)
  if (not ownerFrame) then
     return nil;
  end

  if (type(QuestieCompat) == "table" and QuestieCompat.Tooltip and QuestieCompat.Tooltip._owner == ownerFrame) then
     return QuestieCompat.Tooltip;
  end
  if (WorldMapTooltip and WorldMapTooltip._owner == ownerFrame) then
     return WorldMapTooltip;
  end
  if (GameTooltip and GameTooltip._owner == ownerFrame) then
     return GameTooltip;
  end

  return nil;
end


local function QTR_TranslateQuestieUnitTooltipLines(key, tooltipLines, QuestieTooltips, QuestieDB, QuestieLib)
  if (not key or type(tooltipLines) ~= "table") then
     return tooltipLines;
  end
  if (string.find(key, "^m_") == nil) then
     return tooltipLines;
  end
  if (not QTR_PS or QTR_PS["active"] ~= "1" or QTR_PS["transtitle"] ~= "1") then
     return tooltipLines;
  end
  if (not QuestieTooltips or type(QuestieTooltips.lookupByKey) ~= "table" or not QuestieLib or type(QuestieLib.GetColoredQuestName) ~= "function") then
     return tooltipLines;
  end

  local tooltipEntries = QuestieTooltips.lookupByKey[key];
  if (type(tooltipEntries) ~= "table") then
     return tooltipLines;
  end

  local titleEntries = {};
  local seenQuestIds = {};
  for _, tooltipData in pairs(tooltipEntries) do
     local questId = tooltipData and tooltipData.questId;
     local questKey = questId and tostring(questId);
     if (questKey and not seenQuestIds[questKey]) then
        seenQuestIds[questKey] = true;

        local originalTitle = QTR_GetQuestieQuestTitleFromDb(QuestieDB, questId);
        if (originalTitle and originalTitle ~= "") then
           titleEntries[#titleEntries + 1] = {
              questId = questId,
              originalTitle = originalTitle,
              displayText = QuestieLib:GetColoredQuestName(questId, Questie.db.profile.enableTooltipsQuestLevel, true, true),
           };
        end
     end
  end

  if (#titleEntries == 0) then
     return tooltipLines;
  end

  local translatedLines = {};
  for _, tooltipLine in ipairs(tooltipLines) do
     local replacedLine = false;
     if (type(tooltipLine) == "string" and tooltipLine ~= "" and (not AS_ContainsArabic or not AS_ContainsArabic(tooltipLine))) then
        for _, titleEntry in ipairs(titleEntries) do
           if (((titleEntry.displayText and tooltipLine == titleEntry.displayText) or string.find(tooltipLine, titleEntry.originalTitle, 1, true))) then
              local translatedLine = QTR_PrepareExternalQuestTitleDisplay(titleEntry.questId, tooltipLine, titleEntry.originalTitle, 240, QTR_Font2, 13, QTR_Font2, false);
              if (translatedLine and translatedLine ~= "") then
                 translatedLines[#translatedLines + 1] = translatedLine;
              else
                 translatedLines[#translatedLines + 1] = tooltipLine;
              end
              replacedLine = true;
              break;
           end
        end
     end

     if (not replacedLine) then
        translatedLines[#translatedLines + 1] = tooltipLine;
     end
  end

  return translatedLines;
end


function QTR_TryHookQuestieMapTooltips()
  local MapIconTooltip, QuestieDB, QuestieLib = QTR_GetQuestieMapTooltipModules();
  if (not MapIconTooltip or type(MapIconTooltip.Show) ~= "function") then
     return false;
  end
  if (QTR_QuestieMapTooltipHooked or type(hooksecurefunc) ~= "function") then
     return QTR_QuestieMapTooltipHooked;
  end

  hooksecurefunc(MapIconTooltip, "Show", function(iconFrame)
     if (not iconFrame or iconFrame.miniMapIcon) then
        return;
     end

     local tooltip = QTR_GetQuestieTooltipFrame(iconFrame);
     if (not tooltip or type(tooltip._Rebuild) ~= "function") then
        return;
     end
     if (not QTR_WrapQuestieMapTooltipRebuild(tooltip, QuestieDB, QuestieLib)) then
        return;
     end
     if (QTR_PS and QTR_PS["active"] == "1") then
        QTR_PrimeQuestieTooltipTitleData(tooltip, QuestieDB, QuestieLib);
        QTR_ApplyQuestieTooltipFonts(tooltip);
     end
  end);

  QTR_QuestieMapTooltipHooked = true;
  return true;
end


function QTR_TryHookQuestieUnitTooltips()
  local QuestieTooltips, QuestieDB, QuestieLib = QTR_GetQuestieUnitTooltipModules();
  if (not QuestieTooltips or type(QuestieTooltips.GetTooltip) ~= "function" or type(QuestieTooltips.private) ~= "table" or type(QuestieTooltips.private.AddUnitDataToTooltip) ~= "function") then
     return false;
  end

  if (not QuestieTooltips.qtrWrappedGetTooltipFunc or QuestieTooltips.GetTooltip ~= QuestieTooltips.qtrWrappedGetTooltipFunc) then
     local originalGetTooltip = QuestieTooltips.GetTooltip;
     local wrappedGetTooltip = function(self, key, ...)
        local tooltipLines = originalGetTooltip(self, key, ...);
        return QTR_TranslateQuestieUnitTooltipLines(key, tooltipLines, QuestieTooltips, QuestieDB, QuestieLib);
     end;

     QuestieTooltips.qtrWrappedGetTooltipFunc = wrappedGetTooltip;
     QuestieTooltips.GetTooltip = wrappedGetTooltip;
  end

  if (not QuestieTooltips.private.qtrUnitTooltipFontHooked and type(hooksecurefunc) == "function") then
     hooksecurefunc(QuestieTooltips.private, "AddUnitDataToTooltip", function(tooltip)
        if (not tooltip or tooltip ~= GameTooltip) then
           return;
        end

        tooltip.qtrQuestieTitleLineData = {};
        QTR_ApplyQuestieTooltipFonts(tooltip);
     end);
     QuestieTooltips.private.qtrUnitTooltipFontHooked = true;
  end

  QTR_QuestieUnitTooltipHooked = (QuestieTooltips.GetTooltip == QuestieTooltips.qtrWrappedGetTooltipFunc);
  return QTR_QuestieUnitTooltipHooked;
end