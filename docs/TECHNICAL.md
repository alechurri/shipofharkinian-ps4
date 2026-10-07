# Technical notes

## Overview

The port keeps Ship of Harkinian and libultraship (LUS) as they are wherever possible and adds a
PS4 platform layer:

| Area | Approach |
| --- | --- |
| Toolchain | Stock LLVM 18 + OpenOrbis v0.5.4 (musl libc, libc++ 11), driven by a CMake toolchain file (`cmake/ps4-toolchain.cmake`) |
| Rendering | Piglet, OpenGL ES 2.0 + EGL 1.4. `gfx_opengl_ps4.cpp` is a GLES2 variant of LUS's OpenGL backend |
| Window | LUS's SDL2 window backend, with the GL context created through EGL/Piglet instead of SDL |
| SDL2 | Upstream 2.30.9 built with the dummy video driver; used for events, timing and the game controller API only |
| Controller | `scePad`, exposed to SDL as a *virtual* game controller, so LUS's controller code is untouched |
| Audio | `sceAudioOut`; the game mixes at 32 kHz, a feeder thread resamples to the 48 kHz the main port requires |
| Memory | `mmap`/`munmap` are replaced so the C heap lives in one arena outside the application's flexible memory |
| Assets | `.o2r` archives generated on a PC (no extractor/ZAPD on the console); `.otr` mods through StormLib |

PS4-specific sources (in the [Shipwright](https://github.com/alechurri/Shipwright/tree/ps4) and
[libultraship](https://github.com/alechurri/libultraship/tree/ps4) forks):

- `libultraship/src/ship/port/ps4/Ps4Platform.cpp`: module loading, Piglet/EGL setup, pad, memory statistics
- `libultraship/src/fast/backends/gfx_opengl_ps4.cpp` and `gfx_opengl_ps4_shaders.h`: renderer and shader templates
- `soh/soh/port/ps4/Ps4Main.cpp`: entry point, boot log, fatal signal handler
- `soh/soh/port/ps4/Ps4Heap.c`: heap arena
- `soh/soh/port/ps4/Ps4Compat.c`: `__cxa_thread_atexit_impl`

## The renderer

Piglet reports `OpenGL ES 2.0` and `GLSL ES 2.0`, so compared to LUS's desktop/GLES3 path:

- Shader templates are GLSL ES 1.00 (`attribute`/`varying`/`texture2D`/`gl_FragColor`), never
  index a uniform array with a non-constant expression, and avoid `textureSize()` and `mix()`
  with a boolean selector. They are embedded in the executable instead of being read from
  `soh.o2r`.
- No vertex array objects, no MSAA, unsized texture formats.
- `glBlitFramebuffer` does not exist: framebuffer copies are done by drawing a textured quad.
- The depth buffer cannot be read back: `GetPixelDepth` reports "nothing in front".
- ImGui's GL3 backend always prepends a `#version` line; its `glShaderSource` calls are routed
  through a wrapper that strips it.

The generated shaders are validated on the host: `tests/shadertest` produces thousands of
combiner variants from the real sources and runs them through glslang as GLSL ES 1.00.

## Things that only showed up on hardware

These cost a console round trip each, so they are written down for whoever tries something
similar.

**Memory budget.** This kind of application (`CATEGORY gde` with the system auth info Piglet
needs) gets **768 MiB of direct memory** in total and about **255 MiB of flexible memory**, not
the gigabytes a regular game has. musl's `malloc` gets everything from anonymous `mmap`, i.e.
from flexible memory, which Piglet also uses for textures. The heap is therefore mapped with
`sceKernelMapNamedSystemFlexibleMemory` (a separate pool; 1 GiB arena, the game uses about
250 MiB), with a direct-memory arena as fallback. That leaves the direct memory to Piglet.

**Piglet configuration.** `scePigletSetConfigurationVSH` accepts almost anything; a bad
configuration only fails later, in `eglGetDisplay`, with "Out of memory". The code tries a list
of configurations until one initializes. The one in use: 128 MiB system shared, 512 MiB video
shared, 236 MiB flexible, 4 MiB command buffers. Textures and render targets are allocated from
the flexible memory limit; the game's 1080p framebuffers alone need more than 64 MiB.

**Vsync.** `eglSwapInterval(1)` set after `eglMakeCurrent` made `eglSwapBuffers` block forever on
the first frame. Set before the surface is created it works, but the game felt clearly worse than
with interval 0 and LUS's own frame timer. Vsync is opt-in; a watchdog thread guards the attempt.

**Shader compilation.** The runtime compiler (`libSceShaccVSH`) takes 110 to 260 ms per program.
Piglet rejects `GL_PROGRAM_BINARY_LENGTH`, so linked programs cannot be cached on disk. Instead
the combiner ids the game asks for are appended to a text file and compiled up front at the next
start, behind the system splash screen.

**Reading the window surface.** `glCopyTexImage2D` from the default framebuffer takes seconds.
The pause screen captures the picture that way when the game renders straight to the window, so
on PS4 the game always renders into its own framebuffer (as LUS already does on macOS).

**`struct stat` has the wrong layout in the OpenOrbis headers.** `<bits/alltypes.h>` (v0.5.4)
declares `mode_t` as a 32-bit type, while the PS4 kernel (FreeBSD 9) uses 16 bits, and the C
library hands the kernel's `struct stat` to the caller unconverted. Every member after `st_mode`
lands 8 bytes off: `st_size` actually reads `st_blocks`. The visible symptom was libzip failing
on every archive with `ZIP_ER_NOZIP`, because it looked for the central directory at the wrong
offset. The toolchain file force-includes `compat/include/ps4_fixups.h`, which defines `mode_t`
before any system header; the boot log prints a `file size check` line comparing `stat()` with
`lseek()`. Verified on a PS4 Pro (FW 12.02): sizes now match, every archive opens in place, and
the game uses about 35 MiB less memory than when archives had to be read into RAM. Archives that
still fail to open fall back to being read into memory and opened with `zip_source_buffer_create`. Note that the prebuilt libc++ still uses the old layout internally,
so `std::filesystem::file_size()` and `last_write_time()` are not reliable.

**Relative paths.** They fail with `EINVAL` rather than `ENOENT`, which makes
`std::filesystem::exists` throw. Every lookup goes through an absolute path in `/data/soh`.

**Depth formats.** Only `GL_OES_depth32` is advertised, but a 32-bit depth renderbuffer gives an
incomplete framebuffer; offscreen targets fall back to 16 bits.

**libc++ 11.** The OpenOrbis toolchain ships an old libc++. The only source change it forced was
replacing `std::fill` in a `constexpr` constructor.

**Logging.** The game opens its log file only after the window exists, so early failures left no
trace. stdout/stderr are redirected to `/data/soh/ps4_boot.log` from the first instruction of
`main`; Piglet's own diagnostics (`[PIG]...`) end up there too, which turned out to be the most
useful debugging tool of the whole port.

## Open problems

- Offscreen depth is 16 bits. A depth *texture* attachment (`GL_OES_depth_texture`) has not been
  tried.
- No occlusion for light glows and lens flares.
- Gyro: SDL's virtual joystick has no sensor support; it would need a small LUS-side mapping.
- Only the PS4 Pro has been tested (firmware 12.02 and 9.60).
