local ReplicatedStorage = game:GetService('ReplicatedStorage')

local blocks = {
	['Cube'] = {
		TierPoints = 1,
		Object = ReplicatedStorage.Assets.Blocks.Cube,
		AttachmentPoints = {
			Enum.NormalId.Top,
			Enum.NormalId.Bottom,
			Enum.NormalId.Left,
			Enum.NormalId.Right,
			Enum.NormalId.Front,
			Enum.NormalId.Back
		},
		RotationY = Vector3.new(0, 90, 0),
		RotationZ = Vector3.new(0, 0, 180), -- how the block should be rotated
		OriginRotation = Vector3.new(0, 0, 0),
		BaseBlock = true, -- if the placement indicator should be visible on the block
		CanBeColored = true,
	},
	['Prism'] = {
		TierPoints = 1,
		Object = ReplicatedStorage.Assets.Blocks.Prism,
		AttachmentPoints = {
			Enum.NormalId.Bottom,
			Enum.NormalId.Left,
			Enum.NormalId.Right,
			Enum.NormalId.Back
		},
		RotationY = Vector3.new(0, 90, 0),
		RotationZ = Vector3.new(0, 0, 90), -- how the block should be rotated
		OriginRotation = Vector3.new(0, -90, 0),
		BaseBlock = true,
		CanBeColored = true,
	},
	['Tetra'] = {
		TierPoints = 1,
		Object = ReplicatedStorage.Assets.Blocks.Tetra,
		AttachmentPoints = {
			Enum.NormalId.Bottom,
			Enum.NormalId.Left,
			Enum.NormalId.Back
		},
		RotationY = Vector3.new(0, 90, 0),
		RotationZ = Vector3.new(0, 90, 180), -- how the block should be rotated
		OriginRotation = Vector3.new(0, 180, 0),
		BaseBlock = true,
		CanBeColored = true,
	},
	['Inner'] = {
		TierPoints = 1,
		Object = ReplicatedStorage.Assets.Blocks.Inner,
		AttachmentPoints = {
			Enum.NormalId.Top,
			Enum.NormalId.Bottom,
			Enum.NormalId.Left,
			Enum.NormalId.Right,
			Enum.NormalId.Front,
			Enum.NormalId.Back
		},
		RotationY = Vector3.new(0, 90, 0),
		RotationZ = Vector3.new(0, -90, 180), -- how the block should be rotated
		OriginRotation = Vector3.new(0, 90, 180),
		BaseBlock = true,
		CanBeColored = true,
	},
	['Core'] = {
		TierPoints = 1,
		Object = ReplicatedStorage.Assets.Blocks.Core,
		AttachmentPoints = {
			Enum.NormalId.Top,
			Enum.NormalId.Bottom,
			Enum.NormalId.Left,
			Enum.NormalId.Right,
			Enum.NormalId.Front,
			Enum.NormalId.Back
		},
		RotationY = Vector3.new(0, 0, 0),
		RotationZ = Vector3.new(0, 0, 0), -- how the block should be rotated
		OriginRotation = Vector3.new(0, 0, 0),
		BaseBlock = false,
		CanBeColored = false,
	},
}

return blocks
