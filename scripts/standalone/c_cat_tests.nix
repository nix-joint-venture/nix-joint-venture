{ pkgs, getExe', ... }:
let
  wl-copy = getExe' pkgs.wl-clipboard "wl-copy";
  folder = "\${folder}";
in
''
  a_out=$(mktemp)
  for folder in ./tests/*; do
    if [ -d "$folder" ]; then
      in_file="${folder}/in"
      out_file="${folder}/out"
      exout_file="${folder}/exout"
      curr_str=$( echo "$(cat $in_file) -> $(cat $out_file)" | tr '\n' ' ')
      echo "test $curr_str"
      echo "$curr_str" | ${wl-copy}
      read ans
      echo "in $in_file: $(cat $in_file)"
      ${wl-copy} < $in_file
      read ans
      echo "exout $out_file: $(cat $exout_file)"
      ${wl-copy} < $exout_file
      read ans
    fi
  done
''
