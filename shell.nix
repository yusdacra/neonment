{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell {
  name = "danmake-shell";
  nativeBuildInputs = with pkgs; [ alsaLib pkg-config clang_10 lld_10 ];
  buildInputs = with pkgs; [ alsaLib x11 clang_10 lld_10 ];
}
