{
  description = "Neonment is a hero shooter game with lots of neon lights.";

  inputs.nixpkgs.url = "github:yusdacra/nixpkgs/master";

  outputs = { self, nixpkgs }: {
    defaultPackage.x86_64-linux =
      with import nixpkgs { system = "x86_64-linux"; };
      stdenv.mkDerivation {
        name = "neonment-client";
        src = self;
        buildInputs = [ godot-headless ];
        preConfigure = "export HOME=`mktemp -d`";
        buildPhase = ''godot-headless --export "Linux Client" neonment-client'';
        installPhase = "mkdir -p $out/bin; install -t $out/bin neonment-client";
      };
  };
}
