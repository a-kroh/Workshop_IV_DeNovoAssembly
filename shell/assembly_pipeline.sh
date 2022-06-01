############################ Assembly pipeline ####################################

### In this workshop, we will reconstruct continuous (i.e. syntenic) stretches of DNA (so called contigs) from the genome of the fish Garra longipinnis (Luise's and Sandra's favourite pet's) using three types of sequencing data.

################### (1) Clone Github repository ###################

### As a first step, you will have cloned the GitHub repository of this workshop to your home directory. If this is not the case, you should do it now using the following command

git clone https://github.com/nhmvienna/Workshop_IV_DeNovoAssembly

### now, let's have a look at the data, what do we have?

cd Workshop_IV_DeNovoAssembly/data

ls -l

cd Illumina/

ls -l

### What do the raw Illumina raw data look like?

gunzip -c Garra474_1.fq.gz | head -4

## What do these top 4 rows mean? Can

### ??? Can you repeat the same for the ONT data?

################### (2) DATA Quality ###################

### Next, we will examine the data quality of the Illumina dataset using the program FASTQC

mkdir -p ~/Workshop_IV_DeNovoAssembly/results/Illumina_QC

echo """
#!/bin/sh

## name of Job
#PBS -N fastqc

## Redirect output stream to this file.
#PBS -o ~/Workshop_IV_DeNovoAssembly/results/Illumina_QC/fastq_log.txt

## Stream Standard Output AND Standard Error to outputfile (see above)
#PBS -j oe

## Select 10 cores and 50gb of RAM
#PBS -l select=1:ncpus=10:mem=50g

######## load dependencies #######

module load Tools/FastQC-0.11.9

## loop through all raw FASTQ and test quality

fastqc \
  --outdir ~/Workshop_IV_DeNovoAssembly/results/Illumina_QC \
  --threads 10 \
  ~/Workshop_IV_DeNovoAssembly/data/Illumina/Garra474_1.fq.gz \
  ~/Workshop_IV_DeNovoAssembly/data/Illumina/Garra474_2.fq.gz

""" > ~/Workshop_IV_DeNovoAssembly/results/Illumina_QC/fastqc.sh

## Submit the job to OpenPBS

qsub ~/Workshop_IV_DeNovoAssembly/results/Illumina_QC/fastqc.sh

## check the status of your OpenPBS Job

qstat -awt

## once the job is finished, you can check the output in the browser

firefox ~/Workshop_IV_DeNovoAssembly/results/Illumina_QC/Garra474_1_fastqc.html
firefox ~/Workshop_IV_DeNovoAssembly/results/Illumina_QC/Garra474_2_fastqc.html

## What about the ONT dataset? We will use Nanoplot for this!


mkdir -p ~/Workshop_IV_DeNovoAssembly/results/ONT_QC

echo """
#!/bin/sh

## name of Job
#PBS -N fastqc

## Redirect output stream to this file.
#PBS -o ~/Workshop_IV_DeNovoAssembly/results/ONT_QC/fastq_log.txt

## Stream Standard Output AND Standard Error to outputfile (see above)
#PBS -j oe

## Select 10 cores and 50gb of RAM
#PBS -l select=1:ncpus=10:mem=50g

######## load dependencies #######

source /opt/anaconda3/etc/profile.d/conda.sh
conda activate nanoplot_1.32.1

######## run analyses #######

NanoPlot \
  -t 10 \
  --summary ~/Workshop_IV_DeNovoAssembly/data/ONT/sequencing_summary.txt \
  --plots dot \
  -o ~/Workshop_IV_DeNovoAssembly/results/ONT_QC

""" > ~/Workshop_IV_DeNovoAssembly/results/ONT_QC/nanoplot_ont.sh

## Submit the job to OpenPBS

qsub ~/Workshop_IV_DeNovoAssembly/results/ONT_QC/nanoplot_ont.sh

## check the status of your OpenPBS Job

qstat -awt

## once the job is finished, you can check the output in the browser

firefox ~/Workshop_IV_DeNovoAssembly/results/ONT_QC/NanoPlot-report.html

## for the PacBio data, we do not have a sequencing summary file as for the ONT data, thus, we need to use the FASTQ sequences for QC

mkdir -p ~/Workshop_IV_DeNovoAssembly/results/PacBio_QC

echo """
#!/bin/sh

## name of Job
#PBS -N fastqc

## Redirect output stream to this file.
#PBS -o ~/Workshop_IV_DeNovoAssembly/results/PacBio_QC/fastq_log.txt

## Stream Standard Output AND Standard Error to outputfile (see above)
#PBS -j oe

## Select 10 cores and 50gb of RAM
#PBS -l select=1:ncpus=10:mem=50g

######## load dependencies #######

source /opt/anaconda3/etc/profile.d/conda.sh
conda activate nanoplot_1.32.1

######## run analyses #######

NanoPlot \
  -t 10 \
  --fastq ~/Workshop_IV_DeNovoAssembly/data/PacBio/Garra_PB.fastq.gz \
  --plots dot \
  -o ~/Workshop_IV_DeNovoAssembly/results/PacBio_QC

""" > ~/Workshop_IV_DeNovoAssembly/results/PacBio_QC/nanoplot_pb.sh

## Submit the job to OpenPBS

qsub ~/Workshop_IV_DeNovoAssembly/results/PacBio_QC/nanoplot_pb.sh

## check the status of your OpenPBS Job

qstat -awt

## once the job is finished, you can check the output in the browser

firefox ~/Workshop_IV_DeNovoAssembly/results/PacBio_QC/NanoPlot-report.html

################### (3) Trimming of Illumina reads ###################

## Before we start the actual assembly, we need to "clean up" the Illumina reads, i.e. to trim away tails of the reads with low quality and adaptor sequences that were used for Illumina sequencing. We use the program trim_galore for that.

mkdir ~/Workshop_IV_DeNovoAssembly/results/trimmed

echo """
#!/bin/sh

## name of Job
#PBS -N trim_galore

## Redirect output stream to this file.
#PBS -o ~/Workshop_IV_DeNovoAssembly/results/trimmed/log.txt

## Stream Standard Output AND Standard Error to outputfile (see above)
#PBS -j oe

## Select 10 cores and 50gb of RAM
#PBS -l select=1:ncpus=10:mem=50g

######## load dependencies #######

source /opt/anaconda3/etc/profile.d/conda.sh
conda activate trim-galore-0.6.2

## loop through all FASTQ pairs and trim by quality PHRED 20, min length 85bp and automatically detect & remove adapters

cd ~/Workshop_IV_DeNovoAssembly/results/trimmed

trim_galore \
  --paired \
  --quality 20 \
  --length 85  \
  --cores 200 \
  --fastqc \
  --gzip \
  ~/Workshop_IV_DeNovoAssembly/data/Illumina/Garra474_1.fq.gz \
  ~/Workshop_IV_DeNovoAssembly/data/Illumina/Garra474_2.fq.gz

""" > ~/Workshop_IV_DeNovoAssembly/results/trimmed/trim.sh

qsub ~/Workshop_IV_DeNovoAssembly/results/trimmed/trim.sh

## check the status of your OpenPBS Job
qstat -awt

## once the job is finished, you can check the quality of the trimmed reads in the browser
firefox ~/Workshop_IV_DeNovoAssembly/results/trimmed/Garra474_1_val_1_fastqc.html
firefox ~/Workshop_IV_DeNovoAssembly/results/trimmed/Garra474_2_val_2_fastqc.html

################### (4) Genome-size estimation ###################

## Now that we have an idea the quality and trimmed Illumina reads we can use these data to get a rough idea about the expected size of the genome. Note that we are using only a very small subset. Thus, the estimate will only be very rough.

## First, we will use the program JellyFish to count the number of k-mers in the dataset. A k-mer is a unqiue sequence of a given length n (for example n=31bp) found in the pool of sequences. The original reads will therefore chopped down into substrings of size n, for example (n=5):

# ACGGTGAGGAT
# ACGGT
#  CGGTG
#   GGTGA
#    GTGAG
#     TGAGG
#      GAGGA
#       AGGAT

## After that, the Program GenomeScope will estimate the Genome-size based on the coverage distribution of the k-mers. See https://github.com/nhmvienna/AutDeNovo#3-genome-size-estimation for more details.

mkdir ~/Workshop_IV_DeNovoAssembly/results/genomesize

echo """
  #!/bin/sh

  ## name of Job
  #PBS -N jellyfish

  ## Redirect output stream to this file.
  #PBS -o ~/Workshop_IV_DeNovoAssembly/results/genomesize/jellyfish_log.txt

  ## Stream Standard Output AND Standard Error to outputfile (see above)
  #PBS -j oe

  ## Select a maximum walltime of 2h
  #PBS -l walltime=48:00:00

  ## Select 10 cores and 50gb of RAM
  #PBS -l select=1:ncpus=10:mem=50gb

  ## load all necessary software into environment
  module load Assembly/Jellyfish-2.3.0
  module load Assembly/genomescope-2.0

  ## unzip files
  gunzip -c ~/Workshop_IV_DeNovoAssembly/results/trimmed/Garra474_1_val_1.fq.gz \
  > ~/Workshop_IV_DeNovoAssembly/results/trimmed/Garra474_1_val_1.fq &
  gunzip -c ~/Workshop_IV_DeNovoAssembly/results/trimmed/Garra474_2_val_2.fq.gz \
  > ~/Workshop_IV_DeNovoAssembly/results/trimmed/Garra474_2_val_2.fq

  wait

  ## run Jellyfish
  ## parameters
  # -C canononical; count both strands
  # -m 31 Length of mers
  # -s initial hash size

  jellyfish-linux count \
    -C \
    -m 31 \
    -s 100M \
    -t 10 \
    -F 2 \
    -o ~/Workshop_IV_DeNovoAssembly/results/genomesize/reads.jf \
    ~/Workshop_IV_DeNovoAssembly/results/trimmed/Garra474_1_val_1.fq \
    ~/Workshop_IV_DeNovoAssembly/results/trimmed/Garra474_2_val_2.fq

  ## remove unzipped copy of reads
  rm -f ~/Workshop_IV_DeNovoAssembly/results/trimmed/Garra474_*_val_*.fq

  ## make a histogram of all k-mers
  jellyfish-linux histo \
    -t 10 \
    ~/Workshop_IV_DeNovoAssembly/results/genomesize/reads.jf \
    > ~/Workshop_IV_DeNovoAssembly/results/genomesize/reads.histo

  ## run GenomeScope

  genomescope.R \
  -i ~/Workshop_IV_DeNovoAssembly/results/genomesize/reads.histo \
  -k 31 \
  -p 2 \
  -o ~/Workshop_IV_DeNovoAssembly/results/genomesize/stats
""" > ~/Workshop_IV_DeNovoAssembly/results/genomesize/genomesize.sh

qsub  ~/Workshop_IV_DeNovoAssembly/results/genomesize/genomesize.sh

################### (5) De Novo Assembly ###################

## Now that we have an idea about the Approximate genome-size we can start the de-novo assembly
