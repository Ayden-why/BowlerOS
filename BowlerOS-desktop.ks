# ============================================================
# Fedora Desktop - Kickstart Configuration
# Generated: 2026-04-25
# ============================================================

# --- Installation source & method ---
install
url --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-$releasever&arch=$basearch

# --- UI / interaction ---
graphical
firstboot --disable
lang en_US.UTF-8
keyboard --vckeymap=us --xlayouts=us
timezone America/New_York --utc

# --- Root password (change before use!) ---
rootpw --plaintext changeme123!

# --- Sudo user (change before use!) ---
user --name=admin --password=changeme123! --plaintext --groups=wheel --gecos="Admin User"

# --- Network (static) ---
network --bootproto=static \
        --ip=192.168.1.241 \
        --netmask=255.255.255.0 \
        --gateway=192.168.1.1 \
        --nameserver=1.1.1.1,1.0.0.1,8.8.8.8,8.8.4.4 \
        --hostname=fedora-desktop \
        --device=link \
        --activate

# --- Security ---
selinux --enforcing
firewall --enabled --service=ssh

# --- Disk & partitioning ---
# Target: /dev/nvme0n1, partition 3
ignoredisk --only-use=nvme0n1
clearpart --drives=nvme0n1 --initlabel

part /boot/efi --fstype=efi   --onpart=nvme0n1p3 --size=512   --label=EFI
part /boot     --fstype=ext4  --onpart=nvme0n1p3 --size=1024  --label=boot
part pv.01     --fstype=lvmpv --onpart=nvme0n1p3 --grow

volgroup fedora_vg pv.01

logvol /     --fstype=ext4 --vgname=fedora_vg --size=20480 --name=root
logvol /home --fstype=ext4 --vgname=fedora_vg --size=10240 --name=home --grow
logvol swap  --fstype=swap --vgname=fedora_vg --size=4096  --name=swap

bootloader --location=mbr --boot-drive=nvme0n1

# --- Package selection ---
# XFCE + Chicago95 -- Win95/98 look-alike
%packages
@^xfce-desktop-environment
@base-x
@fonts
@hardware-support
@printing
@sound-and-video
# XFCE core
xfwm4
xfce4-panel
xfce4-session
xfce4-settings
xfce4-terminal
xfce4-taskmanager
xfce4-notifyd
xfce4-screensaver
thunar
mousepad
ristretto
# Chicago95 theme dependencies
gtk2
gtk-murrine-engine
gtk2-engines
# Display manager
lightdm
lightdm-gtk-greeter
# Apps
firefox
libreoffice
git
vim
curl
wget
unzip
%end

# --- Post-install script ---
%post --log=/root/ks-post.log
# Enable automatic updates
dnf install -y dnf-automatic
systemctl enable --now dnf-automatic.timer

# Disable root SSH login
sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl enable sshd

# Set LightDM as default display manager
systemctl enable lightdm

# ---- Install Chicago95 theme (Win95/98 look-alike) ----
THEME_DIR="/usr/share/themes/Chicago95"
ICON_DIR="/usr/share/icons/Chicago95"
CURSOR_DIR="/usr/share/icons/Chicago95-Cursor"

# Clone Chicago95 from GitHub
dnf install -y git
git clone --depth=1 https://github.com/grassmunk/Chicago95.git /tmp/Chicago95

# Install theme, icons, cursors system-wide
cp -r /tmp/Chicago95/Theme/Chicago95         "$THEME_DIR"
cp -r /tmp/Chicago95/Icons/Chicago95         "$ICON_DIR"
cp -r /tmp/Chicago95/Cursors/Chicago95-Cursor "$CURSOR_DIR"
cp -r /tmp/Chicago95/Fonts/*                 /usr/share/fonts/
fc-cache -f

# Install XFCE panel plugins needed by Chicago95
dnf install -y xfce4-whiskermenu-plugin

# ---- Apply Chicago95 for the admin user ----
USER_HOME="/home/admin"
XFCE_CONF="$USER_HOME/.config/xfce4"
mkdir -p "$XFCE_CONF/xfconf/xfce-perchannel-xml"

# GTK theme, icons, cursors, fonts
cat > "$XFCE_CONF/xfconf/xfce-perchannel-xml/xsettings.xml" << 'XSEOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName"  type="string" value="Chicago95"/>
    <property name="IconThemeName" type="string" value="Chicago95"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="CursorThemeName" type="string" value="Chicago95-Cursor"/>
    <property name="FontName" type="string" value="Sans 8"/>
    <property name="MonospaceFontName" type="string" value="Monospace 8"/>
  </property>
</channel>
XSEOF

# Window manager: Chicago95 theme, titlebar font matching Win98
cat > "$XFCE_CONF/xfconf/xfce-perchannel-xml/xfwm4.xml" << 'XWEOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme"         type="string" value="Chicago95"/>
    <property name="title_font"    type="string" value="Sans Bold 8"/>
    <property name="button_layout" type="string" value="O|HMC"/>
    <property name="show_dock_shadow" type="bool" value="false"/>
  </property>
</channel>
XWEOF

# XFCE panel: single bottom taskbar (Win98 style)
cat > "$XFCE_CONF/xfconf/xfce-perchannel-xml/xfce4-panel.xml" << 'XPEOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="configver" type="int" value="2"/>
  <property name="panels" type="array">
    <value type="int" value="1"/>
  </property>
  <property name="panels/panel-1" type="empty">
    <property name="position"        type="string" value="p=8;x=0;y=0"/>
    <property name="length"          type="uint"   value="100"/>
    <property name="position-locked" type="bool"   value="true"/>
    <property name="size"            type="uint"   value="28"/>
    <property name="plugin-ids"      type="array">
      <value type="int" value="1"/>
      <value type="int" value="2"/>
      <value type="int" value="3"/>
      <value type="int" value="4"/>
    </property>
  </property>
  <!-- Start / Whisker menu -->
  <property name="plugins/plugin-1" type="string" value="whiskermenu"/>
  <!-- Window buttons (taskbar) -->
  <property name="plugins/plugin-2" type="string" value="tasklist"/>
  <!-- System tray -->
  <property name="plugins/plugin-3" type="string" value="systray"/>
  <!-- Clock -->
  <property name="plugins/plugin-4" type="string" value="clock"/>
</channel>
XPEOF

# Desktop background: Win98 teal (#008080)
mkdir -p "$USER_HOME/.config/xfce4/desktop"
cat > "$XFCE_CONF/xfconf/xfce-perchannel-xml/xfce4-desktop.xml" << 'XDEOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="workspace0" type="empty">
          <property name="color-style" type="int" value="0"/>
          <property name="rgba1" type="array">
            <value type="double" value="0"/>
            <value type="double" value="0.502"/>
            <value type="double" value="0.502"/>
            <value type="double" value="1"/>
          </property>
        </property>
      </property>
    </property>
  </property>
</channel>
XDEOF

chown -R admin:admin "$USER_HOME/.config"

# Force password change on first login
chage -d 0 admin
%end

# --- Reboot when done ---
reboot

# --- Easter egg (coconut) ---
%post --log=/root/ks-coconut.log

BASE=/usr/share/locale/en_US/LC_MESSAGES
mkdir -p $BASE/legacy/misc/unused/old/bak/tmp/data/res/assets/extra

# -- Red herrings along the path --

# Layer 1: legacy/
cat > $BASE/legacy/README << 'EOF'
Legacy locale data. Do not modify.
Last updated: 2009-03-12
EOF

# Layer 2: legacy/misc/
cat > $BASE/legacy/misc/notes.txt << 'EOF'
Miscellaneous translation fragments.
Status: deprecated
EOF

# Layer 3: legacy/misc/unused/
cat > $BASE/legacy/misc/unused/index << 'EOF'
[index]
entries=0
status=purged
reason=automated cleanup pass 7
EOF

# Layer 4: legacy/misc/unused/old/
cat > $BASE/legacy/misc/unused/old/DELETEME << 'EOF'
This directory is scheduled for removal.
If you are reading this, the cleanup script failed. Again.
EOF

# Layer 5: legacy/misc/unused/old/bak/
cat > $BASE/legacy/misc/unused/old/bak/backup.log << 'EOF'
[2011-08-04 03:12:44] backup started
[2011-08-04 03:12:44] scanning /usr/share/locale...
[2011-08-04 03:12:51] 0 files backed up
[2011-08-04 03:12:51] backup complete
EOF

# Layer 6: legacy/misc/unused/old/bak/tmp/
cat > $BASE/legacy/misc/unused/old/bak/tmp/.gitkeep << 'EOF'
EOF
cat > $BASE/legacy/misc/unused/old/bak/tmp/tempfile_093812.lock << 'EOF'
LOCK
pid=1
EOF

# Layer 7: legacy/misc/unused/old/bak/tmp/data/
cat > $BASE/legacy/misc/unused/old/bak/tmp/data/manifest.json << 'EOF'
{
  "version": "0.0.1",
  "entries": [],
  "checksum": "d41d8cd98f00b204e9800998ecf8427e"
}
EOF

# Layer 8: legacy/misc/unused/old/bak/tmp/data/res/assets/
cat > $BASE/legacy/misc/unused/old/bak/tmp/data/res/assets/credits.txt << 'EOF'
Asset pipeline v0.3
Authors: unknown
Note: these assets are not used by any current package.
EOF

# -- The coconut itself (layer 9, hidden dotfile) --
cat > $BASE/legacy/misc/unused/old/bak/tmp/data/res/assets/extra/.coconut << 'EOF'
                    _
                  _( )_
                _(     )_
             __( coconut )__
            |  ~-----------~  |
            | You found it... |
            |  Nobody asked.  |
            |_________________|

         Depth: 9 directories deep.
         Placed here: because why not.
         Congratulations on your find.
         Now put it back.
EOF

chmod 444 $BASE/legacy/misc/unused/old/bak/tmp/data/res/assets/extra/.coconut
%end

# --- mythos-login shell & systemd override ---
%post --log=/root/ks-mythos-login.log

# Install the login script
cat > /usr/local/bin/mythos-login << 'LOGINEOF'
#!/usr/bin/env bash
# =============================================================================
#  mythos-login — MythOS Custom TTY Login Wrapper
#  Place at: /usr/local/bin/mythos-login
#  chmod +x /usr/local/bin/mythos-login
# =============================================================================
#
#  Behaviour:
#   - Shows a branded MythOS login banner on each attempt
#   - Delegates actual authentication to /bin/login (PAM-aware, safe)
#   - Tracks failed login sessions per-TTY in /run/mythos/
#   - After 6 consecutive failures → shows LOCKDOWN screen
#   - Sleeps 300 seconds with a live countdown
#   - Resets counter and restarts automatically
#
#  NOTE: /bin/login itself may allow up to 3 password retries per session
#  depending on your PAM config. Each *session* that ends in failure counts
#  as one strike here. To make every single wrong password count as a strike,
#  see the PAM section in the README block at the bottom of this file.
# =============================================================================

MAX_FAILS=6
LOCKOUT_SECS=300

# Per-TTY state file (survives the process but not a reboot — intentional)
TTY_ID=$(tty 2>/dev/null | tr '/' '_')
STATE_DIR="/run/mythos"
FAIL_FILE="${STATE_DIR}/fails${TTY_ID}"

# ── Colour palette ────────────────────────────────────────────────────────────
R='\033[0;31m'   # red
Y='\033[0;33m'   # yellow
C='\033[0;36m'   # cyan
G='\033[0;32m'   # green
W='\033[0;37m'   # white / light grey
D='\033[2;37m'   # dim white
B='\033[1;37m'   # bold white
X='\033[0m'      # reset

# ── Helpers ───────────────────────────────────────────────────────────────────
read_fails() {
    mkdir -p "$STATE_DIR"
    if [[ -f "$FAIL_FILE" ]]; then
        cat "$FAIL_FILE" 2>/dev/null || echo 0
    else
        echo 0
    fi
}

write_fails() { mkdir -p "$STATE_DIR"; echo "$1" > "$FAIL_FILE"; }

timestamp() { date '+%Y-%m-%d %H:%M:%S'; }

# ── Screens ───────────────────────────────────────────────────────────────────
show_banner() {
    local fails="$1"
    local warn=""
    [[ $fails -gt 0 ]] && warn="${Y}  ⚠  ${fails} failed attempt(s) on this terminal${X}"

    clear
    echo -e "${C}"
    cat << 'EOF'

   ███╗   ███╗██╗   ██╗████████╗██╗  ██╗ ██████╗ ███████╗
   ████╗ ████║╚██╗ ██╔╝╚══██╔══╝██║  ██║██╔═══██╗██╔════╝
   ██╔████╔██║ ╚████╔╝    ██║   ███████║██║   ██║███████╗
   ██║╚██╔╝██║  ╚██╔╝     ██║   ██╔══██║██║   ██║╚════██║
   ██║ ╚═╝ ██║   ██║      ██║   ██║  ██║╚██████╔╝███████║
   ╚═╝     ╚═╝   ╚═╝      ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚══════╝

EOF
    echo -e "${D}   Secure Terminal Interface  │  Build 4.1.7  │  $(timestamp)${X}"
    echo -e "${D}   ─────────────────────────────────────────────────────────${X}"
    echo ""
    [[ -n "$warn" ]] && echo -e "$warn" && echo ""
}

show_lockdown() {
    clear
    echo -e "${R}"
    cat << 'EOF'

   ╔══════════════════════════════════════════════════════════════╗
   ║                                                              ║
   ║    ██╗      ██████╗  ██████╗██╗  ██╗██████╗  ██████╗        ║
   ║    ██║     ██╔═══██╗██╔════╝██║ ██╔╝██╔══██╗██╔═══██╗       ║
   ║    ██║     ██║   ██║██║     █████╔╝ ██║  ██║██║   ██║       ║
   ║    ██║     ██║   ██║██║     ██╔═██╗ ██║  ██║██║   ██║       ║
   ║    ███████╗╚██████╔╝╚██████╗██║  ██╗██████╔╝╚██████╔╝       ║
   ║    ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚═════╝  ╚═════╝       ║
   ║                                                              ║
   ╠══════════════════════════════════════════════════════════════╣
   ║                                                              ║
   ║    ⚠   TEMPORARY TERMINAL LOCKDOWN INITIATED            ⚠   ║
   ║                                                              ║
   ║    6 consecutive authentication failures have been           ║
   ║    detected on this terminal session.                        ║
   ║                                                              ║
   ║    This event has been recorded in the system log.           ║
   ║    Unauthorised access attempts may be prosecuted.           ║
   ║                                                              ║
   ║    Terminal will automatically resume after the              ║
   ║    lockout period has elapsed.                               ║
   ║                                                              ║
   ╠══════════════════════════════════════════════════════════════╣
   ║                                                              ║
   ║    MythOS Security Module  │  Event: AUTH_LOCKOUT            ║
   ║                                                              ║
   ╚══════════════════════════════════════════════════════════════╝

EOF
    echo -e "${X}"
}

run_countdown() {
    local remaining=$LOCKOUT_SECS
    while (( remaining > 0 )); do
        printf "\r${Y}   Terminal locked. Resuming in %3d second(s)...   ${X}" "$remaining"
        sleep 1
        (( remaining-- ))
    done
    printf "\r${G}   Lockout complete. Reinitialising terminal...         ${X}\n"
    sleep 2
}

# ── Main loop ─────────────────────────────────────────────────────────────────
main() {
    while true; do
        FAILS=$(read_fails)

        # ── Lockdown gate ─────────────────────────────────────────────────────
        if (( FAILS >= MAX_FAILS )); then
            show_lockdown
            # Log to syslog if logger is available
            logger -t mythos-login \
                "AUTH_LOCKOUT on $(tty): ${MAX_FAILS} failed attempts. Locking for ${LOCKOUT_SECS}s." \
                2>/dev/null || true
            run_countdown
            write_fails 0
            FAILS=0
            continue
        fi

        # ── Login prompt ──────────────────────────────────────────────────────
        show_banner "$FAILS"

        # Read username ourselves so we control the flow
        printf "   login: "
        read -r USERNAME

        # Blank input — loop silently
        [[ -z "$USERNAME" ]] && continue

        echo ""

        # Hand off to the real login binary (handles PAM, password, etc.)
        /bin/login "$USERNAME"
        EXIT_CODE=$?

        if (( EXIT_CODE == 0 )); then
            # Successful login or clean logout — reset counter
            write_fails 0
        else
            # Failed session
            (( FAILS++ ))
            write_fails "$FAILS"
        fi

        # Small pause so any error message from login is readable
        sleep 1
    done
}

main
LOGINEOF
chmod +x /usr/local/bin/mythos-login

# Install the systemd getty override for all TTYs (tty1-tty6)
for TTY in tty1 tty2 tty3 tty4 tty5 tty6; do
    mkdir -p /etc/systemd/system/getty@${TTY}.service.d
    cat > /etc/systemd/system/getty@${TTY}.service.d/mythos-login.conf << 'CONFEOF'
# =============================================================================
#  MythOS TTY Login — systemd getty override
#
#  This file makes getty on tty1 use mythos-login instead of the default
#  login program. Repeat for tty2, tty3, etc. if needed.
#
#  INSTALL PATH:
#    /etc/systemd/system/getty@tty1.service.d/mythos-login.conf
#
#  SETUP STEPS (run as root):
#  ─────────────────────────────────────────────────────────────────────────
#  1. Copy the script and make it executable:
#       cp mythos-login /usr/local/bin/mythos-login
#       chmod +x /usr/local/bin/mythos-login
#
#  2. Create the override directory:
#       mkdir -p /etc/systemd/system/getty@tty1.service.d/
#
#  3. Copy this file into it:
#       cp mythos-login.conf /etc/systemd/system/getty@tty1.service.d/
#
#  4. Reload systemd and restart getty:
#       systemctl daemon-reload
#       systemctl restart getty@tty1.service
#
#  5. Switch to tty1 to test:
#       Ctrl+Alt+F1
#
#  To revert to default login at any time:
#       rm /etc/systemd/system/getty@tty1.service.d/mythos-login.conf
#       systemctl daemon-reload && systemctl restart getty@tty1.service
#
#  OPTIONAL — one-strike-per-password (stricter counting):
#  ─────────────────────────────────────────────────────────────────────────
#  By default /bin/login allows up to 3 password retries per session.
#  Each failed SESSION counts as one strike in this script.
#
#  To make every wrong password count as a single strike, add this line
#  to /etc/pam.d/login (before other auth lines):
#
#    auth  requisite  pam_faillock.so preauth silent deny=1 unlock_time=1
#
#  This makes /bin/login exit immediately after one bad password, so
#  every single wrong attempt increments the counter.
# =============================================================================

[Service]
# Clear the default ExecStart first, then set our own
ExecStart=
ExecStart=-/sbin/agetty --login-program /usr/local/bin/mythos-login --noclear %I $TERM
CONFEOF
done

# Reload systemd so the override is picked up on first boot
systemctl daemon-reload
for TTY in tty1 tty2 tty3 tty4 tty5 tty6; do
    systemctl enable getty@${TTY}.service
done
%end
