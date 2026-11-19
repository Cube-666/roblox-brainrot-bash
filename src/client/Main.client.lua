-- Main.client.lua
-- UI Brainrot Bash: uang, $/detik, boost teman, petunjuk, pesan toast.
-- Client HANYA menampilkan; semua angka datang dari server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local updateMoney = remotes:WaitForChild("UpdateMoney")
local showMessage = remotes:WaitForChild("ShowMessage")

-- ------------------------------------------------------------ ScreenGui
local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotBashUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local function makeLabel(name, text, size, pos, textSize, color)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Size = size
	l.Position = pos
	l.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	l.BackgroundTransparency = 0.45
	l.BorderSizePixel = 0
	l.Font = Enum.Font.GothamBold
	l.TextSize = textSize
	l.TextColor3 = color
	l.TextStrokeTransparency = 0.4
	l.Text = text
	l.Parent = gui
	return l
end

-- Uang (kiri bawah, seperti screenshot referensi)
local moneyLabel = makeLabel("Uang", "$100", UDim2.new(0, 190, 0, 52),
	UDim2.new(0, 16, 1, -118), 30, Color3.fromRGB(120, 255, 120))
local incomeLabel = makeLabel("Pemasukan", "$0/dtk", UDim2.new(0, 190, 0, 30),
	UDim2.new(0, 16, 1, -62), 18, Color3.fromRGB(255, 235, 150))
local boostLabel = makeLabel("Boost", "Peningkatan Teman: +0%", UDim2.new(0, 260, 0, 30),
	UDim2.new(0, 16, 1, -28), 16, Color3.fromRGB(255, 255, 255))

-- Info plot (kiri atas)
local plotLabel = makeLabel("Plot", "Rumah: -", UDim2.new(0, 220, 0, 34),
	UDim2.new(0, 16, 0, 16), 18, Color3.fromRGB(255, 255, 255))

-- Petunjuk (tengah bawah)
local hintLabel = makeLabel("Petunjuk",
	"Dekati brainrot lalu tekan E untuk membeli  •  Pecahkan telur di area telur  •  Palu = curi, Tongkat = pukul",
	UDim2.new(0, 640, 0, 30), UDim2.new(0.5, -320, 1, -40), 15, Color3.fromRGB(255, 255, 255))

-- Toast pesan (tengah atas)
local toastLabel = makeLabel("Toast", "", UDim2.new(0, 520, 0, 44),
	UDim2.new(0.5, -260, 0, 70), 19, Color3.fromRGB(255, 255, 255))
toastLabel.Visible = false

local toastUntil = 0

-- ------------------------------------------------------------ Event server

updateMoney.OnClientEvent:Connect(function(money, income, boostPercent, plotIndex)
	moneyLabel.Text = "$" .. tostring(math.floor(money + 0.5))
	-- Format ribuan dengan titik
	local n = math.floor(money + 0.5)
	local s = tostring(n)
	local out = ""
	while #s > 3 do
		out = "." .. string.sub(s, -3) .. out
		s = string.sub(s, 1, -4)
	end
	moneyLabel.Text = "$" .. s .. out
	incomeLabel.Text = "$" .. tostring(math.floor(income + 0.5)) .. "/dtk"
	boostLabel.Text = "Peningkatan Teman: +" .. tostring(boostPercent) .. "%"
	if plotIndex and plotIndex > 0 then
		plotLabel.Text = "Rumah: Plot " .. tostring(plotIndex)
	else
		plotLabel.Text = "Rumah: - (penonton)"
	end
end)

showMessage.OnClientEvent:Connect(function(text)
	toastLabel.Text = text
	toastLabel.Visible = true
	toastUntil = os.clock() + 3
end)

-- Sembunyikan toast setelah 3 detik
task.spawn(function()
	while true do
		task.wait(0.25)
		if toastLabel.Visible and os.clock() > toastUntil then
			toastLabel.Visible = false
		end
	end
end)
