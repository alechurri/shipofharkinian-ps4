# Installation guide

## Requirements

- A PS4 with a jailbreak that can install fake packages and run an FTP server. The port has only
  been tested on a **PS4 Pro, firmware 12.52, with GoldHEN**.
- A PC (Windows, Linux or macOS) to generate the game assets.
- Your own *Ocarina of Time* ROM, in one of the versions Ship of Harkinian supports.
- An FTP client such as FileZilla.

You will end up with these files on the console:

| File | Where it comes from | Destination on the PS4 |
| --- | --- | --- |
| `IV0000-SOHP00001_00-SHIPOFHARKINIAN0.pkg` | [Releases page](https://github.com/alechurri/soh-ps4/releases) | installed as a package |
| `oot.o2r` (and/or `oot-mq.o2r`) | generated from your ROM, step 1 | `/data/soh/` |
| `libScePigletv2VSH.sprx` | see step 2 | `/data/self/system/common/lib/` |
| `libSceShaccVSH.sprx` | see step 2 | `/data/self/system/common/lib/` |

## Step 1: generate `oot.o2r` on a PC

The console build has no ROM extractor, so the asset archive is made with the regular PC release.

1. Download Ship of Harkinian **9.2.3** for your PC from
   <https://github.com/HarbourMasters/Shipwright/releases/tag/9.2.3>.
   It has to be exactly 9.2.3: archives created by a different major version are rejected.
2. Unzip it and run it.
3. When asked, select your ROM. The program extracts the assets and writes `oot.o2r` next to the
   executable (`oot-mq.o2r` for a Master Quest ROM).
4. Close the program. `oot.o2r` is the only file you need from that folder.

## Step 2: get the two Piglet modules

Piglet is Sony's OpenGL ES library. Retail firmware ships it without its runtime shader compiler,
so GLES homebrew uses a matching pair of modules:

- `libScePigletv2VSH.sprx`
- `libSceShaccVSH.sprx`

They are Sony binaries and are **not** distributed here. Two ways to get them:

- **From the Super Mario 64 PS4 port.** Its release archive carries them under
  `data/self/system/common/lib/`. If you already run that port, you already have them in place.
- **From RetroArch for PS4.** Install and start RetroArch, then connect over FTP while it is
  running: its `sce_module` folder is mounted in the app sandbox and holds both files. Download
  them (in binary mode, see step 3). This route comes from the
  [OpenPS4 orbisdev install guide](https://github.com/OpenPS4/guide-to-install-orbisdev).
  Not tested with this port yet: if the files you get differ in size or hash from the table
  below, please report whether the game starts with them.

Check them before copying, a damaged copy is the most common cause of the game not starting:

| File | Size (bytes) | SHA-256 |
| --- | --- | --- |
| `libScePigletv2VSH.sprx` | 744,208 | `69d6b3adc85b6edf5208b7f18fad3b2638ae7c4648f78880877bae3aa4202efd` |
| `libSceShaccVSH.sprx` | 10,394,272 | `0a64982b0d7e33701745ab5180a1d314c11980215e418d14e868c75de3ca1e12` |

## Step 3: copy the files over FTP

1. On the PS4, with GoldHEN loaded: *Settings → GoldHEN → Server Settings → Enable FTP Server*.
   Note the console's IP address.
2. In FileZilla connect to that IP, port **2121**, with empty user name and password.
3. Set *Transfer → Transfer type → Binary*. In automatic or text mode the `.sprx` files get
   corrupted.

   > **Do not use WinSCP for the `.sprx` files.** A user on firmware 9.60 had the game fail every
   > time until the modules were deleted and uploaded again with FileZilla in binary mode. The same
   > applies to other ports that use these files, such as the Super Mario 64 one.
4. Upload:
   - `oot.o2r` → `/data/soh/` (create the `soh` folder inside `/data` if it does not exist)
   - both `.sprx` files → `/data/self/system/common/lib/` (create the folders if needed)
   - the `.pkg` → `/data/pkg/` (create it if needed), or put it on a USB drive instead

## Step 4: install the package

*Settings → GoldHEN → Package Installer* (or *Debug Settings → Game → Package Installer*), pick
the package and install it. To update later, install the new package over the old one; saves and
settings live in `/data/soh/` and are not touched.

## Step 5: play

Launch "Ship of Harkinian" from the home screen.

- The **first run** compiles shaders as they are needed, so expect short hitches when new effects
  appear. They are remembered in `/data/soh/ps4_shaders.txt`.
- From the **second run** on, those shaders are compiled while the system splash screen is
  showing. Startup takes 10 to 15 seconds longer and the hitches are gone for everything you have
  already seen.
- Press the **touchpad** to open the SoH menu.

## Files the game creates in `/data/soh/`

| File | Purpose |
| --- | --- |
| `Save/` | Save files |
| `shipofharkinian.json` | Settings |
| `mods/` | Mods, see [MODS.md](MODS.md) |
| `ps4_boot.log` | Log of the last run. This is the file to attach to any bug report. |
| `logs/` | The regular Ship of Harkinian log |
| `ps4_shaders.txt` | List of shaders to precompile at boot. Safe to delete. |
| `imgui.ini` | Menu layout |

Optional marker file:

| File | Effect |
| --- | --- |
| `ps4_vsync` (empty) | Enables vertical sync. It works but felt clearly worse in testing, so it is off by default. |

## Recommended settings

- Internal resolution: up to about 150%. Above that Piglet runs out of video memory and the log
  fills with framebuffer errors, which also slows the game down.
- Frame interpolation: "Match refresh rate" (60 fps) ran steadily on a PS4 Pro.

## Troubleshooting

**The game drops back to the home screen immediately (CE-34878-0).**
Almost always the Piglet modules. Open `/data/soh/ps4_boot.log` and look for
`sceKernelLoadStartModule(".../libScePigletv2VSH.sprx") failed`:

- `0x80020002`: the file is not there. Check the folder name, `/data/self/system/common/lib/`.
- `0x8002000D`: the file is there but damaged, usually by an FTP client in text mode or by
  WinSCP. Delete both `.sprx` files on the console, check their size and SHA-256 on the PC (table
  in step 2), and upload them again with FileZilla in binary mode.

If the modules load, the last lines of the log say how far the game got.

**A popup says "No ROM Archives".**
`oot.o2r` is missing from `/data/soh/`.

**A popup says "Outdated ROM Archives".**
`oot.o2r` was generated with a version of Ship of Harkinian other than 9.2.3.

**The screen is black, or textures are missing, after raising the internal resolution.**
Video memory ran out. Lower the internal resolution. If you cannot reach the menu, delete
`/data/soh/shipofharkinian.json` over FTP to reset all settings.

**Anything else.**
Open an issue and attach `/data/soh/ps4_boot.log`, with your console model and firmware version.
Download the log before starting the game again, each run overwrites it.
