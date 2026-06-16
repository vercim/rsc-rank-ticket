local CooldownController = {}

--//Imports
local Players = game:GetService("Players")
local RP = game:GetService("ReplicatedStorage")

--//Data table
CooldownController.Cooldowns = {}

--//Functions
function CooldownController:GetCooldown(Plr, ActionName:string)
	if not Plr or not Plr.UserId then return end
	if not self.Cooldowns[Plr.UserId] then return end

	self.Cooldowns[Plr.UserId] = self.Cooldowns[Plr.UserId] or {}
	return self.Cooldowns[Plr.UserId][ActionName]
end

function CooldownController:SetCooldown(Plr, ActionName:string, Time:number)
	if not Plr or not Plr.UserId then return end
	if not self.Cooldowns[Plr.UserId] then 
		self.Cooldowns[Plr.UserId] = {}
	end

	self.Cooldowns[Plr.UserId] = self.Cooldowns[Plr.UserId] or {}
	self.Cooldowns[Plr.UserId][ActionName] = {
		cooldown = Time,
		lastUsed = time()
	}
end

function CooldownController:CanAction(Plr, ActionName:string)
	if not Plr or not Plr.UserId then return end

	if not self.Cooldowns[Plr.UserId] then return true end
	local ActionData = self.Cooldowns[Plr.UserId][ActionName]

	if not ActionData then return true end

	return (time() - ActionData.lastUsed) >= ActionData.cooldown
end

--//Initialize
function CooldownController:init()
	Players.PlayerRemoving:Connect(function(Plr)
		if not Plr or not Plr.UserId then return end
		self.Cooldowns[Plr.UserId] = nil
	end)
end

return CooldownController
