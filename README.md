# Script Video

Script Video turns a photo and a script into a talking-head video on an Apple Silicon Mac. Everything runs locally: no account, API key, or internet connection is needed after setup.

The speech track comes from one of two sources:

- **Cloned voice.** [F5-TTS](https://github.com/SWivid/F5-TTS) reads your script aloud in the voice from a short sample recording.
- **Your own recording.** You record the script yourself and the project converts it.

[SadTalker](https://github.com/OpenTalker/SadTalker) then animates your photo so that its lips follow the speech track, and [GFPGAN](https://github.com/TencentARC/GFPGAN) sharpens the face in the final video.

## Requirements

- A Mac with an Apple Silicon chip (M1 or later). Intel Macs are untested, and PyTorch stopped publishing Intel Mac builds after version 2.2, so setup may fail on them.
- An internet connection for the one-time setup.

The setup script installs everything else.

## Install

Open Terminal in this folder and run:

```bash
bash setup.sh
```

The script performs these steps:

1. Installs [Homebrew](https://brew.sh) if it is missing, and adds it to your `PATH` in `~/.zprofile`. The Homebrew installer asks for your password.
2. Installs `ffmpeg`, `git`, `git-lfs`, and `wget` with Homebrew.
3. Installs [Miniforge](https://github.com/conda-forge/miniforge) if `conda` is missing.
4. Creates two Python environments inside `.envs/`: `voice` (Python 3.11) for F5-TTS and `avatar` (Python 3.10) for SadTalker. Keeping them apart prevents their dependencies from conflicting.
5. Downloads SadTalker into `engines/` together with its model checkpoints.
6. Creates the `inputs/` and `outputs/` folders.

Running `setup.sh` again is safe; it skips the environments and downloads that already exist. F5-TTS downloads its own model the first time you run `clone`.

## Prepare the inputs

Place your files in `inputs/` with these exact names:

| File | Used by | Contents |
|---|---|---|
| `avatar.jpg` | `video` | A well-lit, front-facing photo of one person |
| `voice.wav` | `clone` | A clean 10 to 15 second recording of the voice to clone |
| `voice.txt` | `clone` | The exact words spoken in `voice.wav` (optional) |
| `script.txt` | `clone` | The text the cloned voice should speak |

When `voice.txt` is missing, F5-TTS transcribes `voice.wav` automatically. Writing the transcript yourself gives more accurate cloning.

To turn a recording in another format into `voice.wav`, run:

```bash
ffmpeg -i ~/Downloads/sample.m4a inputs/voice.wav
```

## Usage

Run `./studio.sh` with one of these commands:

| Command | Reads | Writes |
|---|---|---|
| `./studio.sh clone` | `voice.wav`, `voice.txt`, `script.txt` | `inputs/speech.wav` |
| `./studio.sh record <file>` | Any audio file you recorded | `inputs/speech.wav` |
| `./studio.sh video` | `avatar.jpg`, `speech.wav` | A timestamped `.mp4` in `outputs/` |
| `./studio.sh make` | Everything `clone` and `video` read | Both of the above |

To create a video in a cloned voice:

```bash
./studio.sh make
```

To create a video from your own recording:

```bash
./studio.sh record ~/Downloads/my_recording.m4a
./studio.sh video
```

## Video settings

`studio.sh` passes these options to SadTalker in its `video` function:

| Option | Effect | Change it to |
|---|---|---|
| `--size 512` | Uses the 512 pixel face model for a sharper face | `256` for a faster, softer render |
| `--preprocess full` | Keeps the whole photo and animates the face inside it | `crop` for a square close-up of the face |
| `--still` | Limits head movement, which keeps the background of a full photo from warping | Remove it with `crop` for more head motion |
| `--expression_scale 1.3` | Strengthens mouth and facial movement | A value between `1.0` and `1.5` |
| `--enhancer gfpgan` | Restores facial detail and teeth in every frame | Remove it to render faster |

To change a setting, edit the matching line in `studio.sh`.

## Tips for good results

- Expect long renders. SadTalker runs on the CPU only. With `--size 256` and `--preprocess crop`, a 4 second clip took 34 minutes on an Apple M5 Mac; the default 512 pixel full-photo settings take longer.
- Keep the Mac awake during a render, for example with `caffeinate -i ./studio.sh make`. Sleep can stall the render.
- Test with a short script first. A fanless MacBook Air heats up and slows down on long renders.
- Close memory-heavy apps, such as browsers with many tabs, before rendering. The models share the Mac's unified memory.
- Record the voice sample in a quiet room without fan noise, air conditioning, or echo. Background noise lowers cloning accuracy.
- Use a photo with a neutral expression and a closed mouth. SadTalker produces the cleanest lip movement from that starting point.

## Project layout

| Path | Contents |
|---|---|
| `setup.sh` | One-time installer |
| `studio.sh` | Command-line interface for the pipeline |
| `inputs/` | Your photo, voice sample, script, and the generated speech track |
| `outputs/` | Rendered videos |
| `.envs/` | The two Python environments, created by `setup.sh` |
| `engines/` | The SadTalker source and checkpoints, created by `setup.sh` |

## Uninstall

Delete this folder. F5-TTS also stores its model in `~/.cache/huggingface`; delete that folder too if no other project uses it. Homebrew, Miniforge, and the Homebrew packages stay installed; remove them with `brew uninstall` if you no longer need them.
