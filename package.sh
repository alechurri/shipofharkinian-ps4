#!/usr/bin/env bash
# Turns ps4port/build/soh/soh.elf into an installable PS4 package (ps4port/out/*.pkg).
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/env.sh"

TITLE="Ship of Harkinian"
VERSION="01.00"
TITLE_ID="SOHP00001"
CONTENT_ID="IV0000-${TITLE_ID}_00-SHIPOFHARKINIAN0"
# System auth info + program id used by the OpenOrbis Piglet sample: needed to load Piglet.
AUTHINFO="000000000000000000000000001C004000FF000000000080000000000000000000000000000000000000008000400040000000000000008000000000000000080040FFFF000000F000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
PAID="0x3800000000000035"

OO="$OO_PS4_TOOLCHAIN"
BIN="$OO/bin/windows"
ELF="$HERE/build/soh/soh.elf"
STAGE="$HERE/pkg"
OUT="${OUT_DIR:-$HERE/out}"
SOH_O2R="${SOH_O2R:-$HERE/release-pc/soh.o2r}"

[ -f "$ELF" ] || { echo "missing $ELF, build first"; exit 1; }
[ -f "$SOH_O2R" ] || { echo "missing $SOH_O2R (soh.o2r of the matching PC release)"; exit 1; }

rm -rf "$STAGE"
mkdir -p "$STAGE/sce_sys/about" "$STAGE/sce_module" "$OUT"
cp "$HERE/pkg-static/sce_sys/icon0.png" "$STAGE/sce_sys/icon0.png"
cp "$OO/samples/piglet/sce_sys/about/right.sprx" "$STAGE/sce_sys/about/right.sprx"
cp "$OO/samples/piglet/sce_module/libc.prx" "$OO/samples/piglet/sce_module/libSceFios2.prx" "$STAGE/sce_module/"
cp "$SOH_O2R" "$STAGE/soh.o2r"

# Optional self-contained package (personal use, not for sharing):
#   BUNDLE_SPRX_DIR=<dir with libScePigletv2VSH.sprx + libSceShaccVSH.sprx>
#   BUNDLE_OOT_O2R=<oot.o2r> [BUNDLE_OOT_MQ_O2R=<oot-mq.o2r>]
EXTRA_FILES=""
if [ -n "$BUNDLE_SPRX_DIR" ]; then
    mkdir -p "$STAGE/assets/misc"
    cp "$BUNDLE_SPRX_DIR/libScePigletv2VSH.sprx" "$BUNDLE_SPRX_DIR/libSceShaccVSH.sprx" "$STAGE/assets/misc/"
    EXTRA_FILES="$EXTRA_FILES assets/misc/libScePigletv2VSH.sprx assets/misc/libSceShaccVSH.sprx"
fi
if [ -n "$BUNDLE_OOT_O2R" ]; then
    cp "$BUNDLE_OOT_O2R" "$STAGE/oot.o2r"
    EXTRA_FILES="$EXTRA_FILES oot.o2r"
fi
if [ -n "$BUNDLE_OOT_MQ_O2R" ]; then
    cp "$BUNDLE_OOT_MQ_O2R" "$STAGE/oot-mq.o2r"
    EXTRA_FILES="$EXTRA_FILES oot-mq.o2r"
fi

cd "$STAGE"

"$BIN/create-fself.exe" -in="$(cygpath -m "$ELF")" -out="$(cygpath -m "$HERE/build/soh/soh.oelf")" \
    --eboot "eboot.bin" --paid "$PAID" --authinfo "$AUTHINFO"

SFO=sce_sys/param.sfo
P="$BIN/PkgTool.Core.exe"
"$P" sfo_new $SFO
"$P" sfo_setentry $SFO APP_TYPE --type Integer --maxsize 4 --value 1
"$P" sfo_setentry $SFO APP_VER --type Utf8 --maxsize 8 --value "$VERSION"
"$P" sfo_setentry $SFO ATTRIBUTE --type Integer --maxsize 4 --value 0
"$P" sfo_setentry $SFO CATEGORY --type Utf8 --maxsize 4 --value "gde"
"$P" sfo_setentry $SFO FORMAT --type Utf8 --maxsize 4 --value "obs"
"$P" sfo_setentry $SFO CONTENT_ID --type Utf8 --maxsize 48 --value "$CONTENT_ID"
"$P" sfo_setentry $SFO DOWNLOAD_DATA_SIZE --type Integer --maxsize 4 --value 0
"$P" sfo_setentry $SFO SYSTEM_VER --type Integer --maxsize 4 --value 1020
"$P" sfo_setentry $SFO TITLE --type Utf8 --maxsize 128 --value "$TITLE"
"$P" sfo_setentry $SFO TITLE_ID --type Utf8 --maxsize 12 --value "$TITLE_ID"
"$P" sfo_setentry $SFO VERSION --type Utf8 --maxsize 8 --value "$VERSION"

"$BIN/create-gp4.exe" -out pkg.gp4 --content-id="$CONTENT_ID" \
    --files "eboot.bin sce_sys/about/right.sprx sce_sys/param.sfo sce_sys/icon0.png sce_module/libc.prx sce_module/libSceFios2.prx soh.o2r$EXTRA_FILES"

"$P" pkg_build pkg.gp4 "$(cygpath -m "$OUT")"
ls -la "$OUT"
