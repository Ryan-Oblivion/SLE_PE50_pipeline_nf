# SLE_PE50_pipeline_nf
This is a nextflow pipeline for analyzing PE50 reads from Cut&amp;Run data also bulk RNA seq data
I am creating this pipeline to take PE50 reads generated from Cut&Run_seq and bulk RNA-seq. 
The pipeline is ran in the slurm job scheduler and requires a txt file that contains 4 columns (see ELF1_Mock_CutRun_kd_ctr.txt). 
The first two columns should have the forward and reverse reads for the knockdown replicate and the second two columns contain the forward 
and reverse reads for the control replicates. We will have multiple text files each containing this format for each condition and transcription factor. 
I will add a .txt file to show as an example. The .txt file will be in the same directory as all the fastq.gz files.

I will add more information here once I develop the pipeline more.
Now the Pipeline generates the .bam and .bai files and I can add another process to input these files into MACS2 and homer for the cut&run data.

How the bam files are named: They will use the name of the first read from the two PE reads that were used to create them. Followed by the steps used up
to that point. For example .filt.fastq.gz, shows that filtered fastq.gz PE files were used to finally get the .filt.fastq.gz.bam file. (454-Mock-n1-_cut-and-run_S1_L001_R1_001.filt.fastq.gz.bam)


