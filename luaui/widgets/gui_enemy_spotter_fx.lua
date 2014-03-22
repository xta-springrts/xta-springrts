function widget:GetInfo()
   return {
      name      = "EnemySpotter FX",
      desc      = "Generates highlighted, stylized donuts around enemy units (Press ctrl+f11 for options)",
      author    = "Floris",
      date      = "22,Jan,2014",
      license   = "GNU GPL, v2 or later",
      layer     = 5,
      enabled   = false  --  loaded by default?
   }
end

--------------------------------------------------------------------------------
-- Config
--------------------------------------------------------------------------------

local activateWithNumberAllyTeams     = 1       -- (number of teams)   if number >= total number of enemy teams then enable this FX effect
local defaultColorsForAllyTeams       = 0       -- (number of teams)   if number <= total number of allyTeams then dont use teamcoloring but the default colors
local keepTeamColorsForSmallAllyTeam  = 3       -- (number of teams)   use teamcolors if number or teams (inside allyTeam)  <=  this value
local renderAllTeamsAsSpec            = true	--
local renderAllTeamsAsPlayer          = false	--
local drawWithHiddenGUI               = true    -- keep widget enabled when graphical user interface is hidden (when pressing F5)
local circleSize                      = 1
local showUnitNames                   = false   -- renders the unit (human)name above the spotter

local spotterColor = {                          -- default color values (when not picking the color from a player)
{0,0,1} , {1,0,0} , {0,1,1} , {0,1,0} , {1,0.5,0} , {0,1,1} , {1,1,0} , {1,1,1} , {0.5,0.5,0.5} , {0,0,0} , {0.5,0,0} , {0,0.5,0} , {0,0,0.5} , {0.5,0.5,0} , {0.5,0,0.5} , {0,0.5,0.5} , {1,0.5,0.5} , {0.5,0.5,0.1} , {0.5,0.1,0.5},
}

-- basic ground circle
local showBase                        = true
local baseOpacity                     = 0.17
local baseParts                       = 12      -- how many sided circle?
local baseOuterSize                   = 1.30    -- outer fade size compared to circle scale (1 = no outer fade)

-- fx ground circle
local showFx                          = true
local fxOpacity                       = 1.8
local fxDetailOffset                  = false
local fxRandomize                     = false   -- note: if you want to change the ranges of the randomized properties then just search this document for 'math.random'
local fxPartsMultiplier               = 0.75    -- parts * multiplier = number of parts
local useTrueskill                    = true    -- use a players trueskill value for the number of circle divs that will be showed
local trueskillLowest                 = 12      -- set the lowest common known trueskill value (to distinct better between the low and high ts players. Keep in mind minimal displayed trueskill fx parts are 3)
local trueskillPartsFixedWidth        = true    -- to keep the same width for each part (only used for non randomized fx)

-- fx defaults (when not randomized)
local fxParts                         = 25
local fxWidth                         = 0.2    -- 1 = 100%
local fxInnerSize	                  = 0.35
local fxInnerOpacityStart             = 0
local fxInnerOpacity                  = 0.14
local fxOuterSize	                  = 0.31
local fxOuterOpacity                  = 0.14
local fxOuterOpacityEnd               = 0
local rotationSpeed                   = 0.08

-- tweak ui
local buttonsize					  = 18
local rowgap						  = 6
local leftmargin					  = 20
local buttontab						  = 200
local vsx, vsy 						  = gl.GetViewSizes()
local tweakUiWidth, tweakUiHeight	  = 240, 305
local tweakUiPosX, tweakUiPosY		  = 500, 220

-- images
local optContrast			          = "LuaUI/Images/enemyspotter/contrast.png"
local optMinPlus			              = "LuaUI/Images/enemyspotter/minplus.png"
local optCheckBoxOn			          = "LuaUI/Images/enemyspotter/chkBoxOn.png"
local optCheckBoxOff			      = "LuaUI/Images/enemyspotter/chkBoxOff.png"


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local glDrawListAtUnit        = gl.DrawListAtUnit

local gaiaTeamID              = Spring.GetGaiaTeamID()
local myTeamID                = Spring.GetLocalTeamID()
local myAllyID                = Spring.GetMyAllyTeamID()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local realRadii                 = {}
local circlePolys               = {}
local circleValues              = {}
local playerSpecialFxGl         = {}
local allyToSpotterColor        = {}
local rotationAngles            = {}
local currentRotationAngle      = 0
local renderSpotters            = false
local previousOsClock           = 0
local sceduleRandomize          = false
local sceduleFxPartsMultiplier  = false
local sceduleTrueskill          = false
local allyToSpotterColorCount   = 0
local Button				    = {}
local Panel					    = {}
local skipOwnAllyTeam           = true
local oldFxPartsMultiplier      = 1

local parts, width, usedSpotterColor, innerSize, outerSize, factor, unitDefIDValue, a1,a2,a3, radius, dims, scale, ud, visibleUnits, numberOfVisibleUnits

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function widget:GetConfigData(data)
    savedTable = {}
    savedTable.showBase                = showBase
    savedTable.showFx                  = showFx
    savedTable.fxDetailOffset          = fxDetailOffset
    savedTable.fxRandomize             = fxRandomize
    savedTable.useTrueskill            = useTrueskill
    savedTable.renderAllTeamsAsSpec    = renderAllTeamsAsSpec
    savedTable.renderAllTeamsAsPlayer  = renderAllTeamsAsPlayer
    savedTable.showUnitNames           = showUnitNames
    savedTable.baseOpacity             = baseOpacity
    savedTable.fxOpacity               = fxOpacity
    savedTable.fxPartsMultiplier       = fxPartsMultiplier
    return savedTable
end

function widget:SetConfigData(data)
    if data.showBase ~= nil                 then  showBase               = data.showBase end
    if data.showFx ~= nil                   then  showFx                 = data.showFx end
    if data.fxDetailOffset ~= nil           then  fxDetailOffset         = data.fxDetailOffset end
    if data.fxRandomize ~= nil              then  fxRandomize            = data.fxRandomize end
    if data.useTrueskill ~= nil             then  useTrueskill           = data.useTrueskill end
    if data.renderAllTeamsAsSpec ~= nil     then  renderAllTeamsAsSpec   = data.renderAllTeamsAsSpec end
    if data.renderAllTeamsAsPlayer ~= nil   then  renderAllTeamsAsPlayer   = data.renderAllTeamsAsPlayer end
    if data.showUnitNames ~= nil            then  showUnitNames          = data.showUnitNames end
    baseOpacity        = data.baseOpacity       or baseOpacity
    fxOpacity          = data.fxOpacity         or fxOpacity
    fxPartsMultiplier  = data.fxPartsMultiplier or fxPartsMultiplier
end


local function CreateFxValues()
    allyTeamList = Spring.GetAllyTeamList()
    numberOfAllyTeams = #allyTeamList
    for allyTeamListIndex = 1, numberOfAllyTeams do
        allyID                       = allyTeamList[allyTeamListIndex]
        allyToSpotterColorCount      = allyToSpotterColorCount+1
        allyToSpotterColor[allyID]   = allyToSpotterColorCount
        usedSpotterColor             = spotterColor[allyToSpotterColorCount]
        pickedTeamColor              = {1,1,1}

        teamList = Spring.GetTeamList(allyID)
        for teamListIndex = 1, #teamList do
            teamID = teamList[teamListIndex]
            if teamID ~= gaiaTeamID then
                values = {}
                if circleValues[teamID] ~= nil then
                    values = circleValues[teamID]
                end
                -- randomize circle properties
                if not sceduleTrueskill then
                    if not sceduleFxPartsMultiplier then
                        if fxRandomize and sceduleRandomize then
                            values['width']              = math.random(3,14)/20
                            values['parts']              = round(math.random(8,22) * fxPartsMultiplier, 0)
                            values['innerSize']          = math.random(20,47) / 100
                            values['outerSize']          = math.random(1,35)/100
                            values['innerOpacityStart']  = math.random(0,25)/55 * (values['innerSize'])
                            values['innerOpacity']       = 0.07 / (values['width'] + ((1 - values['width'])/2))
                            values['outerOpacity']       = values['innerOpacity']
                            values['outerOpacityEnd']    = math.random(0,25)/55 * (values['outerSize'])
                            values['rotationSpeed']      = math.random(8,12)/100
                            if (math.random(0,1) == 0) then
                                values['rotationSpeed'] = values['rotationSpeed'] - (values['rotationSpeed']*2)
                            end
                        else
                            values['width']              = fxWidth
                            values['parts']              = round(fxParts * fxPartsMultiplier, 0)
                            values['innerSize']          = fxInnerSize
                            values['outerSize']          = fxOuterSize
                            values['innerOpacityStart']  = fxInnerOpacityStart
                            values['innerOpacity']       = fxInnerOpacity
                            values['outerOpacity']       = values['innerOpacity']
                            values['outerOpacityEnd']    = fxOuterOpacityEnd
                            values['rotationSpeed']      = rotationSpeed
                        end
                    else
                        oldParts = values['parts']
                        values['parts'] = round(values['parts'] * (1 + (fxPartsMultiplier - oldFxPartsMultiplier)), 0)
                        if values['parts'] == oldParts  and  (fxPartsMultiplier - oldFxPartsMultiplier) > 0 then
                            values['parts'] = values['parts'] + 1
                        end
                        if values['parts'] > 3  and  values['parts'] == oldParts  and  (fxPartsMultiplier - oldFxPartsMultiplier) < 0 then
                            values['parts'] = values['parts'] - 1
                        end
                    end
                end

                if useTrueskill then
                    trueskill = GetSkill(teamID)
                    if trueskill ~= nil then
                        values['trueskill'] = trueskill
                        values['parts'] = round(((trueskill-trueskillLowest) * 0.75), 0)
                        if values['parts'] < 3 then
                            values['parts'] = 3
                        end
                        if trueskillPartsFixedWidth  and  not fxRandomize  then
                            values['width'] = values['parts'] / 80
                        end
                    end
                end
                circleValues[teamID]  = values
            end
        end
    end
    if sceduleFxPartsMultiplier then
        sceduleFxPartsMultiplier = false
    end
    if sceduleTrueskill then
        sceduleTrueskill = false
    end
    if fxRandomize and sceduleRandomize then
        sceduleRandomize = false
    end
end


local function drawSpottersFx()
   radstep = (2.0 * math.pi) / parts
   for i = 1, parts do
       a1 = (i * radstep)
       a2 = ((i+width) * radstep)
       a3 = ((i+(width/2)) * radstep)

       fxSpotterColor = usedSpotterColor
       innerSize = 1 - circleValues[teamID].innerSize
       outerSize = 1 + circleValues[teamID].outerSize
       --inner (fadein)
       gl.Color(fxSpotterColor[1], fxSpotterColor[2], fxSpotterColor[3], circleValues[teamID].innerOpacityStart)
       gl.Vertex(math.sin(a3)*innerSize, 1, math.cos(a3)*innerSize)
       gl.Vertex(math.sin(a3)*innerSize, 1, math.cos(a3)*innerSize)
       --inner (fadeout)
       gl.Color(fxSpotterColor[1], fxSpotterColor[2], fxSpotterColor[3], ((circleValues[teamID].innerOpacity) * fxOpacity))
       gl.Vertex(math.sin(a1), 1, math.cos(a1))
       gl.Vertex(math.sin(a2), 1, math.cos(a2))

       --outer (fadein)
       gl.Vertex(math.sin(a2), 1, math.cos(a2))
       gl.Vertex(math.sin(a1), 1, math.cos(a1))
       --outer (fadeout)
       gl.Color(fxSpotterColor[1], fxSpotterColor[2], fxSpotterColor[3], circleValues[teamID].outerOpacityEnd)
       gl.Vertex(math.sin(a3)*outerSize, 0, math.cos(a3)*outerSize)
       gl.Vertex(math.sin(a3)*outerSize, 0, math.cos(a3)*outerSize)

       if fxDetailOffset then
           i = i + 0.5

           --detailSpotterColor = {usedSpotterColor[1]/1.5, usedSpotterColor[2]/1.5, usedSpotterColor[3]/1.5}
           detailSpotterColor = usedSpotterColor
           fxOffsetOpacity = fxOpacity
           innerSize = 1 - (circleValues[teamID].innerSize/1.55)
           outerSize = 1 + (circleValues[teamID].outerSize/1.55)
           a1 = (i * radstep)+(width/parts)
           a2 = ((i+(width)) * radstep)-((width/parts))
           a3 = ((i+(width/2)) * radstep)

           factor = 0.1
           --inner (fadein)
           gl.Color(detailSpotterColor[1], detailSpotterColor[2], detailSpotterColor[3], circleValues[teamID].innerOpacityStart)
           gl.Vertex(math.sin(a3)*(innerSize+(innerSize*factor)), 1, math.cos(a3)*(innerSize+(innerSize*factor)))
           gl.Vertex(math.sin(a3)*(innerSize+(innerSize*factor)), 1, math.cos(a3)*(innerSize+(innerSize*factor)))
           --inner (fadeout)
           gl.Color(detailSpotterColor[1], detailSpotterColor[2], detailSpotterColor[3], (circleValues[teamID].innerOpacity * fxOffsetOpacity) + 0.05)
           gl.Vertex(math.sin(a1), 1, math.cos(a1))
           gl.Vertex(math.sin(a2), 1, math.cos(a2))

           factor = factor * 0.5
           --outer (fadein)
           gl.Vertex(math.sin(a2), 1, math.cos(a2))
           gl.Vertex(math.sin(a1), 1, math.cos(a1))
           --outer (fadeout)
           gl.Color(detailSpotterColor[1], detailSpotterColor[2], detailSpotterColor[3], circleValues[teamID].outerOpacityEnd)
           gl.Vertex(math.sin(a3)*(outerSize-(outerSize*factor)), 0, math.cos(a3)*(outerSize-(outerSize*factor)))
           gl.Vertex(math.sin(a3)*(outerSize-(outerSize*factor)), 0, math.cos(a3)*(outerSize-(outerSize*factor)))
       end
   end
end


local function drawSpottersFxDetail()
   radstep = (2.0 * math.pi) / parts
   for i = 1, parts do
       detailSpotterColor = usedSpotterColor
       innerSize = 1 - (circleValues[teamID].innerSize/1.5)
       outerSize = 1 + (circleValues[teamID].outerSize/1.5)
       a1 = (i * radstep)+(width/parts)*1.2
       a2 = ((i+(width)) * radstep)-((width/parts)*1.05)
       a3 = ((i+(width/2)) * radstep)

       factor = 0.1
       --inner (fadein)
       gl.Color(detailSpotterColor[1], detailSpotterColor[2], detailSpotterColor[3], circleValues[teamID].innerOpacityStart)
       gl.Vertex(math.sin(a3)*(innerSize+(innerSize*factor)), 1, math.cos(a3)*(innerSize+(innerSize*factor)))
       gl.Vertex(math.sin(a3)*(innerSize+(innerSize*factor)), 1, math.cos(a3)*(innerSize+(innerSize*factor)))
       --inner (fadeout)
       gl.Color(detailSpotterColor[1], detailSpotterColor[2], detailSpotterColor[3], (circleValues[teamID].innerOpacity * fxOpacity) + 0.05)
       gl.Vertex(math.sin(a1), 1, math.cos(a1))
       gl.Vertex(math.sin(a2), 1, math.cos(a2))

       factor = factor * 0.5
       --outer (fadein)
       gl.Vertex(math.sin(a2), 1, math.cos(a2))
       gl.Vertex(math.sin(a1), 1, math.cos(a1))
       --outer (fadeout)
       gl.Color(detailSpotterColor[1], detailSpotterColor[2], detailSpotterColor[3], circleValues[teamID].outerOpacityEnd)
       gl.Vertex(math.sin(a3)*(outerSize-(outerSize*factor)), 0, math.cos(a3)*(outerSize-(outerSize*factor)))
       gl.Vertex(math.sin(a3)*(outerSize-(outerSize*factor)), 0, math.cos(a3)*(outerSize-(outerSize*factor)))

       if fxDetailOffset then
           i = i + 0.5

           --detailSpotterColor = {usedSpotterColor[1]/1.5, usedSpotterColor[2]/1.5, usedSpotterColor[3]/1.5}
           detailSpotterColor = usedSpotterColor
           fxOffsetOpacity = fxOpacity
           innerSize = 1 - (circleValues[teamID].innerSize/2.35)
           outerSize = 1 + (circleValues[teamID].outerSize/2.35)
           a1 = (i * radstep)+(width/parts)*1.7
           a2 = ((i+(width)) * radstep)-((width/parts)*1.5)
           a3 = ((i+(width/2)) * radstep)

           factor = 0.1
           --inner (fadein)
           gl.Color(detailSpotterColor[1], detailSpotterColor[2], detailSpotterColor[3], circleValues[teamID].innerOpacityStart)
           gl.Vertex(math.sin(a3)*(innerSize+(innerSize*factor)), 1, math.cos(a3)*(innerSize+(innerSize*factor)))
           gl.Vertex(math.sin(a3)*(innerSize+(innerSize*factor)), 1, math.cos(a3)*(innerSize+(innerSize*factor)))
           --inner (fadeout)
           gl.Color(detailSpotterColor[1], detailSpotterColor[2], detailSpotterColor[3], (circleValues[teamID].innerOpacity * fxOffsetOpacity) + 0.05)
           gl.Vertex(math.sin(a1), 1, math.cos(a1))
           gl.Vertex(math.sin(a2), 1, math.cos(a2))

           factor = factor * 0.5
           --outer (fadein)
           gl.Vertex(math.sin(a2), 1, math.cos(a2))
           gl.Vertex(math.sin(a1), 1, math.cos(a1))
           --outer (fadeout)
           gl.Color(detailSpotterColor[1], detailSpotterColor[2], detailSpotterColor[3], circleValues[teamID].outerOpacityEnd)
           gl.Vertex(math.sin(a3)*(outerSize-(outerSize*factor)), 0, math.cos(a3)*(outerSize-(outerSize*factor)))
           gl.Vertex(math.sin(a3)*(outerSize-(outerSize*factor)), 0, math.cos(a3)*(outerSize-(outerSize*factor)))
       end
   end
end


local function drawSpottersBaseInner()
   radstep = (2.0 * math.pi) / baseParts
   for i = 1, baseParts do
       a1 = (i * radstep)
       a2 = ((i+1) * radstep)
       --(fadefrom)
       gl.Color(usedSpotterColor[1], usedSpotterColor[2], usedSpotterColor[3], 0)
       gl.Vertex(0, 0, 0)
       --(colorSet)
       gl.Color(usedSpotterColor[1], usedSpotterColor[2], usedSpotterColor[3], baseOpacity)
       gl.Vertex(math.sin(a1), 0, math.cos(a1))
       gl.Vertex(math.sin(a2), 0, math.cos(a2))
   end
end


local function drawSpottersBaseOuter()
   radstep = (2.0 * math.pi) / baseParts
   for i = 1, baseParts do
       a1 = (i * radstep)
       a2 = ((i+1) * radstep)
       --(colorSet)
       gl.Color(usedSpotterColor[1], usedSpotterColor[2], usedSpotterColor[3], baseOpacity)
       gl.Vertex(math.sin(a1), 0, math.cos(a1))
       gl.Vertex(math.sin(a2), 0, math.cos(a2))
       --(fadeto)
       gl.Color(usedSpotterColor[1], usedSpotterColor[2], usedSpotterColor[3], 0)
       gl.Vertex(math.sin(a2)*baseOuterSize, 0, math.cos(a2)*baseOuterSize)
       gl.Vertex(math.sin(a1)*baseOuterSize, 0, math.cos(a1)*baseOuterSize)
   end
end


local function drawSpotters()

   if showBase then
       gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)      -- disable layer blending
       gl.BeginEnd(GL.TRIANGLES, drawSpottersBaseInner)

       if baseOuterSize ~= 1 then
           gl.BeginEnd(GL.QUADS, drawSpottersBaseOuter)
       end
   end

   if showFx then
       parts = circleValues[teamID].parts
       width = circleValues[teamID].width
       if fxDetailOffset then                   -- because then the fxDetails are on the amounth of parts are doubled, we have to compensate that a little bit
           parts = round(parts / 1.5), 0
           width = width / 1.5
       end
       if circleValues[teamID] ~= nil then
           gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)      -- disable layer blending
           --gl.Blending(GL.SRC_ALPHA, GL.ONE)      -- add layer blending
           gl.BeginEnd(GL.QUADS, drawSpottersFx)

           --gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)      -- disable layer blending
           gl.Blending(GL.SRC_ALPHA, GL.ONE)      -- add layer blending
           gl.BeginEnd(GL.QUADS, drawSpottersFxDetail)
       end
   end
end



local function CreateEnemyspotterGl(updateFxValues)
    if baseOpacity < 0 then
        baseOpacity = 0
    end
    if fxOpacity < 0 then
        fxOpacity = 0
    end
    if fxPartsMultiplier < 0.2 then
       fxPartsMultiplier = 0.2
    end

    if updateFxValues then
        callfunction = CreateFxValues()
    end

   allyTeamList = Spring.GetAllyTeamList()
   numberOfAllyTeams = #allyTeamList
   numberOfAllyTeamsSpotters = numberOfAllyTeams-1       --   -1 for gaia
   if skipOwnAllyTeam then
      numberOfAllyTeamsSpotters = numberOfAllyTeamsSpotters - 1
   end
   if numberOfAllyTeamsSpotters >= activateWithNumberAllyTeams then
      renderSpotters = true
   end
   if renderSpotters then

      allyToSpotterColorCount = 0
      for allyTeamListIndex = 1, numberOfAllyTeams do
         allyID                = allyTeamList[allyTeamListIndex]
         if not skipOwnAllyTeam  or  (skipOwnAllyTeam  and  not (allyID == myAllyID))  then
            allyToSpotterColorCount     = allyToSpotterColorCount+1
            allyToSpotterColor[allyID]  = allyToSpotterColorCount
            usedSpotterColor      = spotterColor[allyToSpotterColorCount]
            if defaultColorsForAllyTeams < numberOfAllyTeams-1 then
               teamList = Spring.GetTeamList(allyID)
               for teamListIndex = 1, #teamList do
                  teamID = teamList[teamListIndex]
                  if teamID ~= gaiaTeamID then
                     if (teamListIndex == 1  and  #teamList <= keepTeamColorsForSmallAllyTeam) then     -- only check for the first allyTeam, (to be consistent with picking a teamcolor or default color, inconsistency could happen with different teamsizes)
                        pickTeamColor = true
                     end
                     if pickTeamColor then
                        -- pick the first team in the allyTeam and take the color from that one
                        if (teamListIndex == 1) then
                            usedSpotterColor[1],usedSpotterColor[2],usedSpotterColor[3],_       = Spring.GetTeamColor(teamID)
                        end
                     end
                  end
               end
            end
            teamList = Spring.GetTeamList(allyID)
            for teamListIndex = 1, #teamList do
               teamID = teamList[teamListIndex]

               if teamID ~= gaiaTeamID then
                  -- setting the angle only once, so on reloads the old angle is used
                  if rotationAngles[allyID] == nil then
                      rotationAngles[allyID] = {currentAngle = 0}
                  end
                  rotationAngles[allyID].rotationSpeed = rotationSpeed

                  circlePolys[teamID] = gl.CreateList(drawSpotters)
               end
            end
         end
      end
   end
end



-- Creating polygons:
function widget:Initialize()
    sceduleRandomize       = fxRandomize
    if Spring.GetSpectatingState()  and  renderAllTeamsAsSpec then
        skipOwnAllyTeam = false
    elseif not Spring.GetSpectatingState() and renderAllTeamsAsPlayer then
        skipOwnAllyTeam = false
    end
    callfunction     = CreateEnemyspotterGl(true)
	
	Button["showBase"] 			    = {}
    Button["showFX"]			    = {}
    Button["fxDetailOffset"]	    = {}
	Button["randomiseFX"]		    = {}
	Button["useTS"]				    = {}
	Button["showAllTeamsAsPlayer"]  = {}
	Button["showAllTeamsAsSpec"]    = {}
	Button["baseOpacity"]		    = {}
	Button["fxOpacity"]			    = {}
	Button["fxPartsMultiplier"]	    = {}
	Panel["main"]				    = {}
	InitButtons()
	
end

function widget:Shutdown()
    for _,circlePoly in pairs(circlePolys) do
        gl.DeleteList(circlePoly)
    end
end

function InitButtons()
	Button["showBase"]["x1"]		= tweakUiPosX + buttontab
	Button["showBase"]["x2"]  		= Button["showBase"]["x1"] + buttonsize
	Button["showBase"]["y1"]  		= tweakUiPosY + tweakUiHeight - 70
	Button["showBase"]["y2"]  		= Button["showBase"]["y1"] +  buttonsize
	Button["showBase"]["above"] 	= false 
	Button["showBase"]["click"]		= showBase

	Button["showFX"]["x1"]			= tweakUiPosX + buttontab
	Button["showFX"]["x2"]  		= Button["showFX"]["x1"] + buttonsize
	Button["showFX"]["y1"]      	= Button["showBase"]["y1"] - rowgap - buttonsize
	Button["showFX"]["y2"] 			= Button["showFX"]["y1"] + buttonsize
	Button["showFX"]["above"] 		= false
	Button["showFX"]["click"]		= showFx

	Button["fxDetailOffset"]["x1"]		= tweakUiPosX + buttontab
	Button["fxDetailOffset"]["x2"]  	= Button["fxDetailOffset"]["x1"] + buttonsize
	Button["fxDetailOffset"]["y1"]      = Button["showFX"]["y1"] - rowgap - buttonsize
	Button["fxDetailOffset"]["y2"] 		= Button["fxDetailOffset"]["y1"] + buttonsize
	Button["fxDetailOffset"]["above"] 	= false
	Button["fxDetailOffset"]["click"]	= fxDetailOffset
	
	Button["randomiseFX"]["x1"]		= tweakUiPosX + buttontab
	Button["randomiseFX"]["x2"]  	= Button["randomiseFX"]["x1"] + buttonsize
	Button["randomiseFX"]["y1"]     = Button["fxDetailOffset"]["y1"] - rowgap - buttonsize
	Button["randomiseFX"]["y2"] 	= Button["randomiseFX"]["y1"] + buttonsize
	Button["randomiseFX"]["above"] 	= false 
	Button["randomiseFX"]["click"]	= fxRandomize

	Button["showAllTeamsAsPlayer"]["x1"]	 = tweakUiPosX + buttontab
	Button["showAllTeamsAsPlayer"]["x2"]     = Button["showAllTeamsAsPlayer"]["x1"] + buttonsize
	Button["showAllTeamsAsPlayer"]["y1"]     = Button["randomiseFX"]["y1"] - rowgap - buttonsize
	Button["showAllTeamsAsPlayer"]["y2"] 	 = Button["showAllTeamsAsPlayer"]["y1"] + buttonsize
	Button["showAllTeamsAsPlayer"]["above"]  = false
	Button["showAllTeamsAsPlayer"]["click"]  = renderAllTeamsAsPlayer
	
	Button["showAllTeamsAsSpec"]["x1"]	   = tweakUiPosX + buttontab
	Button["showAllTeamsAsSpec"]["x2"]     = Button["showAllTeamsAsSpec"]["x1"] + buttonsize
	Button["showAllTeamsAsSpec"]["y1"]     = Button["showAllTeamsAsPlayer"]["y1"] - rowgap - buttonsize
	Button["showAllTeamsAsSpec"]["y2"] 	   = Button["showAllTeamsAsSpec"]["y1"] + buttonsize
	Button["showAllTeamsAsSpec"]["above"]  = false
	Button["showAllTeamsAsSpec"]["click"]  = renderAllTeamsAsSpec
	
	Button["baseOpacity"]["x1"]		= tweakUiPosX + buttontab
	Button["baseOpacity"]["x2"]  	= Button["baseOpacity"]["x1"] + buttonsize
	Button["baseOpacity"]["y1"]     = Button["showAllTeamsAsSpec"]["y1"] - rowgap - buttonsize
	Button["baseOpacity"]["y2"] 	= Button["baseOpacity"]["y1"] + buttonsize
	Button["baseOpacity"]["above"] 	= false 
	Button["baseOpacity"]["click"]	= false
	
	Button["fxOpacity"]["x1"]		= tweakUiPosX + buttontab
	Button["fxOpacity"]["x2"]  		= Button["fxOpacity"]["x1"] + buttonsize
	Button["fxOpacity"]["y1"]     	= Button["baseOpacity"]["y1"] - rowgap - buttonsize
	Button["fxOpacity"]["y2"] 		= Button["fxOpacity"]["y1"] + buttonsize
	Button["fxOpacity"]["above"] 	= false 
	Button["fxOpacity"]["click"]	= false

	Button["fxPartsMultiplier"]["x1"]		= tweakUiPosX + buttontab
	Button["fxPartsMultiplier"]["x2"]  		= Button["fxPartsMultiplier"]["x1"] + buttonsize
	Button["fxPartsMultiplier"]["y1"]     	= Button["fxOpacity"]["y1"] - rowgap - buttonsize
	Button["fxPartsMultiplier"]["y2"] 		= Button["fxPartsMultiplier"]["y1"] + buttonsize
	Button["fxPartsMultiplier"]["above"] 	= false
	Button["fxPartsMultiplier"]["click"]	= false

	Button["useTS"]["x1"]			= tweakUiPosX + buttontab
	Button["useTS"]["x2"]  			= Button["useTS"]["x1"] + buttonsize
	Button["useTS"]["y1"]     		= Button["fxPartsMultiplier"]["y1"] - rowgap - buttonsize
	Button["useTS"]["y2"] 			= Button["useTS"]["y1"] + buttonsize
	Button["useTS"]["above"] 		= false
	Button["useTS"]["click"]		= useTrueskill
	
	Panel["main"]["x1"]				= tweakUiPosX
	Panel["main"]["x2"]				= tweakUiPosX + tweakUiWidth
	Panel["main"]["y1"]				= tweakUiPosY
	Panel["main"]["y2"]				= tweakUiPosY + tweakUiHeight

end


function widget:PlayerChanged()
    if Spring.GetSpectatingState()  and  renderAllTeamsAsSpec then
        skipOwnAllyTeam = false
        callfunction = CreateEnemyspotterGl()
    elseif not Spring.GetSpectatingState() and renderAllTeamsAsPlayer then
        skipOwnAllyTeam = false
        callfunction = CreateEnemyspotterGl()
    end
end


-- Retrieving radius:
local function GetUnitDefRealRadius(udid)
   radius = realRadii[udid]
   if (radius) then return radius end
   ud = UnitDefs[udid]
   if (ud == nil) then return nil end
   dims = Spring.GetUnitDefDimensions(udid)
   if (dims == nil) then return nil end
   scale = ud.hitSphereScale -- missing in 0.76b1+
   scale = ((scale == nil) or (scale == 0.0)) and 1.0 or scale
   radius = dims.radius / scale
   realRadii[udid] = radius
   return radius
end

local function IsOnButton(x, y, BLcornerX, BLcornerY,TRcornerX,TRcornerY)
	if BLcornerX == nil then return false end
	-- check if the mouse is in a rectangle

	return x >= BLcornerX and x <= TRcornerX
	                      and y >= BLcornerY
	                      and y <= TRcornerY

end

function round(num, idp)
    mult = 10^(idp or 0)
    return math.floor(num * mult + 0.5) / mult
end

function GetSkill(playerID)
	customtable = select(10,Spring.GetPlayerInfo(playerID)) or {} -- player custom table
	tsMu = customtable.skill
	tsSigma = customtable.skilluncertainty or "N/A"
	tskill = 0
	if tsMu then
		tskill = tsMu and tonumber(tsMu:match("%d+%.?%d*")) or 0
		tskill = round(tskill,0)
		--if string.find(tsMu, ")") then
		--	tskill = "\255"..string.char(190)..string.char(140)..string.char(140) .. tskill -- ')' means inferred from lobby rank
		--end
	end
	return tskill
end

--------------------------------------------------------------------------------
-- Drawing:
--------------------------------------------------------------------------------

function widget:DrawScreen()      -- needed to even draw the tweak ui

end


function widget:DrawWorldPreUnit()
   if not drawWithHiddenGUI then
       if Spring.IsGUIHidden() then return end
   end
   if not renderSpotters then
       return
   end

    if not paused and showFx then
        if not fxRandomize then
            currentRotationAngle = currentRotationAngle + rotationSpeed
            if currentRotationAngle > 360 then
  	           currentRotationAngle = currentRotationAngle - 360
            end
        end
        currentGameSpeed, _, paused = Spring.GetGameSpeed()
        rotationSpeedMultiplier = ((os.clock() - previousOsClock) * 50) * currentGameSpeed
        previousOsClock = os.clock()

        allyTeamList = Spring.GetAllyTeamList()
        numberOfAllyTeams = #allyTeamList
        for allyTeamListIndex=1, numberOfAllyTeams do
            allyID                = allyTeamList[allyTeamListIndex]
            if not skipOwnAllyTeam  or  (skipOwnAllyTeam  and  not (allyID == myAllyID))  then
                if rotationAngles[allyID] ~= nil then
                    currentRotationAngle = rotationAngles[allyID].currentAngle + (rotationAngles[allyID].rotationSpeed * rotationSpeedMultiplier)
                    if currentRotationAngle > 360 then
                        currentRotationAngle = currentRotationAngle - 360
                    elseif currentRotationAngle < 0 then
                        currentRotationAngle = currentRotationAngle + 360
                    end
                    rotationAngles[allyID].currentAngle = currentRotationAngle
                end
            end
        end
    end

    gl.DepthTest(true)
    gl.PolygonOffset(-100, -2)         -- else the spotters flicker

    visibleUnits = Spring.GetVisibleUnits()
    numberOfVisibleUnits = #visibleUnits
    for i=1, numberOfVisibleUnits do
        unitID = visibleUnits[i]
        teamID = Spring.GetUnitTeam(unitID)
        if teamID ~= gaiaTeamID then
            allyID = Spring.GetUnitAllyTeam(unitID)
            if circlePolys[teamID] ~= nil then
                if not skipOwnAllyTeam  or  (skipOwnAllyTeam  and  not (allyID == myAllyID))  then
                    unitDefIDValue = Spring.GetUnitDefID(unitID)
                    if (unitDefIDValue) then
                        radius = GetUnitDefRealRadius(unitDefIDValue) * circleSize
                        if (radius) then
                            glDrawListAtUnit(unitID, circlePolys[teamID], false, radius, 1.0, radius, rotationAngles[allyID].currentAngle, 0, 1, 0)
                        end
                    end
                end
            end

            if showUnitNames then
                x, y, z = Spring.GetUnitPosition(unitID)
                if x then
                    if (skipOwnAllyTeam  and  (allyID == myAllyID))  then
                        unitDefIDValue = Spring.GetUnitDefID(unitID)
                        radius = GetUnitDefRealRadius(unitDefIDValue) * circleSize
                    end
                    gl.PushMatrix()
                    gl.Color(1,1,1,0.35)
                    gl.Translate( x, y, z)
                    gl.Billboard()
                    gl.Text(UnitDefs[unitDefIDValue].humanName, 0, 1.2 * radius, 15, "cn")
                    gl.PopMatrix()
                end
            end
        end
    end

    gl.DepthTest(false)
    gl.Color(1, 1, 1, 1)
end


function widget:TextCommand(command)
    local mycommand = false
    if (string.find(command, "enemyspotterbase") == 1  and  string.len(command) == 16) then showBase = not showBase ; callfunction = CreateEnemyspotterGl() end

    if (string.find(command, "enemyspotterfx") == 1  and  string.len(command) == 14) then showFx = not showFx ; callfunction = CreateEnemyspotterGl() end

    if (string.find(command, "enemyspotterfxdetailoffset") == 1  and  string.len(command) == 26) then fxDetailOffset = not fxDetailOffset ; callfunction = CreateEnemyspotterGl() end

    if (string.find(command, "enemyspotterrandomize") == 1  and  string.len(command) == 21) then fxRandomize = not fxRandomize ; sceduleRandomize = fxRandomize ; callfunction = CreateEnemyspotterGl(true) end

    if (string.find(command, "enemyspottertrueskill") == 1  and  string.len(command) == 21) then useTrueskill = not useTrueskill ; sceduleTrueskill = true ; callfunction = CreateEnemyspotterGl(true) end

    if (string.find(command, "enemyspotterplayermode") == 1  and  string.len(command) == 22) then renderAllTeamsAsPlayer = not renderAllTeamsAsPlayer ; if not Spring.GetSpectatingState() then skipOwnAllyTeam = not renderAllTeamsAsPlayer ; callfunction = CreateEnemyspotterGl() elseif not renderAllTeamsAsSpec and not renderAllTeamsAsPlayer then skipOwnAllyTeam = not renderAllTeamsAsPlayer ; callfunction = CreateEnemyspotterGl() end end

    if (string.find(command, "enemyspotterspecmode") == 1  and  string.len(command) == 20) then renderAllTeamsAsSpec = not renderAllTeamsAsSpec ; if Spring.GetSpectatingState() and not renderAllTeamsAsPlayer then skipOwnAllyTeam = not renderAllTeamsAsSpec ;  callfunction = CreateEnemyspotterGl() end end

    if (string.find(command, "enemyspotterunitnames") == 1  and  string.len(command) == 21) then showUnitNames = not showUnitNames end

    if (string.find(command, "+enemyspotterbaseopacity") == 1) then baseOpacity = baseOpacity + 0.015 ; callfunction = CreateEnemyspotterGl() end
    if (string.find(command, "-enemyspotterbaseopacity") == 1) then baseOpacity = baseOpacity - 0.015 ; callfunction = CreateEnemyspotterGl() end

    if (string.find(command, "+enemyspotterfxopacity") == 1) then fxOpacity = fxOpacity + 0.15 ; callfunction = CreateEnemyspotterGl() end
    if (string.find(command, "-enemyspotterfxopacity") == 1) then fxOpacity = fxOpacity - 0.15 ; callfunction = CreateEnemyspotterGl() end

    if (string.find(command, "+enemyspotterfxpartsmultiplier") == 1) then oldFxPartsMultiplier = fxPartsMultiplier ; fxPartsMultiplier = fxPartsMultiplier + 0.05 ; sceduleFxPartsMultiplier = true ; callfunction = CreateEnemyspotterGl(true) end
    if (string.find(command, "-enemyspotterfxpartsmultiplier") == 1) then oldFxPartsMultiplier = fxPartsMultiplier ; fxPartsMultiplier = fxPartsMultiplier - 0.05 ; sceduleFxPartsMultiplier = true ; callfunction = CreateEnemyspotterGl(true) end

end


--------------------------------------------------------------------------------
-- Tweak-mode
--------------------------------------------------------------------------------

local function drawOptions()

    gl.Texture(false)       -- because other widgets might be sloppy

	--background panel
	gl.Color(0,0,0,0.5)
	gl.Rect(Panel["main"]["x1"],Panel["main"]["y1"], Panel["main"]["x2"], Panel["main"]["y2"])

	--border
	gl.Color(0,0,0,1)
	gl.Rect(Panel["main"]["x1"]-1,Panel["main"]["y1"], Panel["main"]["x1"], Panel["main"]["y2"])
	gl.Rect(Panel["main"]["x2"],Panel["main"]["y1"], Panel["main"]["x2"]+1, Panel["main"]["y2"])
	gl.Rect(Panel["main"]["x1"],Panel["main"]["y1"]-1, Panel["main"]["x2"], Panel["main"]["y1"])
	gl.Rect(Panel["main"]["x1"],Panel["main"]["y2"], Panel["main"]["x2"], Panel["main"]["y2"]+1)

	-- Heading
	gl.Color(1,1,1,1)
	gl.Text("Enemy-spotter", Panel["main"]["x1"] + leftmargin, Panel["main"]["y2"] - 30,15,'sd')

	-- showbase option
	if Button["showBase"]["mouse"] then
		gl.Color(1,1,1,1)
	else
		gl.Color(0.6,0.6,0.6,1)
	end

	gl.Text("Show base:", tweakUiPosX+leftmargin, Button["showBase"]["y1"],12,'sd')

	if Button["showBase"]["click"] then
		gl.Texture(optCheckBoxOn)
	else
		gl.Texture(optCheckBoxOff)
	end
	gl.TexRect(Button["showBase"]["x1"],Button["showBase"]["y1"],Button["showBase"]["x2"],Button["showBase"]["y2"])

	-- showFX option
	if Button["showFX"]["mouse"] then
		gl.Color(1,1,1,1)
	else
		gl.Color(0.6,0.6,0.6,1)
	end

	gl.Text("Show FX:", tweakUiPosX+leftmargin, Button["showFX"]["y1"],12,'sd')

	if Button["showFX"]["click"] then
		gl.Texture(optCheckBoxOn)
	else
		gl.Texture(optCheckBoxOff)
	end
	gl.TexRect(Button["showFX"]["x1"],Button["showFX"]["y1"],Button["showFX"]["x2"],Button["showFX"]["y2"])

	-- fxDetailOffset option
	if Button["fxDetailOffset"]["mouse"] then
		gl.Color(1,1,1,1)
	else
		gl.Color(0.6,0.6,0.6,1)
	end

	gl.Text("FX details:", tweakUiPosX+leftmargin, Button["fxDetailOffset"]["y1"],12,'sd')

	if Button["fxDetailOffset"]["click"] then
		gl.Texture(optCheckBoxOn)
	else
		gl.Texture(optCheckBoxOff)
	end
	gl.TexRect(Button["fxDetailOffset"]["x1"],Button["fxDetailOffset"]["y1"],Button["fxDetailOffset"]["x2"],Button["fxDetailOffset"]["y2"])

	-- randomiseFX option
	if Button["randomiseFX"]["mouse"] then
		gl.Color(1,1,1,1)
	else
		gl.Color(0.6,0.6,0.6,1)
	end

	gl.Text("Randomize FX properties:", tweakUiPosX+leftmargin, Button["randomiseFX"]["y1"],12,'sd')

	if Button["randomiseFX"]["click"] then
		gl.Texture(optCheckBoxOn)
	else
		gl.Texture(optCheckBoxOff)
	end
	gl.TexRect(Button["randomiseFX"]["x1"],Button["randomiseFX"]["y1"],Button["randomiseFX"]["x2"],Button["randomiseFX"]["y2"])

	-- useTS option
	if Button["useTS"]["mouse"] then
		gl.Color(1,1,1,1)
	else
		gl.Color(0.6,0.6,0.6,1)
	end

	gl.Text("Use Trueskill for FX parts:", tweakUiPosX+leftmargin, Button["useTS"]["y1"],12,'sd')

	if Button["useTS"]["click"] then
		gl.Texture(optCheckBoxOn)
	else
		gl.Texture(optCheckBoxOff)
	end
	gl.TexRect(Button["useTS"]["x1"],Button["useTS"]["y1"],Button["useTS"]["x2"],Button["useTS"]["y2"])

	-- showAllTeamsAsPlayer option
	if Button["showAllTeamsAsPlayer"]["mouse"] then
		gl.Color(1,1,1,1)
	else
		gl.Color(0.6,0.6,0.6,1)
	end

	gl.Text("Show own team as player:", tweakUiPosX+leftmargin, Button["showAllTeamsAsPlayer"]["y1"],12,'sd')

	if Button["showAllTeamsAsPlayer"]["click"] then
		gl.Texture(optCheckBoxOn)
	else
		gl.Texture(optCheckBoxOff)
	end
	gl.TexRect(Button["showAllTeamsAsPlayer"]["x1"],Button["showAllTeamsAsPlayer"]["y1"],Button["showAllTeamsAsPlayer"]["x2"],Button["showAllTeamsAsPlayer"]["y2"])

	-- showAllTeamsAsSpec option
	if Button["showAllTeamsAsSpec"]["mouse"] then
		gl.Color(1,1,1,1)
	else
		gl.Color(0.6,0.6,0.6,1)
	end

	gl.Text("Show all teams as spec:", tweakUiPosX+leftmargin, Button["showAllTeamsAsSpec"]["y1"],12,'sd')

	if Button["showAllTeamsAsSpec"]["click"] then
		gl.Texture(optCheckBoxOn)
	else
		gl.Texture(optCheckBoxOff)
	end
	gl.TexRect(Button["showAllTeamsAsSpec"]["x1"],Button["showAllTeamsAsSpec"]["y1"],Button["showAllTeamsAsSpec"]["x2"],Button["showAllTeamsAsSpec"]["y2"])

	-- baseOpacity option
	if Button["baseOpacity"]["mouse"] then
		gl.Color(1,1,1,1)
	else
		gl.Color(0.6,0.6,0.6,1)
	end

	gl.Text("Base opacity:", tweakUiPosX+leftmargin, Button["baseOpacity"]["y1"],12,'sd')
	gl.Texture(optContrast)
	gl.TexRect(Button["baseOpacity"]["x1"],Button["baseOpacity"]["y1"],Button["baseOpacity"]["x2"],Button["baseOpacity"]["y2"])

	-- fxOpacity option
	if Button["fxOpacity"]["mouse"] then
		gl.Color(1,1,1,1)
	else
		gl.Color(0.6,0.6,0.6,1)
	end

	gl.Text("FX opacity:", tweakUiPosX+leftmargin, Button["fxOpacity"]["y1"],12,'sd')
	gl.Texture(optContrast)
	gl.TexRect(Button["fxOpacity"]["x1"],Button["fxOpacity"]["y1"],Button["fxOpacity"]["x2"],Button["fxOpacity"]["y2"])

	-- fxPartsMultiplier option
	if Button["fxPartsMultiplier"]["mouse"] then
		gl.Color(1,1,1,1)
	else
		gl.Color(0.6,0.6,0.6,1)
	end

	gl.Text("Number of FX parts:", tweakUiPosX+leftmargin, Button["fxPartsMultiplier"]["y1"],12,'sd')
	gl.Texture(optMinPlus)
	gl.TexRect(Button["fxPartsMultiplier"]["x1"],Button["fxPartsMultiplier"]["y1"],Button["fxPartsMultiplier"]["x2"],Button["fxPartsMultiplier"]["y2"])

	--reset state
	gl.Texture(false)
	gl.Color(1,1,1,1)
end

local function drawIsAbove(x,y)
	if not x or not y then return false end

	for _,button in pairs(Button) do
		button["mouse"] = false
	end

	if IsOnButton(x, y, Button["showBase"]["x1"],Button["showBase"]["y1"],Button["showBase"]["x2"],Button["showBase"]["y2"]) then
		 Button["showBase"]["mouse"] = true
		 return true
	elseif IsOnButton(x, y, Button["showFX"]["x1"],Button["showFX"]["y1"],Button["showFX"]["x2"],Button["showFX"]["y2"]) then
		 Button["showFX"]["mouse"] = true
		 return true
    elseif IsOnButton(x, y, Button["fxDetailOffset"]["x1"],Button["fxDetailOffset"]["y1"],Button["fxDetailOffset"]["x2"],Button["fxDetailOffset"]["y2"]) then
        Button["fxDetailOffset"]["mouse"] = true
        return true
	elseif IsOnButton(x, y, Button["randomiseFX"]["x1"],Button["randomiseFX"]["y1"],Button["randomiseFX"]["x2"],Button["randomiseFX"]["y2"]) then
		 Button["randomiseFX"]["mouse"] = true
		 return true
	elseif IsOnButton(x, y, Button["useTS"]["x1"],Button["useTS"]["y1"],Button["useTS"]["x2"],Button["useTS"]["y2"]) then
		 Button["useTS"]["mouse"] = true
		 return true
	elseif IsOnButton(x, y, Button["showAllTeamsAsPlayer"]["x1"],Button["showAllTeamsAsPlayer"]["y1"],Button["showAllTeamsAsPlayer"]["x2"],Button["showAllTeamsAsPlayer"]["y2"]) then
		 Button["showAllTeamsAsPlayer"]["mouse"] = true
		 return true
	elseif IsOnButton(x, y, Button["showAllTeamsAsSpec"]["x1"],Button["showAllTeamsAsSpec"]["y1"],Button["showAllTeamsAsSpec"]["x2"],Button["showAllTeamsAsSpec"]["y2"]) then
		 Button["showAllTeamsAsSpec"]["mouse"] = true
		 return true
	elseif IsOnButton(x, y, Button["baseOpacity"]["x1"],Button["baseOpacity"]["y1"],Button["baseOpacity"]["x2"],Button["baseOpacity"]["y2"]) then
		 Button["baseOpacity"]["mouse"] = true
		 return true
	elseif IsOnButton(x, y, Button["fxOpacity"]["x1"],Button["fxOpacity"]["y1"],Button["fxOpacity"]["x2"],Button["fxOpacity"]["y2"]) then
		 Button["fxOpacity"]["mouse"] = true
		 return true
	elseif IsOnButton(x, y, Button["fxPartsMultiplier"]["x1"],Button["fxPartsMultiplier"]["y1"],Button["fxPartsMultiplier"]["x2"],Button["fxPartsMultiplier"]["y2"]) then
		 Button["fxPartsMultiplier"]["mouse"] = true
		 return true
	end
	 return false
end

function widget:TweakDrawScreen()
	drawOptions()
end

function widget:IsAbove(x,y)
	drawIsAbove(x,y)
	--this callin must be present, otherwise function widget:TweakIsAbove(z,y) isn't called. Maybe a bug in widgethandler.
end

function widget:TweakIsAbove(x,y)
	drawIsAbove(x,y)
 end

function widget:TweakMousePress(x, y, button)

	if button == 1 then
		if IsOnButton(x, y, Button["showBase"]["x1"],Button["showBase"]["y1"],Button["showBase"]["x2"],Button["showBase"]["y2"]) then
			 Spring.SendCommands({"enemyspotterbase"})
			 Button["showBase"]["click"] = showBase
			 return true
		elseif IsOnButton(x, y, Button["showFX"]["x1"],Button["showFX"]["y1"],Button["showFX"]["x2"],Button["showFX"]["y2"]) then
			  Spring.SendCommands({"enemyspotterfx"})
			 Button["showFX"]["click"] = showFx
			 return true
		elseif IsOnButton(x, y, Button["fxDetailOffset"]["x1"],Button["fxDetailOffset"]["y1"],Button["fxDetailOffset"]["x2"],Button["fxDetailOffset"]["y2"]) then
			 Spring.SendCommands({"enemyspotterfxdetailoffset"})
			 Button["fxDetailOffset"]["click"] = fxDetailOffset
			 return true
		elseif IsOnButton(x, y, Button["randomiseFX"]["x1"],Button["randomiseFX"]["y1"],Button["randomiseFX"]["x2"],Button["randomiseFX"]["y2"]) then
             Spring.SendCommands({"enemyspotterrandomize"})
			 Button["randomiseFX"]["click"] = fxRandomize
   			 return true
		elseif IsOnButton(x, y, Button["useTS"]["x1"],Button["useTS"]["y1"],Button["useTS"]["x2"],Button["useTS"]["y2"]) then
			 Spring.SendCommands({"enemyspottertrueskill"})
			 Button["useTS"]["click"] = useTrueskill
			 return true
		elseif IsOnButton(x, y, Button["showAllTeamsAsPlayer"]["x1"],Button["showAllTeamsAsPlayer"]["y1"],Button["showAllTeamsAsPlayer"]["x2"],Button["showAllTeamsAsPlayer"]["y2"]) then
			 Spring.SendCommands({"enemyspotterplayermode"})
			 Button["showAllTeamsAsPlayer"]["click"] = renderAllTeamsAsPlayer
			 return true
		elseif IsOnButton(x, y, Button["showAllTeamsAsSpec"]["x1"],Button["showAllTeamsAsSpec"]["y1"],Button["showAllTeamsAsSpec"]["x2"],Button["showAllTeamsAsSpec"]["y2"]) then
			 Spring.SendCommands({"enemyspotterspecmode"})
			 Button["showAllTeamsAsSpec"]["click"] = renderAllTeamsAsSpec
			 return true
		elseif IsOnButton(x, y, Button["baseOpacity"]["x1"],Button["baseOpacity"]["y1"],Button["baseOpacity"]["x1"]+buttonsize/2,Button["baseOpacity"]["y2"]) then
			 Spring.SendCommands({"-enemyspotterbaseopacity"})
			 return true
		elseif IsOnButton(x, y, (Button["baseOpacity"]["x2"]-Button["baseOpacity"]["x1"])/2,Button["baseOpacity"]["y1"],Button["baseOpacity"]["x2"],Button["baseOpacity"]["y2"]) then
			 Spring.SendCommands({"+enemyspotterbaseopacity"})
			 return true
		elseif IsOnButton(x, y, Button["fxOpacity"]["x1"],Button["fxOpacity"]["y1"],Button["fxOpacity"]["x1"]+(Button["fxOpacity"]["x2"]-Button["fxOpacity"]["x1"])/2,Button["fxOpacity"]["y2"]) then
			 Spring.SendCommands({"-enemyspotterfxopacity"})
			 return true
		elseif IsOnButton(x, y, Button["fxOpacity"]["x1"]+(Button["fxOpacity"]["x2"]-Button["fxOpacity"]["x1"])/2,Button["fxOpacity"]["y1"],Button["fxOpacity"]["x2"],Button["fxOpacity"]["y2"]) then
			  Spring.SendCommands({"+enemyspotterfxopacity"})
			 return true
		elseif IsOnButton(x, y, Button["fxPartsMultiplier"]["x1"],Button["fxPartsMultiplier"]["y1"],Button["fxPartsMultiplier"]["x1"]+(Button["fxPartsMultiplier"]["x2"]-Button["fxPartsMultiplier"]["x1"])/2,Button["fxPartsMultiplier"]["y2"]) then
			 Spring.SendCommands({"-enemyspotterfxpartsmultiplier"})
			 return true
		elseif IsOnButton(x, y, Button["fxPartsMultiplier"]["x1"]+(Button["fxPartsMultiplier"]["x2"]-Button["fxPartsMultiplier"]["x1"])/2,Button["fxPartsMultiplier"]["y1"],Button["fxPartsMultiplier"]["x2"],Button["fxPartsMultiplier"]["y2"]) then
			 Spring.SendCommands({"+enemyspotterfxpartsmultiplier"})
			 return true
		end
	 elseif (button == 2 or button == 3) then
		 if IsOnButton(x, y, Panel["main"]["x1"],Panel["main"]["y1"], Panel["main"]["x2"], Panel["main"]["y2"]) then
			  --Dragging
			 return true
		 end
	 end
	 return false
 end

function widget:TweakMouseMove(mx, my, dx, dy, mButton)

      --Dragging
     if mButton == 2 or mButton == 3 then
		 tweakUiPosX = math.max(0, math.min(tweakUiPosX+dx, vsx-tweakUiWidth))	--prevent moving off screen
		 tweakUiPosY = math.max(0, math.min(tweakUiPosY+dy, vsy-tweakUiHeight))
		 InitButtons()
     end
 end
