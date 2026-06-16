local AnimationController = {}

--//Imports
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

--//Data table
AnimationController.Anims = {}

--//Data type
type animParams = {
	char: Model,
	animId: string | number,
	_type: string,
	speed: number?,
	looped: boolean?,
	markerCallback: {{name: string, func: () -> ()}}?,
	transitionTime: number?,
	priority: number?,
}

local defaultTransition = 0.12

--//Util functions
function getAnimator(char)
	local humanoid = char:WaitForChild("Humanoid")
	if not humanoid then return end
	local animator = humanoid:FindFirstChild("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	return animator
end

--//Functions
function AnimationController:LoadAnim(params: animParams)
	if not params.char or not params.animId or not params._type then return end

	local char = params.char
	local animId = params.animId
	local _type = params._type
	local speed = params.speed or 1
	local looped = params.looped or false
	local markerCallback = params.markerCallback or nil
	local transitionTime = params.transitionTime or defaultTransition
	local priority = params.priority or 0

	local animator = getAnimator(char)
	if not animator then return end

	local animation = Instance.new("Animation")

	if typeof(animId) == "number" then
		animId = "rbxassetid://" .. tostring(animId)
	end

	animation.AnimationId = animId
	local track = animator:LoadAnimation(animation)

	self.Anims[char] = self.Anims[char] or {}
	self.Anims[char][_type] = self.Anims[char][_type] or {}

	local connections = {}

	if markerCallback then
		for _, marker in markerCallback do
			table.insert(connections, track:GetMarkerReachedSignal(marker.name):Connect(function()
				marker.func()
			end))
		end
	end

	table.insert(connections, track.Stopped:Connect(function()
		AnimationController:RemoveAnim(char, _type, animId)
	end))

	self.Anims[char][_type][animId] = {
		Track = track,
		Connections = connections,
		Speed = speed,
		Paused = false
	}

	track.Priority = priority
	track:Play(transitionTime)
	track:AdjustSpeed(speed)
	if looped then
		track.Looped = true
	else
		track.Looped = false
		Debris:AddItem(track, track.Length + 1)
	end

	return track
end

function AnimationController:GetAnims(char, animType)
	if not self.Anims[char] then return {} end
	if animType then return self.Anims[char][animType] or {} end
	return self.Anims[char]
end

function AnimationController:IsAnim(char, _type, animId)
	local charAnims = self.Anims[char]
	if not charAnims then
		return false
	end

	local typeAnims = charAnims[_type]
	if not typeAnims then
		return false
	end

	if animId then
		local entry = typeAnims[animId]
		return entry and entry.Track and entry.Track.IsPlaying or false
	end

	for _, entry in pairs(typeAnims) do
		if entry and entry.Track and entry.Track.IsPlaying then
			return true
		end
	end

	return false
end

function AnimationController:RemoveAnim(char, _type, animId)
	local animData = self.Anims[char] and self.Anims[char][_type] and self.Anims[char][_type][animId]
	if animData then
		if animData.Track then
			animData.Track:Stop()
			animData.Track:Destroy()
		end

		if animData.Connections then
			for _, conn in ipairs(animData.Connections) do
				if conn.Connected then
					conn:Disconnect()
				end
			end
		end

		self.Anims[char][_type][animId] = nil

		if next(self.Anims[char][_type]) == nil then
			self.Anims[char][_type] = nil
		end

		if next(self.Anims[char]) == nil then
			self.Anims[char] = nil
		end
	end
end

function AnimationController:StopAnim(char, _type, animId)
	if not AnimationController.Anims[char] then return end

	if _type == "ALL" then
		for typeKey, anims in pairs(self.Anims[char]) do
			for id in pairs(anims) do
				AnimationController:RemoveAnim(char,typeKey,id)
			end
		end

	else
		if animId then
			AnimationController:RemoveAnim(char, _type, animId)
		else
			for id in pairs(self.Anims[char][_type] or {}) do
				AnimationController:RemoveAnim(char, _type, id)
			end
		end
	end
end

function AnimationController:AnimPause(char, _type, animId)
	if not self.Anims[char] then return end

	local typeAnims = self.Anims[char][_type]
	if not typeAnims then return end

	if animId then
		local entry = typeAnims[animId]
		if entry and entry.Track and entry.Track.IsPlaying and not entry.Paused then
			entry.Track:AdjustSpeed(0)
			entry.Paused = true
		end
	else
		for id, entry in pairs(typeAnims) do
			if entry and entry.Track and entry.Track.IsPlaying and not entry.Paused then
				entry.Track:AdjustSpeed(0)
				entry.Paused = true
			end
		end
	end
end

function AnimationController:AnimResume(char, _type, animId)
	if not self.Anims[char] then return end

	local typeAnims = self.Anims[char][_type]
	if not typeAnims then return end

	if animId then
		local entry = typeAnims[animId]
		if entry and entry.Paused then
			entry.Track:AdjustSpeed(entry.Speed)
			entry.Paused = false
		end
	else
		for id, entry in pairs(typeAnims) do
			if entry and entry.Paused then
				entry.Track:AdjustSpeed(entry.Speed)
				entry.Paused = false
			end
		end
	end
end

--//Initialize
function AnimationController:init()
	Players.PlayerRemoving:Connect(function(player)
		local char = player.Character or player.CharacterAdded:Wait()
		if self.Anims[char] then
			AnimationController:StopAnim(char, 'ALL')
			self.Anims[char] = nil
		end
	end) 
end

return AnimationController
