require "Window"
require "GameLib"
require "PlayerPathLib"
require "Item"
require "Money"

-----------------------------------------------------------------------------------------------
-- Module Initialization
-----------------------------------------------------------------------------------------------
local GeneralistEx = {}

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local kcrEnabledColor = ApolloColor.new("UI_BtnTextHoloNormal")
local kcrDisabledColor = ApolloColor.new("Disabled")
local strTooltip = "<p font=\"CRB_InterfaceSmall\" TextColor=\"white\">%s</p>"
local karCostumeIdToSlots = {
  [GameLib.CodeEnumEquippedItems.Chest] = Apollo.GetString("InventorySlot_Chest"),
  [GameLib.CodeEnumEquippedItems.Legs] = Apollo.GetString("InventorySlot_Legs"),
  [GameLib.CodeEnumEquippedItems.Head] = Apollo.GetString("InventorySlot_Head"),
  [GameLib.CodeEnumEquippedItems.Shoulder] = Apollo.GetString("InventorySlot_Shoulder"),
  [GameLib.CodeEnumEquippedItems.Feet] = Apollo.GetString("InventorySlot_Feet"),
  [GameLib.CodeEnumEquippedItems.Hands] = Apollo.GetString("InventorySlot_Hands"),
  [GameLib.CodeEnumEquippedItems.WeaponPrimary] = Apollo.GetString("CRB_Weapon"),
}
local karClassToIcon = {
  [GameLib.CodeEnumClass.Warrior] = "IconSprites:Icon_Windows_UI_CRB_Warrior",
  [GameLib.CodeEnumClass.Engineer] = "IconSprites:Icon_Windows_UI_CRB_Engineer",
  [GameLib.CodeEnumClass.Esper] = "IconSprites:Icon_Windows_UI_CRB_Esper",
  [GameLib.CodeEnumClass.Medic] = "IconSprites:Icon_Windows_UI_CRB_Medic",
  [GameLib.CodeEnumClass.Stalker] = "IconSprites:Icon_Windows_UI_CRB_Stalker",
  [GameLib.CodeEnumClass.Spellslinger] = "IconSprites:Icon_Windows_UI_CRB_Spellslinger"
}
local karClassToString = {
  [GameLib.CodeEnumClass.Warrior] = Apollo.GetString("CRB_Warrior"),
  [GameLib.CodeEnumClass.Engineer] = Apollo.GetString("CRB_Engineer"),
  [GameLib.CodeEnumClass.Esper] = Apollo.GetString("CRB_Esper"),
  [GameLib.CodeEnumClass.Medic] = Apollo.GetString("CRB_Medic"),
  [GameLib.CodeEnumClass.Stalker] = Apollo.GetString("ClassStalker"),
  [GameLib.CodeEnumClass.Spellslinger] = Apollo.GetString("CRB_Spellslinger")
}
local karPathToIcon = {
  [PlayerPathLib.PlayerPathType_Explorer] = "CRB_PlayerPathSprites:spr_Path_Explorer_Stretch",
  [PlayerPathLib.PlayerPathType_Soldier] = "CRB_PlayerPathSprites:spr_Path_Soldier_Stretch",
  [PlayerPathLib.PlayerPathType_Settler] = "CRB_PlayerPathSprites:spr_Path_Settler_Stretch",
  [PlayerPathLib.PlayerPathType_Scientist] = "CRB_PlayerPathSprites:spr_Path_Scientist_Stretch"
}
local karPathToString = {
  [PlayerPathLib.PlayerPathType_Explorer] = Apollo.GetString("PlayerPathExplorer"),
  [PlayerPathLib.PlayerPathType_Soldier] = Apollo.GetString("PlayerPathSoldier"),
  [PlayerPathLib.PlayerPathType_Settler] = Apollo.GetString("PlayerPathSettler"),
  [PlayerPathLib.PlayerPathType_Scientist] = Apollo.GetString("PlayerPathScientist"),
}
local karCurrency = {           
  { eType = Money.CodeEnumCurrencyType.Renown, strTitle = Apollo.GetString("CRB_Renown"), strDescription = Apollo.GetString("CRB_Renown_Desc") },
  { eType = Money.CodeEnumCurrencyType.ElderGems, strTitle = Apollo.GetString("CRB_Elder_Gems"), strDescription = Apollo.GetString("CRB_Elder_Gems_Desc") },
  { eType = Money.CodeEnumCurrencyType.Prestige, strTitle = Apollo.GetString("CRB_Prestige"), strDescription = Apollo.GetString("CRB_Prestige_Desc") },
  { eType = Money.CodeEnumCurrencyType.CraftingVouchers, strTitle = Apollo.GetString("CRB_Crafting_Vouchers"), strDescription = Apollo.GetString("CRB_Crafting_Voucher_Desc") },
  { eType = Money.CodeEnumCurrencyType.Credits, strTitle = Apollo.GetString(), strDescription = Apollo.GetString() },
  { eType = Money.CodeEnumCurrencyType.Glory, strTitle = Apollo.GetString("CRB_Glory"), strDescription = Apollo.GetString("CRB_Glory_Desc") },
  { eType = Money.CodeEnumCurrencyType.GroupCurrency, strTitle = Apollo.GetString(), strDescription = Apollo.GetString() },
  { eType = Money.CodeEnumCurrencyType.ShadeSilver, strTitle = Apollo.GetString(), strDescription = Apollo.GetString() },
}
local frmOriginalItemToolTipForm = nil
local karBogusRecipes = {
  [18761] = "Spider Stir Fry",
  [29632] = "Enhanced Spider Stir-Fry"
}

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function GeneralistEx:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  
  o.tItems = {}                       -- Keep track of all items
  o.tAltData = {}                     -- Keep track of all alt data
  o.tBogusRecipes = karBogusRecipes   -- Keep track of all known bogus recipes
  o.wndSelectedListItem = nil         -- Keep track of which list item is currently selected.
  
  return o
end

function GeneralistEx:Init()
  local bHasConfigureFunction = false
  local strConfigureButtonText = ""
  local tDependencies = {}
  
  Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end

-----------------------------------------------------------------------------------------------
-- OnLoad
-- 
-- This function is called by the client when the Addon is being loaded.
-- We use this opportunity to build up the Form of our Addon using the local xml file.
-- Because we are hooking into the ToolTip of the game, we need to store the original
-- Callbacks and insert our owns that call the original ones plus our own.
-----------------------------------------------------------------------------------------------
function GeneralistEx:OnLoad()
  -- Load our form from the XML.
  self.xmlDoc = XmlDoc.CreateFromFile("GeneralistEx.xml")
  self.xmlDoc:RegisterCallback("OnDocLoaded", self)
  
  -- Load our version info.
  self.strVersion = XmlDoc.CreateFromFile("toc.xml"):ToTable().Version
  
  -- Initialize the hook for tooltips.
  -- This might not work based on which Tooltip Addon is being used.
  local hToolTip = Apollo.GetAddon("ToolTips")
  
  -- If this loaded too early, or the Addon is disabled due another Addon replacing it
  -- or the User disabled his tooltips for some reason, then signal the user.
  if hToolTip == nil then
    Print("Sorry, but GeneralistEx managed to load before the ToolTips Addon loaded.")
    Print("Or you are using an Addon that has replaced the ToolTips Addon.")
    Print("GeneralistEx might not be able to display the information inside the Tooltips about items and schematics.")
    Print("Doing a /reloadui might fix this, but is not guaranteed")
    
    return
  end
  
  -- Preserve the original callback call
  local originalCreateCallNames = hToolTip.CreateCallNames
  
  -- Create a new callback so we can hook into it.
  hToolTip.CreateCallNames = function(luaCaller)
    -- First, call the original function to create the original callbacks and set up the tooltip.
    originalCreateCallNames(luaCaller)
    
    -- Save the original form.
    frmOriginalItemToolTipForm = Tooltip.GetItemTooltipForm
    
    -- Now create a new callback function for the item form.
    Tooltip.GetItemTooltipForm = function(luaCaller, wndControl, item, bStuff, nCount)
      return self.ItemToolTip(luaCaller, wndControl, item, bStuff, nCount)
    end
  end
end

-----------------------------------------------------------------------------------------------
-- OnDocLoaded
--
-- This is a callback executed when the xml form in the OnLoad method has been properly loaded
-- by the client. This signals us that all information is avaialble.
-- We use this opportunity to load our forms.
-----------------------------------------------------------------------------------------------
function GeneralistEx:OnDocLoaded()
  -- Double check whether the document has been properly loaded.
  if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
    -- Set up the main window of the Addon
    self.wndMain = Apollo.LoadForm(self.xmlDoc, "GeneralistForm", nil, self)
    
    -- If we could not load the main form for whatever reason, throw an error.
    if self.wndMain == nil then
      Apollo.AddAddonErrorText(self, "Could not load the main window for some reason")
      return
    end
    
    -- Keep the main window hidden for now
    self.wndMain:Show(false, true)
    
    -- Build up the various sub windows of the Addon and keep a reference to them
    -- for easy and fast access, and keeping loading resoures down.
    self.wndCharacterList = self.wndMain:FindChild("CharList")
    
    -- Set the version number in the title bar.
    self.wndMain:FindChild("Backing"):FindChild("Title"):SetText("GeneralistEx v"..self.strVersion)
    
    -- Register the slash command to invoke the window.
    Apollo.RegisterSlashCommand("gen", "OnSlashCommand", self)
    
    -- Register our event handlers, so we can hook in on the correct events we need.
    Apollo.RegisterEventHandler("LogOut", "UpdateCurrentCharacter", self)
    Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", "OnInterfaceMenuListHasLoaded", self)
    Apollo.RegisterEventHandler("ToggleGeneralistEx", "OnSlashCommand", self)
    Apollo.RegisterEventHandler("TradeskillAchievementComplete", "GetTradeskills", self)
    Apollo.RegisterEventHandler("TradeSkill_Learned", "GetTradeskills", self)
    Apollo.RegisterEventHandler("CraftingSchematicLearned", "GetTradeskills", self)
    Apollo.RegisterEventHandler("LootedItem", "GetCharInventory", self)
    Apollo.RegisterEventHandler("LootedMoney", "GetCharCash", self)
    Apollo.RegisterEventHandler("ItemAdded", "GetCharInventory", self)
    Apollo.RegisterEventHandler("ItemRemoved", "GetCharInventory", self)
    Apollo.RegisterEventHandler("ItemModified", "GetCharInventory", self)
    Apollo.RegisterEventHandler("PlayerLevelChange", "GetCharLevel", self)
    Apollo.RegisterEventHandler("ItemSentToCrate", "GetCharDecor", self)
    Apollo.RegisterEventHandler("DyeLearned", "GetCharDyes", self)
    Apollo.RegisterEventHandler("ChangeWorld", "OnChangeWorld", self)
    
    -- Register a timer until we can load the player info.
    -- Reason is a race condition between loading the character and the Addon.
    -- By delaying the loading with a timer, we secure our Addon against nil errors.
    -- The timer will be reset every time we swap worls/maps
    self.tmrLoadTimer = ApolloTimer.Create(2, true, "OnTimer", self)
  end
end

---------------------------------------------------------------------------------------------------
-- OnTimer
--
-- This function is triggered by our timer when the allotted time has passed.
-- We use this opportunity to properly load the character data or reset the timer when not possible
---------------------------------------------------------------------------------------------------
function GeneralistEx:OnTimer()
  local unitPlayer = GameLib.GetPlayerUnit()
  
  -- If we could not load our player character, exit the function
  -- and let the timer trigger the function again.
  if unitPlayer == nil then return end
  
  -- We didn't return, so our character data is available.
  -- Kill the timer and update the currently played Character.
  self.tmrLoadTimer = nil
  self:UpdateCurrentCharacter()
end

---------------------------------------------------------------------------------------------------
-- OnChangeWorld
--
-- This function is triggered every time the player enters a different world/map.
-- We use this opportunity to reset the loading timer, so we can safely load the character 
-- information.
---------------------------------------------------------------------------------------------------
function GeneralistEx:OnChangeWorld()
  self.tmrLoadTimer = ApolloTimer.Create(2, true, "OnTimer", self)
end

---------------------------------------------------------------------------------------------------
-- OnInterfaceMenuListHasLoaded
--
-- This function is triggered when the client has finished loading the Interface menu list.
-- We use this option to inject an entry for ourselves in that menu for easy access.
---------------------------------------------------------------------------------------------------
function GeneralistEx:OnInterfaceMenuListHasLoaded()
  Event_FireGenericEvent("InterfaceMenuList_NewAddon", "GeneralistEx", { "ToggleGeneralistEx", "", "ChatLogSprites:CombatLogSaveLogBtnNormal" })
end

---------------------------------------------------------------------------------------------------
-- OnSlashCommand
--
-- This function is called whenever the user types the /gen command in the game.
-- When this happens, we show the main window of the Addon
---------------------------------------------------------------------------------------------------
function GeneralistEx:OnSlashCommand()
  self.wndMain:Invoke()
  self:PopulateCharList()
end