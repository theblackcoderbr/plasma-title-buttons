let
  pin = builtins.fromJSON (builtins.readFile ./nixpkgs.json);
  source = builtins.fetchTarball {
    name = "source";
    url = "https://github.com/NixOS/nixpkgs/archive/${pin.rev}.tar.gz";
    sha256 = pin.sha256;
  };
in
import source {
  config = {};
  overlays = [];
}
