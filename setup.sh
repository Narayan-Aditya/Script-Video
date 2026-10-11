#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"
ENVS="$ROOT/.envs"
SADTALKER="$ROOT/engines/SadTalker"

command -v brew >/dev/null || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
BREW="$(command -v brew || echo /opt/homebrew/bin/brew)"
eval "$("$BREW" shellenv)"
grep -q "brew shellenv" ~/.zprofile 2>/dev/null || echo "eval \"\$($BREW shellenv)\"" >> ~/.zprofile
brew install ffmpeg git git-lfs wget
command -v conda >/dev/null || brew install --cask miniforge

[ -d "$ENVS/voice" ] || conda create -y -p "$ENVS/voice" python=3.11
"$ENVS/voice/bin/pip" install f5-tts

[ -d "$SADTALKER" ] || git clone --depth 1 https://github.com/OpenTalker/SadTalker.git "$SADTALKER"
[ -d "$ENVS/avatar" ] || conda create -y -p "$ENVS/avatar" python=3.10
"$ENVS/avatar/bin/pip" install "setuptools<81" torch==2.0.1 torchvision==0.15.2 torchaudio==2.0.2
"$ENVS/avatar/bin/pip" install --no-build-isolation basicsr==1.4.2
"$ENVS/avatar/bin/pip" install -r <(grep -v gradio "$SADTALKER/requirements.txt") opencv-python==4.10.0.84 ffmpeg-python
[ -d "$SADTALKER/checkpoints" ] || (cd "$SADTALKER" && bash scripts/download_models.sh)

mkdir -p "$ROOT/inputs" "$ROOT/outputs"
chmod +x "$ROOT/studio.sh"
printf 'Setup complete. Run ./studio.sh to see the available commands.\n'
