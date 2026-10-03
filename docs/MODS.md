# Mods

Mods go in `/data/soh/mods/` on the console (the game creates the folder on first boot). Upload
them over FTP, then enable them from the SoH menu (touchpad click) in the mods section.
Subfolders are fine, the folder is scanned recursively.

> `.otr` mods are verified on a PS4 Pro (FW 12.52): eight character, item model and dialogue mods
> loaded together and worked in game, using about 40 MiB of extra memory. `.o2r` mods use the
> same code path as the game's own archives but have not been tried yet. Test a mod on the PC
> release of Ship of Harkinian 9.2.3 first; if it is broken there it will be broken on the console
> too. If one fails, please attach `/data/soh/ps4_boot.log` to an issue.

## Supported formats

| Format | PS4 port | Notes |
| --- | --- | --- |
| `.o2r` | yes | |
| `.otr` | yes, since v0.2.0 (verified) | The old MPQ format. Upload it as is, no conversion needed. |
| `.zip` | no | Ignored on every platform. A downloaded `.zip` is only the wrapper: unzip it on a PC and upload the `.o2r` or `.otr` inside. |

## Limits

Video memory is limited on the console, and archives that can't be read in place are loaded
fully into RAM. Model, sound and small texture mods should fit. Multi-gigabyte HD texture packs
almost certainly will not.

## Converting an `.otr` mod to `.o2r`

Not needed since v0.2.0, `.otr` files load directly. It is still a way out if a particular `.otr`
refuses to load: an `.otr` is an MPQ archive and an `.o2r` holds the same files in a ZIP
container.

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
