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
| `dev-tools` | Node.js via `n`, npm globals (typescript, ts-node, turbo), Python3 |
| `cursor` | Cursor IDE (.deb) con icono custom |
| `appimages` | LM Studio |
| `system-monitor` | SystemMonitor.sh (dashboard tmux) + .desktop file |
| `gnome` | Extensiones GNOME (Caffeine, Dash to Dock, Vitals, App Menu is Back) |
| `grub` | Tema GRUB Tela (2560x1440) + GRUB Customizer |
| `post-config` | Grupo docker, servicios, Git LFS |

## Qué instala

### APT
curl, wget, p7zip, ffmpeg, net-tools, build-essential, cmake, git, git-lfs, python3, htop, nvtop, powertop, iotop, lm-sensors, tmux, google-chrome-stable, libreoffice, baobab, sublime-text, master-pdf-editor-5, vlc, obs-studio, virtualbox, docker.io, docker-compose-v2, gnome-tweaks, grub-customizer, azure-cli, google-cloud-cli, anydesk, fuentes (noto, liberation, dejavu)

### Snap
keepassxc, discord, spotify

### .deb
Cursor IDE (con icono custom sobreescrito)

### AppImage
LM Studio

### Extensiones GNOME
- **Instala**: App Menu is Back, Caffeine, Dash to Dock, Vitals
- **Habilita**: Desktop Icons NG, Ubuntu AppIndicators, Ubuntu Dock, Tiling Assistant

### GRUB
Tema Tela descargado de [vinceliuice/grub2-themes](https://github.com/vinceliuice/grub2-themes), resolución 2560x1440, timeout 20s

## Estructura

```
├── install.sh           # Script principal
├── lib/
│   ├── utils.sh         # Logging, error handling, wrappers
│   ├── repos.sh         # Repositorios y PPAs
│   ├── apt-packages.sh  # Paquetes APT
│   ├── snap-packages.sh # Snaps
│   ├── flatpak-setup.sh # Flatpak
│   ├── gnome-extensions.sh
│   ├── grub-theme.sh
│   ├── cursor-ide.sh
│   ├── appimages.sh
│   ├── dev-tools.sh
│   ├── system-monitor.sh
│   └── post-config.sh
├── SystemMonitor.sh     # Dashboard tmux (htop, powertop, nvtop, sensors, iotop)
├── SystemMonitor.png
└── cursor-icon.png      # Icono custom para Cursor IDE
```

## Notas

- El script es **idempotente**: comprueba si cada cosa ya está instalada antes de actuar
- Los fallos en una sección **no paran** el resto de la instalación
- Al final muestra un **resumen** con lo que funcionó y lo que falló
- Tras la ejecución hay que **cerrar sesión** para que los cambios de grupo (docker) y las extensiones GNOME se apliquen
- Se recomienda **reiniciar** tras la ejecución completa
