local HitHandler = {}

--//Imports
local RP = game:GetService("ReplicatedStorage")
local SS = game:GetService("SoundService")
local SSS = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local SoundController = require(RP:WaitForChild('Shared').SoundController)
local WeaponController = require(SSS:WaitForChild('System').WeaponController)
local ShapecastHitbox = require(RP:WaitForChild('Packages').ShapecastHitbox)
local StateController = require(SSS:WaitForChild('System').StateController)
local MoveController = require(SSS:WaitForChild('System').MoveController)
local TS = game:GetService("TweenService")
local log = require(RP:WaitForChild('Shared').Log)

--//Data tables
HitHandler.Hits = {}
HitHandler.Hitboxes = {}

--//Params
local debugTrailsVisible = true
local highLightTime = 2.2
local stunTime = 0.25

local blockClr = Color3.new(0.160784, 0.2, 0.329412)
local damageClr = Color3.new(0.490196, 0.203922, 0.270588)

--//Combat params
local blockDmgModifier = 0.3
local deg = -0.5

ShapecastHitbox.Settings.Debug_Visible = debugTrailsVisible

--//Util functions
function getDot(char:Model, model:Model)
	if not char or not model then return end
	
	local vector1 = (char.Head.Position - model.Head.Position).Unit 
	local elook = model.HumanoidRootPart.CFrame.LookVector 
	local dot = vector1:Dot(elook)
	
	return dot
end

function calcDamage(plr:Player, model:Model, dmg:number)
	local char = plr.Character or plr.CharacterAdded:Wait()
	if not char or not model then return end
	
	local enemy = Players:GetPlayerFromCharacter(model)
	if enemy then
		if StateController:GetState(enemy, 'Blocking') then
			if getDot(char, model) > deg then
				return dmg * blockDmgModifier, true
			else
				return dmg, false
			end
		else
			return dmg, false
		end
		
	--//Debug dummy
	elseif model:HasTag('BlockingDummy') then
		if getDot(char, model) > deg then
			return dmg * blockDmgModifier, true
		else
			return dmg, false
		end
	else
		return dmg, false
	end
end

function onHit(player:Player, hitboxName:string, tool:Tool, damage:number, raycastResult)
	local part = raycastResult.Instance
	
	if part:FindFirstAncestorOfClass("Accessory") or part:FindFirstAncestorOfClass("Tool") or part:IsDescendantOf(player.Character) or part.Name == "HumanoidRootPart" then return end
	
	local model = part:FindFirstAncestorOfClass("Model")
	if not model then return end
	
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	if humanoid.Health <= 0 then return end
	
	if model == player.Character or model:HasTag('Ragdoll') then return end
	
	if not HitHandler.Hits[player] then HitHandler.Hits[player] = {} end
	if not HitHandler.Hits[player].hitboxName then HitHandler.Hits[player].hitboxName = {} end
	
	local tb = HitHandler.Hits[player].hitboxName
	local blocked:boolean
	
	if not table.find(tb, part) then
		damage, blocked = calcDamage(player, model, damage)
		if damage then 
			humanoid:TakeDamage(damage)
			
			if blocked then 
				SoundController:PlaySoundAtPart(SS.FX.thud1, tool)
			else
				SoundController:PlaySoundAtPart(SS.FX.sword_hit, tool)
			end
		end
		
		MoveController:Slow(model, 35, stunTime)
		addHightlight(part, blocked)
		
		table.insert(tb, part)
	end
end

function addHightlight(part:Part, blocked:boolean)
	local highlight = Instance.new("Highlight")
	highlight:AddTag('HitHighlight')
	
	highlight.FillColor = (blocked and blockClr) or damageClr
	
	highlight.OutlineColor = Color3.new(0, 0, 0)
	highlight.FillTransparency = .4
	highlight.OutlineTransparency = 1
	highlight.Parent = part
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Enabled = true
	
	TS:Create(highlight, 
		TweenInfo.new(highLightTime, Enum.EasingStyle.Quad), 
		{FillTransparency = 1, OutlineTransparency = 1}
	):Play()
	Debris:AddItem(highlight, highLightTime)
end

--function trailProc(tool:Tool, enable:boolean)
--	if not tool then return end
	
--	local Folder = tool:FindFirstChild('Attachs')
--	if not Folder then return end
	
--	local Trail102  = Folder:FindFirstChild('Beam102')
--	local Trail105  = Folder:FindFirstChild('Beam105')
	
--	if enable then
--		if not Trail102 and not Trail105 then
--			Trail102 = script.Beam102:Clone()
--			Trail102.Parent = Folder
			
--			Trail105 = script.Beam105:Clone()
--			Trail105.Parent = Folder

--			for _, att in ipairs(Folder:GetChildren()) do
--				if att.Name == "Trail1" then
--					Trail102.Attachment0 = att
--					Trail105.Attachment0 = att
--				elseif att.Name == "Trail2" then
--					Trail102.Attachment1 = att
--					Trail105.Attachment1 = att
--				end
--			end
--		end
--		Trail102.Enabled = true
--		Trail105.Enabled = true
--	else
--		if Trail102 and Trail105 then 
--			Trail102.Enabled = false 
--			Trail105.Enabled = false 
--		end
--	end
--end

--//Functions
function HitHandler:hitStart(player:Player, name:string)
	local weaponType = WeaponController:GetDataField(player, 'weaponType')
	local module = WeaponController:GetWeaponModule(weaponType)
	local tool = WeaponController:GetTool(player)
	
	if not module or not weaponType or not tool then return end

	SoundController:PlaySoundAtPart(SS.FX.sword_slash1, tool)
	SoundController:PlaySoundAtPart(SS.FX.sword_slash2, tool)

	local hitboxPart = tool:FindFirstChild("Hitbox")
	if hitboxPart then
		local current = require(SSS:WaitForChild('System').CombatEngine).Combos[player].currentCombo
		local dmgCalc = if current == module.maxCombo then module.finalDamage else module.damage
		
		local hitbox = ShapecastHitbox.new(hitboxPart)
		hitbox:OnHit(function(raycastResult)
			onHit(player, name, tool, dmgCalc, raycastResult)
		end)

		if not HitHandler.Hitboxes[player] then 
			HitHandler.Hitboxes[player] = {} 
		else
			for _, hitbox in ipairs(HitHandler.Hitboxes[player]) do
				if hitbox.name == name then
					log.error(script.Name, `hitbox already exists for {player.Name}`)
					return
				end
			end
		end
		
		--trailProc(tool, true)
		hitbox:HitStart()
		table.insert(HitHandler.Hitboxes[player], {hitbox = hitbox, name = name})
	else
		log.error(script.Name, `hitbox not found for {tool.Name}`)
	end
end

function HitHandler:hitStop(player:Player, hitName:string)
	if self.Hitboxes[player] then
		for _, hitbox in ipairs(self.Hitboxes[player]) do
			if hitbox.name == hitName then
				table.remove(self.Hitboxes[player], table.find(self.Hitboxes[player], hitbox))
				hitbox.hitbox:HitStop()
				if self.Hits[player] then
					self.Hits[player].hitboxName = {}
					self.Hits[player].isBlocked = nil
				end
				
				--trailProc(WeaponController:GetTool(player), false)
			end
		end
	end
end

--//Cleanup
game.Players.PlayerRemoving:Connect(function(plr)
	HitHandler.Hits[plr] = nil
	HitHandler.Hitboxes[plr] = nil
end)

return HitHandler
