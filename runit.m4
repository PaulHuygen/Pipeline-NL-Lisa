m4_include(inst.m4)m4_dnl
#!/bin/bash
# runit -- start processing with dutch pipeline
#
# Directories
#
#
# Stopos
#
module load stopos
export STOPOSPOOL=m4_stopospool
#
# Paths
#
PROJROOT=m4_projroot
DATAROOT=$PROJROOT/data
PIPEROOT=m4_piperoot
PIPEBINDIR=$PIPEROOT/bin
export PATH=/home/phuijgen/usrlocal/bin:$PATH
#
# Language
#
export LANG=en_US.utf8
export LANGUAGE=en_US.utf8
export LC_ALL=en_US.utf8
#
# Logging
#
m4_changequote(`<!',`!>')m4_dnl
STARTTIME=`date +%s`
m4_changequote(<!`!>,<!'!>)m4_dnl
LOGGING=true
BOOKKEEPFILE=$DATAROOT/timelog
#
# Data trays
#
INTRAY=$DATAROOT/intray
OUTTRAY=$DATAROOT/outtray
FAILTRAY=$DATAROOT/failtray
JOBSCRIPT=dutch-pipeline-job
JOBSCRIPTTEMPLATE=$JOBSCRIPT.m4
#
# Count files and jobs
#
stopos -p m4_stopospool status
UNTOUCHED_FILES=$STOPOS_PRESENT0
UNPROCESSED_FILES=$STOPOS_PRESENT
m4_changequote(`<!',`!>')m4_dnl
READYFILCOUNT=`find $OUTTRAY -type f -print | wc -l`
SUBMITTED_JOB_COUNT=`qstat -u  phuijgen | grep dutch | wc -l` 
m4_changequote(<!`!>,<!'!>)m4_dnl
if
  [ $UNTOUCHED_FILES -eq 0  -o $SUBMITTED_JOB_COUNT -eq 0 ]
then
  echo UNTOUCHED_FILES: $UNTOUCHED_FILES
  echo SUBMITTED_JOB_COUNT: $SUBMITTED_JOB_COUNT
  ./resetpool
  UNTOUCHED_FILES=$STOPOS_PRESENT0
  UNPROCESSED_FILES=$STOPOS_PRESENT
fi
# 
# Submit jobs
#
FILESPERJOB=100
if
  [ $UNTOUCHED_FILES -gt 0 ]
then
  JOBS_NEEDED=$((UNPROCESSED_FILES / $FILESPERJOB))
  if
    [ $JOBS_NEEDED -lt 1 ]
  then
    JOBS_NEEDED=1
  fi
fi  
COUNTER=$((JOBS_NEEDED - $SUBMITTED_JOB_COUNT))
if
  [ $COUNTER -gt 0 ]
then
  qsub -t 1-$COUNTER $JOBSCRIPT
fi
#
# Report
#
echo Jobs submitted:  $((SUBMITTED_JOB_COUNT + COUNTER))
echo Texts waiting:   $UNTOUCHED_FILES
echo Texts ready:     $READYFILCOUNT
