-- fuck you daisydoo 
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local DataStoreService = game:GetService('DataStoreService')
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TeleportService = game:GetService('TeleportService')

local BlocksData = require(ReplicatedStorage.Assets["[Index] BlockInfo"])
local TierModifiers = require(ReplicatedStorage.Assets['[Index] TierModifiers'])
local Tiers = require(ReplicatedStorage.Assets['[Index] Tiers'])

local Blocks = ReplicatedStorage.Assets.Blocks

local PlayerDataTest = DataStoreService:GetDataStore('PlayerDataTest2')
local PlaceBlock = ReplicatedStorage.Remotes.PlaceBlock

Players.PlayerAdded:Connect(function(Player)
	
	local success, errorMsg = pcall(function()
		
		local pData = PlayerDataTest:GetAsync(Player.UserId)
		if not pData then
			PlayerDataTest:SetAsync(Player.UserId, {
				['rCredits'] = 1000,
				['Quartz'] = 0,
				['Blocks'] = {
					[1] = 200,
					[2] = 0,
					[3] = 0,
				},
			})
		end
		pData = PlayerDataTest:GetAsync(Player.UserId)
		
		local playerMainGui = Player.PlayerGui:WaitForChild('MainGui')
		playerMainGui.ScreenFrame.rCredits.Text = 'rCredits: ' .. pData['rCredits']
		playerMainGui.ScreenFrame.Quartz.Text = 'Quartz: ' .. pData['Quartz']
		
		playerMainGui.ScreenFrame.Play.MouseButton1Click:Connect(function()
			if workspace.Robot:FindFirstChild('Core') then
				TeleportService:Teleport('12727833226', Player, workspace.Robot:GetChildren())
				playerMainGui.ScreenFrame.Play.Text = 'Teleporting...'
			end
		end)
		
	end)

	if errorMsg then warn(errorMsg) end
	
end)

local function saveData(userId, data)
	
	local success, errorMsg = pcall(function()
		
		PlayerDataTest:UpdateAsync(userId, data)
		
	end)
	
end

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


PlaceBlock.OnServerEvent:Connect(function(Player, PartType, Orientation, Position, RemovingPart, Removing)
	if not Removing then
		-- need to add a check here if the player has the block of type they're trying to place or not
		-- create objs, but first check if the obj is a core and has a rotation
		if PartType == 'Core' then
			if workspace.Robot:WaitForChild('Core', .001) then return end
			Orientation = Vector3.new(0, 0, 0)
		end
		
		local newBlock = Blocks[PartType]:Clone()
		newBlock.Transparency = 1
		newBlock.Parent = workspace.Robot
		newBlock.CFrame = CFrame.new(Position) * CFrame.fromOrientation(math.rad(Orientation.X), math.rad(Orientation.Y), math.rad(Orientation.Z))
		if BlocksData[PartType].CanBeColored then
			newBlock.Color = TierModifiers[workspace.GhostPartInfo.Tier.Value].Color
		else
			newBlock.Color = Blocks[PartType].Color
		end
		
		local ValidPlace = false

		-- checking if the part can be placed at the location via its attachment points i.e if its a wedge, don't place it upside down on the floor
		for _, RayDir in pairs(DIRECTIONS) do
			-- cast a ray in each direction that the block can be attached to
			local rayParams = RaycastParams.new(); rayParams.FilterDescendantsInstances = {newBlock}
			local checkAdjacent = workspace:Raycast(newBlock.Placement.Position, Vector3.FromNormalId(RayDir)*2.1, rayParams)
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
						local ObjAttachmentPoint = NormalToFace(workspace:Raycast(checkAdjacent.Instance.Position, Vector3.FromNormalId(RayDir)*-2.1, AttachRayParams).Normal, newBlock)
						-- check if the side that is trying to attach is a valid attachment point for the object
						if BlocksData[PartType].AttachmentPoints[table.find(BlocksData[PartType].AttachmentPoints, ObjAttachmentPoint)] then
							-- check if the block to be placed on has a valid attachment point facing towards the parent block
							local checkBlock
							if checkAdjacent.Instance.Name == 'Placement' then
								checkBlock = checkAdjacent.Instance.Parent
							else
								checkBlock = checkAdjacent.Instance
							end
							local normFace = NormalToFace(checkAdjacent.Normal, checkAdjacent.Instance)
							if BlocksData[checkBlock.PartType.Value].AttachmentPoints[table.find(BlocksData[checkBlock.PartType.Value].AttachmentPoints, normFace)] then
								ValidPlace = true
								return
							end
						end
					end
				end
			end)
		end
		
		if not ValidPlace then
			newBlock:Destroy()
		else
			newBlock.Transparency = 0
		end
		
		
	elseif Removing and RemovingPart then
		RemovingPart:Destroy()
	end
	
end)
