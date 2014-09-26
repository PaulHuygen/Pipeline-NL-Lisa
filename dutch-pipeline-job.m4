m4_include(inst.m4)m4_dnl
#!/bin/bash
#PBS -lnodes=1
#PBS -lwalltime=30:00
ROOT=m4_aprojroot
STARTTIME=`date +%s`
LOGGING=true
DATAROOT=$ROOT/data
BINDIR=$ROOT/bin
POOL=defaultpool

INTRAY=$DATAROOT/intray
OUTTRAY=$DATAROOT/outtray
MODDIR=/home/phuijgen/nlp/dutch-nlp-modules-on-Lisa/modules

TEMPTRAY=$DATAROOT/temptray
BOOKKEEPFILE=$DATAROOT/timelog


# When 10 GB/process has been reserved, the steps alpinohack .. onto can run in one pipelins

function process_file () {
  FILNAM=$1
  cat $INTRAY/$1 | $MODDIR/tok | $MODDIR/mor > $OUTTRAY/$1  
#  $BINDIR/alpinohack <$DATAROOT/bioport_mor/$FILNAM >$DATAROOT/alpinohack/$FILNAM
#  $BINDIR/ner        <$DATAROOT/alpinohack/$FILNAM  >$DATAROOT/ner/$FILNAM
#  $BINDIR/wsd        <$DATAROOT/ner/$FILNAM         >$DATAROOT/wsd/$FILNAM
#  $BINDIR/onto       <$DATAROOT/wsd/$FILNAM         >$DATAROOT/onto/$FILNAM
#  $BINDIR/heidel     <$DATAROOT/onto/$FILNAM        >$DATAROOT/heidel/$FILNAM
#  $BINDIR/srl        <$DATAROOT/heidel/$FILNAM      >$DATAROOT/srl/$FILNAM
}

module load stopos

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


FILNAM=""

function getfile() {
  stopos next -p $POOL
  if
     [ "$STOPOS_RC" == "OK" ]
  then  
     FILNAM=$STOPOS_VALUE
     echo $PROCNUM, getfile: Got $FILNAM
  else
     FILNAM=""
     echo $PROCNUM, getfile: Got $FILNAM
  fi
}

function removefromlist() {
  stopos remove -p $POOL
}

export ALPINO_HOME=$HOME/nlp/Alpino
export PATH=$PATH:$ALPINO_HOME/bin
export SP_CSETLEN=212 
export SP_CTYPE=utf8 

cd $TMPDIR
export NCORES=`sara-get-num-cores`
export MEMORY=`head -n 1 < /proc/meminfo | gawk '{print $2}'`
export MEMCHUNKS=$((MEMORY / 10000000))

MAXPROCS=$((NCORES-1))
if
  [ $MEMCHUNKS -lt $MAXPROCS ]
then
  MAXPROCS=MEMCHUNKS
fi

export MAXPROCS
echo Cores: $NCORES
echo Memory: $MEMORY, allowing for $MEMCHUNKS divisions of 10 GB
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
#     $SCRIPT < $INTRAY/$FILNAM >$TEMPTRAY/$FILNAM
#      mv $TEMPTRAY/$FILNAM $OUTTRAY
      removefromlist
      echo $PROCNUM: $FILNAM processed
      ETIME=`date +%s`
#      echo `stat --printf="%s" $INFIL`"	$(($ETIME - $BTIME))	$FILNAM	$ALPCOMMAND" >> $BOOKKEEPFILE
    done
  ) &
done
wait

exit
