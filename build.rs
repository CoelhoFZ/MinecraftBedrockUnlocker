// Rust build script - runs before compilation
fn main() {
    // Windows resource embedding is OPTIONAL - requires windres (MinGW) to be installed.
    // If you have MinGW/windres in PATH, uncomment the lines below to embed:
    // - Application icon
    // - Windows manifest (for admin privileges)
    // - Version info metadata
    
    // To enable: Install MinGW-w64 and add to PATH, then uncomment:
    // embed_resource::compile("resources.rc", embed_resource::NONE);
    // println!("cargo:rerun-if-changed=resources.rc");
    // println!("cargo:rerun-if-changed=minecraft-unlocker-cli.manifest");
}
