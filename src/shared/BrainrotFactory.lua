-- BrainrotFactory.lua
-- Membangun model brainrot dari Part biasa (tanpa mesh / asset id).
-- Setiap model dibangun di sekitar origin dengan kaki di y=0; fungsi
-- buildBrainrot mengembalikan model + pivotHeight (jarak titik tengah
-- PrimaryPart ke tanah) supaya penempatan di pad/conveyor tepat.

local Config = require(script.Parent.Config)

local Factory = {}

-- Helper: buat satu Part
local function newPart(parent, name, size, color, cf, shape, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.CFrame = cf
	p.Shape = shape or Enum.PartType.Block
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = true
	p.Parent = parent
	return p
end

-- Helper: dua mata (bola putih + pupil hitam) di depan badan.
-- frontZ = posisi z permukaan depan, eyeY = tinggi mata, spread = jarak antar mata
local function addEyes(parent, eyeY, frontZ, spread)
	for _, side in ipairs({ -1, 1 }) do
		local x = side * spread
		newPart(parent, "Mata", Vector3.new(0.45, 0.45, 0.3),
			Color3.fromRGB(255, 255, 255),
			CFrame.new(x, eyeY, frontZ), Enum.PartType.Ball)
		newPart(parent, "Pupil", Vector3.new(0.22, 0.22, 0.15),
			Color3.fromRGB(20, 20, 20),
			CFrame.new(x, eyeY, frontZ + 0.16), Enum.PartType.Ball)
	end
end

-- BillboardGui info di atas model: baris 1 nama, baris 2 harga / $/detik
local function addInfoGui(model, bodyPart, def)
	local gui = Instance.new("BillboardGui")
	gui.Name = "InfoGui"
	gui.Adornee = bodyPart
	gui.Size = UDim2.new(0, 150, 0, 56)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
	gui.AlwaysOnTop = true
	gui.Parent = model

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Line1"
	nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 15
	nameLabel.TextColor3 = Config.RARITY_COLORS[def.rarity] or Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0.2
	nameLabel.Text = def.name
	nameLabel.Parent = gui

	local subLabel = Instance.new("TextLabel")
	subLabel.Name = "Line2"
	subLabel.Size = UDim2.new(1, 0, 0.5, 0)
	subLabel.Position = UDim2.new(0, 0, 0.5, 0)
	subLabel.BackgroundTransparency = 1
	subLabel.Font = Enum.Font.GothamBold
	subLabel.TextSize = 15
	subLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
	subLabel.TextStrokeTransparency = 0.2
	subLabel.Text = Config.formatMoney(def.price)
	subLabel.Parent = gui
	return gui
end

-- Ubah teks BillboardGui
function Factory.setBillboard(model, line1, line2)
	local gui = model:FindFirstChild("InfoGui")
	if not gui then
		return
	end
	local l1 = gui:FindFirstChild("Line1")
	local l2 = gui:FindFirstChild("Line2")
	if l1 then
		l1.Text = line1
	end
	if l2 then
		l2.Text = line2
	end
end

-- ProximityPrompt "Beli" di badan model
local function addBuyPrompt(bodyPart, def)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Beli"
	prompt.ObjectText = def.name .. " - " .. Config.formatMoney(def.price)
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = bodyPart
	return prompt
end

-- ------------------------------------------------------------------ Bentuk
-- Setiap builder menerima (model, def) dan mengembalikan PrimaryPart + pivotHeight.
-- Semua bagian dibangun menghadap +Z (muka di z positif).

local builders = {}

-- Hiu Bajak Laut: badan biru, perut putih, sirip, topi bajak laut
function builders.shark(model, def)
	local body = newPart(model, "Badan", Vector3.new(3.2, 1.8, 2.4), def.bodyColor,
		CFrame.new(0, 2.2, 0))
	newPart(model, "Perut", Vector3.new(2.6, 0.8, 2.45), def.bellyColor,
		CFrame.new(0, 1.6, 0))
	newPart(model, "SiripAtas", Vector3.new(0.5, 1.1, 1.2), def.bodyColor,
		CFrame.new(0, 3.4, -0.3) * CFrame.Angles(0, 0, math.rad(-20)), Enum.PartType.Wedge)
	newPart(model, "Ekor", Vector3.new(0.5, 1.4, 1.0), def.bodyColor,
		CFrame.new(0, 2.4, -1.5) * CFrame.Angles(math.rad(25), 0, 0), Enum.PartType.Wedge)
	newPart(model, "Topi", Vector3.new(2.8, 0.5, 2.6), Color3.fromRGB(30, 30, 30),
		CFrame.new(0, 3.35, 0))
	newPart(model, "TopiAtas", Vector3.new(1.4, 0.7, 1.4), Color3.fromRGB(30, 30, 30),
		CFrame.new(0, 3.85, 0))
	newPart(model, "Tengkorak", Vector3.new(0.5, 0.5, 0.2), Color3.fromRGB(255, 255, 255),
		CFrame.new(0, 3.4, 1.32))
	addEyes(model, 2.5, 1.25, 0.7)
	return body, 2.2
end

-- Tomat Merah: bola merah + tangkai hijau
function builders.tomato(model, def)
	local body = newPart(model, "Badan", Vector3.new(3.6, 3.6, 3.6), def.bodyColor,
		CFrame.new(0, 1.9, 0), Enum.PartType.Ball)
	newPart(model, "Tangkai", Vector3.new(0.5, 0.8, 0.5), Color3.fromRGB(39, 174, 96),
		CFrame.new(0, 3.9, 0))
	newPart(model, "Daun1", Vector3.new(1.2, 0.25, 0.7), Color3.fromRGB(39, 174, 96),
		CFrame.new(0.7, 3.6, 0) * CFrame.Angles(0, 0, math.rad(-25)))
	newPart(model, "Daun2", Vector3.new(1.2, 0.25, 0.7), Color3.fromRGB(39, 174, 96),
		CFrame.new(-0.7, 3.6, 0) * CFrame.Angles(0, 0, math.rad(25)))
	addEyes(model, 2.2, 1.7, 0.7)
	return body, 1.9
end

-- Kaktus Spinoso: badan hijau tinggi + duri + bunga pink
function builders.cactus(model, def)
	local body = newPart(model, "Badan", Vector3.new(2.4, 3.6, 2.4), def.bodyColor,
		CFrame.new(0, 2.0, 0))
	newPart(model, "LenganKiri", Vector3.new(1.4, 0.6, 0.6), def.bellyColor,
		CFrame.new(-1.7, 2.4, 0))
	newPart(model, "LenganKanan", Vector3.new(1.4, 0.6, 0.6), def.bellyColor,
		CFrame.new(1.7, 1.8, 0))
	for _, sx in ipairs({ -1, 1 }) do
		newPart(model, "Duri", Vector3.new(0.3, 0.3, 0.3), Color3.fromRGB(20, 90, 50),
			CFrame.new(sx * 1.25, 2.8, 0.6))
		newPart(model, "Duri", Vector3.new(0.3, 0.3, 0.3), Color3.fromRGB(20, 90, 50),
			CFrame.new(sx * 1.25, 1.4, -0.6))
	end
	newPart(model, "Bunga", Vector3.new(0.9, 0.9, 0.9), Color3.fromRGB(253, 121, 168),
		CFrame.new(0, 4.1, 0), Enum.PartType.Ball)
	addEyes(model, 2.4, 1.25, 0.55)
	return body, 2.0
end

-- Cacing Tomat: 3 ruas bola oranye + antena
function builders.worm(model, def)
	local mid = newPart(model, "Badan", Vector3.new(2.2, 2.2, 2.2), def.bodyColor,
		CFrame.new(0, 1.1, 0), Enum.PartType.Ball)
	newPart(model, "RuasBelakang", Vector3.new(1.9, 1.9, 1.9), def.bellyColor,
		CFrame.new(0, 1.0, -1.9), Enum.PartType.Ball)
	newPart(model, "RuasDepan", Vector3.new(2.0, 2.0, 2.0), def.bodyColor,
		CFrame.new(0, 1.1, 1.9), Enum.PartType.Ball)
	newPart(model, "AntenaKiri", Vector3.new(0.2, 1.0, 0.2), Color3.fromRGB(192, 57, 43),
		CFrame.new(-0.5, 2.6, 2.2) * CFrame.Angles(0, 0, math.rad(15)))
	newPart(model, "AntenaKanan", Vector3.new(0.2, 1.0, 0.2), Color3.fromRGB(192, 57, 43),
		CFrame.new(0.5, 2.6, 2.2) * CFrame.Angles(0, 0, math.rad(-15)))
	addEyes(model, 1.5, 2.85, 0.5)
	return mid, 1.1
end

-- Gajah Flores: badan abu-abu, telinga lebar, belalai, bunga di kepala
function builders.elephant(model, def)
	local body = newPart(model, "Badan", Vector3.new(3.4, 2.6, 2.6), def.bodyColor,
		CFrame.new(0, 2.0, 0))
	newPart(model, "TelingaKiri", Vector3.new(0.3, 1.8, 1.6), def.bellyColor,
		CFrame.new(-1.8, 2.6, 0.6))
	newPart(model, "TelingaKanan", Vector3.new(0.3, 1.8, 1.6), def.bellyColor,
		CFrame.new(1.8, 2.6, 0.6))
	newPart(model, "Belalai1", Vector3.new(0.7, 1.2, 0.7), def.bodyColor,
		CFrame.new(0, 1.6, 1.5))
	newPart(model, "Belalai2", Vector3.new(0.6, 1.0, 0.6), def.bodyColor,
		CFrame.new(0, 0.9, 1.8))
	newPart(model, "Bunga", Vector3.new(0.8, 0.8, 0.8), Color3.fromRGB(253, 121, 168),
		CFrame.new(0.8, 3.6, 0.3), Enum.PartType.Ball)
	newPart(model, "KakiKiri", Vector3.new(0.9, 0.7, 0.9), Color3.fromRGB(120, 130, 130),
		CFrame.new(-1.1, 0.35, 0.8))
	newPart(model, "KakiKanan", Vector3.new(0.9, 0.7, 0.9), Color3.fromRGB(120, 130, 130),
		CFrame.new(1.1, 0.35, 0.8))
	addEyes(model, 2.6, 1.35, 0.8)
	return body, 2.0
end

-- Traktor Bulbito: badan kuning, kabin, 4 roda silinder, knalpot
function builders.tractor(model, def)
	local body = newPart(model, "Badan", Vector3.new(3.0, 1.4, 4.2), def.bodyColor,
		CFrame.new(0, 2.0, 0))
	newPart(model, "Kabin", Vector3.new(2.2, 1.6, 1.8), Color3.fromRGB(52, 73, 94),
		CFrame.new(0, 3.3, -0.8))
	newPart(model, "Kaca", Vector3.new(2.0, 1.0, 0.2), Color3.fromRGB(174, 214, 241),
		CFrame.new(0, 3.4, 0.15))
	newPart(model, "Knalpot", Vector3.new(0.4, 1.4, 0.4), Color3.fromRGB(60, 60, 60),
		CFrame.new(1.2, 3.2, 0.8))
	for _, sz in ipairs({ -1, 1 }) do
		for _, fz in ipairs({ -1.5, 1.5 }) do
			newPart(model, "Roda", Vector3.new(0.5, 2.0, 2.0), Color3.fromRGB(30, 30, 30),
				CFrame.new(sz * 1.6, 1.0, fz), Enum.PartType.Cylinder)
		end
	end
	newPart(model, "Lampu", Vector3.new(0.5, 0.5, 0.3), Color3.fromRGB(255, 255, 200),
		CFrame.new(-0.9, 2.2, 2.15), Enum.Material.Neon)
	newPart(model, "Lampu", Vector3.new(0.5, 0.5, 0.3), Color3.fromRGB(255, 255, 200),
		CFrame.new(0.9, 2.2, 2.15), Enum.Material.Neon)
	return body, 2.0
end

-- Kapten Pirat: badan gelap, topi besar, penutup mata, pedang
function builders.pirate(model, def)
	local body = newPart(model, "Badan", Vector3.new(3.0, 2.0, 2.2), def.bodyColor,
		CFrame.new(0, 2.2, 0))
	newPart(model, "Sabuk", Vector3.new(3.05, 0.4, 2.25), def.bellyColor,
		CFrame.new(0, 1.6, 0))
	newPart(model, "Topi", Vector3.new(3.4, 0.5, 2.8), Color3.fromRGB(20, 20, 20),
		CFrame.new(0, 3.5, 0))
	newPart(model, "TopiAtas", Vector3.new(1.8, 0.9, 1.8), Color3.fromRGB(20, 20, 20),
		CFrame.new(0, 4.1, 0))
	newPart(model, "Tengkorak", Vector3.new(0.6, 0.6, 0.2), Color3.fromRGB(255, 255, 255),
		CFrame.new(0, 3.55, 1.42))
	newPart(model, "PenutupMata", Vector3.new(0.55, 0.4, 0.2), Color3.fromRGB(10, 10, 10),
		CFrame.new(-0.7, 2.6, 1.15))
	newPart(model, "Pedang", Vector3.new(0.25, 2.2, 0.6), Color3.fromRGB(200, 200, 200),
		CFrame.new(1.8, 2.0, 0.4) * CFrame.Angles(0, 0, math.rad(-30)))
	newPart(model, "GagangPedang", Vector3.new(0.3, 0.6, 0.3), Color3.fromRGB(120, 72, 20),
		CFrame.new(1.45, 1.0, 0.4))
	addEyes(model, 2.6, 1.15, 0.7)
	return body, 2.2
end

-- Kucing Samurai: badan emas, telinga runcing, ikat kepala merah, ekor
function builders.cat(model, def)
	local body = newPart(model, "Badan", Vector3.new(2.4, 2.2, 2.0), def.bodyColor,
		CFrame.new(0, 2.0, 0))
	newPart(model, "TelingaKiri", Vector3.new(0.7, 1.0, 0.7), def.bodyColor,
		CFrame.new(-0.8, 3.4, 0), Enum.PartType.Wedge)
	newPart(model, "TelingaKanan", Vector3.new(0.7, 1.0, 0.7), def.bodyColor,
		CFrame.new(0.8, 3.4, 0), Enum.PartType.Wedge)
	newPart(model, "IkatKepala", Vector3.new(2.5, 0.4, 2.05), def.bellyColor,
		CFrame.new(0, 2.9, 0))
	newPart(model, "Ekor", Vector3.new(0.4, 2.2, 0.4), def.bodyColor,
		CFrame.new(0, 1.6, -1.4) * CFrame.Angles(math.rad(-30), 0, 0))
	newPart(model, "Katana", Vector3.new(0.2, 2.4, 0.5), Color3.fromRGB(220, 220, 220),
		CFrame.new(-1.5, 1.8, 0.3) * CFrame.Angles(0, 0, math.rad(25)))
	addEyes(model, 2.4, 1.05, 0.55)
	return body, 2.0
end

-- ------------------------------------------------------------------ API

-- Bangun satu brainrot di posisi tanah (Vector3) dengan arah yaw (radian).
-- Mengembalikan model dan pivotHeight.
function Factory.buildBrainrot(def, groundPos, yaw)
	local model = Instance.new("Model")
	model.Name = def.name

	local builder = builders[def.build] or builders.shark
	local bodyPart, pivotHeight = builder(model, def)

	model.PrimaryPart = bodyPart
	model:SetAttribute("BrainrotId", def.id)
	model:SetAttribute("Price", def.price)
	model:SetAttribute("Income", def.income)
	model:SetAttribute("State", "belt")
	model:SetAttribute("OwnerUserId", 0)
	model:SetAttribute("StunnedUntil", 0)
	model:SetAttribute("StealLockUntil", 0)

	addInfoGui(model, bodyPart, def)
	local prompt = addBuyPrompt(bodyPart, def)
	model:SetAttribute("HasPrompt", true)

	model:PivotTo(CFrame.new(groundPos) * CFrame.Angles(0, yaw or 0, 0)
		* CFrame.new(0, pivotHeight, 0))
	model.Parent = workspace
	return model, pivotHeight, prompt
end

return Factory
