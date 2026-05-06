#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/slice.sh --model <path/to/model.stl|3mf> --config <path/to/slicer_config.ini> [--out <name.gcode>] [--slicer <binary>]

Examples:
  scripts/slice.sh --model parts/clip.stl --config profiles/voron_petg.ini
  scripts/slice.sh --model parts/clip.stl --config profiles/voron_petg.ini --out clip_petg_v1.gcode
  scripts/slice.sh --model parts/clip.stl --config profiles/voron_petg.ini --slicer prusa-slicer
EOF
}

die() {
  echo "Error: $*" >&2
  exit 1
}

model=""
config=""
out_name=""
slicer=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --model)
      [[ $# -ge 2 ]] || die "--model requires a value"
      model="$2"
      shift 2
      ;;
    --config)
      [[ $# -ge 2 ]] || die "--config requires a value"
      config="$2"
      shift 2
      ;;
    --out)
      [[ $# -ge 2 ]] || die "--out requires a value"
      out_name="$2"
      shift 2
      ;;
    --slicer)
      [[ $# -ge 2 ]] || die "--slicer requires a value"
      slicer="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unknown argument: $1 (use --help)"
      ;;
  esac
done

[[ -n "$model" ]] || die "Missing --model"
[[ -n "$config" ]] || die "Missing --config"
[[ -f "$model" ]] || die "Model file not found: $model"
[[ -f "$config" ]] || die "Config file not found: $config"

if [[ -z "$slicer" ]]; then
  if command -v prusa-slicer >/dev/null 2>&1; then
    slicer="prusa-slicer"
  elif command -v superslicer >/dev/null 2>&1; then
    slicer="superslicer"
  else
    die "No slicer binary found. Install PrusaSlicer CLI or SuperSlicer CLI, or pass --slicer <binary>."
  fi
fi

command -v "$slicer" >/dev/null 2>&1 || die "Slicer binary not found in PATH: $slicer"

mkdir -p gcode

if [[ -z "$out_name" ]]; then
  base="$(basename "$model")"
  base="${base%.*}"
  stamp="$(date +%Y%m%d_%H%M%S)"
  out_name="${base}_${stamp}.gcode"
fi

[[ "$out_name" == *.gcode ]] || out_name="${out_name}.gcode"
out_path="gcode/${out_name}"

echo "Slicer: $slicer"
echo "Model:  $model"
echo "Config: $config"
echo "Output: $out_path"

"$slicer" \
  --load "$config" \
  --export-gcode "$model" \
  --output "$out_path"

echo
echo "Done: $out_path"
echo "Upload in Mainsail: Jobs -> Upload -> select $out_path"
