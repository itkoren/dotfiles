function dmginstall {
  if [[ $# -lt 1 ]]; then
    echo "Usage: dmginstall [url or path]"
    exit 1
  fi
    
  url="${1}"
  tempd=""
  app=""
  
  set -x
  
  # Check if the input is a URL or a local file
  if [[ "$url" =~ ^https?:// ]]; then
    echo "The argument starts with http:// or https://"
    # Download file
    echo "Downloading $url..."
    tempd=$(mktemp -d)
    curl -L "$url" -o "$tempd/pkg.dmg" || { echo "Download failed"; exit 1; }
    app="$tempd/pkg.dmg"
  else
    echo "The argument does not start with http:// or https://"
    app="$url"
  fi

  # Mount the DMG file
  echo "Mounting image..."
  listing=$(sudo hdiutil mount "$app" | grep Volumes)
  
  # Use sed to properly extract the volume path (handle spaces in names)
  volume=$(echo "$listing" | sed -E 's/.*\t([^\t]+)$/\1/')

  if [[ -z "$volume" ]]; then
    echo "Failed to mount the disk image."
    exit 1
  fi
  
  echo "Mounted volume: $volume"
  
  # Install the app or package
  if ls "$volume"/*.app &>/dev/null; then
    app_to_install=$(find "$volume" -name "*.app" | head -n 1)
    app_name=$(basename "$app_to_install")
    
    # Check if the app is already installed
    if [[ -d "/Applications/$app_name" ]]; then
      read -p "$app_name already exists. Do you want to overwrite it? (y/n): " yn
      if [[ "$yn" =~ ^[Yy]$ ]]; then
        echo "Copying $app_to_install to /Applications..."
        sudo cp -rf "$app_to_install" /Applications
      fi
    fi
  elif ls "$volume"/*.pkg &>/dev/null; then
    package=$(find "$volume" -name "*.pkg" | head -n 1)
    
    # Install the package
    echo "Installing package $package..."
    sudo installer -pkg "$package" -target /
  else
    echo "No .app or .pkg found in the mounted disk image."
    exit 1
  fi

  # Unmount volume and clean up
  echo "Cleaning up..."
  sudo hdiutil unmount "$volume" -quiet
  if [[ -n "$tempd" ]]; then
    rm -rf "$tempd"
  fi
  echo "Done!"
  set +x
}
