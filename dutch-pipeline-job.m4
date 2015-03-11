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
BOOKKEEPFILE=$DATAROOT/timelog


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
  stopos remove -p $POOL $key
}


startspotlight


FILNAM=""

#
# Get a filename and put it in FILNAM
#
function getfile() {
  passeer
    FILNAM=`ls -1 $INTRAY | head -n 1`
    if
      [ "$FILNAM" == "" ]
    then
      find $PROCTRAY/* -amin +30 -print 2>/dev/null | xargs -Iaap mv aap  $INTRAY
      FILNAM=`ls -1 $INTRAY | head -n 1`
    fi
    if
     [ ! "$FILNAM" == "" ]
    then
      mv $INTRAY/$FILNAM $PROCTRAY
    fi
  veilig
}



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
      echo $PROCNUM, while: Got $FILNAM
      [ ! -z "$FILNAM" ] 
    do
      BTIME=`date +%s`
      echo $PROCNUM: Got file $FILNAM
      process_file $FILNAM
#     $SCRIPT < $INTRAY/$FILNAM >$PROCTRAY/$FILNAM
#      mv $PROCTRAY/$FILNAM $OUTTRAY
#      removefromlist
      echo $PROCNUM: $FILNAM processed
      ETIME=`date +%s`
#      echo `stat --printf="%s" $INFIL`"	$(($ETIME - $BTIME))	$FILNAM	$ALPCOMMAND" >> $BOOKKEEPFILE
    done
  ) &
done
wait

exit
