
-- Constants
MAX_TALENT_TABS = 3
MAX_TALENTS_PER_TAB = 20
MAX_TALENT_TIERS = 7
MAX_TALENTS_PER_TIER = 4
MAX_TALENT_RANK = 5

-- Keep track of which tab is selected
local selectedTab = 1
local playerTalentPoints = 0
local talentAvailable = false

function TalentFrame_Toggle()
    if (TalentFrame:IsVisible()) then
        HideUIPanel(TalentFrame);
    else
        ShowUIPanel(TalentFrame);
    end
end

function TalentFrame_OnLoad(self)
    -- Initialize side panel functionality first, like the close button
    SidePanel_OnLoad(self);
    
    -- Set title
    self:GetChild(0):SetText(Localize("TALENTS"));
    
    -- Register events
    self:RegisterEvent("PLAYER_TALENT_UPDATE", TalentFrame_Update);
    self:RegisterEvent("PLAYER_LEVEL_UP", TalentFrame_Update);
    self:RegisterEvent("PLAYER_ENTER_WORLD", TalentFrame_Update);
    
    -- Clear talent display first
    for i=1, MAX_TALENTS_PER_TAB do
        local button = _G["TalentFrameTalent"..i];
        button:SetOnEnterHandler(TalentFrameTalent_OnEnter);
        button:SetOnLeaveHandler(TalentFrameTalent_OnLeave);
    end

    -- Add button to menu bar
    AddMenuBarButton("Interface/Icons/fg4_icons_emblemShield_result.htex", TalentFrame_Toggle);
end

function TalentFrame_OnShow(self)
    TalentFrame_Update(self);
end

function TalentFrame_Update(self)
    -- Get player's available talent points
    local player = GetUnit("player");
    playerTalentPoints = player:GetTalentPoints() or 0;
    
    -- Update talent point display
    TalentFramePointsText:SetText(Localize("TALENT_POINTS") .. ": " .. playerTalentPoints);
    
    -- Update and display tab information
    TalentFrame_UpdateTabs();
    
    -- Update talents for the selected tab
    TalentFrame_UpdateTalents();
end

function TalentFrame_UpdateTabs()
    -- Get the class tabs info
    local numTabs = GetNumTalentTabs();
    
    -- Show/hide the tabs based on availability
    for i=1, MAX_TALENT_TABS do
        local tabButton = _G["TalentFrameTab"..i];
        
        if (i <= numTabs) then
            local tabInfo = GetTalentTabName(i - 1);
            tabButton:SetText(tabInfo);
            tabButton:Show();
            
            -- Highlight selected tab
            if (i == selectedTab) then
                --tabButton:SetSelected(true)
            else
                --tabButton:SetSelected(false)
            end
        else
            -- Hide unused tabs
            tabButton:Hide();
        end
    end
end

function TalentFrameTab_OnClick(self)
    local id = self.id;

    if (id ~= selectedTab) then
        selectedTab = id;
        TalentFrame_Update(TalentFrame);
    end
end

function TalentFrame_UpdateTalents()
    -- Get the talents for the selected tab
    local numTalents = GetNumTalents(selectedTab);
    
    -- Clear talent display first
    for i=1, MAX_TALENTS_PER_TAB do
        local button = _G["TalentFrameTalent"..i];
        button:Hide();
    end
    
    -- Display the talents
    for i=1, numTalents do
        local talent = GetTalentInfo(selectedTab, i - 1);

        -- Calculate button index from tier and column
        local index = (talent.tier * MAX_TALENTS_PER_TIER) + talent.column + 1;
        local button = _G["TalentFrameTalent"..index];
        
        button.id = i;
        button.tabID = selectedTab;
        button.tier = talent.tier;
        button.column = talent.column;
        button.spell = talent.spell;
        
        -- Set the icon
        button:SetProperty("Icon", talent.icon or "");
        
        -- Set the rank overlay
        local rankFrame = _G["TalentFrameTalent"..i.."_Rank"];
        if rankFrame then
            rankFrame:SetText(string.format("%d/%d", talent.rank, talent.maxRank));
        end
        
        -- Color the talent based on whether it can be trained
        talentAvailable = false;--CanTrainTalent(talent, playerTalentPoints)
        if (talent.rank == talent.maxRank) then
            -- Max rank, show as normal
            --button:SetState("Normal")
            --rankFrame:SetTextColor(1.0, 0.82, 0)  -- Yellow for max rank
        elseif (talentAvailable) then
            -- Available to train
            --button:SetState("Highlighted")
            --rankFrame:SetTextColor(0, 1.0, 0)  -- Green for available
        else
            -- Not available to train
            --button:SetState("Disabled")
            --rankFrame:SetTextColor(0.5, 0.5, 0.5)  -- Grey for unavailable
        end
        
        -- Show the button
        button:Show();
        
        -- Update branch lines
        TalentFrame_UpdateBranches(button, talent);
    end
end

function TalentFrame_UpdateBranches(button, talent)
    -- Update the arrow connections between talents based on prerequisites
    if not talent.prerequisite then return end;
    
    -- Find parent button
    local parentButton = nil;
    for i=1, MAX_TALENTS_PER_TAB do
        local possibleParent = _G["TalentFrameTalent"..i]
        if (possibleParent.id == talent.prerequisite) then;
            parentButton = possibleParent;
            break;
        end
    end
    
    if not parentButton then return end;
    
    -- Calculate positions
    local left = min(button.column, parentButton.column);
    local right = max(button.column, parentButton.column);
    local top = min(button.tier, parentButton.tier);
    local bottom = max(button.tier, parentButton.tier);
    local horizontalDistance = right - left;
    local verticalDistance = bottom - top;
    
    -- Setup branch graphics here between interconnected talents
    if horizontalDistance > 0 and verticalDistance > 0 then
        -- Diagonal connections
    elseif horizontalDistance > 0 then
        -- Horizontal connections
    else
        -- Vertical connections
    end
end

function TalentFrameTalent_OnClick(self)
    if (playerTalentPoints > 0) then
        local talentID = self.id;
        local tabID = self.tabID;
        
        -- Learn the talent (in a real implementation, this would call server)
        local result = false;--LearnTalent(talentID)
        
        if (result) then
            -- Update display after learning
            TalentFrame_Update(TalentFrame);
        end
    end
end

function TalentFrameTalent_OnEnter(self)
    local talentID = self.id;
    local talent = GetTalentInfo(selectedTab, talentID - 1);

    if not talent then
        return
    end;

    GameTooltip:ClearAnchors();
    GameTooltip:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, self, 0);
    GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.RIGHT, self, 0);
    GameTooltip_SetSpell(talent.spell);
    GameTooltip:Show()
end

function TalentFrameTalent_OnLeave(self)
    GameTooltip:Hide();
end
