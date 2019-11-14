#!/bin/bash
###SBATCH -q standard
#SBATCH -n 1
###SBATCH -l pmem=40GB
#SBATCH -t 48:00:00
#SBATCH -A COMP-FE
###SBATCH -p shared


for file in $(ls ./exe_*/queryout*.csv | sed "s/\\.\\/exe_[0-9]\+\\///g" | sort | uniq) ; do
    queryoutname=$(echo $file | sed -e "s/queryout/queryoutall/g")
    cat ./exe_*/${file} > ./output/${queryoutname}
done
