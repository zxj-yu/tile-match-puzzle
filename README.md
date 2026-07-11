# Tile Match Puzzle

**English** | [中文](README.zh-CN.md)

A layered tile-matching puzzle game built from scratch with **Godot 4 / GDScript**. Dig through deeply stacked, interlocking layers of hidden tiles, collect three of a kind to clear them, and empty the board before time runs out.

> A self-directed journey into game development — covering gameplay design, difficulty balancing, UI/UX, audio, and persistence systems.

<!-- Screenshot placeholder -->
<!-- ![Gameplay](screenshots/gameplay.png) -->
<!-- Recommended: one gameplay screenshot + one GIF of the match effect -->

## ✨ Features

### Gameplay
- **Hidden-information digging**: covered tiles show only a card back — you never know what's underneath until you uncover it. Memory, deduction, and calculated risk are core skills
- **Deep interlocking stacks**: 3–5 offset layers per level; removing one tile reveals only fragments of what lies below
- **Special tiles**:
  - ❄️ **Frozen** — takes two clicks: first to thaw, second to collect
  - 🪨 **Stone** — can never be collected; permanently blocks whatever it covers
- **Shaped levels**: every level has a distinct silhouette — pyramid, twin towers, diamond, cross, hollow ring, butterfly — each demanding a different digging strategy
- **Two game modes**:
  - 🗺 **Campaign** — 15 handcrafted levels with escalating mechanics (basics → frozen → stone → mixed → high pressure)
  - ♾ **Endless** — procedurally generated waves with scaling difficulty

### Systems
- ⏱ **Time-attack levels** with a red warning in the final 10 seconds
- ⭐ **Star ratings** (1–3) based on clear time; replay to improve
- 🏆 **Rank system**: score accumulates across sessions, from Bronze to King (7 tiers)
- 🔥 **Combo multiplier**: rapid consecutive matches stack up to ×3 score
- 🎒 **Power-ups** (3 uses each per level): extra tray slot / +5 seconds / shuffle board
- 📉 **Tightening tray**: collection slots shrink from 7 → 6 → 5 as levels progress
- 💾 **Local save**: progress, stars, rank, and endless records persist
- ⏸ **Pause menu**: pause, retry, or return home at any time

### Presentation
- 18 distinct tile types, introduced progressively across the campaign
- Card-back art for hidden tiles with flip-reveal animations
- Particle bursts + floating score popups on every match
- Candy-style "puffy" buttons with press-down feedback
- Full SFX set (click / match / combo / skill / win / lose) + looping BGM
- Complete screen flow: title → level select (with star records) → gameplay

## 🛠 Technical Highlights

| Area | Implementation |
|------|----------------|
| Engine | Godot 4.x / GDScript |
| Level system | **JSON data-driven**: layouts (with special-tile encoding `X/I/S`), time limits, tray sizes, and star thresholds fully externalized |
| Architecture | Signal-based decoupling: gameplay, UI, audio, and persistence communicate only through signals |
| Persistence | Autoload singleton + JSON serialization to `user://` |
| Audio | Pooled SFX players + looping BGM via an autoload SoundManager |
| Procedural generation | Endless mode generates layouts per wave, guaranteeing solvability (tile count always divisible by 3) |
| Occlusion | Real-time cover detection with layer offsets producing interlocking overlap |
| VFX / UI | Particles, floating text, and reusable candy-button styling generated purely in code |

## 🎮 How to Run

1. Download and install [Godot 4.x](https://godotengine.org/download)
2. Clone this repository:
   ```bash
   git clone https://github.com/zxj-yu/tile-match-puzzle.git
   ```
3. Open the project folder in Godot (select `project.godot`)
4. Press `F5` to run

## 📁 Project Structure

```
├── levels.json          # Level config (shaped layouts / special tiles / timing / tray size)
├── scenes/
│   ├── Main.tscn        # Main scene (gameplay + UI + menus)
│   └── Item.tscn        # Tile prefab
├── scripts/
│   ├── GridManager.gd   # Core gameplay: generation / occlusion / matching / power-ups
│   ├── UI.gd            # Screen flow, HUD, and layout styling
│   ├── SaveManager.gd   # Save singleton
│   ├── SoundManager.gd  # Audio singleton (SFX pool + BGM)
│   ├── LevelSelect.gd   # Level select screen
│   ├── TitleScreen.gd   # Title screen
│   ├── Item.gd          # Tile behavior (normal / frozen / stone, card-back)
│   ├── ButtonStyler.gd  # Reusable candy-button styling
│   ├── FloatingText.gd  # Floating score VFX
│   └── BurstParticle.gd # Particle burst VFX
└── resources/           # Art & audio assets
```

## 🗺 Roadmap

- [x] Core matching gameplay with occlusion mechanics
- [x] Hidden-information card backs
- [x] Special tiles (frozen / stone) with mechanic-paced level design
- [x] Shaped level silhouettes (pyramid / towers / diamond / cross / ...)
- [x] Campaign / Endless dual modes
- [x] Timer + stars + ranks + combos + power-ups
- [x] Sound effects and background music
- [x] Candy-style UI buttons
- [ ] Unified visual theme pass
- [ ] More special tiles (bomb / chained)
- [ ] Web export and itch.io release

## 📄 Asset Credits

- Game art assets from [Kenney.nl](https://kenney.nl) (CC0 license)
- Music: **"Holiday Weasel"** by Kevin MacLeod ([incompetech.com](https://incompetech.com))
  Licensed under [Creative Commons: By Attribution 4.0](https://creativecommons.org/licenses/by/4.0/)

---

*Built as a self-directed learning project exploring game development with Godot 4.*
