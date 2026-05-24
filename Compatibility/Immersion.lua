local QTR_ImmersionHooked = false;
local QTR_ImmersionFontState = setmetatable({}, { __mode = "k" });
local QTR_RefreshImmersionQuestLayout;


local function QTR_GetExternalGossipBodyWrapWidth(fontString)
  if (not fontString) then
     return 280;
  end

  local wrapWidth = nil;
  if (fontString.GetLeft and fontString.GetRight) then
     local left = fontString:GetLeft();
     local right = fontString:GetRight();
     if (left and right and right > left) then
        wrapWidth = right - left;
     end
  end

  if ((not wrapWidth or wrapWidth < 220) and fontString.GetParent) then
     local parentFrame = fontString:GetParent();
     if (parentFrame and parentFrame.GetWidth) then
        local parentWidth = parentFrame:GetWidth();
        if (parentWidth and parentWidth > 0) then
           wrapWidth = math.min(QTR_ImmersionGossipBodyTargetWidth, parentWidth - 185);
        end
     end
  end

  if (not wrapWidth or wrapWidth < 220) then
     wrapWidth = QTR_ImmersionGossipBodyTargetWidth;
  end

  return wrapWidth;
end


local QTR_SetExternalQuestBodyText;


local function QTR_SetExternalGossipBodyText(fontString, translatedText, fontName, fontSize, skipRetry)
  if (not fontString) then
     return;
  end

  fontString.qtrQuestPagingActive = nil;
  fontString.qtrQuestOriginalText = nil;
  fontString.qtrQuestFontName = nil;
  fontString.qtrQuestFontSize = nil;

  fontName = fontName or QTR_Font1 or QTR_Font2 or Original_Font2;
  fontSize = fontSize or 13;
  fontString:SetFont(fontName, fontSize);
  local wrapWidth = QTR_GetExternalGossipBodyWrapWidth(fontString);
  fontString:SetWidth(wrapWidth);

  if (translatedText and AS_ContainsArabic and AS_ContainsArabic(translatedText) and QTR_SetExternalQuestBodyText and fontString.QueueTexts and fontString.SetToCurrentLine) then
     QTR_SetExternalQuestBodyText(fontString, translatedText, fontName, fontSize);

     if (not skipRetry and QTR_wait and wrapWidth <= 220) then
        QTR_wait(0, function(targetFontString, targetText, targetFontName, targetFontSize)
           if (targetFontString and targetFontString.IsShown and targetFontString:IsShown()) then
              QTR_SetExternalGossipBodyText(targetFontString, targetText, targetFontName, targetFontSize, true);
           end
        end, fontString, translatedText, fontName, fontSize);
     end
     return;
  end

  if (translatedText and AS_ContainsArabic and AS_ContainsArabic(translatedText)) then
     fontString:SetJustifyH("RIGHT");
     local shapedText = QTR_PrepareShownGossipDisplayText(translatedText, wrapWidth - 12, fontSize, fontName);

     if (fontString.PauseTimer) then
        fontString:PauseTimer();
     end
     if (fontString.OnFinished) then
        fontString:OnFinished();
     end
     fontString.numTexts = nil;
     fontString.timeToFinish = nil;
     fontString.timeStarted = nil;

     local rawSetText = nil;
     local metaTable = getmetatable(fontString);
     if (metaTable and metaTable.__index and metaTable.__index.SetText) then
        rawSetText = metaTable.__index.SetText;
     end

     if (rawSetText) then
        rawSetText(fontString, shapedText);
     else
        fontString:SetText(shapedText);
     end
     fontString.storedText = shapedText;
  else
     fontString:SetJustifyH("LEFT");
     local rawSetText = nil;
     local metaTable = getmetatable(fontString);
     if (metaTable and metaTable.__index and metaTable.__index.SetText) then
        rawSetText = metaTable.__index.SetText;
     end
     if (fontString.PauseTimer) then
        fontString:PauseTimer();
     end
     if (fontString.OnFinished) then
        fontString:OnFinished();
     end
     if (rawSetText) then
        rawSetText(fontString, translatedText or "");
     else
        fontString:SetText(translatedText or "");
     end
     fontString.storedText = translatedText or "";
  end

  if (not skipRetry and QTR_wait and wrapWidth <= 220) then
     QTR_wait(0, function(targetFontString, targetText, targetFontName, targetFontSize)
        if (targetFontString and targetFontString.IsShown and targetFontString:IsShown()) then
           QTR_SetExternalGossipBodyText(targetFontString, targetText, targetFontName, targetFontSize, true);
        end
     end, fontString, translatedText, fontName, fontSize);
  end
end


local function QTR_GetExternalRawSetText(fontString)
  local metaTable = getmetatable(fontString);
  if (metaTable and metaTable.__index and metaTable.__index.SetText) then
     return metaTable.__index.SetText;
  end
  return nil;
end


local function QTR_NormalizeExternalQuestSourceText(text)
  local normalizedText = text or "";
  normalizedText = string.gsub(normalizedText, "\r\n", "\n");
  normalizedText = string.gsub(normalizedText, "\r", "\n");
  normalizedText = string.gsub(normalizedText, "\n[ \t]+", "\n");
  normalizedText = string.gsub(normalizedText, "[ \t]+\n", "\n");
  normalizedText = string.gsub(normalizedText, "\n\n\n+", "\n\n");
  return normalizedText;
end


local function QTR_PrepareExternalQuestPageText(pageText, wrapWidth, fontName, fontSize)
  local displayText = pageText or "";
  local useArabicLayout = false;
  if (displayText ~= "" and AS_ContainsArabic and AS_ContainsArabic(displayText)) then
     useArabicLayout = true;
     displayText = QTR_PrepareWrappedArabicText(displayText, wrapWidth - 12, fontName, fontSize);
  end
  return displayText, useArabicLayout;
end


local function QTR_MeasureExternalQuestPage(fontString, rawSetText, pageText, fontName, fontSize, wrapWidth)
  local displayText, useArabicLayout = QTR_PrepareExternalQuestPageText(pageText, wrapWidth, fontName, fontSize);
  fontString:SetFont(fontName, fontSize);
  fontString:SetWidth(wrapWidth);
  fontString:SetJustifyH(useArabicLayout and "RIGHT" or "LEFT");
  if (rawSetText) then
     rawSetText(fontString, displayText);
  else
     fontString:SetText(displayText);
  end
  return displayText, (fontString.GetStringHeight and fontString:GetStringHeight()) or 0, useArabicLayout;
end


local QTR_ImmersionQuestPageCache = {};


local function QTR_CopyArray(sourceArray)
  local copiedArray = {};
  if (type(sourceArray) ~= "table") then
     return copiedArray;
  end

  for index, value in ipairs(sourceArray) do
     copiedArray[index] = value;
  end

  return copiedArray;
end


local function QTR_GetExternalQuestDisplayLineHeight(fontString, fontName, fontSize, wrapWidth, useArabicLayout)
  local rawSetText = QTR_GetExternalRawSetText(fontString);
  local sampleText = useArabicLayout and "ا" or "Ag";

  fontString:SetFont(fontName, fontSize);
  fontString:SetWidth(wrapWidth);
  fontString:SetJustifyH(useArabicLayout and "RIGHT" or "LEFT");

  if (rawSetText) then
     rawSetText(fontString, sampleText);
  else
     fontString:SetText(sampleText);
  end

  local lineHeight = (fontString.GetStringHeight and fontString:GetStringHeight()) or 0;
  if (not lineHeight or lineHeight <= 0) then
     lineHeight = (fontSize or 13) + 6;
  end

  return lineHeight;
end


local function QTR_ShouldSplitExternalQuestAfterPeriod(text, periodIndex)
  if (type(text) ~= "string" or periodIndex < 1) then
     return false;
  end

  if (string.sub(text, periodIndex, periodIndex) ~= ".") then
     return false;
  end

  local previousChar = (periodIndex > 1) and string.sub(text, periodIndex - 1, periodIndex - 1) or "";
  local nextChar = string.sub(text, periodIndex + 1, periodIndex + 1);
  if (previousChar == "." or nextChar == ".") then
     return false;
  end

  local prefixText = string.sub(text, 1, periodIndex - 1);
  if (string.find(prefixText, "<[^>]*$")) then
     return false;
  end

  return true;
end


local function QTR_SplitExternalQuestDisplayPages(displayText, maxLinesPerPage)
  if (type(displayText) ~= "string" or displayText == "") then
     return { "" };
  end

  local pages = {};
  local lines = {};
  local hasTrailingBreak = string.sub(displayText, -1) == "\n";

  for line in string.gmatch(displayText .. "\n", "(.-)\n") do
     table.insert(lines, line);
  end

  if (not hasTrailingBreak and #lines > 0 and lines[#lines] == "") then
     table.remove(lines, #lines);
  end

  if (#lines == 0) then
     return { displayText };
  end

  local function ShouldStartNewPageAfterLine(lineText)
     if (type(lineText) ~= "string" or lineText == "") then
        return false;
     end

     local trimmedLine = string.gsub(lineText, "%s+$", "");
     local lineLength = string.len(trimmedLine);
     if (lineLength == 0 or string.sub(trimmedLine, lineLength, lineLength) ~= ".") then
        return false;
     end

     return QTR_ShouldSplitExternalQuestAfterPeriod(trimmedLine, lineLength);
  end

  local currentLines = {};
  local function PushPage()
     if (#currentLines > 0) then
        table.insert(pages, table.concat(currentLines, "\n"));
        currentLines = {};
     end
  end

  for _, line in ipairs(lines) do
     table.insert(currentLines, line);
     if (ShouldStartNewPageAfterLine(line) or #currentLines >= maxLinesPerPage) then
        PushPage();
     end
  end

  PushPage();

  if (#pages == 0) then
     pages[1] = displayText;
  end

  return pages;
end


local function QTR_TrimExternalQuestSourceChunk(text)
  local trimmedText = text or "";
  trimmedText = string.gsub(trimmedText, "^%s+", "");
  trimmedText = string.gsub(trimmedText, "%s+$", "");
  return trimmedText;
end


local function QTR_SplitExternalQuestSourcePages(sourceText)
  if (type(sourceText) ~= "string" or sourceText == "") then
     return { "" };
  end

  local pages = {};
  local currentChunk = "";
  local textLength = string.len(sourceText);
  local index = 1;

  local function PushChunk()
     local trimmedChunk = QTR_TrimExternalQuestSourceChunk(currentChunk);
     if (trimmedChunk ~= "") then
        table.insert(pages, trimmedChunk);
     end
     currentChunk = "";
  end

  while (index <= textLength) do
     local currentChar = string.sub(sourceText, index, index);
     currentChunk = currentChunk .. currentChar;

     if (currentChar == "." and QTR_ShouldSplitExternalQuestAfterPeriod(sourceText, index)) then
        PushChunk();
        while (index < textLength) do
           local nextChar = string.sub(sourceText, index + 1, index + 1);
           if (nextChar == " " or nextChar == "\t" or nextChar == "\r" or nextChar == "\n") then
              index = index + 1;
           else
              break;
           end
        end
     elseif (currentChar == "\n" and index < textLength and string.sub(sourceText, index + 1, index + 1) == "\n") then
        PushChunk();
        while (index < textLength and string.sub(sourceText, index + 1, index + 1) == "\n") do
           index = index + 1;
        end
     end

     index = index + 1;
  end

  PushChunk();

  if (#pages == 0) then
     pages[1] = sourceText;
  end

  return pages;
end


local function QTR_BuildExternalQuestBodyPages(fontString, translatedText, fontName, fontSize, wrapWidth, maxHeight)
  local normalizedText = QTR_NormalizeExternalQuestSourceText(translatedText);
  if (normalizedText == "") then
     return { "" }, { "" }, { 0 }, false;
  end

  local cacheKey = table.concat({normalizedText, tostring(wrapWidth), tostring(fontName), tostring(fontSize), tostring(maxHeight)}, "\31");
  local cachedPages = QTR_ImmersionQuestPageCache[cacheKey];
  if (cachedPages) then
     return QTR_CopyArray(cachedPages.pageSources), QTR_CopyArray(cachedPages.displayPages), QTR_CopyArray(cachedPages.timers), cachedPages.useArabicLayout, cachedPages.totalTime;
  end

  local sourcePages = QTR_SplitExternalQuestSourcePages(normalizedText);
  local useArabicLayout = (AS_ContainsArabic and AS_ContainsArabic(normalizedText)) and true or false;
  local lineHeight = QTR_GetExternalQuestDisplayLineHeight(fontString, fontName, fontSize, wrapWidth, useArabicLayout);
  local maxLinesPerPage = math.max(2, math.floor((maxHeight or 0) / math.max(lineHeight, 1)));
  local pageSources = {};
  local displayPages = {};
  local timers = {};
  local totalTime = 0;

  for _, sourcePage in ipairs(sourcePages) do
     local displayPageText, pageUsesArabic = QTR_PrepareExternalQuestPageText(sourcePage, wrapWidth, fontName, fontSize);
     useArabicLayout = useArabicLayout or pageUsesArabic;

     local splitDisplayPages = QTR_SplitExternalQuestDisplayPages(displayPageText, maxLinesPerPage);
     for _, splitDisplayPage in ipairs(splitDisplayPages) do
        table.insert(pageSources, splitDisplayPage);
        table.insert(displayPages, splitDisplayPage);

        local pageTime = (fontString.CalculateLineTime and fontString:CalculateLineTime(string.len(splitDisplayPage))) or 0;
        table.insert(timers, pageTime);
        totalTime = totalTime + pageTime;
     end
  end

  QTR_ImmersionQuestPageCache[cacheKey] = {
     pageSources = QTR_CopyArray(pageSources),
     displayPages = QTR_CopyArray(displayPages),
     timers = QTR_CopyArray(timers),
     useArabicLayout = useArabicLayout,
     totalTime = totalTime,
  };

  return pageSources, displayPages, timers, useArabicLayout, totalTime;
end


local function QTR_GetExternalQuestBodyPageHeight(fontString)
  if (not fontString or not fontString.GetParent) then
     return 110;
  end

  local pageHeightScale = 0.52;

  local textFrame = fontString:GetParent();
  local availableHeight = 0;

  if (textFrame and textFrame.GetHeight) then
     availableHeight = textFrame:GetHeight() or 0;
  end

  local talkBox = textFrame and textFrame.GetParent and textFrame:GetParent();
  local nameHeight = 0;
  if (talkBox and talkBox.NameFrame and talkBox.NameFrame.Name and talkBox.NameFrame.Name.GetStringHeight) then
     nameHeight = talkBox.NameFrame.Name:GetStringHeight() or 0;
  end

  if (availableHeight and availableHeight > 0) then
     availableHeight = math.max(72, math.floor((availableHeight - nameHeight - 30) * pageHeightScale));
  end

  if (availableHeight and availableHeight > 60) then
     return availableHeight;
  end

  if (talkBox and talkBox.GetHeight) then
     local talkBoxHeight = talkBox:GetHeight() or 0;
     if (talkBoxHeight and talkBoxHeight > 0) then
        availableHeight = math.max(72, math.floor((talkBoxHeight - nameHeight - 42) * pageHeightScale));
        if (availableHeight and availableHeight > 60) then
           return availableHeight;
        end
     end
  end

  return 110;
end


QTR_SetExternalQuestBodyText = function(fontString, translatedText, fontName, fontSize)
  if (not fontString) then
     return;
  end

  fontName = fontName or QTR_Font1 or QTR_Font2 or Original_Font2;
  fontSize = fontSize or 13;
  fontString:SetFont(fontName, fontSize);

  local wrapWidth = QTR_GetExternalGossipBodyWrapWidth(fontString);
  fontString:SetWidth(wrapWidth);

  local maxHeight = QTR_GetExternalQuestBodyPageHeight(fontString);

  if (fontString.PauseTimer) then
     fontString:PauseTimer();
  end
  if (fontString.OnFinished) then
     fontString:OnFinished();
  end
  fontString.numTexts = nil;
  fontString.timeToFinish = nil;
  fontString.timeStarted = nil;

  if (not fontString.qtrOriginalRepeatTexts and fontString.RepeatTexts) then
     fontString.qtrOriginalRepeatTexts = fontString.RepeatTexts;
     fontString.RepeatTexts = function(self)
        if (self.qtrQuestPagingActive and self.qtrQuestOriginalText and self.qtrQuestOriginalText ~= "") then
           QTR_SetExternalQuestBodyText(self, self.qtrQuestOriginalText, self.qtrQuestFontName, self.qtrQuestFontSize);
           return;
        end
        if (self.qtrOriginalRepeatTexts) then
           self:qtrOriginalRepeatTexts();
        end
     end;
  end

  fontString.qtrQuestPagingActive = true;
  fontString.qtrQuestOriginalText = translatedText or "";
  fontString.qtrQuestFontName = fontName;
  fontString.qtrQuestFontSize = fontSize;

  local pageSources, displayPages, timers, useArabicLayout, totalTime = QTR_BuildExternalQuestBodyPages(fontString, translatedText or "", fontName, fontSize, wrapWidth, maxHeight);
  fontString:SetJustifyH(useArabicLayout and "RIGHT" or "LEFT");
  fontString.storedText = translatedText or "";

  if (displayPages and #displayPages > 1 and fontString.QueueTexts and fontString.SetToCurrentLine) then
     fontString.numTexts = #displayPages;
     fontString.timeToFinish = totalTime;
     fontString.timeStarted = GetTime and GetTime() or nil;
     fontString:QueueTexts(displayPages, timers);
     fontString:SetToCurrentLine();
  else
     local rawSetText = QTR_GetExternalRawSetText(fontString);
     local displayText = (displayPages and displayPages[1]) or "";
     fontString:SetJustifyH(useArabicLayout and "RIGHT" or "LEFT");
     if (rawSetText) then
        rawSetText(fontString, displayText);
     else
        fontString:SetText(displayText);
     end
  end

  local textFrame = fontString.GetParent and fontString:GetParent();
  if (textFrame and textFrame.SpeechProgress) then
     if (displayPages and #displayPages > 1) then
        textFrame.SpeechProgress:Show();
     else
        textFrame.SpeechProgress:Hide();
     end
  end

  local talkBox = textFrame and textFrame.GetParent and textFrame:GetParent();
  if (talkBox and talkBox.ProgressionBar) then
     if (displayPages and #displayPages > 1 and QTR_ImmersionHooked and talkBox.ProgressionBar.Show) then
        talkBox.ProgressionBar:Show();
     else
        talkBox.ProgressionBar:Hide();
     end
  end
end


local function QTR_GetImmersionTalkingHeadContent(frame, eventName, fallbackTitle, fallbackBody)
  local originalTitle = fallbackTitle or "";
  local originalBody = fallbackBody or "";

  if (eventName == "QUEST_GREETING") then
     originalTitle = (type(UnitName) == "function" and (UnitName("questnpc") or UnitName("npc"))) or originalTitle;
     originalBody = (type(GetGreetingText) == "function" and GetGreetingText()) or originalBody;
  elseif (eventName == "GOSSIP_SHOW") then
     originalTitle = (type(UnitName) == "function" and UnitName("npc")) or originalTitle;
     originalBody = (type(GetGossipText) == "function" and GetGossipText()) or originalBody;
  elseif (eventName == "QUEST_DETAIL") then
     originalTitle = (type(GetTitleText) == "function" and GetTitleText()) or originalTitle;
     originalBody = (type(GetQuestText) == "function" and GetQuestText()) or originalBody;
  elseif (eventName == "QUEST_PROGRESS") then
     originalTitle = (type(GetTitleText) == "function" and GetTitleText()) or originalTitle;
     originalBody = (type(GetProgressText) == "function" and GetProgressText()) or originalBody;
  elseif (eventName == "QUEST_COMPLETE") then
     originalTitle = (type(GetTitleText) == "function" and GetTitleText()) or originalTitle;
     originalBody = (type(GetRewardText) == "function" and GetRewardText()) or originalBody;
  end

  return originalTitle or "", originalBody or "";
end


local function QTR_RestoreImmersionTalkingHead(frame, eventName, fallbackTitle, fallbackBody)
  if (not frame or not frame.TalkBox) then
     return;
  end

  local originalTitle, originalBody = QTR_GetImmersionTalkingHeadContent(frame, eventName, fallbackTitle, fallbackBody);

  local titleFontString = frame.TalkBox.NameFrame and frame.TalkBox.NameFrame.Name;
  if (titleFontString) then
     QTR_RestoreExternalFontState(titleFontString, QTR_ImmersionFontState);
     if (titleFontString.SetJustifyH and (not AS_ContainsArabic or not AS_ContainsArabic(originalTitle or ""))) then
        titleFontString:SetJustifyH("LEFT");
     end
     titleFontString:SetText(originalTitle or "");
  end

  local bodyFontString = frame.TalkBox.TextFrame and frame.TalkBox.TextFrame.Text;
  if (bodyFontString) then
     QTR_RestoreExternalFontState(bodyFontString, QTR_ImmersionFontState);
     if (bodyFontString.SetJustifyH and (not AS_ContainsArabic or not AS_ContainsArabic(originalBody or ""))) then
        bodyFontString:SetJustifyH("LEFT");
     end
     bodyFontString.qtrQuestPagingActive = nil;
     bodyFontString.qtrQuestOriginalText = nil;
     bodyFontString.qtrQuestFontName = nil;
     bodyFontString.qtrQuestFontSize = nil;
     if (bodyFontString.PauseTimer) then
        bodyFontString:PauseTimer();
     end
     if (bodyFontString.OnFinished) then
        bodyFontString:OnFinished();
     end
     bodyFontString:SetText(originalBody or "");
  end
end


local function QTR_RestoreImmersionQuestContent(frame)
  local talkBox = frame and frame.TalkBox;
  local elements = talkBox and talkBox.Elements;
  if (not elements) then
     return;
  end

  local content = elements.Content;
  if (content and content.IsShown and content:IsShown()) then
     if (content.ObjectivesHeader and content.ObjectivesHeader.IsShown and content.ObjectivesHeader:IsShown()) then
        QTR_RestoreExternalFontState(content.ObjectivesHeader, QTR_ImmersionFontState);
        content.ObjectivesHeader:SetText(QUEST_OBJECTIVES or (content.ObjectivesHeader:GetText() or ""));
     end

     if (content.ObjectivesText and content.ObjectivesText.IsShown and content.ObjectivesText:IsShown()) then
        QTR_RestoreExternalFontState(content.ObjectivesText, QTR_ImmersionFontState);
        content.ObjectivesText:SetText((type(GetObjectiveText) == "function" and GetObjectiveText()) or (content.ObjectivesText:GetText() or ""));
     end

     if (content.RewardsFrame and content.RewardsFrame.Header and content.RewardsFrame.Header.IsShown and content.RewardsFrame.Header:IsShown()) then
        QTR_RestoreExternalFontState(content.RewardsFrame.Header, QTR_ImmersionFontState);
        content.RewardsFrame.Header:SetText(QUEST_REWARDS or (content.RewardsFrame.Header:GetText() or ""));
     end

     if (content.RewardsFrame and content.RewardsFrame.ItemChooseText and content.RewardsFrame.ItemChooseText.IsShown and content.RewardsFrame.ItemChooseText:IsShown()) then
        local chooseCount = (type(GetNumQuestChoices) == "function" and GetNumQuestChoices()) or 0;
        local chooseText = REWARD_CHOICES or (content.RewardsFrame.ItemChooseText:GetText() or "");
        if (chooseCount == 1) then
           chooseText = REWARD_ITEMS_ONLY or chooseText;
        elseif (elements.chooseItems) then
           chooseText = REWARD_CHOOSE or chooseText;
        end

        QTR_RestoreExternalFontState(content.RewardsFrame.ItemChooseText, QTR_ImmersionFontState);
        content.RewardsFrame.ItemChooseText:SetText(chooseText);
     end

     if (content.RewardsFrame and content.RewardsFrame.ItemReceiveText and content.RewardsFrame.ItemReceiveText.IsShown and content.RewardsFrame.ItemReceiveText:IsShown()) then
        local chooseCount = (type(GetNumQuestChoices) == "function" and GetNumQuestChoices()) or 0;
        local hasRewardExtras = (chooseCount > 0) or (type(GetNumRewardSpells) == "function" and (GetNumRewardSpells() or 0) > 0) or (content.RewardsFrame.PlayerTitleText and content.RewardsFrame.PlayerTitleText.IsShown and content.RewardsFrame.PlayerTitleText:IsShown());
        local receiveText = hasRewardExtras and (REWARD_ITEMS or (content.RewardsFrame.ItemReceiveText:GetText() or "")) or (REWARD_ITEMS_ONLY or (content.RewardsFrame.ItemReceiveText:GetText() or ""));

        QTR_RestoreExternalFontState(content.RewardsFrame.ItemReceiveText, QTR_ImmersionFontState);
        content.RewardsFrame.ItemReceiveText:SetText(receiveText);
     end

     if (content.RewardsFrame and content.RewardsFrame.XPFrame and content.RewardsFrame.XPFrame.ReceiveText and content.RewardsFrame.XPFrame.ReceiveText.IsShown and content.RewardsFrame.XPFrame.ReceiveText:IsShown()) then
        QTR_RestoreExternalFontState(content.RewardsFrame.XPFrame.ReceiveText, QTR_ImmersionFontState);
        content.RewardsFrame.XPFrame.ReceiveText:SetText(EXPERIENCE_COLON or (content.RewardsFrame.XPFrame.ReceiveText:GetText() or ""));
     end

     if (content.RewardsFrame and content.RewardsFrame.TalentFrame and content.RewardsFrame.TalentFrame.ReceiveText and content.RewardsFrame.TalentFrame.ReceiveText.IsShown and content.RewardsFrame.TalentFrame.ReceiveText:IsShown()) then
        QTR_RestoreExternalFontState(content.RewardsFrame.TalentFrame.ReceiveText, QTR_ImmersionFontState);
        content.RewardsFrame.TalentFrame.ReceiveText:SetText(BONUS_TALENTS or (content.RewardsFrame.TalentFrame.ReceiveText:GetText() or ""));
     end
  end

  local progress = elements.Progress;
  if (progress and progress.IsShown and progress:IsShown()) then
     if (progress.ReqText and progress.ReqText.IsShown and progress.ReqText:IsShown()) then
        QTR_RestoreExternalFontState(progress.ReqText, QTR_ImmersionFontState);
        progress.ReqText:SetText(TURN_IN_ITEMS or (progress.ReqText:GetText() or ""));
     end

     if (progress.MoneyText and progress.MoneyText.IsShown and progress.MoneyText:IsShown()) then
        QTR_RestoreExternalFontState(progress.MoneyText, QTR_ImmersionFontState);
        progress.MoneyText:SetText(REQUIRED_MONEY or (progress.MoneyText:GetText() or ""));
     end
  end

  QTR_RefreshImmersionQuestLayout(frame);
end


local function QTR_UpdateImmersionOptionButtons(buttonsFrame)
  if (not buttonsFrame or not buttonsFrame.Buttons) then
     return;
  end

  local totalHeight = 0;
  for _, button in pairs(buttonsFrame.Buttons) do
     if (button and button:IsShown() and button.Label) then
        local label = button.Label;
        local currentText = label:GetText() or "";
        if (currentText ~= "" and (not button.qtrOriginalDisplayText or button.qtrOriginalDisplayText == "" or not (AS_ContainsArabic and AS_ContainsArabic(currentText)))) then
           button.qtrOriginalDisplayText = currentText;
        end

        local originalText = button.qtrOriginalDisplayText or currentText;
        local fontState = QTR_GetExternalFontState(label, QTR_ImmersionFontState);
        local fontName = QTR_Font2 or (fontState and fontState.font) or Original_Font2;
        local fontSize = (fontState and fontState.size) or 13;
        local translatedText, translatedKind = nil, nil;
        if (QTR_PS and QTR_PS["active"] == "1") then
           translatedText, translatedKind = QTR_GetExternalChoiceTranslatedText(originalText, label:GetWidth(), fontName, fontSize);
        end

        if (translatedText and translatedText ~= "") then
           button:SetText(translatedText);
           label:SetFont(fontName, fontSize, fontState and fontState.flags or nil);
           if (label.SetJustifyH) then
              if (translatedKind == "gossip" and AS_ContainsArabic and AS_ContainsArabic(translatedText)) then
                 label:SetJustifyH("RIGHT");
              else
                 label:SetJustifyH(fontState and fontState.justify or "LEFT");
              end
           end
        else
           QTR_RestoreExternalFontState(label, QTR_ImmersionFontState);
           if (label.SetJustifyH and (not AS_ContainsArabic or not AS_ContainsArabic(originalText or ""))) then
              label:SetJustifyH("LEFT");
           end
           button:SetText(originalText or "");
        end

        local buttonHeight = max(64, (label.GetHeight and label:GetHeight() or 0) + 28);
        button:SetHeight(buttonHeight);
        totalHeight = totalHeight + buttonHeight;
     end
  end

  if (totalHeight > 0 and buttonsFrame.AdjustHeight) then
     buttonsFrame:AdjustHeight(totalHeight);
  end
end


local function QTR_ApplyImmersionQuestTalkingHead(frame, titleText, sourceText)
  if (not frame or not frame.TalkBox or not QTR_PS or QTR_PS["active"] ~= "1") then
     return false;
  end

  local questId = QTR_SelectQuestIdFromTitle(titleText or "");
  if (not questId) then
     return false;
  end

  frame.QTR_LastExternalQuestTitle = titleText;

  local titleFontString = frame.TalkBox.NameFrame and frame.TalkBox.NameFrame.Name;
  if (titleFontString) then
     QTR_GetExternalFontState(titleFontString, QTR_ImmersionFontState);
     if (QTR_PS["transtitle"] == "1") then
        local translatedTitle = QTR_GetTranslatedQuestTitleById(questId) or QTR_GetQuestTitleTranslation(titleText or (titleFontString:GetText() or ""));
        if (translatedTitle and translatedTitle ~= "") then
           local _, titleSize = titleFontString:GetFont();
           QTR_SetShapedTitleText(titleFontString, translatedTitle, QTR_Font1 or QTR_Font2 or Original_Font2, titleSize or 22, titleFontString:GetWidth());
        else
           QTR_RestoreExternalFontState(titleFontString, QTR_ImmersionFontState);
           titleFontString:SetText(titleText or "");
        end
     else
        QTR_RestoreExternalFontState(titleFontString, QTR_ImmersionFontState);
        titleFontString:SetText(titleText or "");
     end
  end

  local bodyFontString = frame.TalkBox.TextFrame and frame.TalkBox.TextFrame.Text;
  if (bodyFontString) then
     QTR_GetExternalFontState(bodyFontString, QTR_ImmersionFontState);
     local translatedBody = QTR_GetExternalQuestTextTranslationFromSource(titleText or "", sourceText or "");
     if (translatedBody and translatedBody ~= "") then
        local _, bodySize = bodyFontString:GetFont();
        QTR_SetExternalQuestBodyText(bodyFontString, translatedBody, QTR_Font1 or QTR_Font2 or Original_Font2, bodySize or 16);
     else
        QTR_RestoreImmersionTalkingHead(frame, frame.lastEvent or (frame.TalkBox and frame.TalkBox.lastEvent), titleText, sourceText);
     end
  end

  return true;
end


QTR_RefreshImmersionQuestLayout = function(frame)
  local talkBox = frame and frame.TalkBox;
  local elements = talkBox and talkBox.Elements;
  if (not talkBox or not elements or not elements.IsShown or not elements:IsShown()) then
     return;
  end

  if (elements.UpdateBoundaries) then
     elements:UpdateBoundaries();
  end

  if (talkBox.SetExtraOffset and elements.GetHeight) then
     local elementsHeight = elements:GetHeight() or 0;
     if (elementsHeight > 0) then
        local elementScale = (elements.GetScale and elements:GetScale()) or 1;
        local extraOffset = (elementsHeight + 32) * elementScale;
        if (talkBox.qtrLastExtraOffset ~= extraOffset) then
           talkBox.qtrLastExtraOffset = extraOffset;
           talkBox:SetExtraOffset(extraOffset);
        end
     end
  end
end


local function QTR_UpdateImmersionQuestContent(frame, titleText)
  local talkBox = frame and frame.TalkBox;
  local elements = talkBox and talkBox.Elements;
  if (not elements) then
     return;
  end

  if (not QTR_PS or QTR_PS["active"] ~= "1") then
     QTR_RestoreImmersionQuestContent(frame);
     return;
  end

  local content = elements.Content;
  if (content and content.IsShown and content:IsShown()) then
     local contentWidth = 507;
     if (content.ObjectivesText and content.ObjectivesText.GetWidth) then
        local measuredWidth = content.ObjectivesText:GetWidth();
        if (measuredWidth and measuredWidth > 0) then
           contentWidth = measuredWidth;
        end
     elseif (content.GetWidth) then
        local measuredWidth = content:GetWidth();
        if (measuredWidth and measuredWidth > 0) then
           contentWidth = measuredWidth - 63;
        end
     end

     if (content.ObjectivesHeader and content.ObjectivesHeader.IsShown and content.ObjectivesHeader:IsShown() and QTR_Messages and QTR_Messages.objectives) then
        local _, headerSize = content.ObjectivesHeader:GetFont();
        QTR_GetExternalFontState(content.ObjectivesHeader, QTR_ImmersionFontState);
        content.ObjectivesHeader:SetWidth(contentWidth);
        QTR_SetShapedTitleText(content.ObjectivesHeader, QTR_Messages.objectives, QTR_Font1 or QTR_Font2 or Original_Font2, headerSize or 18, contentWidth);
     end

     local objectiveText = QTR_GetExternalQuestObjectivesTranslation(titleText);
     if (objectiveText and content.ObjectivesText and content.ObjectivesText.IsShown and content.ObjectivesText:IsShown()) then
        local _, objectiveSize = content.ObjectivesText:GetFont();
        QTR_GetExternalFontState(content.ObjectivesText, QTR_ImmersionFontState);
        content.ObjectivesText:SetWidth(contentWidth);
        QTR_SetShapedTitleText(content.ObjectivesText, objectiveText, QTR_Font2 or QTR_Font1 or Original_Font2, objectiveSize or 13, contentWidth);
     end

     if (content.RewardsFrame and content.RewardsFrame.Header and content.RewardsFrame.Header.IsShown and content.RewardsFrame.Header:IsShown() and QTR_Messages and QTR_Messages.rewards) then
        local _, rewardsSize = content.RewardsFrame.Header:GetFont();
        QTR_GetExternalFontState(content.RewardsFrame.Header, QTR_ImmersionFontState);
        content.RewardsFrame.Header:SetWidth(contentWidth);
        QTR_SetShapedTitleText(content.RewardsFrame.Header, QTR_Messages.rewards, QTR_Font1 or QTR_Font2 or Original_Font2, rewardsSize or 18, contentWidth);
     end

     if (content.RewardsFrame and content.RewardsFrame.ItemChooseText and content.RewardsFrame.ItemChooseText.IsShown and content.RewardsFrame.ItemChooseText:IsShown() and QTR_Messages) then
        local chooseCount = (type(GetNumQuestChoices) == "function" and GetNumQuestChoices()) or 0;
        local chooseText = (chooseCount and chooseCount > 1) and QTR_Messages.itemchoose2 or QTR_Messages.itemchoose1;
        local _, chooseSize = content.RewardsFrame.ItemChooseText:GetFont();
        QTR_GetExternalFontState(content.RewardsFrame.ItemChooseText, QTR_ImmersionFontState);
        QTR_SetShapedText(content.RewardsFrame.ItemChooseText, chooseText, QTR_Font2 or QTR_Font1 or Original_Font2, chooseSize or 13);
     end

     if (content.RewardsFrame and content.RewardsFrame.ItemReceiveText and content.RewardsFrame.ItemReceiveText.IsShown and content.RewardsFrame.ItemReceiveText:IsShown() and QTR_Messages) then
        local chooseCount = (type(GetNumQuestChoices) == "function" and GetNumQuestChoices()) or 0;
        local receiveText = (chooseCount and chooseCount > 1) and QTR_Messages.itemreceiv2 or QTR_Messages.itemreceiv1;
        local _, receiveSize = content.RewardsFrame.ItemReceiveText:GetFont();
        QTR_GetExternalFontState(content.RewardsFrame.ItemReceiveText, QTR_ImmersionFontState);
        QTR_SetShapedText(content.RewardsFrame.ItemReceiveText, receiveText, QTR_Font2 or QTR_Font1 or Original_Font2, receiveSize or 13);
     end

     if (content.RewardsFrame and content.RewardsFrame.XPFrame and content.RewardsFrame.XPFrame.ReceiveText and content.RewardsFrame.XPFrame.ReceiveText.IsShown and content.RewardsFrame.XPFrame.ReceiveText:IsShown() and QTR_Messages and QTR_Messages.experience) then
        local _, xpSize = content.RewardsFrame.XPFrame.ReceiveText:GetFont();
        QTR_GetExternalFontState(content.RewardsFrame.XPFrame.ReceiveText, QTR_ImmersionFontState);
        QTR_SetShapedText(content.RewardsFrame.XPFrame.ReceiveText, QTR_Messages.experience, QTR_Font2 or QTR_Font1 or Original_Font2, xpSize or 13);
     end

     if (content.RewardsFrame and content.RewardsFrame.TalentFrame and content.RewardsFrame.TalentFrame.ReceiveText and content.RewardsFrame.TalentFrame.ReceiveText.IsShown and content.RewardsFrame.TalentFrame.ReceiveText:IsShown() and QTR_Messages and QTR_Messages.bonustalents) then
        local _, talentSize = content.RewardsFrame.TalentFrame.ReceiveText:GetFont();
        QTR_GetExternalFontState(content.RewardsFrame.TalentFrame.ReceiveText, QTR_ImmersionFontState);
        QTR_SetShapedText(content.RewardsFrame.TalentFrame.ReceiveText, QTR_Messages.bonustalents, QTR_Font2 or QTR_Font1 or Original_Font2, talentSize or 13);
     end
  end

  local progress = elements.Progress;
  if (progress and progress.IsShown and progress:IsShown()) then
     if (progress.ReqText and progress.ReqText.IsShown and progress.ReqText:IsShown() and QTR_Messages and QTR_Messages.reqitems) then
        local _, reqSize = progress.ReqText:GetFont();
        local progressWidth = (progress.GetWidth and progress:GetWidth() and (progress:GetWidth() - 63)) or 507;
        QTR_GetExternalFontState(progress.ReqText, QTR_ImmersionFontState);
        progress.ReqText:SetWidth(progressWidth);
        QTR_SetShapedTitleText(progress.ReqText, QTR_Messages.reqitems, QTR_Font1 or QTR_Font2 or Original_Font2, reqSize or 18, progressWidth);
     end
     if (progress.MoneyText and progress.MoneyText.IsShown and progress.MoneyText:IsShown() and QTR_Messages and QTR_Messages.reqmoney) then
        local _, moneySize = progress.MoneyText:GetFont();
        QTR_GetExternalFontState(progress.MoneyText, QTR_ImmersionFontState);
        QTR_SetShapedText(progress.MoneyText, QTR_Messages.reqmoney, QTR_Font2 or QTR_Font1 or Original_Font2, moneySize or 13);
     end
  end

  QTR_RefreshImmersionQuestLayout(frame);
end


local function QTR_UpdateImmersionFrame(frame)
  if (not frame or not frame.IsShown or not frame:IsShown() or not frame.TalkBox) then
     return;
  end

  local eventName = frame.lastEvent or (frame.TalkBox and frame.TalkBox.lastEvent);
  if (not eventName or eventName == "") then
     return;
  end

  local titleText = nil;
  if (type(GetTitleText) == "function") then
     titleText = GetTitleText();
  end
  if ((not titleText or titleText == "") and frame.QTR_LastExternalQuestTitle and frame.QTR_LastExternalQuestTitle ~= "") then
     titleText = frame.QTR_LastExternalQuestTitle;
  end
  if ((not titleText or titleText == "") and frame.IsAvailableQuestID and frame.IsAvailableQuestID ~= "") then
     titleText = frame.IsAvailableQuestID;
  end

  if (not QTR_PS or QTR_PS["active"] ~= "1") then
     QTR_RestoreImmersionTalkingHead(frame, eventName, titleText, nil);
     QTR_RestoreImmersionQuestContent(frame);
     return;
  end

  if (eventName == "QUEST_DETAIL" or eventName == "QUEST_PROGRESS" or eventName == "QUEST_COMPLETE") then
     return;
  end

  local bodyFontString = frame.TalkBox.TextFrame and frame.TalkBox.TextFrame.Text;
  if (bodyFontString) then
     QTR_GetExternalFontState(bodyFontString, QTR_ImmersionFontState);
     local translatedBody = nil;
     if (eventName == "QUEST_GREETING") then
        local greetingText = (type(GetGreetingText) == "function" and GetGreetingText()) or bodyFontString:GetText() or "";
        translatedBody = QTR_GetExternalGossipBodyTranslation(greetingText, true);
     elseif (eventName == "GOSSIP_SHOW") then
        local gossipText = (type(GetGossipText) == "function" and GetGossipText()) or bodyFontString:GetText() or "";
        translatedBody = QTR_GetExternalGossipBodyTranslation(gossipText, true);
     end

     if (translatedBody and translatedBody ~= "") then
        local _, bodySize = bodyFontString:GetFont();
        QTR_SetExternalGossipBodyText(bodyFontString, translatedBody, QTR_Font1 or QTR_Font2 or Original_Font2, bodySize or 16);
     elseif (eventName == "QUEST_GREETING" or eventName == "GOSSIP_SHOW") then
        QTR_RestoreImmersionTalkingHead(frame, eventName, titleText, nil);
     end
  end

  if (QTR_PS and QTR_PS["active"] == "1" and eventName ~= "QUEST_DETAIL" and eventName ~= "QUEST_PROGRESS" and eventName ~= "QUEST_COMPLETE") then
     QTR_UpdateImmersionQuestContent(frame, titleText or "");
  end
end


function QTR_TryHookImmersion()
  if (QTR_ImmersionHooked or type(IsAddOnLoaded) ~= "function" or not IsAddOnLoaded("Immersion")) then
     return QTR_ImmersionHooked;
  end
  if (not ImmersionFrame or type(ImmersionFrame.OnEvent) ~= "function" or not ImmersionFrame.TitleButtons or type(ImmersionFrame.TitleButtons.UpdateActive) ~= "function") then
     return false;
  end

  QTR_ImmersionHooked = true;

  hooksecurefunc(ImmersionFrame, "OnEvent", function(self)
     QTR_UpdateImmersionFrame(self);
  end);

  hooksecurefunc(ImmersionFrame, "UpdateTalkingHead", function(self, titleText, text, npcType)
     if (not self or not self.TalkBox or not self.TalkBox.TextFrame or not self.TalkBox.TextFrame.Text) then
        return;
     end

     if (not QTR_PS or QTR_PS["active"] ~= "1") then
        return;
     end

     local isGreetingText = false;
     if (type(GetGreetingText) == "function") then
        local currentGreetingText = GetGreetingText();
        if (currentGreetingText and currentGreetingText ~= "" and currentGreetingText == (text or "")) then
           isGreetingText = true;
        end
     end

     if (npcType == "GossipGossip" or isGreetingText) then
        local translatedBody = QTR_GetExternalGossipBodyTranslation(text or "", true);
        if (translatedBody and translatedBody ~= "") then
           local bodyFontString = self.TalkBox.TextFrame.Text;
           QTR_GetExternalFontState(bodyFontString, QTR_ImmersionFontState);
           local _, bodySize = bodyFontString:GetFont();
           QTR_SetExternalGossipBodyText(bodyFontString, translatedBody, QTR_Font1 or QTR_Font2 or Original_Font2, bodySize or 16);
        end
        return;
     end

     QTR_ApplyImmersionQuestTalkingHead(self, titleText, text);
  end);

  hooksecurefunc(ImmersionFrame, "AddQuestInfo", function(self)
     local titleText = (type(GetTitleText) == "function" and GetTitleText()) or self.QTR_LastExternalQuestTitle or self.IsAvailableQuestID or "";
     QTR_UpdateImmersionQuestContent(self, titleText);
  end);

  if (ImmersionFrame.TalkBox and ImmersionFrame.TalkBox.Elements and type(ImmersionFrame.TalkBox.Elements.ShowProgress) == "function") then
     hooksecurefunc(ImmersionFrame.TalkBox.Elements, "ShowProgress", function()
        local titleText = (type(GetTitleText) == "function" and GetTitleText()) or ImmersionFrame.QTR_LastExternalQuestTitle or ImmersionFrame.IsAvailableQuestID or "";
        QTR_UpdateImmersionQuestContent(ImmersionFrame, titleText);
     end);
  end;

  hooksecurefunc(ImmersionFrame.TitleButtons, "UpdateActive", function(self)
     QTR_UpdateImmersionOptionButtons(self);
  end);

  QTR_RefreshImmersionLiveView();
  return true;
end


function QTR_RefreshImmersionLiveView()
  if (not QTR_TryHookImmersion() or not ImmersionFrame or not ImmersionFrame.IsShown or not ImmersionFrame:IsShown()) then
     return;
  end

  local eventName = ImmersionFrame.lastEvent or (ImmersionFrame.TalkBox and ImmersionFrame.TalkBox.lastEvent);
  local titleText = (type(GetTitleText) == "function" and GetTitleText()) or ImmersionFrame.QTR_LastExternalQuestTitle or ImmersionFrame.IsAvailableQuestID or "";

  if (not QTR_PS or QTR_PS["active"] ~= "1") then
     QTR_RestoreImmersionTalkingHead(ImmersionFrame, eventName, titleText, nil);
     QTR_RestoreImmersionQuestContent(ImmersionFrame);
  elseif (eventName == "QUEST_DETAIL" or eventName == "QUEST_PROGRESS" or eventName == "QUEST_COMPLETE") then
     local _, sourceText = QTR_GetImmersionTalkingHeadContent(ImmersionFrame, eventName, titleText, nil);
     QTR_ApplyImmersionQuestTalkingHead(ImmersionFrame, titleText, sourceText);
     QTR_UpdateImmersionQuestContent(ImmersionFrame, titleText);
  else
     QTR_UpdateImmersionFrame(ImmersionFrame);
  end

  QTR_UpdateImmersionOptionButtons(ImmersionFrame.TitleButtons);
end