m4_include(inst.m4)m4_dnl
#!/bin/bash
#PBS -lnodes=1
<!#!>PBS -lwalltime=<!!>m4_walltime
#ssh -N -f -L 2060:localhost:2060 huygen@kyoto.let.vu.nl
module load stopos
#PROJROOT=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
PROJROOT=m4_projroot
echo PROJROOT: $PROJROOT
DATAROOT=$PROJROOT/data
echo DATAROOT: $DATAROOT
PIPEROOT=m4_piperoot
PIPEBINDIR=$PIPEROOT/bin

STARTTIME=`date +%s`
LOGGING=true

module load python/m4_pythonversion
export PYTHONPATH=m4_pythonroot/lib/python2.7/site-packages:$PYTHONPATH
export PATH=/home/phuijgen/usrlocal/bin:m4_pythonroot/bin:$PATH

INTRAY=$DATAROOT/intray
OUTTRAY=$DATAROOT/outtray
PROCTRAY=$DATAROOT/proctray
FAILTRAY=$DATAROOT/failtray
mkdir -p $PROCTRAY
mkdir -p $OUTTRAY
mkdir -p $FAILTRAY
BOOKKEEPFILE=$DATAROOT/timelog

#
# Move a file and create (part of) path if necessary.
#
function movefile() {
   fullfile=$1
   oldtray=$2
   newtray=$3
   inpath=${fullfile%/*}
   trunk=${inpath#$oldtray} 
   outpath=$newtray/$trunk
   mkdir -p $outpath
   mv $fullfile $outpath/
}

function copyfile() {
   fullfile=$1
   oldtray=$2
   newtray=$3
   inpath=${fullfile%/*}
   trunk=${inpath#$oldtray} 
   outpath=$newtray/$trunk
   mkdir -p $outpath
   cp $fullfile $outpath/
}



function move_oldprocs_back () {
  while 
    oldproc=`find $INTRAY -amin +30 -print 2>/dev/null | head -n 1`
  do
    if 
      [ ! "$oldproc" == "" ]
    then
     TRUNK=${oldproc#$PROCTRAY/}
     INFILE=$INTRAY/$TRUNK
     movefile $oldproc $PROCTRAY $INTRAY
    fi
  done
}
#
# Get a filename and put it in FILNAM
# Set variables INFILE, PROCFIL, OUTFIL
#
function getfile() {
  INFILE=""
  PROCFILE=""
  OUTFILE=""
  FAILFILE=""
  passeer
    INFILE=`find $INTRAY -name *.m4_extens -print 2>/dev/null | head -n 1`
    if
      [ "$INFILE" == "" ]
    then
      move_oldprocs_back
      INFILE=`find $INTRAY -name *.m4_extens -print 2>/dev/null | head -n 1`
    fi
    if
      [ ! "$INFILE" == "" ]
    then
      TRUNK=${INFILE#$INTRAY/}
      PROCFILE=$PROCTRAY/$TRUNK
      OUTFILE=$OUTTRAY/$TRUNK
      movefile $INFILE $INTRAY $PROCTRAY
    fi
  veilig
}


#
# Process PROCFILE and place result in OUTFILE
function testprocess () {
  copyfile $PROCFILE $PROCTRAY $OUTTRAY
}

function process_file () {
  TEMPDIR=`mktemp -t -d ontemp.XXXXXX`
  FILNAM=$1
  cat $PROCTRAY/$FILNAM       | $PIPEBINDIR/tok        > $TEMPDIR/file.tok.naf
  cat $TEMPDIR/file.tok.naf   | $PIPEBINDIR/mor        > $TEMPDIR/file.mor.naf
  cat $TEMPDIR/file.mor.naf   | $PIPEBINDIR/nerc_conll02  > $TEMPDIR/file.nerc.naf
  cat $TEMPDIR/file.nerc.naf  | $PIPEBINDIR/wsd        > $TEMPDIR/file.wsd.naf
  cat $TEMPDIR/file.wsd.naf   | $PIPEBINDIR/ned        > $TEMPDIR/file.ned.naf
  cat $TEMPDIR/file.ned.naf   | $PIPEBINDIR/onto       > $TEMPDIR/file.onto.naf
  cat $TEMPDIR/file.onto.naf  | $PIPEBINDIR/heideltime > $TEMPDIR/file.times.naf
  cat $TEMPDIR/file.times.naf | $PIPEBINDIR/srl        > $TEMPDIR/file.srl.naf
  cat $TEMPDIR/file.srl.naf   | $PIPEBINDIR/evcoref    > $TEMPDIR/file.ecrf.naf
  cat $TEMPDIR/file.ecrf.naf  | $PIPEBINDIR/framesrl   > $OUTTRAY/$FILNAM
  rm $PROCTRAY/$FILNAM
  rm -rf $TEMPDIR 
}

function startspotlight () {
  spotlightdir=$PIPEROOT/env/spotlight/
  spotlightjar=dbpedia-spotlight-0.7-jar-with-dependencies-candidates.jar
  cd $spotlightdir
  java -jar -Xmx8g $spotlightdir/$spotlightjar nl http://localhost:2060/rest  &
}

function waitforspotlight () {
   spottasks=0
   while
     [ $spottasks -eq 0 ]
   do
     echo Counting to ten ...
     sleep 10
     spottasks=`netstat -an | grep :2060 | wc -l`
   done
}


waitabit()
{ ( RR=$RANDOM
    while
      [ $RR -gt 0 ]
    do
    RR=$((RR - 1))
    done
  )
  
}

export LOCKDIR=$TMPDIR/lock

function passeer () {
 while ! (mkdir $LOCKDIR 2> /dev/null)
 do
   waitabit
 done
}

function veilig () {
  rmdir "$LOCKDIR"
}



function add_to_processed_list () {
  passeer
  echo `date %s` $1 $2 >>$BEING_PROCESSED_LIST
  veilig
}

function remove_processed_file () {
  key=$1
  passeer
    mv $BEING_PROCESSED_LIST $TEMP_BEING_PROCESSED_LIST
    gawk '$2 == key { next } ; {print}' key=$key $TEMP_BEING_PROCESSED_LIST > $BEING_PROCESSED_LIST
    rm $TEMP_BEING_PROCESSED_LIST
  veilig
#  stopos remove -p $POOL $key
}


startspotlight
waitforspotlight


FILNAM=""



cd $TMPDIR
export NCORES=`sara-get-num-cores`
#export MEMORY=`head -n 1 < /proc/meminfo | gawk '{print $2}'`
export MEMORY=`sara-get-mem-size`
export MEMCHUNKS=$(((MEMORY - m4_spotlightmem_GB) / m4_GB_per_process))

MAXPROCS=$((NCORES-1))
if
  [ $MEMCHUNKS -lt $MAXPROCS ]
then
  MAXPROCS=$MEMCHUNKS
fi

export MAXPROCS
echo Cores: $NCORES
echo Memory: $MEMORY, allowing for $MEMCHUNKS divisions of m4_GB_per_process GB
echo Max. number of processes:  $MAXPROCS
echo 0 >$TMPDIR/proctal

PROCNUM=0
for ((i=1; i<= MAXPROCS ; i++)) 
do
  ( passeer
    PROCNUM=`cat $TMPDIR/proctal`
    echo Process number: $PROCNUM
    echo $((PROCNUM + 1 )) > $TMPDIR/proctal
    echo $PROCNUM: Proctal after increment: `cat $TMPDIR/proctal`
    veilig
    while
      getfile
      [ ! -z "$INFILE" ] 
    do
      BTIME=`date +%s`
      echo $PROCNUM: Got file $INFILE
      testprocess
      if
         [ -s $OUTFILE ]
      then
         rm $PROCFILE
      else
         movefile $PROCFILE $PROCTRAY $FAILTRAY
      fi
#      process_file $INFILE
#     $SCRIPT < $INTRAY/$INFILE >$PROCTRAY/$INFILE
#      mv $PROCTRAY/$INFILE $OUTTRAY
#      removefromlist
      echo $PROCNUM: $PROCFILE processed
      ETIME=`date +%s`
#      echo `stat --printf="%s" $INFIL`"	$(($ETIME - $BTIME))	$INFILE	$ALPCOMMAND" >> $BOOKKEEPFILE
    done
  ) &
done
wait

exit
