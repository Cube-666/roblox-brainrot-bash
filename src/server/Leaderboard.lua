-- Leaderboard.lua
-- Papan top 5 pemain berdasarkan uang (state server live, tanpa DataStore).

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local PlayerData = require(script.Parent.PlayerData)

local Leaderboard = {}

local labels = nil

function Leaderboard.init(mapRefs)
	labels = mapRefs.leaderboardLabels
	task.spawn(function()
		while true do
			task.wait(5)
			Leaderboard.refresh()
		end
	end)
end

function Leaderboard.refresh()
	if not labels then
		return
	end
	local rows = {}
	for _, data in pairs(PlayerData.all()) do
		if data.player and data.player.Parent then
			table.insert(rows, { name = data.player.Name, money = data.money })
		end
	end
	table.sort(rows, function(a, b)
		return a.money > b.money
	end)
	for i = 1, 5 do
		local label = labels[i]
		if label then
			local row = rows[i]
			if row then
				label.Text = tostring(i) .. ". " .. row.name .. " - " .. Config.formatMoney(row.money)
			else
				label.Text = tostring(i) .. ". -"
			end
		end
	end
end

return Leaderboard
