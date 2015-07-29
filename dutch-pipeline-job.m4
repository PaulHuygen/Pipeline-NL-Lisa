m4_include(inst.m4)m4_dnl
#!/bin/bash
#PBS -lnodes=1
<!#!>PBS -lwalltime=<!!>m4_walltime
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
STARTTIME=`date +%s`
LOGGING=true
BOOKKEEPFILE=$DATAROOT/timelog
#
# Python
#
module load python/m4_pythonversion
export PYTHONPATH=m4_pythonroot/lib/python2.7/site-packages:$PYTHONPATH
export PATH=m4_pythonroot/bin:$PATH
#
# Data trays
#
INTRAY=$DATAROOT/intray
OUTTRAY=$DATAROOT/outtray
FAILTRAY=$DATAROOT/failtray
LOGTRAY=$DATAROOT/logtray
mkdir -p $OUTTRAY
mkdir -p $FAILTRAY
mkdir -p $LOGTRAY

#
# Move/copy a file and create (part of) path if necessary.
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


m4_dnl function move_oldprocs_back () {
m4_dnl   while 
m4_dnl     oldproc=`find $INTRAY -amin +30 -print 2>/dev/null | head -n 1`
m4_dnl   do
m4_dnl     if 
m4_dnl       [ ! "$oldproc" == "" ]
m4_dnl     then
m4_dnl      TRUNK=${oldproc#$PROCTRAY/}
m4_dnl      INFILE=$INTRAY/$TRUNK
m4_dnl      movefile $oldproc $PROCTRAY $INTRAY
m4_dnl     fi
m4_dnl   done
m4_dnl }


#
# Get a filename
# Set variables INFILE, OUTFIL, FAILFILE
#
function getfile() {
  INFILE=""
  OUTFILE=""
  stopos -p $STOPOSPOOL next
  if
    [ "$STOPOS_RC" == "OK" ]
  then
    INFILE=$STOPOS_VALUE
    FILTRUNK=${INFILE##$INTRAY/}
    OUTFILE=$OUTTRAY/${FILTRUNK}
    LOGFILE=$LOGTRAY/${FILTRUNK}
    FAILFILE=$FAILTRAY/${FILTRUNK}
    OUTPATH=${OUTFILE%/*}
    FAILPATH=${FAILFILE%/*}
    LOGPATH=${LOGFILE%/*}
    echo To process $INFILE
  fi
}

m4_dnl function getfile() {
m4_dnl   INFILE=""
m4_dnl   PROCFILE=""
m4_dnl   OUTFILE=""
m4_dnl   FAILFILE=""
m4_dnl   passeer
m4_dnl     INFILE=`find $INTRAY -name *.m4_extens -print 2>/dev/null | head -n 1`
m4_dnl     if
m4_dnl       [ "$INFILE" == "" ]
m4_dnl     then
m4_dnl       move_oldprocs_back
m4_dnl       INFILE=`find $INTRAY -name *.m4_extens -print 2>/dev/null | head -n 1`
m4_dnl     fi
m4_dnl     if
m4_dnl       [ ! "$INFILE" == "" ]
m4_dnl     then
m4_dnl       TRUNK=${INFILE#$INTRAY/}
m4_dnl       PROCFILE=$PROCTRAY/$TRUNK
m4_dnl       OUTFILE=$OUTTRAY/$TRUNK
m4_dnl       movefile $INFILE $INTRAY $PROCTRAY
m4_dnl     fi
m4_dnl   veilig
m4_dnl }


#
# Process PROCFILE and place result in OUTFILE
function testprocess () {
  copyfile $PROCFILE $PROCTRAY $OUTTRAY
}

function process_file () {
  OLDD=`pwd`
  TEMPDIR=`mktemp -t -d ontemp.XXXXXX`
  cd $TEMPDIR
  cat $INFILE    | $PIPEBINDIR/tok           > tok.naf
  cat tok.naf    | $PIPEBINDIR/mor           > mor.naf
  cat mor.naf    | $PIPEBINDIR/nerc_conll02  > nerc.naf
  cat nerc.naf   | $PIPEBINDIR/wsd           > wsd.naf
  cat wsd.naf    | $PIPEBINDIR/ned           > ned.naf
  cat ned.naf    | $PIPEBINDIR/heideltime    > otimes.naf
  cat otimes.naf | gawk -f $PIPEBINDIR/remprol.awk  > times.naf
  cat times.naf  | $PIPEBINDIR/onto          > onto.naf
  cat onto.naf   | $PIPEBINDIR/srl           > srl.naf
  cat srl.naf    | $PIPEBINDIR/evcoref       > ecrf.naf
  cat ecrf.naf   | $PIPEBINDIR/framesrl      > fsrl.naf
  cat fsrl.naf   | $PIPEBINDIR/dbpner        > dbpner.naf
  cat dbpner.naf | $PIPEBINDIR/nomevent      > nomev.naf
  cat nomev.naf  | $PIPEBINDIR/postsrl             > out.naf
  if
     [ -e out.naf -a $(stat -c%s "out.naf") -gt 700 ]
  then
    mkdir -p $OUTPATH
    cp $TEMPDIR/out.naf $OUTFILE
    echo Produced $OUTFILE of size $(stat -c%s "$OUTFILE")
  else
     if
       [ ! -e $TEMPDIR/file.out.naf ]
     then
       echo Not produced: $OUTFILE
     else
       Too small $OUTFILE: $(stat -c%s "out.naf") 
     fi
  fi
  cd $OLDD
  rm -rf $TEMPDIR 
}

m4_dnl function startspotlight () {
m4_dnl   spotlightdir=$PIPEROOT/env/spotlight/
m4_dnl   spotlightjar=dbpedia-spotlight-0.7-jar-with-dependencies-candidates.jar
m4_dnl   cd $spotlightdir
m4_dnl   java -jar -Xmx8g $spotlightdir/$spotlightjar nl http://localhost:2060/rest  &
m4_dnl }
m4_dnl 
m4_dnl function waitforspotlight () {
m4_dnl    spottasks=0
m4_dnl    while
m4_dnl      [ $spottasks -eq 0 ]
m4_dnl    do
m4_dnl      echo Counting to ten ...
m4_dnl      sleep 10
m4_dnl      spottasks=`netstat -an | grep :2060 | wc -l`
m4_dnl    done
m4_dnl }

function startspotlight () {
   spotnl
}

function waitforspotlight () {
  sleep 1
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



m4_dnl function add_to_processed_list () {
m4_dnl   passeer
m4_dnl   echo `date %s` $1 $2 >>$BEING_PROCESSED_LIST
m4_dnl   veilig
m4_dnl }
m4_dnl 
m4_dnl function remove_processed_file () {
m4_dnl   key=$1
m4_dnl   passeer
m4_dnl     mv $BEING_PROCESSED_LIST $TEMP_BEING_PROCESSED_LIST
m4_dnl     gawk '$2 == key { next } ; {print}' key=$key $TEMP_BEING_PROCESSED_LIST > $BEING_PROCESSED_LIST
m4_dnl     rm $TEMP_BEING_PROCESSED_LIST
m4_dnl   veilig
m4_dnl #  stopos remove -p $POOL $key
m4_dnl }


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
m4_dnl       testprocess
      process_file
      if
         [ -e $OUTFILE -a $(stat -c%s "$OUTFILE") -gt m4_min_outfilesize ]
      then
         rm $INFILE
      else
         movefile $INFILE $INTRAY $FAILTRAY
      fi
m4_dnl       if
m4_dnl          [ -s $OUTFILE ]
m4_dnl       then
m4_dnl          rm $PROCFILE
m4_dnl       else
m4_dnl          movefile $PROCFILE $PROCTRAY $FAILTRAY
m4_dnl       fi
#      process_file $INFILE
#     $SCRIPT < $INTRAY/$INFILE >$PROCTRAY/$INFILE
#      mv $PROCTRAY/$INFILE $OUTTRAY
#      removefromlist
      echo $PROCNUM: $PROCFILE processed
      ETIME=`date +%s`
      stopos -p $STOPOSPOOL remove
#      echo `stat --printf="%s" $INFIL`"	$(($ETIME - $BTIME))	$INFILE	$ALPCOMMAND" >> $BOOKKEEPFILE
    done
  ) &
done
wait

exit
