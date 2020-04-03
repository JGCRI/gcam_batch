    cd exe_$1
    java -cp /pic/projects/GCAM/GCAM-libraries/lib/basex-8.6.7/BaseX.jar:/pic/projects/GCAM/GCAM-libraries/lib/jars/*:../output/modelinterface/ModelInterface.jar ModelInterface/InterfaceMain -b ../queries/${2}
    cd ../
