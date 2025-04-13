{ pkgs, getExe, ... }:
let
  gcc = getExe pkgs.gcc;
  typst = getExe pkgs.typst;
  zathura = getExe pkgs.zathura;
  folder = "\${folder}";
in
''
  a_out=$(mktemp)
  if [[ "$#" -lt 1 ]]; then
    echo "provide c program"
    exit 1
  fi
  for folder in ./tests/*; do
    if [ -d "$folder" ]; then
      in_file="${folder}/in"
      out_file="${folder}/out"
      #echo "$in_file $out_file $1 $a_out"
      c_out=$(mktemp)
      if [[ "$#" -eq 2 ]]; then
        cp "$1" "$c_out"
        $2 "$c_out" "$(cat $in_file)"
      else
        cp "$1" "$c_out"
      fi
      echo "$c_out"
      ${gcc} -x c $c_out -o $a_out
      $a_out < $in_file > $out_file
    fi
  done
  ${typst} c ../tests.typ
  ${zathura} ../tests.pdf
''
