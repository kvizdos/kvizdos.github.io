# Convert PNG/JPEG images to WebP in ./assets/blog
# Requires: cwebp (install with: brew install webp or apt install webp)

# Default recipe - convert all images
default: convert-all

# Convert all PNG and JPEG files to WebP
convert-all:
    #!/usr/bin/env bash
    set -euo pipefail

    if ! command -v cwebp &> /dev/null; then
        echo "Error: cwebp not found. Install with:"
        echo "  macOS: brew install webp"
        echo "  Ubuntu/Debian: sudo apt install webp"
        exit 1
    fi

    cd ./assets/blog

    # Convert PNG files
    find . -name "*.png" -type f | while read -r file; do
        output="${file%.*}.webp"
        echo "Converting: $file -> $output"
        cwebp -q 80 "$file" -o "$output"
        rm "$file"
        echo "Replaced $file with $output"
    done

    # Convert JPEG/JPG files
    find . \( -name "*.jpg" -o -name "*.jpeg" \) -type f | while read -r file; do
        output="${file%.*}.webp"
        echo "Converting: $file -> $output"
        cwebp -q 80 "$file" -o "$output"
        rm "$file"
        echo "Replaced $file with $output"
    done

    echo "✅ All images converted to WebP format"

# Convert with higher quality (90)
convert-hq:
    #!/usr/bin/env bash
    set -euo pipefail

    if ! command -v cwebp &> /dev/null; then
        echo "Error: cwebp not found"
        exit 1
    fi

    cd ./assets/blog

    find . \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) -type f | while read -r file; do
        output="${file%.*}.webp"
        echo "Converting (HQ): $file -> $output"
        cwebp -q 90 "$file" -o "$output"
        rm "$file"
        echo "Replaced $file with $output"
    done

# Convert but keep originals (don't delete)
convert-keep:
    #!/usr/bin/env bash
    set -euo pipefail

    if ! command -v cwebp &> /dev/null; then
        echo "Error: cwebp not found"
        exit 1
    fi

    cd ./assets/blog

    find . \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) -type f | while read -r file; do
        output="${file%.*}.webp"
        echo "Converting (keeping original): $file -> $output"
        cwebp -q 80 "$file" -o "$output"
        echo "Created $output (kept $file)"
    done

# Check what files would be converted (dry run)
check:
    #!/usr/bin/env bash
    cd ./assets/blog
    echo "PNG files found:"
    find . -name "*.png" -type f || echo "  None"
    echo
    echo "JPEG files found:"
    find . \( -name "*.jpg" -o -name "*.jpeg" \) -type f || echo "  None"

# Clean up any leftover original images after conversion
clean-originals:
    #!/usr/bin/env bash
    cd ./assets/blog
    echo "Removing any remaining PNG/JPEG files..."
    find . \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) -type f -delete
    echo "✅ Cleanup complete"
