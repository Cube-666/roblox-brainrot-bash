-- BrainrotSystem.lua
-- Conveyor + jual-beli + jalan ke plot + income + transfer (curi).
-- Semua uang & kepemilikan divalidasi di server.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Factory = require(game:GetService("ReplicatedStorage").Shared.BrainrotFactory)
local PlayerData = require(script.Parent.PlayerData)

local BrainrotSystem = {}

local remotes = nil
local mapRefs = nil
local records = {} -- semua record brainrot hidup
local belt = {} -- record yang sedang di conveyor
local pads = {} -- pads[plotIndex][padIndex] = record atau nil

-- ------------------------------------------------------------------ util

local function removeFromList(list, item)
	for i, v in ipairs(list) do
		if v == item then
			table.remove(list, i)
			return true
		end
	end
	return false
end

local function updateBillboardOwned(rec)
	local income = rec.def.income
	Factory.setBillboard(rec.model, rec.def.name, Config.formatMoney(income) .. "/dtk")
end

local function updateBillboardStunned(rec)
	Factory.setBillboard(rec.model, rec.def.name, "Pusing!")
end

-- ------------------------------------------------------------------ mover
-- Satu loop Heartbeat menggerakkan semua brainrot yang sedang jalan.
-- mover = { waypoints = {Vector3 (Y = permukaan)}, speed, index, onArrive }

local function stepMover(rec, mv, dt)
	local model = rec.model
	if not model.Parent then
		rec.mover = nil
		return nil
	end
	local target = mv.waypoints[mv.index]
	if not target then
		rec.mover = nil
		return "done"
	end
	local pivot = model:GetPivot()
	local current = pivot.Position
	local goal = Vector3.new(target.X, target.Y + rec.pivotHeight, target.Z)
	local delta = goal - current
	local dist = delta.Magnitude
	if dist < 0.35 then
		mv.index = mv.index + 1
		if mv.index > #mv.waypoints then
			rec.mover = nil
			return "done"
		end
		return nil
	end
	local step = math.min(dist, mv.speed * dt)
	local dir = delta / dist
	local bob = math.sin(os.clock() * 8 + (rec.bobPhase or 0)) * 0.12
	local newPos = current + dir * step
	newPos = Vector3.new(newPos.X, newPos.Y + bob * dt * 8, newPos.Z)
	-- Hadap arah jalan (horizontal saja)
	local flat = Vector3.new(dir.X, 0, dir.Z)
	if flat.Magnitude > 0.01 then
		model:PivotTo(CFrame.lookAt(newPos, newPos + flat))
	else
		model:PivotTo(CFrame.new(newPos) * pivot.Rotation)
	end
	return nil
end

local function startMoverLoop()
	local RunService = game:GetService("RunService")
	RunService.Heartbeat:Connect(function(dt)
		local finished = {}
		for _, rec in ipairs(records) do
			local mv = rec.mover
			if mv then
				local result = stepMover(rec, mv, dt)
				if result == "done" then
					table.insert(finished, { rec = rec, cb = mv.onArrive })
				end
			end
		end
		for _, fin in ipairs(finished) do
			if fin.cb then
				fin.cb(fin.rec)
			end
		end
	end)
end

-- ------------------------------------------------------------------ pad

local function findFreePad(plotIndex)
	local plotPads = pads[plotIndex]
	if not plotPads then
		return 0
	end
	for i = 1, Config.PLOT_SLOTS do
		if plotPads[i] == nil then
			return i
		end
	end
	return 0
end

local function freePad(rec)
	if rec.plotIndex > 0 and rec.padIndex > 0 then
		local plotPads = pads[rec.plotIndex]
		if plotPads and plotPads[rec.padIndex] == rec then
			plotPads[rec.padIndex] = nil
		end
	end
	rec.padIndex = 0
end

-- Jalan ke sebuah pad; saat sampai panggil onArrived
local function walkToPad(rec, plotIndex, padIndex, speed, onArrived)
	local plot = mapRefs.plots[plotIndex]
	if not plot then
		return false
	end
	local padPos = plot.padPositions[padIndex]
	local current = rec.model:GetPivot().Position
	pads[plotIndex][padIndex] = rec
	rec.plotIndex = plotIndex
	rec.padIndex = padIndex
	rec.state = "walking"
	rec.model:SetAttribute("State", "walking")
	rec.mover = {
		waypoints = {
			Vector3.new(padPos.X, 0, current.Z),
			padPos,
		},
		speed = speed,
		index = 1,
		onArrive = function(r)
			r.state = "owned"
			r.model:SetAttribute("State", "owned")
			updateBillboardOwned(r)
			if onArrived then
				onArrived(r)
			end
		end,
	}
	return true
end

-- ------------------------------------------------------------------ spawn

local function despawnRecord(rec)
	removeFromList(records, rec)
	removeFromList(belt, rec)
	freePad(rec)
	if rec.model and rec.model.Parent then
		rec.model:Destroy()
	end
end

local function spawnBrainrot()
	if #belt >= Config.CONVEYOR_MAX_ON_BELT then
		return
	end
	local def = Config.pickSpawnBrainrot()
	local start = mapRefs.conveyor.startPos
	local model, pivotHeight, prompt = Factory.buildBrainrot(def, start, math.rad(90))
	local rec = {
		model = model,
		def = def,
		pivotHeight = pivotHeight,
		state = "belt",
		ownerUserId = 0,
		plotIndex = 0,
		padIndex = 0,
		bobPhase = math.random() * 6,
		mover = nil,
	}
	table.insert(records, rec)
	table.insert(belt, rec)
	-- Jalan di conveyor sampai ujung; kalau tidak laku, hilang
	rec.mover = {
		waypoints = { mapRefs.conveyor.endPos },
		speed = Config.CONVEYOR_SPEED,
		index = 1,
		onArrive = function(r)
			if r.state == "belt" then
				despawnRecord(r)
			end
		end,
	}
	prompt.Triggered:Connect(function(player)
		BrainrotSystem.tryBuy(player, rec)
	end)
end

local function startSpawnLoop()
	task.spawn(function()
		while true do
			task.wait(Config.CONVEYOR_SPAWN_INTERVAL + math.random(0, 2))
			local ok, err = pcall(spawnBrainrot)
			if not ok then
				warn("[BrainrotSystem] spawn gagal: " .. tostring(err))
			end
		end
	end)
end

-- ------------------------------------------------------------------ beli

function BrainrotSystem.tryBuy(player, rec)
	if not player or not player.Parent then
		return
	end
	if not rec or not rec.model or not rec.model.Parent then
		return
	end
	if rec.state ~= "belt" then
		return
	end
	local data = PlayerData.getByPlayer(player)
	if not data then
		return
	end
	if data.plotIndex == 0 then
		remotes.ShowMessage:FireClient(player, "Semua plot penuh! Tunggu giliran ya.")
		return
	end
	local padIndex = findFreePad(data.plotIndex)
	if padIndex == 0 then
		remotes.ShowMessage:FireClient(player, "Plot kamu penuh! (5 brainrot maks)")
		return
	end
	local def = rec.def
	if data.money < def.price then
		remotes.ShowMessage:FireClient(player,
			"Uang kurang! " .. def.name .. " harganya " .. Config.formatMoney(def.price))
		return
	end
	-- Semua cek lolos: kunci state dulu (cegah beli ganda), baru potong uang
	rec.state = "sold"
	rec.model:SetAttribute("State", "sold")
	removeFromList(belt, rec)
	local prompt = rec.model:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then
		prompt:Destroy()
	end
	PlayerData.trySpend(player.UserId, def.price)
	rec.ownerUserId = player.UserId
	PlayerData.addOwned(player.UserId, rec)
	remotes.ShowMessage:FireClient(player, "Kamu membeli " .. def.name .. "!")
	walkToPad(rec, data.plotIndex, padIndex, Config.WALK_SPEED, nil)
end

-- Daftarkan brainrot yang sudah dibangun (hasil tetas telur) ke pemain:
-- cari pad kosong, jalan ke sana, mulai hasilkan uang.
-- Mengembalikan true kalau berhasil, false + pesan kalau plot penuh.
function BrainrotSystem.adoptHatched(model, def, pivotHeight, player)
	local data = PlayerData.getByPlayer(player)
	if not data or data.plotIndex == 0 then
		return false, "Kamu belum punya plot."
	end
	local padIndex = findFreePad(data.plotIndex)
	if padIndex == 0 then
		return false, "Plot kamu penuh! (5 brainrot maks)"
	end
	local rec = {
		model = model,
		def = def,
		pivotHeight = pivotHeight,
		state = "sold",
		ownerUserId = player.UserId,
		plotIndex = 0,
		padIndex = 0,
		bobPhase = math.random() * 6,
		mover = nil,
	}
	model:SetAttribute("OwnerUserId", player.UserId)
	table.insert(records, rec)
	PlayerData.addOwned(player.UserId, rec)
	walkToPad(rec, data.plotIndex, padIndex, Config.WALK_SPEED, nil)
	return true, ""
end

-- ------------------------------------------------------------------ curi / pindah

-- Pindahkan brainrot milik orang ke plot pemain baru. Dipakai StealSystem.
-- Mengembalikan true + pesan kalau berhasil.
function BrainrotSystem.transfer(rec, newOwnerPlayer)
	if not rec or not rec.model or not rec.model.Parent then
		return false, "Brainrot sudah tidak ada."
	end
	if rec.state ~= "owned" then
		return false, "Brainrot itu sedang jalan, tunggu sebentar."
	end
	local now = os.time()
	local lockUntil = rec.model:GetAttribute("StealLockUntil") or 0
	if lockUntil > now then
		return false, "Brainrot itu baru saja dicuri, belum bisa dicuri lagi."
	end
	local newData = PlayerData.getByPlayer(newOwnerPlayer)
	if not newData or newData.plotIndex == 0 then
		return false, "Kamu belum punya plot."
	end
	local padIndex = findFreePad(newData.plotIndex)
	if padIndex == 0 then
		return false, "Plot kamu penuh! (5 brainrot maks)"
	end
	local oldOwnerId = rec.ownerUserId
	PlayerData.removeOwned(oldOwnerId, rec)
	freePad(rec)
	rec.ownerUserId = newOwnerPlayer.UserId
	PlayerData.addOwned(newOwnerPlayer.UserId, rec)
	rec.model:SetAttribute("OwnerUserId", newOwnerPlayer.UserId)
	rec.model:SetAttribute("StealLockUntil", now + Config.STOLEN_LOCK)
	remotes.ShowMessage:FireClient(newOwnerPlayer, "Berhasil mencuri " .. rec.def.name .. "!")
	local oldOwner = game:GetService("Players"):GetPlayerByUserId(oldOwnerId)
	if oldOwner then
		remotes.ShowMessage:FireClient(oldOwner,
			newOwnerPlayer.Name .. " mencuri " .. rec.def.name .. " kamu!")
	end
	walkToPad(rec, newData.plotIndex, padIndex, Config.STEAL_WALK_SPEED, nil)
	return true, ""
end

-- Buat brainrot pusing (tidak hasilkan uang) selama duration detik
function BrainrotSystem.stun(rec, duration)
	if not rec or not rec.model or not rec.model.Parent then
		return false
	end
	if rec.state ~= "owned" then
		return false
	end
	rec.model:SetAttribute("StunnedUntil", os.time() + duration)
	updateBillboardStunned(rec)
	return true
end

-- Cari brainrot milik orang lain (atau siapa saja) terdekat dari posisi
function BrainrotSystem.findNearestOwned(position, range, excludeUserId, forSteal)
	local best = nil
	local bestDist = range
	local now = os.time()
	for _, rec in ipairs(records) do
		if rec.state == "owned" and rec.model and rec.model.Parent then
			if excludeUserId == nil or rec.ownerUserId ~= excludeUserId then
				local ok = true
				if forSteal then
					local lockUntil = rec.model:GetAttribute("StealLockUntil") or 0
					if lockUntil > now then
						ok = false
					end
				end
				if ok then
					local d = (rec.model:GetPivot().Position - position).Magnitude
					if d < bestDist then
						bestDist = d
						best = rec
					end
				end
			end
		end
	end
	return best
end

-- Hapus semua brainrot milik pemain yang keluar
function BrainrotSystem.removePlayerBrainrots(userId)
	local data = PlayerData.get(userId)
	if data then
		local copy = {}
		for _, rec in ipairs(data.owned) do
			table.insert(copy, rec)
		end
		for _, rec in ipairs(copy) do
			despawnRecord(rec)
		end
	end
end

-- ------------------------------------------------------------------ income

local function startIncomeLoop()
	task.spawn(function()
		while true do
			task.wait(1)
			local now = os.time()
			for userId, data in pairs(PlayerData.all()) do
				local income = PlayerData.incomePerSecond(userId, now)
				if income > 0 then
					PlayerData.addMoney(userId, income)
				end
				-- Sinkronkan label "Pusing!" kembali ke $/dtk kalau sudah pulih
				for _, rec in ipairs(data.owned) do
					if rec.model and rec.model.Parent and rec.state == "owned" then
						local stunnedUntil = rec.model:GetAttribute("StunnedUntil") or 0
						if stunnedUntil <= now then
							updateBillboardOwned(rec)
						end
					end
				end
				local player = data.player
				if player and player.Parent then
					remotes.UpdateMoney:FireClient(player, data.money, income,
						math.floor(data.boost * 100 + 0.5), data.plotIndex)
				end
			end
		end
	end)
end

-- ------------------------------------------------------------------ init

function BrainrotSystem.init(remotesArg, mapRefsArg)
	remotes = remotesArg
	mapRefs = mapRefsArg
	for i = 1, Config.PLOT_COUNT do
		pads[i] = {}
		for s = 1, Config.PLOT_SLOTS do
			pads[i][s] = nil
		end
	end
	startMoverLoop()
	startSpawnLoop()
	startIncomeLoop()
	-- Spawn awal: 2 brainrot langsung supaya conveyor tidak kosong
	task.spawn(function()
		task.wait(1)
		spawnBrainrot()
		task.wait(2)
		spawnBrainrot()
	end)
end

return BrainrotSystem
