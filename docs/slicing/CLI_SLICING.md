# CLI Slicing to G-code

This repo includes a wrapper script:
- `scripts/slice.sh`

It slices a model with `prusa-slicer` or `superslicer` and writes output to `gcode/`.

## Requirements

Install one CLI slicer:
- `prusa-slicer`
- or `superslicer`

## Export a Config Preset File

From your slicer UI, export the combined preset/config as an `.ini` file that contains your printer/process/filament settings.

Save it in this repo, for example:
- `profiles/voron_pla.ini`
- `profiles/voron_petg.ini`

## Slice a Model

```bash
chmod +x scripts/slice.sh
scripts/slice.sh --model parts/your_part.stl --config profiles/voron_petg.ini
```

Optional output name:

```bash
scripts/slice.sh --model parts/your_part.stl --config profiles/voron_petg.ini --out your_part_petg_v1.gcode
```

Optional slicer binary:

```bash
scripts/slice.sh --model parts/your_part.stl --config profiles/voron_petg.ini --slicer prusa-slicer
```

## Output

Generated file goes to:
- `gcode/<name>.gcode`

Then upload in Mainsail:
1. `Jobs`
2. `Upload`
3. Select the `.gcode` file from `gcode/`
