m4_include(inst.m4)m4_dnl
m4_sinclude(local.m4)m4_dnl
\documentclass[twoside,oldtoc]{artikel3}
@% \documentclass[twoside]{article}
\pagestyle{headings}
\usepackage{pdfswitch}
\usepackage{figlatex}
\usepackage{makeidx}
\renewcommand{\indexname}{General index}
\makeindex
\newcommand{\thedoctitle}{m4_doctitle}
\newcommand{\theauthor}{m4_author}
\newcommand{\thesubject}{m4_subject}
\newcommand{\AWK}{\textsc{awk}}
\newcommand{\CLTL}{\textsc{cltl}}
\newcommand{\EHU}{\textsc{ehu}}
\newcommand{\NAF}{\textsc{naf}}
\newcommand{\NED}{\textsc{ned}}
\newcommand{\NER}{\textsc{ner}}
\newcommand{\NLP}{\textsc{nlp}}
\newcommand{\SRL}{\textsc{srl}}
\def\CaptionTextFont{\small\slshape}
\title{\thedoctitle}
\author{\theauthor}
\date{m4_docdate}
m4_include(texinclusions.m4)m4_dnl
\begin{document}
\maketitle
\begin{abstract}
  This is a description and documentation of a system that uses SurfSara's
  supercomputer \href{https://userinfo.surfsara.nl/systems/lisa}{Lisa} to perform
  large-scale linguistic annotation of dutch documents with
  the 
  \href{https://github.com/PaulHuygen/nlpp}{``Newsreader pipeline''}. 
\end{abstract}
\tableofcontents

\section{Introduction}
\label{sec:Introduction}

This document describes a system for large-scale linguistic annotation of Dutch
documents, using supercomputer
\href{https://userinfo.surfsara.nl/systems/lisa}{Lisa}. Lisa is a
computer-system co-owned by the Vrije Universiteit Amsterdam. This
document is especially useful for members of the Computational
Lexicology and Terminology Lab (\CLTL{}) who have access to that
computer.

The annotation of the documents will be performed by a ``pipeline''
that has been set up in the
Newsreader-project~\footnote{http://www.newsreader-project.eu}. 

\subsection{How to use it}
\label{sec:usage}


Quick user instruction:

\begin{enumerate}
\item Get an account on Lisa.
\item Clone the software from Github. This results in a directory-tree
  with root \verb|m4_progname|.
\item ``cd'' to \verb|m4_progname|.
\item Create a subdirectory \verb|in| and fill it with (a
  directoy-structure containing) raw \NAF's
  that have to be annotated.
\item Run script \verb|runit|.
\item Wait until it has finished.
\end{enumerate}

The following is a demo script that performs the installation and
annotates a set of texts:

@o ../demoscript @{@%
#!/bin/bash
gitrepo=m4_progrepo
xampledir=/home/phuijgen/nlp/data/examplesample/
#
git clone $gitrepo
cd m4_progname
mkdir -p data/in
mkdir -p data/out
cp $xampledir/*.naf data/in/
./runit
@| @}

\section{Elements of the job}
\label{sec:elements}

\subsection{How it works}
\label{sec:how}

The user stores a directory-tree that contains ``raw'' \NAF{} files in an ``intray'' and
then starts a management script. The management script generates a
list of the paths to the naf-files in the intray and stores this in a
``Stopos pool'' (section~\ref{sec:filemanagement}).
\href{https://userinfo.surfsara.nl/systems/lisa/software/stopos}{``Stopos''}
enables parallel running jobs to get the filenames and precludes that
two or more parallel processes obtain the same filename.

The management script submits a number of jobs to the queue of the supercomputer.

Eventually the jobs start on individual nodes, They are allowed to run
for a certain duration, the ``wall time'', after which they are
aborted. Each job starts a number of parallel processes. Each process is
a cycle  of 1) obtain a filename from stopos; 3) annotate the file;
3) store the resulting  \NAF{} in the outtray and remove the input-file from
the .; 4) remove the filename from the stopos pool. 


If a cycle has been completed, the result is:
\begin{enumerate}
\item The number of files in the Stopos pool is reduced by one.
\item The number of files in the intray is reduced by one.
\item Either the failtray or the outtray contains a file with the
  same name as the file that has been removed from the intray.
\item There are entries in log-files
\end{enumerate}

A ``todo'' item is, to manage files that fail to be
annotated. Currently this results in an unusable file in the outtray.

If the cycle could not be completed, the result is:

\begin{enumerate}
\item The Stopos pool contains a file-name that cannot be accessed.
\item The intray contains a file that will not be processed using the
  current pool.
\end{enumerate}
 
The management script has to be run periodically in order to
regenerate the pool and to submit extra jobs to process the remaining files.

Define parameters for the items that have been introduced in this section:

@d parameters @{@%
export walltime=m4_walltime
export root=m4_aprojroot
export intray=m4_indir
export outtray=m4_outdir
export failtray=m4_faildir
export logtray=m4_logdir
@| walltime root intray outtray failtray logtray @}


\subsection{Still to be done}
\label{sec:tobedone}

\begin{enumerate}
\item Handle log files from the job system.
\item Recognize when annotation fails.
\end{enumerate}

\subsection{Set parameters}
\label{sec:parameters}

The system has several parameters that will be set as Bash variables
in file \verb|parameters|. The user can edit that file to change
parameters values

@o m4_projroot/parameters @{@%
@< parameters @>
@| @}



\subsection{Moving NAF-files around}
\label{sec:filemoving}

A job is a Bash script that finds raw \NAF{} files in the intray,
feeds the files through an NLP pipeline and stores the result as
\NAF{} file in the outtray. A complication is, that a job runs until
it's ``wall-time'' has been expired, after which the operation system
aborts the job. The input files that the job was annotating at that
moment will not be completed, and stopos will not pass these files to
other jobs. To solve this problem, before starting to annotate, the
job moves the inputfile to a ``proc'' directory. The management script
can move these files back to the input tray when it finds out that no
job is processing them.

@d parameters @{@%
export proctray=m4_procdir
@| proctray @}

In the pool the input nafs are stored by their full path. The
following code scraps copy or move a file that is presented with
it's full path from one tray to another
tray. Arguments:

\begin{enumerate}
\item Full path of sourcefile.
\item Full path of source tray.
\item Full path of target tray
\end{enumerate}

@d copy file @{cp @1 $@3/${@1##$@2}@| @}

@d move file @{mv @1 $@3/${@1##$@2}@| @}

Here follows the same functionality, bu now as Bash function. The
functions are exported in order to be able to use them in \verb|xargs|
constructions (See
\href{http://unix.stackexchange.com/questions/158564/how-to-use-defined-function-with-xargs}{this
  Stack-exchange item}.

@d functions @{@%
function movetotray () {
local file=$1
local fromtray=$2
local totray=$3
local frompath=${file%/*}
local topath=$totray${frompath##$fromtray}
mv $file $totray${file##$fromtray}
}
export -f movetotray
@| movetotray @}

@d functions @{@%
function copytotray () {
local file=$1
local fromtray=$2
local totray=$3
local frompath=${file%/*}
local topath=$totray${frompath##$fromtray}
mv $file $totray${file##fromtray}
}
export -f copytotray
@| copytotray @}


To enable this moving-around of \NAF{}
files, a management script has to perform the following:

\begin{enumerate}
\item Check whether there are raw NAF's to be processed.
\item Generate the output-tray to store the processed \NAF{}'s
\item Generate a Stopos pool with a list of the filenames of the NAF
  files or update an existing Stopos pool.
\end{enumerate}


A job performs the following:

\begin{enumerate}
\item Obtain the path to a raw naf in the intray.
\item Write a processed naf in a directory-tree on the outtray
\item Move a failed inputfile to the fail-tree
\end{enumerate}

Generate the directories to store the files when they are not yet
there.

\subsubsection{Look whether there are input-files}
\label{sec:lookforinput}

When the management script starts, it checks whether there is
actually something to do.

@d check/create directories @{@%
infilesexist=1
if
  [ ! -d "$intray" ]
then
  echo "No input-files."
  echo "Create $intray and fill it with raw NAF's."
  veilig
  exit 4
fi
mkdir -p $outtray
mkdir -p $logtray
mkdir -p $proctray
if
  [ ! "$(ls -A $intray)" ] &&  [ ! "$(ls -A $proctray)" ]
then
  echo "Finished processing"
  veilig
  exit
fi
@| infilesexist  @}



In the next section  we will see that Stopos stores the full paths to
raw \NAF{}'s. When variable \verb|infile| contains the full path to a
raw \NAF{}, the following code derives the full path to the
annotated \NAF{} that will be created in the outtray:

@d generate filenames @{@%
filtrunk=${infile##$intray/}
outfile=$outtray/${filtrunk}
logfile=$logtray/${filtrunk}
procfile=$proctray/${filtrunk}
outpath=${outfile%/*}
procpath=${procfile%/*}
logpath=${logfile%/*}
@| filtrunk outfile logfile procfile outpath procpath logpath @}




\subsubsection{Stopos: file management}
\label{sec:filemanagement}

Stopos stores a set of parameters (in our case the full paths to
\NAF{} files that have to be processed) in a named ``pool''. A process
in a job can
read a parameter value from the pool and the Stopos system makes sure that
from that moment no other process is able to obtain that parameter value. When the job
has finished processing the parameter value, it removes the parameter value from
the pool.

Set the name of the Stopos pool:

@d parameters @{@%
export stopospool=m4_stopospool
@| stopospool @}

Load the stopos module in a script:

@d load stopos module @{@%
module load stopos
@| @}

\subsubsection{Generate a Stopos pool}
\label{sec:generate_pool}

When the script is started for the first time, hopefully raw \NAF{}
files are present in the intray, but there are no submitted jobs. When
there are no jobs, generate a new Stopos pool. Otherwise, there ought
to be a pool. To update the pool, restore files that resided for longer
time in the proctray into the intray and re-introduce them in the pool.

@% @d (re-)generate stopos pool @{@%
@% if
@%   [ $running_jobs -eq 0 ]
@% then
@%   @< set up new stopos pool @>
@% else
@%   @< restore old procfiles @>
@% fi
@% @| @}


@d set up new stopos pool @{@%
@< move all procfiles to intray @>
find $intray -type f -print >filelist
stopos -p $stopospool purge
stopos -p $stopospool create
stopos -p $stopospool add filelist
stopos -p $stopospool status
@| @}


@d move all procfiles to intray @{@%
find $proctray -type f -print | xargs -iaap  bash -c 'movetotray aap $proctray $intray'
@| @}


Move files that reside longer than \verb|maxproctime| minutes back to
the intray. This works as follows:

\begin{enumerate}
\item function \verb|restoreprocfile| moves a file back to the intray
  and adds the path in the intray to a list in file \verb|restorefiles|.
\item The Unix function \verb|find| the old procfiles to function
  \verb|restoreprocfile|.
\item When the old procfiles have been collected, the filenames in
  \verb|restorefiles| are passed to Stopos.
\end{enumerate}

@d functions @{@%
function restoreprocfile {
  procf=$1
  filelist=$2
  inf=$intray/${procfile##$proctray}
  echo $inf >>$filelist
  movetotray $procf $proctray $intray
}
export -f restoreprocfile
@| restoreprocfile @}



@d restore old procfiles @{@%
restorefilelist=`mktemp -t restore.XXXXXX`
find $proctray -type f -cmin +$maxproctime -print | \
   xargs -iaap  bash -c 'restoreprocfile aap $restorefilelist'
stopos -p $stopospool add $restorefilelist
rm $restorefilelist
@| @}

@d parameters @{@%
maxproctime=15
@|maxproctime @}

To get a filename from Stopos perform:

\begin{verbatim}
  stopos -p $stopospool next

\end{verbatim}

When this instruction is successfull, it sets variable
\verb|STOPOS_RC| to \verb|OK| and puts the filename in variable
\verb|STOPOS_VALUE|.

Get next input-file from stopos and put its full path in variable
\verb|infile|. If Stopos is empty, try to recover old procfiles and
try again. If Stopos is still empty, undefine \verb|infile|.

@d get next infile from stopos @{@%
stopos -p $stopospool next
@% if
@%    [ ! "$STOPOS_RC" == "OK" ]
@%  then
@%   waitingfilecount=`find $intray -type f -print | wc -l`
@%   if
@%     [ $waitingfilecount -gt 0 ]
@%   then
@%      @< restore old procfiles @>
@%      stopos -p $stopospool next
@%   fi
@% fi
if
  [ "$STOPOS_RC" == "OK" ]
then
   infile=$STOPOS_VALUE
else
  infile=""
fi
@| @}



\subsubsection{Get Stopos status}
\label{sec:stopos-state}

Find out whether the stopos pool exists and create it if that is not
the case.

Find out how many filenames are still present in the Stopos
pool. Store the number of input-files that have not yet been given to
a processing job in variable \verb|untouched_files| and the number of
files that have been given to a processing job but have not yet been
finished in variable \verb|busy_files|.

@d get stopos status @{@%
stopos pools
if [ -z "`echo $STOPOS_VALUE | grep $stopospool `" ]
then 
   stopos -p $stopospool create
fi
stopos -p $stopospool status
untouched_files=$STOPOS_PRESENT0
busy_files=$STOPOS_PRESENT
@| @}



\subsubsection{Function to get a filename from Stopos}
\label{sec:getfile-function}


The following function, getfile, reads a file from stopos, puts it in
variable \verb|infile| and sets the
paths to the outtray, the logtray and the failtray. When the Stopos
pool turns out to be empty, variable is made empty.

@d  function getfile @{@%
function getfile() {
  infile=""
  outfile=""
  @< get next infile from stopos @>
  if
    [ ! "$infile" == "" ]
  then
    @< generate filenames @>
@%    echo To process $INFILE
  fi
}

@| @}

\subsection{The pipeline}
\label{sec:pipeline}

The raw \NAF{}'s will be processed with the Dutch Newsreader
Pipeline. It has been installed on the account \texttt{phuijgen} on
Lisa. The installation has been performed using the Github repository
\href{https://github.com/PaulHuygen/nlpp}.

@d directories of the pipeline @{@%
export piperoot=m4_piperoot
export pipebindir=m4_piperoot/bin
@| @}

The following script processes a raw \NAF{} from standard in and
produces the result on standard out.:

@o m4_projroot/pipenl @{@%
#!/bin/bash
source m4_aprojroot/parameters
@< directories of the pipeline @>
@< set utf-8 @>
OLDD=`pwd`
TEMPDIR=`mktemp -t -d ontemp.XXXXXX`
cd $TEMPDIR
cat            | $pipebindir/tok          > tok.naf
cat tok.naf    | $pipebindir/mor           > mor.naf
cat mor.naf    | $pipebindir/nerc_conll02  > nerc.naf
cat nerc.naf   | $pipebindir/wsd           > wsd.naf
cat wsd.naf    | $pipebindir/ned           > ned.naf
cat ned.naf    | $pipebindir/heideltime    > times.naf
cat times.naf  | $pipebindir/onto          > onto.naf
cat onto.naf   | $pipebindir/srl           > srl.naf
cat srl.naf    | $pipebindir/evcoref       > ecrf.naf
cat ecrf.naf   | $pipebindir/framesrl      > fsrl.naf
cat fsrl.naf   | $pipebindir/dbpner        > dbpner.naf
cat dbpner.naf | $pipebindir/nomevent      > nomev.naf
cat nomev.naf  | $pipebindir/postsrl       > psrl.naf
cat psrl.naf   | $pipebindir/opinimin     
rm -rf $TEMPDIR 
@| @}

@d make scripts executable @{@%
chmod 775 m4_aprojroot/pipenl
@| @}


It is important that the computer uses utf-8 character-encoding.

@d set utf-8 @{@%
export LANG=en_US.utf8
export LANGUAGE=en_US.utf8
export LC_ALL=en_US.utf8
@| @}


Actually, we do not yet handle failed files separately. 

@d process infile @{@%
movetotray $infile $intray $proctray
mkdir -p $outpath
cat $procfile | m4_aprojroot/pipenl >$outfile
rm $procfile
stopos -p $stopospool remove
@| @}

Select a proper spotlighthost:

@d parameters @{@%
export spotlighthost=m4_spotlighthost
@| spotlighthost @}



\subsection{Time log}
\label{sec:Timelog}

Keep a time-log with which the time needed to annotate a file can be
reconstructed.

@d parameters @{@%
export timelogfile=m4_logdir/timelog
@| @}

@d add timelog entry @{@%
echo `date +%s`: @1 >> $timelogfile
@| @}


\subsection{General log mechanism}
\label{sec:generallog}

Write to a log file if logging is set to true.

@d init logfile @{@%
LOGGING=m4_logging
LOGFIL=m4_logfile
PROGNAM=@1
@| LOGGING LOGFIL @}

@d write log @{@%
if LOGGING=true
then
  echo `date`";" \$PROGNAM":" @1 >>\$LOGFIL
fi
@| @}



\subsection{Parallel processes}
\label{sec:parallel}

When a job runs, it determines how many resources it has (\textsc{cpu}
nodes, memory) and from that it deterines how many parallel processed
it can start up.

@d start parallel processes @{@%
@< determine amount of memory and nodes @>
@< determine number of parallel processes @>
procnum=0
for ((i=1 ; i<=$maxprocs ; i++))
do
  ( procnum=$i
    while
       getfile
       [ ! -z $infile ]
    do
@%        @< process 1 invokes runit @>
        @< add timelog entry @(Start $infile@) @>
       @< process infile @>
       @< add timelog entry @(Finished $infile@) @>

    done
  )&
done

@| procnum @}

@d determine amount of memory and nodes @{@%
export ncores=`sara-get-num-cores`
#export MEMORY=`head -n 1 < /proc/meminfo | gawk '{print $2}'`
export memory=`sara-get-mem-size`
@| @}


We want to run as many parallel processes as possible, however we do
want to have at least one node per process and at least an amount of
\verb|memchunk| GB of memory per process.

@d parameters @{@%
mem_per_process=m4_memperprocess
@| @}


@d  determine number of parallel processes @{@%
export memchunks=$((memory / mem_per_process))
if
  [ $ncores -gt $memchunks ]
then
  maxprocs=$memchunks
else
  maxprocs=ncores
fi
@| @}


@% @d process 1 invokes runit @{@%
@% if
@%   [ $procnum -eq 1 ]
@% then
@%   @< invoke the runit script @>
@% fi
@% @| @}



\subsection{The job}
\label{sec:thejob}

@% @d  m4_projroot/dutch_pipeline_job.parameters @{@%
@% export walltime=30:00
@% @| @}

@o m4_projroot/m4_jobname.m4 @{@%
m4_<!!>changecom
#!/bin/bash
#PBS -lnodes=1
<!#!>PBS -lwalltime=m4_<!!>walltime
source m4_aprojroot/parameters
@< functions @>
@< function getfile @>
@< load stopos module @>
starttime=`date +%s`
@< start parallel processes @>
wait
exit

@| @}


@% #
@% # Move/copy a file and create (part of) path if necessary.
@% #
@% function movefile() {
@%    fullfile=$1
@%    oldtray=$2
@%    newtray=$3
@%    inpath=${fullfile%/*}
@%    trunk=${inpath#$oldtray} 
@%    outpath=$newtray/$trunk
@%    mkdir -p $outpath
@%    mv $fullfile $outpath/
@% }
@% 
@% function copyfile() {
@%    fullfile=$1
@%    oldtray=$2
@%    newtray=$3
@%    inpath=${fullfile%/*}
@%    trunk=${inpath#$oldtray} 
@%    outpath=$newtray/$trunk
@%    mkdir -p $outpath
@%    cp $fullfile $outpath/
@% }

@% #
@% # Get a filename
@% # Set variables INFILE, OUTFIL, FAILFILE
@% #
@% function getfile() {
@%   INFILE=""
@%   OUTFILE=""
@%   stopos -p $STOPOSPOOL next
@%   if
@%     [ "$STOPOS_RC" == "OK" ]
@%   then
@%     INFILE=$STOPOS_VALUE
@%     FILTRUNK=${INFILE##$INTRAY/}
@%     OUTFILE=$OUTTRAY/${FILTRUNK}
@%     LOGFILE=$LOGTRAY/${FILTRUNK}
@%     FAILFILE=$FAILTRAY/${FILTRUNK}
@%     OUTPATH=${OUTFILE%/*}
@%     FAILPATH=${FAILFILE%/*}
@%     LOGPATH=${LOGFILE%/*}
@%     echo To process $INFILE
@%   fi
@% }


@% #
@% # Process PROCFILE and place result in OUTFILE
@% function testprocess () {
@%   copyfile $PROCFILE $PROCTRAY $OUTTRAY
@% }
@% 
@% function process_file () {
@%   OLDD=`pwd`
@%   TEMPDIR=`mktemp -t -d ontemp.XXXXXX`
@%   cd $TEMPDIR
@%   cat $INFILE    | $PIPEBINDIR/tok           > tok.naf
@%   cat tok.naf    | $PIPEBINDIR/mor           > mor.naf
@%   cat mor.naf    | $PIPEBINDIR/nerc_conll02  > nerc.naf
@%   cat nerc.naf   | $PIPEBINDIR/wsd           > wsd.naf
@%   cat wsd.naf    | $PIPEBINDIR/ned           > ned.naf
@%   cat ned.naf    | $PIPEBINDIR/heideltime    > otimes.naf
@%   cat otimes.naf | gawk -f $PIPEBINDIR/remprol.awk  > times.naf
@%   cat times.naf  | $PIPEBINDIR/onto          > onto.naf
@%   cat onto.naf   | $PIPEBINDIR/srl           > srl.naf
@%   cat srl.naf    | $PIPEBINDIR/evcoref       > ecrf.naf
@%   cat ecrf.naf   | $PIPEBINDIR/framesrl      > fsrl.naf
@%   cat fsrl.naf   | $PIPEBINDIR/dbpner        > dbpner.naf
@%   cat dbpner.naf | $PIPEBINDIR/nomevent      > nomev.naf
@%   cat nomev.naf  | $PIPEBINDIR/postsrl             > out.naf
@%   if
@%      [ -e out.naf -a $(stat -c%s "out.naf") -gt 700 ]
@%   then
@%     mkdir -p $OUTPATH
@%     cp $TEMPDIR/out.naf $OUTFILE
@%     echo Produced $OUTFILE of size $(stat -c%s "$OUTFILE")
@%   else
@%      if
@%        [ ! -e $TEMPDIR/file.out.naf ]
@%      then
@%        echo Not produced: $OUTFILE
@%      else
@%        Too small $OUTFILE: $(stat -c%s "out.naf") 
@%      fi
@%   fi
@%   cd $OLDD
@%   rm -rf $TEMPDIR 
@% }
@% 
@% 
@% function startspotlight () {
@%    spotnl
@% }
@% 
@% function waitforspotlight () {
@%   sleep 1
@% }
@% 
@% waitabit()
@% { ( RR=$RANDOM
@%     while
@%       [ $RR -gt 0 ]
@%     do
@%     RR=$((RR - 1))
@%     done
@%   )
@%   
@% }
@% 
@% export LOCKDIR=$TMPDIR/lock
@% 
@% function passeer () {
@%  while ! (mkdir $LOCKDIR 2> /dev/null)
@%  do
@%    waitabit
@%  done
@% }
@% 
@% function veilig () {
@%   rmdir "$LOCKDIR"
@% }
@% 
@% 
@% 
@% 
@% 
@% startspotlight
@% waitforspotlight
@% 
@% 
@% FILNAM=""
@% 
@% 
@% 
@% cd $TMPDIR
@% export NCORES=`sara-get-num-cores`
@% #export MEMORY=`head -n 1 < /proc/meminfo | gawk '{print $2}'`
@% export MEMORY=`sara-get-mem-size`
@% export MEMCHUNKS=$(((MEMORY - 8) / 5))
@% 
@% MAXPROCS=$((NCORES-1))
@% if
@%   [ $MEMCHUNKS -lt $MAXPROCS ]
@% then
@%   MAXPROCS=$MEMCHUNKS
@% fi
@% 
@% export MAXPROCS
@% echo Cores: $NCORES
@% echo Memory: $MEMORY, allowing for $MEMCHUNKS divisions of 5 GB
@% echo Max. number of processes:  $MAXPROCS
@% echo 0 >$TMPDIR/proctal
@% 
@% PROCNUM=0
@% for ((i=1; i<= MAXPROCS ; i++)) 
@% do
@%   ( passeer
@%     PROCNUM=`cat $TMPDIR/proctal`
@%     echo Process number: $PROCNUM
@%     echo $((PROCNUM + 1 )) > $TMPDIR/proctal
@%     echo $PROCNUM: Proctal after increment: `cat $TMPDIR/proctal`
@%     veilig
@%     while
@%       getfile
@%       [ ! -z "$INFILE" ] 
@%     do
@%       BTIME=`date +%s`
@%       echo $PROCNUM: Got file $INFILE
@%       process_file
@%       if
@%          [ -e $OUTFILE -a $(stat -c%s "$OUTFILE") -gt 1000 ]
@%       then
@%          rm $INFILE
@%       else
@%          movefile $INFILE $INTRAY $FAILTRAY
@%       fi
@% #      process_file $INFILE
@% #     $SCRIPT < $INTRAY/$INFILE >$PROCTRAY/$INFILE
@% #      mv $PROCTRAY/$INFILE $OUTTRAY
@% #      removefromlist
@%       echo $PROCNUM: $PROCFILE processed
@%       ETIME=`date +%s`
@%       stopos -p $STOPOSPOOL remove
@% #      echo `stat --printf="%s" $INFIL`"	$(($ETIME - $BTIME))	$INFILE	$ALPCOMMAND" >> $BOOKKEEPFILE
@%     done
@%   ) &
@% done
@% wait


\subsection{Manage the jobs}
\label{sec:jobtrack}

Find out how many submitted jobs there are and how many are
running. 

@d count jobs @{@%
joblist=`mktemp -t jobrep.XXXXXX`
rm -rf $joblist
showq -u $USER | tail -n 1 > $joblist
running_jobs=`cat $joblist | gawk '
    { match($0, /Active Jobs:[[:blank:]]*([[:digit:]]+)[[:blank:]]*Idle/, arr)
      print arr[1]
    }'`
total_jobs=`cat $joblist | gawk '
    { match($0, /Total Jobs:[[:blank:]]*([[:digit:]]+)[[:blank:]]*Active/, arr)
      print arr[1]
    }'`
rm $joblist
@| running_jobs total_jobs @}

Make sure that enough jobs are submitted. Currently we aim at one job per
m4_filesperjob waiting files.
@d parameters @{@%
filesperjob=m4_filesperjob
@| @}

The follwing code-piece submits jobs when necessary. Note that this
piece will be used when it is already known that there are files
waiting to be processed. So, there must be at least one job.

@d submit jobs @{@%
jobs_needed=$((unprocessedfilecount / $filesperjob))
if
  [ $jobs_needed -lt 1 ]
then
  jobs_needed=1
fi
jobs_to_be_submitted=$((jobs_needed - $total_jobs))
if
  [ $jobs_to_be_submitted -gt 0 ]
then
   @< generate jobscript @>
   qsub -t 1-$jobs_to_be_submitted m4_aprojroot/m4_jobname
fi 

@| jobs_needed jobs_to_be_submitted@}


@d generate jobscript @{@%
echo "m4_<!!>define(m4_<!!>walltime, $walltime)m4_<!!>dnl" >job.m4
m4_changequote(<![!>,<!]!>)m4_dnl
echo 'm4_[]changequote(`<!'"'"',`!>'"'"')m4_[]dnl' >>job.m4
m4_changequote([<!],[!>])m4_dnl
cat m4_jobname<!!>.m4 >>job.m4
cat job.m4 | m4 -P >m4_jobname
# rm job.m4
@| @}



\subsubsection{Keep it going}
\label{sec:koopgoing}

The script \verb|runit| performs job management. Therefore, this
script must be started at regular intervals. We cannot install
cron-jobs on Lisa to do this. Therefore, it would be a good idea to to
have jobs starting runit now and
then. I tried to do that over ssh, but it did not succeed (timed out). 

@% @d parameters @{@%
@% export runit_deadtime=m4_runit_deadtime
@% @| runit_deadtime @}
@% 
@% @d set runit timestamp @{@%
@% echo `date +%s` >m4_runittimefile
@% @| @}
@% 
@% @d invoke the runit script @{@%
@% startrunit=0
@% if
@%   [ -e "m4_runittimefile" ] 
@% then
@%   lasttime=`cat m4_runittimefile`
@%   now=`date +%s`
@%   elapsed_seconds=$((now - $lasttime))
@%   min_seconds=$((runit_deadtime * 60))
@%   if
@%     [ $elapsed_seconds -le $min_seconds ]
@%   then
@%     startrunit=1
@%   fi
@% fi
@% if
@%   [ $startrunit -eq 0 ]
@% then
@%   @< set runit timestamp @>
@%   ssh -o PubkeyAuthentication=yes $USER@@m4_lisahost "nohup m4_aprojroot/runit &"
@% fi
@% @| @}



@% When we have received files to be parsed we have to submit the proper
@% amount of jobs. To determine whether new jobs have to be
@% submitted we have to know the number of waiting and running
@% jobs. Unfortunately it is too costly to often request a list of
@% running jobs. Therefore we will make a bookkeeping. File
@% \verb|m4_jobcountfile| contains a list of the running and waiting
@% jobs.
@% 
@% @d parameters @{@%
@% JOBCOUNTFILE=m4_jobcountfile
@% @| JOBCOUNTFILE @}
@% 
@% 
@% It is updated as follows:
@% 
@% \begin{itemize}
@% \item When a job is submitted, a line containing the job-id, the word
@%   ``wait'' and a timestamp is added to the file.
@% \item A job that starts, replaces in the line with its job-id the word
@%   ``waiting'' by running and replaces the timestamp.
@% \item A job that ends regularly, removes the line with its job-id.
@% \item A job that ends leaves a log message. The filename consists of a 
@%   concatenation of the jobname, a dot, the character ``o'' and the
@%   job-id. At a regular basis the existence of such files is checked
@%   and \verb|\$JOBCOUNTFILE| updated. 
@% \end{itemize}
@% 
@% 
@% Submit a job and write a line in the jobcountfile. The line consists
@% of the jobnumber, the word ``wait'' and the timestamp in universal seconds.
@% 
@% @d submit a job @{@%
@% @% passeer
@% qsub m4_aprojroot/m4_jobname | \
@%  gawk -F"." -v tst=`date +%s`  '{print $1 " wait " tst}' \
@%  >> \$JOBCOUNTFILE
@% @< write log @(Updated jobcountfile@) @>
@% @% veilig
@% @| @}
@% 
@% When a job starts, it performs some bookkeeping. It finds out its own job number and changes \verb|wait| into \verb|run|  in the bookeepfile.
@% 
@% @d perform jobfile-bookkeeping @{@%
@% @< find out the job number @>
@% prognam=m4_jobname$JOBNUM
@% @< write log @(start@) @>
@% @< change ``wait'' to ``run'' in jobcountfile @>
@% @| @}
@% 
@% The job \textsc{id} begins with the number,
@% e.g. \verb|6670732.batch1.irc.sara.nl|. 
@% 
@% @d find out the job number @{@%
@% JOBNUM=\${PBS_JOBID%%.*}
@% @| @}
@% 
@% @d change ``wait'' to ``run'' in jobcountfile @{@%
@% @%stmp=`date +%s`
@% if [ -e \$JOBCOUNTFILE ]
@% then
@%   passeer
@%   mv \$JOBCOUNTFILE \$tmpfil
@%   gawk -v jid=\$JOBNUM -v stmp=`date +%s` \
@%     '@< awk script to change status of job in joblist @>' \
@%     \$tmpfil >\$JOBCOUNTFILE
@%   veilig
@%   rm -rf \$tmpfil
@% fi
@% @| @}
@% 
@% @d awk script to change status of job in joblist @{@%
@% BEGIN {WRIT="N"};
@% { if(match(\$0,"^"jid)>0) {
@%      print jid " run  " stmp;
@%      WRIT="Y";
@%   } else {print}
@% };
@% END {
@%   if(WRIT=="N") print jid " run  " stmp;
@% }@%
@% @| @}
@% 
@% 
@% 
@% When a job ends, it removes the line:
@% 
@% @d remove the job from the counter @{@%
@% passeer
@% mv \$JOBCOUNTFILE \$tmpfil
@% gawk -v jid=\$JOBNUM  '\$1 !~ "^"jid {print}' \$tmpfil >\$JOBCOUNTFILE
@% veilig
@% rm -rf \$tmpfil
@% @| @}
@% 
@% Periodically check whether jobs have been killed before completion and
@% have thus not been able to remove their line in the jobcountfile. To
@% do this, write the jobnumbers in a temporary file and then check the
@% jobcounter file in one blow, to prevent frequent locks.
@% 
@% 
@% @d do brief check of expired jobs @{@%
@% obsfil=`mktemp --tmpdir obs.XXXXXXX`
@% rm -rf \$obsfil
@% @< make a list of jobs that produced logfiles @(\$obsfil@) @>
@% @< compare the logfile list with the jobcounter list @(\$obsfil@) @>
@% rm -rf \$obsfil
@% @| @}
@% 
@% @d do the frequent tasks @{@%
@% @< do brief check of expired jobs @>
@% @| @}
@% 
@% @%@d do thorough check of expired jobs @{@%
@% @%@< check whether update is necessary @(\$thoroughjobcheckfil@,180@,thoroughjobcheck@) @>
@% @%if \$thoroughjobcheck
@% @%then
@% @%@% @< skip brief jobcheck @>
@% @% @< verify jobs-bookkeeping @>
@% @%fi
@% @%@| @}




When a job has ended, a logfile, and sometimes an error-file, is
produced. The name of the logfile is a concatenation of the jobname, a
dot, the character \verb|o| and the jobnumber. The error-file has a
similar name, but the character \verb|o| is replaced by
\verb|e|. Generate a sorted list of the jobnumbers and
remove the logfiles and error-files:

@d make a list of jobs that produced logfiles @{@%
for file in m4_jobname.o*
do
  JOBNUM=\${file<!##!>m4_jobname.o}
  echo \${file<!##!>m4_jobname.o} >>\$tmpfil
  rm -rf m4_jobname.[eo]\$JOBNUM
done
sort < \$tmpfil >@1
rm -rf \$tmpfil
@| @}

Remove the jobs in the list from the counter file if they occur there.

@d compare the logfile list with the jobcounter list @{@%
if [ -e \$JOBCOUNTFILE ]
then
  passeer
  sort < \$JOBCOUNTFILE >\$tmpfil
  gawk -v obsfil=@1 ' 
    BEGIN {getline obs < obsfil}
    { while((obs<\$1) && ((getline obs < obsfil) >0)){}
      if(obs==\$1) next;
      print
    }
  ' \$tmpfil >\$JOBCOUNTFILE
  veilig
fi
rm -rf \$tmpfil
@| @}

From time to time, check whether the jobs-bookkeeping is still
correct.
To this end, request a list of jobs from the operating
system. 

@d verify jobs-bookkeeping @{@%
actjobs=`mktemp --tmpdir act.XXXXXX`
rm -rf \$actjobs
qstat -u  phuijgen | grep m4_jobname | gawk -F"." '{print \$1}' \
 | sort  >\$actjobs
@< compare the active-jobs list with the jobcounter list @(\$actjobs@) @>
rm -rf \$actjobs
@| @}

@d do the now-and-then tasks @{@%
@< verify jobs-bookkeeping @>
@| @}


@d compare the active-jobs list with the jobcounter list @{@%
if [ -e \$JOBCOUNTFILE ]
then
  passeer
  sort < \$JOBCOUNTFILE >\$tmpfil
  gawk -v actfil=@1 -v stmp=`date +%s` ' 
    @< awk script to compare the active-jobs list with the jobcounter list @>
  ' \$tmpfil >\$JOBCOUNTFILE
  veilig
  rm -rf \$tmpfil
else
  cp @1 \$JOBCOUNTFILE
fi
@| @}

Copy lines from the logcount file if the jobnumber matches a line in
the list actual jobs. Write entries for jobnumbers that occur only in
the actual job list.

@d awk script to compare the active-jobs list with the jobcounter list @{@%
BEGIN {actlin=(getline act < actfil)}
{ while(actlin>0 && (act<\$1)){ 
     print act " wait " stmp;
     actlin=(getline act < actfil);
  };
  if((actlin>0) && act==\$1 ){
     print
     actlin=(getline act < actfil);
  }
}
END {
    while((actlin>0) && (act ~ /^[[:digit:]]+/)){
      print act " wait " stmp;
    actlin=(getline act < actfil);
 };
}
@| @}


@% \subsubsection{Submit extra jobs}
@% \label{sec:submit}
@% 
@% Check how many files have to be parsed (\verb|NRFILES|) and how many
@% jobs there are (\verb|NRJOBS|). If there are more than m4_filesperjob
@% files per job, submit extra jobs. Cap the number of jobs to maximimum
@% of m4_maxjobs
@% 
@% When before submitting jobs it turns out that, although no job is
@% running at all, there are files in \verb|proctray|. In that case, they
@% can be moved back to the intray.


@% @d check/perform every time @{@%
@% @< replace files from proctray when no processes are running @>
@% @< submit jobs when necessary @>
@% @| @}




@% @d submit jobs when necessary @{@%
@% @%@< get number of jobs and number of input files @(NRJOBS@,NRFILES@) @>
@% NRFILES=`ls -1 \$INBAK |  wc -l`
@% if [ -e \$JOBCOUNTFILE ]
@% then
@%   NRJOBS=`wc -l < \$JOBCOUNTFILE`
@% else
@%   NRJOBS=0
@% fi
@% @< derive number of jobs to be submitted @(SUBJOBS@) @>
@% @< write log @(start \$SUBJOBS jobs@) @>
@% @< submit extra jobs @(SUBJOBS@) @>
@% @| @}



@d derive number of jobs to be submitted  @{@%
REQJOBS=\$(( \$(( \$NRFILES / m4_filesperjob )) ))
if [ \$REQJOBS -gt m4_maxjobs ]
then
  REQJOBS=m4_maxjobs
fi
if [ \$NRFILES -gt 0 ]
then
  if [ \$REQJOBS -eq 0 ]
  then
    REQJOBS=1
  fi
fi
@1=\$(( \$REQJOBS - \$NRJOBS ))

@| @}

\subsection{Synchronisation mechanism}
\label{sec:synchronisation}

Make a mechanism that ensures that only a single process can execute
some functions at a time. For instance, if a process selects a file to
be processed next, it selects a file name from a directory-listing and
then removes the selected file from the directory. The two steps form
a ``critical code section'' and only a single process at a time should
be allowed to execute this section. Therefore, generate the functions
\verb|passeer| and \verb|veilig| (cf. E.W.~Dijkstra). When a process
completes \verb|passeer|, no other processes can complete
\verb|passeer| until the first process executes \verb|veilig|.

Function \verb|passeer| tries repeatedly to create a \emph{lock
  directory}, until it succeeds and function \verb|veilig| removes the
lock directory.


Sometimes de-synchonisation is good, to prevent that all processes are
waiting at the same time for the same event. Therefore, now and then a
process should wait a random amount of time. We don't need to use
sleep, because the cores have no other work to do.

@d functions @{@%
waitabit()
{ ( RR=\$RANDOM
    while
      [ \$RR -gt 0 ]
    do
    RR=\$((RR - 1))
    done
  )
  
}

@| waitabit @}


@d parameters @{@%
export LOCKDIR=m4_lockdir

@| LOCKDIR @}

@d functions @{@%
function passeer () {
 while ! (mkdir \$LOCKDIR 2> /dev/null)
 do
@%  sleep 1
   waitabit
 done
}

function veilig () {
  rmdir "\$LOCKDIR"
}

@| passeer veilig @}

Function \verb|runsingle| is similar to \verb|passeer|, but it exits
when the lock is set.

@d functions @{@%
function runsingle () {
 if ! (mkdir \$LOCKDIR 2> /dev/null)
 then
    exit
 fi
}

function veilig () {
  rmdir "\$LOCKDIR"
}

@| passeer veilig @}


The processes that execute these functions can crash and they are
killed when the time alotted to them has been used up. Thus it
is possible that a process that executed \verb|passeer| is not able to
execute \verb|veilig|. As a result, all other processes would come to a
halt. Therefore, check the age of the lock directory periodically and
remove the directory when it is older than, say, two minutes (executing critical code
sections ought to take only a very short amount of time).

@d remove old lockdir  @{@%
@%export LOCKDIR=m4_lockdir
find \$LOCKDIR -amin m4_locktimeout -print 2>/dev/null | xargs rm -rf
@| @}

The synchronisation mechanism can be used to have parallel processes
update the same counter. 

@d increment filecontent @{@%
passeer
NUM=`cat @1`
echo \$((NUM + 1 )) > @1
veilig
@| @}

@d decrement filecontent @{@%
passeer
NUM=`cat @1`
echo \$((NUM - 1 )) > @1
veilig
@| @}

We will need a mechanism to find out whether a certain operation has
taken place within a certain past time period. We use the timestamp of
a file for that. When the operation to be monitored is executed, the
file is touched. The following macro checks such a file. It has the
following three arguments: 1) filename; 2) time-out period; 3)
result. The result parameter will become true when the file didn't
exist or when it had not been touched during the time-out period. In
those cases the macro touches the file.

@d check whether update is necessary  @{@%
@< write log @(now: `date +%s`@) @>
arg=@1
stamp=`date -r @1 +%s`
@< write log @($arg: $stamp@) @>
passeer
if [ ! -e @1 ]
then
  @3=true
elif [ \$((`date +%s` - `date -r @1 +%s`)) -gt @2 ]
then
  @3=true
else
  @3=false
fi
if \$@3
then
  echo `date` > @1
fi
veilig
if \$@3
then
  @< write log @(yes, update@) @>
else
  @< write log @(no, no update@) @>
fi
@| @}





\subsection{The management script}
\label{sec:management-script}

@o m4_projroot/runit @{@%
#!/bin/bash
source m4_aprojroot/parameters
@< functions @>
@< remove old lockdir @>
runsingle
@< init logfile @>
@< load stopos module @>
@< check/create directories @>
@< get stopos status @>
waitingfilecount=`find $intray -type f -print | wc -l`
readyfilecount=`find $outtray -type f -print | wc -l`
procfilecount=`find $proctray -type f -print | wc -l`
unprocessedfilecount=$((waitingfilecount + $procfilecount))
@% @< do brief check of expired jobs @>
@< count jobs @>
if
  [ $total_jobs -eq 0 ]
then
   @< set up new stopos pool @>
else
   @< restore old procfiles @>
fi
@< submit jobs @>

veilig
@| @}

@d make scripts executable @{@%
chmod 775 m4_aprojroot/runit
@| @}


@% Regenerate the stopos pool if it is empty but there are still input-files. 
@% 
@% @d regenerate pool if it is prematurely empty @{@%
@% if
@%   [ $untouched_files -eq 0 ]
@% then
@%   @< (re-)generate stopos pool @>
@% fi
@% @| @}



\appendix

\section{How to read and translate this document}
\label{sec:translatedoc}

This document is an example of \emph{literate
  programming}~\cite{Knuth:1983:LP}. It contains the code of all sorts
of scripts and programs, combined with explaining texts. In this
document the literate programming tool \texttt{nuweb} is used, that is
currently available from Sourceforge
(URL:\url{m4_nuwebURL}). The advantages of Nuweb are, that
it can be used for every programming language and scripting language, that
it can contain multiple program sources and that it is very simple.


\subsection{Read this document}
\label{sec:read}

The document contains \emph{code scraps} that are collected into
output files. An output file (e.g. \texttt{output.fil}) shows up in the text as follows:

\begin{alltt}
"output.fil" \textrm{4a \(\equiv\)}
      # output.fil
      \textrm{\(<\) a macro 4b \(>\)}
      \textrm{\(<\) another macro 4c \(>\)}
      \(\diamond\)

\end{alltt}

The above construction contains text for the file. It is labelled with
a code (in this case 4a)  The constructions between the \(<\) and
\(>\) brackets are macro's, placeholders for texts that can be found
in other places of the document. The test for a macro is found in
constructions that look like:

\begin{alltt}
\textrm{\(<\) a macro 4b \(>\) \(\equiv\)}
     This is a scrap of code inside the macro.
     It is concatenated with other scraps inside the
     macro. The concatenated scraps replace
     the invocation of the macro.

{\footnotesize\textrm Macro defined by 4b, 87e}
{\footnotesize\textrm Macro referenced in 4a}
\end{alltt}

Macro's can be defined on different places. They can contain other macro's.

\begin{alltt}
\textrm{\(<\) a scrap 87e \(>\) \(\equiv\)}
     This is another scrap in the macro. It is
     concatenated to the text of scrap 4b.
     This scrap contains another macro:
     \textrm{\(<\) another macro 45b \(>\)}

{\footnotesize\textrm Macro defined by 4b, 87e}
{\footnotesize\textrm Macro referenced in 4a}
\end{alltt}


\subsection{Process the document}
\label{sec:processing}

The raw document is named
\verb|a_<!!>m4_progname<!!>.w|. Figure~\ref{fig:fileschema}
\begin{figure}[hbtp]
  \centering
@%  \includegraphics{fileschema.fig}
  \input{fileschema.pdftex_t}
  \caption{Translation of the raw code of this document into
    printable/viewable documents and into program sources. The figure
    shows the pathways and the main files involved.}
  \label{fig:fileschema}
\end{figure}
 shows pathways to
translate it into printable/viewable documents and to extract the
program sources. Table~\ref{tab:transtools}
\begin{table}[hbtp]
  \centering
  \begin{tabular}{lll}
    \textbf{Tool} & \textbf{Source} & \textbf{Description} \\
    gawk  & \url{www.gnu.org/software/gawk/}& text-processing scripting language \\
    M4    & \url{www.gnu.org/software/m4/}& Gnu macro processor \\
    nuweb & \url{nuweb.sourceforge.net} & Literate programming tool \\
    tex   & \url{www.ctan.org} & Typesetting system \\
    tex4ht & \url{www.ctan.org} & Convert \TeX{} documents into \texttt{xml}/\texttt{html}
  \end{tabular}
  \caption{Tools to translate this document into readable code and to
    extract the program sources}
  \label{tab:transtools}
\end{table}
lists the tools that are
needed for a translation. Most of the tools (except Nuweb) are available on a
well-equipped Linux system.

@%\textbf{NOTE:} Currently, not the most recent version  of Nuweb is used, but an older version that has been modified by me, Paul Huygen.

@d parameters in Makefile @{@%
NUWEB=m4_nuwebbinary
@| @}


\subsection{The Makefile for this project.}
\label{sec:transrun}

This chapter assembles the Makefile for this project.

@o Makefile -t @{@%
@< default target @>

@< parameters in Makefile @> 

@< impliciete make regels @>
@< expliciete make regels @>
@< make targets @>
@| @}

The default target of make is \verb|all|.

@d  default target @{@%
all : @< all targets @>
.PHONY : all

@|PHONY all @}

@d make targets @{@%
clean:
	@< clean up @>

@| @}



One of the targets is certainly the \textsc{pdf} version of this
document.

@d all targets @{m4_progname.pdf@}

We use many suffixes that were not known by the C-programmers who
constructed the \texttt{make} utility. Add these suffixes to the list.

@d parameters in Makefile @{@%
.SUFFIXES: .pdf .w .tex .html .aux .log .php

@| SUFFIXES @}


\subsection{Get Nuweb}
\label{sec:getnuweb}

An annoying problem is, that this program uses nuweb, a utility that
is seldom installed on a computer. Therefore, we are going to install
that first if it is not present. Unfortunately, nuweb is hosted on
sourceforge and it is difficult to achieve automatic downloading from
that repository. Therefore I copied one of the versions on a location
from where it can be downloaded with a script.

Put the nuweb binary in the nuweb subdirectory, so that it can be used before the directory-structure has been generated.

@% @d parameters in Makefile @{@%
@% NUWEB=./nuweb
@% @| NUWEB @}

@d expliciete make regels @{@%

nuweb: $(NUWEB)

$(NUWEB): m4_projroot/m4_nuwebsource
	mkdir -p m4_envbindir
	cd m4_projroot/m4_nuwebsource && make nuweb
	cp m4_projroot/m4_nuwebsource/nuweb $(NUWEB)

@| @}

@d clean up @{@%
rm -rf m4_projroot/m4_nuwebsource
@| @}


@d expliciete make regels @{@%
m4_projroot/m4_nuwebsource:
	cd m4_projroot && wget m4_nuweb_download_url
	cd m4_projroot &&  tar -xzf m4_nuwebsource<!!>.tgz

@| @}



@% @d rule to make nuweb @{@%
@% nuweb-exists := \$(shell which nuweb)
@% 
@% install-nuweb:
@% ifdef nuweb-exists
@% 
@% else
@% 	cd m4_aprojroot &&  wget m4_nuweb_download_url
@%         cd m4_aprojroot &&  tar -xzf m4_nuwebsource<!!>.tgz
@%         cd m4_aprojroot/m4_nuwebsource && make nuweb
@%         mv m4_nuwebsource/nuweb m4_bindir
@% 
@% endif
@% 
@% @| @}


\subsection{Pre-processing}
\label{sec:pre-processing}

To make usable things from the raw input
\verb|a_<!!>m4_progname<!!>.w|, do the following:

\begin{enumerate}
\item Process \verb|\$| characters.
\item Run the m4 pre-processor.
\item Run nuweb.
\end{enumerate}

This results in a \LaTeX{} file, that can be converted into a \pdf{}
or a \HTML{} document, and in the program sources and scripts.

\subsubsection{Process `dollar' characters }
\label{sec:procdollars}

Many ``intelligent'' \TeX{} editors (e.g.\ the auctex utility of
Emacs) handle \verb|\$| characters as special, to switch into
mathematics mode. This is irritating in program texts, that often
contain \verb|\$| characters as well. Therefore, we make a stub, that
translates the two-character sequence \verb|\\$| into the single
\verb|\$| character.


@d expliciete make regels @{@%
m4_<!!>m4_progname<!!>.w : a_<!!>m4_progname<!!>.w
@%	gawk '/^@@%/ {next}; {gsub(/[\\][\\$\$]/, "$$");print}' a_<!!>m4_progname<!!>.w > m4_<!!>m4_progname<!!>.w
	gawk '{if(match($$0, "@@<!!>%")) {printf("%s", substr($$0,1,RSTART-1))} else print}' a_<!!>m4_progname.w \
          | gawk '{gsub(/[\\][\\$\$]/, "$$");print}'  > m4_<!!>m4_progname<!!>.w
@% $

@| @}

@%@d expliciete make regels @{@%
@%m4_<!!>m4_progname<!!>.w : a_<!!>m4_progname<!!>.w
@%	gawk '/^@@%/ {next}; {gsub(/[\\][\\$\$]/, "$$");print}' a_<!!>m4_progname<!!>.w > m4_<!!>m4_progname<!!>.w
@%
@%@% $
@%@| @}

\subsubsection{Run the M4 pre-processor}
\label{sec:run_M4}

@d  expliciete make regels @{@%
m4_progname<!!>.w : m4_<!!>m4_progname<!!>.w inst.m4
	m4 -P m4_<!!>m4_progname<!!>.w > m4_progname<!!>.w

@| @}


\subsection{Typeset this document}
\label{sec:typeset}

Enable the following:
\begin{enumerate}
\item Create a \pdf{} document.
\item Print the typeset document.
\item View the typeset document with a viewer.
\item Create a \HTML document.
\end{enumerate}

In the three items, a typeset \pdf{} document is required or it is the
requirement itself.

@d impliciete make regels @{@%
%.pdf: %.w
	./w2pdf $<

@| @}



\subsubsection{Figures}
\label{sec:figures}

This document contains figures that have been made by
\texttt{xfig}. Post-process the figures to enable inclusion in this
document.

The list of figures to be included:

@d parameters in Makefile @{@%
FIGFILES=fileschema directorystructure

@| FIGFILES @}

We use the package \texttt{figlatex} to include the pictures. This
package expects two files with extensions \verb|.pdftex| and
\verb|.pdftex_t| for \texttt{pdflatex} and two files with extensions \verb|.pstex| and
\verb|.pstex_t| for the \texttt{latex}/\texttt{dvips}
combination. Probably tex4ht uses the latter two formats too.

Make lists of the graphical files that have to be present for
latex/pdflatex:

@d parameters in Makefile @{@%
FIGFILENAMES=\$(foreach fil,\$(FIGFILES), \$(fil).fig)
PDFT_NAMES=\$(foreach fil,\$(FIGFILES), \$(fil).pdftex_t)
PDF_FIG_NAMES=\$(foreach fil,\$(FIGFILES), \$(fil).pdftex)
PST_NAMES=\$(foreach fil,\$(FIGFILES), \$(fil).pstex_t)
PS_FIG_NAMES=\$(foreach fil,\$(FIGFILES), \$(fil).pstex)

@|FIGFILENAMES PDFT_NAMES PDF_FIG_NAMES PST_NAMES PS_FIG_NAMES@}


Create
the graph files with program \verb|fig2dev|:

@d impliciete make regels @{@%
%.eps: %.fig
	fig2dev -L eps \$< > \$@@

%.pstex: %.fig
	fig2dev -L pstex \$< > \$@@

.PRECIOUS : %.pstex
%.pstex_t: %.fig %.pstex
	fig2dev -L pstex_t -p \$*.pstex \$< > \$@@

%.pdftex: %.fig
	fig2dev -L pdftex \$< > \$@@

.PRECIOUS : %.pdftex
%.pdftex_t: %.fig %.pstex
	fig2dev -L pdftex_t -p \$*.pdftex \$< > \$@@

@| fig2dev @}


\subsubsection{Bibliography}
\label{sec:bbliography}

To keep this document portable, create a portable bibliography
file. It works as follows: This document refers in the
\texttt|bibliography| statement to the local \verb|bib|-file
\verb|m4_progname.bib|. To create this file, copy the auxiliary file
to another file \verb|auxfil.aux|, but replace the argument of the
command \verb|\bibdata{m4_progname}| to the names of the bibliography
files that contain the actual references (they should exist on the
computer on which you try this). This procedure should only be
performed on the computer of the author. Therefore, it is dependent of
a binary file on his computer.


@d expliciete make regels @{@%
bibfile : m4_progname.aux m4_mkportbib
	m4_mkportbib m4_progname m4_bibliographies

.PHONY : bibfile
@| @}

\subsubsection{Create a printable/viewable document}
\label{sec:createpdf}

Make a \pdf{} document for printing and viewing.

@d make targets @{@%
pdf : m4_progname.pdf

print : m4_progname.pdf
	m4_printpdf(m4_progname)

view : m4_progname.pdf
	m4_viewpdf(m4_progname)

@| pdf view print @}

Create the \pdf{} document. This may involve multiple runs of nuweb,
the \LaTeX{} processor and the bib\TeX{} processor, and depends on the
state of the \verb|aux| file that the \LaTeX{} processor creates as a
by-product. Therefore, this is performed in a separate script,
\verb|w2pdf|.

\paragraph{The w2pdf script}
\label{sec:w2pdf}

The three processors nuweb, \LaTeX{} and bib\TeX{} are
intertwined. \LaTeX{} and bib\TeX{} create parameters or change the
value of parameters, and write them in an auxiliary file. The other
processors may need those values to produce the correct output. The
\LaTeX{} processor may even need the parameters in a second
run. Therefore, consider the creation of the (\pdf) document finished
when none of the processors causes the auxiliary file to change. This
is performed by a shell script \verb|w2pdf|.

@%@d make targets @{@%
@%m4_progname.pdf : m4_progname.w \$(FIGFILES)
@%	chmod 775 bin/w2pdf
@%	bin/w2pdf m4_progname
@%
@%@| @}



@% Note, that in the following \texttt{make} construct, the implicit rule
@% \verb|.w.pdf| is not used. It turned out, that make did not calculate
@% the dependencies correctly when I did use this rule.
@% 
@% @d  impliciete make regels@{@%
@% @%.w.pdf :
@% %.pdf : %.w \$(W2PDF)  \$(PDF_FIG_NAMES) \$(PDFT_NAMES)
@% 	chmod 775 \$(W2PDF)
@% 	\$(W2PDF) \$*
@% 
@% @| @}

@% Unfortunately, the above rule does not seem to work as expected. When
@% the Makefile is invoked while  \texttt{nlpp.pdf} doens not exists,
@% make produces the following message:
@% 
@% \begin{verbatim}
@% paul@@klipperaak:/mnt/sdb1/pipelines/testnlpp/nlpp/nuweb$ make pdf
@% make: *** No rule to make target `nlpp.pdf', needed by `pdf'.  Stop.
@% 
@% \end{verbatim}
@% 
@% Therefore we add the following explicit rule:


@d make targets @{@%
m4_progname<!!>.pdf : m4_progname<!!>.w \$(W2PDF)  \$(PDF_FIG_NAMES) \$(PDFT_NAMES)
	chmod 775 \$(W2PDF)
	\$(W2PDF) \$*

@| @}



The following is an ugly fix of an unsolved problem. Currently I
develop this thing, while it resides on a remote computer that is
connected via the \verb|sshfs| filesystem. On my home computer I
cannot run executables on this system, but on my work-computer I
can. Therefore, place the following script on a local directory.

@d directories to create @{m4_nuwebbindir @| @}


@d parameters in Makefile @{@%
W2PDF=m4_nuwebbindir/w2pdf
@| @}

@d expliciete make regels  @{@%
\$(W2PDF) : m4_progname.w \$(NUWEB)
	\$(NUWEB) m4_progname.w
@| @}

m4_dnl
m4_dnl Open compile file.
m4_dnl args: 1) directory; 2) file; 3) Latex compiler
m4_dnl
m4_define(m4_opencompilfil,
<!@o !>\$1<!!>\$2<! @{@%
#!/bin/bash
# !>\$2<! -- compile a nuweb file
# usage: !>\$2<! [filename]
# !>m4_header<!
NUWEB=m4_nuwebbinary
LATEXCOMPILER=!>\$3<!
@< filenames in nuweb compile script @>
@< compile nuweb @>

@| @}
!>)m4_dnl

m4_opencompilfil(<!m4_nuwebbindir/!>,<!w2pdf!>,<!pdflatex!>)m4_dnl

@%@o w2pdf @{@%
@%#!/bin/bash
@%# w2pdf -- make a pdf file from a nuweb file
@%# usage: w2pdf [filename]
@%#  [filename]: Name of the nuweb source file.
@%`#' m4_header
@%echo "translate " \$1 >w2pdf.log
@%@< filenames in w2pdf @>
@%
@%@< perform the task of w2pdf @>
@%
@%@| @}

The script retains a copy of the latest version of the auxiliary file.
Then it runs the four processors nuweb, \LaTeX{}, MakeIndex and bib\TeX{}, until
they do not change the auxiliary file or the index. 

@d compile nuweb @{@%
NUWEB=m4_anuwebbinary
@< run the processors until the aux file remains unchanged @>
@< remove the copy of the aux file @>
@| @}

The user provides the name of the nuweb file as argument. Strip the
extension (e.g.\ \verb|.w|) from the filename and create the names of
the \LaTeX{} file (ends with \verb|.tex|), the auxiliary file (ends
with \verb|.aux|) and the copy of the auxiliary file (add \verb|old.|
as a prefix to the auxiliary filename).

@d filenames in nuweb compile script @{@%
nufil=\$1
trunk=\${1%%.*}
texfil=\${trunk}.tex
auxfil=\${trunk}.aux
oldaux=old.\${trunk}.aux
indexfil=\${trunk}.idx
oldindexfil=old.\${trunk}.idx
@| nufil trunk texfil auxfil oldaux indexfil oldindexfil @}

Remove the old copy if it is no longer needed.
@d remove the copy of the aux file @{@%
rm \$oldaux
@| @}

Run the three processors. Do not use the option \verb|-o| (to suppres
generation of program sources) for nuweb,  because \verb|w2pdf| must
be kept up to date as well.

@d run the three processors @{@%
\$NUWEB \$nufil
\$LATEXCOMPILER \$texfil
makeindex \$trunk
bibtex \$trunk
@| nuweb makeindex bibtex @}


Repeat to copy the auxiliary file and the index file  and run the processors until the
auxiliary file and the index file are equal to their copies.
 However, since I have not yet been able to test the \verb|aux|
file and the \verb|idx| in the same test statement, currently only the
\verb|aux| file is tested.

It turns out, that sometimes a strange loop occurs in which the
\verb|aux| file will keep to change. Therefore, with a counter we
prevent the loop to occur more than m4_maxtexloops times.

@d run the processors until the aux file remains unchanged @{@%
LOOPCOUNTER=0
while
  ! cmp -s \$auxfil \$oldaux 
do
  if [ -e \$auxfil ]
  then
   cp \$auxfil \$oldaux
  fi
  if [ -e \$indexfil ]
  then
   cp \$indexfil \$oldindexfil
  fi
  @< run the three processors @>
  if [ \$LOOPCOUNTER -ge 10 ]
  then
    cp \$auxfil \$oldaux
  fi;
done
@| @}


\subsubsection{Create HTML files}
\label{sec:createhtml}

\textsc{Html} is easier to read on-line than a \pdf{} document that
was made for printing. We use \verb|tex4ht| to generate \HTML{}
code. An advantage of this system is, that we can include figures
in the same way as we do for \verb|pdflatex|.

To create a \textsc{html} doc, we do the following:

\begin{enumerate}
\item Create a directory \texttt{m4_htmldocdir} for the \textsc{html} document.
\item Put the nuweb source in it, together with style-files that are needed (see variable \texttt{HTMLSOURCE}).
\item Put the script \texttt{w2html} in it and make it executable.
\item Execute the script \texttt{w2html}.
\end{enumerate}

Make a list of the entities that we mentioned above:

@d parameters in Makefile @{@%
htmldir=m4_htmldocdir
htmlsource=m4_progname<!!>.w m4_progname<!!>.bib m4_html_style m4_4ht_template w2html
htmlmaterial=\$(foreach fil, \$(htmlsource), \$(htmldir)/\$(fil))
htmltarget=$(htmldir)/m4_progname<!!>.html
@| @}

Make the directory:

@d expliciete make regels @{@%
$(htmldir) : 
	mkdir -p $(htmldir)

@| @}

The rule to copy files in it:

@d impliciete make regels  @{@%
$(htmldir)/% : % $(htmldir)
	cp $< $(htmldir)/

@| @}

Do the work:

@d expliciete make regels @{@%
$(htmltarget) : $(htmlmaterial) $(htmldir) 
	cd $(htmldir) && chmod 775 w2html
	cd $(htmldir) && ./w2html nlpp.w

@| @}

Invoke:

@d  make targets @{@%
htm : $(htmldir) $(htmltarget)

@| @}



@% Nuweb creates a \LaTeX{} file that is suitable
@% for \verb|latex2html| if the source file has \verb|.hw| as suffix instead of
@% |.w|. However, this feature is not compatible with tex4ht.
@% 
@% To generate \texttt{html} we need a directory with the following:
@% \begin{itemize}
@% \item Source file \texttt{m4_progname<!!>.w} and bib file \texttt{m4_progname<!!>.bib} 
@% \item Style files \texttt{m4_html_style} and \texttt{m4_4ht_template}.
@% \item Script \texttt{w2html} that generates the \textsc{html} document.
@% @% \item Files with the images (\texttt{.pstex}) and \texttt{pstex_t})
@% \end{itemize}
@% 


@% @d parameters in Makefile @{@%
@% _PS_FIG_NAMES=\$(foreach fil,\$(FIGFILES), m4_htmldocdir/\$(fil).pstex)
@% HTML_PST_NAMES=\$(foreach fil,\$(FIGFILES), m4_htmldocdir/\$(fil).pstex_t)
@% @| @}



@% @d impliciete make regels @{@%
@% m4_htmldocdir/%.pstex : %.pstex
@% 	cp  \$< \$@@
@% 
@% m4_htmldocdir/%.pstex_t : %.pstex_t
@% 	cp  \$< \$@@
@% 
@% @| @}
@% 

@% The author prefers a non-standard \LaTeX{} document-class
@% (i.e. \texttt{artikel3}) above the standard. However, \texttt{htlatex}
@% needs a kind of class file with the same name as tje documentclass,
@% but with extension \texttt{.4ht}. So, let us provide such a thing.
@% 
@% @d expliciete make regels @{@%
@% html/m4_4ht_template : m4_4ht_template
@% 	cp m4_4htfilsource m4_4htfildest
@% 
@% @| @}



@% \texttt{htlatex} cannot handle this documentstyle
@% correctly. Therefore, copy the nuweb file into the \texttt{html}
@% subdirectory, but change the documentstyle with the following
@% \textsc{awk} script.
@% 
@% @d parameters in Makefile @{@%
@% HTMLKLUDGE='/\\documentclass/ {$0 = "\\documentclass{article}"}; {print}'
@% @| @}


@% @d expliciete make regels @{@%
@% m4_htmlsource : m4_progname.w
@% 	cp m4_progname m4_htmlsource
@% 
@% @| @}
@% 
@% Copy the bibliography.
@% 
@% @d expliciete make regels  @{@%
@% m4_htmlbibfil : m4_nuwebdir/m4_progname.bib
@% 	cp m4_nuwebdir/m4_progname.bib m4_htmlbibfil
@% 
@% @| @}



@% Make a dvi file with \texttt{w2html} and then run
@% \texttt{htlatex}. 
@% 
@% @d expliciete make regels @{@%
@% m4_htmltarget : m4_htmlsource m4_4htfildest \$(HTML_PS_FIG_NAMES) \$(HTML_PST_NAMES) m4_htmlbibfil
@% 	cp w2html m4_bindir
@% 	cd m4_bindir && chmod 775 w2html
@% 	cd m4_htmldocdir && m4_bindir/w2html m4_progname.w
@% 
@% @| @}
@% 
Create a script that performs the translation.

@%m4_<!!>opencompilfil(m4_htmldocdir/,`w2dvi',`latex')m4_dnl


@o w2html @{@%
#!/bin/bash
# w2html -- make a html file from a nuweb file
# usage: w2html [filename]
#  [filename]: Name of the nuweb source file.
<!#!> m4_header
echo "translate " \$1 >w2html.log
NUWEB=m4_anuwebbinary
@< filenames in w2html @>

@< perform the task of w2html @>

@| @}

The script is very much like the \verb|w2pdf| script, but at this
moment I have still difficulties to compile the source smoothly into
\textsc{html} and that is why I make a separate file and do not
recycle parts from the other file. However, the file works similar.


@d perform the task of w2html @{@%
@< run the html processors until the aux file remains unchanged @>
@< remove the copy of the aux file @>
@| @}


The user provides the name of the nuweb file as argument. Strip the
extension (e.g.\ \verb|.w|) from the filename and create the names of
the \LaTeX{} file (ends with \verb|.tex|), the auxiliary file (ends
with \verb|.aux|) and the copy of the auxiliary file (add \verb|old.|
as a prefix to the auxiliary filename).

@d filenames in w2html @{@%
nufil=\$1
trunk=\${1%%.*}
texfil=\${trunk}.tex
auxfil=\${trunk}.aux
oldaux=old.\${trunk}.aux
indexfil=\${trunk}.idx
oldindexfil=old.\${trunk}.idx
@| nufil trunk texfil auxfil oldaux @}

@d run the html processors until the aux file remains unchanged @{@%
while
  ! cmp -s \$auxfil \$oldaux 
do
  if [ -e \$auxfil ]
  then
   cp \$auxfil \$oldaux
  fi
@%  if [ -e \$indexfil ]
@%  then
@%   cp \$indexfil \$oldindexfil
@%  fi
  @< run the html processors @>
done
@< run tex4ht @>

@| @}


To work for \textsc{html}, nuweb \emph{must} be run with the \verb|-n|
option, because there are no page numbers.

@d run the html processors @{@%
\$NUWEB -o -n \$nufil
latex \$texfil
makeindex \$trunk
bibtex \$trunk
htlatex \$trunk
@| @}


When the compilation has been satisfied, run makeindex in a special
way, run bibtex again (I don't know why this is necessary) and then run htlatex another time.
@d run tex4ht @{@%
m4_index4ht
makeindex -o \$trunk.ind \$trunk.4dx
bibtex \$trunk
htlatex \$trunk
@| @}


\subsection{Create the program sources}
\label{sec:createsources}

Run nuweb, but suppress the creation of the \LaTeX{} documentation.
Nuweb creates only sources that do not yet exist or that have been
modified. Therefore make does not have to check this. However,
``make'' has to create the directories for the sources if they
do not yet exist.
@%This is especially important for the directories
@%with the \HTML{} files. It seems to be easiest to do this with a shell
@%script.
So, let's create the directories first.

@d parameters in Makefile @{@%
MKDIR = mkdir -p

@| MKDIR @}



@d make targets @{@%
DIRS = @< directories to create @>

\$(DIRS) : 
	\$(MKDIR) \$@@

@| DIRS @}

@d make scripts executable @{@%
chmod -R 775  m4_bindir/*
chmod -R 775  m4_envbindir/*
@| @}



@d make targets @{@%
source : m4_progname.w \$(DIRS) \$(NUWEB)
@%	cp ./createdirs m4_bindir/createdirs
@%	cd m4_bindir && chmod 775 createdirs
@%	m4_bindir/createdirs
	\$(NUWEB) m4_progname.w
	@< make scripts executable @>

@| @}

@%@o createdirs @{@%
@%#/bin/bash
@%# createdirs -- create directories
@%`#' m4_header
@%@< create directories @>
@%@| @}

@% \subsection{Restore paths after transplantation}
@% \label{sec:paths-restore}
@% 
@% When an existing installation has been transplanted to another
@% location, many path indications have to be adapted to the new
@% situation. The scripts that are generated by nuweb can be repaired by
@% re-running nuweb. After that, configuration files of some modules must
@% be modified.
@% 
@% @d make targets @{@%
@% transplant :
@% 	touch a_<!!>m4_progname<!!>.w
@% 	$(MAKE) sources
@% 	m4_envbindir/transplant
@% 
@% @| @}


@% In order to work as expected, the following script must be re-made
@% after a transplantation.
@% 
@% @o m4_envbindir/transplant @{@%
@% #!/bin/bash
@% LOGLEVEL=1
@% @< set variables that point to the directory-structure @>
@% @< set paths after transplantation @>
@% @< re-install modules after the transplantation @>
@% 
@% @| @}



\section{References}
\label{sec:references}

\subsection{Literature}
\label{sec:literature}

\bibliographystyle{plain}
\bibliography{m4_progname}

@% \subsection{URL's}
@% \label{sec:urls}
@% 
@% \begin{description}
@% \item[Nuweb:] \url{m4_nuwebURL}
@% \item[Apache Velocity:] \url{m4_velocityURL}
@% \item[Velocitytools:] \url{m4_velocitytoolsURL}
@% \item[Parameterparser tool:] \url{m4_parameterparserdocURL}
@% \item[Cookietool:] \url{m4_cookietooldocURL}
@% \item[VelocityView:] \url{m4_velocityviewURL}
@% \item[VelocityLayoutServlet:] \url{m4_velocitylayoutservletURL}
@% \item[Jetty:] \url{m4_jettycodehausURL}
@% \item[UserBase javadoc:] \url{m4_userbasejavadocURL}
@% \item[VU corpus Management development site:] \url{http://code.google.com/p/vucom} 
@% \end{description}

\section{Indexes}
\label{sec:indexes}


\subsection{Filenames}
\label{sec:filenames}

@f

\subsection{Macro's}
\label{sec:macros}

@m

\subsection{Variables}
\label{sec:veriables}

@u

\end{document}

% Local IspellDict: british 

% LocalWords:  Webcom
