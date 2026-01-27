fn main() {
    // Load .env at build time and embed public values
    let _ = dotenvy::dotenv();
    
    // These are PUBLIC values, safe to embed in the binary
    if let Ok(url) = std::env::var("SUPABASE_URL") {
        println!("cargo:rustc-env=SUPABASE_URL={}", url);
    }
    if let Ok(key) = std::env::var("SUPABASE_ANON_KEY") {
        println!("cargo:rustc-env=SUPABASE_ANON_KEY={}", key);
    }
    
    tauri_build::build()
}
