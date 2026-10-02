# Mods

Mods go in `/data/soh/mods/` on the console (the game creates the folder on first boot). Upload
them over FTP, then enable them from the SoH menu (touchpad click) in the mods section.
Subfolders are fine, the folder is scanned recursively.

> No mod has been verified on the PS4 port yet. Test a mod on the PC release of Ship of Harkinian
> 9.2.3 first; if it is broken there it will be broken on the console too.

## Supported formats

| Format | PS4 port | Notes |
| --- | --- | --- |
| `.o2r` | yes | |
| `.otr` | **no** | The old MPQ format. StormLib is not part of the PS4 build. Convert it, see below. |
| `.zip` | no | Ignored on every platform. A downloaded `.zip` is only the wrapper: unzip it on a PC and upload the `.o2r` inside. |

## Limits

Every archive is loaded fully into memory on the console, and video memory is limited. Model,
sound and small texture mods should fit. Multi-gigabyte HD texture packs almost certainly will
not.

## Converting an `.otr` mod to `.o2r`

An `.otr` is an MPQ archive. An `.o2r` holds the same files in a ZIP container.

1. On a PC, open the `.otr` with an MPQ editor (for example Ladislav Zezula's
   [MPQ Editor](http://www.zezula.net/en/mpq/download.html)), select everything and extract it to
   an empty folder, keeping the folder structure.
2. Check the result. You should see ordinary folder and file names. If everything is named like
   `File00000123.xxx`, the archive's file list was not found and this method will not work.
3. Select what is **inside** that folder (not the folder itself) and compress it as a ZIP. The
   files must sit at the root of the archive.
4. Rename the `.zip` to `.o2r`.
5. Test it with the PC release of Ship of Harkinian 9.2.3 (put it in the `mods` folder next to the
   executable), then upload it to `/data/soh/mods/`.

Before converting, check whether the mod's author already publishes an `.o2r` version.
