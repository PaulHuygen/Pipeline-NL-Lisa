cltl-magicplace
================

Annotate large quantities of raw NAF documents with the Newsreader
pipeline on the [Lisa computer of SurfSara, NL](https://www.surf.nl/en/services-and-products/lisa-compute-cluster/index.html). This packages provides an infra-structure and a
template for a job to process texts with modules of the
[Newsreader-pipeline](http://www.newsreader-project.eu/). The `nlpp`
packages must be installed
separately on Lisa, using [this Github repository](https://github.com/cltl/nlpp).

# How to use it (outline)

1. Clone this repository in a directory in Lisa.
2. Install [nlpp](https://github.com/cltl/nlpp) on Lisa. Then define in
   `nuweb/inst.m4` variable `m4_pipelineroot` as a pointer to the `nlpp`
   script in the `nlpp` package (e.g. write 
   `m4_define(m4_pipelineroot, /home/phuijgen/nlp/nlpp)m4_dnl`
3. Cd to subdirectory `nuweb` and perform `make source`. 
4. Create a sub-directory `data/in` and place a directory-tree that
   contains raw NAF documents in that directory.
5. Run script `runit`. This script submits jobs that will perform the annotation.
6. The jobs generate subdirectories `data/out`, `data/fail`, `data/log`
   and `data/proc` that contain resp. the annotated documents, documents
   on which `nlpp` failed, log-files and documents that are currently being processed. 
7. It might be that the submitted jobs did not have enough time to process all documents.
   In that case, re-run the `runit` script.
8. Retrieve the result from directory `data/outtray`.

# How it works

This is a simplified description on the workng process. The detailed
description can be find in the literate program code:
`nuweb/cltl-magicplace.pdf`. 

The `runit` script generates a list of paths to files in the `data/in`
tree. It places the list in a [Stopos](https://surfsara.nl/systems/lisa/software/stopos)
pool. Parallel running processes can pick elements (i.e. filenames) from the Stopos pool
and Stopos makes sure that each element is passed to at most one
process. Then the `runit` script counts
the number of files that have to be processed and calculates the number of jobs that are
needed to do this. When there are not enough jobs in the queue of the
job-control system of Lisa,
`runit` submits more jobs.

Jobs execute the job script `magicplace_2` during at most half an
hour on a single node. Each job generates parallel processes. The number of parallel
processes is dependent of the amount of memory and the number of CPU's
that are available in the node. Each process
performs a cycle in which it picks the path to an input-file from the stopos pool,
moves the corresponding file from `data/in` to `data/proc`, and then
applies the `nlpp` script on it. If the `nlpp` script finishes
succesfully, the process writes the result in `data/out` and removes
the input-file from `data/proc`. Otherwise it moves the input-file from
`data/proc` to `data/fail`. The `nlpp` script produces a log-file in
`data/log`. A process stops when there are no items left in the Stopos
pool or when the job aborts due to the run-time limitation. In the
latter case the input-file is left orphanaged in `data/proc`.

The 'runit' script moves old files from `data/proc` back to `data/in`
and removes very old files from `data/out`, `data/fail` and `data/log`.


