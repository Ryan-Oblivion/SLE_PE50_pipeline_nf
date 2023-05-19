// define module


FASTP='fastp/intel/0.20.1'

FASTQC='fastqc/0.11.9'

BWA='bwa/intel/0.7.17'

SAMTOOLS='samtools/intel/1.14'

PICARD='picard/2.23.8'

// use picard or gatk?

GATK='gatk/4.3.0.0'

// this pipeline is created using the dsl2 commands
// so I can access that by using the next line
nextflow.enable.dsl=2



// first process below calles process_fqs_fastp

process process_fqs_fastp {



input:
// for the input i am using the parameters passed from the array .sh job but the names changed 
// here because of syntax seen in the workflow section at the end of this file

path read_f_kd
path read_r_kd
path out_f_kd
path out_r_kd



output:
// i used the name of the output created in the .sh slurm job and gave it a new variable 
// in the workflow section. then gave it a new variable for the next process to 
// call it with

path out_f_kd, emit: fastp_file1
path out_r_kd, emit: fastp_file2

// below is using unix coding to call the fastp module and give the inputs and outputs

"""
#!/bin/env bash
# if this works i can just do the slurm array here and get it to run 3 fastp arrays



module load $FASTP

module load $FASTQC


fastp \
-i $read_f_kd \
-I $read_r_kd \
-o $out_f_kd \
-O $out_r_kd \
--detect_adapter_for_pe \
--trim_front1 7 \
--trim_front2 7 \
--dedup \
#--length_required 76 \
#--n_base_limit 50 \
#--detect_adapter_for_pe \


fastqc $out_f_kd $out_r_kd



"""

}

// this is the second process called align_bwa. the inputs are the files generated from the last 
// process and given the output channel names of fastp_file1 fastp_file2
// which can now be used as the input names


nextflow.enable.dsl=2


process align_bwa {

input: 
path fastp_file1
path fastp_file2
path index_file
path ref

output:
// this output creates a bam and gives it the bam_file name to channel it to the next process

path 'aligned_reads_w_header.bam', emit: bam_file


"""
#!/bin/env bash

module load $BWA
module load $SAMTOOLS


bwa index -a bwtsw $ref

bwa aln -t 8 $ref $fastp_file1 > reads_1.sai
bwa aln -t 8 $ref $fastp_file2 > reads_2.sai

bwa sampe $ref reads_1.sai reads_2.sai $fastp_file1 $fastp_file2 \
> aligned_reads.sam

samtools view -b -h -q 20 aligned_reads.sam -o aligned_reads_w_header.bam


"""


}

// new process to coordinate sort the bam file

process coor_sort_picard{
cpus 10
memory '46 GB'
executor 'slurm'

input:
// this has a new input that changes the name to a the samples name, so we have different 
// bam files at the end of each job. this name was made in the .sh file and was changed 
// to a new variable in the workflow

path bam_file
path out_f_kd

output:
// for the output i added .bam to that sample name i wanted to be specific to each slurm array 
// job

path "${out_f_kd}.bam", emit: coor_sorted_bam

"""


module load $PICARD
module load $SAMTOOLS

# i am not using picard anymore since i couldnt use bwa mem

#java -Xmx44g -jar \$PICARD_JAR SortSam \
#I=$bam_file \
#O="${out_f_kd}.bam" \
#SORT_ORDER=coordinate \

samtools sort $bam_file -o "${out_f_kd}.bam" -O bam

# we always have to create a BAM index file on any coordinate sorted BAM. 
# NOT possible to do so if it is not coordinate sorted

samtools index -b "${out_f_kd}.bam" 

#location="\$(find . -name "${out_f_kd}.bam"'*')"  
#cp \$location /scratch/rj931/tf_sle_project/store_bam_files
"""
}


// here is the workflow section that manages all the processes and channels
// the first four lines show how to get the inputs from the .sh file and give them new 
// variables that nextflow can keep track of.
// then you also get the index file and ref to have their own unique variables

// now we get to the main section where we tell nextflow wich process runs first second and
// third just by the order we place them in. then in the parameters of each process i 
// place the inputs i want that process to take. this is how nextflow manages its workflow

workflow {

// i want to specify which are kd (knockdown) and which are ctr (control)
read_f_kd = Channel.fromPath(params.param1)
read_r_kd = Channel.fromPath(params.param2)
out_f_kd = Channel.fromPath(params.param3)
out_r_kd = Channel.fromPath(params.param4)

// ctr (control)

read_f_ctr = Channel.fromPath(params.param5)
read_r_ctr = Channel.fromPath(params.param6)
out_f_ctr = Channel.fromPath(params.param7)
out_r_ctr = Channel.fromPath(params.param8)

index_file = Channel.fromPath(params.dir_ref_files)
ref = Channel.fromPath(params.ref)

main:

// maybe this could work where i tell nf to run
// a process multiple times with different inputs

process_fqs_fastp(read_f_kd, read_r_kd, out_f_kd, out_r_kd)
// process_fqs_fastp(read_f_ctr, read_r_ctr, out_f_ctr, out_r_ctr)

align_bwa(process_fqs_fastp.out.fastp_file1, process_fqs_fastp.out.fastp_file2, index_file, ref)
coor_sort_picard(align_bwa.out.bam_file, out_f_kd)


//coor_sort_picard.out.coor_sorted_index_bam.view()
//process_fqs_fastp.out.fastp_file1.view()
//process_fqs_fastp.out.fastp_file2.view()
//align_bwa.out.bam_file.view()

}




