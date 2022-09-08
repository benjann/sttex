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

    08sep2022 (version 1.0.0)
    - minor change to how information on parts is managed
    
    08sep2022 (version 1.0.0)
    - released on GitHub
