#!/bin/bash
# decode.sh — Decode semua file bash obfuscate di folder
# Usage: ./decode.sh /path/ke/folder

FOLDER="$1"

if [ -z "$FOLDER" ]; then
  echo "Usage: $0 /path/ke/folder"
  exit 1
fi

if [ ! -d "$FOLDER" ]; then
  echo "Folder $FOLDER tidak ditemukan"
  exit 1
fi

OUTPUT="$HOME/decoded"
mkdir -p "$OUTPUT"

echo "========================================="
echo "  DECODE FOLDER: $FOLDER"
echo "  OUTPUT: $OUTPUT"
echo "========================================="
echo ""

COUNT=0

for file in "$FOLDER"/*; do
  [ -f "$file" ] || continue

  NAMA=$(basename "$file")

  # Cek apakah file mengandung 'eval'
  if grep -q "^eval" "$file" 2>/dev/null; then
    echo "✅ Decode: $NAMA"

    # Langkah 1: ganti eval jadi echo
    sed 's/^eval/echo/' "$file" > "$OUTPUT/$NAMA.step1"

    # Langkah 2: jalankan untuk resolve variabel
    bash "$OUTPUT/$NAMA.step1" > "$OUTPUT/$NAMA.decoded" 2>/dev/null

    # Hapus file step1
    rm -f "$OUTPUT/$NAMA.step1"

    COUNT=$((COUNT+1))
  else
    echo "⏭️  Skip: $NAMA (bukan bash obfuscate)"
  fi
done

echo ""
echo "========================================="
echo "  SELESAI — $COUNT file didecode"
echo "  Hasil di: $OUTPUT"
echo "========================================="