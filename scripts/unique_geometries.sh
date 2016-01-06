#!/bin/bash

header=$(head -1 $1)
echo $header | cut -d , -f 1-4 > $2
sed "1d" $1 | cut -d , -f 1-4 | sort | uniq >> $2
