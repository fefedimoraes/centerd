project := "centerd.xcodeproj"
scheme  := "centerd"

# swift-format ships inside the Xcode toolchain; invoke it via xcrun.
swift-format := "xcrun swift-format"

# List available recipes.
default:
    @just --list

# Build the app (Debug by default; pass `config=Release` to override).
build config="Debug":
    xcodebuild -project {{project}} -scheme {{scheme}} -configuration {{config}} -destination 'platform=macOS' build

# Build a Release configuration.
release: (build "Release")

# Remove build artifacts and DerivedData for this project.
clean:
    xcodebuild -project {{project}} -scheme {{scheme}} clean

# Format all Swift sources in place using the project's .swift-format config.
format:
    {{swift-format}} format --in-place --recursive --configuration .swift-format centerd

# Lint all Swift sources without modifying them (fails on violations).
lint:
    {{swift-format}} lint --strict --recursive --configuration .swift-format centerd

# Regenerate the app icon set from the SVG sources in icon/.
icon:
    ./icon/generate.sh

# Verify formatting and build — handy as a pre-commit / CI check.
check: lint build
