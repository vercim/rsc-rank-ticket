local InputController = {}

--//Imports
local CAS = game:GetService("ContextActionService")
local RP = game:GetService("ReplicatedStorage")
local remotes = require(RP:WaitForChild('Shared').remotes)

local function InputProcessing(actionName, inputState)
	if actionName == "MouseButton1" or actionName == "MouseButton2" then 
		remotes.combatInput:fire("Attack", inputState, os.clock())
		
		return Enum.ContextActionResult.Pass
		
	elseif actionName == "Block" then 
		remotes.combatInput:fire("Block", inputState, os.clock())
	end

end

--//Binds
local function BindInput()
	CAS:BindAction(
		"MouseButton1", 
		InputProcessing, 
		false, 
		Enum.UserInputType.MouseButton1
	)
	CAS:BindAction(
		"MouseButton2", 
		InputProcessing, 
		false,
		Enum.UserInputType.MouseButton2
	)
	CAS:BindAction(
		"Block", 
		InputProcessing, 
		false, 
		Enum.KeyCode.F
	)
end

--//Initialize
function InputController:init()
	BindInput()
end

return InputController
