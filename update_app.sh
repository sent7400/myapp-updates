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
    echo "📦 'jq' not found. Installing jq..."
    
    # Update package list (only if needed)
    sudo apt-get update
    
    # Install jq silently
    sudo apt-get install -y jq

    # Verify installation succeeded
    if ! command -v jq &> /dev/null; then
        echo "❌ Error: Failed to install jq. Please install it manually."
        exit 1
    else
        echo "✅ jq installed successfully."
    fi
else
    echo "✅ jq is already installed."
fi

# Ensure libsqlite3-dev is installed
if ! dpkg -s libsqlite3-dev &> /dev/null; then
    echo "📦 'libsqlite3-dev' not found. Installing..."
    sudo apt-get update
    sudo apt-get install -y libsqlite3-dev

    if ! dpkg -s libsqlite3-dev &> /dev/null; then
        echo "❌ Error: Failed to install libsqlite3-dev. Please install it manually."
        exit 1
    else
        echo "✅ libsqlite3-dev installed successfully."
    fi
else
    echo "✅ libsqlite3-dev is already installed."
fi

# Ensure xterm is installed
if ! command -v xterm &> /dev/null; then
    echo "📦 'xterm' not found. Installing..."
    sudo apt-get update
    sudo apt-get install -y xterm

    if ! command -v xterm &> /dev/null; then
        echo "❌ Error: Failed to install xterm. Please install it manually."
        exit 1
    else
        echo "✅ xterm installed successfully."
    fi
else
    echo "✅ xterm is already installed."
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


# ===========================================
# 📌 Ensure Autostart .desktop File Exists
# ===========================================

AUTOSTART_DIR="$ROOT_HOME/.config/autostart"
DESKTOP_FILE="$AUTOSTART_DIR/capunit.desktop"

echo "🔧 Setting up autostart desktop file at: $DESKTOP_FILE"

# Create autostart directory if it doesn't exist
if [ ! -d "$AUTOSTART_DIR" ]; then
    echo "Creating autostart directory at $AUTOSTART_DIR"
    mkdir -p "$AUTOSTART_DIR"
fi

# Create the capunit.desktop file
cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Type=Application
Exec=$APP_DIR/capunit
Terminal=false
Hidden=false
NoDisplay=false
Name=CapUnit App
Comment=Auto-start CapUnit Flutter app
EOF

# Ensure the desktop file is executable
chmod +x "$DESKTOP_FILE"

echo "✅ capunit.desktop file created at: $DESKTOP_FILE"


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
