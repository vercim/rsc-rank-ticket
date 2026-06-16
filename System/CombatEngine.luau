local CombatEngine = {}

--//Imports
local Players = game:GetService("Players")
local SS = game:GetService("SoundService")
local RP = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local AnimationController = require(RP:WaitForChild('Shared').AnimationController)
local SoundController = require(RP:WaitForChild('Shared').SoundController)
local CooldownController = require(SSS:WaitForChild('System').CooldownController)
local WeaponController = require(SSS:WaitForChild('System').WeaponController)
local StateController = require(SSS:WaitForChild('System').StateController)
local MoveController = require(SSS:WaitForChild('System').MoveController)
local log = require(RP:WaitForChild('Shared').Log)

local remotes = require(RP:WaitForChild('Shared').remotes)
local CombatAnims = RP:WaitForChild('Animations').Combat
local BlockAnims = CombatAnims.Block

--//Data table
CombatEngine.Combos = {}
CombatEngine.Blocks = {}

--//Params
local comboResetTime = 2.6
local globalAttackAnimSpeed = 1.28
local slowModifier = 86

--//Util functions
function comboUpdate(player, maxCombo:number)
	local combo = CombatEngine.Combos[player]
	local reset
	
	if combo.lastAttack then
		reset = tick() - combo.lastAttack > comboResetTime
	end
	
	combo.lastAttack = tick()

	if combo.currentCombo+1 == maxCombo and not reset then
		local weaponType = WeaponController:GetDataField(player, 'weaponType')
		local weaponModule = WeaponController:GetWeaponModule(weaponType)
		if not weaponModule then return end
		local cooldown = weaponModule.cooldown
		CooldownController:SetCooldown(player, 'Combo', cooldown)
	end
		
	if reset or combo.currentCombo == maxCombo then
		combo.currentCombo = 1
	else
		combo.currentCombo += 1
	end
end

--//Functions
function CombatEngine:Attack(player, inputState)
	if inputState == Enum.UserInputState.Begin then
		if StateController:GetState(player, "Blocking") or StateController:GetState(player, "Attacking") or StateController:GetState(player, "Equipping") or not CooldownController:CanAction(player, 'Combo') then return end
		
		local char = player.Character or player.CharacterAdded:Wait()
		local hum = char:FindFirstChild("Humanoid")
		if not hum or not char then return end

		--//Get tool
		local tool = WeaponController:GetTool(player)
		if tool.Parent ~= player.Character then return end

		--//Get type
		local weaponType = WeaponController:GetDataField(player, 'weaponType')

		--//Get module
		local weaponModule = WeaponController:GetWeaponModule(weaponType)
		if not weaponModule then return end

		--//Others
		local maxCombo = weaponModule.maxCombo

		--//Get anims
		local weaponAnims = WeaponController:GetWeaponAnims(weaponType)
		if not weaponAnims then return end
		
		comboUpdate(player, maxCombo)
		local playerCurrentCombo = CombatEngine.Combos[player].currentCombo

		local hitAnim = weaponAnims:FindFirstChild(`Hit{playerCurrentCombo}`)
		if not hitAnim then return end

		--//Result
		if not AnimationController:IsAnim(char, "Equip") then
			local hithandler = require(SSS:WaitForChild('System').HitHandler)
			local animTrack:AnimationTrack = AnimationController:LoadAnim(
				{
					char=char, 
					_type="Attack", 
					animId=hitAnim.AnimationId, 	
					loop=false, 
					priority=Enum.AnimationPriority.Action2,
					speed = globalAttackAnimSpeed,
					markerCallback = {
						{name="HitboxStart", func=function() hithandler:hitStart(player, "Attack") end}, 
						{name="HitboxStop", func=function() hithandler:hitStop(player, "Attack") end}, 
					}
				}
			)
			
			local animTime = animTrack.Length

			StateController:SetState(player, 'Attacking', true, animTime)
			SoundController:PlaySoundAtPart(SS.FX.shaking1, tool)
			MoveController:Slow(char, slowModifier, animTime)
			hum.AutoRotate = false
			
			--//Delay before attack ends
			task.delay(animTime-.2, function()
				if AnimationController:IsAnim(char, "Attack") then
					AnimationController:AnimPause(char, "Attack")
					task.wait(.2)
					AnimationController:AnimResume(char, "Attack")
				end
				
				hum.AutoRotate = true
			end)
		end
	end
end

function CombatEngine:Block(player, inputState)
	local char = player.Character
	local hum = char:WaitForChild('Humanoid')

	local blockTable = self.Blocks[player]
	
	if inputState == Enum.UserInputState.Begin then
		if AnimationController:IsAnim(char, 'Attack') or StateController:GetState(player, 'Attacking') then return end
		if not AnimationController:IsAnim(char, 'Block') and not StateController:GetState(player, 'Blocking') then
			StateController:SetState(player, 'Blocking', true)
			blockTable.guid = MoveController:Slow(char, 40)

			blockTable.hitProcessing = nil
			
			blockTable.hitProcessing = task.spawn(function()
				if not hum then return end
				local hp = hum.Health
				blockTable.hitConnection = nil
				blockTable.hitConnection= hum.HealthChanged:Connect(function(newHp)
					if tick() - blockTable.lastHitTick <= 0.2 then 
						hp = newHp
						return 
					end
					
					if newHp >= hp then
						hp = newHp
						return
					end

					hp = newHp

					if not StateController:GetState(player, 'Blocking') or not AnimationController:IsAnim(char, 'Block') then return end
					if AnimationController:IsAnim(char, 'Block', BlockAnims.BlockHit.AnimationId) then return end
					
					blockTable.lastHitTick = tick()

					AnimationController:LoadAnim(
						{char=char, _type="Block", animId=BlockAnims.BlockHit.AnimationId, priority=Enum.AnimationPriority.Action, looped=false}
					)
				end)
			end)

			AnimationController:LoadAnim(
				{char=char, _type="Block", animId=BlockAnims.Block.AnimationId, priority=Enum.AnimationPriority.Action, looped=true, transitionTime = .25}
			)
			
			SoundController:PlaySoundAtPart(SS.FX.rustle1, char.HumanoidRootPart)
		end
	else
		if StateController:GetState(player, 'Blocking') then
			StateController:RemoveState(player, 'Blocking')
		end

		if AnimationController:IsAnim(char, 'Block') then
			AnimationController:StopAnim(char, 'Block')
		end

		
		if blockTable and blockTable.hitProcessing and blockTable.hitConnection then 
			task.cancel(blockTable.hitProcessing)
			blockTable.hitProcessing = nil
		
			blockTable.hitConnection:Disconnect()
			blockTable.hitConnection = nil
		end
		
		if blockTable and blockTable.guid then
			MoveController:RemoveSlow(char, blockTable.guid)
		end
	end
end

--//Initialize
function CombatEngine:init()
	remotes.combatInput:connect(function(player, action, inputState, time)
		if action == "Attack" then
			self:Attack(player, inputState)
		elseif action == "Block" then
			self:Block(player, inputState)
		end
	end)
	
	Players.PlayerAdded:Connect(function(Plr)
		self.Combos[Plr] = {}
		self.Combos[Plr].currentCombo = 0
		self.Combos[Plr].lastAttack = nil
		
		self.Blocks[Plr] = {}
		self.Blocks[Plr].hitProcessing = nil
		self.Blocks[Plr].hitConnection = nil
		self.Blocks[Plr].lastHitTick = tick()
		self.Blocks[Plr].guid = nil
	end)

	Players.PlayerRemoving:Connect(function(Plr)
		if not Plr then return end
		self.Combos[Plr] = nil
		self.Blocks[Plr] = nil
	end)
end

return CombatEngine
