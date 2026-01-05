-- Define a local name
local appName = "RoleCount"



-- ****************************************************************
-- * BASE DEFINITIONS FOR OUR ADDON AND VARIOUS CALLBAKCS
-- ****************************************************************
local defaultPosition = {
	point = 'CENTER',
	x = 0,
	y = 0,
}

local defaultColour = {
    r = 1,
    g = 1,
    b = 1,
    a = 1
}



local function onPositionChanged(frame, layoutName, point, x, y)
	-- from here you can save the position into a savedvariable
	RoleCountDB[layoutName].point = point
	RoleCountDB[layoutName].x = x
	RoleCountDB[layoutName].y = y
end



-- Create a parent frame that will be the "anchor" for movement.  This is also where we'll register events
local roleCountFrame = CreateFrame("Frame", "RoleCount", UIParent)
roleCountFrame:SetSize(75,15)
roleCountFrame:SetClampedToScreen(true)                                              -- Prevent text from being dragged off screen

-- Create the actual text (FontString) inside that frame
local roleCountText = roleCountFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
roleCountText:SetPoint("CENTER", roleCountFrame, "CENTER") 
roleCountText:SetText("-[ " .. appName .. " ]-")                                      -- this gets updated later (via events)
--roleCountText:SetFont("Fonts\\FRIZQT__.TTF", 16)                                      -- we won't have options to change the font size, because we've got a scaler.  And this is the default font.
--roleCountText:SetTextColor(1.0,1.0,1.0,1.0)                                           -- set default to white and fully solid (4th parm)         --TODO: Parameterize 






-- Register for an event that fires when the group composition changes
-- GROUP_ROSTER_UPDATE is used for both party and raid updates now
roleCountFrame:RegisterEvent("GROUP_ROSTER_UPDATE")

-- Set a script to run when the event is triggered
roleCountFrame:SetScript("OnEvent", function(self, event, ...)
    if DLAPI then DLAPI.DebugLog(appName, "Group roster updated. Scanning members...") end

    local numMembers = GetNumGroupMembers()
    local tankCount = 0
    local healerCount = 0
    local damagerCount = 0

    local resultString="" -- make it 'disappear'


    if numMembers > 0 then 
    local groupMembers={}
    
    --get our instance type
    local _, instanceType = IsInInstance()
    
    if (instanceType ~="raid") then
      --add self to table when not in a raid 
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

     roleCountText:SetText(resultString)
end)






-- ****************************************************************
-- * DEFINE AND SETUP OUR LIB EDIT MODE REFERENCES
-- ****************************************************************
local LEM = LibStub('LibEditMode')

-- additional (anonymous) callbacks
LEM:RegisterCallback('enter', function()
	-- from here you can show your button if it was hidden
    roleCountText:SetText("9 / 9 / 99")
end)
LEM:RegisterCallback('exit', function()
	-- from here you can hide your button if it's supposed to be hidden
    roleCountFrame:GetScript("OnEvent")(roleCountFrame, "GROUP_ROSTER_UPDATE")
end)
LEM:RegisterCallback('layout', function(layoutName)
	-- this will be called every time the Edit Mode layout is changed (which also happens at login),
	-- use it to load the saved button position from savedvariables and position it
    if not RoleCountDB then
		RoleCountDB = {}
	end
	if not RoleCountDB[layoutName] then
		RoleCountDB[layoutName] = CopyTable(defaultPosition)
        RoleCountDB[layoutName].scale = 1
        RoleCountDB[layoutName].colour = CreateColor(defaultColour.r, defaultColour.g, defaultColour.b, defaultColour.a)
	end

	roleCountFrame:ClearAllPoints()
	roleCountFrame:SetPoint(RoleCountDB[layoutName].point, RoleCountDB[layoutName].x, RoleCountDB[layoutName].y)
    roleCountFrame:SetScale(RoleCountDB[layoutName].scale)
    local colour = CreateColor(RoleCountDB[layoutName].colour.r, RoleCountDB[layoutName].colour.g, RoleCountDB[layoutName].colour.b, RoleCountDB[layoutName].colour.a)
    roleCountText:SetTextColor(colour.r, colour.g, colour.b, colour.a)

    -- force a refresh of the roleCounts
    roleCountFrame:GetScript("OnEvent")(frame, "GROUP_ROSTER_UPDATE")
end)

LEM:AddFrame(roleCountFrame, onPositionChanged, defaultPosition)

LEM:AddFrameSettings(roleCountFrame, {
	{
        name = 'Scale',
		kind = LEM.SettingType.Slider,
		default = 1,
		get = function(layoutName)
			return RoleCountDB[layoutName].scale
		end,
		set = function(layoutName, value)
			RoleCountDB[layoutName].scale = value
			roleCountFrame:SetScale(value)
		end,
		minValue = 0.1,
		maxValue = 5,
		valueStep = 0.1,
		formatter = function(value)
			return FormatPercentage(value, true)
		end,
	}
,
    {
        name = 'Color',
        kind = LEM.SettingType.ColorPicker,
        get = function(layoutName)
            local colour = CreateColor(RoleCountDB[layoutName].colour.r, RoleCountDB[layoutName].colour.g, RoleCountDB[layoutName].colour.b, RoleCountDB[layoutName].colour.a)
            return colour
        end,
        set = function(layoutName, value)
            --local colour = CreateColor(value.r, value.g, value.b, value.a)
            local colour = {
                r = value.r,
                g = value.g,
                b = value.b,
                a = value.c
            }

            
            RoleCountDB[layoutName].colour = colour
            roleCountText:SetTextColor(colour.r, colour.g, colour.b, colour.a)
        end, 
        hasOpacity = false,
    }
})









