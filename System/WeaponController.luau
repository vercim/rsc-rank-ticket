local WeaponController = {}

--//Imports
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local CollectionService = game:GetService("CollectionService")
local RP = game:GetService("ReplicatedStorage")
local RS = game:GetService("RunService")
local log = require(RP:WaitForChild('Shared').Log)

local ToolsFolder = RP:WaitForChild('Assets').Weapons

--//Data storage
local weaponDataStore = DataStoreService:GetDataStore("WeaponDataStore")

--//Data table
WeaponController.PlayersData = {}

--//Default data
local defaultWeaponType = 'Longsword' --//test
local defaultWeaponSoul = 'Soulless'

--//Util functions
function createDefaultData()
	return {
		weaponType = defaultWeaponType,
		weaponSoul = defaultWeaponSoul,
	}
end


function giveTool(player, weaponType)
	if not player or not weaponType then return end
	
	local function findChildWithAttribute(parent, attributeName, value)
		for _, child in ipairs(parent:GetChildren()) do
			if child:GetAttribute(attributeName) == value then
				return child
			end
		end
		return nil
	end

	local Backpack = player:WaitForChild("Backpack")
	local tool = findChildWithAttribute(ToolsFolder,'weaponType', weaponType)
	
	if tool and CollectionService:HasTag(tool, 'Weapon') then
		tool:Clone().Parent = Backpack
	else
		log.error(script.Name, `tool {weaponType} not found in assets`)
	end	
end

function removeTool(player, weaponType)
	if not player or not weaponType then return end

	local Char = player.Character
	local Backpack = player:WaitForChild("Backpack")

	for _, tool in ipairs(Char:GetChildren()) do
		if tool:IsA("Tool") and CollectionService:HasTag(tool, "Weapon") and tool:GetAttribute('weaponType')==weaponType then
			tool:Destroy()
		end
	end

	for _, tool in ipairs(Backpack:GetChildren()) do
		if tool:IsA("Tool") and CollectionService:HasTag(tool, "Weapon") and tool:GetAttribute('weaponType')==weaponType then
			tool:Destroy()
		end
	end
end

--//Functions

--//With tools
function WeaponController:UpdateTool(player)
	local tool:Tool = self:GetTool(player)
	local newTool = self:GetDataField(player, 'weaponType')
	
	if not tool then
		giveTool(player, newTool)
	else
		if tool:GetAttribute('weaponType') ~= newTool then
			removeTool(player, tool:GetAttribute('weaponType'))
			giveTool(player, newTool)
		end
	end
end

function WeaponController:GetTool(player)
	if not player then return end

	local Char = player.Character or player.CharacterAdded:Wait()
	local Backpack = player:WaitForChild("Backpack")

	local function findTool(source)
		for _, tool in ipairs(source:GetChildren()) do
			if tool:IsA("Tool") and CollectionService:HasTag(tool, "Weapon") then
				return tool
			end
		end
		return nil
	end

	return findTool(Char) or findTool(Backpack)
end

function WeaponController:GetWeaponModule(weaponType:string)
	if not weaponType then return end
	local module: ModuleScript = RP:WaitForChild('Weapons'):FindFirstChild(weaponType)
	if module then return require(module) end
	log.error(script.Name, `{weaponType} module not found`)
	return nil
end

function WeaponController:GetWeaponAnims(weaponType:string)
	if not weaponType then return end
	local anims: Folder = RP:WaitForChild('Animations').Combat.Weapons:FindFirstChild(weaponType)
	if not anims then log.error(script.Name, `{weaponType} animations not found`) end
	return anims
end

--//With data private
function GetWeaponData(player)
	if typeof(player) == "Instance" and player:IsA("Player") then
		local userId = tostring(player.UserId)
		return WeaponController.PlayersData[userId]
	end
	return nil
end

function SetWeaponData(player, data)
	if typeof(player) == "Instance" and player:IsA("Player") then
		local userId = tostring(player.UserId)
		WeaponController.PlayersData[userId] = data
		
		WeaponController:UpdateTool(player)
		
		if _G.UpdateWeaponLeaderboard then
			_G.UpdateWeaponLeaderboard(player)
		end
		
		return true
	end
	return false
end

--//With data public
function WeaponController:GetDataField(player, key)
	local data = GetWeaponData(player)
	if data then
		return data[key]
	end
	return nil
end

function WeaponController:SetDataField(player, key, value)
	local data
	
	if key == 'weaponType' then
		data = {
			weaponType = value, weaponSoul = self:GetDataField(player, 'weaponSoul')
		}
	elseif key == 'weaponSoul' then
		data = {
			weaponType = self:GetDataField(player, 'weaponType'), weaponSoul = value
		}
	else
		log.error(script.Name, 'unknown data key')
		return false
	end
	
	SetWeaponData(player, data)

	WeaponController:UpdateTool(player)

	if _G.UpdateWeaponLeaderboard then
		_G.UpdateWeaponLeaderboard(player)
	end
	
	return true
end

function WeaponController:LoadPlayerData(player)
	if typeof(player) == "Instance" and player:IsA("Player") then
		local userId = tostring(player.UserId)
		local success, result = pcall(function()
			return weaponDataStore:GetAsync(userId)
		end)
		
		if success then
			if result then
				self.PlayersData[userId] = result
			else
				self.PlayersData[userId] = createDefaultData()
			end
			
			return self.PlayersData[userId]
		else
			log.warn(script.Name, `Failed to load weapon data for player {player.Name}: {tostring(result)}`)
			self.PlayersData[userId] = createDefaultData()
			return self.PlayersData[userId]
		end
	end
	return nil
end

function WeaponController:SavePlayerData(player)
	if typeof(player) == "Instance" and player:IsA("Player") then
		local userId = tostring(player.UserId)
		local data = self.PlayersData[userId]
		
		if data then
			local success, err = pcall(function()
				weaponDataStore:SetAsync(userId, data)
			end)
			
			if not success then
				log.error(script.Name, `Failed to save weapon data for player {player.Name}: {tostring(err)}`)
				return false
			end
			
			log.log(script.Name, `Saved weapon data for {player.Name}`)
			return true
		end
	end
	return false
end

function WeaponController:ClearPlayerData(player)
	if typeof(player) == "Instance" and player:IsA("Player") then
		local userId = tostring(player.UserId)
		self.PlayersData[userId] = nil
	end
end

function WeaponController:SaveAndClearPlayerData(player)
	self:SavePlayerData(player)
	self:ClearPlayerData(player)
end

function WeaponController:SaveAllPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		self:SavePlayerData(player)
	end
end

--//Players processing
local function onCharacterAdded(player, character)
	WeaponController:UpdateTool(player)
end

local function onPlayerAdded(player)
	local data = WeaponController:LoadPlayerData(player)
	if data then
		log.log(script.Name, `Loaded weapon data for {player.Name}: {data.weaponType}, {data.weaponSoul}`)
		
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
		
		if player.Character then
			onCharacterAdded(player, player.Character)
		end
		
		if _G.UpdateWeaponLeaderboard then
			_G.UpdateWeaponLeaderboard(player)
		end
	end
end

local function onPlayerRemoving(player)
	WeaponController:SaveAndClearPlayerData(player)
end

--//Initialize
function WeaponController:init()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			onPlayerAdded(player)
		end)
	end
	

	game:BindToClose(function()
		if RS:IsStudio() then return end
		WeaponController:SaveAllPlayers()
		log.log(script.Name, "Saved all player data on server close")
	end)
end

return WeaponController
