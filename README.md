# astra-linux-based-artifacts-5 — образы `dmp/rust`

Экспорт docker-образов rust-тулчейна из проекта [astra-linux-based](https://github.com/solomatovs/astra-linux-based)
(каталог `rust/`). Цепочка собирается на голом Astra Linux: первое звено `1.90.0` —
через mrustc (C++, без бинарного rustc), дальше обычный bootstrap `x.py`,
где rustc N-1 собирает rustc N.

Первое звено — сутки сборки, поэтому образы удобнее перенести, чем пересобирать.
Собственно ради этого репозиторий и существует.

## Что внутри

12 тегов (`IMAGES.txt` — точный список с ID и датами сборки):

| тег | назначение |
|---|---|
| `dmp/rust:<ver>` | готовый образ с установленным тулчейном |
| `dmp/rust:<ver>-dist` | дистрибутив (собранное, но не установленное в систему) — из него берётся stage0 для следующего звена |

Версии: 1.90.0, 1.91.0, 1.92.0, 1.93.0, 1.94.0, 1.95.0.

## Формат хранения

Все 12 тегов сохранены **одним** `docker save`, поэтому общие слои лежат в архиве
в одном экземпляре: 10 ГБ образов → 1.9 ГБ после zstd. Архив разрезан на куски
по 45 МБ (`parts/`), потому что GitHub не принимает файлы больше 100 МБ.

```
parts/rust-images.tar.zst.part-000 ... part-042   43 куска, 45 МБ каждый
SHA256SUMS.parts                                  контрольные суммы кусков
SHA256SUMS.archive                                контрольная сумма склеенного архива
IMAGES.txt                                        список тегов
restore.sh                                        склейка + docker load
```

## Восстановление

```bash
git clone https://github.com/solomatovs/astra-linux-based-artifacts-5.git
cd astra-linux-based-artifacts-5
./restore.sh
```

Скрипт проверит суммы, склеит куски и выполнит `docker load`. Понадобится `zstd`
и порядка 4 ГБ свободного места под архив (образы в docker — сверх этого, ~4 ГБ
с учётом общих слоёв).

Только склеить архив, без загрузки в docker:

```bash
./restore.sh --no-load
```

Вручную то же самое:

```bash
sha256sum -c SHA256SUMS.parts
cat parts/rust-images.tar.zst.part-* > rust-images.tar.zst
sha256sum -c SHA256SUMS.archive
zstd -dc rust-images.tar.zst | docker load
```

## Проверка

```bash
docker run --rm dmp/rust:1.95.0 rustc --version
```

## Каталог `src` — разрезанные файлы

GitHub не принимает файлы больше 100 МБ, поэтому всё, что в `src` тяжелее 80 МБ,
лежит кусками рядом с исходным путём:

```
src/chainlit-2.11.1.tar.gz                                   3.8 МБ, целиком
src/chainlit-ui-store-2.11.1.tar.gz.part-000 ... part-002    3 куска, 200 МБ
SHA256SUMS.src-parts                                         контрольные суммы кусков
SHA256SUMS.src-files                                         контрольные суммы собранных файлов
src-restore.sh                                               склейка с проверкой сумм
```

Собранные файлы перечислены в `.gitignore` — в репозитории живут только куски.

```bash
./src-restore.sh            # проверить куски, склеить, проверить результат
./src-restore.sh --check    # только проверить куски
```

Вручную то же самое:

```bash
sha256sum -c SHA256SUMS.src-parts
cat src/chainlit-ui-store-2.11.1.tar.gz.part-* > src/chainlit-ui-store-2.11.1.tar.gz
sha256sum -c SHA256SUMS.src-files
```

## Оговорка

Хранить гигабайты бинарников в git — плохая идея: репозиторий не ужимается
(содержимое уже сжато), история необратимо тяжёлая, клон тянет всё целиком.
Правильное место для такого — container registry или GitHub Releases / LFS.
Здесь это сделано осознанно, как разовый перенос.
