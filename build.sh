#!/usr/bin/env bash
#
# This script builds the Rust crate in its directory into a staticlib XCFramework for iOS and macos.

BUILD_PROFILE="release"   # release or debug
FRAMEWORK_NAME="IOSTestFFI"
FRAMEWORK_FILENAME=$FRAMEWORK_NAME
CARGO="$HOME/.cargo/bin/cargo"

# build all required targets
case $BUILD_PROFILE in
  debug)
    cargo build --target aarch64-apple-ios-sim
    cargo build --target x86_64-apple-ios
    cargo build --target aarch64-apple-ios
    cargo build --target x86_64-apple-darwin
    cargo build --target aarch64-apple-darwin
    ;;
  release)
    cargo build --target aarch64-apple-ios-sim --release
    cargo build --target x86_64-apple-ios --release
    cargo build --target aarch64-apple-ios --release
    cargo build --target x86_64-apple-darwin --release
    cargo build --target aarch64-apple-darwin --release
    ;;
  *) echo "Unknown build profile: $BUILD_PROFILE"; exit 1;
esac

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
WORKING_DIR=$THIS_DIR
REPO_ROOT=$THIS_DIR

MANIFEST_PATH="$WORKING_DIR/Cargo.toml"

if [[ ! -f "$MANIFEST_PATH" ]]; then
  echo "Could not locate Cargo.toml in $MANIFEST_PATH"
  exit 1
fi

CRATE_NAME=$(grep --max-count=1 '^name =' "$MANIFEST_PATH" | cut -d '"' -f 2)
if [[ -z "$CRATE_NAME" ]]; then
  echo "Could not determine crate name from $MANIFEST_PATH"
  exit 1
fi

LIB_NAME="lib${CRATE_NAME}.a"

TARGET_DIR="$REPO_ROOT/target"
XCFRAMEWORK_ROOT="$WORKING_DIR/Sources/$FRAMEWORK_FILENAME.xcframework"

# Start from a clean slate.
rm -rf "$XCFRAMEWORK_ROOT"

COMMON="$TARGET_DIR/common"

# Make common
rm -rf "$COMMON"
mkdir -p "$COMMON/Modules"
mkdir -p "$COMMON/Headers"
mkdir -p "$COMMON/Resources"

cp "$WORKING_DIR/misc/module.modulemap" "$COMMON/Modules/"

# generate header and swift file with uniffi-bindgen and move to common
uniffi-bindgen generate "$REPO_ROOT/src/lib.udl" -l swift -o "$COMMON/Headers"
mv "$COMMON/Headers/IOSTest.swift" "$WORKING_DIR/Sources/IOSTest/IOSTest.swift"
rm -rf "$COMMON"/Headers/*.modulemap

# empty info files
cp "$WORKING_DIR/misc/Info.plist" "$COMMON/Resources/"

# make framework for iOS hardware
rm -Rf "$TARGET_DIR/ios-arm64"
mkdir -p "$TARGET_DIR/ios-arm64"
cp -r "$COMMON" "$TARGET_DIR/ios-arm64/$FRAMEWORK_NAME.framework"
cp "$TARGET_DIR/aarch64-apple-ios/$BUILD_PROFILE/$LIB_NAME" "$TARGET_DIR/ios-arm64/$FRAMEWORK_NAME.framework/$FRAMEWORK_NAME"

# make framework for iOS simulator, with both platforms as a fat binary
rm -Rf "$TARGET_DIR/ios-arm64_x86_64-simulator"
mkdir -p "$TARGET_DIR/ios-arm64_x86_64-simulator"
cp -r "$COMMON" "$TARGET_DIR/ios-arm64_x86_64-simulator/$FRAMEWORK_NAME.framework"
lipo -create \
  -output "$TARGET_DIR/ios-arm64_x86_64-simulator/$FRAMEWORK_NAME.framework/$FRAMEWORK_NAME" \
  "$TARGET_DIR/aarch64-apple-ios-sim/$BUILD_PROFILE/$LIB_NAME" \
  "$TARGET_DIR/x86_64-apple-ios/$BUILD_PROFILE/$LIB_NAME"

# make framework for macos, with both platforms as a fat binary
rm -Rf "$TARGET_DIR/macos-arm64_x86_64"
mkdir -p "$TARGET_DIR/macos-arm64_x86_64"
cp -r "$COMMON" "$TARGET_DIR/macos-arm64_x86_64/$FRAMEWORK_NAME.framework"
lipo -create \
  -output "$TARGET_DIR/macos-arm64_x86_64/$FRAMEWORK_NAME.framework/$FRAMEWORK_NAME" \
  "$TARGET_DIR/aarch64-apple-darwin/$BUILD_PROFILE/$LIB_NAME" \
  "$TARGET_DIR/x86_64-apple-darwin/$BUILD_PROFILE/$LIB_NAME"

# Set up the metadata for the XCFramework as a whole.
xcodebuild -create-xcframework -framework "$TARGET_DIR/ios-arm64/$FRAMEWORK_NAME.framework" \
  -framework "$TARGET_DIR/ios-arm64_x86_64-simulator/$FRAMEWORK_NAME.framework" \
  -framework "$TARGET_DIR/macos-arm64_x86_64/$FRAMEWORK_NAME.framework" \
  -output "$XCFRAMEWORK_ROOT"

rm -rf "$COMMON"

# Zip it all up into a bundle for distribution.
#(cd "$WORKING_DIR" && zip -9 -r "$FRAMEWORK_FILENAME.xcframework.zip" "Sources/$FRAMEWORK_FILENAME.xcframework")
