#!/bin/ash
set -eu

DATA_ROOT="${PAYMENTER_DATA_ROOT:-/data}"

mkdir -p \
  "$DATA_ROOT/var" \
  "$DATA_ROOT/storage-app" \
  "$DATA_ROOT/passport" \
  "$DATA_ROOT/themes" \
  "$DATA_ROOT/extensions"

seed_directory() {
  source_dir="$1"
  target_dir="$2"
  marker="$target_dir/.railway-seeded"

  if [ ! -f "$marker" ]; then
    if [ -d "$source_dir" ]; then
      cp -Rp "$source_dir"/. "$target_dir"/
    fi
    touch "$marker"
  fi
}

seed_directory /app/themes_default "$DATA_ROOT/themes"
seed_directory /app/extensions_default "$DATA_ROOT/extensions"

for passport_key in oauth-private.key oauth-public.key; do
  image_key="/app/storage/$passport_key"
  persisted_key="$DATA_ROOT/passport/$passport_key"

  if [ -f "$image_key" ] && [ ! -f "$persisted_key" ]; then
    mv "$image_key" "$persisted_key"
  fi

  touch "$persisted_key"
  rm -f "$image_key"
  ln -s "$persisted_key" "$image_key"
done

rm -rf /app/var /app/storage/app /app/themes /app/extensions
ln -s "$DATA_ROOT/var" /app/var
ln -s "$DATA_ROOT/storage-app" /app/storage/app
ln -s "$DATA_ROOT/themes" /app/themes
ln -s "$DATA_ROOT/extensions" /app/extensions

chown -R nginx:nginx "$DATA_ROOT"
chmod 0750 "$DATA_ROOT/var" "$DATA_ROOT/storage-app" "$DATA_ROOT/passport" "$DATA_ROOT/themes" "$DATA_ROOT/extensions"

bootstrap_paymenter() {
  while [ ! -e /app/.env ]; do
    sleep 1
  done

  until php /app/railway/bootstrap.php; do
    sleep 2
  done

  chown nginx:nginx "$DATA_ROOT/passport"/oauth-private.key "$DATA_ROOT/passport"/oauth-public.key
  chmod 0600 "$DATA_ROOT/passport"/oauth-private.key
  chmod 0660 "$DATA_ROOT/passport"/oauth-public.key
}

bootstrap_paymenter &
exec /usr/local/share/paymenter/entrypoint.sh "$@"
