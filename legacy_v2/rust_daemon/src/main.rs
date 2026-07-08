use std::env;
use std::process::{Command, exit};
use std::path::Path;

fn main() {
    let args: Vec<String> = env::args().collect();
    
    if args.len() < 2 {
        eprintln!("Usage: rulefucker-run <command> [args...]");
        eprintln!("Example: rulefucker-run neofetch");
        exit(1);
    }
    
    let command = &args[1];
    let cmd_args = &args[2..];
    
    // Yolları belirle
    let config_dir = "/home/yusuf/rulefucker/config";
    let so_path = "/home/yusuf/rulefucker/c_hook/rulefucker.so";
    
    if !Path::new(so_path).exists() {
        eprintln!("Error: Hook library not found at {}", so_path);
        eprintln!("Please compile the C hook first.");
        exit(1);
    }
    
    // LD_PRELOAD ve ortam değişkenlerini ayarla
    let mut cmd = Command::new(command);
    cmd.args(cmd_args);
    
    // Var olan LD_PRELOAD varsa sonuna ekle
    let mut ld_preload = env::var("LD_PRELOAD").unwrap_or_default();
    if !ld_preload.is_empty() {
        ld_preload.push_str(":");
    }
    ld_preload.push_str(so_path);
    
    cmd.env("LD_PRELOAD", ld_preload);
    
    // Customizer için özel değişkenler (Eğer halihazırda set edilmemişlerse)
    if env::var("RULEFUCKER_CONFIG_PATH").is_err() {
        cmd.env("RULEFUCKER_CONFIG_PATH", format!("{}/rulefucker.conf", config_dir));
    }
    
    if env::var("RULEFUCKER_SPOOF_DIR").is_err() {
        cmd.env("RULEFUCKER_SPOOF_DIR", format!("{}/rulefucker_spoof", config_dir));
    }
    
    // Komutu çalıştır
    let status = cmd.status().unwrap_or_else(|e| {
        eprintln!("Failed to execute '{}': {}", command, e);
        exit(1);
    });
    
    exit(status.code().unwrap_or(1));
}
