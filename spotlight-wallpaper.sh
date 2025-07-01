#!/bin/bash

# Linux Spotlight Wallpaper Script
# Mimics Windows 11 Spotlight feature for dwm
# Author: Ahmed Elazony + Claude AI
# Requirements: feh, curl, jq

# Configuration
WALLPAPER_DIR="$HOME/.local/share/wallpapers/spotlight"
CURRENT_WALLPAPER="$HOME/.local/share/wallpapers/current_wallpaper"
LOG_FILE="$HOME/.local/share/wallpapers/spotlight.log"
MAX_WALLPAPERS=50 # Keep only last 50 wallpapers to save space

# API endpoints for high-quality images (similar to Spotlight style)
APIS=(
	"https://api.unsplash.com/photos/random?orientation=landscape&w=1920&h=1080&query=nature,landscape"
	"https://picsum.photos/1920/1080"
)

# Unsplash API key (get free key from unsplash.com/developers)
# Set this as environment variable: export UNSPLASH_ACCESS_KEY="your_key_here"
UNSPLASH_KEY="${UNSPLASH_ACCESS_KEY:-}"

# Create directories
mkdir -p "$WALLPAPER_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log_message() {
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check dependencies
check_dependencies() {
	local deps=("curl" "feh" "jq")
	for dep in "${deps[@]}"; do
		if ! command -v "$dep" &>/dev/null; then
			log_message "ERROR: $dep is not installed. Please install it first."
			echo "Install with: sudo pacman -S $dep"
			exit 1
		fi
	done
}

# Clean old wallpapers
clean_old_wallpapers() {
	local count=$(ls -1 "$WALLPAPER_DIR"/*.jpg 2>/dev/null | wc -l)
	if [ "$count" -gt "$MAX_WALLPAPERS" ]; then
		log_message "Cleaning old wallpapers (keeping last $MAX_WALLPAPERS)"
		ls -t "$WALLPAPER_DIR"/*.jpg | tail -n +$((MAX_WALLPAPERS + 1)) | xargs rm -f
	fi
}

# Download image from Unsplash
download_unsplash() {
	if [ -z "$UNSPLASH_KEY" ]; then
		log_message "No Unsplash API key found, skipping Unsplash"
		return 1
	fi

	local url="${APIS[0]}" # Use first API endpoint for Unsplash
	local response=$(curl -s -H "Authorization: Client-ID $UNSPLASH_KEY" "$url")

	if [ $? -ne 0 ]; then
		log_message "Failed to fetch from Unsplash API"
		return 1
	fi

	local image_url=$(echo "$response" | jq -r '.urls.full // .urls.regular // empty')
	local image_id=$(echo "$response" | jq -r '.id // empty')

	if [ -z "$image_url" ] || [ "$image_url" = "null" ]; then
		log_message "No image URL found in Unsplash response"
		return 1
	fi

	local filename="$WALLPAPER_DIR/spotlight_${image_id:-$(date +%s)}.jpg"

	if curl -s -L -o "$filename" "$image_url"; then
		echo "$filename"
		return 0
	else
		log_message "Failed to download from Unsplash"
		return 1
	fi
}

# Download image from Picsum (Lorem Picsum)
download_picsum() {
	local filename="$WALLPAPER_DIR/spotlight_picsum_$(date +%s).jpg"
	local url="${APIS[1]}" # Use second API endpoint for Picsum

	log_message "Downloading from Picsum"
	if curl -s -L -o "$filename" "$url"; then
		echo "filename: $filename"
		return 0
	else
		log_message "Failed to download from Picsum"
		return 1
	fi
}

# Set wallpaper using feh
set_wallpaper() {
	local image_file="$1"

	if [ ! -f "$image_file" ]; then
		echo "image_file: $image_file"
		log_message "ERROR: Image file not found: $image_file"
		return 1
	fi

	# Set wallpaper with feh
	if feh --bg-fill "$image_file"; then
		# Store current wallpaper path
		echo "$image_file" >"$CURRENT_WALLPAPER"
		log_message "Wallpaper set successfully: $(basename "$image_file")"
		return 0
	else
		log_message "ERROR: Failed to set wallpaper"
		return 1
	fi
}

# Get random existing wallpaper as fallback
get_random_existing() {
	local existing_wallpapers=("$WALLPAPER_DIR"/*.jpg)
	if [ ${#existing_wallpapers[@]} -gt 0 ] && [ -f "${existing_wallpapers[0]}" ]; then
		local random_index=$((RANDOM % ${#existing_wallpapers[@]}))
		echo "${existing_wallpapers[$random_index]}"
		return 0
	fi
	return 1
}

# Main function
main() {
	log_message "Starting wallpaper update"

	# Check dependencies
	check_dependencies

	# Clean old wallpapers
	clean_old_wallpapers

	# Try to download new wallpaper
	local new_wallpaper=""

	# Try Unsplash first (better quality, more variety)
	if [ -n "$UNSPLASH_KEY" ]; then
		new_wallpaper=$(download_unsplash)
	fi

	# Fallback to Picsum if Unsplash failed
	if [ -z "$new_wallpaper" ]; then
		new_wallpaper=$(download_picsum)
	fi

	# If download failed, use existing wallpaper
	if [ -z "$new_wallpaper" ]; then
		log_message "All downloads failed, trying existing wallpaper"
		new_wallpaper=$(get_random_existing)
	fi

	# Set wallpaper
	if [ -n "$new_wallpaper" ]; then
		set_wallpaper "$new_wallpaper"
	else
		log_message "ERROR: No wallpaper available to set"
		exit 1
	fi

	log_message "Wallpaper update completed"
}

# Handle command line arguments
case "${1:-}" in
"init")
	log_message "Initializing spotlight wallpaper system"
	main
	;;
"next")
	log_message "Manual wallpaper change requested"
	main
	;;
"status")
	if [ -f "$CURRENT_WALLPAPER" ]; then
		current=$(cat "$CURRENT_WALLPAPER")
		echo "Current wallpaper: $(basename "$current")"
		echo "Wallpaper directory: $WALLPAPER_DIR"
		echo "Stored wallpapers: $(ls -1 "$WALLPAPER_DIR"/*.jpg 2>/dev/null | wc -l)"
	else
		echo "No wallpaper currently set"
	fi
	;;
"")
	main
	;;
*)
	echo "Usage: $0 [init|next|status]"
	echo "  init   - Initialize and set first wallpaper"
	echo "  next   - Manually get next wallpaper"
	echo "  status - Show current status"
	echo "  (no args) - Regular wallpaper update"
	exit 1
	;;
esac
