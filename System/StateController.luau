local StateController = {}

--//Imports
local Players = game:GetService("Players")
local RP = game:GetService("ReplicatedStorage")
local remotes = require(RP:WaitForChild('Shared').remotes)

--//Data tables
StateController.States = {}

--//Util functions
function updateDebug(plr: Player)
	local data

	if plr then data = StateController.States[plr] or {}
	else data = StateController.States or {} end

	remotes.dataRouter.updateState:fire(plr, data)
end

--//Functions
function StateController:ReturnStates(plr: Player)
	if not plr or not plr.UserId then return end
	return self.States[plr]
end

function StateController:GetState(plr: Player, stateKey)
	if not plr or not plr.UserId then return end
	if self.States[plr] then
		if stateKey then
			return self.States[plr][stateKey]
		else
			return self.States[plr]
		end
	end
	return nil
end

function StateController:SetState(plr: Player, stateKey:string, value:boolean, duration:number)
	if not plr or not plr.UserId then return end
	if not self.States[plr] then
		self.States[plr] = {}
	end

	self.States[plr][stateKey] = value

	if duration then
		task.delay(duration,function()
			if self.States[plr] then
				self.States[plr][stateKey] = nil

				if next(self.States[plr]) == nil then
					self.States[plr] = nil
				end
				updateDebug(plr)
			end
		end)
	end

	updateDebug(plr)
end

function StateController:RemoveState(plr: Player, stateKey)
	if not plr or not plr.UserId then return end
	if not self.States[plr] then return end

	if stateKey then
		self.States[plr][stateKey] = nil
		if next(self.States[plr]) == nil then
			self.States[plr] = nil
		end
	else
		self.States[plr] = nil
	end

	updateDebug(plr)
end

function StateController:ClearAllStates()
	for plr in pairs(self.States) do
		self.States[plr] = nil
	end

	updateDebug()
end

--//Initialize
function StateController:init()
	Players.PlayerRemoving:Connect(function(plr)
		if not plr or not plr.UserId then return end
		self.States[plr] = nil
	end)
end

return StateController
