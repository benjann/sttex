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

---

Installation from GitHub:

    . net install sttex, replace from(https://raw.githubusercontent.com/benjann/sttex/main/)

---

Main changes:

    notes: - some of the log options listed under "main" in the help file are
             not implemented yet for code logs
           - use current version with care; still need to do some testing and
             bug fixing; database format may still change

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
