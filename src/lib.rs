use uniffi_macros;

uniffi_macros::include_scaffolding!("lib");

pub fn test_add(left: u32, right: u32) -> u32 {
    left + right
}