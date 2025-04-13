{ pkgs, getExe', ... }:
let
  nvim = getExe' pkgs.neovim "nvim";
  folder = "\${folder}";
in
''
  #!/bin/sh
  vim_script_file=$(mktemp)

  for folder in $(fd . tests | grep -E '[[:digit:]]/$' | sort -V) ; do
    if [ -d "$folder" ]; then
      in_file="${folder}in"
      out_file="${folder}out"
      exout_file="${folder}exout"
    cat <<EOF >> "$vim_script_file"
  tabe $exout_file
  vsp +set\ readonly $out_file
  vsp $in_file
  EOF
    fi
  done

  cat <<EOF >> "$vim_script_file"
  set switchbuf=useopen,usetab
  sb $(fd . tests | grep -E '[[:digit:]]/$' | sort -V | head -n 1)in
  EOF

  cat "$vim_script_file"
  ${nvim} -S "$vim_script_file"
  rm "$vim_script_file"
''
