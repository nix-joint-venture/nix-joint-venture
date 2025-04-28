{ pkgs, scripts, lib, globals, ... }:
let xournalpp = lib.getExe pkgs.xournalpp;
in ''
  # run above python script
  readarray -t files <<<$(cat $HOME/.config/xournalpp/metadata/*.metadata | grep "\"" | tac | sed -e 's/^.//' -e 's/.$//')

  end_files=()
  print_files=()
  print_files+=("no file")

  # check if files exist
  for file in "''${files[@]}"; do
      if [ -f "$file" ]; then
          end_files+=("$file")
          print_files+=("$(basename "$file")")
      fi
  done

  file_i=$(printf "%s\n" "''${print_files[@]}" | rofi -dmenu -format i)

  # open file in xournalpp (if selected)
  if [ "$file_i" = 0 ]; then
      ${xournalpp}
  elif [ -n "$file_i" ]; then
      ((file_i--))
      ${xournalpp} "''${end_files[$file_i]}"
  fi

''
