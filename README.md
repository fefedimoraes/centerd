# centerd

**centerd** is a simple command line application for MacOS that warps the mouse to the center of the active application.

This application is useful when paired with a Keyboard-based Application Launcher such as [koekeishiya's **skhd**](https://github.com/koekeishiya/skhd), so that not only does it open a new application (or, most importantly, focus on an already opened one) but also warps the mouse together with it.

## Usage

### `active` command

Warps the mouse to the center of the active application.

```bash
centerd active [--delay DELAY]
```

Optional arguments:

1. `--delay` **(Integer)**: The amount of seconds to wait before probing for the active application.

### `apps` command

Prints a list of running applications that can be used with the `cycle` command.

```bash
centerd apps
```

### `cycle` command

Warps the mouse to the center of the active application. Upon re-execution, if the mouse pointer is already centered in an active application window, it attempts to find the next window belonging to the same application. If another window is found, that window is focused and the mouse cursor is warped to its center.

```bash
centerd cycle [forward|backwards] <--app APP NAME> [--tolerance TOLERANCE]
```

Optional arguments:

1. `forward|backwards`: Whether to navigate forwards or backwards through the active application windows. Ordering is determined by Window's ID. Defaults to `forward`;
2. `--app` **(String)**: The name of the application whose windows will be cycled through. This argument is required.
3. `--tolerance` **(Double)**: The tolerance threshold to be used when checking if the mouse cursor is at the center of a window. Defaults to `2.0`.

## skhd Configuration Sample

Below is a `skhdrc` example that illustrates how **centerd** can be paired with **skhd**:

```bash
# Ctrl + Shift + T (for terminal) opens (or focuses) the Terminal app;
# and warps the mouse to the center of its window.
shift + ctrl - t : open "/Applications/Utilities/Terminal.app" && centerd active

# Ctrl + Shift + B (for browser) focuses Google Chrome or opens a new instance if it is not running;
# and warps the mouse to the center of its window,
# or goes to the next Google Chrome window if the current one is already centered...
shift + ctrl - b : centerd cycle --app "Google Chrome" || open "/Applications/Google Chrome.app"
# ...or goes to the previous Google Chrome window if Alt is also pressed.
shift + ctrl + alt - b : centerd cycle backwards --app "Google Chrome" || open "/Applications/Google Chrome.app"
```

## Install

### Homebrew

Use [Homebrew](https://brew.sh/) to install `centerd`:

```bash
brew install fefedimoraes/tap/centerd
```

### Pre-build Binaries

Download the latest release from the [`centerd` releases page](https://github.com/fefedimoraes/centerd/releases).

Then, extract and install it using the following commands:

```bash
tar -xzf v*.tar.gz
sudo cp centerd /usr/local/bin/
```

### Source

> #### Requirements
>
> Xcode Command Line Tools
>
> ```bash
> xcode-select --install
> ```
>
> (Optional) `just` command runner
>
> ```bash
> brew install just
> ```

```bash
git clone https://github.com/fefedimoraes/centerd centerd
cd centerd

# If using just, run:
just install

# Otherwise, run:
swift build -c release --arch arm64 --arch x86_64 --product centerd
cp .build/apple/Products/Release/centerd /usr/local/bin/
```

## Acknowledgments

Parts of this project were heavily inspired by:

1. [lwouis' **alt-tab-macos**](https://github.com/lwouis/alt-tab-macos) &mdash; In special to [commit `2cd8b96`](https://github.com/lwouis/alt-tab-macos/commit/2cd8b96d389004b41ce2aad5667d0a11be36dabf), which introduced a workaround to retrieve focusable windows across all virtual Spaces;
2. [koekeishiya's **skhd**](https://github.com/koekeishiya/skhd) &mdash; Without it, there would be no reason to create **centerd**.
