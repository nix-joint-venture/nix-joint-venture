{ pkgs, lib, ... }:
let
  typst = lib.getExe' pkgs.typst "typst";
  zathura = lib.getExe' pkgs.zathura "zathura";
in pkgs.writeShellScriptBin "typst-preview.sh" ''
  dir=$(mktemp -d)
  _=$(${typst} watch "$1" "$dir/tmp.pdf" & echo $! > "$dir/pid")&
  until [ -f "$dir/tmp.pdf" ]
  do
    sleep 0.5
  done
  pid=$(cat "$dir/pid")
  ${zathura} "$dir/tmp.pdf"
  kill "$pid"
  rm -fr "$dir"
''
