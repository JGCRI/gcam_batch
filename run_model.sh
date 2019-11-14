#!/bin/bash 

# Script expects two parameters: the configuration filename and the task number
# Filename should be the base name, not including job number or extension

CONFIGURATION_FILE=${1}_${2}.xml

if [ ! -e $CONFIGURATION_FILE ]; then
	echo "$CONFIGURATION_FILE does not exist; task $2 bailing!"
	exit 
fi

echo "Configuration file: $CONFIGURATION_FILE"

# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/homes/pralitp/libs/dbxml-2.5.16/install/lib

# It turns out that to pass data from C++ to Fortran, MiniCAM writes out a 'gas.emk' file
# which is then read in by MAGICC.  This is not good, as multiple instances will stomp
# all over each other.  The long-term solution is to pass internally; for now, we'll 
# create separate exe directories, even though this is a performance hit.

rm -rf exe_$2	 	# just in case
cp -fR exe exe_$2
cd exe_$2

echo "Running Minicam with $CONFIGURATION_FILE..."
# let's keep a copy of config file in the running directory
cp ../$CONFIGURATION_FILE ./config_this.xml
./gcam.exe -C../$CONFIGURATION_FILE > output_${2}.txt 
err=$?

# Clean up

	# ksh ../filter_outfile_cost.ksh < outFile_${2}.csv > ../output/outFileCost_${2}.csv

# Xvfb :$2 -pn -audit 4 -screen 0 800x600x16 &
# export DISPLAY=:${2}.0

java -cp /pic/projects/GCAM/GCAM-libraries/lib/basex-8.6.7/BaseX.jar:/pic/projects/GCAM/GCAM-libraries/lib/jars/*:../output/modelinterface/ModelInterface.jar ModelInterface/InterfaceMain -b xmldb_batch.xml

# run-diag here

if [[ $err -gt 0 ]]; then
	echo "Error code reported: $err"
	echo $err > ../errors/$2
else
	# ksh ../filter_outfile.ksh < outFile_${2}.csv > ../output/outFileSummary_${2}.csv
	# cp batchout_${2}.csv ../output/
	# cp magout_c.csv ../output/magout_${2}.csv
    	# cp gas.emk ../output/gas_${2}.emk
	# cp database.dbxml ../output/database_${2}.dbxml
    # Xvfb :$2 -pn -audit 4 -screen 0 800x600x16 &
    # export DISPLAY=:${2}.0
    # java -jar /homes/pralitp/ModelInterface/ModelInterface.jar -b xmldb_batch.xml
	# cd ..
	# rm -rf exe_$2
	echo "Good"
fi

echo "Task $2 is done!"

# return $err

