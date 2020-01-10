for folder in ./exe_*/; do
    echo "copying ./queries/${1} ${folder}${1}"
    cp ./queries/${1} ${folder}${1}
    cd ${folder}
    java -cp /pic/projects/GCAM/GCAM-libraries/lib/basex-8.6.7/BaseX.jar:/pic/projects/GCAM/GCAM-libraries/lib/jars/*:../output/modelinterface/ModelInterface.jar ModelInterface/InterfaceMain -b ${1}
    cd ../
done

for file in $(ls ./exe_*/queryout*.csv | sed "s/\\.\\/exe_[0-9]\+\\///g" | sort | uniq) ; do
    queryoutname=$(echo $file | sed -e "s/queryout/queryoutall/g")
    cat ./exe_*/${file} > ./output/${queryoutname}
done
