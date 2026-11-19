-- Config.lua
-- Semua data & konstanta Brainrot Bash. Modul murni (tidak butuh service),
-- dipakai server dan client. Ditulis dalam gaya Lua 5.1 agar mudah dicek.

local Config = {}

-- Uang awal pemain baru
Config.START_MONEY = 100

-- Plot (base "Rumah") dan slot brainrot per plot
Config.PLOT_COUNT = 6
Config.PLOT_SLOTS = 5

-- Conveyor
Config.CONVEYOR_SPAWN_INTERVAL = 6 -- detik antar spawn
Config.CONVEYOR_MAX_ON_BELT = 8
Config.CONVEYOR_SPEED = 4 -- stud/detik
Config.WALK_SPEED = 6 -- jalan ke plot
Config.STEAL_WALK_SPEED = 9 -- jalan saat dicuri (lebih cepat, dramatis)

-- Curi & pukul
Config.STEAL_RANGE = 12
Config.STEAL_COOLDOWN = 5 -- detik per pemain
Config.STOLEN_LOCK = 10 -- detik brainrot tidak bisa dicuri lagi
Config.SLAP_RANGE = 10
Config.SLAP_COOLDOWN = 2
Config.STUN_DURATION = 5 -- detik brainrot pusing (tidak hasilkan uang)

-- Boost teman: +10% per teman di server yang sama, maks +50%
Config.FRIEND_BOOST_PER_FRIEND = 0.10
Config.FRIEND_BOOST_MAX = 0.50

-- Tinggi pivot model brainrot di atas permukaan (semua model dibangun
-- dengan titik tengah badan di y = 2.2 lokal)
Config.BRAINROT_PIVOT_HEIGHT = 2.2

-- Definisi brainrot. build = varian bentuk di BrainrotFactory.
-- weight = bobot spawn di conveyor (total 100).
Config.BRAINROTS = {
	{
		id = "hiu",
		name = "Hiu Bajak Laut",
		rarity = "Biasa",
		price = 100,
		income = 12,
		weight = 26,
		build = "shark",
		bodyColor = Color3.fromRGB(52, 152, 219),
		bellyColor = Color3.fromRGB(235, 245, 251),
	},
	{
		id = "tomat",
		name = "Tomat Merah",
		rarity = "Biasa",
		price = 150,
		income = 15,
		weight = 24,
		build = "tomato",
		bodyColor = Color3.fromRGB(231, 76, 60),
		bellyColor = Color3.fromRGB(46, 204, 113),
	},
	{
		id = "kaktus",
		name = "Kaktus Spinoso",
		rarity = "Langka",
		price = 300,
		income = 30,
		weight = 16,
		build = "cactus",
		bodyColor = Color3.fromRGB(39, 174, 96),
		bellyColor = Color3.fromRGB(88, 214, 141),
	},
	{
		id = "cacing",
		name = "Cacing Tomat",
		rarity = "Langka",
		price = 400,
		income = 42,
		weight = 12,
		build = "worm",
		bodyColor = Color3.fromRGB(230, 126, 34),
		bellyColor = Color3.fromRGB(245, 176, 65),
	},
	{
		id = "gajah",
		name = "Gajah Flores",
		rarity = "Epik",
		price = 750,
		income = 80,
		weight = 10,
		build = "elephant",
		bodyColor = Color3.fromRGB(149, 165, 166),
		bellyColor = Color3.fromRGB(253, 121, 168),
	},
	{
		id = "traktor",
		name = "Traktor Bulbito",
		rarity = "Epik",
		price = 2000,
		income = 200,
		weight = 6,
		build = "tractor",
		bodyColor = Color3.fromRGB(241, 196, 15),
		bellyColor = Color3.fromRGB(52, 73, 94),
	},
	{
		id = "kapten",
		name = "Kapten Pirat",
		rarity = "Mistis",
		price = 5000,
		income = 500,
		weight = 4,
		build = "pirate",
		bodyColor = Color3.fromRGB(44, 62, 80),
		bellyColor = Color3.fromRGB(212, 172, 13),
	},
	{
		id = "kucing",
		name = "Kucing Samurai",
		rarity = "Mistis",
		price = 10000,
		income = 1000,
		weight = 2,
		build = "cat",
		bodyColor = Color3.fromRGB(212, 172, 13),
		bellyColor = Color3.fromRGB(192, 57, 43),
	},
}

-- Warna label rarity (dipakai BillboardGui)
Config.RARITY_COLORS = {
	Biasa = Color3.fromRGB(220, 220, 220),
	Langka = Color3.fromRGB(46, 204, 113),
	Epik = Color3.fromRGB(155, 89, 182),
	Mistis = Color3.fromRGB(241, 196, 15),
}

-- Telur: pool berisi id brainrot + bobot penetasan.
Config.EGGS = {
	{
		tier = 1,
		name = "Telur Biasa",
		price = 250,
		color = Color3.fromRGB(236, 240, 241),
		pool = {
			{ id = "hiu", weight = 40 },
			{ id = "tomat", weight = 35 },
			{ id = "kaktus", weight = 15 },
			{ id = "cacing", weight = 10 },
		},
	},
	{
		tier = 2,
		name = "Telur Langka",
		price = 1000,
		color = Color3.fromRGB(46, 204, 113),
		pool = {
			{ id = "kaktus", weight = 35 },
			{ id = "cacing", weight = 30 },
			{ id = "gajah", weight = 20 },
			{ id = "traktor", weight = 10 },
			{ id = "kapten", weight = 5 },
		},
	},
	{
		tier = 3,
		name = "Telur Mistis",
		price = 5000,
		color = Color3.fromRGB(155, 89, 182),
		pool = {
			{ id = "gajah", weight = 30 },
			{ id = "traktor", weight = 30 },
			{ id = "kapten", weight = 25 },
			{ id = "kucing", weight = 15 },
		},
	},
}

-- Cari definisi brainrot dari id
function Config.getBrainrot(id)
	for _, def in ipairs(Config.BRAINROTS) do
		if def.id == id then
			return def
		end
	end
	return nil
end

-- Pilih satu entri berbobot dari sebuah list { {weight=...}, ... }
function Config.pickWeighted(list)
	local total = 0
	for _, entry in ipairs(list) do
		total = total + entry.weight
	end
	local roll = math.random(1, total)
	local acc = 0
	for _, entry in ipairs(list) do
		acc = acc + entry.weight
		if roll <= acc then
			return entry
		end
	end
	return list[1]
end

-- Pilih brainrot acak untuk spawn conveyor (pakai weight tiap definisi)
function Config.pickSpawnBrainrot()
	local entry = Config.pickWeighted(Config.BRAINROTS)
	return entry
end

-- Pilih brainrot acak dari pool telur
function Config.pickEggBrainrot(tier)
	local egg = Config.EGGS[tier]
	if not egg then
		return nil
	end
	local entry = Config.pickWeighted(egg.pool)
	return Config.getBrainrot(entry.id)
end

-- Format uang gaya Indonesia: $1.234, $1,23 jt, $1,23 M, $1,23 T
function Config.formatMoney(n)
	n = math.floor(n + 0.5)
	if n < 0 then
		n = 0
	end
	local suffix = ""
	local value = n
	if n >= 1000000000000 then
		value = n / 1000000000000
		suffix = " T"
	elseif n >= 1000000000 then
		value = n / 1000000000
		suffix = " M"
	elseif n >= 1000000 then
		value = n / 1000000
		suffix = " jt"
	end
	if suffix ~= "" then
		local whole = math.floor(value)
		local frac = math.floor((value - whole) * 100 + 0.5)
		if frac >= 100 then
			whole = whole + 1
			frac = 0
		end
		return "$" .. tostring(whole) .. "," .. string.format("%02d", frac) .. suffix
	end
	-- Ribuan dengan pemisah titik: 1.234.567
	local s = tostring(n)
	local out = ""
	while #s > 3 do
		out = "." .. string.sub(s, -3) .. out
		s = string.sub(s, 1, -4)
	end
	out = s .. out
	return "$" .. out
end

return Config
