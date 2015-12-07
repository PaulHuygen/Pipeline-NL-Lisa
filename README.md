Pipeline-NL-Lisa
================

Dutch pipeline on Lisa computer (SurfSara). An infra-structure and a
template for a job to process texts with modules of the dutch pipeline
of the CLTL (Computational Lexicology and Terminology Lab, VU
university, Amsterdam). The modules themselves can be installed
separately with [this Github repository](https://github.com/PaulHuygen/dutch-nlp-modules-on-Lisa).

# How to use it (outline)

1. Clone this repository.
2. Put a directory with input NAF-files somewhere on the Lisa filesystem.
3. When the suffix of the inputfiles is not "naf", edit variable
   "m4_extens" in `inst.m4`.    
4. Run script `start`, with the directory of NAF files as argument.
5. Run script `runit` regularly.
6. Retrieve the result from directory `data/outtray`.

# How it works

For each module there is a script that processes a file obtained from
standard in and produces the result on standard out. Generally the
scripts read and write NAF format. The first step (tokenizer) reads
plain text and produces NAF.

The job-script `dutch-pipeline-job` picks NAF files from an "intray",
have them processed by a sequence of modules. When processing has been
completed, the script writes the resulting file in the "outtray"
(ii.e. `data/outtray`) and removes the inputfile. When processing
fails the script moves the inputfile to `data/failtray`. The
job-script can process multiple files at the same time (parallel) and
multiple copies of the job-script can run at the same time on multiple
nodes of Lisa.

To prevent that two or more jobs process the same file,
the [Stopos](https://surfsara.nl/systems/lisa/software/stopos) package
of SurfSara is used. Stopos creates a "pool" that contains the names
of the files to be processed. When a process picks a name from this
pool, it is guaranteed that no other process will pick the same filename.

The job-scripts have time limits. When a job-script has been running
longer than the time-limit, it is aborted by Lisa and the NAF files that
the script was processing remain unprocessed. Therefore the Stopos
pool has to be re-generated. 

A job manager script `runit` generates or re-generates the stopos pool
when this is necessary, counts the number of submitted jobs and
submits more jobs when necessary.

An attempt is made to parameterize this package. Parameters (e.g. the
maximum time alotted to jobs or the suffix of NAF files) are stored in
`inst.m4` and the M4 preprocessor places them in the scripts. 


# Loose ends

## Memory management

The number of processes that can run parallel in a node is limited by
the amount of memory that the programs need. Therefore, the number of
parallel processes is determined by the modules in the pipeline. I
have not yet found an easy way to automatically determine how many
processes can run in parallel.

## Aborted processes

Usually jobs are aborted while they are processing files. As a result,
processing of those files will not be completed. Currently, now and
then the stopos pool has to be re-generated. What
is needed is a management module that runs on a regular basis
(e.g. cron job) and that performs this job.

