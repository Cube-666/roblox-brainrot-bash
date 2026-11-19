# Brainrot Bash

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/Cube-666/roblox-brainrot-bash/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/Cube-666/roblox-brainrot-bash/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

**Brainrot Bash** — game Roblox 3D ala Steal a Brainrot, dibuat sepenuhnya dari Part biasa (tanpa mesh, tanpa asset id, tanpa Roblox Studio). Brainrot jalan di conveyor, pemain membelinya, brainrot itu menghasilkan uang per detik di plot base ("Rumah") milik pemain. Pecahkan telur untuk menetaskan brainrot acak, curi brainrot dari base pemain lain dengan Palu, dan kejar posisi teratas di leaderboard.

## Cara main

1. **Beli brainrot** — dekati brainrot yang jalan di conveyor, tekan **E** (ProximityPrompt) kalau uangmu cukup. Brainrot berjalan sendiri ke plot kamu.
2. **Hasilkan uang** — setiap brainrot di plot kamu menghasilkan **$/detik** otomatis. Makin langka brainrot-nya, makin besar hasilnya.
3. **Pecahkan telur** — di area **Pecahkan Telur!** ada 3 telur (Biasa $250, Langka $1.000, Mistis $5.000). Beli telur, brainrot acak menetas dan jalan ke plot kamu.
4. **Curi brainrot** — pakai **Palu** (klik) di dekat brainrot milik pemain lain untuk mencurinya ke plot kamu. Ada cooldown 5 detik dan brainrot yang baru dicuri tidak bisa dicuri lagi selama 10 detik.
5. **Pukul dengan Tongkat** — klik Tongkat di dekat brainrot mana pun untuk membuatnya pusing 5 detik (tidak menghasilkan uang selama pusing).
6. **Peningkatan Teman** — setiap teman yang main di server yang sama menambah +10% penghasilan (maks +50%).

Semua uang dan kepemilikan dihitung di **server** (authoritative); client hanya menampilkan UI.

## Brainrot (8 karakter, semua dari Part)

| Brainrot | Rarity | Harga | $/detik |
|---|---|---|---|
| Hiu Bajak Laut | Biasa | $100 | $12 |
| Tomat Merah | Biasa | $150 | $15 |
| Kaktus Spinoso | Langka | $300 | $30 |
| Cacing Tomat | Langka | $400 | $42 |
| Gajah Flores | Epik | $750 | $80 |
| Traktor Bulbito | Epik | $2.000 | $200 |
| Kapten Pirat | Mistis | $5.000 | $500 |
| Kucing Samurai | Mistis | $10.000 | $1.000 |

## Struktur proyek (Rojo 7.7.1)

```
default.project.json   # manifest Rojo
src/
  shared/
    Config.lua          # data brainrot, telur, konstanta, format uang
    BrainrotFactory.lua # bangun model brainrot dari Part + BillboardGui
  server/
    Main.server.lua     # boot: remote, map, sistem, pemain
    MapBuilder.lua      # bangun map dari Part: 6 plot, conveyor, area telur
    PlayerData.lua      # uang & kepemilikan pemain (server-side)
    BrainrotSystem.lua  # spawn conveyor, beli, jalan, income
    EggSystem.lua       # beli & tetaskan telur
    StealSystem.lua     # tool Palu & Tongkat, curi & pukul
    Leaderboard.lua     # papan top 5 uang
  client/
    Main.client.lua     # UI: uang, $/detik, boost teman, pesan
```

## Build

```sh
rojo build -o game.rbxl
```

Lalu publish `game.rbxl` sebagai Public experience dari Roblox Studio / Creator Dashboard (akun harus berumur 2 hari atau lebih dan lolos age check). Game tidak memakai DataStore, mesh, atau asset id apa pun — semua dari Part.

## Lisensi

MIT — lihat `LICENSE`.

---

<sub>Entered on [make.fun](https://make.fun/?ref=k11s2hyb&utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>
