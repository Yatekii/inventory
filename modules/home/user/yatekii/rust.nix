{
  self,
  pkgs,
  ...
}:
{
  nixpkgs.overlays = [
    (import self.inputs.rust-overlay)
  ];

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
        "wasm32-unknown-unknown"
        "riscv32imac-unknown-none-elf"
      ];
    })
  ];
}
