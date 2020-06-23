#!/bin/bash 

# This is the main script used for running GCAM on the Evergreen cluster
# It is adapted from the NERSC version!

# Preset necessary variables

# Generate the configuration files?  
generate=y

# Write out the new config files?
writetodisk=y

# Which config file would you like to start with?
first_task=0

# Which config file would you like to end with? 
last_task=0

# How many cores should be used for each run?
num_cores=1

# Do you want the run to actually go?
run=y

# Do you want to be emailed when each run is done? 
email=n


# Input files' locations
config=configuration-sets/config.xml
batch=configuration-sets/batch.xml


EXPECTED_ARGS=0

RUN_SCRIPT=run_model.sh

PBS_TEMPLATEFILE=gcam_template.pbs
PBS_BATCHFILE=gcam.pbs

if [ $# -eq $EXPECTED_ARGS ] ; then
	echo "This is $0"
else
	echo "Usage: <script name> <template config file> <batch file>"
	exit 
fi

# --------------------------------------------------------------------------------------------
# 1. Copy everything over to scratch directory and work there
# --------------------------------------------------------------------------------------------


# skip sync of files (possibly would want to do this from HOME to EMSL_HOME?)
RUN_DIR_NAME=
WORKSPACE_DIR_NAME=
SCRATCH=
INPUT_OPTIONS="--include=*.xml --include=*.ini --include=climate/*.csv --include=Hist_to_2008_Annual.csv --include=*.jar --exclude=.svn --exclude=*.*" 
echo "Syncing input directory to $SCRATCH..."
rsync -av $INPUT_OPTIONS ${WORKSPACE_DIR_NAME}/input ${SCRATCH}/${RUN_DIR_NAME}/
echo "Syncing exe directory to $SCRATCH..."
rsync -av ${WORKSPACE_DIR_NAME}/exe ${SCRATCH}/${RUN_DIR_NAME}/
echo "Syncing output directory to $SCRATCH..."
rsync -av ${WORKSPACE_DIR_NAME}/output ${SCRATCH}/${RUN_DIR_NAME}/


cd ${SCRATCH}/${RUN_DIR_NAME}


# --------------------------------------------------------------------------------------------
# 2. Generate the required permutations of the base configuration file
# --------------------------------------------------------------------------------------------
        
template_path=`dirname $config`
template_root=`basename $config | cut -f 1 -d.`
echo $template_path
echo $template_root




if [[ $generate = 'y' ]]; then
        echo "Generating..."
        ./permutator.sh $config $batch $writetodisk
        if [[ $? -lt 0 ]]; then
                exit;
        fi
fi

# --------------------------------------------------------------------------------------------
# 3. Figure out how many jobs will be run and generate the gcam.pbs batch file
# --------------------------------------------------------------------------------------------


let "tasks=$last_task - $first_task + 1"
let "last_tasknum=$last_task + 1"
num_tasks=$(echo "
scale=5;
define ceil(number) {
   auto oldscale
   oldscale = scale
   scale = 0
   if(number != (number / 1)) {
      number = (number / 1) + 1
   } else {
      number /= 1
   }
   scale = oldscale
   return number
}
ceil($tasks / $num_cores)" | bc)


sed "s/NUM_TASKS/${num_cores}/g" $PBS_TEMPLATEFILE | sed "s/JOB_ARRAY/${first_task}-${last_task}/g" \
	> $PBS_BATCHFILE

# The job array will cycle through the jobs, so put an ID for each loop through

echo "
   srun -n ${num_cores} ./mpi_wrapper.exe ${template_path}/${template_root} \$SLURM_ARRAY_TASK_ID
"	>> $PBS_BATCHFILE

# --------------------------------------------------------------------------------------------
# 4  Go ahead and run!
# --------------------------------------------------------------------------------------------

if [[ $run = 'y' ]]; then

	rm -rf errors	# clean up from last time
	mkdir errors

        if [[ $email = 'y' ]]; then
             echo "
#SBATCH --mail-user EXAMPLE_EMAIL@pnnl.gov
#SBATCH --mail-type END
"                    >> $PBS_BATCHFILE

        fi

	job=`sbatch --parsable $PBS_BATCHFILE`
	echo "We are off and running with job $job"
        job2=$(sbatch --parsable --dependency=afterok:$job cat_queries.sh)
        # sbatch  -d afterok:$jobid1 ./cat_queries.sh
	./watch_pbs.sh

fi



exit
