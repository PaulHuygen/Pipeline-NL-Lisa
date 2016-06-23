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
\newcommand{\CPU}{\textsc{cpu}}
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
  This is a description and documentation of a system that uses
  SurfSara's supercomputer
  \href{https://userinfo.surfsara.nl/systems/lisa}{Lisa} to perform
  large-scale \NLP{} annotation on Dutch or English documents. The
  documents should have the size of typical newspaper-articles and
  they should be formatted in the \NAF{} format. The
  annotation-pipeline can be found on
  \href{https://github.com/PaulHuygen/nlpp}{``Newsreader pipeline''}.
\end{abstract}
\tableofcontents

\section{Introduction}
\label{sec:Introduction}

This document describes a system for large-scale linguistic annotation
of documents, using supercomputer
\href{https://userinfo.surfsara.nl/systems/lisa}{Lisa}. Lisa is a
computer-system co-owned by the Vrije Universiteit Amsterdam. This
document is especially useful for members of the Computational
Lexicology and Terminology Lab (\CLTL{}) of the Vrije Universiteit
Amsterdam who have access to that computer. Currently, the documents
to be processed have to be encoded in the \emph{NLP Annotation Format}
(\href{https://github.com/newsreader/NAF}{\NAF}).

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
\item Create a subdirectory \verb|data/in| and fill it with (a
  directoy-structure containing) raw \NAF's
  that have to be annotated.
\item Run script \verb|runit|.
\item Repeat to run \verb|runit| on a regular bases (e.g. twice per
  hour) until subdirectory \verb|data/in/| and subdirectory
  \verb|data/proc| are both empty.
\item The annotated \NAF{} files can be found in
  \verb|data/out|. Documents on which the annotation failed
  (e.g. because the annotation took too much time) have been moved to
  directory \verb|data/fail|.  
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

@% \section{Elements of the job}
@% \label{sec:elements}

\subsection{How it works}
\label{sec:how}

\subsubsection{Moving files around}
\label{sec:filestructure}

The \NAF{} files and the logfiles are stored in the following
subdirectories of the \verb|data| subdirectory:

\begin{description}
\item[in:] To store the input \NAF{}'s.
\item[proc:] Temporary storage of the input files while they are being processed.
\item[fail:] For the input \NAF's that could not be processed.
\item[log:] For logfiles.
\item[out] The annotated files appear here.
\end{description}

The user stores the raw \NAF{} files in directory \verb|data/in|. She
may construct a structure with subdirectories in \verb|data/in| that
contain the \NAF{} files. If she does that, the system copies this
file-structure in the other subdirectories of \verb|data|.  Processing
the files is performed by jobs. Before a job processes a document, it
moves the document from \verb|in| to \verb|proc|, to indicate that
processing this document has been started.

When the job is not able to perform processing to completion
(e.g. because it is aborted), the \NAF{} file remains in the
\verb|proc| subdirectory. At regular intervals a management script
runs, and this moves \NAF{}'s of which
processing has not been completed back to \verb|in|.

While processing a document, a job generates log information and
stores this in a log file with the same name as the input \NAF{} file
in directory \verb|log|. If processing fails, the job moves the
input \NAF{} file from \verb|proc| to
\verb|fail|. Otherwise, the job stores the output \NAF{} file in
\verb|out| and removes the input \NAF{} file from \verb|proc|.

@d parameters @{@%
export walltime=m4_walltime
export root=m4_aprojroot
export intray=m4_indir
export proctray=m4_procdir
export outtray=m4_outdir
export failtray=m4_faildir
export logtray=m4_logdir
@| walltime root intray outtray failtray logtray @}


\subsubsection{Managing the documents with Stopos}
\label{sec:docmanagement}

The processes in the jobs that do the work pick \NAF{} files from \verb|data/in|
in order to process them. There must be a system that arranges that
each \NAF{} file is picked up by only one job-process. To do this, we
use the
\href{https://userinfo.surfsara.nl/systems/lisa/software/stopos}{``Stopos''}
system that is implemented in Lisa. A management script makes a list
of the files in \verb|\data\in| and passes it to a ``stopos
pool'' where the work processes can find them.

Periodically the management script moves unprocessed documents from
\verb|data/proc| to \verb|data/in| and regenerate the infilelist in the
Stopos pool.

A list of files to be processed is called a ``Stopos pool''. 

@d parameters @{@%
export stopospool=m4_stopospool
@| stopospool @}

Load the stopos module in a script:

@d load stopos module @{@%
module load stopos
@| stopos module @}

\subsubsection{Management script}
\label{sec:managementscript}

A management script \verb|runit| set the system to work and keep
the system working until all input files have been processed until either
successful completion or failure. The script must run periodically in
order to restore unfinished input-files from \verb|data/proc| to
\verb|data/in| and to submit enough jobs to the job-system.

\subsubsection{Job script}
\label{sec:jobscript}

The management-script submits a Bash script as a job to the
job-management system of Lisa. The script contains special parameters
for the job system (e.g. to set the maximum processing time). It
generate a number of parallel processes that do the work.

To enhance flexibility the job script is generated from a template
with the M4 pre-processor.

\subsubsection{Set parameters}
\label{sec:parameters}

The system has several parameters that will be set as Bash variables
in file \verb|parameters|. The user can edit that file to change
parameters values

@o m4_projroot/parameters @{@%
@< parameters @>
@| @}


\section{Files}
\label{sec:files}

Viewed from the surface, what the pipeline does is reading, creating,
moving and deleting files. The input is a directory tree with \NAF{}
files, the outputs are similar trees with \NAF{} files and log
files. The system generates processes that run at the same time, reading files from the
input tree. It must be made certain that each file is processed by
only one process. This section describes and builds the directory
trees and the ``stopos'' system that supplies paths to input \NAF{}
files to the processes.

\subsection{Move NAF-files around}
\label{sec:filemoving}

The user may set up a structure with subdirectories to store the input
\NAF{} files. This structure must be copied in the other data
directories.

@% The following two macro's copy resp.{} move a file that is presented
@% with it's full path from a source data directory to a similar path in a
@% target data-directory. Arguments:
@% 
@% \begin{enumerate}
@% \item Full path of sourcefile.
@% \item Full path of source tray.
@% \item Full path of target tray
@% \end{enumerate}
@% 
@% @d copy file @{cp @1 $@3/${@1##$@2}@| @}
@% 
@% @d move file @{mv @1 $@3/${@1##$@2}@| @}

The following bash functions copy resp.{} move a file that is presented
with it's full path from a source data directory to a similar path in a
target data-directory. Arguments:
\begin{enumerate}
\item Full path of sourcefile.
\item Full path of source tray.
\item Full path of target tray
\end{enumerate}

The functions can be used as
\href{http://unix.stackexchange.com/questions/158564/how-to-use-defined-function-with-xargs}{arguments
  in \texttt{xargs}}.

@d functions @{@%
function movetotray () {
local file=$1
local fromtray=$2
local totray=$3
local frompath=${file%/*}
local topath=$totray${frompath##$fromtray}
mkdir -p $topath
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
mkdir -p $topath
cp $file $totray${file##fromtray}
}

export -f copytotray

@| copytotray @}

\subsection{Count the files and manage directories}
\label{sec:bookkeeping}

When the management script starts, it checks whether there is an input
directory. If that is the case, it generates the other directories if
they do not yet exist and then counts the files in the
directories. The variable \verb|unreadycount| is for the total number
of documents in the intray and in the proctray. 

@d check/create directories @{@%
@% infilesexist=1
@% if
@%   [ ! -d "$intray" ]
@% then
@%   echo "No input-files."
@%   echo "Create $intray and fill it with raw NAF's."
@%   veilig
@%   exit 4
@% fi
mkdir -p $outtray
mkdir -p $failtray
mkdir -p $logtray
mkdir -p $proctray
@< count files in tray @(intray@,incount@) @>
@< count files in tray @(proctray@,proccount@) @>
@< count files in tray @(failtray@,failcount@) @>
@< count files in tray @(logtray@,logcount@) @>
unreadycount=$((incount + $proccount))
@< remove empty directories @>
@| infilesexist incount proccount failcount logcount unreadycount @}

@% \subsection{Reset if there are no files to be processed}
@% \label{sec:reset}
@% 
@% If it turns out that there are no files to be processed, reset the system:
@% \begin{itemize}
@% \item Delete outstanding jobs.
@% \item Purge the stopos pool.
@% \item Set jobcounter to zero.
@% \item move remaining joblogfiles.
@% \end{itemize}
@% 
@% 
@% @d check/create directories @{@%
@% if
@%   [ ! "$(ls -A $intray)" ] &&  [ ! "$(ls -A $proctray)" ]
@% then
@%   echo "Finished processing"
@%   veilig
@%   exit
@% fi
@% @| @}



@d count files in tray @{@%
@2=`find $@1 -type f -print | wc -l`
@| @}

Remove empty directories in the intray and the proctray.
@d remove empty directories @{@%
find $intray -depth -type d -empty -delete
find $proctray -depth -type d -empty -delete
mkdir -p $intray
mkdir -p $proctray
@| @}

\subsection{Generate pathnames}
\label{sec:generatefilenames}

When a job has obtained the name of a file that it has to process, it
generates the full-pathnames of the files to be produced, i.e. the
files in the proctray, the outtray or the failtray and the logtray:

@d generate filenames @{@%
filtrunk=${infile##$intray/}
export outfile=$outtray/${filtrunk}
export failfile=$failtray/${filtrunk}
export logfile=$logtray/${filtrunk}
export procfile=$proctray/${filtrunk}
export outpath=${outfile%/*}
export procpath=${procfile%/*}
export logpath=${logfile%/*}
@| filtrunk outfile logfile procfile outpath procpath logpath @}

\subsection{Manage list of files in Stopos}
\label{sec:manage-by-stopos}

\subsubsection{Set up/reset pool}
\label{sec:poolsetup}

The processes obtain the names of the files to be processed from
Stopos. Adding large amount of filenames to the stopos pool take much
time, so this must be done sparingly. We do it as follows:
\begin{enumerate}
\item First look how many filenames are still available in the
  pool. If the pool is empty, or there are no files in the intray, or
  there are no jobs, the pool must be renewed. On the other hand,
  if there are still lots of filenames in it, we can leave the pool alone.
\item If the pool is running out, something has to be done:
\item Generate a file \verb|infilelist| that contains the paths to the files in
  the intray.
\item Assume file \verb|old.filenames|, if it exists, contains the
  filenames that have been inserted in the Stopos pool.
\item Delete from \verb|old.filenames| the names of the
  files that are no longer in the intray. They have probably been
  processed or are being processed.
\item  Move the files in the proctray that are not actually being
  processed back the intray. We know that these files are not being
  processed because either there are no running jobs or the files reside
  in the proctray for a longer time than jobs are allowed to run.
\item Make file \verb|infilelist| that lists files that are
  currently in the intray.
\item Check whether the listed filenames are present in
  \verb|old.filenames| and remove them from  \verb|infilelist| when
  that is the case. Put the result in  \verb|new.filenames|.
\item Add the files in \verb|new.filenames| to the pool.
\item Add the content of \verb|new.filenames| to \verb|old.filenames|.
\end{enumerate}

It seems that the file-bookkeeping that is external is sometimes
flawed and therefore we renew the pool as often as we can.


When we run the job -manager twice per hour, Stopos needs to contain
enough filenames to keep Lisa working for the next half hour. Probably
Lisa's job-control system does not allow us to run more than 100 jobs
at the same time. Typically a job runs seven parallel processes. Each
process will probably handle at most one \NAF{} file per minute. That
means, that if stopos contains $100 \times 7 \times 30 = 21 10^{3}$
filenames, Lisa can be kept working for half an hour.

First let us see whether we will update the existing pool or purge and
renew it. We renew it:
\begin{enumerate}
\item When there are no files in the intray, so the pool ought to be empty;
\item When there are no jobs around, so renewing the pool does not
  interfere with jobs running.
\item When the pool status tells us that the pool is empty.
\end{enumerate}




@d update the stopos pool @{@%
cd $root
@< is the pool full or empty? @(pool_full@,pool_empty@) @>
if
  [ \$pool_full -ne 0 ]
then
  @< make a list of filenames in the intray @>
  @< decide whether to renew the stopos-pool @>
  @< clean up pool and old.filenames @>
  @< clean up proctray @>
  @< add new filenames to the pool @>
fi
@|pool_full pool_empty @}


The following macro sets the first argument variable to ``1'' if the pool
does not exist or if it contains less then
m4_sufficient_stopos_entries filenames. Otherwise, it sets the
variable to ``0'' (true). It sets the second argument variable similar
when there no filenames left in the pool.

@d is the pool full or empty? @{@%
@1=1
@2=0
stopos -p \$stopospool status >/dev/null
result=\$?
if
  [ \$result -eq 0 ]
then
  if
    [ $STOPOS_PRESENT0 -gt m4_sufficient_stopos_entries ]
  then
    @1=0
  fi
  if
    [ $STOPOS_PRESENT0 -gt 0 ]
  then
    @2=1
  fi
fi
@| @}

@d  make a list of filenames in the intray @{@%
find \$intray -type f -print | sort >infilelist
intraysize=`cat infilelist | wc -l`
@| infilelist intraysize @}



Note that variable \verb|jobcount| needs to be known before running
the following macro. When variable \verb|regen_pool_condtion| is equal
to zero, the pool has to be renewed.

@d decide whether to renew the stopos-pool @{@%
cd $root
regen_pool_condition=1
if
  [ \$intraysize -eq 0 ] || [ \$jobcount -eq 0 ] || [ \$pool_empty -eq 0 ]
then
  regen_pool_condition=0
fi
@| regen_pool_condition @}

@d clean up pool and old.filenames @{@%
if
  [ \$regen_pool_condition -eq 0 ]
then
  stopos -p $stopospool purge
  stopos -p $stopospool create
  rm -f old.infilelist
  touch old.infilelist
else
    @< clean up old.infilelist @>
fi

@| @}

Remove from \verb|old.filelist| the names of files that are no longer
in the intray.

@d clean up old.infilelist @{@%
comm -12 old.infilelist infilelist >temp.infilelist
cp temp.infilelist old.infilelist
comm -13 old.infilelist infilelist >temp.infilelist
cp temp.infilelist infilelist
@| @}

Make a list of names of files in the proctray that should be moved to
the intray, either because they reside longer in the proctray than the
lifetime of jobs or because there are no running jobs.  Move the files
in the list back to the intray and add the list to \verb|infilelist|. \textbf{Note:} that after this \verb|infilelist| is no longer sorted.

@d clean up proctray @{@%
if
  [ $running_jobs -eq 0 ]
then
  find $proctray -type f -print | sort >oldprocfilelist
else
  find $proctray -type f -cmin +$maxproctime -print | sort  >oldprocfilelist
fi
cat oldprocfilelist | xargs -iaap  bash -c 'movetotray aap $proctray $intray'
cat infilelist oldprocfilelist >temp.infilelist
mv temp.infilelist infilelist
@| @}

Add the names of the files in the intray that are not yet in the pool
to the pool. Then update \verb|old.infilelist|.

@d add new filenames to the pool @{@%
stopos -p $stopospool add infilelist
cat infilelist old.infilelist | sort >temp.infilelist
mv temp.infilelist old.infilelist
rm infilelist
@| @}


@% Find the names of files that have been inserted in the pool and are
@% still in the intray. Pre-requisite: \verb|filenames| and
@% \verb|old.filenames| are both sorted. Replace \verb|old.filenames|
@% with this list. See \verb|man comm| to learn how \verb|comm| works.
@% 
@% The following macro generates a list of filenames that have in the past been added
@% to the pool and that are still present in the intray. This list goes
@% into \verb|old.infilelist|
@% 
@% @d update old.infilelist @{@%
@% comm -12 old.infilelist infilelist >old_current.infilelist
@% cp old_current.infilelist old.infilelist
@% @| @}
@% 
@% Find the names or the files that are in the intray but not yet in the
@% pool. Replace \verb|new.filenames| with this list.
@% 
@% @d generate new.infilelist @{@%
@% comm -13 old.infilelist infilelist >new.infilelist
@% @| @}
@% 
@% @d add contents of new.infilelist to old.infilelist @{@%
@% cat new.infilelist >>old.infilelist
@% sort old.infilelist >old.infilelist.sorted
@% mv old.infilelist.sorted old.infilelist
@% @| @}


@% @< make list  @>
@% 
@% @< add new infiles to stopos @>
@% 
@% @< make a sorted list of files in the intray @>
@% 
@% @< find out the number of files in the Stopos pool @>
@% if
@%   [ $stoposfiles -lt m4_min_stoposfiles ]
@% then
@%   passeer
@%   
@%   find $intray -type f -print >infilelist
@%   stopos -p $stopospool purge
@%   stopos -p $stopospool create
@%   stopos -p $stopospool add infilelist
@%   stopos -p $stopospool status
@%   veilig
@% @| @}


@% When no jobs are running, the files in the proctray will never be
@% annotated, so move them back to the intray.
@% 
@% @d move  procfiles to intray @{@%
@% if 
@%   [ $old_procfiles_only -eq 0 ]
@% then
@%    find $proctray -type f -cmin +$maxproctime -print | sort  >oldprocfilelist
@% else 
@%   find $proctray -type f -print | sort >oldprocfilelist
@% fi
@% @| @}
@% 
@% However, when there are running jobs, move only the files that reside
@% longer in the proctray than jobs can run.
@% 
@% @d move procfiles to intray @{@%
@% comm  -23 old.filelist oldprocfilelist >temp.filelist
@% mv temp.filelist old.filelist
@% cat oldprocfilelist | xargs -iaap  bash -c 'movetotray aap $proctray $intray'
@% @% find $proctray -type f -cmin +$maxproctime -print | xargs -iaap  bash -c 'movetotray aap $proctray $intray'
@% @| @}
@% 



@d parameters @{@%
maxproctime=m4_maxprocminutes
@|maxproctime @}

@% @d add new infiles to stopos @{@%
@% find $intray -type f -print | sort >infilelist
@% if
@%   [ -e old.infilelist ]
@% then
@%   diff old.infilelist infilelist | \
@%      gawk '/^> / {gsub(/^> /, ""); print}' \
@%      >new.infilelist  
@% else
@%   cp infilelist newfilelist
@% fi
@% 
@% @| @}


\subsubsection{Get a filename from the pool}
\label{sec:getfilename}

To get a filename from Stopos perform:

\begin{verbatim}
  stopos -p $stopospool next

\end{verbatim}

When this instruction is successfull, it sets variable
\verb|STOPOS_RC| to \verb|OK| and puts the filename in variable
\verb|STOPOS_VALUE|.

Get next input-file from stopos and put its full path in variable
\verb|infile|. If Stopos is empty, put an empty string in
\verb|infile|.

@d get next infile from stopos @{@%
stopos -p $stopospool next
if
  [ "$STOPOS_RC" == "OK" ]
then
   infile=$STOPOS_VALUE
else
  infile=""
fi
@| @}


\subsubsection{Function to get a filename from Stopos}
\label{sec:getfile-function}


The following function, getfile, reads a file from stopos, puts it in
variable \verb|infile| and sets the
paths to the outtray, the logtray and the failtray. When the Stopos
pool turns out to be empty, the variable is made empty.

@d  functions in the jobfile @{@%
function getfile() {
  infile=""
  outfile=""
  @< get next infile from stopos @>
  if
    [ ! "$infile" == "" ]
  then
    @< generate filenames @>
@%    echo To process $infile
  fi
}

@| getfile @}

\subsubsection{Remove a filename from Stopos}
\label{sec:removefilenamefromstopos}

@d remove the infile from the stopos pool @{@%
stopos -p $stopospool remove
@| @}


@%    \subsubsection{Get Stopos status}
@% \la@% bel{sec:stopos-state}
@% 
@% Find out whether the stopos pool exists and create it if that is not
@% the case.
@% 
@% When the stopos pool exists, find out how many filenames it lists and
@% how many of these files are still ``untouched'' (not claimed by any
@% process). 
@% 
@% @d get stopos status @{@%
@% stopos pools
@% if [ -z "`echo $STOPOS_VALUE | grep $stopospool `" ]
@% then 
@%    stopos -p $stopospool create
@% fi
@% stopos -p $stopospool status
@% untouched_files=$STOPOS_PRESENT0
@% busy_files=$STOPOS_PRESENT
@% @| @}
@% 
@% 

@% To enable this moving-around of \NAF{}
@% files, a management script has to perform the following:
@% 
@% \begin{enumerate}
@% \item Check whether there are raw NAF's to be processed.
@% \item Generate the output-tray to store the processed \NAF{}'s
@% \item Generate a Stopos pool with a list of the filenames of the NAF
@%   files or update an existing Stopos pool.
@% \end{enumerate}
@% 
@% 
@% A job performs the following:
@% 
@% \begin{enumerate}
@% \item Obtain the path to a raw naf in the intray.
@% \item Write a processed naf in a directory-tree on the outtray
@% \item Move a failed inputfile to the fail-tree
@% \end{enumerate}
@% 
@% Generate the directories to store the files when they are not yet
@% there.

\section{Jobs}
\label{sec:jobs}

\subsection{Manage the jobs}
\label{sec:manage-jobs}


The management script submits jobs when necessary. It needs to do the
following:

\begin{enumerate}
\item Count the number of submitted and running jobs.
\item Count the number of documents that still have to be processed.
\item Calculate the number of extra jobs that have to be submitted.
\item Submit the extra jobs.
\end{enumerate}

Find out how many submitted jobs there are and how many of them are
actually running. Lisa supplies an instruction \verb|showq| that
produces a list of running and waiting jobs. Unfortunately, it seems
that this instruction shows only the running jobs in job
arrays. Therefore we need to make job bookkeeping.

File \verb|jobcounter| lists the number of jobs. When extra jobs are
submitted, the number is increased. When logfiles are found that job
produce when they end, the number is decreased. 

@d count jobs @{@%
if
  [ -e jobcounter ]
then
  export jobcount=`cat jobcounter`
else
  jobcount=0
fi
@| @}

Count the logfiles that finished jobs produce. Derive the number of
jobs that have been finished since last time. Move the logfiles to
directory \verb|joblogs|. It is possible that jobs finish and produce
logfiles while we are doing all this. Therefore we start to make a
list of the logfiles that we will process.

@d count jobs @{@%
cd $root
ls -1 m4_jobname<!!>.[eo]* >jobloglist
finished_jobs=`cat jobloglist | grep "\.e" | wc -l`
@% finished_jobs=`ls -1 $root/m4_jobname<!!>.e* | wc -l`
mkdir -p joblogs
cat jobloglist | xargs -iaap mv aap joblogs/
if
  [ $finished_jobs -gt $jobcount ]
then
  jobcount=0
else
  jobcount=$((jobcount - $finished_jobs))
fi
@| @}

Extract the summaries of
the numbers of running jobs and the total number of jobs from the job
management system of Lisa.

@d count jobs @{@%
joblist=`mktemp -t jobrep.XXXXXX`
rm -rf $joblist
showq -u $USER | tail -n 1 > $joblist
running_jobs=`cat $joblist | gawk '
    { match($0, /Active Jobs:[[:blank:]]*([[:digit:]]+)[[:blank:]]*Idle/, arr)
      print arr[1]
    }'`
total_jobs_qn=`cat $joblist | gawk '
    { match($0, /Total Jobs:[[:blank:]]*([[:digit:]]+)[[:blank:]]*Active/, arr)
      print arr[1]
    }'`
rm $joblist
@| running_jobs total_jobs_qn @}


If there are more running than \verb|jobcount| lists, something is
wrong. The best we can do in that case is to make \verb|jobcount|
equal to \verb|running_jobs|. The same repair must be performed when
\verb|jobcount| reports that there are jobs around while Sara
maintains that this isn't the case.

@d count jobs @{@%
if
  [ $running_jobs -gt $jobcount ] || [ $running_jobs -eq 0 ]
then
  jobcount=$running_jobs
fi
@| @}



Currently we aim at one job per m4_filesperjob waiting files.
@d parameters @{@%
filesperjob=m4_filesperjob
@| @}

Calculate the number of jobs that have to be submitted.

@d determine how many jobs have to be submitted @{@%
@< determine number of jobs that we want to have @>
jobs_to_be_submitted=$((jobs_needed - $jobcount))
@| @}

Variable \verb|jobs_needed| will contain the number of jobs that we
want to have submitted, given the number of unready NAF files.

@d determine number of jobs that we want to have @{@%
jobs_needed=$((unreadycount / $filesperjob))
if
  [ $unreadycount -gt 0 ] && [ $jobs_needed -eq 0 ]
then
  jobs_needed=1
fi
@| @}

Let us not flood the place with millions of jobs. Set a max of
m4_maxjobs submitted jobs.

@d determine number of jobs that we want to have @{@%
if
  [ $jobs_needed -gt m4_maxjobs ]
then
  jobs_needed=m4_maxjobs
fi
@| @}


@d submit jobs when necessary @{@%
@< determine how many jobs have to be submitted @>
if
  [ \$jobs_to_be_submitted -gt 0 ]
then
   @< submit jobs @(\$jobs_to_be_submitted@) @>
   jobcount=$((jobcount + $jobs_to_be_submitted))
fi 
echo $jobcount > jobcounter
@| jobs_needed jobs_to_be_submitted@}




\subsection{Generate and submit jobs}
\label{sec:generate-jobs}

A job needs a script that tells what to do. The job-script is a Bash
script with the recipe to be executed, supplemented with instructions
for the job control system of the host. In order to perform the Art of
Making Things Unccesessary Complicated, we have a template from which
the job-script can be generated with the
\href{http://www.gnu.org/software/m4/m4.html}{M4 pre-processor}.

Generate job-script template \verb|job.m4| as follows:
\begin{enumerate}
\item Open the job-script with the wall-time parameter (the maximum duration that is allowed
for the job).
\item Add an instruction to change the M4 ``quote'' characters.
\item Add the M4 template \verb|m4_jobname|.
\end{enumerate}

Process the template with \texttt{M4}.


@d generate jobscript @{@%
echo "m4_<!!>define(m4_<!!>walltime, $walltime)m4_<!!>dnl" >job.m4
m4_changequote(<![!>,<!]!>)m4_dnl
echo 'm4_[]changequote(`<!'"'"',`!>'"'"')m4_[]dnl' >>job.m4
m4_changequote([<!],[!>])m4_dnl
cat m4_jobname<!!>.m4 >>job.m4
cat job.m4 | m4 -P >m4_jobname
# rm job.m4
@| @}


Submit the jobscript. The argument is the number of times that the
jobscript has to be submitted.

@d submit jobs @{@%
 @< generate jobscript @>
 jobid=`qsub -t 1-@1 m4_aprojroot/m4_jobname`
@| @}

\section{Logging}
\label{sec:logging}

There are three kinds of log-files:

\begin{enumerate}
\item Every job generates two logfiles in the directory from which it
  has been submitted (job logs).
\item Every job writes the time that it starts or finishes processing
  a naf in a \emph{time log}.
\item For every \NAF{} a file is generated in the log directory. This
  file contains the standard error output of the modules that
  processed the file.
\end{enumerate}


@% \subsection{Job logs}
@% \label{sec:joblogs}
@% 
@% While we are busy with file-bookkeeping, let us handle the job-logs
@% too. When a job finishes it produces two files that contain standard
@% output and standard error of the log. We remove logfiles that are more
@% than a day old. Job-logs have the same name as the job. The extension
@% begins with character \verb|o| (output) or  \verb|e|, followed by a number.
@% 
@% @d remove old joblogs @{@%
@% find $root -name "m4_jobname.[eo]*" -cmin +<!!>m4_maxjoblogminutes -delete
@% @| @}


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

@d log that the job starts @{@%
@< add timelog entry @(Start job $jobname@) @>
@| @}

@d log that the job finishes @{@%
@< add timelog entry @(Finish job $jobname@) @>
@| @}




@% \subsubsection{Stopos: file management}
@% \label{sec:filemanagement}
@% 
@% Stopos stores a set of parameters (in our case the full paths to
@% \NAF{} files that have to be processed) in a named ``pool''. A process
@% in a job can
@% read a parameter value from the pool and the Stopos system makes sure that
@% from that moment no other process is able to obtain that parameter value. When the job
@% has finished processing the parameter value, it removes the parameter value from
@% the pool.

@% \subsubsection{Generate a Stopos pool}
@% \label{sec:generate_pool}
@% 
@% When the script is started for the first time, hopefully raw \NAF{}
@% files are present in the intray, but there are no submitted jobs. When
@% there are no jobs, generate a new Stopos pool. Otherwise, there ought
@% to be a pool. To update the pool, restore files that resided for longer
@% time in the proctray into the intray and re-introduce them in the pool.

@% @d (re-)generate stopos pool @{@%
@% if
@%   [ $running_jobs -eq 0 ]
@% then
@%   @< set up new stopos pool @>
@% else
@%   @< restore old procfiles @>
@% fi
@% @| @}


@% Move files that reside longer than \verb|maxproctime| minutes back to
@% the intray. This works as follows:
@% 
@% \begin{enumerate}
@% \item function \verb|restoreprocfile| moves a file back to the intray
@%   and adds the path in the intray to a list in file \verb|restorefiles|.
@% \item The Unix function \verb|find| the old procfiles to function
@%   \verb|restoreprocfile|.
@% \item When the old procfiles have been collected, the filenames in
@%   \verb|restorefiles| are passed to Stopos.
@% \end{enumerate}
@% 
@% @d functions @{@%
@% function restoreprocfile {
@%   procf=$1
@%   infilelist=$2
@%   inf=$intray/${procfile##$proctray}
@%   echo $inf >>$filelist
@%   movetotray $procf $proctray $intray
@% }
@% export -f restoreprocfile
@% @| restoreprocfile @}



@% @d restore old procfiles @{@%
@% restorefilelist=`mktemp -t restore.XXXXXX`
@% find $proctray -type f -cmin +$maxproctime -print | \
@%    xargs -iaap  bash -c 'restoreprocfile aap $restorefilelist'
@% stopos -p $stopospool add $restorefilelist
@% rm $restorefilelist
@% @| @}



\section{Processes}
\label{sec:processes}

A job runs in computer that is part of the Lisa supercomputer. The
computer has a \CPU{} with multiple cores. To use the cores
effectively, the job generates parallel processes that do the
work. The number of processes to be generated depends on the number of
cores and the amount of memory that is available.

\subsection{Calculate the number of parallel processes to be launched}
\label{sec:processes_to_be_launched}

The stopos module, that we use to synchronize file management,
supplies the instructions \verb|sara-get-num-cores| and
\verb|sara-get-mem-size| that return the number of cores resp. the
amount of memory of the computer that hosts the job. \textbf{Note}
that the stopos module has to be loaded before the following macro can
be executed succesfully.

@d determine amount of memory and nodes @{@%
export ncores=`sara-get-num-cores`
#export MEMORY=`head -n 1 < /proc/meminfo | gawk '{print $2}'`
export memory=`sara-get-mem-size`
@| memory ncores @}


We want to run as many parallel processes as possible, however we do
want to have at least one node per process and at least an amount of
\verb|m4_memperprocess| GB of memory per process.

@d parameters @{@%
mem_per_process=m4_memperprocess
@| @}

Calculate the number of processes to be launched and write the result
in variable \verb|maxprogs|.

@d  determine number of parallel processes @{@%
export memchunks=$((memory / mem_per_process))
if
  [ $ncores -gt $memchunks ]
then
  maxprocs=$memchunks
else
  maxprocs=ncores
fi
@| maxprogs @}


\subsection{Start parallel processes}
\label{sec:start_processes}

@d run parallel processes @{@%
@< determine amount of memory and nodes @>
@< determine number of parallel processes @>
procnum=0
@< init processescounter @>
for ((i=1 ; i<=$maxprocs ; i++))
do
  ( procnum=$i
    @< increment the processes-counter @>
    @< perform the processing loop @>
    @< decrement the processes-counter, kill if this was the only process @>
  )&
done
@< wait for working-processes @>
@| procnum @}




\subsection{Perform the processing loop}
\label{sec:procloop}


In a loop, the process obtains the path to  an input \NAF{} and
processes it.  

@d perform the processing loop @{@%
while
   getfile
   [ ! -z $infile ]
do
@%        @< process 1 invokes runit @>
   @< add timelog entry @(Start $infile@) @>
   @< process infile @>
   @< add timelog entry @(Finished $infile with result: $pipelineresult@) @>

done
@| @}


\section{Apply the pipeline}
\label{sec:pipeline}

This section finally deals with the essential purpose of this
software: to annotate a document with the modules of the pipeline.

The pipeline is installed in directory \verb|m4_pipelineroot|. For
each of the modules there is a script in subdirectory \verb|bin|.

@d parameters @{@%
export pipelineroot=m4_pipelineroot
export BIND=$pipelineroot/bin
@| @}




\subsection{Spotlight server}
\label{sec:spotlightserver}

Some of the pipeline modules need to consult a \emph{Spotlight server}
that provides information from DBPedia about named entities. If it is
possible, use an external server, otherwise start a server on the host
of the job. We need two Spotlight servers, one for English and the
other for Dutch. We expect that we can find spotlight servers on host
\verb|m4_spotlighthost|, port m4_spotlight_nl_port for Dutch and
m4_spotlight_en_port for English. If it turns out that we cannot
access these servers, we have to build Spotlightserver on the local
host.

@% @d check/start spotlight @{@%
@% spothost_nl=check_start_spotlight "nl"
@% spothost_en=check_start_spotlight "en"
@% @| @}



@d functions in the jobfile @{@%
function check_start_spotlight {
  language=$1
  if
    [ language == "nl" ]
  then
    spotport=m4_spotlight_nl_port
  else
    spotport=m4_spotlight_en_port
  fi
  spotlighthost=m4_spotlighthost
  @< check spotlight on@($spotlighthost@,$spotport@) @>
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
@| @}


@d functions in the jobfile @{@%
function start_spotlight_on_localhost {
   language=$1
   port=$2
   spotlightdirectory=m4_spotlight_directory
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
@| @}

@d check spotlight on @{@%
exec 6<>/dev/tcp/@1/@2
spotlightrunning=$?
exec 6<&-
exec 6>&-
@| @}

\subsection{Language of the document}
\label{sec:language}

Our pipeline is currently bi-lingual. Only documents in Dutch or
English can be annotated. The language is specified as argument in the
\verb|NAF| tag. The pipeline installation contains a Python script that
returns the language of the document in the \NAF{}. Put the language
in variable \verb|naflang|.

Select the model that the Nerc module has to use, dependent of the language.

@d retrieve the language of the document  @{@%
naflang=`cat @1 | python m4_pipelineroot/env/bin/langdetect.py`
export naflang
#
@< set nercmodel @>
@| naflang @}

By the way, the python script uses Python 2.7, so let us import the
corresponding module.

@d load python module @{@%
module load python/2.7.9
@| @}

@d set nercmodel @{@%
if
  [ "$naflang" == "nl" ]
then
  export nercmodel=nl/nl-clusters-conll02.bin
else
  export nercmodel=en/en-newsreader-clusters-3-class-muc7-conll03-ontonotes-4.0.bin
fi
@| nercmodel @}



\subsection{Apply a module on a NAF file}
\label{sec:apply_module}

For each NLP module, there is a script in the \verb|bin| subdirectory
of the pipeline-installation. This script reads a \NAF{} file from
standard in and produces annotated \NAF{}-encoded document on standard
out, if all goes well. The exit-code of the module-script can be used
as indication of the success of the annotation.

To prevent that modules are applied on the result of a failed
annotation by a previous module, the exit code will be stored in
variable \verb|moduleresult|. 

The following function applies a module on the input naf file, but
only if variable \verb|moduleresult| is equal to zero. If the
annotation fails, the function writes a fail message to standard error
and it sets variable \verb|failmodule| to the name of the module that
failed. In this way the modules can easily be concatenated to annotate
the input document and to stop processing with a clear message when a
module goes wrong. The module's output of standard error is concatenated to the
logfile that belongs to the input-file. The function has the following arguments:

\begin{enumerate}
\item Path of the input \NAF{}.
\item Module script.
\item Path of the output \NAF{}.
\end{enumerate}


@d functions in the pipeline-file @{@%
function runmodule {
infile=\$1
modulecommand=\$2
outfile=\$3
@% logfile=\$4
if
  [ $moduleresult -eq 0 ]
then
  cat $infile | $modulecommand > $outfile 2>>$logfile
  moduleresult=$?
  if
    [ $moduleresult -gt 0 ]
  then
    failmodule=$modulecommand
@%     echo Failed: process $procnum";" file $infilefullname";" module $modulecommand";" result $moduleresult >&2
     echo Failed: module $modulecommand";" result $moduleresult >>$logfile
     echo Failed: module $modulecommand";" result $moduleresult >&2
     echo Failed: module $modulecommand";" result $moduleresult
     cp $outfile out.naf
     exit $moduleresult
  else
     echo Completed: module $modulecommand";" result $moduleresult >>$logfile
     echo Completed: module $modulecommand";" result $moduleresult >&2
     echo Completed: module $modulecommand";" result $moduleresult
  fi
fi  
}

export runmodule
@| @}

Initialise \verb|moduleresult| with value 0:

@d functions in the pipeline-file @{@%
export moduleresult=0
@|moduleresult @}




\subsection{Perform the annotation on an input NAF}
\label{sec:perform}

When a process has obtained the name of a \NAF{} file to be processed
and has generated filenames for the input-, proc-, log-, fail- and
output files (section~\ref{sec:generatefilenames}, it can start
process the file:

@d process infile @{@%
movetotray $infile $intray $proctray
mkdir -p $outpath
mkdir -p $logpath
export TEMPDIR=`mktemp -d -t nlpp.XXXXXX`
cd $TEMPDIR
@< retrieve the language of the document @($procfile@) @>
moduleresult=0
timeout m4_timeoutsecs $root/apply_pipeline
pipelineresult=$?
@< move the processed naf around @>
cd $root
rm -rf $TEMPDIR
@| pipelineresult timeout @}

We need to set a time-out on processing, otherwise documents that take
too much time keep being recycled between the intray and the
proctray. The bash timeout function executes the instruction that is
given as argument in a subshell. Therefore, execute processing in a
separate script. The subshell knows the exported parameters in the
environment from which the timeout instruction has been executed.

@o m4_projroot/apply_pipeline @{@%
#!/bin/bash
@< functions in the pipeline-file @>

cd $TEMPDIR
if
  [ "$naflang" == "nl" ]
then
   apply_dutch_pipeline
else
   apply_english_pipeline
fi
@| @}

@d make scripts executable @{@%
chmod 775 m4_aprojroot/apply_pipeline
@| @}


@% @d apply the modules for Dutch @{@%
@d functions in the pipeline-file @{@%
function apply_dutch_pipeline {
  runmodule $procfile   $BIND/tok                 tok.naf
  runmodule tok.naf     $BIND/mor                 mor.naf
  runmodule mor.naf     $BIND/nerc                nerc.naf
  runmodule nerc.naf    $BIND/wsd                 wsd.naf
  runmodule wsd.naf     $BIND/ned                 ned.naf
  runmodule ned.naf     $BIND/heideltime          times.naf
  runmodule times.naf   $BIND/onto                onto.naf
  runmodule onto.naf    $BIND/srl                 srl.naf
  runmodule srl.naf     $BIND/nomevent            nomev.naf
  runmodule nomev.naf   $BIND/srl-dutch-nominals  psrl.naf
  runmodule psrl.naf    $BIND/framesrl            fsrl.naf
  runmodule fsrl.naf    $BIND/opinimin            opin.naf
  runmodule opin.naf    $BIND/evcoref             out.naf
}

export apply_dutch_pipeline

@| @}


@% @d apply the modules for English @{@%
@d functions in the pipeline-file @{@%
function apply_english_pipeline {
  runmodule $procfile    $BIND/tok               tok.naf
  runmodule tok.naf      $BIND/topic             top.naf
  runmodule top.naf      $BIND/pos               pos.naf
  runmodule pos.naf      $BIND/constpars         consp.naf
  runmodule consp.naf    $BIND/nerc              nerc.naf
  runmodule nerc.naf     $BIND/coreference-base  coref.naf
  runmodule coref.naf    $BIND/ned               ned.naf
  runmodule ned.naf      $BIND/nedrer            nedr.naf
  runmodule nedr.naf     $BIND/wikify            wikif.naf
  runmodule wikif.naf    $BIND/ukb               ukb.naf
  runmodule ukb.naf      $BIND/ewsd              ewsd.naf
  runmodule ewsd.naf     $BIND/eSRL              esrl.naf
  runmodule esrl.naf     $BIND/FBK-time          time.naf
  runmodule time.naf     $BIND/FBK-temprel       trel.naf
  runmodule trel.naf     $BIND/FBK-causalrel     crel.naf
  runmodule crel.naf     $BIND/evcoref           ecrf.naf
  runmodule ecrf.naf     $BIND/factuality        fact.naf
  runmodule fact.naf     $BIND/opinimin          out.naf
}

export apply_english_pipeline

@| @}

When processing is ready, the \NAF's involved must be placed in the
correct location. When processing has been successful, the produced
\NAF{}, i.e. \verb|out.naf|, must be moved to the outtray and the file
in the proctray must be removed. Otherwise, the file in the proctray
must be moved to the failtray. Finally, remove the filename from the
stopos pool

@d move the processed naf around @{@%
if
 [ $pipelineresult -eq 0 ]
then
  mkdir -p \$outpath
  mv out.naf \$outfile
  rm \$procfile
else
  movetotray \$procfile \$proctray \$failtray
fi  
@< remove the infile from the stopos pool @>
@| @}



@% The raw \NAF{}'s will be processed with the Newsreader
@% Pipeline. This has been installed on the account \texttt{phuijgen} on
@% Lisa. The installation has been performed using the Github repository
@% \href{https://github.com/PaulHuygen/nlpp}.
@% 
@% @d directories of the pipeline @{@%
@% export piperoot=m4_piperoot
@% export pipebindir=m4_piperoot/bin
@% @| @}
@% 
@% The following script processes a raw \NAF{} from standard in and
@% produces the result on standard out.:
@% 
@% @o m4_projroot/nlpp @{@%
@% #!/bin/bash
@% source m4_aprojroot/parameters
@% @< directories of the pipeline @>
@% @< set utf-8 @>
@% @< check/start the Spotlight server @>
@% 
@% OLDD=`pwd`
@% TEMPDIR=`mktemp -t -d ontemp.XXXXXX`
@% cd $TEMPDIR
@% cat            | $pipebindir/tok           > tok.naf
@% cat tok.naf    | $pipebindir/mor           > mor.naf
@% cat mor.naf    | $pipebindir/nerc_conll02  > nerc.naf
@% cat nerc.naf   | $pipebindir/wsd           > wsd.naf
@% cat wsd.naf    | $pipebindir/ned           > ned.naf
@% cat ned.naf    | $pipebindir/heideltime    > times.naf
@% cat times.naf  | $pipebindir/onto          > onto.naf
@% cat onto.naf   | $pipebindir/srl           > srl.naf
@% cat srl.naf    | $pipebindir/evcoref       > ecrf.naf
@% cat ecrf.naf   | $pipebindir/framesrl      > fsrl.naf
@% cat fsrl.naf   | $pipebindir/dbpner        > dbpner.naf
@% cat dbpner.naf | $pipebindir/nomevent      > nomev.naf
@% cat nomev.naf  | $pipebindir/postsrl       > psrl.naf
@% cat psrl.naf   | $pipebindir/opinimin     
@% rm -rf $TEMPDIR 
@% @| @}
@% 
@% @d make scripts executable @{@%
@% chmod 775 m4_aprojroot/pipenl
@% @| @}
@% 
@% Let us start a pipeline with more facilities.
@% 
@% \begin{itemize}
@% \item Create a log file that accepts the log info
@% \end{itemize}
@% 
@% @o m4_projroot/newpipenl @{@%
@% #!/bin/bash
@% source m4_aprojroot/parameters
@% @< directories of the pipeline @>
@% @< set utf-8 @>
@% OLDD=`pwd`
@% TEMPDIR=`mktemp -t -d ontemp.XXXXXX`
@% cd $TEMPDIR
@% echo `date +%s`: tok: >&2  
@% cat | $pipebindir/tok >tok.naf
@% @< nextmodule @(tok@,mor@,mor@) @>
@% @< nextmodule @(mor@,nerc_conll02@,nerc@) @>
@% @< nextmodule @(nerc@,wsd@,wsd@) @>
@% @< nextmodule @(wsd@,ned@,ned@) @>
@% @< nextmodule @(ned@,heideltime@,times@) @>
@% @< nextmodule @(times@,onto@,onto@) @>
@% @< nextmodule @(onto@,srl@,srl@) @>
@% @< nextmodule @(srl@,evcoref@,ecrf@) @>
@% @< nextmodule @(ecrf@,framesrl@,fsrl@) @>
@% @< nextmodule @(fsrl@,dbpner@,dbpner@) @>
@% @< nextmodule @(dbpner@,nomevent@,nomev@) @>
@% @< nextmodule @(nomev@,postsrl@,psrl@) @>
@% @< nextmodule @(psrl@,opinimin@,opinimin@) @>
@% cat opinimin.naf
@% @% echo Tokenizer: >&2
@% @% cat            | $pipebindir/tok           > tok.naf
@% @% echo : Morpho-syntactic parser >&2
@% @% cat tok.naf    | $pipebindir/mor           > mor.naf
@% @% echo Nerc (conll02): >&2
@% @% cat mor.naf    | $pipebindir/nerc_conll02  > nerc.naf
@% @% echo WSD: >&2
@% @% cat nerc.naf   | $pipebindir/wsd           > wsd.naf
@% @% echo NED: >&2
@% @% cat wsd.naf    | $pipebindir/ned           > ned.naf
@% @% echo Heideltime: >&2
@% @% cat ned.naf    | $pipebindir/heideltime    > times.naf
@% @% echo Onot-tagger: >&2
@% @% cat times.naf  | $pipebindir/onto          > onto.naf
@% @% echo SRL: >&2
@% @% cat onto.naf   | $pipebindir/srl           > srl.naf
@% @% echo Event Coreferencing: >&2
@% @% cat srl.naf    | $pipebindir/evcoref       > ecrf.naf
@% @% echo Frame SRL: >&2
@% @% cat ecrf.naf   | $pipebindir/framesrl      > fsrl.naf
@% @% echo DBPedia NER: >&2
@% @% cat fsrl.naf   | $pipebindir/dbpner        > dbpner.naf
@% @% echo Nominal Event coref.: >&2
@% @% cat dbpner.naf | $pipebindir/nomevent      > nomev.naf
@% @% echo Post SRL: >&2
@% @% cat nomev.naf  | $pipebindir/postsrl       > psrl.naf
@% @% echo Opinion miner: >&2
@% @% cat psrl.naf   | $pipebindir/opinimin     
@% cd $OLDD
@% rm -rf $TEMPDIR 
@% exit
@% @| @}
@% 
@% @d make scripts executable @{@%
@% chmod 775 m4_aprojroot/newpipenl
@% @| @}


@%  1: Name infile
@%  2: Name module
@%  3: Name outfile

@% If a module has been passed, proceed with the next module unless
@% previous module failed. The follosing macro, \verb|nextmodule|, tests
@% whether the last module has been successfull. If so, it writes a
@% header to standard error (the logfile) and starts up next
@% module. Otherwise, it exits the pipeline script with an error code.
@% 
@% @d nextmodule @{@%
@% err=$?
@% if
@%   [ $err -gt 0 ]
@% then
@%   cd $OLDD
@%   rm -rf $TEMPDIR
@%   exit $err
@% fi
@% echo `date +%s`: @2: >&2  
@% cat @1.naf | $pipebindir/@2 >@3.naf 
@% @| @}


It is important that the computer uses utf-8 character-encoding.

@d set utf-8 @{@%
export LANG=en_US.utf8
export LANGUAGE=en_US.utf8
export LC_ALL=en_US.utf8
@| @}


@% Actually, we do not yet handle failed files separately. 
@% And, more actually, we secretly use another script that \verb|m4_pipelinescript| from this document.


@% @d process infile @{@%
@% @% cat $procfile | timeout m4_timeoutsecs m4_aprojroot/newpipenl 2>$logfile  >$outfile
@% cat $procfile | timeout m4_timeoutsecs m4_pipelinescript 2>$logfile  >$outfile
@% exitstat=$?
@% if
@%   [ $exitstat -gt 0 ]
@% then
@%   if
@%     [ $exitstat == m4_timeouterr ]
@%   then
@%     echo `date +%s`: Time-out >>$logfile
@%   fi
@%   movetotray $procfile $proctray $failtray
@%   rm -f $outfile
@% else
@% rm $procfile
@% fi
@% stopos -p $stopospool remove
@% @| @}
@% 
@% Select a proper spotlighthost:
@% 
@% @d parameters @{@%
@% export spotlighthost=m4_spotlighthost
@% @| spotlighthost @}


\subsection{The jobfile template}
\label{sec:jobfiletemplate}

Now we know what the job has to do, we can generate the script. It
executes the functions \verb|passeer| and \verb|veilig| to ensure that
the management script is not  

@o m4_projroot/m4_jobname.m4 @{@%
m4_<!!>changecom()m4_dnl
#!/bin/bash
#PBS -lnodes=1
<!#!>PBS -lwalltime=m4_<!!>walltime
source m4_aprojroot/parameters
piddir=`mktemp -d -t piddir.XXXXXXX`
( $BIND/start_eSRL $piddir )&
export jobname=$PBS_JOBID
@< log that the job starts @>
@< set utf-8 @>
@% @< initialize sematree @>
@% passeer
@% veilig
@< load stopos module @>
@< load python module @>
@< functions @>
@< functions in the jobfile @>
check_start_spotlight nl
check_start_spotlight en
echo spotlighthost: $spotlighthost >&2
echo spotlighthost: $spotlighthost
@% @< function getfile @>
starttime=`date +%s`
@< run parallel processes @>
@< log that the job finishes @>
exit

@| @}



\subsection{Synchronisation mechanism}
\label{sec:synchronisation}

Make a mechanism that ensures that only a single process can execute
some functions at a time. Currently we only use this to make sure that
only one instance of the management script runs. This is necessary
because loading Stopos with a huge amount of filenames takes a lot of
time and we don not want that a new instance of the management script
interferes with this.

The script \verb|sematree|, obtained from
\url{http://www.pixelbeat.org/scripts/sematree/} allows this kind of
``mutex'' locking. Inside information learns that sematree is
available on Lisa (in \verb|m4_sematree_script_location|). To lock
access Sematree places a file in a \emph{lockdir}. The directory where
the lockdir resides must be accessable for the management script as
well as for the jobs. Its name must be present in variable
\verb|workdir|, that must be exported.

@d initialize sematree @{@%
export workdir=m4_aworkdir
mkdir -p $workdir
@| @}

Now we can implement functions \verb|passeer| (gain exclusive access)
and \verb|veilig| (give up access).


@d functions @{@%
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

@| passeer veilig @}

Occasionally a process applies the \verb|passeer| function, but is
aborted before it could apply the \verb|veilig| function.  

@d functions @{@%

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
@| @}


\subsubsection{Count processes in jobs}
\label{sec:processescounter}

When a job runs, it start up independent sub-processes that do the
work and it may start up servers that perform specific tasks (e.g. a
Spotlight server). We want the job to shut down when there is nothing
to be done. The ``wait'' instruction of Bash does not help us, because
that instruction waits for the servers that will not stop. Instead we
make a construction that counts the number of processes that do the
work and activates the exit instruction when there are no more
left. We use the capacity of sematree to increment and decrement
counters. The process that decrements the counter to zero releases a
lock that frees the main process. The working directory of sematree
must be local on the node that hosts the job.

@d init processescounter @{@%
export workdir=`mktemp -d -t workdir.XXXXXX`
sematree acquire finishlock
@| workdir finishlock @}


@d increment the processes-counter @{@%
sematree acquire countlock
proccount=`sematree inc countlock`
sematree release countlock
@| countlock @}

@d decrement the processes-counter, kill if this was the only process @{@%
sematree acquire countlock
proccount=`sematree dec countlock`
sematree release countlock
echo "Process $proccunt stops." >&2
if
  [ $proccount -eq 0 ]
then
  sematree release finishlock
fi
@| @}

@d wait for working-processes @{@%
sematree acquire finishlock
sematree release finishlock
echo "No working processes left. Exiting." >&2
@| @}
 




@% The processes that execute these functions can crash and they are
@% killed when the time alotted to them has been used up. Thus it
@% is possible that a process that executed \verb|passeer| is not able to
@% execute \verb|veilig|. As a result, all other processes would come to a
@% halt. Therefore, check the age of the lock directory periodically and
@% remove the directory when it is older than, say, an hour.
@% 
@% @d remove old lockdir  @{@%
@% @%export LOCKDIR=m4_lockdir
@% find \$workdir/m4_lockfile -amin m4_locktimeout -print 2>/dev/null | xargs rm -rf
@% @| @}
@% 
@% @% The synchronisation mechanism can be used to have parallel processes
@% @% update the same counter. 
@% @% 
@% @% @d increment filecontent @{@%
@% @% passeer
@% @% NUM=`cat @1`
@% @% echo \$((NUM + 1 )) > @1
@% @% veilig
@% @% @| @}
@% @% 
@% @% @d decrement filecontent @{@%
@% @% passeer
@% @% NUM=`cat @1`
@% @% echo \$((NUM - 1 )) > @1
@% @% veilig
@% @% @| @}
@% 
@% We use the synchronisation as follows: when a management script
@% starts, it looks whether jobs are running. If that is not the case it
@% updates Stopos in a critical section (between commands \verb|passeer|
@% en \verb|veilig|). If jobs start, they begin to axecute \verb|passeer|
@% and \verb|veilig|, so they can only go on when not a management
@% script is updating Stopos. Theoretically, this can go wrong when a job
@% starts and passes its critical sectiion  between the moment that the
@% management script counts the jobs and starts the critical
@% section. However, starting jobs takes a lot of time, so I assume that
@% this will not happen frequently.
@% 
@% 
@% 
@% We will need a mechanism to find out whether a certain operation has
@% taken place within a certain past time period. We use the timestamp of
@% a file for that. When the operation to be monitored is executed, the
@% file is touched. The following macro checks such a file. It has the
@% following three arguments: 1) filename; 2) time-out period; 3)
@% result. The result parameter will become true when the file didn't
@% exist or when it had not been touched during the time-out period. In
@% those cases the macro touches the file.
@% 
@% @d check whether update is necessary  @{@%
@% @< write log @(now: `date +%s`@) @>
@% arg=@1
@% stamp=`date -r @1 +%s`
@% @< write log @($arg: $stamp@) @>
@% passeer
@% if [ ! -e @1 ]
@% then
@%   @3=true
@% elif [ \$((`date +%s` - `date -r @1 +%s`)) -gt @2 ]
@% then
@%   @3=true
@% else
@%   @3=false
@% fi
@% if \$@3
@% then
@%   echo `date` > @1
@% fi
@% veilig
@% if \$@3
@% then
@%   @< write log @(yes, update@) @>
@% else
@%   @< write log @(no, no update@) @>
@% fi
@% @| @}
@% 





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
@%     FAILFILE=$FAILTRAY/${FILTRUNK}@%     OUTPATH=${OUTFILE%/*}
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


\subsection{The job management script}
\label{sec:jobtrack}


@% \subsubsection{Keep it going}
@% \label{sec:koopgoing}
@% 
@% The script \verb|runit| performs job management. Therefore, this
@% script must be started at regular intervals. We cannot install
@% cron-jobs on Lisa to do this. Therefore, it would be a good idea to to
@% have jobs starting runit now and
@% then. I tried to do that over ssh, but it did not succeed (timed out). 
@% 
@% @% @d parameters @{@%
@% @% export runit_deadtime=m4_runit_deadtime
@% @% @| runit_deadtime @}
@% @% 
@% @% @d set runit timestamp @{@%
@% @% echo `date +%s` >m4_runittimefile
@% @% @| @}
@% @% 
@% @% @d invoke the runit script @{@%
@% @% startrunit=0
@% @% if
@% @%   [ -e "m4_runittimefile" ] 
@% @% then
@% @%   lasttime=`cat m4_runittimefile`
@% @%   now=`date +%s`
@% @%   elapsed_seconds=$((now - $lasttime))
@% @%   min_seconds=$((runit_deadtime * 60))
@% @%   if
@% @%     [ $elapsed_seconds -le $min_seconds ]
@% @%   then
@% @%     startrunit=1
@% @%   fi
@% @% fi
@% @% if
@% @%   [ $startrunit -eq 0 ]
@% @% then
@% @%   @< set runit timestamp @>
@% @%   ssh -o PubkeyAuthentication=yes $USER@@m4_lisahost "nohup m4_aprojroot/runit &"
@% @% fi
@% @% @| @}
@% 
@% 
@% 
@% @% When we have received files to be parsed we have to submit the proper
@% @% amount of jobs. To determine whether new jobs have to be
@% @% submitted we have to know the number of waiting and running
@% @% jobs. Unfortunately it is too costly to often request a list of
@% @% running jobs. Therefore we will make a bookkeeping. File
@% @% \verb|m4_jobcountfile| contains a list of the running and waiting
@% @% jobs.
@% @% 
@% @% @d parameters @{@%
@% @% JOBCOUNTFILE=m4_jobcountfile
@% @% @| JOBCOUNTFILE @}
@% @% 
@% @% 
@% @% It is updated as follows:
@% @% 
@% @% \begin{itemize}
@% @% \item When a job is submitted, a line containing the job-id, the word
@% @%   ``wait'' and a timestamp is added to the file.
@% @% \item A job that starts, replaces in the line with its job-id the word
@% @%   ``waiting'' by running and replaces the timestamp.
@% @% \item A job that ends regularly, removes the line with its job-id.
@% @% \item A job that ends leaves a log message. The filename consists of a 
@% @%   concatenation of the jobname, a dot, the character ``o'' and the
@% @%   job-id. At a regular basis the existence of such files is checked
@% @%   and \verb|\$JOBCOUNTFILE| updated. 
@% @% \end{itemize}
@% @% 
@% @% 
@% @% Submit a job and write a line in the jobcountfile. The line consists
@% @% of the jobnumber, the word ``wait'' and the timestamp in universal seconds.
@% @% 
@% @% @d submit a job @{@%
@% @% @% passeer
@% @% qsub m4_aprojroot/m4_jobname | \
@% @%  gawk -F"." -v tst=`date +%s`  '{print $1 " wait " tst}' \
@% @%  >> \$JOBCOUNTFILE
@% @% @< write log @(Updated jobcountfile@) @>
@% @% @% veilig
@% @% @| @}
@% @% 
@% @% When a job starts, it performs some bookkeeping. It finds out its own job number and changes \verb|wait| into \verb|run|  in the bookeepfile.
@% @% 
@% @% @d perform jobfile-bookkeeping @{@%
@% @% @< find out the job number @>
@% @% prognam=m4_jobname$JOBNUM
@% @% @< write log @(start@) @>
@% @% @< change ``wait'' to ``run'' in jobcountfile @>
@% @% @| @}
@% @% 
@% @% The job \textsc{id} begins with the number,
@% @% e.g. \verb|6670732.batch1.irc.sara.nl|. 
@% @% 
@% @% @d find out the job number @{@%
@% @% JOBNUM=\${PBS_JOBID%%.*}
@% @% @| @}
@% @% 
@% @% @d change ``wait'' to ``run'' in jobcountfile @{@%
@% @% @%stmp=`date +%s`
@% @% if [ -e \$JOBCOUNTFILE ]
@% @% then
@% @%   passeer
@% @%   mv \$JOBCOUNTFILE \$tmpfil
@% @%   gawk -v jid=\$JOBNUM -v stmp=`date +%s` \
@% @%     '@< awk script to change status of job in joblist @>' \
@% @%     \$tmpfil >\$JOBCOUNTFILE
@% @%   veilig
@% @%   rm -rf \$tmpfil
@% @% fi
@% @% @| @}
@% @% 
@% @% @d awk script to change status of job in joblist @{@%
@% @% BEGIN {WRIT="N"};
@% @% { if(match(\$0,"^"jid)>0) {
@% @%      print jid " run  " stmp;
@% @%      WRIT="Y";
@% @%   } else {print}
@% @% };
@% @% END {
@% @%   if(WRIT=="N") print jid " run  " stmp;
@% @% }@%
@% @% @| @}
@% @% 
@% @% 
@% @% 
@% @% When a job ends, it removes the line:
@% @% 
@% @% @d remove the job from the counter @{@%
@% @% passeer
@% @% mv \$JOBCOUNTFILE \$tmpfil
@% @% gawk -v jid=\$JOBNUM  '\$1 !~ "^"jid {print}' \$tmpfil >\$JOBCOUNTFILE
@% @% veilig
@% @% rm -rf \$tmpfil
@% @% @| @}
@% @% 
@% @% Periodically check whether jobs have been killed before completion and
@% @% have thus not been able to remove their line in the jobcountfile. To
@% @% do this, write the jobnumbers in a temporary file and then check the
@% @% jobcounter file in one blow, to prevent frequent locks.
@% @% 
@% @% 
@% @% @d do brief check of expired jobs @{@%
@% @% obsfil=`mktemp --tmpdir obs.XXXXXXX`
@% @% rm -rf \$obsfil
@% @% @< make a list of jobs that produced logfiles @(\$obsfil@) @>
@% @% @< compare the logfile list with the jobcounter list @(\$obsfil@) @>
@% @% rm -rf \$obsfil
@% @% @| @}
@% @% 
@% @% @d do the frequent tasks @{@%
@% @% @< do brief check of expired jobs @>
@% @% @| @}
@% @% 
@% @% @%@d do thorough check of expired jobs @{@%
@% @% @%@< check whether update is necessary @(\$thoroughjobcheckfil@,180@,thoroughjobcheck@) @>
@% @% @%if \$thoroughjobcheck
@% @% @%then
@% @% @%@% @< skip brief jobcheck @>
@% @% @% @< verify jobs-bookkeeping @>
@% @% @%fi
@% @% @%@| @}
@% 
@% 
@% 
@% 
@% When a job has ended, a logfile, and sometimes an error-file, is
@% produced. The name of the logfile is a concatenation of the jobname, a
@% dot, the character \verb|o| and the jobnumber. The error-file has a
@% similar name, but the character \verb|o| is replaced by
@% \verb|e|. Generate a sorted list of the jobnumbers and
@% remove the logfiles and error-files:
@% 
@% @d make a list of jobs that produced logfiles @{@%
@% for file in m4_jobname.o*
@% do
@%   JOBNUM=\${file<!##!>m4_jobname.o}
@%   echo \${file<!##!>m4_jobname.o} >>\$tmpfil
@%   rm -rf m4_jobname.[eo]\$JOBNUM
@% done
@% sort < \$tmpfil >@1
@% rm -rf \$tmpfil
@% @| @}
@% 
@% Remove the jobs in the list from the counter file if they occur there.
@% 
@% @d compare the logfile list with the jobcounter list @{@%
@% if [ -e \$JOBCOUNTFILE ]
@% then
@%   passeer
@%   sort < \$JOBCOUNTFILE >\$tmpfil
@%   gawk -v obsfil=@1 ' 
@%     BEGIN {getline obs < obsfil}
@%     { while((obs<\$1) && ((getline obs < obsfil) >0)){}
@%       if(obs==\$1) next;
@%       print
@%     }
@%   ' \$tmpfil >\$JOBCOUNTFILE
@%   veilig
@% fi
@% rm -rf \$tmpfil
@% @| @}
@% 
@% From time to time, check whether the jobs-bookkeeping is still
@% correct.
@% To this end, request a list of jobs from the operating
@% system. 
@% 
@% @d verify jobs-bookkeeping @{@%
@% actjobs=`mktemp --tmpdir act.XXXXXX`
@% rm -rf \$actjobs
@% qstat -u  phuijgen | grep m4_jobname | gawk -F"." '{print \$1}' \
@%  | sort  >\$actjobs
@% @< compare the active-jobs list with the jobcounter list @(\$actjobs@) @>
@% rm -rf \$actjobs
@% @| @}
@% 
@% @d do the now-and-then tasks @{@%
@% @< verify jobs-bookkeeping @>
@% @| @}
@% 
@% 
@% @d compare the active-jobs list with the jobcounter list @{@%
@% if [ -e \$JOBCOUNTFILE ]
@% then
@%   passeer
@%   sort < \$JOBCOUNTFILE >\$tmpfil
@%   gawk -v actfil=@1 -v stmp=`date +%s` ' 
@%     @< awk script to compare the active-jobs list with the jobcounter list @>
@%   ' \$tmpfil >\$JOBCOUNTFILE
@%   veilig
@%   rm -rf \$tmpfil
@% else
@%   cp @1 \$JOBCOUNTFILE
@% fi
@% @| @}
@% 
@% Copy lines from the logcount file if the jobnumber matches a line in
@% the list actual jobs. Write entries for jobnumbers that occur only in
@% the actual job list.
@% 
@% @d awk script to compare the active-jobs list with the jobcounter list @{@%
@% BEGIN {actlin=(getline act < actfil)}
@% { while(actlin>0 && (act<\$1)){ 
@%      print act " wait " stmp;
@%      actlin=(getline act < actfil);
@%   };
@%   if((actlin>0) && act==\$1 ){
@%      print
@%      actlin=(getline act < actfil);
@%   }
@% }
@% END {
@%     while((actlin>0) && (act ~ /^[[:digit:]]+/)){
@%       print act " wait " stmp;
@%     actlin=(getline act < actfil);
@%  };
@% }
@% @| @}


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



@% @d derive number of jobs to be submitted  @{@%
@% REQJOBS=\$(( \$(( \$NRFILES / m4_filesperjob )) ))
@% if [ \$REQJOBS -gt m4_maxjobs ]
@% then
@%   REQJOBS=m4_maxjobs
@% fi
@% if [ \$NRFILES -gt 0 ]
@% then
@%   if [ \$REQJOBS -eq 0 ]
@%   then
@%     REQJOBS=1
@%   fi
@% fi
@% @1=\$(( \$REQJOBS - \$NRJOBS ))
@% 
@% @| @}




\subsection{The management script}
\label{sec:management-script}

@o m4_projroot/runit @{@%
#!/bin/bash
source /etc/profile
export PATH=/home/phuijgen/usrlocal/bin/:$PATH
source m4_aprojroot/parameters
cd $root
@< initialize sematree @>
@< get runit options @>
@< functions @>
remove_obsolete_lock runit_runs
@% @< remove old lockdir @(runit_runs@) @>
runsingle runit_runs
@% runsingle
@% @< init logfile @>
@< load stopos module @>
@< check/create directories @>
@% @< reset if nothing is to be done @>
@% @< remove old joblogs @>
@% @< get stopos status @>
@% @< do brief check of expired jobs @>
@< count jobs @>
@% if
@%   [ $running_jobs -eq 0 ]
@% then
@< update the stopos pool @>
@% fi
@< submit jobs when necessary @>
@% veilig
if
  [ $loud ]
then
  @< print summary @>
fi
veilig runit_runs
exit
@| @}

@d make scripts executable @{@%
chmod 775 m4_aprojroot/runit
@| @}

\subsection{Print a summary}
\label{sec:printsummary}

The \verb|runit| script prints a summary of the number of jobs and the
number of files in the trays unless a \verb|-s| (silent) option is
given. 

Use \href{http://mywiki.wooledge.org/BashFAQ/035#getopts}{getopts} to
unset the \verb|loud| flag if the \verb|-s| option is present.

@d get runit options @{@%
OPTIND=1
export loud=0
while getopts "s:" opt; do
    case "$opt" in
    s)  loud=
        ;;
    esac
done
shift $((OPTIND-1))
@| @}

Print the summary:

@d print summary @{@%
echo in         : $incount
echo proc       : $proccount
echo failed     : $failcount
echo processed  : $((logcount - $failcount))
echo jobs       : $jobcount
echo running    : $running_jobs
echo submitted  : $jobs_to_be_submitted
if
  [ ! "$jobid" == "" ]
then
  echo "job-id     : $jobid"
fi
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

% LocalWords:  Webcom stopos filenames proctray intray
