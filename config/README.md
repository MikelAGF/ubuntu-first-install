# Config backup (dconf)

This folder holds your GNOME settings backup so they can be restored on a fresh install.

## Export your current settings

On your **current** Ubuntu (with your keybindings, dark mode, keyboard layout, etc. already set):

```bash
./export-my-settings.sh
```

This creates `config/dconf-gnome.ini`. Then add and commit it:

```bash
git add config/dconf-gnome.ini
git commit -m "Add dconf backup (GNOME settings)"
```

## Restore on a new install

When you run the main install script (or only the gnome-settings section), it will load this file if present:

```bash
./install.sh --section gnome-settings
# or run full install (gnome-settings runs after gnome extensions)
./install.sh
```

Restored settings include: keybindings, keyboard layout and options, appearance (dark/light theme, accent), desktop, windows, and other GNOME Settings under `/org/gnome/`.
