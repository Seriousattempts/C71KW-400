#!/data/data/com.termux/files/usr/bin/bash

export PATH=/data/data/com.termux/files/usr/bin:/data/data/com.termux/files/usr/sbin:$PATH
export DEBIAN_FRONTEND=noninteractive

TERMUX_HOME="/data/data/com.termux/files/home"
PREFIX="/data/data/com.termux/files/usr"
DEB_ROOT="$TERMUX_HOME/x86deb"
DEB_STABLE="$DEB_ROOT/debian-stable"
WINE_DIR="/opt/wine"
WINE_SRC="$DEB_ROOT/wine"
X11_BIN="/data/data/com.termux/files/usr/bin/termux-x11"
export HOME="$TERMUX_HOME"

log() { echo "[*] $*"; }
ok()  { echo "[+] $*"; }
warn(){ echo "[!] $*"; }
die() { echo "[x] $*"; exit 1; }

check_space() {
    local need=$1 label=$2 avail_raw avail
    avail_raw=$(df "$TERMUX_HOME" 2>/dev/null \
        | awk '{for(i=1;i<=NF;i++) if($i=="Avail") print $(i+1)}' \
        | tail -1)
    [ -z "$avail_raw" ] && \
        avail_raw=$(df "$TERMUX_HOME" 2>/dev/null | awk 'END{print $4}')
    case "$avail_raw" in
        *[Gg]) avail=$(echo "$avail_raw" | sed 's/[Gg]$//' | \
                   awk '{printf "%d", $1*1024}') ;;
        *[Mm]) avail=$(echo "$avail_raw" | sed 's/[Mm]$//' | \
                   awk '{printf "%d", $1}') ;;
        *[Kk]) avail=$(echo "$avail_raw" | sed 's/[Kk]$//' | \
                   awk '{printf "%d", $1/1024}') ;;
        ''   ) warn "Cannot read space for $label — continuing."; return 0 ;;
        *    ) avail=$(echo "$avail_raw" | tr -dc '0-9') ;;
    esac
    [ -z "$avail" ] && { warn "Cannot parse space — continuing."; return 0; }
    [ "$avail" -lt "$need" ] && \
        die "Not enough space for $label. Need ${need}MB, have ${avail}MB."
    ok "Space OK for $label (${avail}MB free)."
}

termux_clean() {
    pkg autoclean 2>/dev/null || true
    pkg clean 2>/dev/null || true
}

setup_dns() {
    local dns1 dns2
    dns1=$(getprop net.dns1 2>/dev/null)
    dns2=$(getprop net.dns2 2>/dev/null)
    [ -z "$dns1" ] && dns1="8.8.8.8"
    [ -z "$dns2" ] && dns2="8.8.4.4"
    mkdir -p "$DEB_STABLE/etc"
    printf "nameserver %s\nnameserver %s\n" "$dns1" "$dns2" \
        > "$DEB_STABLE/etc/resolv.conf"
    ok "DNS: $dns1 / $dns2"
}

run_in_debian() {
    unset LD_PRELOAD
    mkdir -p "$DEB_STABLE/tmp"
    TMPDIR=/tmp TEMP=/tmp TMP=/tmp \
    proot --link2symlink -0 -r "$DEB_STABLE" \
        -b /dev -b /proc -b /sys \
        -b "$DEB_STABLE/etc/resolv.conf:/etc/resolv.conf" \
        -b "$DEB_STABLE/data/data/com.termux/files/usr/tmp:$PREFIX/tmp" \
        -w /root \
        /usr/bin/bash -c "
            export HOME=/root
            export PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin
            export DEBIAN_FRONTEND=noninteractive
            export LANG=C.UTF-8
            export TMPDIR=/tmp TEMP=/tmp TMP=/tmp
            $1
        "
}

deb_clean() {
    run_in_debian "
        apt-get clean 2>/dev/null || true
        apt-get autoclean -y 2>/dev/null || true
        rm -rf /var/lib/apt/lists/* /tmp/* 2>/dev/null || true
    " || true
    ok "Apt cache cleaned."
}

echo "======================================"
echo "  open.sh — x86 Setup v15"
echo "======================================"

# ─────────────────────────────────────────
# STEP 1: Storage
# ─────────────────────────────────────────
log "Checking storage link..."
if [ -d "$TERMUX_HOME/storage/downloads" ]; then
    ok "Storage already linked."
else
    warn "Running termux-setup-storage — tap ALLOW."
    termux-setup-storage
    sleep 6
    [ -d "$TERMUX_HOME/storage/downloads" ] || die "Storage access denied."
    ok "Storage connected."
fi

# ─────────────────────────────────────────
# STEP 2: Termux packages
# ─────────────────────────────────────────
check_space 1400 "full install"
log "Installing Termux core packages..."
pkg update -y
pkg install -y proot debootstrap wget pulseaudio git xz-utils
log "Adding x11-repo..."
pkg install -y x11-repo && pkg install -y termux-x11-nightly
log "Installing virglrenderer-android..."
pkg install -y virglrenderer-android 2>/dev/null || \
    warn "virglrenderer-android not found — GPU unavailable."
termux_clean

if [ ! -f "$X11_BIN" ]; then
    warn "Binary not at $X11_BIN — searching..."
    FOUND=$(find "$PREFIX/bin" -name "termux-x11*" 2>/dev/null | head -1)
    [ -n "$FOUND" ] && { X11_BIN="$FOUND"; ok "Found at $X11_BIN"; } \
        || warn "Still not found — launcher will retry at runtime."
fi

# ─────────────────────────────────────────
# STEP 3: Debian armhf minbase
# ─────────────────────────────────────────
if [ -d "$DEB_STABLE" ] && [ -f "$DEB_STABLE/bin/bash" ]; then
    ok "Existing Debian found at ~/x86deb — reusing."
    warn "To force reinstall: rm -rf \"$DEB_ROOT\" then re-run."
    setup_dns
else
    log "Bootstrapping Debian armhf minbase..."
    rm -rf "$DEB_ROOT"
    mkdir -p "$DEB_ROOT"
    cd "$DEB_ROOT" || die "cd failed"
    debootstrap --arch=armhf --variant=minbase \
        --exclude=systemd,systemd-sysv \
        stable debian-stable http://ftp.debian.org/debian/ \
        || die "debootstrap failed. Check network and space."
    ok "Debian base installed."
    setup_dns
fi

mkdir -p "$DEB_STABLE/tmp/.X11-unix"
mkdir -p "$DEB_STABLE/tmp/runtime"
mkdir -p "$DEB_STABLE/data/data/com.termux/files/usr/tmp"
mkdir -p "$DEB_STABLE/storage/downloads"
mkdir -p "$DEB_STABLE/storage/shared"
chmod 1777 "$DEB_STABLE/tmp"
chmod 700  "$DEB_STABLE/tmp/runtime"
chmod 1777 "$DEB_STABLE/tmp/.X11-unix"
chmod 1777 "$DEB_STABLE/data/data/com.termux/files/usr/tmp"

# ─────────────────────────────────────────
# STEP 4: 99noninteractive
# ─────────────────────────────────────────
if [ -f "$DEB_STABLE/etc/apt/apt.conf.d/99noninteractive" ]; then
    ok "99noninteractive already written."
else
    log "Writing dpkg non-interactive config..."
    run_in_debian '
    mkdir -p /etc/apt/apt.conf.d
    cat > /etc/apt/apt.conf.d/99noninteractive << "APTEOF"
Dpkg::Options {
  "--force-confold";
  "--force-confdef";
};
APT::Get::Assume-Yes "true";
APT::Get::allow-change-held-packages "true";
APTEOF
    echo "[+] 99noninteractive written."
    '
fi

# ─────────────────────────────────────────
# STEP 5: Fake systemctl + update-binfmts
# ─────────────────────────────────────────
if [ -f "$DEB_STABLE/usr/local/bin/systemctl" ]; then
    ok "Stubs already present."
else
    run_in_debian '
    mkdir -p /usr/local/bin
    for stub in systemctl update-binfmts; do
        printf "#!/bin/sh\nexit 0\n" > /usr/local/bin/$stub
        chmod +x /usr/local/bin/$stub
    done
    echo "[+] stubs ready."
    '
fi

# ─────────────────────────────────────────
# STEP 6: CA certs
# ─────────────────────────────────────────
if [ -f "$DEB_STABLE/etc/ssl/certs/ca-certificates.crt" ]; then
    ok "CA certs already installed."
else
    log "Bootstrapping CA certs..."
    run_in_debian "dpkg --configure -a 2>/dev/null || true"
    run_in_debian '
    printf "Acquire::https::Verify-Peer \"false\";\nAcquire::https::Verify-Host \"false\";\n" \
        > /etc/apt/apt.conf.d/99insecure
    '
    run_in_debian "apt-get update -y" \
        || die "apt-get update failed. Check WiFi/data."
    run_in_debian "apt-get install -y --no-install-recommends \
        ca-certificates openssl wget gpg gpg-agent" \
        || die "CA cert install failed."
    run_in_debian "update-ca-certificates 2>/dev/null || true"
    run_in_debian "rm -f /etc/apt/apt.conf.d/99insecure"
    ok "CA certs ready."
fi

# ─────────────────────────────────────────
# STEP 7: Box86
# ─────────────────────────────────────────
check_box86() { run_in_debian "command -v box86" &>/dev/null; }

if check_box86; then
    ok "Box86 already installed."
else
    check_space 300 "Box86"
    log "Adding Box86 repo..."
    run_in_debian '
        rm -f /etc/apt/sources.list.d/box86.* \
              /usr/share/keyrings/box86-archive-keyring.gpg
        mkdir -p /usr/share/keyrings
        wget -qO- https://pi-apps-coders.github.io/box86-debs/KEY.gpg \
            | gpg --dearmor -o /usr/share/keyrings/box86-archive-keyring.gpg \
            && echo "[+] GPG key written." \
            || echo "[!] GPG key failed — using --allow-unauthenticated"
        cat > /etc/apt/sources.list.d/box86.sources << "SRCEOF"
Types: deb
URIs: https://Pi-Apps-Coders.github.io/box86-debs/debian
Suites: ./
Signed-By: /usr/share/keyrings/box86-archive-keyring.gpg
SRCEOF
    '
    run_in_debian "apt-get update -y"
    run_in_debian '
        if apt-get install -y --no-install-recommends \
                --allow-unauthenticated box86-android 2>/dev/null; then
            echo "[+] box86-android installed."
        else
            echo "[!] Falling back to box86-generic-arm..."
            apt-get install -y --no-install-recommends \
                --allow-unauthenticated box86-generic-arm \
                || { echo "[!] Both variants failed."; exit 1; }
        fi
    '
    check_box86 && ok "Box86 installed at /usr/local/bin/box86." \
        || die "Box86 not found after install."
fi

log "Verifying box86..."
run_in_debian "BOX86_NOBANNER=1 box86 2>&1 | head -2 || true"

# ─────────────────────────────────────────
# STEP 8: Debian packages
# ─────────────────────────────────────────
if [ -f "$DEB_STABLE/usr/bin/openbox" ] && \
   [ -f "$DEB_STABLE/usr/bin/xterm" ] && \
   [ -f "$DEB_STABLE/usr/bin/pcmanfm" ]; then
    ok "Core Debian packages already installed."
else
    log "Installing Debian packages..."
    run_in_debian "apt-get update -y" \
        || die "apt-get update failed."

    run_in_debian '
    apt-get install -y --no-install-recommends \
        libfreetype6 libfontconfig1 libstdc++6 libgcc-s1 \
        libxext6 libx11-6 libxrender1 libxcomposite1 libxrandr2 \
        libxcursor1 libxinerama1 tar gzip wget \
        openbox xterm dbus-x11 x11-xserver-utils x11-utils \
        pcmanfm xvkbd \
        libgl1-mesa-dri mesa-utils \
        libsdl2-2.0-0 libsdl2-mixer-2.0-0 libsdl2-image-2.0-0 libsdl2-ttf-2.0-0 \
        libopenal1 cabextract
    ' || die "Core package install failed."

    run_in_debian '
    apt-get install -y --no-install-recommends libglib2.0-0t64 2>/dev/null \
        || apt-get install -y --no-install-recommends libglib2.0-0 || true
    '
    run_in_debian '
    apt-get install -y --no-install-recommends libgnutls30t64 2>/dev/null \
        || apt-get install -y --no-install-recommends libgnutls30 || true
    '
    ok "Debian packages installed."
    deb_clean
fi

if [ -f "$DEB_STABLE/usr/local/bin/winetricks" ]; then
    ok "winetricks already installed."
else
    log "Installing winetricks from GitHub..."
    run_in_debian '
    wget -q \
        "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks" \
        -O /usr/local/bin/winetricks \
        && chmod +x /usr/local/bin/winetricks \
        && echo "[+] winetricks installed." \
        || echo "[!] winetricks download failed."
    '
fi

# ─────────────────────────────────────────
# STEP 9: Wine x86
# ─────────────────────────────────────────
check_wine() { [ -f "$WINE_SRC/bin/wine" ]; }

if check_wine; then
    ok "Wine already installed at $WINE_SRC."
else
    deb_clean
    termux_clean
    check_space 800 "Wine"

    log "Downloading Wine 11.4 x86..."
    mkdir -p "$WINE_SRC"
    wget -q --show-progress \
        'https://github.com/Kron4ek/Wine-Builds/releases/download/11.4/wine-11.4-x86.tar.xz' \
        -O "$DEB_ROOT/wine.tar.xz" \
        || die "Wine download failed. Check network."

    [ -s "$DEB_ROOT/wine.tar.xz" ] || die "Wine tarball is empty."

    log "Extracting Wine (headers excluded)..."
    xz -dc "$DEB_ROOT/wine.tar.xz" \
        | tar -xf - --strip-components=1 -C "$WINE_SRC/" \
            --exclude='*/include' \
            --exclude='*/share/man' \
        || die "Wine extraction failed."

    rm -f "$DEB_ROOT/wine.tar.xz"
    check_wine && ok "Wine installed at $WINE_SRC." \
        || die "Wine binary missing after extraction."
fi

mkdir -p "$DEB_STABLE/opt/wine"

# ─────────────────────────────────────────
# STEP 10: Box86 Wine wrappers
# ─────────────────────────────────────────
if [ -f "$DEB_STABLE/usr/local/bin/wine" ]; then
    ok "Box86 Wine wrappers already present."
else
    log "Creating Box86 Wine wrappers..."
    mkdir -p "$DEB_STABLE/usr/local/bin"
    for w in wine wineboot wineserver winecfg; do
        cat > "$DEB_STABLE/usr/local/bin/$w" << WEOF
#!/bin/bash
export BOX86_NOBANNER=1
export WINEPREFIX=\${WINEPREFIX:-/root/.wine}
export BOX86_LD_LIBRARY_PATH=$WINE_DIR/lib/wine/i386-unix/:$WINE_DIR/lib/:/lib/arm-linux-gnueabihf/:/usr/lib/arm-linux-gnueabihf/
exec box86 $WINE_DIR/bin/$w "\$@"
WEOF
        chmod +x "$DEB_STABLE/usr/local/bin/$w"
    done
    cat > "$DEB_STABLE/usr/local/bin/winefile" << WEOF
#!/bin/bash
export BOX86_NOBANNER=1
export WINEPREFIX=\${WINEPREFIX:-/root/.wine}
export BOX86_LD_LIBRARY_PATH=$WINE_DIR/lib/wine/i386-unix/:$WINE_DIR/lib/:/lib/arm-linux-gnueabihf/:/usr/lib/arm-linux-gnueabihf/
exec box86 $WINE_DIR/bin/wine explorer "\$@"
WEOF
    chmod +x "$DEB_STABLE/usr/local/bin/winefile"
    ok "Box86 wrappers created."
fi

# ─────────────────────────────────────────
# STEP 11: .exe MIME association
# ─────────────────────────────────────────
if [ -f "$DEB_STABLE/usr/share/applications/wine.desktop" ]; then
    ok "MIME associations already written."
else
    log "Registering .exe MIME association..."
    mkdir -p "$DEB_STABLE/usr/share/applications"
    cat > "$DEB_STABLE/usr/share/applications/wine.desktop" << 'DESKEOF'
[Desktop Entry]
Name=Wine Windows Program Loader
Exec=wine %f
Type=Application
Categories=Application;
MimeType=application/x-msdos-program;application/x-wine-extension-exe;
Terminal=false
NoDisplay=false
DESKEOF

    mkdir -p "$DEB_STABLE/etc/xdg"
    cat > "$DEB_STABLE/etc/xdg/mimeapps.list" << 'MIMEEOF'
[Default Applications]
application/x-msdos-program=wine.desktop
application/x-wine-extension-exe=wine.desktop
MIMEEOF

    mkdir -p "$DEB_STABLE/root/.config"
    cat > "$DEB_STABLE/root/.config/mimeapps.list" << 'MIMEEOF'
[Default Applications]
application/x-msdos-program=wine.desktop
application/x-wine-extension-exe=wine.desktop
MIMEEOF
    ok ".exe MIME association written."
fi

# ─────────────────────────────────────────
# STEP 12: pcmanfm config
# ─────────────────────────────────────────
mkdir -p "$DEB_STABLE/root/.config/pcmanfm/default"
cat > "$DEB_STABLE/root/.config/pcmanfm/default/pcmanfm.conf" << 'PCMEOF'
[config]
bm_open_method=0
single_click=1

[volume]
mount_on_startup=0
mount_removable=0
autorun=0
PCMEOF

# ─────────────────────────────────────────
# STEP 13: /root/.bashrc
# ─────────────────────────────────────────
cat > "$DEB_STABLE/root/.bashrc" << 'BASHRCEOF'
export PS1='\[\033[01;32m\]x86\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
export DISPLAY=:0
export PULSE_SERVER=127.0.0.1
export WINEPREFIX=/root/.wine
export BOX86_NOBANNER=1
export WINEDEBUG=-all
export LANG=C.UTF-8
export SDL_VIDEODRIVER=x11
export SDL_AUDIODRIVER=pulse

alias ls='ls --color=auto'
alias ll='ls -la'

winedl() { wine "/storage/downloads/$1"; }

winedx() {
    echo "[*] Installing DirectX + VC++ via winetricks..."
    echo "[*] This will take a long time. Do not close."
    for pkg in vcrun2019 d3dx9_43 d3dx11_43 d3dcompiler_47; do
        echo "[*] winetricks: $pkg ..."
        DISPLAY=:0 WINEPREFIX=/root/.wine winetricks -q $pkg \
            && echo "[+] $pkg done" || echo "[!] $pkg failed (non-fatal)"
    done
    echo "[+] DirectX install complete."
}

wine_run() {
    local exe="$1"
    cd "$(dirname "$exe")" && wine "$(basename "$exe")"
}

wine_debug() {
    local exe="$1"
    cd "$(dirname "$exe")" && \
    BOX86_LOG=1 BOX86_SHOWSEGV=1 \
    WINEDEBUG=+loaddll,+module wine "$(basename "$exe")" \
        2>&1 | tee /storage/downloads/wine_debug.log
}

wine_compat() {
    local exe="$1"
    cd "$(dirname "$exe")" && \
    BOX86_DYNAREC=0 BOX86_LOG=1 \
    WINEDEBUG=warn+all wine "$(basename "$exe")"
}

cd /storage/downloads 2>/dev/null || cd /root

echo ""
echo "  ── x86 Terminal ─────────────────────────────────"
echo "  winedl  \"file.exe\"       ← run from Downloads"
echo "  wine_run \"path/file.exe\" ← sets correct CWD"
echo "  wine_compat \"path/file\"  ← if nothing opens"
echo "  wine_debug \"path/file\"   ← see all errors"
echo "  winedx                   ← install DirectX/VC++"
echo "  ─────────────────────────────────────────────────"
echo ""
BASHRCEOF
ok ".bashrc written."

# ─────────────────────────────────────────
# STEP 14: wineboot-init.sh
# ─────────────────────────────────────────
cat > "$DEB_STABLE/root/wineboot-init.sh" << 'WBEOF'
#!/bin/bash
export DISPLAY=:0
export WINEPREFIX=/root/.wine
export BOX86_NOBANNER=1
export BOX86_LOG=0
export BOX86_DYNAREC=1
export BOX86_DYNAREC_STRONGMEM=1
export WINEDEBUG=-all
export PATH=/opt/wine/bin:/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Wine First-Time Prefix Init"
echo "  This takes 2-5 minutes. Do NOT close."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "[*] Running wineboot --init ..."
wine wineboot --init 2>/dev/null
echo ""
echo "[+] wineboot complete."
touch /root/.wineboot-done
echo "[+] Closing in 3 seconds..."
sleep 3
WBEOF
chmod +x "$DEB_STABLE/root/wineboot-init.sh"

if [ -f "$DEB_STABLE/root/.wineboot-done" ]; then
    ok "wineboot already completed — will skip on launch."
else
    ok "wineboot-init.sh written — runs on first launch."
fi

# ─────────────────────────────────────────
# STEP 15: Openbox config + menu
#
# Uses Clearlooks — built into openbox.
# No git clone required.
# ─────────────────────────────────────────
if [ -f "$DEB_STABLE/root/.config/openbox/rc.xml" ]; then
    ok "Openbox config already written."
else
    log "Writing Openbox config..."
    mkdir -p "$DEB_STABLE/root/.config/openbox"

    cat > "$DEB_STABLE/root/.config/openbox/rc.xml" << 'RCEOF'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc">
  <theme>
    <name>Clearlooks</name>
    <titleLayout>NMC</titleLayout>
  </theme>
  <desktops>
    <number>1</number>
    <names><name>x86</name></names>
  </desktops>
  <focus>
    <focusNew>yes</focusNew>
    <followMouse>no</followMouse>
    <focusLast>yes</focusLast>
    <underMouse>no</underMouse>
    <focusDelay>0</focusDelay>
    <raiseOnFocus>no</raiseOnFocus>
  </focus>
  <placement>
    <policy>Smart</policy>
  </placement>
  <keyboard>
    <keybind key="C-F2">
      <action name="ShowMenu"><menu>root-menu</menu></action>
    </keybind>
    <keybind key="A-F4">
      <action name="Close"/>
    </keybind>
  </keyboard>
  <mouse>
    <context name="Root">
      <mousebind button="Right" action="Press">
        <action name="ShowMenu"><menu>root-menu</menu></action>
      </mousebind>
    </context>
    <context name="Titlebar">
      <mousebind button="Left" action="Press">
        <action name="Focus"/><action name="Raise"/>
      </mousebind>
      <mousebind button="Left" action="Drag">
        <action name="Move"/>
      </mousebind>
      <mousebind button="Left" action="DoubleClick">
        <action name="ToggleMaximizeFull"/>
      </mousebind>
    </context>
    <context name="Close">
      <mousebind button="Left" action="Click">
        <action name="Close"/>
      </mousebind>
    </context>
    <context name="Maximize">
      <mousebind button="Left" action="Click">
        <action name="ToggleMaximizeFull"/>
      </mousebind>
    </context>
    <context name="Minimize">
      <mousebind button="Left" action="Click">
        <action name="Iconify"/>
      </mousebind>
    </context>
    <context name="Frame">
      <mousebind button="Left" action="Press">
        <action name="Focus"/><action name="Raise"/>
      </mousebind>
    </context>
  </mouse>
</openbox_config>
RCEOF

    cat > "$DEB_STABLE/root/.config/openbox/menu.xml" << 'MENUEOF'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_menu xmlns="http://openbox.org/3.4/menu">
  <menu id="root-menu" label="x86">
    <item label="Terminal">
      <action name="Execute"><execute>xterm -e bash</execute></action>
    </item>
    <item label="File Manager (Downloads)">
      <action name="Execute"><execute>pcmanfm /storage/downloads</execute></action>
    </item>
    <separator/>
    <item label="Wine Explorer">
      <action name="Execute"><execute>winefile</execute></action>
    </item>
    <item label="Wine Config">
      <action name="Execute"><execute>winecfg</execute></action>
    </item>
    <item label="Install DirectX + VC++">
      <action name="Execute">
        <execute>xterm -e bash -c "winedx; read -p 'Press Enter to close'"</execute>
      </action>
    </item>
    <separator/>
    <item label="On-Screen Keyboard">
      <action name="Execute"><execute>xvkbd</execute></action>
    </item>
    <separator/>
    <item label="Exit Openbox">
      <action name="Exit"/>
    </item>
  </menu>
</openbox_menu>
MENUEOF
    ok "Openbox config written."
fi

# ─────────────────────────────────────────
# STEP 16: PulseAudio
# ─────────────────────────────────────────
if ! command -v pulseaudio &>/dev/null; then
    pkg install pulseaudio -y
fi

# ─────────────────────────────────────────
# STEP 17: Termux:Boot script
# ─────────────────────────────────────────
mkdir -p "$TERMUX_HOME/.termux/boot"
cat > "$TERMUX_HOME/.termux/boot/start-open.sh" << 'BOOTEOF'
#!/data/data/com.termux/files/usr/bin/bash
export HOME=/data/data/com.termux/files/home
export PATH=/data/data/com.termux/files/usr/bin:/data/data/com.termux/files/usr/sbin:$PATH
termux-wake-lock
pulseaudio --start \
    --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" \
    --exit-idle-time=-1 2>/dev/null
BOOTEOF
chmod +x "$TERMUX_HOME/.termux/boot/start-open.sh"
ok "Boot script written."

# ─────────────────────────────────────────
# STEP 18: Launcher ~/open
#
# KEY FACTS from device testing:
#
# 1. termux-x11 is a shell script Loader
#    client — the X server runs inside the
#    Android app. am start must fire first
#    so the service is running before the
#    Loader tries to connect.
#
# 2. X11 uses abstract Unix sockets only.
#    No socket file ever appears on the
#    filesystem. /proc/net/unix is
#    permission denied from shell.
#    There is NO way to detect readiness.
#
# 3. The .X11-unix bind mount IS required.
#    Not for the socket file (there is none)
#    but because Xlib checks that the
#    directory /tmp/.X11-unix EXISTS before
#    attempting the abstract socket connect.
#    Without the directory, Xlib skips
#    abstract sockets entirely and fails
#    with "Can't open display: %s".
#    We bind an empty dir just to satisfy
#    this Xlib directory existence check.
#
# 4. Widget mode logs to ~/open.log.
#    Monitor via: tail -f ~/open.log
#
# 5. Delayed second am start fires after
#    proot/openbox/xterm are up so the
#    compositor has real content to show.
# ─────────────────────────────────────────
cat > "$TERMUX_HOME/open" << 'LAUNCHEOF'
#!/data/data/com.termux/files/usr/bin/bash
export PATH=/data/data/com.termux/files/usr/bin:/data/data/com.termux/files/usr/sbin:$PATH
export HOME=/data/data/com.termux/files/home
export TMPDIR=/data/data/com.termux/files/usr/tmp

DEB="/data/data/com.termux/files/home/x86deb/debian-stable"
WINE_SRC="/data/data/com.termux/files/home/x86deb/wine"
PREFIX="/data/data/com.termux/files/usr"
WINE_DIR="/opt/wine"
X11_BIN="/data/data/com.termux/files/usr/bin/termux-x11"
LOG="$HOME/open.log"

# Widget has no TTY — redirect all output to log
if [ ! -t 1 ]; then
    exec >> "$LOG" 2>&1
    echo ""
    echo "========================================"
    echo "  $(date)  — widget launch"
    echo "========================================"
fi

log() { echo "[*] $*"; }
ok()  { echo "[+] $*"; }
warn(){ echo "[!] $*"; }

# ── PulseAudio ────────────────────────────
start_pa() {
    pgrep -x pulseaudio &>/dev/null && { ok "PulseAudio running."; return; }
    log "Starting PulseAudio..."
    pulseaudio --start \
        --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" \
        --exit-idle-time=-1 2>/dev/null
    ok "PulseAudio started."
}

# ── VirGL ────────────────────────────────
start_virgl() {
    if ! command -v virgl_test_server_android &>/dev/null; then
        warn "virgl_test_server_android not found — GPU unavailable."
        return 1
    fi
    if pgrep -f "virgl_test_server" &>/dev/null && \
       [ -S "$TMPDIR/.virgl_test" ]; then
        ok "VirGL already running."; return 0
    fi
    pkill -f "virgl_test_server" 2>/dev/null; sleep 1
    log "Starting VirGL..."
    virgl_test_server_android &
    local elapsed=0
    while [ "$elapsed" -lt 10 ]; do
        [ -S "$TMPDIR/.virgl_test" ] && { ok "VirGL ready."; return 0; }
        sleep 1; elapsed=$((elapsed + 1))
    done
    warn "VirGL socket not ready — software fallback."
    return 1
}

# ── X11 ──────────────────────────────────
# Sequence:
#   1. am start — launches Android app/service
#   2. sleep    — let service initialize
#   3. Loader   — connects to running service
#   4. sleep    — let X server initialize
# The .X11-unix bind mount below does NOT
# carry a socket. It only makes the directory
# exist inside proot so Xlib can find it and
# attempt the abstract socket connection.
start_x11() {
    [ -f "$X11_BIN" ] || { warn "termux-x11 not found."; exit 1; }

    pkill -f proot 2>/dev/null
    pkill -f "termux-x11" 2>/dev/null
    sleep 2

    log "Launching Termux:X11 Android app..."
    am start \
        -n com.termux.x11/.MainActivity \
        --activity-clear-top \
        2>/dev/null || true
    sleep 4

    log "Connecting X server Loader..."
    unset LD_PRELOAD
    "$X11_BIN" :0 -ac 2>/dev/null &
    sleep 4

    ok "X11 ready."
}

# ════════════════════════════════════════
# LAUNCH SEQUENCE
# ════════════════════════════════════════
log "Starting PulseAudio..."
start_pa

log "Starting VirGL..."
start_virgl
VIRGL_READY=$?

log "Starting X11..."
start_x11

# Ensure .X11-unix directory exists on Termux side
# so the bind mount source path is valid
mkdir -p "$TMPDIR/.X11-unix"
mkdir -p "$DEB/tmp/.X11-unix"
mkdir -p "$DEB/tmp/runtime"
mkdir -p "$DEB/data/data/com.termux/files/usr/tmp"
mkdir -p "$HOME/storage/downloads" "$HOME/storage/shared" 2>/dev/null || true
mkdir -p "$DEB/opt/wine"

VIRGL_BIND=""
[ "$VIRGL_READY" -eq 0 ] && [ -S "$TMPDIR/.virgl_test" ] && \
    VIRGL_BIND="-b $TMPDIR/.virgl_test:/tmp/.virgl_test"

if [ -n "$VIRGL_BIND" ]; then
    GPU_DRIVER="virpipe"
    ok "GPU: VirGL (virpipe)"
else
    GPU_DRIVER="softpipe"
    warn "GPU: softpipe (software fallback)"
fi

# Second am start fires after desktop is live
# so compositor shows real content, not a
# blank surface. This is the widget fix.
( sleep 12 && am start \
    -n com.termux.x11/.MainActivity \
    --activity-clear-top \
    2>/dev/null ) &

log "Entering x86 session (GPU=$GPU_DRIVER)..."
unset LD_PRELOAD

TMPDIR=/tmp TEMP=/tmp TMP=/tmp \
proot --link2symlink -0 -r "$DEB" \
    -b /dev -b /proc -b /sys \
    -b "$DEB/etc/resolv.conf:/etc/resolv.conf" \
    -b "$DEB/data/data/com.termux/files/usr/tmp:$PREFIX/tmp" \
    -b "$TMPDIR/.X11-unix:/tmp/.X11-unix" \
    -b "$HOME/storage/downloads:/storage/downloads" \
    -b "$HOME/storage/shared:/storage/shared" \
    -b "$WINE_SRC:$WINE_DIR" \
    $VIRGL_BIND \
    -w /root \
    /usr/bin/bash -c "
        export HOME=/root
        export PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin
        export DISPLAY=:0
        export PULSE_SERVER=127.0.0.1
        export WINEPREFIX=/root/.wine
        export BOX86_NOBANNER=1
        export BOX86_LOG=0
        export BOX86_DYNAREC=1
        export BOX86_DYNAREC_STRONGMEM=1
        export BOX86_DYNAREC_SAFEFLAGS=1
        export BOX86_SHOWSEGV=0
        export WINEDEBUG=-all
        export LANG=C.UTF-8
        export TMPDIR=/tmp TEMP=/tmp TMP=/tmp
        export XDG_RUNTIME_DIR=/tmp/runtime
        export XDG_SESSION_TYPE=x11
        export SDL_VIDEODRIVER=x11
        export SDL_AUDIODRIVER=pulse
        export GALLIUM_DRIVER=$GPU_DRIVER
        export MESA_GL_VERSION_OVERRIDE=4.3COMPAT
        export MESA_GLES_VERSION_OVERRIDE=3.2
        export MESA_NO_ERROR=1
        export BOX86_LD_LIBRARY_PATH=$WINE_DIR/lib/wine/i386-unix/:$WINE_DIR/lib/:/lib/arm-linux-gnueabihf/:/usr/lib/arm-linux-gnueabihf/

        mkdir -p /tmp/runtime && chmod 700 /tmp/runtime
        mkdir -p /root/.wine/drive_c

        # wineboot — first time only
        if [ ! -f /root/.wineboot-done ]; then
            xterm -title 'Wine Setup — do not close' \
                  -fa 'Monospace' -fs 12 \
                  -e /root/wineboot-init.sh
        fi

        openbox &
        sleep 2

        if command -v pcmanfm &>/dev/null; then
            if [ -d /storage/downloads ] && \
               ls /storage/downloads &>/dev/null 2>&1; then
                pcmanfm /storage/downloads &
            else
                pcmanfm /root &
            fi
        fi

        exec xterm -title 'x86 Terminal' -fa 'Monospace' -fs 11 -e bash
    "
LAUNCHEOF
chmod +x "$TERMUX_HOME/open"
ok "Launcher ~/open written."

# ─────────────────────────────────────────
# STEP 19: deb.sh — bare Debian login
# ─────────────────────────────────────────
cat > "$TERMUX_HOME/deb.sh" << 'DEBEOF'
#!/data/data/com.termux/files/usr/bin/bash
export PATH=/data/data/com.termux/files/usr/bin:/data/data/com.termux/files/usr/sbin:$PATH
export HOME=/data/data/com.termux/files/home
export TMPDIR=/data/data/com.termux/files/usr/tmp

DEB="/data/data/com.termux/files/home/x86deb/debian-stable"
WINE_SRC="/data/data/com.termux/files/home/x86deb/wine"
PREFIX="/data/data/com.termux/files/usr"
mkdir -p "$DEB/tmp" "$DEB/opt/wine"

unset LD_PRELOAD
TMPDIR=/tmp TEMP=/tmp TMP=/tmp \
exec proot --link2symlink -0 -r "$DEB" \
    -b /dev -b /proc -b /sys \
    -b "$DEB/etc/resolv.conf:/etc/resolv.conf" \
    -b "$DEB/data/data/com.termux/files/usr/tmp:$PREFIX/tmp" \
    -b "$WINE_SRC:/opt/wine" \
    -w /root \
    /usr/bin/bash -c "
        export HOME=/root
        export PATH=/opt/wine/bin:/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin
        export TMPDIR=/tmp
        export LANG=C.UTF-8
        exec bash --login
    "
DEBEOF
chmod +x "$TERMUX_HOME/deb.sh"
ok "Bare login ~/deb.sh written."

# ─────────────────────────────────────────
# STEP 20: Termux:Widget shortcuts
# ─────────────────────────────────────────
mkdir -p "$TERMUX_HOME/.shortcuts"
chmod 700 "$TERMUX_HOME/.shortcuts"
cat > "$TERMUX_HOME/.shortcuts/open.sh" << 'SHORTEOF'
#!/data/data/com.termux/files/usr/bin/bash
export PATH=/data/data/com.termux/files/usr/bin:/data/data/com.termux/files/usr/sbin:$PATH
export HOME=/data/data/com.termux/files/home
bash /data/data/com.termux/files/home/open
SHORTEOF
chmod +x "$TERMUX_HOME/.shortcuts/open.sh"

mkdir -p "$TERMUX_HOME/.termux/widget/dynamic_shortcuts"
chmod 700 "$TERMUX_HOME/.termux/widget/dynamic_shortcuts"
cat > "$TERMUX_HOME/.termux/widget/dynamic_shortcuts/open.sh" << 'DYNEOF'
#!/data/data/com.termux/files/usr/bin/bash
export PATH=/data/data/com.termux/files/usr/bin:/data/data/com.termux/files/usr/sbin:$PATH
export HOME=/data/data/com.termux/files/home
bash /data/data/com.termux/files/home/open
DYNEOF
chmod +x "$TERMUX_HOME/.termux/widget/dynamic_shortcuts/open.sh"
ok "Widget shortcuts written."

# ─────────────────────────────────────────
# DONE
# ─────────────────────────────────────────
echo ""
log "Finished - v15"
log "One of two things need to happen"
log "Either:"
log "Needs to be used with adb unless a better understanding of termux-x11 is noted"
log "Open x11"
log "connect to android device via adb"
log "Run bash /data/data/com.termux/files/home/open"
log "Or:
log "Go to the home screen"
log "Open Widget termux app"
log "Refresh widget, create shortcut"
log "Go to the home screen"
log "Press and hold the termux widget app and select open.sh"
"
sleep 3
