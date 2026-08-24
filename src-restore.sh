#!/usr/bin/env bash
# Собирает разрезанные файлы каталога src обратно из кусков part-NNN.
#
#   ./src-restore.sh          # проверить суммы кусков, склеить, проверить целые файлы
#   ./src-restore.sh --check  # только проверить суммы кусков
#
set -euo pipefail

cd "$(dirname "$0")"

PARTS_MANIFEST=SHA256SUMS.src-parts
FILES_MANIFEST=SHA256SUMS.src-files

if [ ! -f "$PARTS_MANIFEST" ]; then
	echo "! нет $PARTS_MANIFEST — репозиторий склонирован не полностью" >&2
	exit 1
fi

echo "== проверка контрольных сумм кусков"
sha256sum -c "$PARTS_MANIFEST"

if [ "${1:-}" = "--check" ]; then
	echo "== готово: куски на месте, склейка пропущена (--check)"
	exit 0
fi

mapfile -t TARGETS < <(sed 's/^[0-9a-f]*  //' "$PARTS_MANIFEST" | sed 's/\.part-[0-9]*$//' | sort -u)

for target in "${TARGETS[@]}"; do
	echo "== склеиваю ${target}.part-* -> $target"
	cat "$target".part-* > "$target"
done

echo "== проверка контрольных сумм собранных файлов"
sha256sum -c "$FILES_MANIFEST"

echo "== готово: собрано файлов ${#TARGETS[@]}"
