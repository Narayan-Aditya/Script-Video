# Agent setup instructions

These instructions are for a coding agent that installs Script Video on the user's Mac. Follow the steps in order, and report the result of each step to the user. The project is at https://github.com/Narayan-Aditya/Script-Video.

## Rules

- Change only what these steps ask for. The package versions in `setup.sh` are pinned on purpose; see [Known issues](#known-issues) before changing any of them.
- Do not run `./studio.sh clone`, `video`, or `make` as a test unless the user asks. A video render takes 30 minutes or more on the CPU.
- Do not add files to the repository. The setup creates `.envs/`, `engines/`, `inputs/`, and `outputs/`; `.gitignore` already excludes them.

## 1. Check the machine

Run:

```bash
uname -sm
```

The output must be `Darwin arm64`, which means an Apple Silicon Mac. On `Darwin x86_64` (an Intel Mac), tell the user that the project is untested there and that PyTorch publishes no Intel Mac builds after version 2.2. Continue only if the user agrees.

## 2. Get the project

Skip this step when the current folder already contains `setup.sh` and `studio.sh`. Otherwise run:

```bash
git clone https://github.com/Narayan-Aditya/Script-Video.git
cd Script-Video
```

## 3. Install Homebrew when it is missing

Run:

```bash
command -v brew || ls /opt/homebrew/bin/brew /usr/local/bin/brew
```

When this prints nothing, Homebrew is missing. Its installer needs the user's password at an interactive prompt, which an agent shell cannot answer. Ask the user to run this command in their own Terminal, then continue after they confirm:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## 4. Run the setup script

From the project folder, run:

```bash
bash setup.sh
```

The installed environments and models take about 5.5 GB of disk space, and the F5-TTS model adds 1.3 GB on the first `clone`. Allow the script at least 30 minutes, and run it in the background when your shell has a command timeout. It prints `Setup complete.` when it finishes. When it fails, read the last 30 lines of its output and check [Known issues](#known-issues). `setup.sh` skips the parts that already exist, so it can be run again after a fix.

## 5. Verify the installation

Run each command from the project folder:

```bash
./studio.sh
.envs/voice/bin/python -c "import f5_tts.infer.utils_infer; print('voice ok')"
cd engines/SadTalker && ../../.envs/avatar/bin/python -c "import torch, basicsr, gfpgan, librosa, cv2; from src.facerender.animate import AnimateFromCoeff; print('avatar ok')" && cd ../..
ls engines/SadTalker/checkpoints engines/SadTalker/gfpgan/weights
```

The expected results are:

1. `./studio.sh` prints a usage message that lists `clone`, `record`, `video`, and `make`.
2. The second command prints `voice ok`.
3. The third command prints `avatar ok`. Warnings about `functional_tensor` are expected.
4. `checkpoints` contains four files and `gfpgan/weights` contains four `.pth` files.

## 6. Hand over to the user

Tell the user that the setup is complete, and point them to the "Prepare the inputs" and "Usage" sections of `README.md`. The first `clone` run downloads the F5-TTS model, so it needs an internet connection.

## Known issues

These failures appeared while the project was tested on macOS 27. `setup.sh` already contains each fix.

| Symptom | Cause | Fix in `setup.sh` |
|---|---|---|
| `ImportError` in `scipy` mentioning `__DATA/__thread_bss` | The scipy 1.15 wheel for Python 3.10 does not load on macOS 27 | The `voice` environment uses Python 3.11, which installs a newer scipy |
| `No module named 'pkg_resources'` | setuptools 81 and later removed `pkg_resources`, which librosa 0.9.2 imports | `setuptools<81` in the `avatar` environment |
| `No module named 'torch'` while installing `basicsr` | basicsr 1.4.2 imports torch in its build script | torch is installed first, then basicsr with `--no-build-isolation` |
| `torchvision.transforms.functional_tensor` not found | torchvision 0.17 removed a module that basicsr uses | torch 2.0.1 with torchvision 0.15.2 |
| `Couldn't find ffmpeg` | Homebrew is not on `PATH` | `setup.sh` adds Homebrew to `~/.zprofile`; `studio.sh` loads it on every run |
