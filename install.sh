#!/usr/bin/env bash
# ==============================================================================
# Script de Instalación / Exportación del Panel Superior 100% Transparente
# KDE Plasma 6.x (Qt6 / Wayland) - macOS Golden Gate Style
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_SRC="${SCRIPT_DIR}/theme/macOS-GoldenGate"
THEME_DEST="${HOME}/.local/share/plasma/desktoptheme/macOS-GoldenGate"

echo "==> [1/5] Verificando dependencias..."
for cmd in kwriteconfig6 kreadconfig6 systemctl; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: Comando '$cmd' no encontrado en el sistema." >&2
        exit 1
    fi
done

echo "==> [2/5] Desplegando tema de escritorio 'macOS-GoldenGate'..."
mkdir -p "${HOME}/.local/share/plasma/desktoptheme"
rm -rf "${THEME_DEST}"
cp -r "${THEME_SRC}" "${THEME_DEST}"

echo "==> [3/5] Configurando 'macOS-GoldenGate' como tema activo de Plasma..."
kwriteconfig6 --file plasmarc --group Theme --key name macOS-GoldenGate

echo "==> [4/5] Ajustando opacidad nativa del panel en plasmashellrc..."
# Buscar los paneles configurados en plasmashellrc y asegurar opacidad adaptativa/transparente
if [ -f "${HOME}/.config/plasmashellrc" ]; then
    panels=$(grep -oE '\[PlasmaViews\]\[Panel [0-9]+\]' "${HOME}/.config/plasmashellrc" | sed 's/\[PlasmaViews\]\[Panel //;s/\]//' | sort -u || true)
    for p in $panels; do
        # Asegurar panelOpacity=0 (Translucent/Adaptive) y floating=0 para paneles pegados al borde superior
        kwriteconfig6 --file plasmashellrc --group PlasmaViews --group "Panel ${p}" --key panelOpacity 0
    done
fi

echo "==> [5/5] Purgando caché de temas y reiniciando plasmashell..."
rm -f "${HOME}"/.cache/plasma_theme* "${HOME}"/.cache/*kcache* 2>/dev/null || true

if systemctl --user is-active plasma-plasmashell.service >/dev/null 2>&1; then
    systemctl --user restart plasma-plasmashell.service
    echo "==> Esperando confirmación de plasmashell..."
    sleep 2
    if systemctl --user is-active plasma-plasmashell.service >/dev/null 2>&1; then
        echo "==> ¡Completado con éxito! El panel es ahora 100% transparente sin efectos de blur ni tintado."
    else
        echo "Advertencia: plasmashell tardó en iniciar. Verifica con 'systemctl --user status plasma-plasmashell'."
    fi
else
    # En caso de sesiones no gestionadas por systemd
    kquitapp6 plasmashell 2>/dev/null || killall plasmashell 2>/dev/null || true
    kstart plasmashell >/dev/null 2>&1 &
    echo "==> ¡Completado con éxito!"
fi
