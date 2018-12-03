m4_changecom()#!/bin/bash
#PBS -lnodes=1
#PBS -lwalltime=m4_walltime
export eSRL_piddir=`mktemp -d -t eSRL_piddir.XXXXXX`
export semaworkdir=`mktemp -d -t sema.XXXXXX`

source /home/phuijgen/nlp/Pipeline-NL-Lisa/parameters
piddir=`mktemp -d -t piddir.XXXXXXX`
( export naflang="en" ; $BIND/start_eSRL $piddir ) &

export jobname=$PBS_JOBID
echo `date +%s`: Start job $jobname >> $timelogfile


export LANG=en_US.utf8
export LANGUAGE=en_US.utf8
export LC_ALL=en_US.utf8

module load stopos

module load python/2.7.9

function movetotray () {
local file="$1"
local fromtray="$2"
local totray="$3"
local frompath=${file%/*}
local topath=$totray${frompath##$fromtray}
mkdir -p $topath
mv "$file" "$totray${file##$fromtray}"
}

export -f movetotray

function copytotray () {
local file=$1
local fromtray=$2
local totray=$3
local frompath=${file%/*}
local topath=$totray${frompath##$fromtray}
mkdir -p $topath
cp $file $totray${file##fromtray}
}

export -f copytotray

function passeer () {
  local lock=$1
  sematree acquire $lock
}

function runsingle () {
  local lock=$1
  sematree acquire $lock 0 || exit
}


function veilig () {
  local lock=$1
  sematree release $lock
}


function remove_obsolete_lock {
  local lock=$1
  local max_minutes=$2
  if
    [ "$max_minutes" == "" ]
  then
   local max_minutes=60
  fi
  find $workdir -name $lock -cmin +$max_minutes -print | xargs -iaap rm -rf aap
}

function getfile() {
  infile=""
  outfile=""
  repeat=0
  while 
    [ $repeat -eq 0 ]
  do
    stopos -p $stopospool next
    if
      [ ! "$STOPOS_RC" == "OK" ]
    then
      infile=""
      repeat=1
    else
      infile=$STOPOS_VALUE
      if
        [ -e "$infile" ]
      then
        repeat=1
      fi
    fi
  done
  
  if
    [ ! "$infile" == "" ]
  then
    filtrunk=${infile##$intray/}
    export outfile=$outtray/"${filtrunk}"
    export failfile=$failtray/"${filtrunk}"
    export logfile=$logtray/"${filtrunk}"
    export procfile=$proctray/"${filtrunk}"
    export outpath=${outfile%/*}
    export procpath=${procfile%/*}
    export logpath=${logfile%/*}
    
  fi
}

function check_start_spotlight {
  language=$1
  if
    [ language == "nl" ]
  then
    spotport=2060
  else
    spotport=2020
  fi
  spotlighthost=130.37.53.33
  exec 6<>/dev/tcp/$spotlighthost/$spotport
  spotlightrunning=$?
  exec 6<&-
  exec 6>&-
  
  if
    [ $spotlightrunning -ne 0 ]
  then
    start_spotlight_on_localhost $language $spotport
    spotlighthost="localhost"
    spotlightrunning=0
  fi
  export spotlighthost
  export spotlightrunning
}
function start_spotlight_on_localhost {
   language=$1
   port=$2
   spotlightdirectory=/home/phuijgen/nlp/nlpp/env/spotlight
   spotlightjar=dbpedia-spotlight-0.7-jar-with-dependencies-candidates.jar
   if
     [ "$language" == "nl" ]
   then
     spotresource=$spotlightdirectory"/nl"
   else
     spotresource=$spotlightdirectory"/en_2+2"
   fi
   java -Xmx8g \
        -jar $spotlightdirectory/$spotlightjar \
        $spotresource \ 
        http://localhost:$port/rest \
   &
}

check_start_spotlight nl
check_start_spotlight en
echo spotlighthost: $spotlighthost >&2
echo spotlighthost: $spotlighthost
starttime=`date +%s`
export ncores=`sara-get-num-cores`
#export MEMORY=`head -n 1 < /proc/meminfo | gawk '{print $2}'`
export memory=`sara-get-mem-size`

export memchunks=$((memory / mem_per_process))
if
  [ $ncores -gt $memchunks ]
then
  maxprocs=$memchunks
else
  maxprocs=ncores
fi

procnum=0
export workdir=`mktemp -d -t workdir.XXXXXX`
sematree acquire finishlock

for ((i=1 ; i<=$maxprocs ; i++))
do
  ( procnum=$i
    sematree acquire countlock
    proccount=`sematree inc countlock`
    sematree release countlock
    
    while
       getfile
       [ ! -z "$infile" ]
    do
       echo `date +%s`: Start $infile >> $timelogfile
       
       export nlppscript=$BIND/nlpp
       movetotray "$infile" "$intray" "$proctray"
       mkdir -p $outpath
       mkdir -p $logpath
       export TEMPRES=`mktemp -t tempout.XXXXXX`
       naflang=`cat $procfile | python /home/phuijgen/nlp/nlpp/env/bin/langdetect.py`
       export naflang
       #
       if
         [ "$naflang" == "nl" ]
       then
         export nercmodel=nl/nl-clusters-conll02.bin
       else
         export nercmodel=en/en-newsreader-clusters-3-class-muc7-conll03-ontonotes-4.0.bin
       fi
       
       
       moduleresult=0
       timeout 1500 bash -c "(cat \"$procfile\" | $nlppscript >$TEMPRES 2>\"$logfile\")"
       pipelineresult=$?
       if
        [ $pipelineresult -eq 0 ]
       then
         mkdir -p $outpath
         mv $TEMPRES "$outfile"
         rm "$procfile"
       else
         movetotray "$procfile" "$proctray" "$failtray"
       fi  
       stopos -p $stopospool remove
       
       
       cd $root
       rm -f $TEMPRES
       
       echo `date +%s`: Finished $infile with result: $pipelineresult >> $timelogfile
       

    done
    
    sematree acquire countlock
    proccount=`sematree dec countlock`
    sematree release countlock
    echo "Process $proccunt stops." >&2
    if
      [ $proccount -eq 0 ]
    then
      sematree release finishlock
    fi
    
  )&
done
sematree acquire finishlock
sematree release finishlock
echo "No working processes left. Exiting." >&2


echo `date +%s`: Finish job $jobname >> $timelogfile


exit

