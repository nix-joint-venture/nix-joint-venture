# FAQ:
- escaping string interpolation: put '' befor $
  - example: `''${nointerpolation}`
  - except if you have a preceding " then use:
    ```nix
       let
         folder = "\${folder}";
       in ''
         in_file="${folder}/in"
       ''
    ```
    this will produce: `in_file="${folder}/in"` \
    TODO can sb find a workaround?
# Scripts:
- always use lib.getExe  or lib.getExe' instead of add /bin/$name

# cmds expected to always be present (no pkgs. needed)
- cat
- echo
- mktemp
- read
- fd
- grep
- sort
- head
- rm
- exit


