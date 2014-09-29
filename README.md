Pipeline-NL-Lisa
================

Dutch pipeline on Lisa computer (SurfSara). An infra-structure and a
template for a job to process texts with modules of the dutch pipeline
of the CLTL (Computational Lexicology and Terminology Lab, VU
university, Amsterdam). The modules themselves can be installed
separately with [this Github repository](https://github.com/PaulHuygen/dutch-nlp-modules-on-Lisa).

# How to use it (outline)

1. Clone this repository.
2. Put inputfiles in directory `data/intray`.
3. Edit `dutch-pipeline-job.m4`.
4. Start script `runit`.
5. Manage.
6. Retrieve the result from directory `data/outtray`.

# How it works

For each module there is a script that processes a file obtained from
standard in and produces the result on standard out. Generally the
scripts read and write NAF format. The first step (tokenizer) reads
plain text and produces NAF.

To do the work, a job-script is submitted to the job-management system
of Lisa. Script `dutch-pipeline-job` is a template that can be
used. The job-script can be submitted multiple times and then run parallel
to each other. To prevent that two or more jobs process the same file,
the [Stopos](https://surfsara.nl/systems/lisa/software/stopos) package
of SurfSara is used. Stopos creates a "pool" that contains the names
of the files to be processed. When a process picks a name from this
pool, it is guaranteed that no other process will pick the same filename.

Each job has a maximum duration ("wall-time") of thirty minutes, after
which it is aborted. As a result, processing some of the files will
never be completed. Currently the user has to find out which files
have gone stuck and re-submit them.



# Loose ends

## Memory management

The number of processes that can run parallel in a node is limited by
the amount of memory that the programs need. Therefore, the number of
parallel processes is determinied by the modules in the pipeline. I
have not yet fount an easy way to automatically determine how many
processes can run in parallel.

## Aborted processes

Usually jobs are aborted while they are processing files. As a result,
processing of those files will not be completed. Currently, the
unclompleted files must be identified and re-submitted manually. What
is needed is a management module that runs on a regular basis
(e.g. cron job) and that performs thins job.
