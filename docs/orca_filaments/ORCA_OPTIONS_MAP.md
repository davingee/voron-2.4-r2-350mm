# OrcaSlicer Options Map (Voron 2.4r2 350)

Use this as a quick "where is that setting?" guide for OrcaSlicer.

## 1) Process Preset Options (what your screenshot shows)

Path:
1. `Prepare` view
2. Top bar: click the **Process preset** (example: `0.20mm Standard @Voron`)
3. Click edit icon (or open tabs directly)
4. Tabs: `Quality`, `Strength`, `Speed`, `Support`, `Others`

### Quality -> Layer/Width/Seam

| Setting | Starter value |
|---|---|
| Layer height | 0.20 |
| First layer height | 0.25 |
| Default line width | 0.40 |
| First layer line width | 0.50 |
| Outer wall line width | 0.40 |
| Inner wall line width | 0.40 |
| Top surface line width | 0.40 |
| Sparse infill line width | 0.45 |
| Seam position | Aligned or Back |
| Scarf joint seam (beta) | Contour |
| Scarf length | 20 |
| Scarf steps | 10 |

### Strength

| Setting | Starter value |
|---|---|
| Wall loops | 4 |
| Top shell layers | 5 |
| Bottom shell layers | 5 |
| Infill pattern | Gyroid |
| Infill density | 25-40% |

### Speed

| Setting | Starter value (mm/s) |
|---|---|
| Outer wall | 120 |
| Inner wall | 180-200 |
| Sparse infill | 220-250 |
| Internal solid infill | 150-180 |
| Top surface | 80-100 |
| Gap infill | 80-100 |
| Support | 120-150 |
| Support interface | 60-90 |
| Travel | 300 |
| First layer | 25-35 |
| First layer travel | 120-150 |
| Small perimeters | 50% |
| Small perimeters threshold | 15 mm |

### Overhang speed

Keep both enabled:
- `Slow down for overhangs`
- `Slow down for curled perimeters`

Starter values:
- 10% overhang: `80%`
- 25% overhang: `50 mm/s`
- 50% overhang: `30 mm/s`
- 75% overhang: `10-15 mm/s`

## 2) Filament Preset Options (material-specific)

Path:
1. `Prepare` view
2. Right panel: click **Filament preset**
3. Click edit icon
4. Tabs: `Filament`, `Cooling`, `Advanced`

### Filament tab (most-used)

| Setting | What it controls |
|---|---|
| Nozzle temperature | Printing melt temp |
| Bed temperature | Adhesion and warping control |
| Flow ratio | Extrusion multiplier |
| Pressure advance | Corner pressure compensation |

### Cooling tab

| Setting | What it controls |
|---|---|
| Min/Max fan speed | Part cooling strength |
| Disable fan for first N layers | Layer-1 adhesion and warp resistance |
| Slow down for cooling | Keeps small layers from overheating |

### Advanced tab

| Setting | What it controls |
|---|---|
| Retraction distance/speed | Stringing and ooze control |
| Z hop (if used) | Collision avoidance during travel |

## 3) Printer / Machine Options (start/end gcode and limits)

Path:
1. `Prepare` view
2. Top bar: click **Printer preset** (your Voron machine preset)
3. Click edit icon
4. Sections: machine limits, extruder, gcode

### Key machine settings for this Klipper config

| Setting | Value |
|---|---|
| Max print/travel speed | 300 mm/s |
| Max acceleration | 6000 mm/s^2 |
| Start G-code | `PRINT_START BED=[bed_temperature_initial_layer_single] EXTRUDER=[nozzle_temperature_initial_layer]` |
| End G-code | `PRINT_END` |

## 4) Quick PLA/PETG filament baselines

### PLA
- Nozzle: 200-220C
- Bed: 50-60C
- Fan: 100% after first 2-3 layers

### PETG
- Nozzle: 235-250C
- Bed: 70-85C
- Fan: 20-40%

## 5) Shaper-based speed/accel tiers (your printer)

Current measured shaper values:
- X: `mzv @ 49.6`
- Y: `2hump_ei @ 54.8`

Current Klipper cap in `printer.cfg`:
- `max_velocity: 300`
- `max_accel: 6000`

Important:
- Orca process acceleration cannot exceed Klipper `max_accel`.
- With current config, any Orca accel above `6000` will be clipped.

### Tier A: Safe baseline (works now with `max_accel: 6000`)

| Move type | Speed (mm/s) | Accel (mm/s^2) |
|---|---:|---:|
| Outer wall | 120 | 3500-4500 |
| Inner wall | 180-200 | 5000-6000 |
| Sparse infill | 220-250 | 5500-6000 |
| Internal solid infill | 150-180 | 4500-5500 |
| Top surface | 80-100 | 3000-4000 |
| Travel | 300 | 6000 |

### Tier B: Fast daily (requires Klipper `max_accel` around 9000-10000)

| Move type | Speed (mm/s) | Accel (mm/s^2) |
|---|---:|---:|
| Outer wall | 140-160 | 5000-6500 |
| Inner wall | 220-240 | 7000-9000 |
| Sparse infill | 260-300 | 8000-10000 |
| Internal solid infill | 180-220 | 6500-8500 |
| Top surface | 100-120 | 4000-5500 |
| Travel | 300 | 10000-12000 |

### Tier C: Max-test only (quality checks required each step)

| Move type | Speed (mm/s) | Accel (mm/s^2) |
|---|---:|---:|
| Outer wall | 160-180 | 6500-8000 |
| Inner wall | 240-280 | 9000-12000 |
| Sparse infill | 300 | 12000-15000 |
| Internal solid infill | 220-250 | 8500-12000 |
| Top surface | 110-130 | 4500-6500 |
| Travel | 300 | 14000-18000 |

Validation checklist before moving up a tier:
1. Print ringing test and inspect X/Y ghosting.
2. Print top-surface test and check gloss/uniformity.
3. Print a real functional part and check dimensions.
4. If quality drops, reduce outer/top speeds first before lowering infill speeds.

## 6) Save workflow (important)
1. Change settings in the correct preset type (`Process`, `Filament`, or `Printer`).
2. Click **Save as** and name clearly:
- `Voron350-0.20-Structural` (Process)
- `PETG-BrandName-Voron350` (Filament)
- `Voron2.4r2-350-Klipper` (Printer)
3. Avoid changing built-in defaults directly; keep your own named presets.
