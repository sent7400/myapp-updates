#!/bin/bash

# Detect root user (or the user running the script)
ROOT_USER=$(whoami)
ROOT_HOME=$(eval echo "~$ROOT_USER")

LOG_FILE="$ROOT_HOME/update_log.txt"
exec > >(tee -a "$LOG_FILE") 2>&1  # Redirect stdout and stderr to log file

echo "============================="
echo "Update check started at: $(date)"
echo "User: $ROOT_USER"
echo "Home Directory: $ROOT_HOME"
echo "============================="

APP_DIR="$ROOT_HOME/capunit"
CURRENT_VERSION_FILE="$APP_DIR/version.txt"
VERSION_URL="https://raw.githubusercontent.com/sent7400/myapp-updates/main/version.json"
EXAMPLE_FILE="$ROOT_HOME/example.txt"
WAYFIRE_CONFIG="$ROOT_HOME/.config/wayfire.ini"

# Ensure jq is installed
if ! command -v jq &> /dev/null; then
    echo "❌ Error: jq is not installed! Install it using 'sudo apt-get install jq'."
    exit 1
fi

# Ensure the capunit directory exists
if [ ! -d "$APP_DIR" ]; then
    echo "Creating capunit directory."
    mkdir -p "$APP_DIR"
fi

# Ensure example.txt file exists and populate it
if [ ! -f "$EXAMPLE_FILE" ]; then
    echo "Creating example.txt with default values."
    cat <<EOF > "$EXAMPLE_FILE"
{
  "serialNumber": "12345ABC",
  "macAddress": "MyWiFiNetwork"
}
EOF
fi

# Ensure Wayfire configuration exists and update it
if [ ! -d "$ROOT_HOME/.config" ]; then
    echo "Creating Wayfire configuration directory."
    mkdir -p "$ROOT_HOME/.config"
fi
if [ ! -f "$WAYFIRE_CONFIG" ]; then
    echo "Creating wayfire.ini file."
    touch "$WAYFIRE_CONFIG"
fi
if ! grep -q "1 = $APP_DIR/capunit" "$WAYFIRE_CONFIG"; then
    echo "Adding auto-start and window rules to wayfire.ini."
    cat <<EOL >> "$WAYFIRE_CONFIG"

[autostart]
1 = $APP_DIR/capunit

[window-rules]
1 = on created if type is "toplevel" then maximize
2 = on created if type is "toplevel" then start_on_output "HDMI-A-2"
rule_1 = on created if app_id is "capunit" then fullscreen
rule_2 = on created if app_id is "capunit" then set no_border
rule_3 = on created if app_id is "capunit" then set skip_taskbar
rule_4 = on created if app_id is "capunit" then set always_on_top
EOL
fi

# Remaining script continues as-is...
