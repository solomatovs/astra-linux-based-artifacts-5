#!/usr/bin/env bash
# Собирает архив из кусков и загружает образы в docker.
#
#   ./restore.sh            # склеить, проверить sha256 и docker load
#   ./restore.sh --no-load  # только склеить архив, без загрузки
#
set -euo pipefail

cd "$(dirname "$0")"

PARTS_DIR=parts
ARCHIVE=rust-images.tar.zst
LOAD=1

[ "${1:-}" = "--no-load" ] && LOAD=0

if [ ! -d "$PARTS_DIR" ]; then
	echo "! нет каталога $PARTS_DIR — репозиторий склонирован не полностью" >&2
	exit 1
fi

echo "== проверка контрольных сумм кусков"
sha256sum -c SHA256SUMS.parts

echo "== склеиваю $PARTS_DIR/${ARCHIVE}.part-* -> $ARCHIVE"
cat "$PARTS_DIR/${ARCHIVE}".part-* > "$ARCHIVE"

echo "== проверка контрольной суммы архива"
sha256sum -c SHA256SUMS.archive

if [ "$LOAD" = "0" ]; then
	echo "== готово: $ARCHIVE (загрузка пропущена, --no-load)"
	exit 0
fi

echo "== docker load (распаковка потоком, промежуточный tar на диск не пишется)"
zstd -dc "$ARCHIVE" | docker load

echo "== загруженные образы"
docker images | grep '^dmp/rust' || true
