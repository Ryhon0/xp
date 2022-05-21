# xp

GUI and TUI music player with support for multiple streaming services.  
![](screenshots/tui.gif)

## Features
* Gtk4 GUI and TUI
* Downloading music from multiple streaming services. See table below.
* Partial MPRIS implementation (play/pause, seek, quit, see [ddbus#60](https://github.com/trishume/ddbus/issues/60))
### Supported services
| Service | Notes |
|---|---|
| Local files | Metadata provided by `taglib_c` |
| YouTube | |
| Spotify | Audio is downloaded with youtube-dl's `ytsearch:` feature |
| SoundCloud | |

## Dependencies
* DUB and D compiler (prefarably LDC2)
* SDL2_mixer
* gtk4
* youtube-dl
* ffmpeg or avconv
* taglib (taglib_c)
* dbus
* sqlite3
* libmodest