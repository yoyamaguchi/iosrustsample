# Example to make xcframework of Rust crate for apple platform
Memo for creating xcframework for apple platform as swift package from Rust crate.

## Prerequisites
- Rust (confirmed with 1.65.0)
  - targets
    - aarch64-apple-darwin
    - x86_64-apple-darwin
    - x86_64-apple-ios
    - aarch64-apple-ios
    - aarch64-apple-ios-sim
- how to add cross compile target
```
$ rustup target add aarch64-apple-ios
```
- Xcode (confirmed with 14.1)
- uniffi_bindgen
```
$ cargo install uniffi_bindgen
```

## Build
At repository root,
```
$ bash build.sh
```

## Repository Tree Memo
``` 
.
├── Cargo.toml
├── Package.swift  (swift package manifest file)
├── Sources
│         ├── IOSTest (swift file is created by uniffi_bindgen)
│         └── IOSTestFFI.xcframework (created by build.sh)
├── build.rs
├── build.sh (build script)
├── misc (required files to create xcframework)
│         ├── Info.plist
│         └── module.modulemap
└── src (sources written in Rust)
    ├── bin
    ├── lib.rs
    └── lib.udl (udl file. see uniffi-rs)
```

## References
- [uniffi-rs](https://github.com/mozilla/uniffi-rs)
- [application-service](https://github.com/mozilla/application-services)
- [uniffi-rs-fullstack-examples](https://github.com/imWildCat/uniffi-rs-fullstack-examples)