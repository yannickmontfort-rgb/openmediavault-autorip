#!/bin/bash
set -u

OUT_DIR="${1:-/tmp/autorip-debug-$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$OUT_DIR"

run_and_save() {
  local name="$1"
  shift
  {
    echo "$ $*"
    "$@"
  } >"$OUT_DIR/$name" 2>&1
}

echo "Collecte des informations de debug dans: $OUT_DIR"

run_and_save "dpkg_status.txt" dpkg-query -W -f='${Package} ${Version} ${Status}\n' openmediavault-autorip
run_and_save "systemctl_failed.txt" systemctl --failed
run_and_save "status_omv-engined.txt" systemctl status omv-engined --no-pager
run_and_save "status_nginx.txt" systemctl status nginx --no-pager

PHP_FPM_SVC=$(systemctl list-unit-files | awk '/^php8\.[0-9]+-fpm\.service/ {print $1; exit}')
if [ -n "$PHP_FPM_SVC" ]; then
  run_and_save "status_${PHP_FPM_SVC}.txt" systemctl status "$PHP_FPM_SVC" --no-pager
fi

run_and_save "journal_omv-engined_last300.txt" journalctl -u omv-engined -n 300 --no-pager
run_and_save "journal_nginx_last300.txt" journalctl -u nginx -n 300 --no-pager
if [ -n "$PHP_FPM_SVC" ]; then
  run_and_save "journal_phpfpm_last300.txt" journalctl -u "$PHP_FPM_SVC" -n 300 --no-pager
fi

if [ -f /var/log/nginx/error.log ]; then
  tail -n 300 /var/log/nginx/error.log >"$OUT_DIR/nginx_error_tail300.log" 2>&1
fi

run_and_save "php_lint_rpc.txt" php -l /usr/share/openmediavault/engined/rpc/autorip.inc
run_and_save "php_lint_module.txt" php -l /usr/share/openmediavault/engined/module/autorip.inc
run_and_save "yaml_route.txt" cat /usr/share/openmediavault/workbench/route.d/omv-services-autorip.yaml
run_and_save "yaml_navigation.txt" cat /usr/share/openmediavault/workbench/navigation.d/omv-services-autorip.yaml
run_and_save "yaml_component_settings.txt" cat /usr/share/openmediavault/workbench/component.d/omv-services-autorip-settings-form-page.yaml
run_and_save "yaml_component_logs.txt" cat /usr/share/openmediavault/workbench/component.d/omv-services-autorip-logs-datatable-page.yaml
run_and_save "autorip_conf.txt" cat /etc/openmediavault/autorip.conf

cp /usr/share/openmediavault/engined/rpc/autorip.inc "$OUT_DIR/" 2>/dev/null || true
cp /usr/share/openmediavault/engined/module/autorip.inc "$OUT_DIR/" 2>/dev/null || true

ARCHIVE="${OUT_DIR}.tar.gz"
tar -czf "$ARCHIVE" -C "$(dirname "$OUT_DIR")" "$(basename "$OUT_DIR")"

echo "Collecte terminee."
echo "Dossier: $OUT_DIR"
echo "Archive: $ARCHIVE"
echo "Partage moi l'archive ou le contenu des fichiers journal_omv-engined_last300.txt et nginx_error_tail300.log"
