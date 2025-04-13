_: ''
  set -xeu
  if [[ "$#" -ne 1 ]]; then
    exit 1
  fi
  for  i in $(seq 1 $1);
  do
    if [ ! -d  "$i" ]; then
      mkdir -p tests/$i
      echo  "atest" >"tests/$i/in"
      echo  "btest" >"tests/$i/out"
      echo  "ctest" >"tests/$i/exout"
    fi
  done
''
