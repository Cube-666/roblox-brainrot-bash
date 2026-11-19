-- MapBuilder.lua
-- Membangun seluruh map Brainrot Bash dari Part biasa.
-- Layout (y=0 permukaan baseplate):
--   Spawn di (0, 0, 88), menghadap -Z ke arah plot.
--   Conveyor di z = -30, dari x = -80 ke x = +80.
--   6 plot "Rumah" berderet di z = +30, pusat x = -75..75.
--   Area telur di sisi barat (x = -115). Leaderboard di dekat spawn.
-- Mengembalikan tabel referensi yang dipakai sistem lain.

local MapBuilder = {}

local PLOT_X = { -75, -45, -15, 15, 45, 75 }
local PLOT_Z = 30
local PLOT_COLORS = {
	Color3.fromRGB(93, 173, 226),
	Color3.fromRGB(88, 214, 141),
	Color3.fromRGB(245, 176, 65),
	Color3.fromRGB(236, 112, 99),
	Color3.fromRGB(187, 143, 206),
	Color3.fromRGB(93, 173, 226),
}
local PAD_OFFSETS = { -8.4, -4.2, 0, 4.2, 8.4 }

-- Helper: satu Part kotak
local function box(parent, name, size, color, pos, collide, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Position = pos
	p.Anchored = true
	p.CanCollide = collide
	p.CanTouch = false
	p.Material = material or Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end

-- Helper: label teks di SurfaceGui
local function guiLabel(gui, name, text, size, pos, textSize, textColor, bold)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Size = size
	l.Position = pos
	l.BackgroundTransparency = 1
	l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	l.TextSize = textSize
	l.TextColor3 = textColor
	l.TextStrokeTransparency = 0.3
	l.TextScaled = true
	l.Text = text
	l.Parent = gui
	return l
end

-- Helper: SurfaceGui di satu sisi part
local function surfaceGui(part, face)
	local g = Instance.new("SurfaceGui")
	g.Face = face
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 40
	g.Parent = part
	return g
end

function MapBuilder.build()
	local ws = game:GetService("Workspace")
	local map = Instance.new("Folder")
	map.Name = "Map"
	map.Parent = ws

	local refs = {
		plots = {},
		eggStands = {},
		leaderboardLabels = {},
	}

	-- ---------------------------------------------------------- Spawn area
	box(map, "SpawnPad", Vector3.new(24, 0.5, 14), Color3.fromRGB(213, 220, 229),
		Vector3.new(0, 0.25, 88), true)
	local safePart = box(map, "AreaAman", Vector3.new(10, 0.2, 4), Color3.fromRGB(88, 214, 141),
		Vector3.new(0, 0.6, 82), false)
	local safeGui = surfaceGui(safePart, Enum.NormalId.Top)
	guiLabel(safeGui, "Teks", "Area Aman", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0),
		40, Color3.fromRGB(255, 255, 255), true)

	local spawnLoc = Instance.new("SpawnLocation")
	spawnLoc.Name = "SpawnLocation"
	spawnLoc.Size = Vector3.new(10, 1, 6)
	spawnLoc.Position = Vector3.new(0, 0.5, 88)
	spawnLoc.Anchored = true
	spawnLoc.Neutral = true
	spawnLoc.Duration = 0
	spawnLoc.TopSurface = Enum.SurfaceType.Smooth
	spawnLoc.Parent = map
	refs.spawn = spawnLoc

	-- Papan judul besar
	local titleBoard = box(map, "PapanJudul", Vector3.new(26, 6, 0.5), Color3.fromRGB(231, 76, 60),
		Vector3.new(0, 5, 74), false)
	local titleGui = surfaceGui(titleBoard, Enum.NormalId.Back)
	guiLabel(titleGui, "Judul", "BRAINROT BASH", UDim2.new(1, 0, 0.55, 0), UDim2.new(0, 0, 0.05, 0),
		60, Color3.fromRGB(255, 255, 255), true)
	guiLabel(titleGui, "Sub", "Beli  •  Hasilkan  •  Curi", UDim2.new(1, 0, 0.3, 0),
		UDim2.new(0, 0, 0.6, 0), 30, Color3.fromRGB(255, 235, 150), true)

	-- Papan leaderboard
	local lbBoard = box(map, "PapanLeaderboard", Vector3.new(16, 9, 0.5), Color3.fromRGB(44, 62, 80),
		Vector3.new(26, 4.5, 74), false)
	local lbGui = surfaceGui(lbBoard, Enum.NormalId.Back)
	guiLabel(lbGui, "Judul", "LEADERBOARD", UDim2.new(1, 0, 0.16, 0), UDim2.new(0, 0, 0.02, 0),
		40, Color3.fromRGB(241, 196, 15), true)
	for i = 1, 5 do
		local row = guiLabel(lbGui, "Baris" .. tostring(i), tostring(i) .. ". -",
			UDim2.new(0.94, 0, 0.14, 0), UDim2.new(0.03, 0, 0.18 + (i - 1) * 0.15, 0),
			28, Color3.fromRGB(255, 255, 255), false)
		row.TextXAlignment = Enum.TextXAlignment.Left
		refs.leaderboardLabels[i] = row
	end

	-- ---------------------------------------------------------- Conveyor
	local belt = box(map, "Conveyor", Vector3.new(170, 1, 8), Color3.fromRGB(60, 60, 70),
		Vector3.new(0, 0.7, -30), true)
	belt.Material = Enum.Material.Metal
	box(map, "RelKiri", Vector3.new(170, 0.6, 0.6), Color3.fromRGB(241, 196, 15),
		Vector3.new(0, 1.4, -34.2), false)
	box(map, "RelKanan", Vector3.new(170, 0.6, 0.6), Color3.fromRGB(241, 196, 15),
		Vector3.new(0, 1.4, -25.8), false)
	for _, lx in ipairs({ -60, -20, 20, 60 }) do
		box(map, "KakiConveyor", Vector3.new(1, 1.4, 6), Color3.fromRGB(80, 80, 90),
			Vector3.new(lx, -0.7, -30), false)
	end
	-- Penanda ujung conveyor
	box(map, "UjungMasuk", Vector3.new(1, 3, 8), Color3.fromRGB(46, 204, 113),
		Vector3.new(-86, 1.5, -30), false)
	box(map, "UjungKeluar", Vector3.new(1, 3, 8), Color3.fromRGB(231, 76, 60),
		Vector3.new(86, 1.5, -30), false)

	refs.conveyor = {
		startPos = Vector3.new(-80, 1.2, -30),
		endPos = Vector3.new(80, 1.2, -30),
		beltTopY = 1.2,
	}

	-- ---------------------------------------------------------- Plot (Rumah)
	for i, cx in ipairs(PLOT_X) do
		local plotColor = PLOT_COLORS[i]
		box(map, "LantaiPlot" .. tostring(i), Vector3.new(24, 0.5, 20), plotColor,
			Vector3.new(cx, 0.25, PLOT_Z), true)
		-- Dinding belakang (dekorasi, tidak menghalangi)
		box(map, "DindingPlot" .. tostring(i), Vector3.new(24, 1.2, 0.5), plotColor,
			Vector3.new(cx, 1.1, PLOT_Z + 9.75), false)

		local plot = {
			index = i,
			center = Vector3.new(cx, 0, PLOT_Z),
			pads = {},
			padPositions = {},
		}
		for s, off in ipairs(PAD_OFFSETS) do
			local padPos = Vector3.new(cx + off, 0.65, PLOT_Z)
			local pad = Instance.new("Part")
			pad.Name = "Pad" .. tostring(s)
			pad.Shape = Enum.PartType.Cylinder
			pad.Size = Vector3.new(0.3, 5, 5)
			pad.CFrame = CFrame.new(padPos) * CFrame.Angles(0, 0, math.rad(90))
			pad.Color = Color3.fromRGB(46, 204, 113)
			pad.Material = Enum.Material.Neon
			pad.Anchored = true
			pad.CanCollide = false
			pad.CanTouch = false
			pad.Parent = map
			plot.pads[s] = pad
			plot.padPositions[s] = Vector3.new(cx + off, 0.8, PLOT_Z)
		end

		-- Papan nama "Rumah" di belakang plot, menghadap spawn (+Z = Back)
		box(map, "TiangNama" .. tostring(i), Vector3.new(1, 4, 1), Color3.fromRGB(120, 72, 20),
			Vector3.new(cx, 2.5, PLOT_Z + 11), false)
		local sign = box(map, "PapanNama" .. tostring(i), Vector3.new(10, 3, 0.5),
			Color3.fromRGB(192, 57, 43), Vector3.new(cx, 5, PLOT_Z + 11), false)
		local signGui = surfaceGui(sign, Enum.NormalId.Back)
		guiLabel(signGui, "Judul", "Rumah", UDim2.new(1, 0, 0.55, 0), UDim2.new(0, 0, 0.02, 0),
			50, Color3.fromRGB(255, 255, 255), true)
		local ownerLabel = guiLabel(signGui, "Pemilik", "Kosong", UDim2.new(1, 0, 0.35, 0),
			UDim2.new(0, 0, 0.6, 0), 30, Color3.fromRGB(255, 235, 150), true)
		plot.ownerLabel = ownerLabel
		refs.plots[i] = plot
	end

	-- ---------------------------------------------------------- Area telur
	local eggSign = box(map, "PapanTelur", Vector3.new(0.5, 4, 12), Color3.fromRGB(192, 57, 43),
		Vector3.new(-122, 4, -30), false)
	local eggSignGui = surfaceGui(eggSign, Enum.NormalId.Right)
	guiLabel(eggSignGui, "Judul", "Pecahkan", UDim2.new(1, 0, 0.4, 0), UDim2.new(0, 0, 0.05, 0),
		44, Color3.fromRGB(255, 255, 255), true)
	guiLabel(eggSignGui, "Judul2", "Telur!", UDim2.new(1, 0, 0.4, 0), UDim2.new(0, 0, 0.45, 0),
		44, Color3.fromRGB(255, 235, 150), true)

	local eggZ = { -45, -30, -15 }
	for tier = 1, 3 do
		local z = eggZ[tier]
		local pedestal = Instance.new("Part")
		pedestal.Name = "AlasTelur" .. tostring(tier)
		pedestal.Shape = Enum.PartType.Cylinder
		pedestal.Size = Vector3.new(1, 4.5, 4.5)
		pedestal.CFrame = CFrame.new(-115, 0.5, z) * CFrame.Angles(0, 0, math.rad(90))
		pedestal.Color = Color3.fromRGB(200, 200, 210)
		pedestal.Anchored = true
		pedestal.CanCollide = true
		pedestal.CanTouch = false
		pedestal.Parent = map

		local egg = Instance.new("Part")
		egg.Name = "Telur" .. tostring(tier)
		egg.Shape = Enum.PartType.Ball
		egg.Size = Vector3.new(2.8, 3.4, 2.8)
		egg.Position = Vector3.new(-115, 2.6, z)
		egg.Color = Color3.fromRGB(236, 240, 241)
		egg.Anchored = true
		egg.CanCollide = false
		egg.CanTouch = false
		egg.Parent = map

		local standSign = box(map, "LabelTelur" .. tostring(tier), Vector3.new(0.5, 2.5, 5),
			Color3.fromRGB(44, 62, 80), Vector3.new(-112, 2.2, z), false)
		local standGui = surfaceGui(standSign, Enum.NormalId.Right)
		guiLabel(standGui, "Nama", "Telur " .. tostring(tier), UDim2.new(1, 0, 0.5, 0),
			UDim2.new(0, 0, 0.05, 0), 34, Color3.fromRGB(255, 255, 255), true)
		guiLabel(standGui, "Harga", "???", UDim2.new(1, 0, 0.4, 0), UDim2.new(0, 0, 0.5, 0),
			30, Color3.fromRGB(255, 235, 150), true)

		refs.eggStands[tier] = {
			tier = tier,
			eggPart = egg,
			position = Vector3.new(-115, 1.0, z),
			priceLabel = standGui:FindFirstChild("Harga"),
		}
	end

	-- ---------------------------------------------------------- Dekorasi
	local treeSpots = {
		{ -120, 70 }, { 120, 70 }, { -120, -70 }, { 120, -70 },
		{ -100, 55 }, { 100, -55 },
	}
	for _, spot in ipairs(treeSpots) do
		local trunk = Instance.new("Part")
		trunk.Name = "Pohon"
		trunk.Shape = Enum.PartType.Cylinder
		trunk.Size = Vector3.new(3, 1.4, 1.4)
		trunk.CFrame = CFrame.new(spot[1], 1.5, spot[2]) * CFrame.Angles(0, 0, math.rad(90))
		trunk.Color = Color3.fromRGB(120, 72, 20)
		trunk.Anchored = true
		trunk.CanCollide = false
		trunk.CanTouch = false
		trunk.Parent = map
		local leaves = Instance.new("Part")
		leaves.Name = "Daun"
		leaves.Shape = Enum.PartType.Ball
		leaves.Size = Vector3.new(6, 6, 6)
		leaves.Position = Vector3.new(spot[1], 6, spot[2])
		leaves.Color = Color3.fromRGB(39, 174, 96)
		leaves.Anchored = true
		leaves.CanCollide = false
		leaves.CanTouch = false
		leaves.Parent = map
	end
	for _, lx in ipairs({ -40, 40 }) do
		box(map, "TiangLampu", Vector3.new(0.6, 7, 0.6), Color3.fromRGB(60, 60, 60),
			Vector3.new(lx, 3.5, 60), false)
		local lamp = Instance.new("Part")
		lamp.Name = "Lampu"
		lamp.Shape = Enum.PartType.Ball
		lamp.Size = Vector3.new(1.6, 1.6, 1.6)
		lamp.Position = Vector3.new(lx, 7.4, 60)
		lamp.Color = Color3.fromRGB(255, 240, 180)
		lamp.Material = Enum.Material.Neon
		lamp.Anchored = true
		lamp.CanCollide = false
		lamp.CanTouch = false
		lamp.Parent = map
	end

	return refs
end

return MapBuilder
