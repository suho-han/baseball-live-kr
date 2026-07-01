#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if (($# == 0)); then
  set -- \
    "$ROOT_DIR/.xcode/DerivedData/Build/Products" \
    "$ROOT_DIR/.build/macmini-runtime" \
    "$ROOT_DIR/.build/transfer"
fi

found=0

is_official_asset_path() {
  case "$1" in
    *TeamBrandAssets*|*TeamWordmarks*|*TeamLogos*|*logo*|*wordmark*|*emblem*|*mascot*|*HH.png|*HT.png|*KT.png|*LG.png|*LT.png|*NC.png|*OB.png|*SK.png|*SS.png|*WO.png)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

for target in "$@"; do
  [[ -e "$target" ]] || continue

  while IFS= read -r path; do
    printf '%s\n' "$path"
    found=1
  done < <(
    find "$target" \( \
      -iname '*TeamBrandAssets*' -o \
      -iname '*TeamWordmarks*' -o \
      -iname '*TeamLogos*' -o \
      -iname '*logo*' -o \
      -iname '*wordmark*' -o \
      -iname '*emblem*' -o \
      -iname '*mascot*' -o \
      -iname 'HH.png' -o \
      -iname 'HT.png' -o \
      -iname 'KT.png' -o \
      -iname 'LG.png' -o \
      -iname 'LT.png' -o \
      -iname 'NC.png' -o \
      -iname 'OB.png' -o \
      -iname 'SK.png' -o \
      -iname 'SS.png' -o \
      -iname 'WO.png' \
    \) -print 2>/dev/null | sort
  )

  while IFS= read -r archive; do
    [[ -f "$archive" ]] || continue
    case "$archive" in
      *.tar.gz|*.tgz)
        while IFS= read -r member; do
          if is_official_asset_path "$member"; then
            printf '%s:%s\n' "$archive" "$member"
            found=1
          fi
        done < <(tar -tzf "$archive" 2>/dev/null || true)
        ;;
      *.zip)
        while IFS= read -r member; do
          if is_official_asset_path "$member"; then
            printf '%s:%s\n' "$archive" "$member"
            found=1
          fi
        done < <(unzip -Z1 "$archive" 2>/dev/null || true)
        ;;
    esac
  done < <(find "$target" -type f \( -iname '*.tar.gz' -o -iname '*.tgz' -o -iname '*.zip' \) -print 2>/dev/null | sort)
done

if ((found)); then
  printf 'Official visual asset risk found in release/staged artifacts.\n' >&2
  exit 1
fi

printf 'No official visual asset filenames found in release/staged artifacts.\n'
