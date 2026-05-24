local QTR_ElvUITrackerHooked = false;


local function QTR_IsElvUILoaded()
  return (type(IsAddOnLoaded) == "function" and IsAddOnLoaded("ElvUI"));
end


function QTR_TryHookElvUITracker()
  if (QTR_ElvUITrackerHooked or not QTR_IsElvUILoaded()) then
     return false;
  end
  if (type(hooksecurefunc) ~= "function" or type(WatchFrame_SetLine) ~= "function") then
     return false;
  end

  hooksecurefunc("WatchFrame_SetLine", function(line, anchor, verticalOffset, isHeader, text)
     if (not QTR_IsElvUILoaded() or not isHeader or not text or text == "") then
        return;
     end
     if (not QTR_PS or QTR_PS["active"] ~= "1" or QTR_PS["transtitle"] ~= "1") then
        return;
     end

     local originalTitle = QTR_GetQuestTitleFromDisplayText(text);
     if (not originalTitle) then
        return;
     end

     QTR_ApplyWatchFrameQuestTitle(line, nil, originalTitle, text);
  end);

  QTR_ElvUITrackerHooked = true;
  return true;
end