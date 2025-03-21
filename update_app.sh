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

# Fetch latest update info
echo "Fetching update info from: $VERSION_URL"
LATEST_INFO=$(curl -s "$VERSION_URL")

# Validate JSON response
if ! echo "$LATEST_INFO" | jq . > /dev/null 2>&1; then
    echo "❌ Error: Invalid JSON received from GitHub!"
    echo "Response: $LATEST_INFO"
    exit 1
fi

# Extract version and URL
LATEST_VERSION=$(echo "$LATEST_INFO" | jq -r '.version')
LATEST_URL=$(echo "$LATEST_INFO" | jq -r '.url')

# Ensure version and URL are not empty
if [ -z "$LATEST_VERSION" ] || [ -z "$LATEST_URL" ]; then
    echo "❌ Error: Version or URL missing in JSON!"
    exit 1
fi

echo "Latest Version: $LATEST_VERSION"
echo "Download URL: $LATEST_URL"

# Get current version
if [ -f "$CURRENT_VERSION_FILE" ]; then
    CURRENT_VERSION=$(cat "$CURRENT_VERSION_FILE")
else
    CURRENT_VERSION="0.0.0"
fi

echo "Current Installed Version: $CURRENT_VERSION"

# Compare versions
if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
    echo "🚀 New version available: $LATEST_VERSION"
    
    # Download the update
    echo "⬇️ Downloading update..."
    wget --header="User-Agent: Mozilla/5.0" -O "/tmp/myapp.tar.gz" "$LATEST_URL"
    
    # Verify if download was successful
    if [ ! -f "/tmp/myapp.tar.gz" ]; then
        echo "❌ Error: Download failed!"
        exit 1
    fi

    # Remove old files before extracting
    echo "🗑 Removing old files..."
    rm -rf "$APP_DIR"/*

    # Extract the new version into the target directory
    echo "📦 Extracting update..."
    tar -xzf "/tmp/myapp.tar.gz" -C "$APP_DIR"

    # Verify extraction success
    if [ $? -ne 0 ]; then
        echo "❌ Error: Extraction failed!"
        exit 1
    fi

    # Update version file
    echo "$LATEST_VERSION" > "$CURRENT_VERSION_FILE"

    # Restart the application safely
    if pgrep -f capunit > /dev/null; then
        echo "🔄 Restarting application..."
        pkill -f capunit
    fi
    nohup "$APP_DIR/capunit" &

    echo "✅ Update applied successfully!"
else
    echo "✔ No update needed. Already running the latest version."
fi

echo "============================="
echo "Update check finished at: $(date)"
echo "============================="
