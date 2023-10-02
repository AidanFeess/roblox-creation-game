local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local InMenu = script.Parent:WaitForChild('InMenu')

local camera = workspace.CurrentCamera
camera.CameraType = Enum.CameraType.Scriptable

UserInputService.MouseIcon = 'rbxassetid://12736394281'

local KEY_DIRECTIONS = table.freeze({
	[Enum.KeyCode.A] = Vector3.new(-1, 0, 0),
	[Enum.KeyCode.D] = Vector3.new(1, 0, 0),
	[Enum.KeyCode.S] = Vector3.new(0, 0, 1),
	[Enum.KeyCode.W] = Vector3.new(0, 0, -1),
	[Enum.KeyCode.Space] = Vector3.new(0, -1, 0),
	[Enum.KeyCode.LeftControl] = Vector3.new(0, 1, 0)
})

local TURN_SPEED = 1/90 -- in radians/pixel
local SHIFT_SPEED = 6 -- in studs/second
local MOVE_SPEED = 60 -- in studs/second

local shiftPressed = false

local activeDirections = {}

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()

local maxDistX = 74.5
local maxDistY = workspace.BoundingBox.Ceiling.Position.Y - .1
local minDistY = 1
local maxDistZ = 74.5

local x = 0
local y = 0
local angle = CFrame.Angles(0, x, 0) * CFrame.Angles(y, 0, 0)
local position = Vector3.new(0, 3, 0)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if KEY_DIRECTIONS[input.KeyCode] and not gameProcessed and not InMenu.Value then
		activeDirections[input.KeyCode] = KEY_DIRECTIONS[input.KeyCode]
	elseif input.KeyCode == Enum.KeyCode.LeftShift then
		shiftPressed = true
	elseif input.KeyCode == Enum.KeyCode.E then
		player.PlayerGui.MainGui.Paused.Visible = not player.PlayerGui.MainGui.Paused.Visible
		InMenu.Value = player.PlayerGui.MainGui.Paused.Visible
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if KEY_DIRECTIONS[input.KeyCode] then
		activeDirections[input.KeyCode] = nil
	elseif input.KeyCode == Enum.KeyCode.LeftShift then
		shiftPressed = false
	end
end)

UserInputService.InputChanged:Connect(function(input, gameProcessed)
	if gameProcessed or InMenu.Value then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		x = (x - input.Delta.X * TURN_SPEED)%(2*math.pi)
		y = math.clamp(y - input.Delta.Y * TURN_SPEED, math.rad(-89), math.rad(89))
		angle = CFrame.Angles(0, x, 0) * CFrame.Angles(y, 0, 0)
	end
end)

local speedBonus = 0
RunService.RenderStepped:Connect(function(dt)
	if not InMenu.Value then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
	local move = Vector3.zero
	for _, v in pairs(activeDirections) do
		move += v
	end

	if move ~= Vector3.zero then
		speedBonus += 0.1
	else
		speedBonus = 0
	end

	local speed = if shiftPressed then SHIFT_SPEED else MOVE_SPEED + speedBonus
	position += angle * (move * speed * dt)
	local newCFrame = angle+position
	if newCFrame.Position.X >= maxDistX or newCFrame.Position.X <= -maxDistX or newCFrame.Position.Y >= maxDistY or newCFrame.Position.Y <= minDistY or newCFrame.Position.Z >= maxDistZ or newCFrame.Position.Z <= -maxDistZ then
		position -= angle * (move * speed * dt)
		camera.CFrame  = angle + position
	else
		camera.CFrame  = angle + position
	end
end)
