{ pkgs, ... }:
{
  home.packages = [
    (pkgs.rust-bin.stable.latest.default.override {
      extensions = [
        "rust-src"
        "rust-analyzer"
        "clippy"
      ];
      targets = [
        "aarch64-apple-darwin"
        "thumbv7em-none-eabihf"
        "thumbv6m-none-eabi"
        "wasm32-unknown-unknown"
        "riscv32imac-unknown-none-elf"
        "aarch64-unknown-linux-gnu"
      ];
    })
  ];
}
