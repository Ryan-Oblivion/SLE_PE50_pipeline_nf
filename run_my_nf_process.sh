#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --partition=cm
#SBATCH --time=10:00:00
#SBATCH --mem=10GB
#SBATCH --job-name=test_nf
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=rj931@nyu.edu
#SBATCH --output=slurm_%j.out
#SBATCH --array=1


module purge

# loading the nextflow module below

module load nextflow/21.10.6

# giving the path to the txt file that contains the 4 columns, forward and reverse reads for KD, and control

PE_list='all_sle_data/ELF1_Mock_CutRun_kd_ctr.txt'

# using the array number to get the contents on that line, then separating the line by columns
# to get the name fo the foward read and name of the reverse read

line="$(less "$PE_list" | head -n ${SLURM_ARRAY_TASK_ID} | tail -n 1)"
file_f_kd="$(printf "%s" "${line}"| cut -f1)"
file_r_kd="$(printf "%s" "${line}"| cut -f2)"

# the control files
file_f_ctr="$(printf "%s" "${line}"| cut -f3)"
file_r_ctr="$(printf "%s" "${line}"| cut -f4)"

# below I realize i needed to put the name onto the location of the directory 
# this gets the full path of the foward file and reverse file

read_f_kd='/scratch/rj931/tf_sle_project/all_sle_data/'$file_f_kd'*'
read_r_kd='/scratch/rj931/tf_sle_project/all_sle_data/'$file_r_kd'*'


# the control files
read_f_ctr='/scratch/rj931/tf_sle_project/all_sle_data/'$file_f_ctr'*'
read_r_ctr='/scratch/rj931/tf_sle_project/all_sle_data/'$file_r_ctr'*'

# later I need to change the name to from the input name to an output name used in fastp as the 
# output name later in the first process

name_f_kd="$(basename -s .fastq.gz $file_f_kd ).filt.fastq.gz"
name_r_kd="$(basename -s .fastq.gz $file_r_kd ).filt.fastq.gz"


# now I want to do the same thing but for the control files which 
# are in the 3rd and 4th columns
name_f_ctr="$(basename -s .fastq.gz $file_f_ctr ).filt.fastq.gz"
name_r_ctr="$(basename -s .fastq.gz $file_r_ctr ).filt.fastq.gz"


# these echo lines are just for debugging

echo $line
echo $read_f_kd
echo $read_r_kd
echo $name_f_kd
echo $name_r_kd


# now call nextflow and tell it to run the name of my nextflow pipeline called final_project.nf
# I need to send all the variables i created above to the nf file so the pipeline can access
# them. i do this using the param parameters.
# I do not think i can use resume and could not figure out where to put it now that i have the 
# parameters there.

# making a new directory to store all the bam files in this condition

new_c_n="$(basename -s .txt $PE_list)"
new_dir='store_bam_files_'$new_c_n
mkdir $new_dir

nextflow run -resume process_KD_cutrun_reads.nf --param1 $read_f_kd --param2 $read_r_kd --param3 $name_f_kd --param4 $name_r_kd \
--param5 $read_f_ctr --param6 $read_r_ctr --param7 $name_f_ctr --param8 $name_r_ctr


nextflow run -resume process_ctr_cutrun_reads.nf --param1 $read_f_kd --param2 $read_r_kd --param3 $name_f_kd --param4 $name_r_kd \
--param5 $read_f_ctr --param6 $read_r_ctr --param7 $name_f_ctr --param8 $name_r_ctr

location="$(find . -name "4*.bam*")"
cp $location '/scratch/rj931/tf_sle_project/'$new_dir


# this is to get the fastqc files and the full names so i can
# use to generate a multiqc report
find $PWD -name \*fastqc.zip > fastqc_files.txt


# i want to name the multiqc file the condition it comes from

new_c_n="$(basename -s .txt $PE_list)"

module load multiqc/1.9

multiqc --file-list fastqc_files.txt --filename 'multiqc_'$new_c_n'.html'

# next, take all the bam files from the directory and use their
# basename to place into a txt file. 454, 455 in the first and 
# second columns respectively

# store_bam_files

path_to_bam_bai_files='/scratch/rj931/tf_sle_project/'$new_dir

cd $path_to_bam_bai_files

# now i need to create a name first for the file

bam_file_name=$new_dir'_bam.txt'
bai_file_name=$new_dir'_bai.txt'

basename -s .filt.fastq.gz.bam 454*.bam > 454_bam.txt
basename -s .filt.fastq.gz.bam 455*.bam > 455_bam.txt
paste 454_bam.txt 455_bam.txt > $bam_file_name

basename -s .filt.fastq.gz.bai 454*.bai > 454_bai.txt
basename -s .filt.fastq.gz.bai 455*.bai > 455_bai.txt
paste 454_bai.txt 455_bai.txt > $bai_file_name

# the variable bam_file_name, stores all the bam files for the 
# condition currently being processed.
# the variable bai_file_name, does the same for bai files


# below I need to make a tag dir for homer, will do that in the nf script

line2="$(less "$bam_file_name" | head -n ${SLURM_ARRAY_TASK_ID} | tail -n 1)" 

# storing the basename of the kd and ctr bam files
kd_bam="$(printf "%s" "${line2}" | cut -f1)"
ctr_bam="$(printf "%s" "${line2}" | cut -f2)"

# debugging to make sure the name is how i want
echo $kd_bam
echo $ctr_bam



########################################

# this section is just to test homer before i put it in a nf pipeline

#module load homer/4.11
#module load samtools/intel/1.14

# cant use format bam option but the program still knows its a bam file
# the tbp 1 parameter should remove all duplicate reads that start at the same position

#makeTagDirectory $kd_bam'_tag_dir/' $kd_bam'.filt.fastq.gz.bam' -tbp 1

#makeTagDirectory $ctr_bam'_tag_dir/' $ctr_bam'.filt.fastq.gz.bam' -tbp 1


# now we run the tool to find peaks, with the kd tag dir and ctr tag dir

#findPeaks $kd_bam'_tag_dir/' -style factor -i $ctr_bam'_tag_dir/' -o 
#$path_to_bam_bai_files$kd_bam'peaks.txt'

# now i have to go back to the directory that has the nf script
cd ../

nextflow run -resume homer_pipeline.nf  --param1 $kd_bam --param2 $ctr_bam --param3 $path_to_bam_bai_files 


