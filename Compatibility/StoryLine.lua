local QTR_StorylineHooked = false;
local QTR_StorylineFontState = setmetatable({}, { __mode = "k" });
local QTR_StorylineRefreshPending = false;


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


local function QTR_SetExternalPrefixedText(fontString, originalText, translatedText, fontName, fontSize)
  if (not fontString or not translatedText or translatedText == "") then
     return;
  end

  local prefixTexture, remainder = QTR_ExtractLeadingTextureTags(originalText or "");
  local prefixColor, _ = QTR_ExtractLeadingDisplayControlCodes(remainder or "");
  local suffixColor = string.match(remainder or "", "(|r%s*)$") or "";
  local wrapWidth = nil;
  if (fontString.GetWidth) then
     wrapWidth = fontString:GetWidth();
  end

  fontString:SetFont(fontName, fontSize);
  if (AS_ContainsArabic and AS_ContainsArabic(translatedText)) then
     fontString:SetJustifyH("RIGHT");
     fontString:SetText((prefixTexture or "") .. (prefixColor or "") .. QTR_PrepareWrappedArabicText(translatedText, wrapWidth, fontName, fontSize) .. suffixColor);
  else
     fontString:SetJustifyH("LEFT");
     fontString:SetText((prefixTexture or "") .. (prefixColor or "") .. translatedText .. suffixColor);
  end
end


function QTR_UpdateStorylineDialogButtons()
  local function UpdateStorylineChoiceButton(button)
     if (not button or not button.IsShown or not button:IsShown()) then
        return 0;
     end

     local label = button.Text or button.text or (button.GetFontString and button:GetFontString());
     if (not label or not label.GetText) then
        return (button.GetHeight and button:GetHeight()) or 0;
     end

     local currentText = label:GetText() or "";
     if (currentText ~= "" and (not button.qtrOriginalDisplayText or button.qtrOriginalDisplayText == "" or not (AS_ContainsArabic and AS_ContainsArabic(currentText)))) then
        button.qtrOriginalDisplayText = currentText;
     end

     local originalText = button.qtrOriginalDisplayText or currentText;
     local fontState = QTR_GetExternalFontState(label, QTR_StorylineFontState);
     local fontName = QTR_Font2 or (fontState and fontState.font) or Original_Font2;
     local fontSize = (fontState and fontState.size) or 13;
     local width = (label.GetWidth and label:GetWidth()) or (button.GetWidth and button:GetWidth()) or 0;
     local translatedText, translatedKind = nil, nil;
     if (QTR_PS and QTR_PS["active"] == "1") then
        translatedText, translatedKind = QTR_GetExternalChoiceTranslatedText(originalText, width, fontName, fontSize);
     end

     if (translatedText and translatedText ~= "") then
        if (type(button.SetText) == "function") then
           button:SetText(translatedText);
        else
           label:SetText(translatedText);
        end
        label:SetFont(fontName, fontSize, fontState and fontState.flags or nil);
        if (label.SetJustifyH) then
           if (translatedKind == "gossip" and AS_ContainsArabic and AS_ContainsArabic(translatedText)) then
              label:SetJustifyH("RIGHT");
           else
              label:SetJustifyH(fontState and fontState.justify or "LEFT");
           end
        end
     else
        if (type(button.SetText) == "function") then
           button:SetText(originalText or "");
        else
           label:SetText(originalText or "");
        end
        QTR_RestoreExternalFontState(label, QTR_StorylineFontState);
     end

     if (type(button.RefreshHeight) == "function") then
        button:RefreshHeight();
     end

     return (button.GetHeight and button:GetHeight()) or 0;
  end

  for _, button in ipairs({ Storyline_NPCFrameChatOption1, Storyline_NPCFrameChatOption2, Storyline_NPCFrameChatOption3 }) do
     UpdateStorylineChoiceButton(button);
  end

  if (Storyline_NPCFrameGossipChoices and Storyline_NPCFrameGossipChoices.IsShown and Storyline_NPCFrameGossipChoices:IsShown()) then
     local totalHeight = 40;
     for _, button in ipairs({ Storyline_NPCFrameGossipChoices:GetChildren() }) do
        if (button and button.IsShown and button:IsShown()) then
           totalHeight = totalHeight + UpdateStorylineChoiceButton(button) + 10;
        end
     end
     if (totalHeight > 40) then
        Storyline_NPCFrameGossipChoices:SetHeight(totalHeight);
     end
  end
end


function QTR_GetStorylineEventName()
  if (Storyline_NPCFrameChat and Storyline_NPCFrameChat.event and Storyline_NPCFrameChat.event ~= "") then
     return Storyline_NPCFrameChat.event;
  end

  return nil;
end


function QTR_GetStorylineTitleFontString()
  if (Storyline_NPCFrame and Storyline_NPCFrame.Banner and Storyline_NPCFrame.Banner.Title) then
     return Storyline_NPCFrame.Banner.Title;
  end

  return Storyline_NPCFrameTitle;
end


function QTR_GetStorylineQuestTitle()
  local questTitle = (type(GetTitleText) == "function" and GetTitleText()) or nil;
  if ((not questTitle or questTitle == "") and Storyline_NPCFrameTitle and Storyline_NPCFrameTitle.GetText) then
     questTitle = Storyline_NPCFrameTitle:GetText();
  end

  return questTitle or "";
end


function QTR_GetStorylineBodySourceText(eventName)
  if (eventName == "QUEST_DETAIL") then
     return (type(GetQuestText) == "function" and GetQuestText()) or "";
  elseif (eventName == "QUEST_PROGRESS") then
     return (type(GetProgressText) == "function" and GetProgressText()) or "";
  elseif (eventName == "QUEST_COMPLETE") then
     return (type(GetRewardText) == "function" and GetRewardText()) or "";
  elseif (eventName == "QUEST_GREETING") then
     return (type(GetGreetingText) == "function" and GetGreetingText()) or "";
  elseif (eventName == "GOSSIP_SHOW") then
     return (type(GetGossipText) == "function" and GetGossipText()) or "";
  end

  return "";
end


function QTR_GetStorylineQuestLogObjectives(questTitle)
  if (not questTitle or questTitle == "" or type(GetNumQuestLogEntries) ~= "function" or type(GetQuestLogTitle) ~= "function" or type(SelectQuestLogEntry) ~= "function" or type(GetQuestLogQuestText) ~= "function") then
     return "";
  end

  local currentSelection = (type(GetQuestLogSelection) == "function" and GetQuestLogSelection()) or nil;
  local objectivesText = "";
  local questEntries = GetNumQuestLogEntries() or 0;

  for questIndex = 1, questEntries do
     local currentTitle, _, _, _, isHeader = GetQuestLogTitle(questIndex);
     if (currentTitle == questTitle and not isHeader) then
        SelectQuestLogEntry(questIndex);
        local _, questObjectives = GetQuestLogQuestText();
        objectivesText = questObjectives or "";
        break;
     end
  end

  if (currentSelection and currentSelection > 0) then
     SelectQuestLogEntry(currentSelection);
  end

  return objectivesText;
end


function QTR_GetStorylineOriginalObjectivesText(eventName, questTitle)
  if (eventName == "QUEST_DETAIL") then
     return (type(GetObjectiveText) == "function" and GetObjectiveText()) or "";
  end

  if (eventName == "QUEST_PROGRESS") then
     local objectivesText = QTR_GetStorylineQuestLogObjectives(questTitle);
     if (objectivesText ~= "") then
        if (type(IsQuestCompletable) == "function" and IsQuestCompletable()) then
           objectivesText = "|TInterface\\RAIDFRAME\\ReadyCheck-Ready:15:15|t |cff00ff00" .. objectivesText;
        else
           objectivesText = "|TInterface\\RAIDFRAME\\ReadyCheck-NotReady:15:15|t |cffff0000" .. objectivesText;
        end
     end
     return objectivesText;
  end

  return "";
end


function QTR_SplitStorylineTextPages(text)
  local pages = QTR_SplitMultilineText(text);
  local filteredPages = {};

  for _, pageText in ipairs(pages) do
     if (type(pageText) == "string" and string.find(pageText, "%S")) then
        filteredPages[#filteredPages + 1] = pageText;
     end
  end

  if (#filteredPages == 0) then
     filteredPages[1] = text or "";
  end

  return filteredPages;
end


function QTR_PrepareStorylineDisplayPages(pages, width, fontName, fontSize)
  local displayPages = {};

  for index, pageText in ipairs(pages or {}) do
     if (pageText and AS_ContainsArabic and AS_ContainsArabic(pageText)) then
        displayPages[index] = QTR_PrepareWrappedArabicText(pageText, width, fontName, fontSize);
     else
        displayPages[index] = pageText or "";
     end
  end

  if (#displayPages == 0) then
     displayPages[1] = "";
  end

  return displayPages;
end


function QTR_RefreshStorylineFrameLayout()
  if (Storyline_NPCFrameChat and Storyline_NPCFrameChatText and Storyline_NPCFrameChatNextText) then
     local nameHeight = Storyline_NPCFrameChatName and Storyline_NPCFrameChatName:GetHeight() or 0;
     if (issecretvalue and issecretvalue(nameHeight) and Storyline_Data and Storyline_Data.config and Storyline_Data.config["NPCName"]) then
        nameHeight = Storyline_Data.config["NPCName"].Size;
     end
     Storyline_NPCFrameChat:SetHeight((Storyline_NPCFrameChatText:GetHeight() or 0) + nameHeight + (Storyline_NPCFrameChatNextText:GetHeight() or 0) + 50);
  end
end


function QTR_RestoreStorylineFrame()
  if (not Storyline_NPCFrame or not Storyline_NPCFrame.IsShown or not Storyline_NPCFrame:IsShown()) then
     return;
  end

  local eventName = QTR_GetStorylineEventName();
  local questTitle = QTR_GetStorylineQuestTitle();

  local titleFontString = QTR_GetStorylineTitleFontString();
  if (titleFontString) then
     QTR_RestoreExternalFontState(titleFontString, QTR_StorylineFontState);
     titleFontString:SetText(questTitle or "");
  end

  if (Storyline_NPCFrameChat and Storyline_NPCFrameChatText) then
     local sourceText = QTR_GetStorylineBodySourceText(eventName);
     local originalTexts = QTR_SplitStorylineTextPages(sourceText);

     Storyline_NPCFrameChat.texts = originalTexts;

     local textCount = #originalTexts;
     local currentIndex = Storyline_NPCFrameChat.currentIndex or 1;
     if (currentIndex < 1) then
        currentIndex = 1;
     end
     if (textCount > 0 and currentIndex > textCount) then
        currentIndex = textCount;
     end
     Storyline_NPCFrameChat.currentIndex = currentIndex;

     local currentText = (textCount > 0 and originalTexts[currentIndex]) or "";
     QTR_RestoreExternalFontState(Storyline_NPCFrameChatText, QTR_StorylineFontState);
     Storyline_NPCFrameChatText:SetText(currentText or "");
     if (Storyline_NPCFrameChatText.SetAlphaGradient) then
        Storyline_NPCFrameChatText:SetAlphaGradient(string.len(currentText or ""), 1);
     end
     Storyline_NPCFrameChat.start = nil;
  end

  if (Storyline_NPCFrameObjectivesContent) then
     if (Storyline_NPCFrameObjectivesContent.Title and Storyline_NPCFrameObjectivesContent.Title.IsShown and Storyline_NPCFrameObjectivesContent.Title:IsShown()) then
        QTR_RestoreExternalFontState(Storyline_NPCFrameObjectivesContent.Title, QTR_StorylineFontState);
        Storyline_NPCFrameObjectivesContent.Title:SetText(QUEST_OBJECTIVES or (Storyline_NPCFrameObjectivesContent.Title:GetText() or ""));
     end

     if (Storyline_NPCFrameObjectivesContent.RequiredItemText and Storyline_NPCFrameObjectivesContent.RequiredItemText.IsShown and Storyline_NPCFrameObjectivesContent.RequiredItemText:IsShown()) then
        QTR_RestoreExternalFontState(Storyline_NPCFrameObjectivesContent.RequiredItemText, QTR_StorylineFontState);
        Storyline_NPCFrameObjectivesContent.RequiredItemText:SetText(TURN_IN_ITEMS or (Storyline_NPCFrameObjectivesContent.RequiredItemText:GetText() or ""));
     end

     if (Storyline_NPCFrameObjectivesContent.Objectives and Storyline_NPCFrameObjectivesContent.Objectives.IsShown and Storyline_NPCFrameObjectivesContent.Objectives:IsShown()) then
        local originalObjectives = QTR_GetStorylineOriginalObjectivesText(eventName, questTitle);
        QTR_RestoreExternalFontState(Storyline_NPCFrameObjectivesContent.Objectives, QTR_StorylineFontState);
        Storyline_NPCFrameObjectivesContent.Objectives:SetText(originalObjectives or "");
     end
  end

  if (Storyline_NPCFrameRewards and Storyline_NPCFrameRewards.IsShown and Storyline_NPCFrameRewards:IsShown() and Storyline_NPCFrameRewards.Content and Storyline_NPCFrameRewards.Content.Title and Storyline_NPCFrameRewards.Content.Title.IsShown and Storyline_NPCFrameRewards.Content.Title:IsShown()) then
     QTR_RestoreExternalFontState(Storyline_NPCFrameRewards.Content.Title, QTR_StorylineFontState);
     Storyline_NPCFrameRewards.Content.Title:SetText(REWARDS or (Storyline_NPCFrameRewards.Content.Title:GetText() or ""));
  end

  QTR_UpdateStorylineDialogButtons();
  QTR_RefreshStorylineFrameLayout();
end


function QTR_UpdateStorylineFrame()
  if (not Storyline_NPCFrame or not Storyline_NPCFrame.IsShown or not Storyline_NPCFrame:IsShown()) then
     return;
  end

  local eventName = QTR_GetStorylineEventName();
  local questTitle = QTR_GetStorylineQuestTitle();
  local titleFontString = QTR_GetStorylineTitleFontString();

  if (not QTR_PS or QTR_PS["active"] ~= "1") then
     QTR_RestoreStorylineFrame();
     return;
  end

  if (titleFontString) then
     QTR_GetExternalFontState(titleFontString, QTR_StorylineFontState);
     if (QTR_PS["transtitle"] == "1") then
        local translatedTitle = QTR_GetQuestTitleTranslation(questTitle or (titleFontString.GetText and titleFontString:GetText()) or "");
        if (translatedTitle and translatedTitle ~= "") then
           local _, titleSize = titleFontString:GetFont();
           QTR_SetShapedTitleText(titleFontString, translatedTitle, QTR_Font1 or QTR_Font2 or Original_Font2, titleSize or 18, titleFontString:GetWidth());
        else
           QTR_RestoreExternalFontState(titleFontString, QTR_StorylineFontState);
           titleFontString:SetText(questTitle or "");
        end
     else
        QTR_RestoreExternalFontState(titleFontString, QTR_StorylineFontState);
        titleFontString:SetText(questTitle or "");
     end
  end

  local sourceText = QTR_GetStorylineBodySourceText(eventName);
  local translatedBody = nil;
  if (eventName == "QUEST_DETAIL" or eventName == "QUEST_PROGRESS" or eventName == "QUEST_COMPLETE") then
     translatedBody = QTR_GetExternalQuestTextTranslationFromSource(questTitle or "", sourceText or "");
  elseif (eventName == "QUEST_GREETING") then
     translatedBody = QTR_GetExternalGossipBodyTranslation(sourceText or "", true);
  elseif (eventName == "GOSSIP_SHOW") then
     translatedBody = QTR_GetExternalGossipBodyTranslation(sourceText or "", true);
  end

  if (Storyline_NPCFrameChat and Storyline_NPCFrameChatText) then
     QTR_GetExternalFontState(Storyline_NPCFrameChatText, QTR_StorylineFontState);
  end

  if (translatedBody and translatedBody ~= "" and Storyline_NPCFrameChat and Storyline_NPCFrameChatText) then
     local translatedTexts = QTR_SplitStorylineTextPages(translatedBody);
     local _, bodySize = Storyline_NPCFrameChatText:GetFont();
     local displayTexts = QTR_PrepareStorylineDisplayPages(translatedTexts, Storyline_NPCFrameChatText:GetWidth(), QTR_Font1 or QTR_Font2 or Original_Font2, bodySize or 16);
     if (#translatedTexts > 0) then
        Storyline_NPCFrameChat.texts = displayTexts;
     end

     local activeTexts = Storyline_NPCFrameChat.texts or {};
     local currentIndex = Storyline_NPCFrameChat.currentIndex or 1;
     local textCount = #activeTexts;
     if (currentIndex < 1) then
        currentIndex = 1;
     end
     if (textCount > 0 and currentIndex > textCount) then
        currentIndex = textCount;
     end
     Storyline_NPCFrameChat.currentIndex = currentIndex;
     if (textCount > 0) then
        local currentText = activeTexts[currentIndex];
        if (currentText and currentText ~= "") then
           local fontName = QTR_Font1 or QTR_Font2 or Original_Font2;
           Storyline_NPCFrameChatText:SetFont(fontName, bodySize or 16);
           Storyline_NPCFrameChatText:SetJustifyH((AS_ContainsArabic and AS_ContainsArabic(currentText)) and "RIGHT" or "LEFT");
           Storyline_NPCFrameChatText:SetText(currentText);
        end
     end
  elseif (Storyline_NPCFrameChat and Storyline_NPCFrameChatText) then
     local originalTexts = QTR_SplitStorylineTextPages(sourceText);
     Storyline_NPCFrameChat.texts = originalTexts;

     local textCount = #originalTexts;
     local currentIndex = Storyline_NPCFrameChat.currentIndex or 1;
     if (currentIndex < 1) then
        currentIndex = 1;
     end
     if (textCount > 0 and currentIndex > textCount) then
        currentIndex = textCount;
     end
     local currentText = (textCount > 0 and originalTexts[currentIndex]) or "";
     QTR_RestoreExternalFontState(Storyline_NPCFrameChatText, QTR_StorylineFontState);
     Storyline_NPCFrameChatText:SetText(currentText or "");
     if (Storyline_NPCFrameChatText.SetAlphaGradient) then
        Storyline_NPCFrameChatText:SetAlphaGradient(string.len(currentText or ""), 1);
     end
     Storyline_NPCFrameChat.start = nil;
  end

  if (Storyline_NPCFrameObjectivesContent) then
     if (Storyline_NPCFrameObjectivesContent.Title and Storyline_NPCFrameObjectivesContent.Title.IsShown and Storyline_NPCFrameObjectivesContent.Title:IsShown()) then
        QTR_GetExternalFontState(Storyline_NPCFrameObjectivesContent.Title, QTR_StorylineFontState);
     end
     if (Storyline_NPCFrameObjectivesContent.RequiredItemText and Storyline_NPCFrameObjectivesContent.RequiredItemText.IsShown and Storyline_NPCFrameObjectivesContent.RequiredItemText:IsShown()) then
        QTR_GetExternalFontState(Storyline_NPCFrameObjectivesContent.RequiredItemText, QTR_StorylineFontState);
     end
     if (Storyline_NPCFrameObjectivesContent.Objectives and Storyline_NPCFrameObjectivesContent.Objectives.IsShown and Storyline_NPCFrameObjectivesContent.Objectives:IsShown()) then
        QTR_GetExternalFontState(Storyline_NPCFrameObjectivesContent.Objectives, QTR_StorylineFontState);
     end

     if (Storyline_NPCFrameObjectivesContent.Title and Storyline_NPCFrameObjectivesContent.Title.IsShown and Storyline_NPCFrameObjectivesContent.Title:IsShown() and QTR_Messages and QTR_Messages.objectives) then
        local _, titleSize = Storyline_NPCFrameObjectivesContent.Title:GetFont();
        QTR_SetShapedText(Storyline_NPCFrameObjectivesContent.Title, QTR_Messages.objectives, QTR_Font1 or QTR_Font2 or Original_Font2, titleSize or 18);
     end
     if (Storyline_NPCFrameObjectivesContent.RequiredItemText and Storyline_NPCFrameObjectivesContent.RequiredItemText.IsShown and Storyline_NPCFrameObjectivesContent.RequiredItemText:IsShown() and QTR_Messages and QTR_Messages.reqitems) then
        local _, reqSize = Storyline_NPCFrameObjectivesContent.RequiredItemText:GetFont();
        QTR_SetShapedText(Storyline_NPCFrameObjectivesContent.RequiredItemText, QTR_Messages.reqitems, QTR_Font1 or QTR_Font2 or Original_Font2, reqSize or 13);
     end

     local objectiveText = QTR_GetExternalQuestObjectivesTranslation(questTitle or "");
     if (objectiveText and Storyline_NPCFrameObjectivesContent.Objectives and Storyline_NPCFrameObjectivesContent.Objectives.IsShown and Storyline_NPCFrameObjectivesContent.Objectives:IsShown()) then
        local _, objectiveSize = Storyline_NPCFrameObjectivesContent.Objectives:GetFont();
        QTR_SetExternalPrefixedText(Storyline_NPCFrameObjectivesContent.Objectives, Storyline_NPCFrameObjectivesContent.Objectives:GetText() or "", objectiveText, QTR_Font1 or QTR_Font2 or Original_Font2, objectiveSize or 13);
     elseif (Storyline_NPCFrameObjectivesContent.Objectives and Storyline_NPCFrameObjectivesContent.Objectives.IsShown and Storyline_NPCFrameObjectivesContent.Objectives:IsShown()) then
        local originalObjectives = QTR_GetStorylineOriginalObjectivesText(eventName, questTitle);
        QTR_RestoreExternalFontState(Storyline_NPCFrameObjectivesContent.Objectives, QTR_StorylineFontState);
        Storyline_NPCFrameObjectivesContent.Objectives:SetText(originalObjectives or "");
     end
  end

  if (Storyline_NPCFrameRewards and Storyline_NPCFrameRewards.IsShown and Storyline_NPCFrameRewards:IsShown() and Storyline_NPCFrameRewards.Content and Storyline_NPCFrameRewards.Content.Title and Storyline_NPCFrameRewards.Content.Title.IsShown and Storyline_NPCFrameRewards.Content.Title:IsShown()) then
     QTR_GetExternalFontState(Storyline_NPCFrameRewards.Content.Title, QTR_StorylineFontState);
     if (QTR_Messages and QTR_Messages.rewards) then
        local _, rewardsSize = Storyline_NPCFrameRewards.Content.Title:GetFont();
        QTR_SetShapedText(Storyline_NPCFrameRewards.Content.Title, QTR_Messages.rewards, QTR_Font1 or QTR_Font2 or Original_Font2, rewardsSize or 18);
     else
        QTR_RestoreExternalFontState(Storyline_NPCFrameRewards.Content.Title, QTR_StorylineFontState);
     end
  end

  QTR_UpdateStorylineDialogButtons();
  QTR_RefreshStorylineFrameLayout();
end


function QTR_TryHookStoryline()
  if (QTR_StorylineHooked or type(IsAddOnLoaded) ~= "function" or not IsAddOnLoaded("Storyline")) then
     return QTR_StorylineHooked;
  end
  if (not Storyline_API or not Storyline_NPCFrame) then
     return false;
  end

  QTR_StorylineHooked = true;

  if (Storyline_API and type(Storyline_API.playNext) == "function") then
     hooksecurefunc(Storyline_API, "playNext", function()
        QTR_RequestStorylineRefresh(0);
     end);
  end

  if (Storyline_NPCFrame and Storyline_NPCFrame.HookScript) then
     Storyline_NPCFrame:HookScript("OnShow", function()
        QTR_RequestStorylineRefresh(0);
     end);
  end

  for _, button in ipairs({ Storyline_NPCFrameChatNext, Storyline_NPCFrameChatPrevious, Storyline_NPCFrameChatOption1, Storyline_NPCFrameChatOption2, Storyline_NPCFrameChatOption3, Storyline_NPCFrameObjectives, Storyline_NPCFrameObjectivesYes, Storyline_NPCFrameObjectivesNo, Storyline_NPCFrameObjectives.OK, Storyline_NPCFrameRewardsItem }) do
     if (button and button.HookScript) then
        button:HookScript("OnClick", function()
           QTR_RequestStorylineRefresh(0);
        end);
     end
  end

  if (Storyline_NPCFrameGossipChoices and Storyline_NPCFrameGossipChoices.HookScript) then
     Storyline_NPCFrameGossipChoices:HookScript("OnShow", function()
        QTR_RequestStorylineRefresh(0);
     end);
     Storyline_NPCFrameGossipChoices:HookScript("OnHide", function()
        QTR_RequestStorylineRefresh(0);
     end);
  end

  QTR_RequestStorylineRefresh(0);
  return true;
end


function QTR_RefreshStorylineLiveView()
  if (not QTR_TryHookStoryline() or not Storyline_NPCFrame or not Storyline_NPCFrame.IsShown or not Storyline_NPCFrame:IsShown()) then
     return;
  end

  QTR_UpdateStorylineFrame();
end


function QTR_RunQueuedStorylineRefresh()
  QTR_StorylineRefreshPending = false;
  if (Storyline_NPCFrame and Storyline_NPCFrame.IsShown and Storyline_NPCFrame:IsShown()) then
     QTR_UpdateStorylineFrame();
  end
end


function QTR_RequestStorylineRefresh(delay)
  if (QTR_StorylineRefreshPending) then
     return;
  end

  QTR_StorylineRefreshPending = true;
  if (not QTR_wait(delay or 0, QTR_RunQueuedStorylineRefresh)) then
     QTR_StorylineRefreshPending = false;
  end
end