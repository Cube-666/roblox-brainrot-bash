-- StealSystem.lua
-- Tool Palu (mencuri brainrot pemain lain) dan Tongkat (memukul sampai pusing).
-- Tool dibuat dari Part di server dan diberikan saat pemain join.
-- Aktivasi tool ditangani server (Tool.Activated) + validasi jarak & cooldown.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local PlayerData = require(script.Parent.PlayerData)
local BrainrotSystem = require(script.Parent.BrainrotSystem)

local StealSystem = {}

local remotes = nil

-- ------------------------------------------------------------------ tool

local function buildHammer()
	local tool = Instance.new("Tool")
	tool.Name = "Palu"
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool.ToolTip = "Klik untuk mencuri brainrot pemain lain!"

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.4, 1.8, 0.4)
	handle.Color = Color3.fromRGB(139, 69, 19)
	handle.Material = Enum.Material.SmoothPlastic
	handle.CanCollide = false
	handle.CanTouch = false
	handle.Parent = tool

	local head = Instance.new("Part")
	head.Name = "Kepala"
	head.Size = Vector3.new(1.4, 0.9, 0.9)
	head.Color = Color3.fromRGB(231, 76, 60)
	head.Material = Enum.Material.SmoothPlastic
	head.CanCollide = false
	head.CanTouch = false
	head.Parent = tool
	-- Kepala menempel di ujung atas handle
	head.CFrame = handle.CFrame * CFrame.new(0, 1.2, 0)
	-- Weld supaya kepala ikut handle saat dipegang
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = head
	weld.Parent = tool

	local cap1 = Instance.new("Part")
	cap1.Name = "UjungKuning"
	cap1.Size = Vector3.new(1.5, 0.3, 1.0)
	cap1.Color = Color3.fromRGB(241, 196, 15)
	cap1.CanCollide = false
	cap1.CanTouch = false
	cap1.Parent = tool
	cap1.CFrame = handle.CFrame * CFrame.new(0, 1.7, 0)
	local weld2 = Instance.new("WeldConstraint")
	weld2.Part0 = handle
	weld2.Part1 = cap1
	weld2.Parent = tool
	return tool
end

local function buildStick()
	local tool = Instance.new("Tool")
	tool.Name = "Tongkat"
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool.ToolTip = "Klik untuk memukul brainrot sampai pusing!"

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.35, 3.0, 0.35)
	handle.Color = Color3.fromRGB(120, 72, 20)
	handle.Material = Enum.Material.SmoothPlastic
	handle.CanCollide = false
	handle.CanTouch = false
	handle.Parent = tool
	return tool
end

-- ------------------------------------------------------------------ aksi

local function getRootPart(player)
	local char = player.Character
	if not char then
		return nil
	end
	return char:FindFirstChild("HumanoidRootPart")
end

local function onHammerActivated(player)
	local data = PlayerData.getByPlayer(player)
	if not data then
		return
	end
	local now = os.time()
	if now - data.lastSteal < Config.STEAL_COOLDOWN then
		return
	end
	data.lastSteal = now
	local root = getRootPart(player)
	if not root then
		return
	end
	local target = BrainrotSystem.findNearestOwned(root.Position, Config.STEAL_RANGE,
		player.UserId, true)
	if not target then
		remotes.ShowMessage:FireClient(player, "Tidak ada brainrot curian di dekatmu.")
		return
	end
	local ok, message = BrainrotSystem.transfer(target, player)
	if not ok then
		remotes.ShowMessage:FireClient(player, message)
	end
end

local function onStickActivated(player)
	local data = PlayerData.getByPlayer(player)
	if not data then
		return
	end
	local now = os.time()
	if now - data.lastSlap < Config.SLAP_COOLDOWN then
		return
	end
	data.lastSlap = now
	local root = getRootPart(player)
	if not root then
		return
	end
	local target = BrainrotSystem.findNearestOwned(root.Position, Config.SLAP_RANGE, nil, false)
	if not target then
		return
	end
	local stunned = BrainrotSystem.stun(target, Config.STUN_DURATION)
	if stunned then
		remotes.ShowMessage:FireClient(player,
			"Kamu memukul " .. target.def.name .. " sampai pusing!")
	end
end

-- Beri kedua tool ke pemain (sekali saat join; Backpack dipertahankan saat respawn)
function StealSystem.giveTools(player)
	local backpack = player:WaitForChild("Backpack")
	local hammer = buildHammer()
	hammer.Parent = backpack
	hammer.Activated:Connect(function()
		onHammerActivated(player)
	end)
	local stick = buildStick()
	stick.Parent = backpack
	stick.Activated:Connect(function()
		onStickActivated(player)
	end)
end

function StealSystem.init(remotesArg)
	remotes = remotesArg
end

return StealSystem
