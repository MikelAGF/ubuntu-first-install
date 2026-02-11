# Ubuntu 24.04 Fresh Install Script

Script modular para automatizar la configuración completa de un Ubuntu 24.04 LTS recién instalado.

## Uso rápido

```bash
# Clonar el repo
git clone https://github.com/MikelAGF/ubuntu-first-install.git
cd ubuntu-first-install

# Ver qué haría sin ejecutar nada
./install.sh --dry-run

# Ejecutar todo
./install.sh

# Ejecutar solo una sección
./install.sh --section repos

# Ejecutar varias secciones
./install.sh --section repos,apt,snaps

# Ver secciones disponibles
./install.sh --list
```

## Secciones

| Sección | Descripción |
|---------|-------------|
| `repos` | PPAs, repositorios y GPG keys |
| `apt` | Paquetes APT (Chrome, LibreOffice, Docker, VLC, OBS, Sublime, etc.) |
| `snaps` | KeePassXC, Discord, Spotify |
| `flatpak` | Flatpak + Flathub remote |
| `dev-tools` | Node.js via `n`, npm globals (typescript, ts-node, turbo), Python3, **pyenv**, **GitHub CLI** |
| `cursor` | Cursor IDE (.deb) con icono custom + **perfil automático** |
| `appimages` | LM Studio |
| `system-monitor` | SystemMonitor.sh (dashboard tmux) + .desktop file |
| `gnome` | Extensiones GNOME (**Caffeine**, Dash to Dock, Vitals, App Menu is Back) |
| `gnome-settings` | Restaurar Settings GNOME (dconf: keybindings, tema, teclado, etc.) |
| `grub` | Tema GRUB Tela (2560x1440) + GRUB Customizer |
| `system-optimization` | **Timeshift** (snapshots), **TRIM SSD**, **swappiness**, **zswap** |
| `datadisk` | Montaje automático DataDisk NTFS en fstab (remove_hiberfile) |
| `post-config` | Grupo docker, servicios, Git LFS, **cleanup**, **verificación** |

## Qué instala

### APT
curl, wget, p7zip, ffmpeg, net-tools, build-essential, cmake, git, git-lfs, python3, htop, nvtop, powertop, iotop, lm-sensors, tmux, google-chrome-stable, libreoffice, baobab, sublime-text, master-pdf-editor-5, vlc, obs-studio, virtualbox, docker.io, docker-compose-v2, gnome-tweaks, grub-customizer, azure-cli, google-cloud-cli, anydesk, fuentes (noto, liberation, dejavu)

### Snap
keepassxc, discord, spotify

### .deb
Cursor IDE (con icono custom sobreescrito)

### Extensiones del editor (VSCode / Cursor)
Para las extensiones del editor: instala **VSCode**, haz la importación sincronizando en VSCode desde **GitHub** y en **Cursor** sincroniza/importa desde VSCode.

### AppImage
LM Studio

### Extensiones GNOME
- **Instala**: App Menu is Back, **Caffeine**, Dash to Dock, Vitals, OpenWeather, Soft Brightness Plus, Status Area Spacing
- **Habilita**: Apps Menu, Desktop Icons NG (DING), Places Menu, Tiling Assistant, Ubuntu AppIndicators, User Theme
- **Desactiva**: Ubuntu Dock (usa Dash to Dock en su lugar)

### GRUB
Tema Tela descargado de [vinceliuice/grub2-themes](https://github.com/vinceliuice/grub2-themes), resolución 2560x1440, timeout 20s

## Exportar y restaurar tu configuración GNOME (y estado de extensiones)

Para que en otra instalación (o en este PC tras reinstalar) queden **las mismas extensiones activadas/desactivadas y sus configuraciones** (Caffeine, Dash to Dock, etc.), así como tema, keybindings y teclado:

1. **En este PC** (con las extensiones y la configuración ya como quieres):
   ```bash
   ./export-my-settings.sh
   git add config/dconf-gnome.ini
   git commit -m "Update dconf backup (GNOME + extensiones)"
   ```
2. **En la instalación nueva** (o al ejecutar solo extensiones):
   - `./install.sh --section gnome` instala las extensiones y **aplica el estado guardado** (activadas/desactivadas y configs) si existe `config/dconf-gnome.ini`.
   - `./install.sh --section gnome-settings` restaura todo el dconf (tema, teclado, keybindings, etc.).

El backup incluye **extensiones** (lista enabled/disabled y configs en `[shell/extensions/...]`) y el resto de **dconf** bajo `/org/gnome/`. Ver `config/README.md` para más detalle.

## Estructura

```
├── install.sh             # Script principal
├── export-my-settings.sh  # Exportar dconf en tu Ubuntu actual → config/dconf-gnome.ini
├── config/
│   ├── README.md          # Instrucciones del backup dconf
│   └── dconf-gnome.ini    # (lo creas con export-my-settings.sh)
├── lib/
│   ├── utils.sh
│   ├── repos.sh
│   ├── apt-packages.sh
│   ├── snap-packages.sh
│   ├── flatpak-setup.sh
│   ├── gnome-extensions.sh
│   ├── dconf-settings.sh  # Restaurar dconf desde config/dconf-gnome.ini
│   ├── grub-theme.sh
│   ├── cursor-ide.sh
│   ├── appimages.sh
│   ├── dev-tools.sh
│   ├── system-monitor.sh
│   └── post-config.sh
├── SystemMonitor.sh
├── SystemMonitor.png
└── cursor-icon.png
```

## Optimizaciones del sistema

### Timeshift (Snapshots)
Instala Timeshift para crear puntos de restauración del sistema:
```bash
./install.sh system-optimization
# Configura después con: sudo timeshift-gtk
```

### SSD Optimization
- **TRIM automático**: Habilita `fstrim.timer` (ejecución semanal)
- **Verificación de noatime**: Informa si falta en `/etc/fstab`

### Swap Optimization
- **swappiness=10**: Reduce escrituras en swap (mejor para SSD)
- **zswap**: Compresión de swap en RAM antes de escribir a disco (efectivo tras reinicio)

## Sistema de logging

Todos los logs se guardan automáticamente en:
```
~/.cache/ubuntu-install-logs/install-YYYYMMDD-HHMMSS.log
```

Útil para debugging si algo falla.

## Post-config improvements

La sección `post-config` ahora incluye:
- **Cleanup**: `apt autoremove`, `apt clean`, limpieza de snaps antiguos
- **Verificación**: Comprueba que servicios críticos (docker, comandos) funcionan

## Automatizar el montaje del DataDisk (NTFS)

Si usas un disco NTFS (p. ej. `/dev/sda2`) montado en `/media/mikel/DataDisk` y Windows deja el disco en estado de hibernación, Ubuntu puede encargarse de limpiar y montar el disco al arrancar.

**El script lo hace por ti**: al ejecutar `./install.sh` (o `./install.sh --section post-config`) se configura automáticamente el montaje en `/etc/fstab` si el disco `/dev/sda2` existe. Para ejecutar solo esta parte: `./install.sh --section datadisk`. Puedes cambiar el dispositivo con `DATADISK_DEV=/dev/sdXY ./install.sh --section datadisk`.

### 1. Opción recomendada: montaje automático con fstab

1. **Obtén el UUID del disco**:
   ```bash
   lsblk -d -no UUID /dev/sda2
   ```
   Copia el código (ej. `A6C421CEC421A213`).

2. **Edita el archivo de montajes**:
   ```bash
   sudo nano /etc/fstab
   ```
   Añade al final (sustituye `TU_UUID_AQUÍ` por el UUID que copiaste):
   ```
   UUID=TU_UUID_AQUÍ /media/mikel/DataDisk ntfs-3g defaults,rw,remove_hiberfile 0 0
   ```
   La opción `remove_hiberfile` hace que Ubuntu intente limpiar el bloqueo en cada arranque.

3. **Guarda y sal**: `Ctrl+O`, Enter, `Ctrl+X`.

### 2. Alias (acceso rápido manual)

Si prefieres no tocar fstab y montar el disco solo cuando lo necesites:

1. Abre la configuración de la terminal:
   ```bash
   nano ~/.bashrc
   ```
2. Ve al final y pega:
   ```bash
   alias montardisco='sudo ntfs-3g -o remove_hiberfile /dev/sda2 /media/mikel/DataDisk'
   ```
3. Guarda (`Ctrl+O`, Enter, `Ctrl+X`) y recarga:
   ```bash
   source ~/.bashrc
   ```
   A partir de entonces, el comando `montardisco` ejecutará el montaje.

### Recomendación

Prueba primero **Reiniciar** en Windows después de ejecutar `powercfg /h off`. Si el problema continúa, la opción de **fstab** (paso 1) es la más cómoda porque evitas el problema en cada arranque.

## Notas

- El script es **idempotente**: comprueba si cada cosa ya está instalada antes de actuar
- Los fallos en una sección **no paran** el resto de la instalación
- Al final muestra un **resumen** con lo que funcionó y lo que falló
- **Los logs se guardan** automáticamente en `~/.cache/ubuntu-install-logs/`
- Tras la ejecución hay que **cerrar sesión** para que los cambios de grupo (docker) y las extensiones GNOME se apliquen
- Se recomienda **reiniciar** tras la ejecución completa (especialmente para activar zswap)
