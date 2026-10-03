# Building

The port has been built on **Windows 11 from Git Bash**, with portable tools. The scripts are
plain bash and CMake, so Linux should work with small changes (use the `linux` binaries of the
OpenOrbis tools), but that has not been tried.

## Workspace layout

Everything lives side by side in one workspace directory, and this repository has to be cloned
under the name `ps4port`:

```
<workspace>/
├─ ps4port/      this repository
├─ Shipwright/   Ship of Harkinian 9.2.3 + the patches
└─ tools/
   ├─ llvm/                                  LLVM 18.1.8 (clang, ld.lld, llvm-ar...)
   ├─ cmake-<version>-windows-x86_64/        CMake 3.26 or newer
   ├─ ninja/                                 ninja.exe
   └─ OpenOrbis/OpenOrbis/PS4Toolchain/      OpenOrbis toolchain v0.5.4
```

## 1. Tools

Download and unpack into `tools/` as shown above:

- **LLVM 18.1.8** for Windows: `LLVM-18.1.8-win64.exe` from the
  [LLVM releases](https://github.com/llvm/llvm-project/releases/tag/llvmorg-18.1.8). It is a
  self-extracting archive; it can be unpacked with 7-Zip instead of installed
  (`7z x -otools/llvm LLVM-18.1.8-win64.exe`).
- **CMake** (`cmake-*-windows-x86_64.zip`) and **Ninja** (`ninja-win.zip`).
- **OpenOrbis toolchain v0.5.4**: `toolchain-llvm-18.tar.gz` from the
  [OpenOrbis releases](https://github.com/OpenOrbis/OpenOrbis-PS4-Toolchain/releases/tag/v0.5.4),
  extracted into `tools/OpenOrbis/`.
- Git, Python 3 and a .NET runtime (`PkgTool.Core` is a .NET application; any recent runtime
  works, the scripts set `DOTNET_ROLL_FORWARD`).

## 2. Sources

The patched sources are published as forks, on a `ps4` branch. The Shipwright fork's submodule
already points at the libultraship fork, so one recursive clone gets everything:

```bash
cd <workspace>
git clone --recurse-submodules --branch ps4 https://github.com/alechurri/Shipwright.git
git clone https://github.com/alechurri/shipofharkinian-ps4.git ps4port
```

Alternatively, the same changes are available as patches against the upstream repositories
(Shipwright `cb71e22`, tag 9.2.3, and libultraship `fdcaf63`):

```bash
git clone --recurse-submodules --branch 9.2.3 https://github.com/HarbourMasters/Shipwright.git
cd Shipwright
git apply ../ps4port/patches/shipwright-9.2.3-ps4.patch
cd libultraship
git apply ../../ps4port/patches/libultraship-ps4.patch
```

## 3. Dependencies

```bash
cd <workspace>/ps4port
./build-deps.sh
```

Cross-builds zlib, bzip2, libzip, tinyxml2, nlohmann-json, spdlog, ogg, vorbis, opus, opusfile
and SDL2 2.30.9 into `ps4port/prefix/`. This is only needed once (but again after changing the
toolchain file, everything has to be rebuilt with the same flags). StormLib, for `.otr`
archives, is fetched and built with the game.

## 4. Game

```bash
./configure.sh
source env.sh
cmake --build build --target soh
```

The result is `build/soh/soh.elf`.

## 5. Package

`package.sh` needs the `soh.o2r` of the matching PC release (it holds Ship of Harkinian's own
assets, no game data). Take it from the 9.2.3 release zip and put it in `ps4port/release-pc/`:

```bash
mkdir -p release-pc
unzip -o SoH-Ackbar-Delta-Win64.zip soh.o2r -d release-pc
./package.sh
```

The package is written to `ps4port/out/`.

### Self-contained package (personal use only)

`package.sh` can also bundle the Piglet modules and your ROM archive, so that nothing has to be
copied to `/data` by hand. Such a package contains Sony binaries and game assets: **do not
distribute it.**

```bash
BUNDLE_SPRX_DIR=/path/to/dir/with/both/sprx \
BUNDLE_OOT_O2R=/path/to/oot.o2r \
OUT_DIR="$PWD/out-personal" ./package.sh
```

## Tests

Two host-side checks exist for the parts that can be tested without a console. Both need a
compiler that targets the host; [llvm-mingw](https://github.com/mstorsjo/llvm-mingw) was used.

- `tests/hosttest/heaptest.c`: exercises the PS4 heap arena (`Ps4Heap.c`) against a fake kernel.
  ```bash
  clang -O1 -static -Itests/hosttest/stubs tests/hosttest/heaptest.c -o heaptest && ./heaptest
  ```
- `tests/shadertest/gen_harness.py`: builds a harness out of the real renderer sources that
  generates thousands of shader variants, to be validated as GLSL ES 1.00 with Khronos'
  [glslang](https://github.com/KhronosGroup/glslang). It expects the game to have been
  configured first (it compiles the prism sources fetched into `build/_deps/`); read the script
  for the exact paths.
