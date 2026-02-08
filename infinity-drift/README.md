# Top-Down Drift Game (Godot)

## Game Overview
- **Genre:** Arcade / Endless Drift
- **Perspective:** Top-down (2D)
- **Platform:** Mobile (Android & iOS)
- **Engine:** Godot (2D)
- **Mode:** Single-player

---

## Core Gameplay
- The player controls a car that **accelerates automatically**.
- The **only player input** is steering using a **virtual steering wheel** displayed at the bottom of the screen.
- The car continuously moves forward.
- The objective is to **drive as far as possible** and **survive as long as possible**.

---

## Controls
- Steering wheel rotation controls the car’s direction and drifting behavior.
- No brake or throttle controls.

---

## Driving & Physics
- Arcade-style drifting with smooth and forgiving controls.
- The car naturally slides during turns.
- Tire smoke effects appear while drifting.
- Speed gradually increases over distance unless capped by upgrades.

---

## Obstacles & Hazards
- **Moving obstacles:** Other AI-controlled cars.
- **Static hazards:**
  - Trash / debris
  - Holes / potholes
- Collisions reduce vehicle durability.
- The run ends when durability reaches zero.

---

## Fuel System
- The car consumes fuel over time and based on speed.
- Fuel pickups appear on the road.
- Running out of fuel ends the run.

---

## Upgrade System
- After reaching specific **distance milestones** (every X kilometers), the game pauses.
- An **upgrade selection screen** appears.
- The player chooses **one upgrade** before continuing the run.

### Available Upgrades

#### 1. Speed Upgrade
- Increases maximum speed.
- Slightly increases difficulty due to faster reaction times.

#### 2. Durability Upgrade
- Increases vehicle health.
- Reduces damage taken from collisions.

#### 3. Fuel Tank Upgrade
- Increases maximum fuel capacity.
- Slows fuel consumption over time.

- Upgrades stack.
- Upgrades persist only during the current run (roguelike-style).

---

## Progression & Difficulty
- Road curvature increases over distance.
- Traffic density increases gradually.
- Hazard frequency increases over time.

---

## Scoring & Records
- Track:
  - Distance traveled
  - Survival time
- Save:
  - Best distance ever achieved
  - Longest survival time ever achieved

---

## Visual Style
- Minimalist arcade-style visuals inspired by the reference image.
- Clear visual separation between road, grass, obstacles, and vehicles.
- Simple particle effects for drifting and collisions.

---

## UI / HUD
- Steering wheel fixed at the bottom center of the screen.
- HUD displays:
  - Fuel level
  - Durability
  - Distance traveled
  - Time survived
- Upgrade selection screen uses large, touch-friendly buttons.

---

## Audio
- Engine sound that scales with speed.
- Tire screech sounds during drifting.
- Collision and fuel pickup sound effects.

---

## Goal
Create an addictive, skill-based endless drift game that rewards precision steering, smart upgrade choices, and risk management.

---

## Technical Notes (Godot)
- Use **Godot 4.x**.
- Prefer **Node2D-based architecture**.
- Use **signals** for collisions, fuel pickup, and upgrade selection.
- Use **resources** to define upgrades and balance values.
