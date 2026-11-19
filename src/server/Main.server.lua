-- Main.server.lua
-- Boot Brainrot Bash: remote, map, semua sistem, join/leave pemain.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local MapBuilder = require(script.Parent.MapBuilder)
local PlayerData = require(script.Parent.PlayerData)
local BrainrotSystem = require(script.Parent.BrainrotSystem)
local EggSystem = require(script.Parent.EggSystem)
local StealSystem = require(script.Parent.StealSystem)
local Leaderboard = require(script.Parent.Leaderboard)

-- ------------------------------------------------------------ RemoteEvents
local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "Remotes"
remotesFolder.Parent = ReplicatedStorage

local updateMoney = Instance.new("RemoteEvent")
updateMoney.Name = "UpdateMoney"
updateMoney.Parent = remotesFolder

local showMessage = Instance.new("RemoteEvent")
showMessage.Name = "ShowMessage"
showMessage.Parent = remotesFolder

local remotes = {
	UpdateMoney = updateMoney,
	ShowMessage = showMessage,
}

-- ------------------------------------------------------------ Map & sistem
local mapRefs = MapBuilder.build()

BrainrotSystem.init(remotes, mapRefs)
EggSystem.init(remotes, mapRefs)
StealSystem.init(remotes)
Leaderboard.init(mapRefs)

-- ------------------------------------------------------------ Pemain
local usedPlots = {} -- [plotIndex] = userId

local function assignPlot(player)
	for i = 1, Config.PLOT_COUNT do
		if usedPlots[i] == nil then
			usedPlots[i] = player.UserId
			return i
		end
	end
	return 0
end

local function freePlot(userId)
	for i, owner in pairs(usedPlots) do
		if owner == userId then
			usedPlots[i] = nil
			local plot = mapRefs.plots[i]
			if plot and plot.ownerLabel then
				plot.ownerLabel.Text = "Kosong"
			end
		end
	end
end

local function onPlayerAdded(player)
	local plotIndex = assignPlot(player)
	PlayerData.add(player, plotIndex)
	if plotIndex > 0 then
		local plot = mapRefs.plots[plotIndex]
		if plot and plot.ownerLabel then
			plot.ownerLabel.Text = player.Name
		end
		remotes.ShowMessage:FireClient(player,
			"Selamat datang! Plot " .. tostring(plotIndex) .. " jadi Rumah kamu.")
	else
		remotes.ShowMessage:FireClient(player,
			"Semua plot penuh! Kamu jadi penonton dulu.")
	end
	-- Boost teman dihitung terpisah (panggilan web, bisa lambat)
	task.spawn(function()
		PlayerData.computeFriendBoost(player)
	end)
	-- Beri tool Palu + Tongkat
	task.spawn(function()
		local ok, err = pcall(function()
			StealSystem.giveTools(player)
		end)
		if not ok then
			warn("[Main] giveTools gagal untuk " .. player.Name .. ": " .. tostring(err))
		end
	end)
	-- Kirim uang awal ke client
	task.spawn(function()
		task.wait(1)
		if player.Parent then
			remotes.UpdateMoney:FireClient(player, Config.START_MONEY, 0, 0, plotIndex)
		end
	end)
end

local function onPlayerRemoving(player)
	BrainrotSystem.removePlayerBrainrots(player.UserId)
	freePlot(player.UserId)
	PlayerData.remove(player.UserId)
	Leaderboard.refresh()
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

print("[Brainrot Bash] Server jalan. Plot: " .. tostring(Config.PLOT_COUNT)
	.. ", brainrot: " .. tostring(#Config.BRAINROTS)
	.. ", telur: " .. tostring(#Config.EGGS))
