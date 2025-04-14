{ pkgs, lib, ... }:
let
  typst = lib.getExe pkgs.typst;
  zathura = lib.getExe pkgs.zathura;
in ''
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
