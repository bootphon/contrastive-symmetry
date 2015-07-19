#!/bin/bash

files=($1/*.csv)
head -1 ${files[0]}

for f in ${files[@]}
do
  sed -e "/^\$/d;1d" $f
done


