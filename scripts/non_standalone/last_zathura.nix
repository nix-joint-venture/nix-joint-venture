{
  pkgs,
  getExe,
  ...
}:
{ globals, ... }:
let
  zathura = getExe pkgs.zathura;
  python3 = getExe pkgs.python3;

in
''
  py_str="$(cat <<-EOF
  import sqlite3;

  file = "$HOME/.local/share/zathura/bookmarks.sqlite";
  con = sqlite3.connect(file);
  cur = con.cursor();

  res = cur.execute("SELECT DISTINCT file FROM jumplist ORDER BY id DESC").fetchall();
  [print(r[0]) for r in res];
  con.close();
  EOF
  )"

  # run above python script
  readarray -t files <<<$(${python3} -c "$py_str")

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

  file_i=$(printf "%s\n" "''${print_files[@]}" | ${globals.dmenu} -format i)

  # open file in zathure (if selected)
  if [ "$file_i" = 0 ]; then
      ${zathura}
  elif [ -n "$file_i" ]; then
      ((file_i--))
      ${zathura} "''${end_files[$file_i]}"
  fi
''
