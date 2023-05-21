// defining modules


HOMER='homer/4.11'

REMOVEST='samtools/intel/1.12'

SAMTOOLS='samtools/intel/1.14'


nextflow.enable.dsl=2


process homer_tag_dir {

input:
path kd_bam_name
path ctr_bam_name
path path_to_bam_files

output:

path "${path_to_bam_files}/${kd_bam_name}_peaks.txt", emit: peaks_txt

"""
#module unload $REMOVEST
module load $HOMER
module swap $REMOVEST $SAMTOOLS

# makeTagDirectory still reconizes the file as bam without the format parameter
# the tbp 1 parameter should remove all duplicate reads that start at the same position

cd $path_to_bam_files

makeTagDirectory $kd_bam_name'_tag_dir/' $kd_bam_name'.filt.fastq.gz.bam' -tbp 1

makeTagDirectory $ctr_bam_name'_tag_dir/' $ctr_bam_name'.filt.fastq.gz.bam' -tbp 1

findPeaks $kd_bam_name'_tag_dir/' -style factor -i $ctr_bam_name'_tag_dir/' -o $path_to_bam_files'/'$kd_bam_name'_peaks.txt'

 
"""
}



workflow {

kd_bam_name = Channel.fromPath(params.param1)
ctr_bam_name = Channel.fromPath(params.param2)

path_to_bam_files = Channel.fromPath(params.param3)

main:

homer_tag_dir(kd_bam_name, ctr_bam_name, path_to_bam_files)
//homer_motif(homer_tag_dir.out.peaks_txt)

}
