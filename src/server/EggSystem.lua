-- EggSystem.lua
-- Area "Pecahkan Telur!": beli telur, brainrot acak menetas dan jalan ke plot.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Factory = require(game:GetService("ReplicatedStorage").Shared.BrainrotFactory)
local PlayerData = require(script.Parent.PlayerData)
local BrainrotSystem = require(script.Parent.BrainrotSystem)

local EggSystem = {}

local remotes = nil
local mapRefs = nil

local function tryBuyEgg(player, tier)
	local egg = Config.EGGS[tier]
	if not egg then
		return
	end
	local data = PlayerData.getByPlayer(player)
	if not data then
		return
	end
	if data.plotIndex == 0 then
		remotes.ShowMessage:FireClient(player, "Kamu belum punya plot!")
		return
	end
	if data.money < egg.price then
		remotes.ShowMessage:FireClient(player,
			"Uang kurang! " .. egg.name .. " harganya " .. Config.formatMoney(egg.price))
		return
	end
	-- Cek slot kosong dulu (pakai BrainrotSystem lewat pad gratis)
	local plot = mapRefs.plots[data.plotIndex]
	if not plot then
		return
	end
	-- Menetas: pilih brainrot acak dari pool tier ini
	local def = Config.pickEggBrainrot(tier)
	if not def then
		return
	end
	-- Potong uang setelah semua cek lolos
	PlayerData.trySpend(player.UserId, egg.price)
	local stand = mapRefs.eggStands[tier]
	local spawnPos = stand.position
	-- Telur menetas tepat di stand, lalu brainrot jalan ke plot
	local model, pivotHeight = Factory.buildBrainrot(def, spawnPos, math.rad(90))
	-- Telur yang dibeli bukan untuk dijual: hapus prompt belinya
	local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then
		prompt:Destroy()
	end
	model:SetAttribute("State", "sold")
	-- Daftarkan sebagai record lewat BrainrotSystem (jalan ke plot + income)
	local ok, message = BrainrotSystem.adoptHatched(model, def, pivotHeight, player)
	if not ok then
		-- Plot penuh mendadak: kembalikan uang, hapus model
		PlayerData.addMoney(player.UserId, egg.price)
		if model.Parent then
			model:Destroy()
		end
		remotes.ShowMessage:FireClient(player, message or "Plot kamu penuh!")
		return
	end
	remotes.ShowMessage:FireClient(player, egg.name .. " menetas jadi " .. def.name .. "!")
end

function EggSystem.init(remotesArg, mapRefsArg)
	remotes = remotesArg
	mapRefs = mapRefsArg
	for tier, stand in ipairs(mapRefs.eggStands) do
		local egg = Config.EGGS[tier]
		stand.eggPart.Color = egg.color
		if stand.priceLabel then
			stand.priceLabel.Text = Config.formatMoney(egg.price)
		end
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Beli"
		prompt.ObjectText = egg.name .. " - " .. Config.formatMoney(egg.price)
		prompt.HoldDuration = 0.5
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = stand.eggPart
		local thisTier = tier
		prompt.Triggered:Connect(function(player)
			tryBuyEgg(player, thisTier)
		end)
	end
end

return EggSystem
