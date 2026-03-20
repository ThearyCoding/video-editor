#!/bin/bash

# Create directories if they don't exist
mkdir -p assets/bin/windows
mkdir -p assets/bin/macos

# Download Windows FFmpeg (essential build)
echo "Downloading Windows FFmpeg..."
curl -L -o /tmp/ffmpeg-windows.zip https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip

# Extract just ffmpeg.exe
unzip -j /tmp/ffmpeg-windows.zip "*/bin/ffmpeg.exe" -d assets/bin/windows/

# Make sure it's executable
chmod +x assets/bin/windows/ffmpeg.exe

# Verify macOS binary exists
if [ ! -f "assets/bin/macos/ffmpeg" ]; then
    echo "Warning: macOS ffmpeg not found!"
fi

echo "FFmpeg binaries ready:"
ls -la assets/bin/macos/
ls -la assets/bin/windows/

# Cleanup
rm /tmp/ffmpeg-windows.zip