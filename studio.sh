#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"
IN="$ROOT/inputs"
OUT="$ROOT/outputs"
ENVS="$ROOT/.envs"
eval "$("$(command -v brew || echo /opt/homebrew/bin/brew)" shellenv)"

clone() {
  "$ENVS/voice/bin/f5-tts_infer-cli" \
    --ref_audio "$IN/voice.wav" \
    --ref_text "$(cat "$IN/voice.txt" 2>/dev/null)" \
    --gen_file "$IN/script.txt" \
    --output_dir "$IN" \
    --output_file speech.wav
}

record() {
  ffmpeg -y -i "$1" -ar 16000 -ac 1 "$IN/speech.wav"
}

video() {
  cd "$ROOT/engines/SadTalker"
  "$ENVS/avatar/bin/python" inference.py \
    --driven_audio "$IN/speech.wav" \
    --source_image "$IN/avatar.jpg" \
    --result_dir "$OUT" \
    --size 512 \
    --preprocess full \
    --still \
    --expression_scale 1.3 \
    --enhancer gfpgan
}

case "$1" in
  clone) clone ;;
  record) record "$2" ;;
  video) video ;;
  make) clone && video ;;
  *) printf 'Usage: ./studio.sh <command>\n\n  clone          Speak inputs/script.txt in the voice from inputs/voice.wav\n  record <file>  Use your own recording as the speech track\n  video          Render inputs/avatar.jpg speaking inputs/speech.wav\n  make           Run clone, then video\n' ;;
esac
