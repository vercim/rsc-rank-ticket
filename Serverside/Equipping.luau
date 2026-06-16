--//Imports
local RP = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local SS = game:GetService("SoundService")
local SSS = game:GetService("ServerScriptService")
local SoundController = require(RP:WaitForChild('Shared').SoundController)
local AnimationController = require(RP:WaitForChild('Shared').AnimationController)
local StateController = require(SSS:WaitForChild('System').StateController)
local equipAnim = RP:WaitForChild('Animations').Combat.Equip
local toolGripAnim =RP:WaitForChild('Animations').Combat.Grip

--//Params
local equipColor = Color3.fromRGB(255, 215, 146)
local tinfo = TweenInfo.new(1.6, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)

--//Util functions
local function marker(tool)
	--//Part transparency
	for _,v in tool:GetDescendants() do
		if v:IsA('BasePart') and not v:HasTag('DebugPart') then
			v.Transparency = 0
		end
	end

	--//Highlight transparency
	local highlight = tool:FindFirstChild('Highlight')
	if highlight then 
		highlight.FillTransparency = .25
		TS:Create(highlight, tinfo, {FillTransparency = 1}):Play()
		Debris:AddItem(highlight, tinfo.Time)
	end
	
	--//Particles
	local hitbox = tool:FindFirstChild('Hitbox')
	if hitbox then
		for _,e in script.Effect:GetChildren() do
			local emitter = e:Clone()
			emitter.Parent = hitbox
			
			emitter.Enabled = true
			emitter:Emit(58)
			task.delay(1, function()
				emitter.Enabled = false
			end)
			
			Debris:AddItem(emitter, 3)
		end
	end
end

--//Functions
local function connection(char)
	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child:HasTag('Weapon') then
			for _,v in child:GetDescendants() do
				if v:IsA('BasePart') and not v:HasTag('DebugPart') then
					v.Transparency = 1
				end
			end
			
			local anim:AnimationTrack = AnimationController:LoadAnim({
				char=char, 
				animId=equipAnim.AnimationId, 
				_type="Equip", 
				priority=Enum.AnimationPriority.Action2,
				markerName = "Equip",
				markerCallback = {{name = "Equip", func = function() marker(child) end}}
			})
			
			SoundController:PlaySoundAtPart(SS.FX.backpack1, char.HumanoidRootPart)

			local hl = Instance.new('Highlight', child)
			hl.FillColor = equipColor
			hl.FillTransparency = 1
			hl.OutlineTransparency = 1
			hl.DepthMode = Enum.HighlightDepthMode.Occluded
			hl.Enabled = true
			
			local plr = game.Players:GetPlayerFromCharacter(char)
			if plr then 
				StateController:SetState(plr, "Equipping", true, anim.Length) 
			end
			
			task.wait(anim.Length * .6)
			SoundController:PlaySoundAtPart(SS.FX.sword_swing1, char.HumanoidRootPart)
			task.wait(anim.Length * .4)
			if child.Parent ~= char then return end
			
			
			--AnimationController:LoadAnim({
			--	char=char, 
			--	animId=toolGripAnim.AnimationId, 
			--	_type="Grip", 
			--	priority=Enum.AnimationPriority.Idle,
			--	looped = true
			--})
		end
	end)

	char.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") and child:HasTag('Weapon') then
			if AnimationController:IsAnim(char, "Equip") then
				AnimationController:StopAnim(char, "Equip")
				
				local plr = game.Players:GetPlayerFromCharacter(char)
				StateController:RemoveState(plr, "Equipping")
			end
			
			if AnimationController:IsAnim(char, "Grip") then
				AnimationController:StopAnim(char, "Grip")
			end
		end
	end)
end

--//Initialize
game.Players.PlayerAdded:Connect(function(Player)
	Player.CharacterAdded:Connect(function(Char)
		connection(Char)	
	end)
end)
