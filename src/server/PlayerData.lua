-- PlayerData.lua
-- State pemain di sisi server (SATU-SATUNYA sumber kebenaran soal uang
-- dan kepemilikan). Client tidak pernah menulis angka ini.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local PlayerData = {}
PlayerData._players = {} -- [userId] = { player, money, plotIndex, owned = {record,...}, boost, lastSteal, lastSlap }

function PlayerData.add(player, plotIndex)
	PlayerData._players[player.UserId] = {
		player = player,
		money = Config.START_MONEY,
		plotIndex = plotIndex or 0, -- 0 = tidak kebagian plot
		owned = {},
		boost = 0,
		lastSteal = 0,
		lastSlap = 0,
	}
end

function PlayerData.remove(userId)
	PlayerData._players[userId] = nil
end

function PlayerData.get(userId)
	return PlayerData._players[userId]
end

function PlayerData.getByPlayer(player)
	if not player then
		return nil
	end
	return PlayerData._players[player.UserId]
end

function PlayerData.getMoney(userId)
	local data = PlayerData._players[userId]
	if not data then
		return 0
	end
	return data.money
end

function PlayerData.addMoney(userId, amount)
	local data = PlayerData._players[userId]
	if not data then
		return 0
	end
	data.money = data.money + amount
	if data.money < 0 then
		data.money = 0
	end
	return data.money
end

-- Coba bayar; mengembalikan true kalau uang cukup (dan langsung dipotong)
function PlayerData.trySpend(userId, amount)
	local data = PlayerData._players[userId]
	if not data then
		return false
	end
	if data.money < amount then
		return false
	end
	data.money = data.money - amount
	return true
end

-- Daftarkan brainrot sebagai milik pemain (record dibuat BrainrotSystem)
function PlayerData.addOwned(userId, record)
	local data = PlayerData._players[userId]
	if not data then
		return false
	end
	table.insert(data.owned, record)
	return true
end

-- Hapus brainrot dari daftar milik pemain; true kalau ketemu
function PlayerData.removeOwned(userId, record)
	local data = PlayerData._players[userId]
	if not data then
		return false
	end
	for i, rec in ipairs(data.owned) do
		if rec == record then
			table.remove(data.owned, i)
			return true
		end
	end
	return false
end

-- Jumlah brainrot milik pemain
function PlayerData.ownedCount(userId)
	local data = PlayerData._players[userId]
	if not data then
		return 0
	end
	return #data.owned
end

-- Total $/detik dari semua brainrot milik pemain (abaikan yang pusing)
function PlayerData.incomePerSecond(userId, now)
	local data = PlayerData._players[userId]
	if not data then
		return 0
	end
	local total = 0
	for _, rec in ipairs(data.owned) do
		if rec.model and rec.model.Parent then
			local stunnedUntil = rec.model:GetAttribute("StunnedUntil") or 0
			if stunnedUntil <= now then
				total = total + rec.def.income
			end
		end
	end
	return total * (1 + data.boost)
end

-- Hitung boost teman: +10% per teman yang ada di server yang sama.
-- Dijalankan di task terpisah karena IsFriendsWith memanggil web.
function PlayerData.computeFriendBoost(player)
	local userId = player.UserId
	local data = PlayerData._players[userId]
	if not data then
		return
	end
	local playersService = game:GetService("Players")
	local friends = 0
	for _, other in ipairs(playersService:GetPlayers()) do
		if other ~= player then
			local ok, isFriend = pcall(function()
				return player:IsFriendsWith(other.UserId)
			end)
			if ok and isFriend then
				friends = friends + 1
			end
		end
	end
	local boost = friends * Config.FRIEND_BOOST_PER_FRIEND
	if boost > Config.FRIEND_BOOST_MAX then
		boost = Config.FRIEND_BOOST_MAX
	end
	local current = PlayerData._players[userId]
	if current then
		current.boost = boost
	end
end

-- Semua data pemain (untuk leaderboard)
function PlayerData.all()
	return PlayerData._players
end

return PlayerData
