# Packaging the Qt client as a `.deb`

Builds a distributable Debian package for **Virtual Foreign Language** (the
vLearn2 Qt client).

## Build

```bash
cd qt_app
QMAKE=~/Qt5.12.12/5.12.12/gcc_64/bin/qmake ./packaging/make_deb.sh 1.0.0
# → dist/vlearn-chat_1.0.0_amd64.deb
```

`make_deb.sh [VERSION]` — env overrides: `QMAKE`, `ARCH` (default `amd64`),
`JOBS`. It compiles a release build, strips the binary, and assembles the
package.

## What the package installs

| Path | Purpose |
|---|---|
| `/usr/bin/vlearn-chat` | the application binary |
| `/etc/vlearn/app_config.json` | backend endpoint (a **conffile** — survives upgrades) |
| `/usr/share/applications/vlearn.desktop` | app-menu launcher |
| `/usr/share/doc/vlearn-chat/README.md` | docs |

## Install / configure / run (on the target machine)

```bash
sudo apt install ./vlearn-chat_1.0.0_amd64.deb     # resolves Qt deps automatically
sudo nano /etc/vlearn/app_config.json              # set { "baseUrl": "http://HOST:5101/api" }
vlearn-chat                                         # or launch from the app menu
```

Per-user override: a `~/.config/vlearn/app_config.json` takes precedence over
the system `/etc/vlearn/app_config.json`.

Remove: `sudo apt remove vlearn-chat`.

## Dependencies & target compatibility

The package depends on the **system Qt 5** runtime
(`libqt5core5a/gui5/widgets5/network5 ≥ 5.12`), so the `.deb` stays small
(~570 KB). This is the right choice for **Ubuntu 20.04** (ships Qt 5.12.8) and
works on 22.04/24.04 (Qt 5.15, backward-compatible with a 5.12-built binary).

> The binary here is compiled against the Qt 5.12.12 SDK installer but links the
> unversioned `libQt5*.so.5`; patch releases within 5.12.x are ABI-compatible,
> so it runs against the distro's 5.12.8.

### Fully self-contained alternative (no Qt on target)

If you must target machines without system Qt5, bundle the Qt libraries instead
of depending on them:

1. `sudo apt install patchelf && wget the linuxdeployqt AppImage`
2. Run `linuxdeployqt vlearn_chat -bundle-non-qt-libs`, then place the collected
   `lib/` + binary under `/opt/vlearn/` in the package tree and set
   `Exec=/opt/vlearn/vlearn-chat` with an `LD_LIBRARY_PATH` wrapper.

This produces a larger (~40–60 MB) but dependency-free `.deb`. The current script
uses the system-Qt approach by default.
