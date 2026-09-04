#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
MODELS="original, new"

if [[ "$1" == "" ]]; then
  DIR="$SCRIPT_DIR/litmus"
else
  DIR=$1
fi

ALLOY_JAR="$HOME/org.alloytools.alloy.dist.jar"
OUTPUT=results.csv
echo "test,model,result" >$OUTPUT
for MODEL in $(MODELS); do
  rm -f $DIR/ptx.als
  ln -s "$DIR/ptx_$MODEL.als" $DIR/ptx.als"
  for TEST in $(ls $DIR/*.als); do
    if [[ "${TEST##*/}" == "ptx.als" || "${TEST##*/}" == "util.als" || "${TEST##*/}" == "ptx_original.als" || "${TEST##*/}" == "ptx_new.als" ]]; then
      continue
    fi
    echo ${TEST##*/}
    echo -n ${TEST##*/}, >>$OUTPUT
    echo -n "$MODEL," >>$OUTPUT
    timeout 60 java -jar --enable-native-access=ALL-UNNAMED $ALLOY_JAR exec -f -o alloyout $TEST 2>&1 | tee runlitmus.log | grep -o -e "[^N]SAT" -e "UNSAT" >>$OUTPUT
    TIMEOUT_EXIT=${PIPESTATUS[0]}
    if [ "$TIMEOUT_EXIT" -eq 124 ]; then
      echo "UNSAT" >>$OUTPUT
    fi
    cat runlitmus.log
  done
done
