-- Define a local name
local appName = "RoleCount"


print ("RoleCount>  Starting up...")





-- Define a local frame to register events if running as an addon

-- 1. Create a parent frame that will be the "anchor" for movement
local frame = CreateFrame("Frame", "RoleCountMoveableTextFrame, UIParent")
frame:SetSize(50,15)
frame:SetPoint("CENTER") -- this sets the default location ... but blizz seems to save it if we move it.

-- 2. Prevent text from being dragged off screen
frame:SetClampedToScreen(true)

-- 3. Create the actual text (FontString) inside that frame
local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
text:SetPoint("CENTER", frame, "CENTER") 
text:SetText("<RoleCount>")                             -- this gets updated later (via events)
text:SetFont("Fonts\\FRIZQT__.TTF", 9)               -- set font size to 9                                       --TODO: Parameterize (default 16)
text:SetTextColor(1.0,1.0,1.0,1.0)                   -- set default to white and fully solid (4th parm)         --TODO: Parameterize 

-- 4. Enable movement for the frame
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")

-- 5. Define drag behavior
frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)





-- Register for an event that fires when the group composition changes
-- GROUP_ROSTER_UPDATE is used for both party and raid updates now
frame:RegisterEvent("GROUP_ROSTER_UPDATE")

-- Set a script to run when the event is triggered
frame:SetScript("OnEvent", function(self, event, ...)
    if DLAPI then DLAPI.DebugLog(appName, "Group roster updated. Scanning members...") end

    local numMembers = GetNumGroupMembers()
    local tankCount = 0
    local healerCount = 0
    local damagerCount = 0

    local resultString="not grouped"


    if numMembers > 0 then 
    local groupMembers={}
    
    --get our instance type
    local _, instanceType = IsInInstance()
    
    if (instanceType ~="raid") then
      --add self to table
      local playerName = UnitName("player")
      table.insert(groupMembers,playerName)
    end

    -- Iterate through each group member
    for i = 1, numMembers do
        -- Construct the unit ID string, e.g., "raid1", "raid2", etc.
        -- Player is included in the "raidN" units
        local unitID = instanceType .. i
        
        --fetch the unit Name
        unitName=UnitName(unitID)
        if unitName ~= nil then
            table.insert(groupMembers,unitName)
        end
    end
    
    for index, unitName in ipairs(groupMembers) do
        local role = UnitGroupRolesAssigned (unitName)
        
        if (role == "TANK") then
            tankCount = tankCount + 1
        elseif(role=="HEALER") then 
            healerCount = healerCount + 1
        elseif(role=="DAMAGER") then
            damagerCount = damagerCount + 1
        end
    end
    
    resultString = tankCount .. " / " .. healerCount .. " / " .. damagerCount
    
    end

    text:SetText(resultString)

end)


-- An initial call can be made upon loading, especially in an addon's OnLoad script
frame:GetScript("OnEvent")(frame, "GROUP_ROSTER_UPDATE")

-- Check if the player is in a group (party or raid) using IsInGroup()
--if IsInGroup() then
    -- Manually trigger the scan when the addon loads, if already in a group
    -- frame:GetScript("OnEvent")(frame, "GROUP_ROSTER_UPDATE")
--end





