# Tile Match Puzzle

**English** | [中文](README.zh-CN.md)

A layered tile-matching puzzle game built from scratch with **Godot 4 / GDScript**. Tap tiles stacked in overlapping layers, collect three of a kind to clear them, and empty the board before time runs out.

> A self-directed journey into game development — covering gameplay design, difficulty balancing, UI/UX, and persistence systems.

<!-- Screenshot placeholder -->
<!-- ![Gameplay](screenshots/gameplay.png) -->
<!-- Recommended: one gameplay screenshot + one GIF of the match effect -->

## ✨ Features

### Gameplay
- **Layered matching mechanic**: tiles stack in offset, overlapping layers — only uncovered tiles are clickable, so you must plan your digging order
- **Collection-slot matching**: picked tiles go into a 7-slot tray; three of a kind auto-clears, and a full tray means game over
- **Two game modes**:
  - 🗺 **Campaign** — 18 handcrafted levels, including themed layouts (heart, diamond, cross)
  - ♾ **Endless** — procedurally generated waves with scaling difficulty; chase your best record

### Systems
- ⏱ **Time-attack levels**: per-level countdown with a red warning in the final 10 seconds
- ⭐ **Star ratings**: 1–3 stars based on clear time; replay any level to improve
- 🏆 **Rank system**: score accumulates across sessions, climbing 7 tiers from Bronze to King
- 🔥 **Combo multiplier**: rapid consecutive matches stack up to ×3 score
- 🎒 **Power-ups**: 3 uses per level — extra tray slot / +5 seconds / shuffle board
- 💾 **Local save**: level progress, stars, rank, and endless records all persist
- ⏸ **Pause menu**: pause, retry, or return home at any time

### Feel & Feedback
- Particle bursts + floating score popups on every match
- Enhanced visual feedback on combos
- Springy Tween animations for tile spawn and merge
- Full screen flow: title screen → level select → gameplay

## 🛠 Technical Highlights

| Area | Implementation |
|------|----------------|
| Engine | Godot 4.x / GDScript |
| Level system | **JSON data-driven**: layouts, time limits, and star thresholds are fully externalized — adding levels requires zero code changes |
| Architecture | Signal-based decoupling: gameplay, UI, and persistence communicate only through signals |
| Persistence | Autoload singleton + JSON serialization to `user://` |
| Procedural generation | Endless mode generates layouts per wave, guaranteeing solvability (tile count always divisible by 3) |
| Occlusion | Real-time cover detection based on layer index + positional overlap |
| VFX | Particles and floating text spawned purely in code via static utility classes |

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
├── levels.json          # Level config (layouts / time limits / star thresholds)
├── scenes/              # Scene files
│   ├── Main.tscn        # Main scene (gameplay + UI + menus)
│   └── Item.tscn        # Tile prefab
├── scripts/
│   ├── GridManager.gd   # Core gameplay: generation / occlusion / matching / power-ups
│   ├── UI.gd            # Screen flow and HUD
│   ├── SaveManager.gd   # Save singleton
│   ├── LevelSelect.gd   # Level select screen
│   ├── TitleScreen.gd   # Title screen
│   ├── Item.gd          # Tile behavior
│   ├── FloatingText.gd  # Floating score VFX
│   └── BurstParticle.gd # Particle burst VFX
└── resources/           # Art assets (free assets from Kenney)
```

## 🗺 Roadmap

- [x] Core matching gameplay with occlusion mechanics
- [x] Campaign / Endless dual modes
- [x] Timer + stars + ranks + combos
- [x] Power-up system and pause menu
- [x] Match VFX (particles + floating score)
- [ ] Sound effects and background music
- [ ] Unified visual theme
- [ ] Special tiles (frozen / bomb)
- [ ] Web export and itch.io release

## 📄 Asset Credits

Game art assets from [Kenney.nl](https://kenney.nl) (CC0 license).

---

*Built as a self-directed learning project exploring game development with Godot 4.*
