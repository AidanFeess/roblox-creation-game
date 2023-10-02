local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UserInputService = game:GetService('UserInputService')
local Players = game:GetService('Players')

local BlocksInfo = require(ReplicatedStorage.Assets["[Index] BlockInfo"])
local Tiers = require(ReplicatedStorage.Assets["[Index] Tiers"])
local TierModifiers = require(ReplicatedStorage.Assets["[Index] TierModifiers"])

local Blocks = ReplicatedStorage.Assets.Blocks
local ChosenPart = Blocks:GetChildren()[1]
local PlaceBlockEvent = ReplicatedStorage.Remotes.PlaceBlock

local GhostPart
local DisplayPart
local ToRemovePart
local SavedOrientation = Vector3.new(0, 0, 0)

local placingIndicator = workspace.PlacingIndicator
local placingIndicatorFrames = {}
for _, Frame in pairs(placingIndicator:GetChildren()) do
	if Frame:IsA('Frame') then
		table.insert(placingIndicatorFrames, Frame)
	end
end

local Player = Players.LocalPlayer
local InMenu = script.Parent:WaitForChild('InMenu')
local Camera = workspace.Camera
local MainMenu = Player.PlayerGui:WaitForChild('MainGui')

local ObjDisplay = Player.PlayerGui:WaitForChild('MainGui').ObjDisplay
local ObjDisplayCamera = Instance.new('Camera')
ObjDisplayCamera.Parent = ObjDisplay
ObjDisplay.CurrentCamera = ObjDisplayCamera
ObjDisplayCamera.CFrame = CFrame.new(Vector3.new(0,0,6))

local GhostPartInfo = workspace.GhostPartInfo
local buildYLimit = 60 + 2.5

--[[
	[Vector3.new(-1, 0, 0)] = Enum.NormalId.Left,
	[Vector3.new(1, 0, 0)] = Enum.NormalId.Right,
	[Vector3.new(0, 0, 1)] = Enum.NormalId.Back,
	[Vector3.new(0, 0, -1)] = Enum.NormalId.Front,
	[Vector3.new(0, -1, 0)] = Enum.NormalId.Top,
	[Vector3.new(0, 1, 0)] = Enum.NormalId.Bottom
]]

local DIRECTIONS = table.freeze({
	Enum.NormalId.Left,
	Enum.NormalId.Right,
	Enum.NormalId.Back,
	Enum.NormalId.Front,
	Enum.NormalId.Top,
	Enum.NormalId.Bottom
})

function NormalToFace(normalVector, part)

	--[[**
   This function returns the face that we hit on the given part based on
   an input normal. If the normal vector is not within a certain tolerance of
   any face normal on the part, we return nil.

    @param normalVector (Vector3) The normal vector we are comparing to the normals of the faces of the given part.
    @param part (BasePart) The part in question.

    @return (Enum.NormalId) The face we hit.
**--]]

	local TOLERANCE_VALUE = 1 - 0.001
	local allFaceNormalIds = {
		Enum.NormalId.Front,
		Enum.NormalId.Back,
		Enum.NormalId.Bottom,
		Enum.NormalId.Top,
		Enum.NormalId.Left,
		Enum.NormalId.Right
	}    

	for _, normalId in pairs( allFaceNormalIds ) do
		-- If the two vectors are almost parallel,
		if GetNormalFromFace(part, normalId):Dot(normalVector) > TOLERANCE_VALUE then
			return normalId -- We found it!
		end
	end

	return nil -- None found within tolerance.

end

function GetNormalFromFace(part, normalId)
	--[[**
    This function returns a vector representing the normal for the given
    face of the given part.

    @param part (BasePart) The part for which to find the normal of the given face.
    @param normalId (Enum.NormalId) The face to find the normal of.

    @returns (Vector3) The normal for the given face.
**--]]
	return part.CFrame:VectorToWorldSpace(Vector3.FromNormalId(normalId))
end

function ConvertNormalToRotation(normalId, rotation)
	local normalVectors = {
		[Enum.NormalId.Front] = Vector3.new(0, 0, -1),
		[Enum.NormalId.Back] = Vector3.new(0, 0, 1),
		[Enum.NormalId.Top] = Vector3.new(0, -1, 0),
		[Enum.NormalId.Bottom] = Vector3.new(0, 1, 0),
		[Enum.NormalId.Right] = Vector3.new(1, 0, 0),
		[Enum.NormalId.Left] = Vector3.new(-1, 0, 0),
	}
	local rotationMatrix = CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))
	local transformedVector = rotationMatrix:VectorToWorldSpace(normalVectors[normalId])
	local closestNormal = Enum.NormalId.Front
	local closestAngle = math.huge
	for id, vector in pairs(normalVectors) do
		local angle = math.acos(transformedVector:Dot(vector) / (transformedVector.Magnitude * vector.Magnitude))
		if angle < closestAngle then
			closestAngle = angle
			closestNormal = id
		end
	end
	return closestNormal
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	pcall(function()

		if gameProcessed or InMenu.Value then return end
		-- rotate on the Y axis
		if input.KeyCode == Enum.KeyCode.R then
			GhostPartInfo.Orientation.Value +=	BlocksInfo[GhostPart.PartType.Value].RotationY
			if GhostPartInfo.Orientation.Value.Y >= 360 then GhostPartInfo.Orientation.Value -= Vector3.new(0, 360, 0) end
			-- rotate on the Z axis
		elseif input.KeyCode == Enum.KeyCode.T then
			-- check if the object is a 180degZ or 90degZ turn block i.e. tetra = 180degZ, prism = 90degZ
			if BlocksInfo[GhostPart.PartType.Value].RotationZ.Z == 180 or  BlocksInfo[GhostPart.PartType.Value].RotationZ.Z == -180 then
				if GhostPartInfo.Orientation.Value.Z % 180 ~= 0 then
					GhostPartInfo.Orientation.Value -= Vector3.new(0, 0, 90)
				end
				-- check if its already rotated 180deg on the Z axis and rotate accordingly
				if GhostPartInfo.Orientation.Value.Z > 0 or GhostPartInfo.Orientation.Value.Z < 0 then
					GhostPartInfo.Orientation.Value += BlocksInfo[GhostPart.PartType.Value].RotationZ
				else
					GhostPartInfo.Orientation.Value -= BlocksInfo[GhostPart.PartType.Value].RotationZ
				end
			else
				GhostPartInfo.Orientation.Value += BlocksInfo[GhostPart.PartType.Value].RotationZ
			end

			-- reset Z values to -360 < Z < 360
			if GhostPartInfo.Orientation.Value.Z >= 360 then
				GhostPartInfo.Orientation.Value -= Vector3.new(0, 0, 360)
			elseif GhostPartInfo.Orientation.Value.Z <= -360 then
				GhostPartInfo.Orientation.Value += Vector3.new(0, 0, 360)
			end

			if GhostPartInfo.Orientation.Value.Y >= 360 then GhostPartInfo.Orientation.Value -= Vector3.new(0, 360, 0) end

			-- object placement
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 and GhostPartInfo.CanPlace.Value then
			if GhostPart.Transparency ~= 1 then
				PlaceBlockEvent:FireServer(GhostPart.PartType.Value, GhostPart.Orientation, GhostPart.Position)
			end
			-- object removal
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			if GhostPart.Transparency ~= 1 then
				PlaceBlockEvent:FireServer(nil, nil, nil, ToRemovePart, true)
				GhostPartInfo.CanPlace.Value = true
			end
		end

	end)
end)

task.spawn(function()
	-- slow rotate for objects in the display hand (bottom right obj display)
	local moveSpeed = Vector3.new(0, .1, 0)
	local orientation = Vector3.new(0, 0, 0)
	while wait() do
		local DisplayPart = ObjDisplay:WaitForChild('DisplayPart')
		local originalOrientation = BlocksInfo[DisplayPart.PartType.Value].OriginRotation
		local maxY, minY = 10, -10
		if orientation.Y  <= minY or orientation.Y >= maxY then
			wait(1)
			moveSpeed *= -1
		end
		orientation += moveSpeed
		DisplayPart.Orientation = originalOrientation + orientation
	end

end)

-- create the ghost part
local function createGhostPart()
	-- create ghost part and display part at the same time
	GhostPart = ChosenPart:Clone()
	GhostPart.Parent = workspace
	GhostPart.CFrame = CFrame.new(Vector3.new(0, (GhostPart.Size.Y / 2) + .5, 0)) -- place ghost part at 0,0,0
	GhostPart.Name = 'GhostPart'
	GhostPart.Transparency = 1
	-- display part section
	DisplayPart = GhostPart:Clone()
	DisplayPart.Transparency = 0
	DisplayPart.Name = 'DisplayPart'
	DisplayPart.Parent = ObjDisplay
	DisplayPart.Position = Vector3.new(0, 0, 0)
	DisplayPart.Orientation = BlocksInfo[DisplayPart.PartType.Value].OriginRotation
	if BlocksInfo[DisplayPart.PartType.Value].CanBeColored then
		DisplayPart.Color = TierModifiers[workspace.GhostPartInfo.Tier.Value].Color
	end
	ObjDisplayCamera.CFrame = CFrame.new(Vector3.new(2, 2, 6), DisplayPart.Position)
end

-- creating the block choice ui
local function createGui(text, pos)
	-- Instances:

	local TextButton = Instance.new("TextButton")
	--Properties:
	TextButton.Parent = MainMenu.SelectObj.Scroll
	TextButton.BackgroundColor3 = Color3.fromRGB(73, 65, 55)
	TextButton.Size = UDim2.new(0, 218, 0, 50)
	TextButton.Font = Enum.Font.SourceSans
	TextButton.Text = text
	TextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	TextButton.TextSize = 24.000
	TextButton.TextXAlignment = Enum.TextXAlignment.Left
	TextButton.Position = pos
	-- define what happens when a button is clicked on
	TextButton.MouseButton1Click:Connect(function()
		-- change the chosen part
		ChosenPart = Blocks[text]
		if GhostPart then
			GhostPart:Destroy()
			DisplayPart:Destroy()
		end
		createGhostPart()
		-- check if its the robot core and set the rotation to none because core cannot be rotated
		if text == 'Core' then
			SavedOrientation = GhostPartInfo.Orientation.Value
			GhostPartInfo.Orientation.Value = Vector3.new(0, 0, 0)
		elseif SavedOrientation.Magnitude > 0 then
			GhostPartInfo.Orientation.Value = SavedOrientation
		end
	end)
end

local ObjectIteration = 0
for _, object in pairs(Blocks:GetChildren()) do
	createGui(object.Name, UDim2.new(0, 0, .055*ObjectIteration, 0)) 
	ObjectIteration += 1
end

-- Check if the player is aiming at either the floor or an already built part
while wait() do
	for _, Frame in pairs(placingIndicatorFrames) do
		Frame.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	end
	-- first, add a ghostpart if there is not already one in the workspace
	-- then, add a display ghost part for the character's hand, into the ObjDisplay viewport frame
	-- also make sure to change the camera's cframe
	GhostPart = workspace:FindFirstChild('GhostPart', .1)
	DisplayPart = ObjDisplay:WaitForChild('DisplayPart', .1)
	if not GhostPart  then
		createGhostPart()
	end

	-- define the y offset
	local yOffset = 2.5
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = {GhostPart}
	local ray = workspace:Raycast(Camera.CFrame.Position, Camera.CFrame.LookVector*1000, raycastParams)
	local success, errorMsg = pcall(function()
		-- first check if the ray has even hit a part
		-- then check if the part is either the floor or an already built part
		if ray.Instance == workspace.BoundingBox.Floor or ray.Instance:IsDescendantOf(workspace.Robot) and ray.Instance.Position.Y <= buildYLimit then

			local ValidPlace = false
			local RecievingPlacingFace = NormalToFace(ray.Normal, ray.Instance)

			-- checking if the part can be placed at the location via its attachment points i.e if its a wedge, don't place it upside down on the floor
			for _, RayDir in pairs(DIRECTIONS) do
				-- cast a ray in each direction that the block can be attached to
				local rayParams = RaycastParams.new(); rayParams.FilterDescendantsInstances = {GhostPart}
				local checkAdjacent = workspace:Raycast(GhostPart.Placement.Position, Vector3.FromNormalId(RayDir)*2.1, rayParams)
				local s, f = pcall(function()
					-- if it can't be attached to, make it impossible to place, else check if the recieving attachment point can recieve this block's attachment request
					if not checkAdjacent.Instance then
						ValidPlace = false
					elseif checkAdjacent.Instance then
						if checkAdjacent.Instance == workspace.BoundingBox.Floor then
							ValidPlace = true
							return
						elseif checkAdjacent.Instance ~= workspace.BoundingBox.Floor then
							local AttachRayParams = RaycastParams.new(); --AttachRayParams.FilterDescendantsInstances = {checkAdjacent.Instance}	
							local ObjAttachmentPoint = NormalToFace(workspace:Raycast(checkAdjacent.Instance.Position, Vector3.FromNormalId(RayDir)*-2.1, AttachRayParams).Normal, GhostPart)
							-- check if the side that is trying to attach is a valid attachment point for the object
							if BlocksInfo[GhostPart.PartType.Value].AttachmentPoints[table.find(BlocksInfo[GhostPart.PartType.Value].AttachmentPoints, ObjAttachmentPoint)] then
								-- check if the block to be placed on has a valid attachment point facing towards the parent block
								local checkBlock
								if checkAdjacent.Instance.Name == 'Placement' then
									checkBlock = checkAdjacent.Instance.Parent
								else
									checkBlock = checkAdjacent.Instance
								end
								local normFace = NormalToFace(checkAdjacent.Normal, checkAdjacent.Instance)
								if BlocksInfo[checkBlock.PartType.Value].AttachmentPoints[table.find(BlocksInfo[checkBlock.PartType.Value].AttachmentPoints, normFace)] then
									ValidPlace = true
									return
								end
							end
						end
					end
				end)
			end


			if ray.Instance:IsDescendantOf(workspace.Robot) then

				if ray.Instance.Parent ~= workspace.Robot and ray.Instance ~= workspace.Robot then
					ToRemovePart = ray.Instance.Parent
					if BlocksInfo[ray.Instance.Parent.PartType.Value].BaseBlock == true then -- check if the block requires a placing indicator
						placingIndicator.Parent = ray.Instance
						placingIndicator.Face = RecievingPlacingFace
						if not ValidPlace then
							for _, Frame in pairs(placingIndicatorFrames) do
								Frame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
							end
						end
					end
				else
					placingIndicator.Parent = workspace
					ToRemovePart = ray.Instance
				end

			else
				placingIndicator.Parent = workspace
				ToRemovePart = nil
			end

			local x = math.round(ray.Position.X / 4) * 4
			local y = math.floor(ray.Position.Y / 4) * 4 + yOffset
			local z = math.round(ray.Position.Z / 4) * 4 		
			local gridPosition = Vector3.new(x, y, z)
			-- angles convert deg --> rad and change the position to be the grid position
			local rotation = CFrame.Angles(math.rad(GhostPartInfo.Orientation.Value.X), math.rad(GhostPartInfo.Orientation.Value.Y), math.rad(GhostPartInfo.Orientation.Value.Z))
			GhostPart.Placement.CFrame = CFrame.new(gridPosition) * rotation
			-- set the part's color to ensure its not stuck red like a non-placable block would be
			if BlocksInfo[GhostPart.PartType.Value].CanBeColored and ValidPlace then
				GhostPart.Color = TierModifiers[GhostPartInfo.Tier.Value].Color
			elseif not BlocksInfo[GhostPart.PartType.Value].CanBeColored and ValidPlace then
				GhostPart.Color = Blocks.Core.Color
			end
			-- check the block and move it if its invalid placed
			for _, otherBlock in pairs(workspace.Robot:GetChildren()) do
				if table.find(workspace:GetPartsInPart(GhostPart), otherBlock.Placement) then
					while table.find(workspace:GetPartsInPart(GhostPart), otherBlock.Placement) do
						GhostPart.CFrame += ray.Normal * 4
					end
					break
				end
			end
			
			-- if the block is still invalid placed then color it red and make it where it cannot be placed
			for _, otherBlock in pairs(workspace.Robot:GetChildren()) do
				if table.find(workspace:GetPartsInPart(GhostPart), otherBlock) then
					ValidPlace = false
					break
				end
			end
			
			-- final check, if there is already a core and the player is trying to place a core, don't let them
			if workspace.Robot:WaitForChild('Core', .001) and GhostPart.PartType.Value == 'Core' then
				ValidPlace = false
			end

			if not ValidPlace then
				GhostPart.Color = Color3.fromRGB(255, 0, 0)
				GhostPartInfo.CanPlace.Value = false
			elseif ValidPlace then
				GhostPartInfo.CanPlace.Value = true
			end

			GhostPart.Transparency = .75
		else
			GhostPart.Transparency = 1
			ToRemovePart = nil
		end
	end)

	if errorMsg then print(errorMsg) end
end
