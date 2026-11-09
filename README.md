# Panel Superior 100% Transparente - KDE Plasma 6 (macOS Golden Gate)

Este paquete contiene la solución técnica definitiva, ligera y 100% nativa para obtener un **panel superior totalmente transparente e invisible** en KDE Plasma 6 (Qt6 / Wayland) sin utilizar plasmoides de terceros (cero dependencias de `panel-colorizer`) ni alterar la reactividad del escritorio o de los plasmoides contenidos.

---

## 1. Fundamento Técnico y Arquitectura

En KDE Plasma 6 (`plasma-workspace` y `libplasma`), la apariencia del panel superior involucra tres subsistemas:

1. **El Motor Gráfico SVG (`KSvg::FrameSvgItem`):**
   - El panel carga `widgets/panel-background.svg` y `translucent/widgets/panel-background.svg`.
   - Si los elementos (`center`, `top`, `bottom`, `left`, `right`, esquinas y sombras) no tienen `style="opacity:0;fill:none"`, o si contienen elementos `mask-*` residuales, el motor dibuja una superficie o define un área de recorte visible.
   
2. **El Controlador de Efectos de KWin (`PanelView::updateMask`):**
   - Si el tema SVG no define un área de máscara gráfica (`mask.isEmpty()`), Plasma 6 recurre automáticamente a toda la geometría del panel:
     ```cpp
     if (mask.isEmpty()) {
         mask = QRegion(QRect(screenPanelRect));
     }
     ```
   - Si los efectos de desenfoque y contraste están activos en el tema, Plasma solicita a KWin aplicar blur y ajuste de contraste a través de `KWindowEffects::enableBlurBehind` y `KWindowEffects::enableBackgroundContrast`. Esto generaba una franja visiblemente más brillante o saturada respecto al wallpaper de fondo.

3. **La Clave Oculta de Configuración en `libplasma`:**
   - En `Plasma::ThemePrivate::processBlurBehindSettings`, KDE busca la sección exacta:
     ```ini
     [BlurBehindEffect]
     enabled=false
     ```
     *(El uso del grupo estándar `[Blur]` es ignorado por `libplasma`, activando el desenfoque por defecto).*
   - La sección `[ContrastEffect]` con `enabled=false` desactiva el tintado cromático de KWin.

4. **Paleta de Color y Contraste macOS (Texto e Iconos Blancos):**
   - En macOS, los elementos del panel superior (reloj, menú global, iconos de estado) se mantienen en color blanco para garantizar legibilidad y fidelidad estética frente al fondo de pantalla, independientemente de si el tema global del sistema conmuta entre modo Claro y Oscuro.
   - Al definir [`colors`](file:///home/cesar/Proyectos/macos-transparent-panel/theme/macOS-GoldenGate/colors) dentro del tema de Plasma con `ForegroundNormal=252,252,252`, los componentes (`Kirigami.Theme.textColor`, `PlasmaComponents3`, SVG de iconos) permanecen en blanco nítido incluso cuando las aplicaciones del sistema adoptan el esquema de color Claro diurno (`BreezeLight`).

Al combinar los elementos SVG en `opacity: 0` junto a `[BlurBehindEffect] enabled=false`, `[ContrastEffect] enabled=false` y la paleta `colors`, el panel pasa a ser **completamente invisible para el compositor**, pero mantiene todos sus applets, relojes, iconos y menús en blanco puro 100% nítidos e interactivos.

---

## 2. Contenido del Paquete

```
macos-transparent-panel/
├── install.sh                  # Script de instalación y aplicación automática
├── README.md                   # Esta documentación
├── macos-transparent-panel.tar.gz # Archivo portable comprimido
└── theme/
    └── macOS-GoldenGate/       # Tema nativo de Plasma Desktop
        ├── metadata.json       # Definición de ID y fallbackTheme
        ├── plasmarc            # Control de efectos (BlurBehindEffect, ContrastEffect)
        ├── widgets/
        │   ├── panel-background.svg
        │   └── panel-background.svgz
        └── translucent/
            └── widgets/
                ├── panel-background.svg
                └── panel-background.svgz
```

---

## 3. Modo de Uso

### Opción A: Instalación Automática (Recomendada)

Simplemente ejecuta el script `install.sh` desde el directorio extraído:

```bash
chmod +x install.sh
./install.sh
```

El script se encargará automáticamente de:
1. Copiar el tema a `~/.local/share/plasma/desktoptheme/macOS-GoldenGate/`.
2. Asignar `macOS-GoldenGate` como el tema de Plasma activo en `plasmarc`.
3. Establecer `panelOpacity=0` en `plasmashellrc`.
4. Purgar la caché de gráficos y reiniciar `plasmashell`.

---

### Opción B: Aplicación Manual en Otra Instalación

1. **Copiar la carpeta del tema:**
   ```bash
   cp -r theme/macOS-GoldenGate ~/.local/share/plasma/desktoptheme/
   ```

2. **Activar el tema en Plasma:**
   ```bash
   kwriteconfig6 --file plasmarc --group Theme --key name macOS-GoldenGate
   ```

3. **Verificar que el panel use opacidad translúcida/adaptativa:**
   En las opciones de edición del panel (clic derecho en el panel > *Configuración del panel*), asegúrate de que el estilo de opacidad esté en **Translúcido** o **Adaptativo** (y panel no flotante).
   O por comando:
   ```bash
   kwriteconfig6 --file plasmashellrc --group PlasmaViews --group "Panel <ID>" --key panelOpacity 0
   kwriteconfig6 --file plasmashellrc --group PlasmaViews --group "Panel <ID>" --key floating 0
   ```

4. **Purgar la caché y recargar plasmashell:**
   ```bash
   rm -f ~/.cache/plasma_theme* ~/.cache/*kcache*
   systemctl --user restart plasma-plasmashell.service
   ```
