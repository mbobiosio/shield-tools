#!/usr/bin/env bash
# Manage the default launcher.
#
#   ./shield-launcher.sh status
#   ./shield-launcher.sh set [package] [--disable-stock]   default package: Projectivy
#   ./shield-launcher.sh stock                            undo: re-enable + use stock launcher
#
# --disable-stock also disables the stock Android TV home screen, so the Home button
# can't fall back to it and its background work stops. If the new launcher ever breaks,
# `./shield-launcher.sh stock` from your Mac brings the stock one back.
source "$(dirname "$0")/common.sh"
require_device

status() {
  echo "Default launcher: $(home_activity)"
  if has "$STOCK_LAUNCHER" "$(pkgs -d)"; then echo "Stock launcher:   disabled"
  else echo "Stock launcher:   enabled"; fi
  echo "Available launchers:"
  ash cmd package query-activities --brief \
    -a android.intent.action.MAIN -c android.intent.category.HOME | grep '/' | sed 's/^ */  /'
}

case "${1:-status}" in
  status) status ;;

  set)
    pkg="com.spocky.projengmenu"; disable_stock=0
    shift
    for a in "$@"; do
      case "$a" in --disable-stock) disable_stock=1 ;; *) pkg="$a" ;; esac
    done
    comp=$(ash cmd package query-activities --brief \
      -a android.intent.action.MAIN -c android.intent.category.HOME \
      | sed -n "s|^[[:space:]]*\($pkg/[^[:space:]]*\).*|\1|p" | head -1)
    [ -n "$comp" ] || die "$pkg is not installed or has no launcher (HOME) activity"
    out=$(ash pm set-home-activity "$comp")
    echo "set-home-activity $comp: $out"
    if [ "$disable_stock" = 1 ]; then
      echo "Disabling stock launcher: $(ash pm disable-user --user 0 "$STOCK_LAUNCHER")"
    fi
    status
    ;;

  stock)
    echo "Enabling stock launcher: $(ash pm enable "$STOCK_LAUNCHER")"
    echo "set-home-activity: $(ash pm set-home-activity "$STOCK_LAUNCHER/.MainActivity")"
    status
    ;;

  *) die "usage: $0 status | set [package] [--disable-stock] | stock" ;;
esac
