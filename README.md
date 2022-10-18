# sttex
Stata module to integrate Stata results into a LaTeX document

`sttex` is a command to process a LaTeX source file containing blocks of Stata
code. `sttex` will extract the Stata commands into a do-file, run the
do-file, and then weave the LaTeX source and the Stata output into a target
LaTeX document. Optionally, `sttex` also typesets the LaTeX document and
displays the resulting PDF. Various tags can be used within the LaTeX source
file to define the information that will be processed by `sttex`.

A main feature of `sttex` is that it detects whether Stata code changed between
calls. If the code did not change, execution of Stata commands will be skipped
to save computer time. It is also possible to partition a source file into
independent sections, such that only the sections affected by changes will be
executed.

To install `sttex` from the SSC Archive, type

    . ssc install sttex, replace

in Stata. Stata version 11 or newer is required.

---

Installation from GitHub:

    . net from https://raw.githubusercontent.com/benjann/sttex/main/
    . net install sttex, replace

---

Main changes:

    18oct2022 (version 1.1.8)
    - if used on Windows, sttex failed to replace "\" by "/" in file paths written
      to the target LaTeX file; this is fixed

    17oct2022 (version 1.1.7)
    - new \stfile{} tag to collect files created by code; \stres{{file}} and 
      \stres{{fname}} added; fileopts() added to sttex, %STini, %STpart
    - if \stres{{logname}} was used to reference a log for which option -static- was
      specified, sttex failed to store the log in an external file; this is fixed
    - dbversion now 1.1.7; can still read version 1.1.6

    12oct2022 (version 1.1.6)
    - %STpart did not update the log options; this is fixed
    - option -certify- caused error; this is fixed
    - -certify- now looks at both the SMCL log as well as the log translated to plain
      text and only returns error if both are different; this implies that a change
      in linesize does not lead to certification error in most cases
    - log option -nolskip- added (restore empty lines in code log)
    - scale() option: \noindent and modification of \leftmargini now omitted if
      -beamer- is specified
    - scale() option: now writing simplified code if scale=1
    - typesetting options other than -typeset- and -view- no longer cause typesetting
    - extension vrb added to -cleanup-
    - now storing original SMCL log in database; translation to TeX is now done on
      the fly; dbversion now 1.1.6

    05oct2022 (version 1.1.5)
    - %STset implemented
    - log option -notexman- added
    - log options -nolb- and -nogt- now also applied to code logs
    - commands without output could confuse the log parser in some situations;
      this is fixed
    - db on disk will no longer be updated if only options change that are not
      relevant for determining whether elements need to be refreshed; realized size
      of -trim- no longer stored in db; dbversion now 1.1.5

    29sep2022 (version 1.1.4):
    - the log files of a part were not updated correctly if a part did not contain
      any changes but was evaluated due to dependencies; this is fixed;
      dbversion now 1.1.4
 
    29sep2022 (version 1.1.3):
    - tgtdir is now added on the fly to logdir, dodir, and graph dir when writing
      files (if necessary) rather than setting up the paths upfront; this affects
      the definition of objects in the database; dbversion now 1.1.2
    - if graph dir() changed, sttex now also looks in new location for existing
      graph files, not only the old location
    - code log was regenerated if raw results log of code block was not available
      (e.g. because option nodo was specified); code log is now only regenerated if
      there is a change in the code irrespective of whether a raw results log is
      available or not
    - scale() no longer adds a \par in front of the block
    - \blstretch() without scale() now encloses the log in \begingroup...\endgroup
      rather than {...}

    26sep2022 (version 1.1.2):
    - %STpart ignored -gropts()-; this is fixed

    26sep2022 (version 1.1.1):
    - \stlog{} can now obtain logs from multiple code blocks
    - log options tag(), alert(), and substitute() are now also applied to code logs
    - log option lcontinue added
    - range() is now applied before lnumbers and ltags()
    - lnumbers are now included in \stlnum{}
    - line numbers and line tags are now added at the very end, when exporting a log
    - now using errprintf() to display errors in Mata
    - added a fix for vertical spacing after (non-verbatim) code log
    - order of elements is now stored in the database; dbversion now 1.1.1
    - error message is now written to target file if log or graph is not found

    21sep2022 (version 1.1.0):
    - code blocks and logs are now treated as different elements in the internal
      accounting system, such that a code block can have multiple logs (e.g. a
      code log and a results log); \stlog{} and \stlog*{} added
    - syntax \do<keyword>{filename} added to create code block from file
    - log option range() added
    - log option ltag() added
    - log option lnumbers added
    - log option clsize() added
    - log option scale() added
    - log option substitute() added
    - log option blstretch() added
    - log option nooutput() renamed to qui()
    - log option verbatim now adds \begin{verbatim}...\end{verbatim} to log rather
      than using \verbatiminput{}, such that \usepackage{verbatim} is no longer
      needed
    - linsize(.) now selects default behavior
    - -trim- without argument now clears previous trim(#) setting
    - \stgraph{} can now be specified as \stgraph*{}; graph option -custom-
      discarded
    - \stgraph{} now only allowed if there is at least preceding code block in the
      current part
    - target id now allowed in \stres{{log}} and \stres{{graph}}
    - \stappend{} added
    - "//ST.." tags will now be removed from files saved by dosave() 
    - filename is now reported in error messages
    - mata error messages are now also displayed if -quietly- is applied
    - command -sttex extract- added
    - dodir() and graph dir(), if not specified, were not updated if logdir()
      changed along the way; this is fixed
    - version of database now 1.1.0; new database will be created (causing execution
      of all Stata commands) if sttex is applied to outdated database
    
    08sep2022 (version 1.0.0)
    - released on GitHub
