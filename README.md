# Voron 2.4r2 350

**Formbot kit** — Manta M8P v2.0 + CB1 · EBB SB2209 CAN (RP2040) · Dragon High Flow hotend · TAP probe · Stealthburner

---

## Access

### Local network

```bash
ssh scott@192.168.7.106 -p81
```

### Remote (DuckDNS)

```bash
ssh scott@dirtbike.duckdns.org -p81
/etc/sysctl.d/99-tailscale.conf
scott@voron:~$ /usr/sbin/iw dev wlan0 get power_save
Power save: off
scott@voron:~$ sudo /usr/sbin/ethtool -k wlan0 | grep -E "rx-udp-gro-forwarding|rx-gro-list"
rx-gro-list: off
ssh scott@192.168.7.85

  243  sudo nano /etc/mediamtx/mediamtx.yml
  244  sudo systemctl start mediamtx
  245  sudo systemctl stop mediamtx
  246  sudo systemctl start mediamtx
  247  sudo systemctl restart mediamtx
  248  sudo journalctl -u mediamtx.service -n 10
  249  sudo journalctl -u mediamtx.service -n 40
  250  sudo nano /etc/mediamtx/mediamtx.yml
  251  sudo systemctl restart mediamtx
  252  sudo journalctl -u mediamtx.service -n 40
  253  sudo systemctl is-enabled mediamtx

```

### Mainsail web UI — local

```
http://192.168.7.106
```

### Mainsail web UI — remote (port forward to local machine)

```bash
ssh -L 8080:localhost:80 scott@dirtbike.duckdns.org -p81
# then open http://localhost:8080
```

### Mainsail + camera — remote (single tunnel)

```bash
sudo ifconfig lo0 alias 192.168.7.85
sudo ssh -L 80:localhost:80 -L 192.168.7.85:8889:192.168.7.85:8889 scott@dirtbike.duckdns.org -p81
```

---

## Config files

| File                | Purpose                                                               |
| ------------------- | --------------------------------------------------------------------- |
| `printer.cfg`       | Full Klipper config — all hardware, macros, limits                    |
| `mainsail.cfg`      | Auto-managed by Mainsail — do not edit                                |
| `KAMP_Settings.cfg` | Adaptive mesh/purge settings (on printer at `~/printer_data/config/`) |

Config lives on the printer at:

```
~/printer_data/config/printer.cfg
```

Push changes from this repo to the printer:

```bash
scp -P81 printer.cfg scott@192.168.7.106:~/printer_data/config/printer.cfg
```

Then do a `FIRMWARE_RESTART` in Mainsail console.

---

## CLI slicing to G-code

Slice from terminal using your saved slicer preset/config:

```bash
chmod +x scripts/slice.sh
scripts/slice.sh --model parts/your_part.stl --config profiles/voron_petg.ini
```

Output is written to:

```bash
gcode/<name>.gcode
```

Then upload in Mainsail:

- `Jobs` -> `Upload` -> choose file from `gcode/`

Full guide:

- `docs/slicing/CLI_SLICING.md`

---

## Key Klipper console commands

| Command                                        | What it does                                       |
| ---------------------------------------------- | -------------------------------------------------- |
| `FIRMWARE_RESTART`                             | Reload config without rebooting                    |
| `RESTART`                                      | Full Klipper restart                               |
| `G28`                                          | Home all axes                                      |
| `G32`                                          | Home + QGL (custom macro)                          |
| `QUAD_GANTRY_LEVEL`                            | Level the gantry                                   |
| `BED_MESH_CALIBRATE`                           | Run adaptive bed mesh                              |
| `PROBE_CALIBRATE`                              | Set z_offset (paper test)                          |
| `Z_OFFSET_APPLY_PROBE`                         | Save live z adjust to config                       |
| `SAVE_CONFIG`                                  | Write calibration to printer.cfg SAVE_CONFIG block |
| `QUERY_PROBE`                                  | Check TAP state (open / triggered)                 |
| `QUERY_FILAMENT_SENSOR SENSOR=filament_sensor` | Check filament sensor state                        |
| `PID_CALIBRATE HEATER=extruder TARGET=240`     | PID tune hotend                                    |
| `PID_CALIBRATE HEATER=heater_bed TARGET=100`   | PID tune bed                                       |
| `SHAPER_CALIBRATE`                             | Run full input shaper calibration                  |
| `MEASURE_AXES_NOISE`                           | Check accelerometer noise floor                    |
| `SET_FAN_SPEED FAN=nevermore SPEED=1.0`        | Nevermore on                                       |
| `SET_FAN_SPEED FAN=exhaust_fan SPEED=1.0`      | Exhaust fan on                                     |

---

## CAN bus

Find CAN UUIDs (run on CB1):

```bash
cd ~/klipper
python3 ./scripts/canbus_query.py can0
```

Check interface is up:

```bash
ip link show can0
```

Current UUIDs:

- M8P MCU: `7cbf8eef4543`
- EBB SB2209: `fa817e71ef41`

---

## Firmware flash (CB1 SD card — Mac)

Find disk number first:

```bash
diskutil list
```

Flash CB1 image:

```bash
diskutil unmountDisk /dev/disk4
sudo dd if=~/Downloads/CB1_Debian12_Klipper_kernel6.6_20241219.img of=/dev/rdisk4 bs=1m status=progress
```

Mount boot partition to edit config:

```bash
sudo mount_msdos /dev/disk4s1 /Volumes/cb1_boot
```

---

## WiFi (on CB1)

Connect to network:

```bash
nmcli dev wifi connect "NetworkName" password "password" ifname wlan0
nmcli connection modify "NetworkName" connection.autoconnect yes
```

---

## Calibrations

Do these in order on first build, and re-run as noted when things change.

---

### 1. Belt tension (X and Y)

Do this **before** anything else — everything downstream depends on it.

**Method — phone app:**

- Download GuitarTuna or a spectrogram app
- With printer homed and steppers energized, pluck each belt like a guitar string near the center
- Target frequency for 350mm Voron with 1.8° motors: **~110 Hz** (close to A2 on guitar)
- Both X and Y should match within a few Hz of each other

**Method — ADXL (more accurate):**

```
TEST_RESONANCES AXIS=X
TEST_RESONANCES AXIS=Y
```

Look at the generated graphs — the belt frequency appears as a low-frequency peak separate from the ringing peak. A well-tensioned belt shows a sharp, narrow ringing peak. A loose belt shows a broad, low peak.

**When to redo:** Every few months, after moving the printer, or if ringing suddenly returns after a previously clean print.

---

### 2. Gantry / Z alignment (QGL)

```
G28
QUAD_GANTRY_LEVEL
```

Should converge in 2–3 iterations. If it takes 8–10 retries consistently → belts loose or mechanical binding somewhere.

After initial build, run QGL 3–4 times in a row and verify it converges to the same position — confirms gantry is mechanically sound.

---

### 3. Z offset (TAP probe calibration)

Run at **full print temp** — thermal expansion of the toolhead affects the result.

```
G28
QUAD_GANTRY_LEVEL
PROBE_CALIBRATE
```

Use the paper test: lower nozzle until paper has slight drag. Then:

```
ACCEPT
SAVE_CONFIG
```

**Fine-tune live during a print:** use the Z offset adjustment in Mainsail. After a good first layer:

```
Z_OFFSET_APPLY_PROBE
SAVE_CONFIG
```

**When to redo:** After every nozzle swap, after a crash, or if first layer adhesion changes suddenly.

---

### 4. PID tuning (hotend + bed)

Run at your target print temp for the filament you use most.

```
PID_CALIBRATE HEATER=extruder TARGET=250
SAVE_CONFIG
```

```
PID_CALIBRATE HEATER=heater_bed TARGET=100
SAVE_CONFIG
```

**When to redo:** After changing the hotend, heater block, thermistor, or silicone bed.

---

### 5. Extruder rotation distance (e-steps)

Calibrate the actual amount of filament extruded vs commanded.

1. Cut filament flush at the top of the extruder, or mark it 100mm above with tape
2. Heat hotend to 200°C, then extrude 100mm slowly:
   ```
   G91
   G1 E100 F100
   ```
3. Measure how much actually moved
4. Calculate:
   ```
   new_rotation_distance = old_rotation_distance × (requested_mm / actual_mm)
   ```
5. Update `rotation_distance` in `printer.cfg` (currently `21.8864`)

**When to redo:** After changing extruder gears, motor, or if under/over-extrusion appears after all other checks pass.

---

### 6. Input shaper / resonance calibration

Heat printer to print temp before running — thermal expansion affects results.

**Run full calibration (both axes):**

```
G28
G1 Z30 F3000
SHAPER_CALIBRATE
SAVE_CONFIG
```

Or test axes individually and view graphs:

```
TEST_RESONANCES AXIS=X
TEST_RESONANCES AXIS=Y
```

Graphs saved to `/tmp/` on CB1 — copy off with `scp` to review.

**Reading results:**

- **MZV** — best quality, lowest vibration, lower accel ceiling (~6300 mm/s² at 51Hz)
- **EI** — higher accel ceiling but less forgiving; Y currently uses EI (suggests slight belt looseness — recheck Y tension if you want MZV)
- **ZV** — allows highest accel (~9000+) but shows ringing immediately if tension drifts

Current results (in `SAVE_CONFIG`):

- X: MZV @ 51 Hz
- Y: EI @ 46 Hz

**When to redo:** After re-tensioning belts, after moving printer, after changing toolhead mass (new hotend/extruder).

---

### 7. Pressure advance (per filament)

PA compensates for extruder/hotend pressure lag at speed changes. Tune per filament type and brand.

**OrcaSlicer built-in (easiest):**

- Open Calibration menu → Pressure Advance
- Print the test pattern, read the value from the best line
- Set in the filament profile

**Manual method:**

```
SET_PRESSURE_ADVANCE ADVANCE=0.04   # start here, adjust up/down
```

Print a PA test square at speed — look for clean corners without bulging or gaps.

Current value: `0.04` (starting point — tune per spool). Set in `printer.cfg` or per-filament in OrcaSlicer.

**When to redo:** Every new filament type, or when corners look bulgy/under-filled.

---

### 8. Flow rate / extrusion multiplier

Corrects for filament diameter variation and hotend differences.

**OrcaSlicer built-in (easiest):**

- Calibration → Flow Rate → print test cube
- Measure single wall thickness with calipers
- `flow_multiplier = expected_width / actual_width`
- Set in filament profile

Typical range: 0.92–1.05. Set per filament profile, not globally.

**When to redo:** New filament brand or type, or if top surfaces look over/under-filled despite correct PA.

---

### 9. Bed mesh

Runs automatically in `PRINT_START` via `BED_MESH_CALIBRATE` (KAMP adaptive). No manual action needed for normal printing.

To run manually and save a mesh:

```
G28
QUAD_GANTRY_LEVEL
BED_MESH_CALIBRATE
SAVE_CONFIG
```

---

### Calibration order summary

| #   | Calibration                                                         | Trigger                                              | Commands                                       | Reference                                                                                                                  |
| --- | ------------------------------------------------------------------- | ---------------------------------------------------- | ---------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| 1   | [Belt tension](#1-belt-tension-x-and-y)                             | Every few months, ringing returns, after move        | GuitarTuna app or `TEST_RESONANCES AXIS=X`     | [Voron docs](https://docs.vorondesign.com/tuning/secondary_printer_tuning.html)                                            |
| 2   | [QGL gantry level](#2-gantry--z-alignment-qgl)                      | Each print (auto in PRINT_START)                     | `G28` → `QUAD_GANTRY_LEVEL`                    | [Klipper docs](https://www.klipper3d.org/Config_Reference.html#quad_gantry_level)                                          |
| 3   | [Z offset](#3-z-offset-tap-probe-calibration)                       | After nozzle swap, after crash                       | `PROBE_CALIBRATE` → paper test → `SAVE_CONFIG` | [Klipper docs](https://www.klipper3d.org/Probe_Calibrate.html)                                                             |
| 4   | [PID tuning](#4-pid-tuning-hotend--bed)                             | After hotend/bed hardware changes                    | `PID_CALIBRATE HEATER=extruder TARGET=250`     | [Klipper docs](https://www.klipper3d.org/Config_checks.html)                                                               |
| 5   | [Extruder rotation distance](#5-extruder-rotation-distance-e-steps) | After extruder swap, persistent over/under-extrusion | `G1 E100 F100` → measure → calc                | [Ellis' guide](https://ellis3dp.com/Print-Tuning-Guide/)                                                                   |
| 6   | [Input shaper](#6-input-shaper--resonance-calibration)              | After belt re-tension, toolhead changes              | `SHAPER_CALIBRATE` → `SAVE_CONFIG`             | [Klipper docs](https://www.klipper3d.org/Resonance_Compensation.html)                                                      |
| 7   | [Pressure advance](#7-pressure-advance-per-filament)                | Per filament type/brand                              | OrcaSlicer PA test or `SET_PRESSURE_ADVANCE`   | [Klipper docs](https://www.klipper3d.org/Pressure_Advance.html) · [Ellis' guide](https://ellis3dp.com/Print-Tuning-Guide/) |
| 8   | [Flow rate](#8-flow-rate--extrusion-multiplier)                     | Per filament brand, if top surfaces look wrong       | OrcaSlicer flow test → calipers                | [Ellis' guide](https://ellis3dp.com/Print-Tuning-Guide/)                                                                   |
| 9   | [Bed mesh](#9-bed-mesh)                                             | Automatic each print (KAMP adaptive)                 | `BED_MESH_CALIBRATE`                           | [Klipper docs](https://www.klipper3d.org/Bed_Mesh.html)                                                                    |

---

## OrcaSlicer — recommended settings for this printer

### Quality tab

| Setting                    | Value                   | Why                                                       |
| -------------------------- | ----------------------- | --------------------------------------------------------- |
| Layer height               | 0.2mm                   | Standard — try 0.15 for detail, 0.25 for speed            |
| First layer height         | 0.25–0.3mm              | Thicker squish improves ASA bed adhesion                  |
| Wall generator             | **Arachne**             | Handles curves and variable widths better than Classic    |
| Wall order                 | **Outer before inner**  | Better dimensional accuracy on external faces             |
| Seam position              | **Aligned** or **Back** | Aligned hides seam in one spot; Back keeps it rear-facing |
| Scarf joint seam           | **Contour**             | Blends seam into wall — nearly eliminates visible blob    |
| Wipe before external loop  | **enabled**             | Purges ooze on inner wall before printing outer surface   |
| Elephant foot compensation | **0.1 mm**              | Corrects first-layer squish spread on ASA                 |

### Strength tab

| Setting             | Value      | Why                                                              |
| ------------------- | ---------- | ---------------------------------------------------------------- |
| Wall loops          | 4          | Good structural strength for functional parts                    |
| Top/bottom layers   | 5          | Solid surface closure                                            |
| Infill pattern      | **Gyroid** | Best strength-to-weight; **Grid** if faster slice times needed   |
| Infill density      | 40%        | General purpose — 20% for visual models, 60%+ for structural     |
| Infill/wall overlap | 25%        | Default is fine; increase slightly if infill detaches from walls |

### Speed tab

| Move type             | Speed        | Notes                                  |
| --------------------- | ------------ | -------------------------------------- |
| Outer wall            | **120 mm/s** | Quality-critical — don't push past 150 |
| Inner wall            | **200 mm/s** |                                        |
| Sparse infill         | **250 mm/s** |                                        |
| Internal solid infill | **200 mm/s** |                                        |
| Top surface           | **100 mm/s** | Slower = better surface finish         |
| Travel                | **300 mm/s** | Match printer max_velocity             |
| First layer           | **35 mm/s**  | Keep slow for ASA adhesion             |
| First layer travel    | **150 mm/s** |                                        |
| Enable overhang speed | **on**       | Auto-slows on steep overhangs          |

> Machine limits in OrcaSlicer should match Klipper: max velocity 300, max accel 6000.

### Other / Miscellaneous

| Setting                   | Value        | Why                                                         |
| ------------------------- | ------------ | ----------------------------------------------------------- |
| Arc fitting (G2/G3)       | **enabled**  | Klipper has `[gcode_arcs]` — smoother curves, smaller files |
| Wipe tower                | **disabled** | Using KAMP LINE_PURGE — wipe tower wastes filament          |
| Avoid crossing perimeters | **enabled**  | Routes travel inside the print — reduces stringing          |
| Reduce infill retraction  | **enabled**  | Fewer retracts on infill = faster, less wear                |

### Start/End G-code (machine settings)

**Start G-code:**

```
PRINT_START BED=[bed_temperature_initial_layer_single] EXTRUDER=[nozzle_temperature_initial_layer]
```

**End G-code:**

```
PRINT_END
```

---

### Filament profiles

#### ASA ⭐ recommended for Voron parts

| Setting               | Value                                           |
| --------------------- | ----------------------------------------------- |
| Print temp            | 240–250°C                                       |
| Bed temp              | 100–110°C                                       |
| Part cooling fan      | 0% first 4 layers, max 30% after                |
| Slow down for cooling | disabled                                        |
| Chamber temp          | 40–50°C minimum (close enclosure during warmup) |
| Pressure advance      | 0.04 starting point — tune per spool            |

- Superior UV stability and higher temp resistance vs ABS — preferred by the Voron community
- Better interlayer adhesion than ABS, less warping than PC
- Nevermore runs during print + 5 min cooldown after — don't open enclosure immediately
- If corners lift: increase bed to 110°C, add brim, slow first layer to 25mm/s

#### ABS / ABS+

| Setting          | Value                    |
| ---------------- | ------------------------ |
| Print temp       | 230–245°C                |
| Bed temp         | 100–110°C                |
| Part cooling fan | 0% — enclosure heat only |
| Chamber temp     | 40°C+                    |

- Glass transition ~90–100°C — functional for most Voron parts
- ABS+ is easier to print and more forgiving than standard ABS
- More prone to warping and layer splitting than ASA — keep enclosure sealed
- If splitting: raise temp 5°C, ensure no drafts

#### Polycarbonate (PC / PC-Blend)

| Setting          | Value                   |
| ---------------- | ----------------------- |
| Print temp       | 260–280°C (check spool) |
| Bed temp         | 110–115°C               |
| Part cooling fan | 0%                      |
| Chamber temp     | 50°C+                   |

- Glass transition 110–130°C — needed for parts near the hotend or motors
- PC-Blend (e.g. PolyMax PC) is much easier to print than pure PC
- Requires all-metal hotend — Dragon High Flow handles it fine
- Very moisture-sensitive — dry spool at 65°C for 6–8h before printing

#### Nylon (PA / PA12)

| Setting          | Value     |
| ---------------- | --------- |
| Print temp       | 240–260°C |
| Bed temp         | 70–85°C   |
| Part cooling fan | 0–20%     |
| Chamber temp     | 40°C+     |

- Low creep under sustained load — good for gears and wear parts
- Extremely hygroscopic — must be dry-printed or it will foam and string badly
- PA12 (e.g. PolyMide PA12-CF) is easier than PA6 and less moisture-sensitive
- Use PVA glue stick or Magigoo PA on bed for adhesion

#### Carbon Fiber Reinforced (CF-ABS / CF-ASA / CF-PA)

| Setting          | Value                          |
| ---------------- | ------------------------------ |
| Print temp       | Same as base material + 5–10°C |
| Bed temp         | Same as base material          |
| Part cooling fan | 0–10%                          |

- Exceptional rigidity and matte finish — popular for gantry and structural parts
- CF particles are abrasive — requires hardened steel nozzle (0.4mm min, 0.6mm preferred)
- Do **not** use brass nozzle — will wear out in hours
- Shorter fibers = less strength gain but easier to print; longer fibers = stiffer but more clogging risk
- Reduce retraction slightly vs base material to avoid clogs

#### TPU (flexible)

| Setting          | Value                           |
| ---------------- | ------------------------------- |
| Print temp       | 220–235°C                       |
| Bed temp         | 30–45°C                         |
| Part cooling fan | 30–50%                          |
| Print speed      | 25–40mm/s max                   |
| Retraction       | 0–0.5mm (minimal — causes jams) |

- Useful for feet, gaskets, cable strain reliefs, and dampeners
- Direct drive (CW2) handles TPU well — reduce speed significantly
- Disable pressure advance for TPU
- Shore hardness 95A is easiest; softer durometers require slower speeds

---

## Useful links

- [Voron 2.4 GitHub](https://github.com/VoronDesign/Voron-2/tree/Voron2.4/Manual)
- [CB1 releases](https://github.com/bigtreetech/CB1/releases)
- [Manta M8P v2.0 firmware README](https://github.com/bigtreetech/Manta-M8P/blob/master/V2.0/Firmware/README.md)
- [KAMP (adaptive purge)](https://github.com/kyleisah/Klipper-Adaptive-Meshing-Purging)

## OrcaSlicer filament profile docs

- `docs/orca_filaments/README.md`
- `docs/orca_filaments/ORCA_OPTIONS_MAP.md`
- `docs/orca_filaments/ASA.md`
- `docs/orca_filaments/ABS_ABS_PLUS.md`
- `docs/orca_filaments/PLA.md`
- `docs/orca_filaments/PETG.md`
- `docs/orca_filaments/PC_PC_BLEND.md`
- `docs/orca_filaments/NYLON_PA.md`
- `docs/orca_filaments/CF_REINFORCED.md`
- `docs/orca_filaments/TPU.md`

---

## Hardware

| Component       | Detail                         |
| --------------- | ------------------------------ |
| Frame           | Voron 2.4r2 Pro+ 350×350×350mm |
| MCU             | BTT Manta M8P v2.0             |
| SBC             | BTT CB1                        |
| Toolhead board  | BTT EBB SB2209 CAN (RP2040)    |
| Hotend          | Dragon High Flow               |
| Extruder        | Clockwork 2 (CW2)              |
| Probe           | Voron TAP                      |
| X/Y motors      | Formbot kit (run_current 1.1A) |
| Z motors        | 4× (run_current 1.0A)          |
| Accelerometer   | ADXL345 on EBBCan              |
| Display         | BTT mini12864                  |
| Filament sensor | Switch sensor on EBBCan:gpio21 |
