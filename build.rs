// Rust build script - runs before compilation
fn main() {
    // Resources disabled temporarily - windres not available
    // embed_resource::compile("resources.rc", embed_resource::NONE);
    // println!("cargo:rerun-if-changed=resources.rc");
    // println!("cargo:rerun-if-changed=minecraft-unlocker-cli.manifest");
}
