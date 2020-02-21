#!/bin/bash 

# This is the main script used for running GCAM on the Evergreen cluster
# It is adapted from the NERSC version!

EXPECTED_ARGS=2

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
echo "Syncing magicc directory to $SCRATCH..."


cd ${SCRATCH}/${RUN_DIR_NAME}


# --------------------------------------------------------------------------------------------
# 2. Generate the required permutations of the base configuration file
# --------------------------------------------------------------------------------------------
        
template_path=`dirname $1`
template_root=`basename $1 | cut -f 1 -d.`
echo $template_path
echo $template_root

# Read in necessary variables from user 
echo "Generate permutations (y/n)?"
read generate

echo "First task number to run (normally 0)?"
read first_task

echo "Last task number to run (normally same as number of permutations - 1)?"
read last_task

echo "Number of cores to use?"
read num_cores

echo "Run $tasks tasks on cluster (y/n)?"
read run

if [[ $run = 'y' ]]; then
	echo "Would you like to be emailed when the job is done? (y/n)"
	read email
fi



if [[ $generate = 'y' ]]; then
        echo "Generating..."
        ./permutator.sh $1 $2 $generate
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

# put the loop code into the batch file rather than just generating
# all the mpiruns here because there was a limit to 10 apruns in a 
# single batch file for nersc and we are esentially maintaining
# compatability
echo "
ap_run_set=1
# stop one before the end to make sure we don't over allocate runs
while [ \$ap_run_set -lt $num_tasks ]
do
   let \"curr_first_task=$first_task + (\$ap_run_set - 1) * $num_cores\"
   srun -n ${num_cores} ./mpi_wrapper.exe ${template_path}/${template_root} \${curr_first_task}
   let \"ap_run_set=\$ap_run_set + 1\"
done
# add the last one but make sure we adjust the number of cores so we don't
# allocate more than the user wanted
let \"curr_first_task=$first_task + (\$ap_run_set - 1) * $num_cores\"
let \"leftoever_cores=$last_tasknum - \$curr_first_task\"
srun -n \${leftoever_cores} ./mpi_wrapper.exe ${template_path}/${template_root} \${curr_first_task}
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
