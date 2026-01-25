fn main() {
    // Set rpath for bundled dylibs (macOS)
    #[cfg(target_os = "macos")]
    {
        println!("cargo:rustc-link-arg=-Wl,-rpath,@executable_path/../Frameworks");
        println!("cargo:rustc-link-arg=-Wl,-rpath,@executable_path/../libs");
    }
    
    tauri_build::build()
}
