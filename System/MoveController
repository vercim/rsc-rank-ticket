local MoveController = {}

--//Imports
local Http = game:GetService("HttpService")
local SSS = game:GetService("ServerScriptService")
local StateController = require(SSS:WaitForChild("System").StateController)

--//Data table
MoveController.Effects = {}

--//Params
local defaultWalkSpeed = 10
local minimalSpeed = 0.5

--//Util functions
function updateSpeed(player, hum:Humanoid)
	if not MoveController.Effects[player] then return end
	
	local strongest = 0
	for _, effect in MoveController.Effects[player] do
		if effect.strength > strongest then strongest = effect.strength end
	end
	
	local speed = strongest~=0 and defaultWalkSpeed * (1 - strongest / 100) or defaultWalkSpeed
	hum.WalkSpeed = math.max(speed, minimalSpeed)
end

--//Functions
function MoveController:Slow(char, strength:number, _time:number)
	if not char or not strength then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local player = game.Players:GetPlayerFromCharacter(char)
	if not hum or not player then return end
	
	if not self.Effects[player] then self.Effects[player] = {} end
	
	strength = math.clamp(strength, 0, 100)
	local newEffect = { strength = strength, time = _time or nil, guid = Http:GenerateGUID(false) }
	table.insert(self.Effects[player], newEffect)
	
	updateSpeed(player, hum)
	
	if _time then
		task.delay(_time,function()
			if not self.Effects[player] or self.Effects[player] == {} then return end
			
			for _, e in self.Effects[player] do
				if e == newEffect then
					table.remove(self.Effects[player], table.find(self.Effects[player], e))
				end
			end

			updateSpeed(player, hum)
		end)
	end
	
	return newEffect.guid
end

function MoveController:RemoveSlow(char, guid:string)
	local player = game.Players:GetPlayerFromCharacter(char)
	if not player or not guid then return end
	
	if not self.Effects[player] then return end
	
	for _, effect in self.Effects[player] do
		if effect.guid == guid then
			table.remove(self.Effects[player], table.find(self.Effects[player], effect))
		end
	end
	
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then updateSpeed(player, hum) end
end

--//Initialize
game.Players.PlayerAdded:Connect(function(Plr)
	MoveController.Effects[Plr] = {}
end)

game.Players.PlayerRemoving:Connect(function(Plr)
	MoveController.Effects[Plr] = nil
end)

return MoveController
