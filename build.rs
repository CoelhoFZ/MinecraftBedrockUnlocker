// Rust build script - runs before compilation
fn main() {
    // Embed manifest and resources into the Windows executable
    embed_resource::compile("resources.rc", embed_resource::NONE);
    println!("cargo:rerun-if-changed=resources.rc");
    println!("cargo:rerun-if-changed=minecraft-unlocker-cli.manifest");
}
