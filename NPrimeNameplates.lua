-----------------------------------------------------------------------------------------------
-- Client Lua Script for NPrimeNameplates
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "ChallengesLib"
require "Unit"
require "GameLib"
require "Apollo"
require "PathMission"
require "Quest"
require "Episode"
require "math"
require "string"
require "DialogSys"
require "PublicEvent"
require "PublicEventObjective"
require "CommunicatorLib"
require "GroupLib"
require "PlayerPathLib"
require "bit32"
 
local NPrimeNameplates = {} 

local _ccWhiteList =
{
 	[Unit.CodeEnumCCState.Stun] 			= "Stun",
	[Unit.CodeEnumCCState.Disarm] 			= "Disarm",
	[Unit.CodeEnumCCState.Fear] 			= "Fear",
	[Unit.CodeEnumCCState.Knockdown] 		= "knockdown",
	[Unit.CodeEnumCCState.Blind] 			= "Blind",
	[Unit.CodeEnumCCState.Tether] 			= "Tether",
	[Unit.CodeEnumCCState.Subdue] 			= "Subdue",
	[Unit.CodeEnumCCState.Vulnerability]            = "MoO",
}

local _exceptions =
{
	["NyanPrime"] 				= false, 	-- Hidden
	["Cactoid"] 				= true, 	-- Visible
	["Spirit of the Darned"] 	= true,
	["Wilderrun Trap"] 			= true,
}

local _color = ApolloColor.new

local _playerClass =
{
	[GameLib.CodeEnumClass.Esper]  		 = "NPrimeNameplates_Sprites:IconEsper",
	[GameLib.CodeEnumClass.Medic]  		 = "NPrimeNameplates_Sprites:IconMedic",
	[GameLib.CodeEnumClass.Stalker]  	 = "NPrimeNameplates_Sprites:IconStalker",
	[GameLib.CodeEnumClass.Warrior]  	 = "NPrimeNameplates_Sprites:IconWarrior",
	[GameLib.CodeEnumClass.Engineer]  	 = "NPrimeNameplates_Sprites:IconEngineer",
	[GameLib.CodeEnumClass.Spellslinger]    = "NPrimeNameplates_Sprites:IconSpellslinger",
}

local _npcRank =
{
	[Unit.CodeEnumRank.Elite] 		= "NPrimeNameplates_Sprites:icon_6_elite",
	[Unit.CodeEnumRank.Superior]            = "NPrimeNameplates_Sprites:icon_5_superior",
	[Unit.CodeEnumRank.Champion]            = "NPrimeNameplates_Sprites:icon_4_champion",
	[Unit.CodeEnumRank.Standard]            = "NPrimeNameplates_Sprites:icon_3_standard",
	[Unit.CodeEnumRank.Minion] 		= "NPrimeNameplates_Sprites:icon_2_minion",
	[Unit.CodeEnumRank.Fodder] 		= "NPrimeNameplates_Sprites:icon_1_fodder",
}


local _dispColor =
{
	[Unit.CodeEnumDisposition.Neutral]  = _color("FFFFBC55"), -- Well, Neutral enemies color.
	[Unit.CodeEnumDisposition.Hostile]  = _color("FFFA394C"), -- No idea what this does.
	[Unit.CodeEnumDisposition.Friendly] = _color("FF7DAF29"), -- Friendly healthbarcolor
	[Unit.CodeEnumDisposition.Unknown]  = _color("FFFFFFFF"),
}

local _typeColor =
{
	Self 		= _color("FF43C8F3"), -- FF7DAF29
	Friendly 	= _color("FF7DAF29"), -- Friendly NPC Text Color
	FriendlyP	= _color("FF43C8F3"), -- Friendly Player Text Color
	Neutral 	= _color("FFFFF569"), -- Neutral Text / Bar Color ? 
	Hostile 	= _color("FFD9544D"), -- Hostile NPC
        HostileP        = _color("FFFFFFFF"), -- Hostile player Text
        HostilePPVP     = _color("FFD9544D"), -- Hostile player PvP Flagged Text
	Group 		= _color("FFF49500"), -- Group Bar color. 
	Harvest 	= _color("FFFFFFFF"),
	Other 		= _color("FFFFFFFF"), -- No idea
	Hidden 		= _color("FFFFFFFF"),
	LowThreat	= _color("FFF49500"), -- Threat Loss Bar Color. 
	LowHP    	= _color("FF55FAFF"), -- Low HP Threash hold
	Cleanse 	= _color("FFAF40E1"), -- Cleanse Bar Color. 
	CC		= _color("FF7E00FF"), -- MoO Bar Color
}

local _paths =
{
	[0] = "Soldier",
	[1] = "Settler",
	[2] = "Scientist",
	[3] = "Explorer",
}

local _matrixCategories =
{
	"Nameplates",
	"Health",
	"Class",
	"Level",
	"Title",
	"Guild",
	"CastingBar",
	"CCBar",
	"Armor",
	"TextBubbleFade",
}

local _matrixFilters = 
{
	"Self",
	"Target",
	"Friendly",
	"Neutral",
	"Hostile",
	"Group",
	"Other",
}

local _matrixButtonSprites =
{
	[0] = "MatrixOff",
	[1] = "MatrixInCombat",
	[2] = "MatrixOutOfCombat",
	[3] = "MatrixOn",
}

local _asbl =
{
	["Chair"] = true,
	["CityDirections"] = true,
	["TradeskillNode"] = true,
}

local _flags =
{
	opacity = 1,
	contacts = 1,
}

local _fontPrimary =
{
	[1] = { font = "CRB_Header9_O",  height = 20 },
	[2] = { font = "CRB_Header10_O", height = 21 },
	[3] = { font = "CRB_Header11_O", height = 22 },
	[4] = { font = "CRB_Header12_O", height = 24 },
	[5] = { font = "CRB_Header14_O", height = 28 },
	[6] = { font = "CRB_Header16_O", height = 34 },
}

local _fontSecondary =
{
	[1] = { font = "CRB_Interface9_O",  height = 20 },
	[2] = { font = "CRB_Interface10_O", height = 21 },
	[3] = { font = "CRB_Interface11_O", height = 22 },
	[4] = { font = "CRB_Interface12_O", height = 24 },
	[5] = { font = "CRB_Interface14_O", height = 28 },
	[6] = { font = "CRB_Interface16_O", height = 34 },
}

local _dispStr =
{
	[Unit.CodeEnumDisposition.Hostile]  	= "Hostile",
	[Unit.CodeEnumDisposition.Neutral]  	= "Neutral",
	[Unit.CodeEnumDisposition.Friendly] 	= "Friendly",
	[Unit.CodeEnumDisposition.Unknown] 	= "Hidden",
}

local F_PATH 		= 0
local F_QUEST 		= 1
local F_CHALLENGE 	= 2
local F_FRIEND	 	= 3
local F_RIVAL	 	= 4
local F_PVP 		= 4
local F_AGGRO 		= 5
local F_CLEANSE 	= 6
local F_LOW_HP 		= 7
local F_GROUP		= 8
local F_MOO		= 9

local F_NAMEPLATE 	= 0
local F_HEALTH 		= 1
local F_CLASS 		= 2
local F_LEVEL 		= 3
local F_TITLE 		= 4
local F_GUILD 		= 5
local F_CASTING_BAR     = 6
local F_CC_BAR		= 7
local F_ARMOR 		= 8
local F_BUBBLE 		= 9

local _player 		= nil
local _playerPath	= nil
local _playerPos	= nil
local _blinded		= nil

local _targetNP		= nil

local _floor		= math.floor
local _min		= math.min
local _max		= math.max
local _ipairs		= ipairs
local _pairs		= pairs
local _tableInsert	= table.insert
local _tableRemove	= table.remove
local _next		= next
local _type		= type
local _weaselStr	= String_GetWeaselString
local _strLen		= string.len
local _textWidth	= Apollo.GetTextWidth

local _or 		= bit32.bor
local _lshift		= bit32.lshift
local _and		= bit32.band
local _not		= bit32.bnot
local _xor		= bit32.bxor

local _configUI		= nil

local _matrix 		= {}
local _count		= 0
local _cycleSize	= 25

local _iconPixie =
{
	strSprite = "",
	cr = white,
	loc =
	{
		fPoints = { 0, 0, 1, 1 },
		nOffsets = { 0, 0, 0, 0 }
	},
}

local _targetPixie =
{
	strSprite = "BK3:sprHolo_Accent_Rounded",
	cr = white,
	loc =
	{
		fPoints = { 0.5, 0.5, 0.5, 0.5 },
		nOffsets = { 0, 0, 0, 0 }
	},
}
 
-------------------------------------------------------------------------------

function NPrimeNameplates:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function NPrimeNameplates:Init()
    Apollo.RegisterAddon(self, true)
end

function NPrimeNameplates:OnLoad()
	self.nameplates = {}
	self.pool = {}
	self.buffer = {}
	self.challenges = ChallengesLib.GetActiveChallengeList()

	Apollo.RegisterSlashCommand("npnpdebug", 					"OnNPrimeNameplatesCommandDebug", self)
	Apollo.RegisterEventHandler("VarChange_FrameCount", 		"OnDebuggerUnit", self)

	Apollo.RegisterSlashCommand("npnp", 						"OnConfigure", self)

	Apollo.RegisterEventHandler("VarChange_FrameCount", 		"OnFrame", self)
	Apollo.RegisterEventHandler("ChangeWorld", 					"OnChangeWorld", self)

    Apollo.RegisterEventHandler("UnitCreated", 					"OnUnitCreated", self)
	Apollo.RegisterEventHandler("UnitDestroyed", 				"OnUnitDestroyed", self)
	Apollo.RegisterEventHandler("UnitTextBubbleCreate", 		"OnTextBubble", self)
	Apollo.RegisterEventHandler("UnitTextBubblesDestroyed", 	"OnTextBubble", self)
	Apollo.RegisterEventHandler("TargetUnitChanged", 			"OnTargetUnitChanged", self)
	Apollo.RegisterEventHandler("UnitActivationTypeChanged", 	"OnUnitActivationTypeChanged", self)

	Apollo.RegisterEventHandler("UnitLevelChanged", 			"OnUnitLevelChanged", self)

	Apollo.RegisterEventHandler("PlayerTitleChange", 			"OnPlayerMainTextChanged", self)
	Apollo.RegisterEventHandler("UnitNameChanged", 				"OnUnitMainTextChanged", self)
	Apollo.RegisterEventHandler("UnitTitleChanged", 			"OnUnitMainTextChanged", self)
	Apollo.RegisterEventHandler("GuildChange", 					"OnPlayerMainTextChanged", self)
	Apollo.RegisterEventHandler("UnitGuildNameplateChanged", 	"OnUnitMainTextChanged", self)
	Apollo.RegisterEventHandler("UnitMemberOfGuildChange", 		"OnUnitMainTextChanged", self)

	Apollo.RegisterEventHandler("ApplyCCState", 				"OnCCStateApplied", self)
	Apollo.RegisterEventHandler("UnitGroupChanged", 			"OnGroupUpdated", self)
	Apollo.RegisterEventHandler("ChallengeUnlocked", 			"OnChallengeUnlocked", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", 			"OnUnitCombatStateChanged", self)
	Apollo.RegisterEventHandler("UnitPvpFlagsChanged", 			"OnUnitPvpFlagsChanged", self)

	Apollo.RegisterEventHandler("FriendshipAdd", 				"OnFriendshipChanged", self)
	Apollo.RegisterEventHandler("FriendshipRemove", 			"OnFriendshipChanged", self)

	self.xmlDoc = XmlDoc.CreateFromFile("NPrimeNameplates.xml")
	Apollo.LoadSprites("NPrimeNameplates_Sprites.xml")
end

function NPrimeNameplates:OnSave(p_type)
	if p_type ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
	return _matrix
end

function NPrimeNameplates:OnRestore(p_type, p_savedData)
	if p_type ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
	_matrix = p_savedData
	self:CheckMatrixIntegrity()
end

function NPrimeNameplates:OnFriendshipChanged()
	_flags.contacts = 1
end

function NPrimeNameplates:OnNameClick(wndHandler, wndCtrl, nClick)
	local l_unit = wndCtrl:GetData()
	if (l_unit ~= nil and nClick == 0) then
		GameLib.SetTargetUnit(l_unit)
		return true
	end
end

function NPrimeNameplates:OnChangeWorld()
	_player = nil

	if (_targetNP ~= nil) then
		if (_targetNP.targetMark ~= nil) then
			_targetNP.targetMark:Destroy()
		end
		_targetNP.form:Destroy()
		_targetNP = nil
	end
end

function NPrimeNameplates:OnUnitCombatStateChanged(p_unit, p_inCombat)
	if (p_unit == nil) then return end
	local l_nameplate = self.nameplates[p_unit:GetId()]
	self:SetCombatState(l_nameplate, p_inCombat)
	if (_player ~= nil and _player:GetTarget() == p_unit) then
		self:SetCombatState(_targetNP, p_inCombat)
	end
end

function NPrimeNameplates:OnGroupUpdated(p_unit)
	if (p_unit == nil) then return end
	local l_nameplate = self.nameplates[p_unit:GetId()]
	if (l_nameplate ~= nil) then
		l_nameplate.inGroup = p_unit:IsInYourGroup()
		l_nameplate.type = l_nameplate.inGroup and "Group" or _dispStr[l_nameplate.disposition]
	end
end

function NPrimeNameplates:OnUnitPvpFlagsChanged(p_unit)
	if (p_unit == nil) then return end
	local l_nameplate = self.nameplates[p_unit:GetId()]
	if (l_nameplate ~= nil) then
		l_nameplate.pvpFlagged = p_unit:IsPvpFlagged()
	end
	if (_targetNP ~= nil and _player:GetTarget() == p_unit) then
		_targetNP.pvpFlagged = p_unit:IsPvpFlagged()
	end
end

-------------------------------------------------------------------------------

function NPrimeNameplates:InitNameplate(p_unit, p_nameplate, p_type, p_target)
	p_nameplate = p_nameplate or {}
	p_target = p_target or false

	p_nameplate.unit 			= p_unit
	p_nameplate.unitClassID 		= p_unit:IsACharacter() and p_unit:GetClassId() or p_unit:GetRank()
	p_nameplate.disposition			= p_unit:GetDispositionTo(_player)
	p_nameplate.isPlayer			= p_unit:IsACharacter()
        
	p_nameplate.type 			= p_type
	p_nameplate.color 			= "FFFFFFFF"
	p_nameplate.targetNP 			= p_target
	p_nameplate.hasHealth 			= self:HasHealth(p_unit)

	if (p_target) then
		local l_source = self.nameplates[p_unit:GetId()]
		p_nameplate.ccActiveID 		= l_source and l_source.ccActiveID or -1
		p_nameplate.ccDuration 		= l_source and l_source.ccDuration or 0
		p_nameplate.ccDurationMax 	= l_source and l_source.ccDurationMax or 0
	else
		p_nameplate.ccActiveID 		= -1
		p_nameplate.ccDuration 		= 0
		p_nameplate.ccDurationMax 	= 0
	end

	p_nameplate.lowHealth			= false
	p_nameplate.healthy			= false
	p_nameplate.prevHealth			= 0
	p_nameplate.prevShield			= 0
	p_nameplate.prevAbsorb			= 0
	p_nameplate.prevArmor			= -2
	p_nameplate.levelWidth 			= 1

	p_nameplate.iconFlags			= -1
	p_nameplate.colorFlags			= -1
	p_nameplate.matrixFlags			= -1
	p_nameplate.rearrange			= false

	p_nameplate.outOfRange			= true
	p_nameplate.occluded			= p_unit:IsOccluded()
	p_nameplate.inCombat 			= p_unit:IsInCombat()
	p_nameplate.inGroup 			= p_unit:IsInYourGroup()
	p_nameplate.isMounted 			= p_unit:IsMounted()
	p_nameplate.isObjective			= false
	p_nameplate.pvpFlagged 			= p_unit:IsPvpFlagged()
	p_nameplate.hasActivationState	= self:HasActivationState(p_unit)
	p_nameplate.hasShield			= p_unit:GetShieldCapacityMax() ~= nil and p_unit:GetShieldCapacityMax() ~= 0

	local l_w = _matrix["SliderBarScale"] / 2
	local l_h = _matrix["SliderBarScale"] / 10
	local l_fontSize = _matrix["SliderFontSize"]
	local l_font = _matrix["ConfigAlternativeFont"] and _fontSecondary or _fontPrimary

	if (p_nameplate.form == nil) then
		p_nameplate.form = Apollo.LoadForm(self.xmlDoc, "Nameplate", "InWorldHudStratum", self)

		p_nameplate.containerTop		= p_nameplate.form:FindChild("ContainerTop")
		p_nameplate.containerMain		= p_nameplate.form:FindChild("ContainerMain")
		p_nameplate.containerIcons		= p_nameplate.form:FindChild("ContainerIcons")

		p_nameplate.textUnitName 		= p_nameplate.form:FindChild("TextUnitName")
		p_nameplate.textUnitGuild 		= p_nameplate.form:FindChild("TextUnitGuild")
		p_nameplate.textUnitLevel 		= p_nameplate.form:FindChild("TextUnitLevel")
	
		p_nameplate.containerCC			= p_nameplate.form:FindChild("ContainerCC")
		p_nameplate.containerCastBar            = p_nameplate.form:FindChild("ContainerCastBar")

		p_nameplate.iconUnit 			= p_nameplate.form:FindChild("IconUnit")
		p_nameplate.iconArmor 			= p_nameplate.form:FindChild("IconArmor")

		p_nameplate.health 	= p_nameplate.form:FindChild("BarHealth")
		p_nameplate.shield 	= p_nameplate.form:FindChild("BarShield")
		p_nameplate.absorb 	= p_nameplate.form:FindChild("BarAbsorb")
		p_nameplate.casting     = p_nameplate.form:FindChild("BarCasting")
		p_nameplate.cc 		= p_nameplate.form:FindChild("BarCC")

		if (not _matrix["ConfigBarIncrements"]) then
			p_nameplate.health:SetFullSprite("Bar_02")
			p_nameplate.health:SetFillSprite("Bar_02")
			p_nameplate.absorb:SetFullSprite("Bar_02")
			p_nameplate.absorb:SetFillSprite("Bar_02")
		end

		p_nameplate.casting:SetMax(100)

		local l_vOffset = _matrix["SliderVerticalOffset"]
		local l_fontH = l_font[l_fontSize].height
		local l_fontGuild = l_fontSize > 1 and l_fontSize - 1 or l_fontSize

		p_nameplate.form:SetAnchorOffsets(-200, -75 - l_vOffset, 200, 75 - l_vOffset)
		p_nameplate.iconArmor:SetFont(l_font[l_fontSize].font)
		
		p_nameplate.containerTop:SetAnchorOffsets(0, 0, 0, l_font[l_fontSize].height * 0.8)
		p_nameplate.iconUnit:SetAnchorOffsets(-l_fontH * 0.9, 0, l_fontH * 0.1, 0)

		p_nameplate.textUnitName:SetFont(l_font[l_fontSize].font)
		p_nameplate.textUnitLevel:SetFont(l_font[l_fontSize].font)
		p_nameplate.textUnitGuild:SetFont(l_font[l_fontGuild].font)
		p_nameplate.textUnitGuild:SetAnchorOffsets(0, 0, 0, l_font[l_fontGuild].height * 0.9)

		p_nameplate.containerCastBar:SetFont(l_font[l_fontSize].font)
		p_nameplate.containerCC:SetFont(l_font[l_fontSize].font)
		p_nameplate.containerCastBar:SetAnchorOffsets(0, 0, 0, (l_font[l_fontSize].height * 0.75) + l_h)
		p_nameplate.containerCC:SetAnchorOffsets(0, 0, 0, (l_font[l_fontSize].height * 0.75) + l_h)

		p_nameplate.containerMain:SetFont(l_font[l_fontSize].font)

		p_nameplate.casting:SetAnchorOffsets(-l_w, (l_h * 0.25), l_w, l_h)
		p_nameplate.cc:SetAnchorOffsets(-l_w, (l_h * 0.25), l_w, l_h)

		local l_armorWidth = p_nameplate.iconArmor:GetHeight() / 2
		p_nameplate.iconArmor:SetAnchorOffsets(-l_armorWidth, 0, l_armorWidth, 0)
	end

	p_nameplate.matrixFlags = self:GetMatrixFlags(p_nameplate)

	self:UpdateAnchoring(p_nameplate)

	p_nameplate.textUnitName:SetData(p_unit)
	p_nameplate.health:SetData(p_unit)
	p_nameplate.onScreen = p_nameplate.form:IsOnScreen()

	self:UpdateOpacity(p_nameplate)
	p_nameplate.containerCC:Show(false)
	p_nameplate.containerMain:Show(false)
	p_nameplate.containerCastBar:Show(false)
	p_nameplate.textUnitGuild:Show(false)
	p_nameplate.iconArmor:Show(false)

	p_nameplate.containerMain:SetText("")
	local l_heightMod = (p_nameplate.hasShield and 1.3 or 1)
	local l_shield = p_nameplate.hasShield and l_h * 1.3 or l_h
	local l_shieldHeightMod = _matrix["ConfigLargeShield"] and 0.5 or 0.35
	local l_shieldHeight = p_nameplate.health:GetHeight() * l_shieldHeightMod
	local l_healthText = _matrix["ConfigHealthText"] and (l_font[l_fontSize].height * 0.75) or 0

	p_nameplate.shield:Show(p_nameplate.hasShield)
	p_nameplate.health:SetAnchorOffsets(-l_w, 0, l_w, l_h * l_heightMod)
	p_nameplate.containerMain:SetAnchorOffsets(0, 0, 0, l_shield + l_healthText)
	p_nameplate.shield:SetAnchorOffsets(0, _min(-l_shieldHeight, -3), 0, 0)

	if (p_nameplate.hasHealth) then
		self:UpdateMainContainer(p_nameplate)
	end

	p_nameplate.colorFlags = self:GetColorFlags(p_nameplate)
	self:UpdateNameplateColors(p_nameplate)

	p_nameplate.containerIcons:DestroyAllPixies()
	if (p_nameplate.isPlayer) then
		self:UpdateIconsPC(p_nameplate)
	else
		self:UpdateIconsNPC(p_nameplate)
	end

	self:UpdateTextNameGuild(p_nameplate)
	self:UpdateTextLevel(p_nameplate)
	self:UpdateArmor(p_nameplate)
	self:InitClassIcon(p_nameplate)

	p_nameplate.form:Show(self:GetNameplateVisibility(p_nameplate), true)

	self:UpdateTopContainer(p_nameplate)

	p_nameplate.form:ArrangeChildrenVert(1)

	return p_nameplate
end

function NPrimeNameplates:OnUnitCreated(p_unit)
	_tableInsert(self.buffer, p_unit)
end

function NPrimeNameplates:UpdateBuffer()
	for i = 1, #self.buffer do
		local l_unit = self.buffer[i]
		if (l_unit ~= nil and l_unit:IsValid()) then
			self:AllocateNameplate(l_unit)
		end
		self.buffer[i] = nil
	end
end

function NPrimeNameplates:OnFrame()
	if (_player == nil) then
		_player = GameLib.GetPlayerUnit()
		if (_player ~= nil) then
			_playerPath = _paths[PlayerPathLib.GetPlayerPathType()]
			if (_player:GetTarget() ~= nil) then
				self:OnTargetUnitChanged(_player:GetTarget())
			end
			self:CheckMatrixIntegrity()
		end
	end

	if (_configUI == nil and _next(_matrix) ~= nil) then
		self:InitConfiguration()
	end

	if (_player == nil) then return end

	---------------------------------------------------------------------------
	
	_playerPos = _player:GetPosition()
	_blinded = _player:IsInCCState(Unit.CodeEnumCCState.Blind)

	for flag, flagValue in _pairs(_flags) do
		_flags[flag] = flagValue == 1 and 2 or flagValue
	end

	local l_c = 0
	for id, nameplate in _pairs(self.nameplates) do
		l_c = l_c + 1
		local l_cyclic = (l_c > _count and l_c < _count + _cycleSize)
		self:UpdateNameplate(nameplate, l_cyclic)
	end

	_count = (_count + _cycleSize > l_c) and 0 or _count + _cycleSize

	if (_targetNP ~= nil) then
		self:UpdateNameplate(_targetNP, true)
	end

	if (_configUI ~= nil and _configUI:IsVisible()) then
		self:UpdateConfiguration()
	end

	self:UpdateBuffer()

	for flag, flagValue in _pairs(_flags) do
		_flags[flag] = flagValue == 2 and 0 or flagValue
	end
end



function NPrimeNameplates:UpdateNameplate(p_nameplate, p_cyclicUpdate)
	local l_showCastingBar = GetFlag(p_nameplate.matrixFlags, F_CASTING_BAR)
	local l_showCCBar = GetFlag(p_nameplate.matrixFlags, F_CC_BAR)
	p_nameplate.onScreen = p_nameplate.form:IsOnScreen()
	p_nameplate.occluded = p_nameplate.form:IsOccluded()

	if (p_cyclicUpdate) then
		local l_distanceToUnit = self:DistanceToUnit(p_nameplate.unit)
		p_nameplate.outOfRange = l_distanceToUnit > _matrix["SliderDrawDistance"]
	end

	if (p_nameplate.onScreen) then
		local l_disposition = p_nameplate.unit:GetDispositionTo(_player)
		if (p_nameplate.disposition ~= l_disposition) then
			p_nameplate.disposition = l_disposition
			p_nameplate.type = _dispStr[l_disposition]
		end
	end

	local l_visible = self:GetNameplateVisibility(p_nameplate)
	if (p_nameplate.form:IsVisible() ~= l_visible) then
		p_nameplate.form:Show(l_visible, true)
	end

	if (l_showCCBar and p_nameplate.ccActiveID ~= -1) then
		self:UpdateCC(p_nameplate)
	end

	if (_flags.opacity == 2) then
		self:UpdateOpacity(p_nameplate) 
	end

	if (_flags.contacts == 2 and p_nameplate.isPlayer) then
		self:UpdateIconsPC(p_nameplate)
	end

	if (not l_visible) then return end

	---------------------------------------------------------------------------

	self:UpdateAnchoring(p_nameplate)

	if (l_showCastingBar) then
		self:UpdateCasting(p_nameplate)
	end

	self:UpdateArmor(p_nameplate)

	if (p_nameplate.hasHealth) then
		self:UpdateMainContainer(p_nameplate)
	end

	if (p_cyclicUpdate) then
		local l_colorFlags = self:GetColorFlags(p_nameplate)
		if (p_nameplate.colorFlags ~= l_colorFlags) then
			p_nameplate.colorFlags = l_colorFlags
			self:UpdateNameplateColors(p_nameplate)
		end

		if (not p_nameplate.isPlayer) then
			self:UpdateIconsNPC(p_nameplate)
		end
	end

	if (p_nameplate.rearrange) then
		p_nameplate.form:ArrangeChildrenVert(1)
		p_nameplate.rearrange = false
	end
end

function NPrimeNameplates:UpdateAnchoring(p_nameplate)
	local l_anchorUnit = p_nameplate.unit:IsMounted() and p_nameplate.unit:GetUnitMount() or p_nameplate.unit
	local l_reposition = false

	if (_matrix["ConfigDynamicVPos"] and not p_nameplate.isPlayer) then
		local l_overhead = p_nameplate.unit:GetOverheadAnchor()
		if (l_overhead ~= nil) then
			l_reposition = not p_nameplate.occluded and l_overhead.y < 25
		end
	end
	
	p_nameplate.form:SetUnit(l_anchorUnit, l_reposition and 0 or 1)
end

function NPrimeNameplates:UpdateMainContainer(p_nameplate)
	local l_health 		= p_nameplate.unit:GetHealth();
	local l_healthMax 	= p_nameplate.unit:GetMaxHealth();
	local l_shield 		= p_nameplate.unit:GetShieldCapacity();
	local l_shieldMax 	= p_nameplate.unit:GetShieldCapacityMax();
	local l_absorb 		= p_nameplate.unit:GetAbsorptionValue();
	local l_fullHealth 	= l_health == l_healthMax;
	local l_shieldFull 	= false;
	local l_hiddenBecauseFull = false;
	local l_isFriendly = p_nameplate.disposition == Unit.CodeEnumDisposition.Friendly

	if (p_nameplate.hasShield)
		then l_shieldFull = l_shield == l_shieldMax;
	end

	if (not p_nameplate.targetNP) then
		l_hiddenBecauseFull = (_matrix["ConfigSimpleWhenHealthy"] and l_fullHealth) or
							  (_matrix["ConfigSimpleWhenFullShield"] and l_shieldFull);
	end
        if (not p_nameplate.targetNP) then
		l_hiddenBecauseFull = (_matrix["ConfigSimpleWhenHealthy"] and l_fullHealth) and
							  (_matrix["ConfigSimpleWhenFullShield"] and l_shieldFull);
	end

	local l_matrixEnabled = GetFlag(p_nameplate.matrixFlags, F_HEALTH)
	local l_visible = l_matrixEnabled and not l_hiddenBecauseFull

	if (p_nameplate.containerMain:IsVisible() ~= l_visible) then
		p_nameplate.containerMain:Show(l_visible)
		p_nameplate.rearrange = true
	end

	if (l_visible) then
		if (l_health ~= prevHealth) then
			local l_temp = l_isFriendly and "SliderLowHealthFriendly" or "SliderLowHealth"
			if (_matrix[l_temp] ~= 0) then
				local l_cutoff = (_matrix[l_temp] / 100)
				local l_healthPct = l_health / l_healthMax
				p_nameplate.lowHealth = l_healthPct <= l_cutoff
			end
			self:SetProgressBar(p_nameplate.health, l_health, l_healthMax)
		end

		if (l_absorb ~= prevAbsorb) then
			self:SetProgressBar(p_nameplate.absorb, l_absorb, l_healthMax)
		end

		if (p_nameplate.hasShield and l_shield ~= prevShield) then
			self:SetProgressBar(p_nameplate.shield, l_shield, l_shieldMax)
		end

		if (_matrix["ConfigHealthText"]) then
			local l_shieldText = ""
			local l_healthText = self:GetNumber(l_health, l_healthMax)

			if (p_nameplate.hasShield and l_shield ~= 0) then
				l_shieldText = " (" .. self:GetNumber(l_shield, l_shieldMax) .. ")"
			end

			p_nameplate.containerMain:SetText(l_healthText .. l_shieldText)
		end
	end

	p_nameplate.prevHealth = l_health
	p_nameplate.prevShield = l_shield
	p_nameplate.prevAbsorb = l_absorb
end

function NPrimeNameplates:UpdateTopContainer(p_nameplate)
	local l_levelVisible = GetFlag(p_nameplate.matrixFlags, F_LEVEL)
	local l_classVisible = GetFlag(p_nameplate.matrixFlags, F_CLASS)
	p_nameplate.iconUnit:SetBGColor(l_classVisible and "FFFFFFFF" or "00FFFFFF")
	local l_width = p_nameplate.levelWidth + p_nameplate.textUnitName:GetWidth()
	local l_ratio = p_nameplate.levelWidth / l_width
	local l_middle = (l_width * l_ratio) - (l_width / 2)

	if (not l_levelVisible) then
		local l_extents = p_nameplate.textUnitName:GetWidth() / 2
		p_nameplate.textUnitLevel:SetTextColor("00FFFFFF")
		p_nameplate.textUnitLevel:SetAnchorOffsets(-l_extents - 5, 0, -l_extents, 1)
		p_nameplate.textUnitName:SetAnchorOffsets(-l_extents, 0, l_extents, 1)
	else
		p_nameplate.textUnitLevel:SetTextColor("FFFFFFFF")
		p_nameplate.textUnitLevel:SetAnchorOffsets(-(l_width / 2), 0, l_middle, 1)
		p_nameplate.textUnitName:SetAnchorOffsets(l_middle, 0, (l_width / 2), 1)
	end
end

function NPrimeNameplates:UpdateNameplateColors(p_nameplate, p_ccID, p_unit)
	local l_pvpFlagged 	= GetFlag(p_nameplate.colorFlags, F_PVP)
	local l_aggroLost 	= GetFlag(p_nameplate.colorFlags, F_AGGRO)
        local l_moo             = GetFlag(p_nameplate.colorFlags, F_MOO)
	local l_cleanse 	= GetFlag(p_nameplate.colorFlags, F_CLEANSE)
	local l_lowHP 		= GetFlag(p_nameplate.colorFlags, F_LOW_HP)
	local l_group		= GetFlag(p_nameplate.colorFlags, F_GROUP)

	local l_textColor = _typeColor[p_nameplate.type]
	local l_barColor = _dispColor[p_nameplate.disposition]

	local l_isHostile = p_nameplate.disposition == Unit.CodeEnumDisposition.Hostile
	local l_isFriendly = p_nameplate.disposition == Unit.CodeEnumDisposition.Friendly
	local l_isSelf	= self.nameplates
        local l_ispvp = p_nameplate.unit:IsPvpFlagged()
        
	p_nameplate.color = l_textColor
	
	if (p_nameplate.isPlayer) then
		if (not l_pvpFlagged and l_isHostile) then
			l_textColor = _dispColor[Unit.CodeEnumDisposition.Neutral]
			l_barColor = _dispColor[Unit.CodeEnumDisposition.Neutral]
			p_nameplate.color = l_textColor
		end
                if (l_isHostile and l_ispvp) then
			l_textColor = _typeColor["HostilePPVP"]
                else 
                        l_textColor = _typeColor["HostileP"]
		end
		if (l_isSelf and l_group) then
			l_textColor = _typeColor["Group"]
		end
		if (not l_group and l_isFriendly) then
			l_textColor = _typeColor["FriendlyP"]
		end
		if (l_cleanse and l_isFriendly) then
			l_barColor = _typeColor["Cleanse"]
		end
	else
		if (l_aggroLost and l_isHostile) then
			l_barColor = _typeColor["LowThreat"]
		end
	end
                if (l_moo) then
                    l_barColor = _typeColor["CC"]
                end
                
        if (l_lowHP) then
            l_barColor = _typeColor["LowHP"]
        end
			
	p_nameplate.textUnitName:SetTextColor(l_textColor)
	p_nameplate.textUnitGuild:SetTextColor(l_textColor)
	p_nameplate.health:SetBarColor(l_barColor)

	if (p_nameplate.targetNP and p_nameplate.targetMark ~= nil) then
		p_nameplate.targetMark:SetBGColor(p_nameplate.color)
	end
end

function NPrimeNameplates:GetColorFlags(p_nameplate)
	if (_player == nil) then return end

	local l_flags = SetFlag(0, p_nameplate.disposition)
	local l_isFriendly = p_nameplate.disposition == Unit.CodeEnumDisposition.Friendly
	local l_isMoo = p_nameplate.unit:GetCCStateTimeRemaining(Unit.CodeEnumCCState.Vulnerability)
        local l_ispvp = p_nameplate.unit:IsPvpFlagged()

	if (p_nameplate.inGroup) 	then l_flags = SetFlag(l_flags, F_GROUP) end
	if (p_nameplate.pvpFlagged)     then l_flags = SetFlag(l_flags, F_PVP) end
	if (p_nameplate.lowHealth) 	then l_flags = SetFlag(l_flags, F_LOW_HP) end
        if (l_isMoo > 0)                then l_flags = SetFlag(l_flags, F_MOO) end
            
	if (_matrix["ConfigAggroIndication"]) then
		if (p_nameplate.inCombat and not p_nameplate.isPlayer and p_nameplate.unit:GetTarget() ~= _player) then
			l_flags = SetFlag(l_flags, F_AGGRO)
		end
	end
        

	if (_matrix["ConfigCleanseIndicator"] and l_isFriendly) then
		local l_debuffs = p_nameplate.unit:GetBuffs()["arHarmful"]
		for i = 1, #l_debuffs do
			if (l_debuffs[i]["splEffect"]:GetClass() == Spell.CodeEnumSpellClass.DebuffDispellable) then
				l_flags = SetFlag(l_flags, F_CLEANSE)
			end
		end
	end

	return l_flags
end

function NPrimeNameplates:GetMatrixFlags(p_nameplate)
	local l_flags = 0
	local l_inCombat = p_nameplate.inCombat
	local l_type = p_nameplate.targetNP and "Target" or p_nameplate.type

	for i = 1, #_matrixCategories do
		local l_matrix = _matrix[_matrixCategories[i] .. l_type]
		if ((type(l_matrix) ~= "number") or (l_matrix == 3) or
			(l_matrix + (l_inCombat and 1 or 0) == 2)) then
			l_flags = SetFlag(l_flags, i - 1)
		end
	end

	if (not p_nameplate.hasHealth) then
		l_flags = ClearFlag(l_flags, F_HEALTH)
	end

	return l_flags
end

function SetFlag(p_flags, p_flag)
	return _or(p_flags, _lshift(1, p_flag))
end

function ClearFlag(p_flags, p_flag)
	return _and(p_flags, _xor(_lshift(1, p_flag), 65535))
end

function GetFlag(p_flags, p_flag)
	return _and(p_flags, _lshift(1, p_flag)) ~= 0
end

function NPrimeNameplates:GetNumber(p_current, p_max)
	if (p_current == nil or p_max == nil) then return "" end
	if (_matrix["ConfigHealthPct"]) then
		return _floor((p_current / p_max) * 100) .. "%"
	else
		return self:FormatNumber(p_current)
	end
end

function NPrimeNameplates:UpdateConfiguration()
	self:UpdateConfigSlider("SliderDrawDistance", 		50, 	155.0, "m")
	self:UpdateConfigSlider("SliderLowHealth", 	 		 0, 	101.0, "%")
	self:UpdateConfigSlider("SliderLowHealthFriendly", 	 0, 	101.0, "%")
	self:UpdateConfigSlider("SliderVerticalOffset", 	 0, 	101.0, "px")
	self:UpdateConfigSlider("SliderBarScale", 		    50, 	205.0, "%")
	self:UpdateConfigSlider("SliderFontSize", 			 1, 	  6.2)
end

function NPrimeNameplates:UpdateConfigSlider(p_name, p_min, p_max, p_labelSuffix)
	local l_slider = _configUI:FindChild(p_name)
	if (l_slider ~= nil) then
		local l_sliderVal = l_slider:FindChild("SliderBar"):GetValue()
		l_slider:SetProgress((l_sliderVal - p_min) / (p_max - p_min))
		l_slider:FindChild("TextValue"):SetText(l_sliderVal .. (p_labelSuffix or ""))
	end
end

function NPrimeNameplates:OnTargetUnitChanged(p_target)
	if (_player == nil) then return end 

	if (p_target ~= nil and self.nameplates[p_target:GetId()]) then
		self.nameplates[p_target:GetId()].form:Show(false, true)
	end

	if (p_target ~= nil) then
		local l_type = self:GetUnitType(p_target)
		if (_targetNP == nil) then
			_targetNP = self:InitNameplate(p_target, nil, l_type, true)

			if (_matrix["ConfigLegacyTargeting"]) then
				self:UpdateLegacyTargetPixie()
				_targetNP.form:AddPixie(_targetPixie)
			else
				_targetNP.targetMark = Apollo.LoadForm(self.xmlDoc, "Target Indicator", _targetNP.containerTop, self)
				local l_offset = _targetNP.targetMark:GetHeight() / 2
				_targetNP.targetMark:SetAnchorOffsets(-l_offset, 0, l_offset, 0)
				_targetNP.targetMark:SetBGColor(_targetNP.color)
			end
		else
			_targetNP = self:InitNameplate(p_target, _targetNP, l_type, true)

			if (_matrix["ConfigLegacyTargeting"]) then
				self:UpdateLegacyTargetPixie()
				_targetNP.form:UpdatePixie(1, _targetPixie)
			end
		end
	end

	_flags.opacity = 1
	_targetNP.form:Show(p_target ~= nil, true)
end

function NPrimeNameplates:UpdateLegacyTargetPixie()
	local l_width = _targetNP.textUnitName:GetWidth()
	local l_height = _targetNP.textUnitName:GetHeight()

	if (_targetNP.textUnitLevel:IsVisible()) then l_width = l_width + _targetNP.textUnitLevel:GetWidth() end
	if (_targetNP.textUnitGuild:IsVisible()) then l_height = l_height + _targetNP.textUnitGuild:GetHeight() end
	if (_targetNP.containerMain:IsVisible()) then l_height = l_height + _targetNP.containerMain:GetHeight() end

	l_height = (l_height / 2) + 30
	l_width = (l_width / 2) + 50

	l_width = l_width < 45 and 45 or (l_width > 200 and 200 or l_width)
	l_height = l_height < 45 and 45 or (l_height > 75 and 75 or l_height)

	_targetPixie.loc.nOffsets[1] = -l_width
	_targetPixie.loc.nOffsets[2] = -l_height
	_targetPixie.loc.nOffsets[3] =  l_width
	_targetPixie.loc.nOffsets[4] =  l_height
end

function NPrimeNameplates:OnTextBubble(p_unit, p_text)
	if (_player == nil) then return end

	local l_nameplate = self.nameplates[p_unit:GetId()]
	if (l_nameplate ~= nil) then
		self:ProcessTextBubble(l_nameplate, p_text)
	end
end

function NPrimeNameplates:ProcessTextBubble(p_nameplate, p_text)
	if (GetFlag(p_nameplate.matrixFlags, F_BUBBLE)) then
		self:UpdateOpacity(p_nameplate, (p_text ~= nil))
	end
end

function NPrimeNameplates:OnPlayerMainTextChanged()
	if (_player == nil) then return end
	self:OnUnitMainTextChanged(_player)
end

function NPrimeNameplates:OnUnitMainTextChanged(p_unit)
	if (p_unit == nil) then return end
	local l_nameplate = self.nameplates[p_unit:GetId()]
	if (l_nameplate ~= nil) then
		self:UpdateTextNameGuild(l_nameplate)
		self:UpdateTopContainer(l_nameplate)
	end
	if (_targetNP ~= nil and _player:GetTarget() == p_unit) then
		self:UpdateTextNameGuild(_targetNP)
		self:UpdateTopContainer(_targetNP)
	end
end

function NPrimeNameplates:OnUnitLevelChanged(p_unit)
	if (p_unit == nil) then return end
	local l_nameplate = self.nameplates[p_unit:GetId()]
	if (l_nameplate ~= nil) then
		self:UpdateTextLevel(l_nameplate)
		self:UpdateTopContainer(l_nameplate)
	end
	if (_targetNP ~= nil and _player:GetTarget() == p_unit) then
		self:UpdateTextLevel(_targetNP)
		self:UpdateTopContainer(_targetNP)
	end
end

function NPrimeNameplates:OnUnitActivationTypeChanged(p_unit)
	if (_player == nil) then return end

	local l_nameplate = self.nameplates[p_unit:GetId()]
	local l_hasActivationState = self:HasActivationState(p_unit)

	if (l_nameplate ~= nil) then
		l_nameplate.hasActivationState = l_hasActivationState
	elseif (l_hasActivationState) then
		self:AllocateNameplate(p_unit)
	end
	if (_targetNP ~= nil and _player:GetTarget() == p_unit) then
		_targetNP.hasActivationState = l_hasActivationState
	end
end

function NPrimeNameplates:OnChallengeUnlocked()
	self.challenges = ChallengesLib.GetActiveChallengeList()
end

-------------------------------------------------------------------------------

function string.starts(String, Start)
	return string.sub(String, 1, string.len(Start)) == Start
end

function NPrimeNameplates:OnConfigure(strCmd, strArg)
	if (strArg == "occlusion") then
		_matrix["ConfigOcclusionCulling"] = not _matrix["ConfigOcclusionCulling"]
		local l_occlusionString = _matrix["ConfigOcclusionCulling"] and "<Enabled>" or "<Disabled>"
		Print("[nPrimeNameplates] Occlusion culling " .. l_occlusionString)
	elseif ((strArg == nil or strArg == "") and _configUI ~= nil) then
		_configUI:Show(not _configUI:IsVisible(), true)
	end
end

-- Called from form
function NPrimeNameplates:OnConfigButton(p_wndHandler, p_wndControl, p_mouseButton)
	local l_name = p_wndHandler:GetName()

	if 	   (l_name == "ButtonClose") then _configUI:Show(false)
	elseif (l_name == "ButtonApply") then RequestReloadUI()
	elseif (string.starts(l_name, "Config")) then
		_matrix[l_name] = p_wndHandler:IsChecked()
	end
end

-- Called from form
function NPrimeNameplates:OnSliderBarChanged(p1, p_wndHandler, p_value, p_oldValue)
	local l_name = p_wndHandler:GetParent():GetName()
	if (_matrix[l_name] ~= nil) then
		_matrix[l_name] = p_value
	end
end

-- Called from form
function NPrimeNameplates:OnMatrixClick(p_wndHandler, wndCtrl, nClick)
	if (nClick ~= 0 and nClick ~= 1) then return end

	local l_parent = p_wndHandler:GetParent():GetParent():GetName()
	local l_key = l_parent .. p_wndHandler:GetName()
	local l_valueOld = _matrix[l_key]
	local l_xor = bit32.bxor(bit32.extract(l_valueOld, nClick), 1)
	local l_valueNew = bit32.replace(l_valueOld, l_xor, nClick)

	p_wndHandler:SetTooltip(self:GetMatrixTooltip(l_valueNew))

	_matrix[l_key] = l_valueNew
	p_wndHandler:SetSprite(_matrixButtonSprites[l_valueNew])
end

function NPrimeNameplates:CheckMatrixIntegrity()
	if (_type(_matrix["ConfigBarIncrements"]) ~= "boolean") 		then _matrix["ConfigBarIncrements"] 		= true end
	if (_type(_matrix["ConfigHealthText"]) ~= "boolean") 			then _matrix["ConfigHealthText"] 			= true end
	if (_type(_matrix["ConfigShowHarvest"]) ~= "boolean") 			then _matrix["ConfigShowHarvest"] 			= true end
	if (_type(_matrix["ConfigOcclusionCulling"]) ~= "boolean") 		then _matrix["ConfigOcclusionCulling"] 		= true end
	if (_type(_matrix["ConfigFadeNonTargeted"]) ~= "boolean") 		then _matrix["ConfigFadeNonTargeted"] 		= true end
	if (_type(_matrix["ConfigDynamicVPos"]) ~= "boolean") 			then _matrix["ConfigDynamicVPos"] 			= true end

	if (_type(_matrix["ConfigLargeShield"]) ~= "boolean") 			then _matrix["ConfigLargeShield"] 			= false end
	if (_type(_matrix["ConfigHealthPct"]) ~= "boolean") 			then _matrix["ConfigHealthPct"] 			= false end
	if (_type(_matrix["ConfigSimpleWhenHealthy"]) ~= "boolean") 	then _matrix["ConfigSimpleWhenHealthy"] 	= false end
	if (_type(_matrix["ConfigSimpleWhenFullShield"]) ~= "boolean") 	then _matrix["ConfigSimpleWhenFullShield"] 	= false end
	if (_type(_matrix["ConfigAggroIndication"]) ~= "boolean") 		then _matrix["ConfigAggroIndication"] 		= false end
	if (_type(_matrix["ConfigHideAffiliations"]) ~= "boolean") 		then _matrix["ConfigHideAffiliations"] 		= false end
	if (_type(_matrix["ConfigAlternativeFont"]) ~= "boolean") 		then _matrix["ConfigAlternativeFont"] 		= false end
	if (_type(_matrix["ConfigLegacyTargeting"]) ~= "boolean") 		then _matrix["ConfigLegacyTargeting"] 		= false end
	if (_type(_matrix["ConfigCleanseIndicator"]) ~= "boolean") 		then _matrix["ConfigCleanseIndicator"] 		= false end

	if (_type(_matrix["SliderDrawDistance"]) ~= "number") 			then _matrix["SliderDrawDistance"] 			= 100 end
	if (_type(_matrix["SliderLowHealth"]) ~= "number") 				then _matrix["SliderLowHealth"] 			= 30 end
	if (_type(_matrix["SliderLowHealthFriendly"]) ~= "number") 		then _matrix["SliderLowHealthFriendly"] 	= 0 end
	if (_type(_matrix["SliderVerticalOffset"]) ~= "number") 		then _matrix["SliderVerticalOffset"] 		= 20 end
	if (_type(_matrix["SliderBarScale"]) ~= "number") 				then _matrix["SliderBarScale"] 				= 100 end
	if (_type(_matrix["SliderFontSize"]) ~= "number") 				then _matrix["SliderFontSize"] 				= 1 end

	for i, category in _ipairs(_matrixCategories) do
		for j, filter in _ipairs(_matrixFilters) do
			local l_key = category .. filter
			if (type(_matrix[l_key]) ~= "number") then
				_matrix[l_key] = 3
			end
		end
	end
end

function NPrimeNameplates:InitConfiguration()
	_configUI = Apollo.LoadForm(self.xmlDoc, "Configuration", nil, self)
	_configUI:Show(false)

	local l_matrix = _configUI:FindChild("MatrixConfiguration")
	local l_rowHeight = (1 / #_matrixCategories)

	-- Matrix layout
	self:DistributeMatrixColumns(l_matrix:FindChild("RowNames"))
	for i, category in _ipairs(_matrixCategories) do
		local containerCategory = l_matrix:FindChild(category)
		containerCategory:SetAnchorPoints(0, l_rowHeight * (i - 1), 1, l_rowHeight * i)
		self:DistributeMatrixColumns(containerCategory, category)
	end

	for k, v in _pairs(_matrix) do
		if (string.starts(k, "Config")) then
			local l_button = _configUI:FindChild(k)
			if (l_button ~= nil) then
				l_button:SetCheck(v)
			end
		elseif (string.starts(k, "Slider")) then
			local l_slider = _configUI:FindChild(k)
			if (l_slider ~= nil) then
				l_slider:FindChild("SliderBar"):SetValue(v)
			end
		end
	end
end

function NPrimeNameplates:DistributeMatrixColumns(p_categoryWindow, p_categoryName)
	local l_columns = (1 / #_matrixFilters)
	for i, filter in _ipairs(_matrixFilters) do
		local l_left = l_columns * (i - 1)
		local l_right = l_columns * i
		local l_button = p_categoryWindow:FindChild(filter)

		l_button:SetAnchorPoints(l_left, 0, l_right, 1)
		l_button:SetAnchorOffsets(1, 1, -1, -1)
		
		if (p_categoryName ~= nil) then
			local l_value = _matrix[p_categoryName .. filter] or 0
			l_button:SetSprite(_matrixButtonSprites[l_value])
			l_button:SetStyle("IgnoreTooltipDelay", true)
			l_button:SetTooltip(self:GetMatrixTooltip(l_value))
		end
	end
end

function NPrimeNameplates:GetMatrixTooltip(p_value)
	if (p_value == 0) then return "Never enabled" end
	if (p_value == 1) then return "Enabled in combat" end
	if (p_value == 2) then return "Enabled out of combat" end
	if (p_value == 3) then return "Always enabled" end
	return "?"
end

function NPrimeNameplates:DistanceToUnit(p_unit)
	if (p_unit == nil) then return 0 end

	local l_pos = p_unit:GetPosition()
	if (l_pos == nil) then return 0 end
	if (l_pos.x == 0) then return 0 end

	local deltaPos = Vector3.New(l_pos.x - _playerPos.x, l_pos.y - _playerPos.y, l_pos.z - _playerPos.z)
	return deltaPos:Length()
end

-------------------------------------------------------------------------------

function NPrimeNameplates:FormatNumber(p_number)
	if (p_number == nil) then return "" end
	local l_result = p_number
	if 		p_number < 1000 then 			l_result = p_number
	elseif 	p_number < 1000000 then 		l_result = _weaselStr("$1f1k", 	p_number / 1000)
	elseif 	p_number < 1000000000 then 		l_result = _weaselStr("$1f1m", 	p_number / 1000000)
	elseif 	p_number < 1000000000000 then 	l_result = _weaselStr("$1f1b", 	p_number / 1000000)
	end
	return l_result
end

function NPrimeNameplates:UpdateTextNameGuild(p_nameplate)
	local l_showTitle = GetFlag(p_nameplate.matrixFlags, F_TITLE)
	local l_showGuild = GetFlag(p_nameplate.matrixFlags, F_GUILD)
	local l_hideAffiliation = _matrix["ConfigHideAffiliations"]
	local l_unit = p_nameplate.unit
	local l_name = l_showTitle and l_unit:GetTitleOrName() or l_unit:GetName()
	local l_guild = nil
	local l_fontSize = _matrix["SliderFontSize"]
	local l_font = _matrix["ConfigAlternativeFont"] and _fontSecondary or _fontPrimary
	local l_width = _textWidth(l_font[l_fontSize].font, l_name .. " ")

	if (l_showGuild and p_nameplate.isPlayer) then
		l_guild = l_unit:GetGuildName() and ("<" .. l_unit:GetGuildName() .. ">") or nil
	elseif (l_showGuild and not l_hideAffiliation and not p_nameplate.isPlayer) then
		l_guild = l_unit:GetAffiliationName() or nil
	end
	
	p_nameplate.textUnitName:SetText(l_name)
	p_nameplate.textUnitName:SetAnchorOffsets(0, 0, l_width, 0)

	local l_hasGuild = l_guild ~= nil and (_strLen(l_guild) > 0)
	if (p_nameplate.textUnitGuild:IsVisible() ~= l_hasGuild) then
		p_nameplate.textUnitGuild:Show(l_hasGuild)
		p_nameplate.rearrange = true
	end
	if (l_hasGuild) then
		p_nameplate.textUnitGuild:SetTextRaw(l_guild)
	end
end

function NPrimeNameplates:UpdateTextLevel(p_nameplate)
	local l_level = p_nameplate.unit:GetLevel()
	if (l_level ~= nil) then
		l_level = "Lv" .. l_level .. "   "
		local l_fontSize = _matrix["SliderFontSize"]
		local l_font = _matrix["ConfigAlternativeFont"] and _fontSecondary or _fontPrimary
		local l_width = _textWidth(l_font[l_fontSize].font, l_level)
		p_nameplate.levelWidth = l_width
		p_nameplate.textUnitLevel:SetText(l_level)
	else
		p_nameplate.levelWidth = 1
		p_nameplate.textUnitLevel:SetText("")
	end
end

function NPrimeNameplates:InitClassIcon(p_nameplate)
	local l_table = p_nameplate.isPlayer and _playerClass or _npcRank
	local l_icon = l_table[p_nameplate.unitClassID]
	p_nameplate.iconUnit:Show(l_icon ~= nil)
	p_nameplate.iconUnit:SetSprite(l_icon ~= nil and l_icon or "")
end

function NPrimeNameplates:OnCCStateApplied(p_ccID, p_unit)
	if (_ccWhiteList[p_ccID] == nil) then return end

	local l_nameplate = self.nameplates[p_unit:GetId()]

	if (l_nameplate ~= nil) then
		if (GetFlag(l_nameplate.matrixFlags, F_CC_BAR)) then
			self:RegisterCC(l_nameplate, p_ccID)
		end
	end

	if (_targetNP ~= nil and _targetNP.unit == p_unit) then
		if (GetFlag(_targetNP.matrixFlags, F_CC_BAR)) then
			self:RegisterCC(_targetNP, p_ccID)
		end
	end
end

function NPrimeNameplates:RegisterCC(p_nameplate, p_ccID)
	local l_duration = p_nameplate.unit:GetCCStateTimeRemaining(p_ccID)
	if (p_ccID == 9 or l_duration > p_nameplate.ccDuration) then
		p_nameplate.ccDurationMax = _max(l_duration, 0.1)
		p_nameplate.ccActiveID = p_ccID
		p_nameplate.containerCC:SetText(_ccWhiteList[p_ccID])
		p_nameplate.containerCC:Show(true)
		p_nameplate.rearrange = true
	end
end

function NPrimeNameplates:UpdateCC(p_nameplate)
	p_nameplate.ccDuration = p_nameplate.unit:GetCCStateTimeRemaining(p_nameplate.ccActiveID) or 0
	local l_show = p_nameplate.ccActiveID ~= -1
	if (p_nameplate.containerCC:IsVisible() ~= l_show) then
		p_nameplate.containerCC:Show(l_show)
		p_nameplate.rearrange = true
	end
	if (p_nameplate.ccDuration <= 0) then
		p_nameplate.ccActiveID = -1
		p_nameplate.containerCC:Show(false)
		p_nameplate.rearrange = true
	elseif (p_nameplate.form:IsVisible()) then
		if (p_nameplate.ccDuration > p_nameplate.ccDurationMax) then
			p_nameplate.ccDurationMax = p_nameplate.ccDuration
		end
		self:SetProgressBar(p_nameplate.cc, p_nameplate.ccDuration, p_nameplate.ccDurationMax)
	end
end

function NPrimeNameplates:UpdateCasting(p_nameplate)
	local l_showCastBar = p_nameplate.unit:ShouldShowCastBar()
	if (p_nameplate.containerCastBar:IsVisible() ~= l_showCastBar) then
		p_nameplate.containerCastBar:Show(l_showCastBar)
		p_nameplate.rearrange = true
	end
	if (l_showCastBar) then
		p_nameplate.casting:SetProgress(p_nameplate.unit:GetCastTotalPercent())
		p_nameplate.containerCastBar:SetText(p_nameplate.unit:GetCastName())
	end
end

function NPrimeNameplates:UpdateArmor(p_nameplate)
	local l_armorMax = p_nameplate.unit:GetInterruptArmorMax()
	local l_showArmor = GetFlag(p_nameplate.matrixFlags, F_ARMOR) and l_armorMax ~= 0

	if (p_nameplate.iconArmor:IsVisible() ~= l_showArmor) then
		p_nameplate.iconArmor:Show(l_showArmor)
	end

	if (not l_showArmor) then return end

	if (l_armorMax > 0) then
            p_nameplate.iconArmor:SetText(p_nameplate.unit:GetInterruptArmorValue())
            p_nameplate.iconArmor:SetTextColor("FFFFFFFF")
            p_nameplate.iconArmor:SetSprite("NPrimeNameplates_Sprites:IconArmor")
        end


	if (p_nameplate.prevArmor ~= l_armorMax) then
		p_nameplate.prevArmor = l_armorMax
		if (l_armorMax == -1) then
			p_nameplate.iconArmor:SetText("")
			p_nameplate.iconArmor:SetSprite("NPrimeNameplates_Sprites:IconArmor_02")
		elseif (l_armorMax > 0) then
			p_nameplate.iconArmor:SetSprite("NPrimeNameplates_Sprites:IconArmor")
		end
	end
        if p_nameplate.unit:GetInterruptArmorValue() <= 0 then
            p_nameplate.iconArmor:SetText("")
            p_nameplate.iconArmor:SetSprite("")
        end
        
end

function NPrimeNameplates:UpdateOpacity(p_nameplate, p_textBubble)
	if (p_nameplate.targetNP) then return end
	p_textBubble = p_textBubble or false

	if (p_textBubble) then
		p_nameplate.form:SetOpacity(0.25, 10)
	else
		local l_opacity = 1
		if (_matrix["ConfigFadeNonTargeted"] and _player:GetTarget() ~= nil) then
			l_opacity = 0.6
		end
		p_nameplate.form:SetOpacity(l_opacity, 10)
	end
end

function NPrimeNameplates:UpdateIconsNPC(p_nameplate)
	local l_flags = 0
	local l_icons = 0

	local l_rewardInfo = p_nameplate.unit:GetRewardInfo()
	if (l_rewardInfo ~= nil and _next(l_rewardInfo) ~= nil) then
		for i = 1, #l_rewardInfo do
			local l_type = l_rewardInfo[i].strType
			if (l_type == _playerPath) then
				l_icons = l_icons + 1
				l_flags = SetFlag(l_flags, F_PATH)
			elseif (l_type == "Quest") then
				l_icons = l_icons + 1
				l_flags = SetFlag(l_flags, F_QUEST)
			elseif (l_type == "Challenge") then
				local l_ID = l_rewardInfo[i].idChallenge
				local l_challenge = self.challenges[l_ID]
				if (l_challenge ~= nil and l_challenge:IsActivated()) then
					l_icons = l_icons + 1
					l_flags = SetFlag(l_flags, F_CHALLENGE)
				end
			end
		end
	end

	p_nameplate.isObjective = l_flags > 0

	if (l_flags ~= p_nameplate.iconFlags) then
		p_nameplate.iconFlags = l_flags
		p_nameplate.containerIcons:DestroyAllPixies()

		local l_height = p_nameplate.containerIcons:GetHeight()
		local l_width = 1 / l_icons
		local l_iconN = 0

		p_nameplate.containerIcons:SetAnchorOffsets(0, 0, l_icons * l_height, 0)

		if (GetFlag(l_flags, F_CHALLENGE)) then
			self:AddIcon(p_nameplate, "IconChallenge", l_iconN, l_width)
			l_iconN = l_iconN + 1
		end

		if (GetFlag(l_flags, F_PATH)) then
			self:AddIcon(p_nameplate, "IconPath", l_iconN, l_width)
			l_iconN = l_iconN + 1
		end

		if (GetFlag(l_flags, F_QUEST)) then
			self:AddIcon(p_nameplate, "IconQuest", l_iconN, l_width)
			l_iconN = l_iconN + 1
		end
	end
end

function NPrimeNameplates:UpdateIconsPC(p_nameplate)
	local l_flags = 0
	local l_icons = 0

	if (p_nameplate.unit:IsFriend() or
		p_nameplate.unit:IsAccountFriend()) then
		l_icons = l_icons + 1
		l_flags = SetFlag(l_flags, F_FRIEND)
	end

	if (p_nameplate.unit:IsRival()) then
		l_icons = l_icons + 1
		l_flags = SetFlag(l_flags, F_RIVAL)
	end

	if (l_flags ~= p_nameplate.iconFlags) then
		p_nameplate.iconFlags = l_flags
		p_nameplate.containerIcons:DestroyAllPixies()

		local l_height = p_nameplate.containerIcons:GetHeight()
		local l_width = 1 / l_icons
		local l_iconN = 0

		p_nameplate.containerIcons:SetAnchorOffsets(0, 0, l_icons * l_height, 0)

		if (GetFlag(l_flags, F_FRIEND)) then
			self:AddIcon(p_nameplate, "IconFriend", l_iconN, l_width)
			l_iconN = l_iconN + 1
		end

		if (GetFlag(l_flags, F_RIVAL)) then
			self:AddIcon(p_nameplate, "IconRival", l_iconN, l_width)
			l_iconN = l_iconN + 1
		end
	end
end

function NPrimeNameplates:AddIcon(p_nameplate, p_sprite, p_iconN, p_width)
	_iconPixie.strSprite = p_sprite
	_iconPixie.loc.fPoints[1] = p_iconN * p_width
	_iconPixie.loc.fPoints[3] = (p_iconN + 1) * p_width
	p_nameplate.containerIcons:AddPixie(_iconPixie)
end

function NPrimeNameplates:HasHealth(p_unit)
	if (p_unit:GetMouseOverType() == "Simple") 	then return false end
	if (p_unit:IsDead()) 						then return false end
	if (p_unit:GetMaxHealth() == nil) 			then return false end
	if (p_unit:GetMaxHealth() == 0) 			then return false end
	return true
end

function NPrimeNameplates:GetNameplateVisibility(p_nameplate)
	if (_blinded) 									then return false end

	if (p_nameplate.targetNP) then
		return _player:GetTarget() == p_nameplate.unit
	end

	if (_player:GetTarget() == p_nameplate.unit) 	then return false end

	if (not p_nameplate.onScreen) 					then return false end

	if (_matrix["ConfigOcclusionCulling"] and 
		p_nameplate.occluded) 						then return false end

	if (not GetFlag(p_nameplate.matrixFlags, F_NAMEPLATE)) then
		return p_nameplate.hasActivationState or p_nameplate.isObjective
	end

	if (p_nameplate.unit:IsDead()) 					then return false end
	if (p_nameplate.outOfRange)						then return false end

	local l_isFriendly = p_nameplate.disposition == Unit.CodeEnumDisposition.Friendly
	if (not p_nameplate.isPlayer and l_isFriendly) then
		return p_nameplate.hasActivationState or p_nameplate.isObjective
	end

	return true
end

function NPrimeNameplates:GetUnitType(p_unit)
	if (p_unit == nil) 			then return "Hidden" end
	if (not p_unit:IsValid()) 	then return "Hidden" end

	if (p_unit:CanBeHarvestedBy(_player)) then
		return _matrix["ConfigShowHarvest"] and "Other" or "Hidden"
	end

	if (p_unit:IsThePlayer()) 				then return "Self" end
	if (p_unit:IsInYourGroup()) 			then return "Group" end

	local l_type = p_unit:GetType()
	if (l_type == "BindPoint") 				then return "Other" end
	if (l_type == "PinataLoot") 			then return "Other" end
	if (l_type == "Ghost") 					then return "Hidden" end
	if (l_type == "Mount")	 				then return "Hidden" end

	local l_disposition = p_unit:GetDispositionTo(_player)

	if (_exceptions[p_unit:GetName()] ~= nil) then
		return _exceptions[p_unit:GetName()] and _dispStr[l_disposition] or "Hidden"
	end

	local l_rewardInfo = p_unit:GetRewardInfo()

	if (l_rewardInfo ~= nil and _next(l_rewardInfo) ~= nil) then
		for i = 1, #l_rewardInfo do
			if (l_rewardInfo[i].strType ~= "Challenge") then
				return _dispStr[l_disposition]
			end
		end
	end

	if (p_unit:IsACharacter() or self:HasActivationState(p_unit)) then
		return _dispStr[l_disposition]
	end

	if (p_unit:GetHealth() == nil) then return "Hidden" end

	local l_archetype = p_unit:GetArchetype()

	if (l_archetype ~= nil) then
		return _dispStr[l_disposition]
	end

	return "Hidden"
end

function NPrimeNameplates:SetCombatState(p_nameplate, p_inCombat)
	if (p_nameplate == nil) then return end
	if (p_nameplate.inCombat ~= p_inCombat) then
		p_nameplate.inCombat = p_inCombat
		p_nameplate.matrixFlags = self:GetMatrixFlags(p_nameplate)
		self:UpdateTopContainer(p_nameplate)
	end
end

function NPrimeNameplates:HasActivationState(p_unit)
	local l_activationStates = p_unit:GetActivationState()
	if (_next(l_activationStates) == nil) then return false end
	local l_show = false
	for state, a in _pairs(l_activationStates) do
		if (state == "Busy") then return false end
		if (not _asbl[state]) then l_show = true end
	end
	return l_show
end

function NPrimeNameplates:SetProgressBar(p_bar, p_current, p_max)
	p_bar:SetMax(p_max)
	p_bar:SetProgress(p_current)
end

function NPrimeNameplates:AllocateNameplate(p_unit)
	if (self.nameplates[p_unit:GetId()] == nil) then
		local l_type = self:GetUnitType(p_unit)
		if (l_type ~= "Hidden") then
			local l_nameplate = self:InitNameplate(p_unit, _tableRemove(self.pool) or nil, l_type)
			self.nameplates[p_unit:GetId()] = l_nameplate
		end
	end
end

function NPrimeNameplates:OnUnitDestroyed(p_unit)
	local l_nameplate = self.nameplates[p_unit:GetId()]
	if (l_nameplate == nil) then return end

	if (#self.pool < 50) then
		l_nameplate.form:Show(false, true)
		l_nameplate.form:SetUnit(nil)
		l_nameplate.textUnitName:SetData(nil)
		l_nameplate.health:SetData(nil)
		_tableInsert(self.pool, l_nameplate)
	else
		l_nameplate.form:Destroy()
	end
	self.nameplates[p_unit:GetId()] = nil
end

-------------------------------------------------------------------------------

local NPrimeNameplatesInst = NPrimeNameplates:new()
NPrimeNameplatesInst:Init()
