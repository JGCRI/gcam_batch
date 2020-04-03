
cores=$(echo "$3-$2"|bc)


sed "s/JOB_ARRAY/${2}-${3}/g" query_exe_template.sh | sed "s/num_cores/$cores/g" > query_exe.sh


job=`sbatch --parsable query_exes.sh $1`
echo "We are off and running with job $job"
job2=$(sbatch --parsable --dependency=afterok:$job cat_queries.sh)
echo "We are off and running with job $job2"