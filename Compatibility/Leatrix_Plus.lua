local QTR_LeatrixPlusHooked = false;
local QTR_LeatrixPlusQuestLogRefreshPending = false;


local function QTR_IsLeatrixPlusLoaded()
  if (type(IsAddOnLoaded) == "function" and IsAddOnLoaded("Leatrix_Plus")) then
	  return true;
  end

  return (type(LeaPlusDB) == "table");
end


local function QTR_RunLeatrixPlusQuestLogRefresh()
  QTR_LeatrixPlusQuestLogRefreshPending = false;

  if (type(QTR_UpdateQuestLogTitleButtons) == "function") then
	  QTR_UpdateQuestLogTitleButtons();
  end

  if (type(QTR_ShowAndUpdateQuestInfo) == "function" and QuestLogFrame and QuestLogFrame.IsVisible and QuestLogFrame:IsVisible()) then
	  QTR_ShowAndUpdateQuestInfo();
  end
end


function QTR_RequestLeatrixPlusQuestLogRefresh()
  if (QTR_LeatrixPlusQuestLogRefreshPending) then
	  return false;
  end

  QTR_LeatrixPlusQuestLogRefreshPending = true;
  if (not QTR_wait or not QTR_wait(0, QTR_RunLeatrixPlusQuestLogRefresh)) then
	  QTR_RunLeatrixPlusQuestLogRefresh();
  end

  return true;
end


function QTR_TryHookLeatrixPlus()
  if (QTR_LeatrixPlusHooked or not QTR_IsLeatrixPlusLoaded()) then
	  return false;
  end
  if (type(hooksecurefunc) ~= "function") then
	  return false;
  end

  if (type(QuestLogTitleButton_Resize) == "function") then
	  hooksecurefunc("QuestLogTitleButton_Resize", function(titleButton)
		  if (not QTR_IsLeatrixPlusLoaded() or not titleButton or not titleButton.GetName) then
			  return;
		  end

		  local titleButtonName = titleButton:GetName();
		  if (titleButtonName and string.find(titleButtonName, "^QuestLogScrollFrameButton")) then
			  QTR_RequestLeatrixPlusQuestLogRefresh();
		  end
	  end);
  end

  if (type(QuestLog_Update) == "function") then
	  hooksecurefunc("QuestLog_Update", function()
		  if (QTR_IsLeatrixPlusLoaded()) then
			  QTR_RequestLeatrixPlusQuestLogRefresh();
		  end
	  end);
  end

  if (QuestLogScrollFrameScrollBar and QuestLogScrollFrameScrollBar.HookScript) then
	  QuestLogScrollFrameScrollBar:HookScript("OnValueChanged", function()
		  if (QTR_IsLeatrixPlusLoaded()) then
			  QTR_RequestLeatrixPlusQuestLogRefresh();
		  end
	  end);
  end

  if (QuestLogFrame and QuestLogFrame.HookScript) then
	  QuestLogFrame:HookScript("OnShow", function()
		  if (QTR_IsLeatrixPlusLoaded()) then
			  QTR_RequestLeatrixPlusQuestLogRefresh();
		  end
	  end);
  end

  QTR_LeatrixPlusHooked = true;
  QTR_RequestLeatrixPlusQuestLogRefresh();
  return true;
end


function QTR_RefreshLeatrixPlusQuestLog()
  QTR_TryHookLeatrixPlus();
  if (QTR_IsLeatrixPlusLoaded()) then
	  QTR_RequestLeatrixPlusQuestLogRefresh();
  end
end
