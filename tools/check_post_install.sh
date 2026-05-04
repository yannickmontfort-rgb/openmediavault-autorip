#!/bin/bash
set -u

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

pass() {
  echo -e "${GREEN}[PASS]${NC} $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
  WARN_COUNT=$((WARN_COUNT + 1))
}

fail() {
  echo -e "${RED}[FAIL]${NC} $1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

check_file() {
  local path="$1"
  if [ -f "$path" ]; then
    pass "Fichier present: $path"
  else
    fail "Fichier manquant: $path"
  fi
}

check_service_active() {
  local svc="$1"
  if systemctl is-active --quiet "$svc"; then
    pass "Service actif: $svc"
  else
    fail "Service inactif: $svc"
  fi
}

check_service_enabled() {
  local svc="$1"
  if systemctl is-enabled --quiet "$svc" 2>/dev/null; then
    pass "Service active au boot: $svc"
  else
    warn "Service non active au boot: $svc"
  fi
}

echo "== Verification post-install openmediavault-autorip =="

if dpkg-query -W -f='${Status}' openmediavault-autorip 2>/dev/null | grep -q "install ok installed"; then
  pass "Paquet Debian installe: openmediavault-autorip"
else
  fail "Paquet Debian non installe: openmediavault-autorip"
fi

check_file "/usr/share/openmediavault/engined/rpc/autorip.inc"
check_file "/usr/share/openmediavault/engined/module/autorip.inc"
check_file "/usr/share/openmediavault/workbench/route.d/omv-services-autorip.yaml"
check_file "/usr/share/openmediavault/workbench/navigation.d/omv-services-autorip.yaml"
check_file "/usr/share/openmediavault/workbench/component.d/omv-services-autorip-settings-form-page.yaml"
check_file "/usr/share/openmediavault/workbench/component.d/omv-services-autorip-logs-datatable-page.yaml"
check_file "/etc/openmediavault/autorip.conf"
check_file "/etc/systemd/system/autorip.service"
check_file "/etc/udev/rules.d/99-dvd-autorip.rules"

if command -v php >/dev/null 2>&1; then
  if php -l /usr/share/openmediavault/engined/rpc/autorip.inc >/dev/null 2>&1; then
    pass "Syntaxe PHP valide: rpc/autorip.inc"
  else
    fail "Erreur syntaxe PHP: rpc/autorip.inc"
  fi

  if php -l /usr/share/openmediavault/engined/module/autorip.inc >/dev/null 2>&1; then
    pass "Syntaxe PHP valide: module/autorip.inc"
  else
    fail "Erreur syntaxe PHP: module/autorip.inc"
  fi
else
  warn "php introuvable: verification syntaxe PHP ignoree"
fi

if command -v python3 >/dev/null 2>&1; then
  python3 - <<'PY' >/dev/null 2>&1
import json
with open('/etc/openmediavault/autorip.conf', 'r', encoding='utf-8') as f:
    cfg = json.load(f)
required = ['enable', 'device', 'share_path', 'tmp_dir', 'min_length', 'eject_after', 'notify_email']
for key in required:
    if key not in cfg:
        raise SystemExit(1)
PY
  if [ $? -eq 0 ]; then
    pass "Configuration JSON valide: /etc/openmediavault/autorip.conf"
  else
    fail "Configuration invalide ou incomplete: /etc/openmediavault/autorip.conf"
  fi

  if ls /srv/autorip/*.py >/dev/null 2>&1; then
    if python3 -m py_compile /srv/autorip/*.py >/dev/null 2>&1; then
      pass "Syntaxe Python valide: /srv/autorip/*.py"
    else
      fail "Erreur syntaxe Python dans /srv/autorip/*.py"
    fi
  else
    warn "Aucun fichier Python trouve dans /srv/autorip"
  fi
else
  warn "python3 introuvable: verification JSON/Python ignoree"
fi

check_service_active "omv-engined"
check_service_active "nginx"

if systemctl list-unit-files | grep -q '^php8\\.[0-9]-fpm.service'; then
  PHP_FPM_SVC=$(systemctl list-unit-files | awk '/^php8\.[0-9]-fpm.service/ {print $1; exit}')
  check_service_active "$PHP_FPM_SVC"
else
  warn "Service php-fpm non detecte automatiquement"
fi

check_service_enabled "autorip.service"

if systemctl is-active --quiet autorip.service; then
  pass "Service actif: autorip.service"
else
  warn "Service inactif: autorip.service (normal si aucun DVD n'est insere selon ton workflow)"
fi

echo
echo "--- Resume ---"
echo "PASS: $PASS_COUNT"
echo "WARN: $WARN_COUNT"
echo "FAIL: $FAIL_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo
  echo "Des checks critiques ont echoue."
  echo "Logs utiles:"
  echo "  journalctl -u omv-engined -n 200 --no-pager"
  echo "  tail -n 200 /var/log/nginx/error.log"
  exit 1
fi

echo
if [ "$WARN_COUNT" -gt 0 ]; then
  echo "Verification terminee avec avertissements."
else
  echo "Verification terminee sans erreur."
fi
exit 0
