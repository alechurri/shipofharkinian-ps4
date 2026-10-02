# Ship of Harkinian for PS4

An experimental native port of [Ship of Harkinian](https://github.com/HarbourMasters/Shipwright)
9.2.3 "Ackbar Delta" (the PC port of the *Ocarina of Time* decompilation) to jailbroken PS4
consoles. It is built with the [OpenOrbis toolchain](https://github.com/OpenOrbis/OpenOrbis-PS4-Toolchain)
and renders through Piglet, Sony's OpenGL ES 2.0 implementation. It is not an emulator.

**Download:** the installable package is on the [Releases page](https://github.com/alechurri/soh-ps4/releases).

Where everything lives:

| Repository | Contents |
| --- | --- |
| [alechurri/soh-ps4](https://github.com/alechurri/soh-ps4) (this one) | Releases, build scripts, CMake toolchain, tests, documentation |
| [alechurri/Shipwright, branch `ps4`](https://github.com/alechurri/Shipwright/tree/ps4) | Ship of Harkinian 9.2.3 with the PS4 changes applied |
| [alechurri/libultraship, branch `ps4`](https://github.com/alechurri/libultraship/tree/ps4) | libultraship with the PS4 platform layer and renderer |

**None of this contains game assets or Sony binaries.** You need your own legally obtained ROM,
and the two Piglet modules described in the install guide.

> **Tested on exactly one console:** PS4 Pro, firmware 12.52, GoldHEN. Nobody knows yet how it
> behaves on a base PS4 or on other firmwares. Reports are welcome.

## What works

- Graphics, audio, DualShock 4, saves
- 60 fps with frame interpolation, internal resolution up to about 150%
- The full SoH menu: graphics options, enhancements, mod manager

Not tested yet: Randomizer, Boss Rush, and loading actual mods (only `.o2r` is supported, see
[docs/MODS.md](docs/MODS.md)).

## Known limitations

- No MSAA and no gyro aiming.
- Light glows and lens flares are never hidden by walls (GLES2 cannot read the depth buffer back).
- Offscreen framebuffers use 16-bit depth.
- The first run compiles shaders on demand (hitches of about 0.2 s). From the second run on they
  are precompiled at boot, which makes startup 10 to 15 seconds longer.
- `.otr` (MPQ) mods are not supported, only `.o2r`.
- No ROM extractor on the console; assets are generated on a PC.

## Installing

Full walkthrough: **[docs/INSTALL.md](docs/INSTALL.md)**. In short:

1. Generate `oot.o2r` from your ROM with Ship of Harkinian **9.2.3** on a PC.
2. Copy `oot.o2r` to `/data/soh/` and the two Piglet modules to `/data/self/system/common/lib/`
   on the console over FTP.
3. Install the `.pkg` with GoldHEN's Package Installer and launch the game.

## Controls

| DualShock 4 | N64 |
| --- | --- |
| Cross | A |
| Circle | B |
| L2 | Z |
| R2 | R |
| L1 | L |
| OPTIONS | Start |
| Right stick | C buttons |
| D-pad | D-pad |
| **Touchpad click** | opens / closes the SoH menu |

Everything can be remapped from the SoH menu.

## Building

See **[docs/BUILDING.md](docs/BUILDING.md)**. The build runs on Windows (Git Bash) with portable
copies of LLVM 18, CMake, Ninja and the OpenOrbis toolchain; nothing has to be installed
system-wide.

## How it works

[docs/TECHNICAL.md](docs/TECHNICAL.md) describes the port and, more usefully for anyone attempting
something similar, the PS4-specific problems that only showed up on real hardware.

## Disclosure

The person who published this port is not a C++ developer. The code was written with an AI coding
assistant (Claude) and debugged by installing builds on a console and feeding the logs back. It
has had no review by anyone who knows the Ship of Harkinian or libultraship codebases; review and
corrections are very welcome.

## Credits

- The [HarbourMasters](https://github.com/HarbourMasters) team for Ship of Harkinian and
  [libultraship](https://github.com/Kenix3/libultraship), which is where all of the actual game
  port lives.
- The [OpenOrbis](https://github.com/OpenOrbis) team for the toolchain.
- flat_z and the orbisdev contributors for the Piglet research, and OsirizX's
  [Super Mario 64 PS4 port](https://github.com/OsirizX/sm64-port/tree/ps4), which showed how to
  bring Piglet up with runtime shader compilation.

## License

The build scripts, CMake files, tests and documentation in this repository are released under the
[MIT License](LICENSE). The files under `patches/` are modifications of Ship of Harkinian and
libultraship and remain subject to the terms of those projects.

This project is not affiliated with or endorsed by Nintendo or Sony.
