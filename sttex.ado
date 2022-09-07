*! version 1.0.0  07sep2022  Ben Jann

program sttex
    version 11
    local caller : di _caller()
    gettoken subcmd : 0
    if `"`subcmd'"'=="register" {
        gettoken subcmd 0 : 0   // strip register
        Register `macval(0)'
        exit
    }
    if `"`subcmd'"'=="extract" {
        gettoken subcmd 0 : 0   // strip extract
        Extract `macval(0)'
        exit
    }
    if `"`subcmd'"'=="using" {
        gettoken subcmd 0 : 0   // strip using
    }
    version `caller': Process `macval(0)'
end

program Register
    gettoken name 0 : 0
    if `"`name'"'!="tex" {
        di as err `"`name' not allowed"'
        exit 198
    }
    gettoken location 0 : 0
    if `"`0'"'!="" {
        di as err `"`0' not allowed"'
        exit 198
    }
    if `"`location'"'=="" { // delete settings
        capt findfile sttex_register_`name'.txt
        if _rc {
            di as txt `"(sttex_register_`name'.txt found)"'
            exit
        }
        erase `"`r(fn)'"'
        di as txt `"(`r(fn)' removed)"'
        exit
    }
    capt findfile sttex.ado
    if _rc {    // should never happen
        di as err "sttex.ado not found; cannot record settings"
        exit 499
    }
    mata: Get_Path(st_global("r(fn)"))
    mata: st_local("fn", pathjoin(st_local("path"), "sttex_register_`name'.txt"))
    tempname fh
    qui file open `fh' using `"`fn'"', write replace
    file write `fh' `"`location'"'
    file close `fh'
    di as txt `"(settings recorded in `fn')"'
end

program Extract
    di "to be implemented"
end

program Process, rclass
    local caller : di _caller()
    // syntax
    _parse comma args 0 : 0
    gettoken src args : args // source file
    mata: AddSuffixToSourcefile()
    confirm file `"`src'"'
    _collect_overall_options `0'
    _collect_typeset_options, `macval(options)'
    local options0 `macval(options)'
    local StartAtLine 1
    nobreak {
        capt n break mata: GetInitFromSourcefile()  // parse %STinit
        mata: CloseOpenFHsAndExit(`=_rc')
    }
    local options1 `macval(options)'
    local typeset `typeset' `typeset2' `view' `view2' `jobname' `cleanup' ///
        `nobibtex' `bibtex' `nomakeindex' `makeindex'
    mata: PrepareFilenames()
    // run main routine
    local pwd `"`c(pwd)'"'
    local cmore `"`c(more)'"'
    local crmsg `"`c(rmsg)'"'
    local clsize `"`c(linesize)'"'
    nobreak {
        if "`more'"=="" set more off
        else            set more on
        if "`rmsg'"=="" set rmsg off
        else            set rmsg on
        capt n break mata: Process()
        local rc = _rc
        capt log close `lognm'
        capt cd `pwd'
        capt set more `cmore'
        capt set rmsg `crmsg'
        capt set linesize `clsize'
        if `rc' set output proc  // make sure that output is on
        mata: CloseOpenFHsAndExit(`rc')
    }
    // returns
    _make_displaylink `"`tgt'"' // returns local link
    di as txt `"(target file saved as {`link':`tgt'})"'
    // typeset
    if `"`typeset'"'!="" {
        Typeset using `"`tgt'"', `typeset'
    }
    // returns
    if `"`dbfile'"'!="" {
        return scalar dbupdate = `"`dbupdate'"'!=""
    }
    return local pdf    `"`pdffile'"'
    return local db     `"`dbfile'"'
    return local target `"`tgt'"'
    return local source `"`src'"'
end

program _collect_overall_options
    _parse comma target 0 : 0
    local opts NOCD Replace NODB reset NOSTOP more rmsg
    syntax [, SAVing(str) DBname(str) `opts' * ]
    foreach o of local opts {
        local opt = strlower("`o'")
        if "``opt''"!="" c_local `opt' ``opt''
    }
    if `"`dbname'"'!="" c_local dbname `"`dbname'"'
    c_local options `macval(options)'
    if `"`target'"'!="" { // target before comma takes precedence over saving()
        local 0 `", saving(`target')"'
        syntax [, saving(str) ]
    }
    if `"`saving'"'!="" c_local saving `"`saving'"'
end

program _collect_typeset_options
    syntax [, TYPEset TYPEset2(passthru) VIEW VIEW2(passthru) ///
        jobname(passthru) CLEANup NOBIBTEX BIBTEX NOMAKEINDEX MAKEINDEX * ]
    if `"`typeset2'"'!="" local typeset typeset
    if `"`view2'"'!="" local view view
    if `"`view'"'!="" local typeset typeset
    if "`bibtex'"!="" & "`nobibtex'"!="" {
        di as err "bibtex and nobibtex not both allowed"
        exit 198
    }
    if "`makeindex'"!="" & "`nomakeindex'"!="" {
        di as err "makeindex and nomakeindex not both allowed"
        exit 198
    }
    foreach opt in typeset typeset2 view view2 jobname cleanup {
        if "``opt''"!="" c_local `opt' ``opt''
    }
    if "`nobibtex'`bibtex'"!=""       c_local bibtex `nobibtex' `bibtex'
    if "`nomakeindex'`makeindex'"!="" c_local makeindex `nomakeindex' `makeindex'
    c_local options `"`macval(options)'"'
end

program _collect_stlog_options
    local opts OUTput COMmands CODE VERBatim MATA QUIetly TRIM PRompt ///
            LB GT BEGIN END BEAMER STATic DOSave CERTify DO 
    foreach o of local opts {
        local noopts `noopts' NO`o'
    }
    syntax [, `noopts' `opts' ///
        drop(numlist int missingokay) ///
        oom(numlist int missingokay) ///
        NOOUTput2(numlist int missingokay) ///
        cnp(numlist int missingokay) ///
        TRIM2(numlist int max=1 >=0) ///
        BEGIN2(str asis) END2(str asis) ///
        LInesize(numlist int max=1 >=40 <=255) ////
        alert(str asis) tag(str asis) SUBStitute(str asis) ///
        logdir(passthru) ///
        dodir(passthru) ///
        GRopts(str asis) ]
    if `"`trim2'"'!=""  local trim  trim
    if `"`begin2'"'!="" local begin begin
    if `"`end2'"'!=""   local end   end
    foreach o of local opts {
        local opt = strlower("`o'")
        if "``opt''"!="" & "`no`opt''"!="" {
            di as err "`opt' and no`opt' not both allowed"
            exit 198
        }
        c_local `opt' `no`opt'' ``opt''
    }
    c_local drop         `drop'
    c_local oom          `oom'
    c_local nooutput2    `nooutput2'
    c_local cnp          `cnp'
    c_local trim2        `trim2'
    c_local begin2       `"`macval(begin2)'"'
    c_local end2         `"`macval(end2)'"'
    c_local linesize     `linesize'
    c_local alert        `"`macval(alert)'"'
    c_local tag          `"`macval(tag)'"'
    c_local substitute   `"`macval(substitute)'"'
    c_local options      `"`macval(gropts)'"'
    local 0 ","
    foreach o in logdir dodir {
        c_local has`o' `"``o''"'
        local 0 `"`0' ``o''"'
    }
    syntax [, logdir(str) dodir(str) ]
    c_local logdir       `"`logdir'"'
    c_local dodir        `"`dodir'"'
end

program _collect_graph_options
    local opts SUFfix EPSFIG CENTER CUSTom
    foreach o of local opts {
        local noopts `noopts' NO`o'
    }
    syntax [, `noopts' `opts' ///
        as(str) ///
        name(str) ///
        ARGs(passthru) ///
        OVERRide(passthru) ///
        dir(passthru) ]
    foreach o of local opts {
        local opt = strlower("`o'")
        if "``opt''"!="" & "`no`opt''"!="" {
            di as err "`opt' and no`opt' not both allowed"
            exit 198
        }
        c_local gr_`opt' `no`opt'' ``opt''
    }
    c_local gr_as   `as'
    c_local gr_name `name'
    local 0 ","
    foreach o in args override dir {
        c_local gr_has`o' `"``o''"'
        local 0 `"`0' ``o''"'
    }
    syntax [, args(str) override(str) dir(str) ]
    c_local gr_args     `"`args'"'
    c_local gr_override `"`override'"'
    c_local gr_dir      `"`dir'"'
end

program _make_displaylink
    args fn
    if c(os)=="Unix" {
        c_local link `"stata `"!xdg-open "`fn'" >& /dev/null &"'"'
    }
    else {
        c_local link `"browse `"`fn'"'"'
    }
end

program Typeset
    // syntax
    syntax using/ [, TYPEset TYPEset2(numlist int max=1 >=0) ///
        VIEW VIEW2(numlist int max=1 >=0) ///
        jobname(str) CLEANup NOBIBTEX BIBTEX NOMAKEINDEX MAKEINDEX ]
    // file names
    mata: st_local("basename", pathbasename(st_local("using")))
    mata: Get_Path(st_local("using"))
    if `"`basename'"'=="" {
        di as txt "(LaTeX document not found; nothing to typeset)"
        exit
    }
    if `"`jobname'"'!="" {
        local jobnmopt `"-jobname "`jobname'" "' 
    }
    else {
        mata: st_local("jobname", pathrmsuffix(st_local("basename")))
    }
    local pwd `"`c(pwd)'"'
    // - find path of tex installation
    capt findfile sttex_register_tex.txt
    if _rc==0 {
        tempname fh
        file open `fh' using `"`r(fn)'"', read
        file read `fh' texbin
        file close `fh'
    }
    if `"`texbin'"'=="" {
        di as err "location of TeX installation not registered;"
        di as err "apply {bf:sttex register tex} {it:path} to register TeX installation"
        exit 499
    }
    mata: st_local("pdflatex", pathjoin(st_local("texbin"), "pdflatex"))
    mata: st_local("Bibtex", pathjoin(st_local("texbin"), "bibtex"))
    mata: st_local("mkidx", pathjoin(st_local("texbin"), "makeindex"))
    capt confirm file `"`pdflatex'"'
    if _rc {
        di as err `"pdflatex not found in `texbin'"'
        exit 499
    }
    // - run pdflatex
    nobreak {
        if `"`path'"'!="" {
            qui cd `"`path'"'
        }
        capt n break {
            di as txt "(running pdflatex ...)"
            _typeset_pdflatex`"`pdflatex'"' `"`basename'"' ///
                `"`jobname'"' `"`jobnmopt'"'
            if `success' {
                if "`bibtex'`nobibtex'"=="" {
                    _typeset_checkbibtex `"`jobname'.aux"'
                    if "`bibtex'"!="" {
                        quietly shell "`Bibtex'" -terse "`jobname'"
                    }
                }
                if `"`typeset2'"'=="" local typeset2 `view2'
                if `"`typeset2'"'=="" {
                    if "`bibtex'"!="" local typeset2 2
                    else              local typeset2 1
                }
                forv i=1/`typeset2' {
                    if `i'==`typeset2' {    // run makeindex
                        if "`makeindex'`nomakeindex'"=="" {
                            capt confirm file `"`jobname'.idx"'
                            if _rc==0 local makeindex makeindex
                        }
                        if "`makeindex'"!="" {
                            quietly shell "`mkidx'" "`jobname'"
                        }
                    }
                    _typeset_pdflatex`"`pdflatex'"' `"`basename'"' ///
                        `"`jobname'"' `"`jobnmopt'"'
                    if `success'==0 continue, break
                }
            }
            capt erase `"`jobname'.idx"'
            if `success' & "`cleanup'"!="" {
                local exts log aux toc lof lot out nav snm blg bbl ilg ind
                foreach s of local exts {
                    capture erase `"`jobname'.`s'"'
                }
            }
        }
        local rc = _rc
        qui cd `pwd'
        if `rc' exit `rc'
    }
    // return messaged
    mata: st_local("jobname", pathjoin(st_local("path"), st_local("jobname")))
    if `success'==0 {
        capt confirm file `"`jobname'.log"'
        if _rc==0 {
            _make_displaylink `"`jobname'.log"' // returns local link
            di as err "pdflatex error: no output PDF file produced"
            di as err `"view log file for source of error: {`link':`jobname'.log}"'
        }
        else {
            di as err "pdflatex error; no output PDF file produced"
        }
        exit 499
    }
    _make_displaylink `"`jobname'.pdf"' // returns local link
    di as txt `"(PDF saved as {`link':`jobname'.pdf})"'
    // view PDF
    if "`view'"=="" exit
    if c(os)=="Unix" {
        shell xdg-open "`jobname'.pdf" >& /dev/null &
    }
    else if c(os)=="MacOSX" {
        shell open "`jobname'.pdf"
    }
    else if c(os)=="Windows" {
        shell start "`jobname'.pdf"
    }
    // push name of PDF to caller
    c_local pdffile `"`jobname'.pdf"'
end

program _typeset_pdflatex
    args pdflatex basename jobname jobnmopt
    local success 1
    quietly shell "`pdflatex'" `jobnmopt' "`basename'"
    capt confirm file `"`jobname'.pdf"'
    if _rc local success 0
    if `success' {
        capt confirm file `"`jobname'.log"'
        if _rc local success 0
    }
    if `success' {
        nobreak {
            capt n break mata: PDFlatex_success(`"`jobname'.log"')
            mata: CloseOpenFHsAndExit(`=_rc')
        }
    }
    c_local success `success'
end

program _typeset_checkbibtex
    args aux
    capt confirm file `"`aux'"'
    if _rc exit
    nobreak {
        capt n break mata: Checkbibtex(`"`aux'"')
        mata: CloseOpenFHsAndExit(`=_rc')
    }
    c_local bibtex `bibtex'
end

version 11

// Mata declarations
// - Boolean
local Bool      real scalar
local BoolR     real rowvector
local BoolC     real colvector
local BoolV     real vector
local TRUE      1
local FALSE     0
// - integers
local Int       real scalar
local IntR      real rowvector
local IntC      real colvector
local IntV      real vector
local IntM      real matrix
// - strings
local Str       string scalar
local StrR      string rowvector
local StrC      string colvector
local StrV      string vector
local StrM      string matrix
// - pointers
local pStr      pointer(`Str') scalar
local pStrC     pointer(`StrC') scalar
local pRIntM    pointer (`IntM') rowvector
// - environments
local TokEnv    transmorphic
local AsArray   transmorphic
// - main structure
local MAIN      MAIN
local Main      struct `MAIN' scalar
// - structure for files
local FILE      FILE
local File      struct `FILE' scalar
// - structure for input
local SOURCE    SOURCE
local Source    struct `SOURCE' scalar
// - structures containing tags
local TAG       TAG
local Tag       struct `TAG' scalar
local ITAG      ITAG
local Itag      struct `ITAG' scalar
local LTAG      LTAG
local Ltag      struct `LTAG' scalar
local TTAG      TTAG
local Ttag      struct `TTAG' scalar
// - structures for parts and inserts
local PARTS     PARTS
local Parts     struct `PARTS' scalar
// - structures for Stata blocks 
local STATA     STATA
local Stata     struct `STATA' scalar
local pStata    pointer(`Stata') scalar
local SOPT      SOPT
local Sopt      struct `SOPT' scalar
local SoptR     struct `SOPT' rowvector
// - structures for Graphs
local GRAPH     GRAPH
local Graph     struct `GRAPH' scalar
local pGraph    pointer(`Graph') scalar
local GOPT      GOPT
local Gopt      struct `GOPT' scalar
local GoptR     struct `GOPT' rowvector
// - structure inline results
local INLINE    INLINE
local Inline    struct `INLINE' scalar
local pInline   pointer(`Inline') scalar
// - structure for command line token environment
local CMDLINE   CMDLINE
local Cmdline   struct `CMDLINE' scalar
// - pragma
local Unset     pragma unset

mata:
mata set matastrict on

/*---------------------------------------------------------------------------*/
/* classes and structures                                                    */
/*---------------------------------------------------------------------------*/

// master structure
struct `MAIN' {
    `File'      tgt,      // target file
                db,       // database file
                dof,      // temporary do file
                tex,      // temporary tex file
                log       // temporary log file
    `Bool'      nocd,     // do not change directory for execution of do-file
                replace,  // whether replace was specified
                reset,    // eliminate preexisting database
                nodb,     // do not keep database
                update,   // whether database needs updating
                dosave    // whether dosave option active for any Stata insert
    `Int'       s,        // counter for Stata blocks
                g,        // counter for graphs
                i         // counter for Stata inline expressions
    `Str'       lognm,    // log name
                srcdir,   // path of source file
                tgtdir,   // path of output file
                lastS,    // id of last Stata insert
                lastG,    // id of last graph
                punct     // punctuation for composite names
    `Tag'       tag       // input tags
    `Itag'      Itag      // inline expression tags
    `Ltag'      Ltag      // weaving tags in log file
    `Ttag'      Ttag      // weaving tags in LaTeX file
    `Parts'     P         // info on parts
    `Sopt'      Sopt      // default options for Stata inserts
    `Gopt'      Gopt      // default options for graphs
    `TokEnv'    t1,       // tokeninit() for reading first token of input lines
                t2        // tokeninit() for reading argument within {} or []
    `Cmdline'   t         // tokeninit() for reading Stata command lines
    `AsArray'   S,        // associative array for Stata inserts
                G,        // associative array for graphs
                I         // associative array for Stata inline expressions
    `StrC'      Skeys,    // keys of Stata blocks
                Gkeys,    // keys of graphs
                Ikeys     // keys of Stata inline expressions
}

// structure for files
struct `FILE' {
    `Str'       fn,     // file name
                id      // id for local macro containing file handle
    `Int'       fh      // file handle
}

// structure for contents of input file
struct `SOURCE' {
    `Int'       i,  // current line
                i0, // first line of current parsing block
                n   // number of lines
    `StrC'      S   // file contents
}

// structure for input tags
struct `TAG' {
    `Str'       st,         // prefix of %ST-tags
                part,       // %STpart
                ignore,     // %STignore
                endignore,  // %STendignore
                remove,     // %STremove
                endremove,  // %STendremove
                cs,         // LaTeX command start (backslash)
                Begin,      // \begin{}
                End,        // \end{}
                stinput,    // \stinput{}
                stgraph,    // \stgraph{}
                stres,      // \stres{}
                endinput,   // \endinput
                qui,        // //STqui
                oom,        // //SToom
                cnp         // //STcnp
    `StrC'      env         // keyword in \begin{}...\end{}
}

// inline expression tags: tags within \stres{{}}
struct `ITAG' {
    `Str'       log,      // log include
                lognm,    // log name
                graph,    // graph include
                graphnm   // graph name (without suffix)
}

// weaving tags in log file
struct `LTAG' {
    `Str'       S,    // Stata block start
                Send, // Stata block end
                G,    // Graph
                I,    // Inline result start
                Iend, // Inline result stop
                qui,  // STqui
                oom   // SToom
}

// weaving tags in LaTeX file
struct `TTAG' {
    `Str'       S,    // Stata block start
                Send, // Stata block end
                G,    // Graph start
                Gend, // Graph end
                I,    // Inline result start
                Iend  // Inline result stop
}

// structure for information on parts
struct `PARTS' {
    `Int'       j      // part counter
    `StrR'      id     // part ids
    `StrR'      pid    // id of parent part
    `BoolR'     run    // whether to run part
    `IntR'      a      // starting position of part in do-file
}

// structure for Stata blocks
struct `STATA' {
    `Bool'      newcmd, // whether commands changed
                newlog, // whether log changed
                save    // whether log needs to be saved on disc
    `Int'       trim    // size of trimmed indentation
    `Sopt'      O       // options
    `pStrC'     cmd,    // current commands
                cmd0,   // previous version
                log,    // raw TeX log
                log0,   // previous version
                tex     // modified TeX log
}

// struct for Stata insert options
struct `SOPT' {
    `Bool'      nooutput,   // set output proc / set output inform
                nooutput0,  // previous version
                nocommands, // strip commands from log
                code,       // include copy of commands instead of output log
                verb,       // use verbatim copy of commands
                mata,       // commands are Mata
                quietly,    // do not include commands/output in document
                notrim,     // do not remove indentation
                noprompt,   // strip command prompt
                nolb,       // strip line break comments from log
                nogt,       // strip line continuation symbols from log
                nobegin,    // omit stlog environment begin
                noend,      // omit stlog environment end
                beamer,     // use \begin{stlog}[beamer] instead of \begin{stlog}
                statc,      // copy log into LaTeX file 
                dosave,     // whether to store commands in a do-file
                certify,    // compare results against existing version
                nodo        // do not run the commands
    `Int'       trim,       // max. levels of indentation to remove
                linesize,   // width of output log
                linesize0   // previous version
    `IntR'      drop,       // indices of commands to be removed
                oom,        // indices of commands for which to insert \oom
                noo,        // indices of commands from which to delete output
                cnp         // indices of commands after which to insert \cnp
    `Str'       Begin,      // environment begin, default: \begin{stlog}
                End,        // environment end, default: \end{stlog}
                alert,      // enclose specified strings in \alert{}                // maybe alert, tag, subst should be StrR or so... !!!
                tag,        // apply custom tags to specified strings
                subst,      // apply specified substitutions 
                logdir,     // path of log file
                logdir0,    // include path for log file
                dodir,      // path of do file
                dodir0      // include path for do file
}

// structure for graphs
struct `GRAPH' {
    `Gopt'      O          // options
    `StrC'      fn         // tempfiles containing graph
}

// structure for graph options
struct `GOPT' {
    `Bool'      suffix,    // whether to add file suffix
                epsfig,    // whether to use \epsfig{}
                center,    // whether to include in center environment
                custom     // use custom code to include graph
    `Str'       name,      // name of graph window
                args,      // arguments for \includegraphics
                override,  // override options for graph command
                dir,       // path of graph files
                dir0       // include path for graph file
    `StrC'      as         // graph formats
}

// structure for inline expressions
struct `INLINE' {
    `pStr'      cmd,  // command
                log   // TeX log
}

// structure for command-line tokeninit()
struct `CMDLINE' {
    `Str'       l,  // inline comment start (/*)
                r,  // inline commend end (*/)
                lb, // line break comment (///)
                eol // end of line comment (//)
    `TokEnv'    t
}

/*---------------------------------------------------------------------------*/
/* Some preparatory taks                                                     */
/*---------------------------------------------------------------------------*/

// add suffix to source file
void AddSuffixToSourcefile()
{
    `Str' src
    
    src = st_local("src")
    if (pathsuffix(src)=="") src = src + ".sttex"
    st_local("src", src)
}

// look for %STinit in first 50 lines of source file
void GetInitFromSourcefile()
{
    `Int'    i, fh
    `Str'    tag, line, s
    `StrM'   EOF
    `TokEnv' t
    
    tag = "%STinit"
    EOF = J(0, 0, "")
    t = tokeninit((" "+char(9)), (","))
    fh = FOpen(st_local("src"), "r")
    for (i=1; i<=50; i++) {
        if ((line=fget(fh))==EOF) {
            FClose(fh)
            return
        }
        tokenset(t, line)
        s = tokenget(t)
        if (s==tag) break
    }
    FClose(fh)
    if (i>50) return // %STtex not found
    stata("_collect_overall_options " + tokenrest(t))
    stata("_collect_typeset_options, " + st_local("options"))
    st_local("StartAtLine", strofreal(i+1))
}

// prepare file names
void PrepareFilenames()
{
    `Str' src                     // path and name of source file
    `Str' srcdir; `Unset' srcdir  // path of source file (without name)
    `Str' srcnm;  `Unset' srcnm   // name of source file (without path)
    `Str' tgt                     // path and name of target file
    `Str' tgtdir; `Unset' tgtdir  // path of target file (without name)
    `Str' tgtnm;  `Unset' tgtnm   // name of target file (without path)

    // source file
    src = st_local("src")
    pathsplit(src, srcdir, srcnm)
    // target file
    tgt = st_local("saving")
    if (tgt=="")                  tgt = pathrmsuffix(srcnm) + ".tex"
    else if (pathsuffix(tgt)=="") tgt = tgt + ".tex"
    if (!pathisabs(tgt)) tgt = pathjoin(srcdir, tgt)
    if (src==tgt) {
        display("{err}target file can not be the same as the source file")
        exit(602)
    }
    pathsplit(tgt, tgtdir, tgtnm)
    // returns
    st_local("srcdir", srcdir)
    st_local("srcnm", srcnm)
    st_local("tgt", tgt)
    st_local("tgtdir", tgtdir)
    st_local("tgtnm", tgtnm)
}

/*---------------------------------------------------------------------------*/
/* main routine                                                              */
/*---------------------------------------------------------------------------*/

void Process()
{
    `Str'  pwd
    `Int'  rc, run
    `Main' M
    
    // process input file
    ParseSrc(M = Initialize(), ImportSrc(st_local("src"), strtoreal(st_local("StartAtLine"))))
    FClose(M.dof.fh, M.dof.id)
    FClose(M.tex.fh, M.tex.id)

    // remove old keys
    if (!M.nodb & !M.reset) DeleteOldKeys(M)
    
    // run do-file and collect log
    run = sum(M.P.run)
    if (run) {
        // determine parts of dofile to be executed
        if (run<M.P.j) {
            UpdateRunFlags(M.P)
            RemovePartsFromDofile(M)
        }
        // - working directory
        pwd = pwd()
        if (!M.nocd & M.srcdir!="") chdir(M.srcdir)
        // - make sure that output is on
        stata("set output proc")
        // - start log
        stata("quietly log using " + "`" + `"""' + M.log.fn + `"""' + "'" + 
            ", smcl name(" + M.lognm + ")")
        // - run do-file
        rc = _stata("version " + st_local("caller") + ": do " + 
            "`" + `"""' + M.dof.fn + `"""' + "'" +
            (st_local("args")!="" ? " " + st_local("args") : "") +
            (st_local("nostop")!="" ? ", nostop" : ""))
        if (rc) exit(rc)
        // - stop log
        stata("quietly log close " + M.lognm)
        // - make sure that output is on
        stata("set output proc")
        // - restore working directory
        chdir(pwd)
        // - collect results
        Collect(M)
    }
    
    // format log files; also sets M.dosave flag
    Format(M)
    
    // weave
    M.tgt.fh = FOpen(M.tgt.fn, "w", M.tgt.id, 1)
    Weave(M)
    FClose(M.tgt.fh, M.tgt.id)
    
    // store external log files
    External_logfiles(M)

    // store external do-files
    External_dofiles(M)

    // backup database
    if (!M.nodb) {
        if (M.update) DatabaseWrite(M)
    }
    else DatabaseDelete(M)
}

/*---------------------------------------------------------------------------*/
/* initialization                                                            */
/*---------------------------------------------------------------------------*/

// initialization
`Main' Initialize()
{
    `Bool' haslogdir, hasdodir, hasgrdir
    `Main' M
    
    // target file and path
    M.srcdir  = st_local("srcdir")
    M.tgt.fn  = st_local("tgt"); M.tgt.id  = "tgt"
    M.tgtdir  = st_local("tgtdir")
    M.nocd    = (st_local("nocd")!="")
    if (!direxists(M.tgtdir)) mkdir(M.tgtdir)
    
    // replace option
    M.replace = (st_local("replace")!="")
    Fexists(M.tgt.fn, M.replace)
    
    // temporary do-file and tex-file
    M.dof.fh = FOpen(M.dof.fn = st_tempfilename(), "rw", M.dof.id = "dof")
    M.tex.fh = FOpen(M.tex.fn = st_tempfilename(), "w" , M.tex.id = "tex")
    
    // main log file
    M.log.fn = st_tempfilename()
    M.lognm  = st_tempname() //"stTeX_log"
    st_local("lognm", M.lognm)
    
    // part setup
    M.P.j = 1 
    M.P.a = 0
    M.P.id  = ""
    M.P.pid = "."
    M.P.run = `FALSE'
    
    // other
    M.s = M.g = M.i = 0 // counters
    M.dosave = `FALSE'
    M.punct = "_"
    
    // Stata block options and graph options specified with sttex (adding a
    // blank to the options so that the routines will run through even if no
    // options are specified; this ensured that the defaults will be set)
    _collect_stlog_options(M, M.Sopt, st_local("options0")+" ", `SOURCE'())
    haslogdir = (st_local("haslogdir")!="")
    hasdodir  = (st_local("hasdodir")!="")
    _collect_graph_options(M, M.Gopt, st_local("options")+" ", `SOURCE'())
    hasgrdir  = (st_local("gr_hasdir")!="")
    
    // Stata block options and graph options specified with %STinit
    _collect_stlog_options(M, M.Sopt, st_local("options1"), `SOURCE'())
    if (!haslogdir & st_local("haslogdir")=="") {
        M.Sopt.logdir  = pathrmsuffix(M.tgt.fn)
        M.Sopt.logdir0 = pathrmsuffix(pathbasename(M.tgt.fn))
    }
    if (!hasdodir & st_local("hasdodir")=="") {
        M.Sopt.dodir  = M.Sopt.logdir
        M.Sopt.dodir0 = M.Sopt.logdir0
    }
    if (M.Sopt.nodo==`TRUE') M.P.run[M.P.j] = 0   // forced nodo
    _collect_graph_options(M, M.Gopt, st_local("options"), `SOURCE'())
    if (!hasgrdir & st_local("gr_hasdir")=="") {
        M.Gopt.dir  = M.Sopt.logdir
        M.Gopt.dir0 = M.Sopt.logdir0
    }
    
    // input tags
    M.tag.st        = "%ST"
    M.tag.part      = M.tag.st + "part"
    M.tag.ignore    = M.tag.st + "ignore"
    M.tag.endignore = M.tag.st + "endignore"
    M.tag.remove    = M.tag.st + "remove"
    M.tag.endremove = M.tag.st + "endremove"
    M.tag.cs        = "\"
    M.tag.Begin     = M.tag.cs + "begin"
    M.tag.End       = M.tag.cs + "end"
    M.tag.stinput   = M.tag.cs + "stinput"
    M.tag.stgraph   = M.tag.cs + "stgraph"
    M.tag.stres     = M.tag.cs + "stres"
    M.tag.endinput  = M.tag.cs + "endinput"
    M.tag.qui       = "//STqui"
    M.tag.oom       = "//SToom"
    M.tag.cnp       = "//STcnp"
    M.tag.env       = ("stata", "stata*", "mata", "mata*")'
    
    // inline expression tags
    M.Itag.log      = "log"
    M.Itag.lognm    = "logname"
    M.Itag.graph    = "graph"
    M.Itag.graphnm  = "grname"
      
    // weaving tags in log file
    M.Ltag.S    = "//stTeX// --> stlog start:"
    M.Ltag.Send = "//stTeX// --> stlog stop"
    M.Ltag.G    = "//stTeX// --> stgraph:"
    M.Ltag.I    = "//stTeX// --> inline expression start:"
    M.Ltag.Iend = "//stTeX// --> inline expression stop"
    M.Ltag.qui  = "/*STqui -->*/ quietly ///"
    M.Ltag.oom  = "/*SToom -->*/ quietly ///"

    // weaving tags in LaTeX file
    M.Ttag.S    = "%%stTeX-stlog:"
    M.Ttag.Send = ":golts-XeTts%%"
    M.Ttag.G    = "%%stTeX-stgraph:"
    M.Ttag.Gend = ":hpargts-XeTts%%"
    M.Ttag.I    = "%%stTeX-stres:"
    M.Ttag.Iend = ":serts-XeTts%%"
    
    // tokeninit() 
    // - for reading first token of input lines
    M.t1 = tokeninit((" "+char(9)), (",", "{", "["))
    // - for reading argument within {} or []
    M.t2 = tokeninit("", ("{", "}", "[", "]"))
    // - command-line tokeninit()
    M.t.l = "/*"; M.t.r = "*/"; M.t.lb = " ///"; M.t.eol  = " //"
    M.t.t = tokeninit("", (M.t.l, M.t.r, M.t.lb, M.t.eol))
    
    // db an associative arrays for logs, graphs, and inline expressions
    M.update = 0
    M.db.fn = st_local("dbname")
    if (M.db.fn=="") M.db.fn = st_local("src") + ".db"
    else {
        if (pathsuffix(M.db.fn)=="")
            M.db.fn = M.db.fn + pathsuffix(st_local("src")) + ".db"
        if (!pathisabs(M.db.fn))
            M.db.fn = pathjoin(st_local("srcdir"), M.db.fn)
    }
    M.reset = (st_local("reset")!="")
    M.nodb  = (st_local("nodb")!="")
    if (!M.nodb) {
        /*
        if (M.db.fn==st_local("src")) {
            display("{err}database file can not be the same as the source file")
            exit(602)
        }
        if (M.db.fn==M.tgt.fn) {
            display("{err}database file can not be the same as the target file")
            exit(602)
        }
        */
        Fexists(M.db.fn, M.replace)
    }
    if (!DatabaseRead(M)) {
        M.S = asarray_create()
        M.G = asarray_create()
        M.I = asarray_create()
    }
    return(M)
}

// collect stlog options
void _collect_stlog_options(`Main' M, `Sopt' O, `Str' opts, `Source' F)
{
    `Bool' rc
    
    if (opts=="") {
        if (O.nodo==`FALSE') M.P.run[M.P.j] = `TRUE' // forced do
        st_local("options", "")
        return
    }
    // run Stata parser
    rc = _stata("_collect_stlog_options, " + opts)
    if (rc) {
        if (F.i0<.) ErrorLines(F)
        exit(rc)
    }
    // collect on/off options (1 = on, 0 = off, . = not specified)
    _collect_onoff_option("nooutput"     , O.nooutput)
    _collect_onoff_option("nocommands"   , O.nocommands)
    _collect_onoff_option("code"         , O.code)
    _collect_onoff_option("verbatim"     , O.verb)
    _collect_onoff_option("mata"         , O.mata)
    _collect_onoff_option("quietly"      , O.quietly)
    _collect_onoff_option("notrim"       , O.notrim)
    _collect_onoff_option("noprompt"     , O.noprompt)
    _collect_onoff_option("nolb"         , O.nolb)
    _collect_onoff_option("nogt"         , O.nogt)
    _collect_onoff_option("nobegin"      , O.nobegin)
    _collect_onoff_option("noend"        , O.noend)
    _collect_onoff_option("beamer"       , O.beamer)
    _collect_onoff_option("static"       , O.statc)
    _collect_onoff_option("dosave"       , O.dosave)
    _collect_onoff_option("certify"      , O.certify)
    _collect_onoff_option("nodo"         , O.nodo)
    // numeric options (. if not specified)
    if (st_local("trim2")!="")    O.trim     = strtoreal(st_local("trim2"))
    if (st_local("linesize")!="") O.linesize = strtoreal(st_local("linesize"))
    // multivalued numeric option (J(1,0,.) if not specified)
    if (st_local("drop")!="") O.drop = strtoreal(tokens(st_local("drop")))
    if (st_local("oom")!="")  O.oom = strtoreal(tokens(st_local("oom")))
    if (st_local("nooutput2")!="") O.noo = strtoreal(tokens(st_local("nooutput2")))
    if (st_local("cnp")!="")  O.cnp = strtoreal(tokens(st_local("cnp")))
    // string options ("" if not specified)
    if (st_local("begin2")!="")     O.Begin = st_local("begin2")
    if (st_local("end2")!="")       O.End   = st_local("end2")
    if (st_local("alert")!="")      O.alert = st_local("alert")
    if (st_local("tag")!="")        O.tag   = st_local("tag")
    if (st_local("substitute")!="") O.subst = st_local("substitute")
    // logdir
    if (st_local("haslogdir")!="") {
        O.logdir0 = st_local("logdir")
        if (pathisabs(O.logdir0)) O.logdir = O.logdir0
        else O.logdir = pathjoin(M.tgtdir, O.logdir0)
    }
    // dodir
    if (st_local("hasdodir")!="") {
        O.dodir0 = st_local("dodir")
        if (pathisabs(O.dodir0)) O.dodir = O.dodir0
        else O.dodir = pathjoin(M.tgtdir, O.dodir0)
    }
    // forced do
    if (O.nodo==`FALSE') M.P.run[M.P.j] = `TRUE'
}

// collect on/off option
void _collect_onoff_option(`Str' opt, `Bool' o, | `Str' prefix)
{
    `Str' s
    
    if (substr(opt,1,2)=="no") {
        opt = substr(opt,3,.)
        s = st_local(prefix + opt)
        if (s==("no"+opt))  o = `TRUE'
        else if (s==opt)    o = `FALSE'
        return
    }
    s = st_local(prefix + opt)
    if (s==opt)             o = `TRUE'
    else if (s==("no"+opt)) o = `FALSE'
}

// collect graph options
void _collect_graph_options(`Main' M, `Gopt' O, `Str' opts, `Source' F)
{
    `Bool' rc
    
    // run Stata parser
    if (opts=="") return
    rc = _stata("_collect_graph_options, " + opts)
    if (rc) {
        if (F.i0<.) ErrorLines(F)
        exit(rc)
    }
    // collect on/off options (1 = on, 0 = off, . = not specified)
    _collect_onoff_option("suffix"  , O.suffix, "gr_")
    _collect_onoff_option("epsfig"  , O.epsfig, "gr_")
    _collect_onoff_option("center"  , O.center, "gr_")
    _collect_onoff_option("custom",   O.custom, "gr_")
    // string options ("" if not specified)
    if (st_local("gr_name")!="")        O.name     = st_local("gr_name")
    if (st_local("gr_hasargs")!="")     O.args     = st_local("gr_args")
    if (st_local("gr_hasoverride")!="") O.override = st_local("gr_override")
    // multivalued string option (J(,1,"") if not specified)
    if (st_local("gr_as")!="")          O.as       = tokens(st_local("gr_as"))'
    // grdir option
    if (st_local("gr_hasdir")!="") {
        O.dir0 = st_local("gr_dir")
        if (pathisabs(O.dir0)) O.dir = O.dir0
        else O.dir = pathjoin(M.tgtdir, O.dir0)
    }
}

/*---------------------------------------------------------------------------*/
/* database write/read                                                       */
/*---------------------------------------------------------------------------*/

void DatabaseWrite(`Main' M)
{
    // push name of database file to Stata
    st_local("dbfile", M.db.fn)
    // open DB and write header
    M.db.fh = FOpen(M.db.fn, "w", "", 1)
    fput(M.db.fh, "stTeX database version 1.0.0")
    // write associative arrays
    fputmatrix(M.db.fh, M.S)
    fputmatrix(M.db.fh, M.G)
    fputmatrix(M.db.fh, M.I)
    // close DB
    FClose(M.db.fh, "")
    printf("{txt}(sttex database saved as %s)\n", M.db.fn)
    // push update status to Stata
    st_local("dbupdate","1")
}

`Bool' DatabaseRead(`Main' M)
{
    if (M.nodb | M.reset) return(0)
    if (!fileexists(M.db.fn)) return(0)
    // open DB and read header
    M.db.fh = FOpen(M.db.fn, "r")
    if (fget(M.db.fh)!="stTeX database version 1.0.0") {
        printf("{txt}(%s is not a valid sttex database)\n", M.db.fn)
        FClose(M.db.fh)
        return(0)
    }
    // read associative arrays
    M.S = fgetmatrix(M.db.fh)
    M.G = fgetmatrix(M.db.fh)
    M.I = fgetmatrix(M.db.fh)
    FClose(M.db.fh)
    return(1)
}

void DatabaseDelete(`Main' M)
{
    `Str' line
    
    if (!fileexists(M.db.fn)) return
    // open DB and read header
    M.db.fh = FOpen(M.db.fn, "r")
    line = fget(M.db.fh)
    FClose(M.db.fh)
    // do nothing if no sttex database
    if (line!="stTeX database version 1.0.0") return
    // unlink database
    unlink(M.db.fn)
    printf("{txt}(sttex database %s erased)\n", M.db.fn)
}

/*---------------------------------------------------------------------------*/
/* function to process input file                                            */
/*---------------------------------------------------------------------------*/

`Source' ImportSrc(`Str' fn, `Int' i)
{
    `Source' F

    F.S = Cat(fn)
    F.i = i
    F.n = rows(F.S) 
    return(F)
}

void ParseSrc(`Main' M, `Source' F)
{
    `Str' s

    for (; F.i<=F.n; (void) F.i++) {
        tokenset(M.t1, F.S[F.i])
        s = tokenget(M.t1)
        if (substr(s,1,3)==M.tag.st) {
            if (s==M.tag.part) {
                Part(M, tokenrest(M.t1), F)
                continue
            }
            if (s==M.tag.ignore) { 
                if (Ignore(M, F)) break
                continue
            }
            if (s==M.tag.remove) { 
                if (Remove(M, F)) break
                continue
            }
            Parse_I(M, F)
            continue
        }
        if (substr(s,1,1)!=M.tag.cs) {
            Parse_I(M, F)
            continue
        }
        if (s==M.tag.endinput) break
        if (s==M.tag.Begin) {
            if (Parse_S(M, F)) continue
        }
        else if (s==M.tag.stinput) {
            Input(M, F)
            continue
        }
        else if (s==M.tag.stgraph) {
            if (Parse_G(M, F)) continue
        }
        Parse_I(M, F)
    }
}

/*---------------------------------------------------------------------------*/
/* functions to handle parts                                                 */
/*---------------------------------------------------------------------------*/

// main function
void Part(`Main' M, `Str' s, `Source' F)
{
    `Str' id, pid, tok, opts
    
    M.s = M.g = M.i = 0 // reset counters
    M.P.j   = M.P.j + 1
    M.P.a   = M.P.a, ftell(M.dof.fh)
    M.P.run = M.P.run, `FALSE'
    tokenset(M.t1, s)
    if ((tok=tokenget(M.t1))!="") {
        if (tok!=",") {
            id = tok
            if (id==".") id = ""
            else if (!st_islmname(id)) {
                printf("{err}'%s' invalid name\n", id)
                F.i0 = F.i; ErrorLines(F)
                exit(7)
            }
            tok = tokenget(M.t1)
        }
        if (tok!=",") {
            pid = tok
            if (pid!="." & pid!="") {
                if (!st_islmname(pid)) {
                    printf("{err}'%s' invalid name\n", pid)
                    F.i0 = F.i; ErrorLines(F)
                    exit(7)
                }
            }
            tok = tokenget(M.t1)
        }
        if (tok==",") opts = tokenrest(M.t1)
        else if (tok!="") {
            printf("{err}'%s' not allowed\n", tok)
            F.i0 = F.i; ErrorLines(F)
            exit(499)
        }
    }
    if (id=="") id = strofreal(M.P.j-1)
    if (anyof(M.P.id, id)) {
        printf("{err}'%s' already taken; part names must be unique\n", id)
        F.i0 = F.i; ErrorLines(F)
        exit(499)
    }
    M.P.id  = M.P.id, id
    M.P.pid = M.P.pid, pid
    _collect_stlog_options(M, M.Sopt, opts, F)
    _collect_graph_options(M, M.Gopt, st_local("options"), F)
}

/*---------------------------------------------------------------------------*/
/* functions to parse Stata blocks                                           */
/*---------------------------------------------------------------------------*/

// main function
// return code: 0 not a Stata block, 1 Stata block processed
`Bool' Parse_S(`Main' M, `Source' F)
{
    `Int'   mode
    `Str'   tag, id, opts
    `Sopt'  O
    
    // determine mode
    tag = TabTrim(Get_Arg(M, "{", "}", F))
    if (!anyof(M.tag.env, tag)) return(`FALSE')
    mode = select(1::length(M.tag.env), M.tag.env:==tag)
    // parse id and options: \begin{...}[id][options]
    F.i0 = F.i
    (void) M.s++; M.g = 0
    id = TabTrim(Get_Arg(M, "[", "]", F))
    opts = TabTrim(Get_Arg(M, "[", "]", F))
    O = M.Sopt
    if (!mod(mode,2))       O.quietly = `TRUE'
    if (anyof((3,4), mode)) O.mata    = `TRUE'
    _collect_stlog_options(M, O, opts, F)
    if (id=="") id = (M.P.j>1 ? M.P.id[M.P.j] + M.punct : "") + 
                     strofreal(M.s)
    else if (!st_islmname(id)) {
        printf("{err}'%s' invalid name\n", id)
        ErrorLines(F)
        exit(7)
    }
    if (anyof(M.Skeys, id)) {
        printf("{err}'%s' already taken; log names must be unique\n", id)
        ErrorLines(F)
        exit(499)
    }
    // read and process section
    _Parse_S(M, F, id, O, tag) 
    return(`TRUE')
}

void _Parse_S(`Main' M, `Source' F, `Str' id, `Sopt' O, `Str' tag)
{
    `Int'   i0, rc, trim
    `StrC'  C
    
    // read the commands
    // - find end
    i0 = F.i = F.i + 1
    for (; F.i<=F.n; F.i=F.i+1) {  // also handles //STqui and //SToom
        if (rc = Parse_S_End(M, F, tag)) break
    }
    if (rc!=1) {
        printf("{err}line %g: %s\n", F.i0, F.S[F.i0])
        if (rc==0)  printf("{err}end not found\n")
        else        printf("{err}ended on line %g with: %s\n", F.i, F.S[F.i])
        exit(499)
    }
    // - copy commands
    if (F.i>i0)  C = F.S[|i0 \ F.i-1|]
    // - get rid of indentation
    if (O.notrim!=`TRUE') trim = Parse_S_trim(M, C, O.trim)
    // prepare do-file
    if (O.nodo!=`TRUE') {
        // - set line size and output mode
        if (O.code!=`TRUE') {
            if (O.linesize<.) {
                fput(M.dof.fh, "local stTeX_linesize = c(linesize)")
                fput(M.dof.fh, "set linesize " + strofreal(O.linesize))
            }
            if (O.nooutput==`TRUE') fput(M.dof.fh, "set output inform")
        }
        // - start mata if needed
        if (O.mata==`TRUE') {
            //fput(M.dof.fh, "#delimit cr")                                           // ???
            fput(M.dof.fh, "mata:")
        }
        // - start insert
        if (O.code!=`TRUE') fput(M.dof.fh, M.Ltag.S + id)
        // - write the commands
        _Fput(M.dof.fh, C)
        // - stop insert
        if (O.code!=`TRUE') fput(M.dof.fh, M.Ltag.Send)
        // - end mata if needed
        if (O.mata==`TRUE') {
            fput(M.dof.fh, "end")
            //fput(M.dof.fh, "#delimit ;")                                          // ???
        }
        // - restore line size and output mode
        if (O.code!=`TRUE') {
            if (O.linesize<.) fput(M.dof.fh, "set linesize \`stTeX_linesize'")
            if (O.nooutput==`TRUE') fput(M.dof.fh, "set output proc")
        }
    }
    // write tags to LaTeX file
    if (O.quietly!=`TRUE') 
        fput(M.tex.fh, M.Ttag.S + id + M.Ttag.Send)
    // update database
    Parse_S_store(M, id, O, C, trim)
    M.Skeys = M.Skeys \ id                                                      // make more efficient?
    M.lastS = id
}

// look for end of Stata insert; also handle //STqui and //SToom
// return code: 0 continue, 1 end found, -1 wrong end tag, -2 \endinput
`Int' Parse_S_End(`Main' M, `Source' F, `Str' tag)
{
    `Str' s
    
    tokenset(M.t1, F.S[F.i])
    s = tokenget(M.t1)
    if (s==M.tag.qui) {
        F.S[F.i] = substr(F.S[F.i], 1, strpos(F.S[F.i], M.tag.qui)-1) + M.Ltag.qui
        return(0)
    }
    if (s==M.tag.oom) {
        F.S[F.i] = substr(F.S[F.i], 1, strpos(F.S[F.i], M.tag.oom)-1) + M.Ltag.oom
        return(0)
    }
    if (s==M.tag.End) {
        if (TabTrim(Get_Arg(M, "{", "}", F))==tag) return(1)
        else return(-1) // wrong \end tag
    }
    if (s==M.tag.endinput) return(-2)
    return(0)
}

// trim indentation; returns the size of trimmed indentation
`Int' Parse_S_trim(`Main' M, `StrC' C, `Int' trim)
{
    `Int' t, i, l

    t = trim
    for (i=1; i<=rows(C); i++) {
        tokenset(M.t1, C[i])
        if ((l = strlen(tokenget(M.t1)))==0) continue // empty line
        l = tokenoffset(M.t1) - l - 1 // size of indentation
        if (l<t) t = l
        if (t<1) return(t) // zero indentation
    }
    if (t>=.) return(0) // can happen if all lines only contain white space
    C = substr(C, t+1, .)
    return(t)
}

// update info on Stata block in database and determine whether code needs to be run
void Parse_S_store(`Main' M, `Str' id, `Sopt' O, `StrC' C, `Int' trim)
{
    `Bool'   chflag
    `pStata' S
    
    // update M.P.run if forced do
    if (O.nodo==`FALSE') M.P.run[M.P.j] = `TRUE'
    // no preexisting version
    if (!asarray_contains(M.S, id)) {
        if (O.nodo!=`TRUE') M.P.run[M.P.j] = `TRUE'
        M.update = `TRUE'
        S = &(`STATA'())
        S->cmd = &C
        S->newcmd = `TRUE'; S->newlog = `FALSE'
        S->O = O
        S->trim = trim
        asarray(M.S, id, S)
        return
    }
    // update preexisting version
    S = asarray(M.S, id)
    S->cmd0 = S->cmd; S->log0 = S->log // ... also handle nooutput0, linesize0....
    S->newcmd = `FALSE'; S->newlog = `FALSE'
    // - change in commands
    chflag = `FALSE'
    if (*S->cmd!=C) {
        S->cmd = &C; S->newcmd = `TRUE'; M.update = `TRUE';     chflag = `TRUE'
    }
    // - other changes that require rerunning the code
    else if ((S->O.mata==`TRUE')!=(O.mata==`TRUE'))             chflag = `TRUE'
    else if (O.code!=`TRUE') {
        // no previous output
        if (S->O.code==`TRUE')                                  chflag = `TRUE'
        // type of output changed
        else if ((S->O.nooutput==`TRUE')!=(O.nooutput==`TRUE')) chflag = `TRUE'
        // linesize changed
        else if (S->O.linesize!=O.linesize)                     chflag = `TRUE'
    }
    if (chflag) {
        S->log = S->tex = NULL
        // update M.P.run unless forced nodo
        if (O.nodo!=`TRUE') M.P.run[M.P.j] = `TRUE'
    }
    // changes that require regenerating S->log without rerunning the code
    else if (S->O.code==`TRUE') {
        chflag = `FALSE'
        if (S->O.linesize!=O.linesize)                         chflag = `TRUE'
        else if ((S->O.verb==`TRUE')!=(O.verb==`TRUE'))        chflag = `TRUE'
        if (chflag) S->log = S->tex = NULL
    }
    // - changes that require regenerating S->tex
    if (!chflag) {
        chflag = `FALSE'
        if ((S->O.nocommands==`TRUE')!=(O.nocommands==`TRUE'))  chflag = `TRUE'
        else if ((S->O.noprompt==`TRUE')!=(O.noprompt==`TRUE')) chflag = `TRUE'
        else if ((S->O.nolb==`TRUE')!=(O.nolb==`TRUE'))         chflag = `TRUE'
        else if ((S->O.nogt==`TRUE')!=(O.nogt==`TRUE'))         chflag = `TRUE'
        else if (S->O.drop!=O.drop)                             chflag = `TRUE'
        else if (S->O.oom!=O.oom)                               chflag = `TRUE'
        else if (S->O.noo!=O.noo)                               chflag = `TRUE'
        else if (S->O.cnp!=O.cnp)                               chflag = `TRUE'
        else if (S->O.alert!=O.alert)                           chflag = `TRUE'
        else if (S->O.tag!=O.tag)                               chflag = `TRUE'
        if (chflag) S->tex = NULL
    }
    // - copy options
    if (S->O!=O) M.update = `TRUE'
    S->O =  O
    // - amount of trimming
    if (S->trim!=trim) M.update = `TRUE'
    S->trim = trim
}

/*---------------------------------------------------------------------------*/
/* functions to handle Graphs                                                */
/*---------------------------------------------------------------------------*/

// return code: 1 Graph processed; 0 not a valid \stgraph command
`Bool' Parse_G(`Main' M, `Source' F)
{
    `Bool' rc; `Unset' rc
    `Str'  id, opts
    
    F.i0 = F.i
    id = TabTrim(Get_Arg(M, "[", "]", F)) // ignore errors
    if (id!="") {
        if (!st_islmname(id)) {
            printf("{err}'%s' invalid name\n", id)
            ErrorLines(F)
            exit(7)
        }
    }
    opts = TabTrim(Get_Arg(M, "{", "}", F, rc))
    if (rc) return(`FALSE')
    _Parse_G(M, F, id, opts)
    return(`TRUE')
}

void _Parse_G(`Main' M, `Source' F, `Str' id, `Str' opts)
{
    `Bool'   nodo
    `StrC'   fn
    `pStata' S
    `Gopt'   O
    
    O = M.Gopt
    _collect_graph_options(M, O, opts, F)
    if (length(O.as)==0) {
        if (O.epsfig==`TRUE') O.as = "eps"
        else                  O.as = "pdf"
    }
    if (id=="") {
        if (M.lastS!="") id = M.lastS
        else id = (M.P.j>1 ? M.P.id[M.P.j] + M.punct : "") + "0"
        if (M.g>0) id = id + NumToLetter(M.g)
    }
    if (M.lastS=="") nodo = M.Sopt.nodo
    else {
        S = asarray(M.S, M.lastS)
        nodo = S->O.nodo
    }
    (void) M.g++ // update graph counter
    if (anyof(M.Gkeys, id)) {
        printf("{err}'%s' already taken; graph names must be unique\n", id)
        ErrorLines(F)
        exit(499)
    }
    // prepare do-file
    if (nodo!=`TRUE') {
        fn = st_tempfilename(length(O.as))'
        Parse_G_dof(M, O, fn)
        fput(M.dof.fh, M.Ltag.G + id)
    }
    // write tags to LaTeX file
    if (O.custom!=`TRUE') 
        fput(M.tex.fh, M.Ttag.G + id + M.Ttag.Gend)
    // update database
    Parse_G_store(M, id, O, fn, nodo)
    M.Gkeys = M.Gkeys \ id                                                      // make more efficient?
    M.lastG = id
}

void Parse_G_dof(`Main' M, `Gopt' O, `StrC' fn)
{
    `Int' i, n
    `Str' name
    
    if (O.name!="") name = "name(" + O.name + ") "
    n = length(O.as)
    for (i=1; i<=n; i++) {
        fput(M.dof.fh, "quietly graph export " + 
            "`" + `"""' + fn[i] + `"""' + "'" + 
            ", as(" + O.as[i] + ") " + name + O.override)
    }
}

// update info on Graph in database and determine whether code needs to be run
void Parse_G_store(`Main' M, `Str' id, `Gopt' O, `StrC' fn, `Bool' nodo)
{
    `Bool'   chflag
    `Int'    i
    `StrC'   f
    `pGraph' G
    
    // update M.P.run if forced do
    if (nodo==`FALSE') M.P.run[M.P.j] = `TRUE'
    // no preexisting version
    if (!asarray_contains(M.G, id)) {
        if (nodo!=`TRUE') M.P.run[M.P.j] = `TRUE'
        M.update = `TRUE'
        G = &(`GRAPH'())
        G->fn = fn
        G->O = O
        asarray(M.G, id, G)
        return
    }
    // update preexisting version
    G = asarray(M.G, id)
    G->fn = fn
    // - determine whether code needs to be run
    if (nodo!=`TRUE') {
        chflag = `FALSE'
        // file format(s) changed
        if (length(Complement(O.as, G->O.as))) chflag = `TRUE'
        // graph window changed
        else if (G->O.name!=O.name)            chflag = `TRUE'
        // override() option changed
        else if (G->O.override!=O.override)    chflag = `TRUE'
        // grdir changed
        else if (G->O.dir!=O.dir) {
            f = J(length(O.as), 1, "") 
            for (i=1; i<=length(O.as); i++) {
                f[i] = pathjoin(G->O.dir, id) + "." + O.as[i]
                if (!fileexists(f[i])) {
                    chflag = `TRUE'
                    f = J(0, 1, "")
                    break
                }
            }
            // copy files from old location
            if (!chflag) Copy_GRfiles(f, O.dir, id, O.as, M.replace)
        }
        // graph file(s) missing
        else {
            for (i=1; i<=length(O.as); i++) {
                f = pathjoin(O.dir, id) + "." + O.as[i]
                if (!fileexists(f)) {
                    chflag = `TRUE'
                    break
                }
            }
        }
        if (chflag) M.P.run[M.P.j] = `TRUE'
    }
    // - copy options
    if (G->O!=O) M.update = `TRUE'
    G->O = O
}

/*---------------------------------------------------------------------------*/
/* functions to handle inline expressions                                    */
/*---------------------------------------------------------------------------*/

// main function
void Parse_I(`Main' M, `Source' F)
{
    `Int' p
    `Str' s
    
    if (!(p = Parse_I_find(M, F.S[F.i]))) {
        fput(M.tex.fh, F.S[F.i])
        return
    }
    s = F.S[F.i]
    while (p) {
        _Parse_I(M, s, p, F)
        p = Parse_I_find(M, s)
    }
    fput(M.tex.fh, s) // write remainder of line + line break
}

// return position of inline expression, 0 if not found
`Int' Parse_I_find(`Main' M, `Str' s)
{
    `Int' p
    
    p = strpos(s, M.tag.stres)
    if (!p) return(0)
    if (p>=Parse_I_texcomment(s)) return(0)
    return(p)
}

void _Parse_I(`Main' M, `Str' s, `Int' p, `Source' F)
{
    `Bool'  rc; `Unset' rc
    `Str'   id, exp

    // get exp and id from \stres{exp}[id]
    F.i0 = F.i
    tokenset(M.t1, substr(s, p+6, .))
    id = TabTrim(Get_Arg(M, "[", "]", F)) // ignore errors
    exp = Get_Arg(M, "{", "}", F, rc)
    if (rc) { // invalid syntax => move on
        fwrite(M.tex.fh, substr(s, 1, p+5))
        s = substr(s, p+6, .)
        return
    }
    fwrite(M.tex.fh, substr(s, 1, p-1)) // write start of line to LaTeX file
    exp = subinstr(exp, "\%", "%") // so that Stata formats can be typed as \%
    s = tokenrest(M.t1) // remainder of line for further processing
    if (substr(exp,1,1)=="{" & substr(exp,strlen(exp),1)=="}") {
        Parse_I_immediate(M, exp, F)   // immediate expression
        return
    }
    (void) M.i++ // inline expression counter
    if (id=="") id = (M.P.j>1 ? M.P.id[M.P.j] + M.punct : "") + strofreal(M.i)
    else if (!st_islmname(id)) {
        printf("{err}'%s' invalid name\n", id)
        ErrorLines(F)
        exit(7)
    }
    if (anyof(M.Ikeys, id)) {
        printf("{err}'%s' already taken; inline expression names must be unique\n", id)
        ErrorLines(F)
        exit(499)
    }
    // prepare do-file                                                          // should this also depend on S->O.nodo from last insert?
    if (M.Sopt.nodo!=`TRUE') {
        fput(M.dof.fh, M.Ltag.I + id)
        fput(M.dof.fh, "display " + exp)
        fput(M.dof.fh, M.Ltag.Iend)
    }
    // add insert tag to LaTeX file
    fwrite(M.tex.fh, M.Ttag.I + id + M.Ttag.Iend)
    // update database
    Parse_I_store(M, id, exp)
    M.Ikeys = M.Ikeys \ id                                                      // make more efficient?
}

void Parse_I_immediate(`Main' M, `Str' exp, `Source' F)
{
    `Bool'   rc
    `pStata' S
    `pGraph' G
    
    exp = TabTrim(substr(exp,2,strlen(exp)-2)) // strip outer { }
    if (exp==M.Itag.log) {
        if (M.lastS=="") return
        //S = asarray(M.S, M.lastS)
        fwrite(M.tex.fh, M.Ttag.S + M.lastS + M.Ttag.Send)
        return
    }
    if (exp==M.Itag.lognm) { // paste Stata log filename
        if (M.lastS=="") return
        S = asarray(M.S, M.lastS)
        fwrite(M.tex.fh, pathjoin(S->O.logdir0, M.lastS) + ".log.tex")
        S->save = `TRUE'
        return
    }
    if (exp==M.Itag.graph) {
        if (M.lastG=="") return
        //G = asarray(M.G, M.lastG)
        fwrite(M.tex.fh, M.Ttag.G + M.lastG + M.Ttag.Gend)
        return
    }
    if (exp==M.Itag.graphnm) { // paste graph filename without suffix
        if (M.lastG=="") return
        G = asarray(M.G, M.lastG)
        fwrite(M.tex.fh, pathjoin(G->O.dir0, M.lastG))
        return
    }
    if ((rc = _stata("local sttex_value: display " + exp))) {
        ErrorLines(F)
        exit(rc)
    }
    fwrite(M.tex.fh, strtrim(st_local("sttex_value")))
}

// return position of tex comment; missing if not found
`Int' Parse_I_texcomment(`Str' s)
{
    `Int' p, p0

    p0 = 0
    while ((p = strpos(substr(s, p0+1, .), "%"))) {
        p = p0 + p
        if (substr(s, p-1, 1)!="\") return(p)
        p0 = p
    }
    return(.)
}

// update info on Stata inline expression in database and determine whether code needs to be run
void Parse_I_store(`Main' M, `Str' id, `Str' exp)
{
    `pInline' I
    
    // (updating M.P.run not needed; is done when creating M.Sopt)
    // no preexisting version
    if (!asarray_contains(M.I, id)) {
        if (M.Sopt.nodo!=`TRUE') M.P.run[M.P.j] = `TRUE'
        M.update = `TRUE'
        I = &(`INLINE'())
        I->cmd = &exp
        asarray(M.I, id, I)
        return
    }
    // update preexisting version
    I = asarray(M.I, id)
    if (*I->cmd!=exp) {
        if (M.Sopt.nodo!=`TRUE') M.P.run[M.P.j] = `TRUE'
        M.update = `TRUE'
        I->cmd = &exp
        I->log = NULL
    }
}

/*---------------------------------------------------------------------------*/
/* further functions for input processing                                    */
/*---------------------------------------------------------------------------*/

// handle STignore; returns 1 if \endinput encountered
`Bool' Ignore(`Main' M, `Source' F)
{
    `Int' l
    `Str' tok
    
    l = 1
    (void) F.i++
    for (; F.i<=F.n; (void) F.i++) {
        tokenset(M.t1, F.S[F.i])
        tok = tokenget(M.t1)
        if      (tok==M.tag.endignore) l--
        else if (tok==M.tag.ignore)    l++
        else if (tok==M.tag.endinput)  return(`TRUE')
        if (!l) return(`FALSE')
        fput(M.tex.fh, F.S[F.i])
    }
    return(`FALSE')
}

// handle STremove; returns 1 if \endinput encountered
`Bool' Remove(`Main' M, `Source' F)
{
    `Int' l
    `Str' tok

    l = 1
    (void) F.i++
    for (; F.i<=F.n; (void) F.i++) {
        tokenset(M.t1, F.S[F.i])
        tok = tokenget(M.t1)
        if      (tok==M.tag.endremove) l--
        else if (tok==M.tag.remove)    l++
        else if (tok==M.tag.endinput)  return(`TRUE')
        if (!l) return(`FALSE')
    }
    return(`FALSE')
}

// handle \stinput{} => nested call to ParseSrc()
void Input(`Main' M, `Source' F)
{
    `Bool' rc; `Unset' rc
    `Str'  fn
    
    F.i0 = F.i
    fn = TabTrim(Get_Arg(M, "{", "}", F, rc))
    if (rc)     fput(M.tex.fh, F.S[F.i])
    if (fn!="") {
        if (!pathisabs(fn)) fn = pathjoin(M.srcdir, fn)
        if (!fileexists(fn)) {
            printf("{err}%s not found\n", fn)
            ErrorLines(F)
            exit(601)
        }
        ParseSrc(M, ImportSrc(fn, 1))
    }
}

/*---------------------------------------------------------------------------*/
/* Delete old keys from associative arrays                                   */
/*---------------------------------------------------------------------------*/

void DeleteOldKeys(`Main' M)
{
    _DeleteOldKeys(M, M.S, M.Skeys)
    _DeleteOldKeys(M, M.G, M.Gkeys)
    _DeleteOldKeys(M, M.I, M.Ikeys)
}
void _DeleteOldKeys(`Main' M, `AsArray' A, `StrC' keys)
{
    `Int'  i, n
    `StrV' k
    
    k = Complement(asarray_keys(A), keys)
    if ((n = length(k))) {
        M.update = `TRUE'
        for (i=1; i<=n; i++) asarray_remove(A, k[i])
    }
}

/*---------------------------------------------------------------------------*/
/* Remove parts from dofile that do not need to be run                       */
/*---------------------------------------------------------------------------*/

void UpdateRunFlags(`Parts' P)
{
    `Int'     j
    `Str'     pid
    `BoolR'   up, dwn
    `AsArray' A
    
    up = dwn = P.run
    // upstream updating
    A = asarray_create()
    asarray_notfound(A, .)
    j = P.j
    for (;j;j--) asarray(A, P.id[j], j)
    j = P.j
    for (;j;j--) {
        if (P.run[j]==`FALSE') continue // nothing to do
        UpdateUpstream(P.pid, A, up, j)
    }
    // downstream updating
    A = asarray_create()
    asarray_notfound(A, J(1,0,.))
    j = P.j
    for (;j;j--) {
        // collect children
        pid = P.pid[j]
        if (pid==".") continue
        if (asarray_contains(A, pid)) continue
        asarray(A, pid, select(1..P.j, P.pid:==pid))
    }
    j = P.j
    for (;j;j--) {
        if (P.run[j]==`FALSE') continue // nothing to do
        UpdateDwnstream(P.id, A, dwn, j)
    }
    // store result
    P.run = (up+dwn):!=0
}

void UpdateUpstream(`StrR' pid, `AsArray' A, `BoolR' up, `Int' j0)
{
    `Int' j

    if (pid[j0]==".")  return // no parent
    j = asarray(A, pid[j0])
    if (j>=.)          return // parent not found; maybe issue error/warning?
    if (up[j]==`TRUE') return // already active
    up[j] = `TRUE'
    UpdateUpstream(pid, A, up, j)
}

void UpdateDwnstream(`StrR' id, `AsArray' A, `BoolR' dwn, `Int' j0)
{
    `IntC' c
    `Int'  j

    c = asarray(A, id[j0])
    j = length(c)
    for (;j;j--) {
        if (dwn[c[j]]==`TRUE') return // already active
        dwn[c[j]] = `TRUE'
        UpdateDwnstream(id, A, dwn, c[j])
    }
}

void RemovePartsFromDofile(`Main' M)
{   // note: assumes M.P.j>1
    `Int'  j, J, k, fh
    `IntR' l
    `StrC' S
    
    // read
    J = M.P.j
    fh = FOpen(M.dof.fn, "r")
    fseek(fh, 0, 1) // move to end of file
    l = (M.P.a[|2\J|], ftell(fh)) - M.P.a
    fseek(fh, 0, -1) // move to beginning of file
    k = 0
    S = J(J, 1, "")
    for (j=1; j<=J; j++) {
        if (M.P.run[j]) S[++k] = fread(fh, l[j]) // read part
        else            fseek(fh, l[j], 0)       // skip part
    }
    FClose(fh)
    // write
    fh = FOpen(M.dof.fn, "w", "", 1)
    for (j=1; j<=k; j++) fwrite(fh, S[j])
    FClose(fh, "")
}

/*---------------------------------------------------------------------------*/
/* collect Stata output                                                      */
/*---------------------------------------------------------------------------*/

// analyze log file
void Collect(`Main' M)
{
    `Int'    p
    `Str'    id, s
    `Source' F
    
    F.S = Cat(M.log.fn); F.n = rows(F.S)
    for (F.i=1; F.i<=F.n; (void) F.i++) {
        s = F.S[F.i]
        // look for Stata insert start
        if ((p=strpos(s, M.Ltag.S))) {
            // - get id
            id = substr(s, p+strlen(M.Ltag.S), .)
            if (!asarray_contains(M.S, id)) continue // no valid id
            // - collect results
            Collect_S(M, F, id)
        }
        // look for Graph
        else if ((p=strpos(s, M.Ltag.G))) {
            // - get id
            id = substr(s, p+strlen(M.Ltag.G), .)
            if (!asarray_contains(M.G, id)) continue // no valid id
            // - collect results
            Collect_G(M, id)
        }
        // look for inline expression start
        else if ((p=strpos(s, M.Ltag.I))) {
            // - get id
            id = substr(s, p+strlen(M.Ltag.I), .)
            if (!asarray_contains(M.I, id)) continue // no valid id
            // - collect results
            Collect_I(M, F, id)
        }
    }
}

// collect output form Stata insert and apply log texman
void Collect_S(`Main' M, `Source' F, `Str' id)
{
    `StrC'   C
    `pStata' S
    
    // find end
    (void) F.i++
    F.i0 = F.i
    for (; F.i<=F.n; F.i++) {
        if (strpos(F.S[F.i], M.Ltag.Send)) break
    }
    // copy log
    if (F.i>F.i0) {
        C = F.S[|F.i0 \ F.i-1|]
        C[1] = "{com}"+C[1]
    }
    else C = J(0, 1, "")
    // apply texman and add pointer to database
    S = asarray(M.S, id)
    S->log = &(Apply_Texman(C, S->O.linesize))
    S->tex = NULL
    // - certify
    if (S->O.certify==`TRUE') Collect_S_cert(*S, id)
}

// certify that output is still the same
void Collect_S_cert(`Stata' S, `Str' id)
{
    if (S.log0==NULL) {
        printf("(%s: no previous log available; certification skipped)\n", id)
        return
    }
    if (*S.cmd!=*S.cmd0) {
        printf("(%s: commands changed; certification skipped)\n", id)
        return
    }
    if (*S.log!=*S.log0) {
        printf("{err}\nnew version of log %s is different from previous version\n", id)
        Collect_S_cert_di(*S.log, *S.log0)
        printf("\n{err}certification error\n")
        exit(499)
    }
    //printf("%s: certification successful\n", id)
}

// compare logs and display (first) difference
void Collect_S_cert_di(`StrC' S1, `StrC' S0)
{
    `Int' i, j, r, r1, r0, a, b, l
    `Str' fmt
    
    r1 = rows(S1); r0 = rows(S0); r = max((r1,r0))
    for (i=1; i<=r; i++) {
        if (i>r0) break
        if (i>r1) break
        if (S1[i]!=S0[i]) break
    }
    if (i>r) return // should never happen
    printf("{err}(first) difference on line %g\n", i)
    printf("\n{err}extract from old version:\n")
    a = max((i-2,1)); b = min(((i+2),r))
    l = floor(log10(b))+1; fmt = "%"+strofreal(l)+"s"
    for (j=a; j<=b; j++) {
        if (j>r0) {
            display("end of file", 1)
            break
        }
        display(sprintf(fmt + ": %s", strofreal(j), S0[j]), 1)
    }
    printf("\n{err}extract from new version:\n")
    for (j=a; j<=b; j++) {
        if (j>r1) {
            display("end of file", 1)
            break
        }
        display(sprintf(fmt + ": %s", strofreal(j), S1[j]), 1)
    }
}

void Collect_G(`Main' M, `Str' id)
{
    `pGraph' G

    G = asarray(M.G, id)
    Copy_GRfiles(G->fn, G->O.dir, id, G->O.as, M.replace)
}
void Copy_GRfiles(`StrC' fn, `Str' dir, `Str' name, `StrC' as, `Bool' r)
{
    `Int' i, n

    if (!direxists(dir)) mkdir(dir)
    n = length(as)
    for (i=1; i<=n; i++) {
        if (!fileexists(fn[i])) continue
        stata("capt copy " + "`" + `"""' + fn[i] + `"""' + "'" + " " +
            "`" + `"""' + pathjoin(dir, name) + "." + 
            as[i] + `"""' + "'" + (r ? ", replace " : ""))
    }
}

// collect output form inline expression and apply log texman
void Collect_I(`Main' M, `Source' F, `Str' id)
{
    `Int'     i
    `StrC'    C
    `pInline' I
    
    // find end
    (void) F.i++
    F.i0 = F.i
    for (; F.i<=F.n; (void) F.i++) {
        if (strpos(F.S[F.i], M.Ltag.Iend)) break
    }
    // copy log
    if (F.i>F.i0) {
        C = F.S[|F.i0 \ F.i-1|]
        C[1] = "{com}"+C[1]
    }
    else C = J(0, 1, "")
    // apply texman and add to database
    C = Apply_Texman(C, 255)
    // find first line of output
    (void) Read_cmd(M, C, i = 1, rows(C), `FALSE', `FALSE')
    i++
    if (i<=rows(C)) {
        C = strtrim(C[i])
        if (C=="{\smallskip}") C = "" // display evaluated to empty string
    }
    else C = ""
    // add to database
    I = asarray(M.I, id)
    I->log = &C
}

// use log texman to translate SMCL to TeX
`StrC' Apply_Texman(`StrC' S, `Int' linesize)
{
    `Str' fn1, fn2, lsize
    
    fn1 = st_tempfilename()
    fn2 = st_tempfilename()
    Fput(fn1, S)
    if (linesize<.) lsize = strofreal(linesize)
    else            lsize = strofreal(st_numscalar("c(linesize)"))
    stata("qui log texman " + "`" + `"""' + fn1 + `"""' + "'" +
        "`" + `"""' + fn2 + `"""' + "'" + ", replace ll(" + lsize + ")")
    return(Cat(fn2))
}

/*---------------------------------------------------------------------------*/
/* apply formatting options / obtain command log                             */
/*---------------------------------------------------------------------------*/

void Format(`Main' M)
{
    `Int'  i, n
    `StrC' keys

    keys = asarray_keys(M.S)
    n = length(keys)
    for (i=1; i<=n; i++) _Format(M, keys[i])
}

void _Format(`Main' M, `Str' id)
{
    `pStata' S
    
    S = asarray(M.S, id)
    if (S->save!=`TRUE') S->save = `FALSE'     // save log on disc: initialize
    if (S->O.dosave==`TRUE') M.dosave = `TRUE' // set overall dosave flag
    if (S->O.code!=`TRUE') Format_log(M, *S)   // maybe omit formatting if quietly and log not used anywhere?
    else                   Format_clog(M, *S)
}

// apply formatting options to log
void Format_log(`Main' M, `Stata' S)
{
    `StrC' C
    
    if (S.log==NULL) return // no log file available
    if (S.tex!=NULL) return // nothing changed; no need to process log
    S.newlog = `TRUE'
    Striplog(M, S, C = *S.log)
    if (C!=*S.log) S.tex = &C
    else           S.tex = S.log
}

// process log file
void Striplog(`Main' M, `Stata' S, `StrC' f)
{
    `Bool'  inmata, hasoom
    `BoolC' p
    `Int'   i, j, r
    `IntM'  idx
    `Str'   s, prompt

    if ((r=rows(f))<1) return
    p = J(r,1,`TRUE')
    idx = J(r,4,.) // index table: start of cmd, end of cmd, end of output, has oom
    prompt = substr(f[1],1,2)
    if       (prompt==": ") inmata = `TRUE'
    else if  (prompt==". ") inmata = `FALSE'
    else                    exit(499)   // should never happen
    j = 0 // command counter
    hasoom = `FALSE'
    for (i=1; i<=r; i++) {
        s = strltrim(substr(f[i],3,.)) // strip prompt
        // handle STcnp
        if (s==M.tag.cnp) {
            if (i<r) f[i+1] = substr(f[i],1,2) + substr(f[i+1],3,.) // copy prompt
            f[i] = "\cnp"
            continue
        }
        if (!inmata) {
            // handle STqui
            if (s==M.Ltag.qui) {
                if (i<r) f[i+1] = substr(f[i],1,2) + substr(f[i+1],3,.) // copy prompt
                p[i] = `FALSE'
                continue
            }
            // handle SToom
            if (s==M.Ltag.oom) {
                if (i<r) f[i+1] = substr(f[i],1,2) + substr(f[i+1],3,.) // copy prompt
                p[i] = `FALSE'
                idx[j+1, 4] = 1
                hasoom = `TRUE'
                continue
            }
        }
        // read command line
        ++j
        idx[j, 1] = i   // first line of commands
        s = Read_cmd(M, f, i, r, inmata, S.O.nolb==`TRUE')
        idx[j, 2] = i   // last line of command
        if (S.O.nocommands==`TRUE') { // nocommands option
            p[|idx[j,1] \ i|] = J(i-idx[j,1]+1, 1, `FALSE')
        }
        else if (S.O.nogt==`TRUE' | S.O.noprompt==`TRUE') {
            for (i=idx[j, 1]; i<=idx[j, 2]; i++) {
                if (substr(f[i],1,2)==prompt & S.O.noprompt==`TRUE') 
                    f[i] = substr(f[i],3,.)
                else if (substr(f[i],1,2)=="> " & S.O.nogt==`TRUE')
                    f[i] = "  " + substr(f[i],3,.)
            }
        }
        // update mata status
        s = strtrim(s)                                                          // needed?
        if (!inmata) {
            if (substr(s,1,4)=="mata") { // "mata", "mata:", or "mata<blanks>:"
                s = substr(s,5,.)
                if (s=="")                  inmata = `TRUE'
                else if (strltrim(s)==":")  inmata = `TRUE'
                if (inmata)                 prompt = ": "
            }
        }
        else if (s=="end") {
            inmata = `FALSE'
            prompt = ". "
        }
        // move to next command
        while (i<r) {
            if (substr(f[i+1],1,2)==prompt) break
            i++
        }
        idx[j, 3] = i   // last line of output
    }
    idx = idx[|1,1\j,.|]
    // handle SToom
    if (hasoom) {
        for (j=1;j<=rows(idx);j++) {
            if (idx[j,4]!=1) continue
            _Striplog_oom(f, p, idx, j)
        }
    }
    // handle drop(), nooutput(), oom(), cnp()
    if (length(S.O.drop)) Striplog_edit(S.O.drop, f, p, idx, 1)
    if (length(S.O.noo))  Striplog_edit(S.O.noo,  f, p, idx, 2)
    if (length(S.O.oom))  Striplog_edit(S.O.oom,  f, p, idx, 3)
    if (length(S.O.cnp))  Striplog_edit(S.O.cnp,  f, p, idx, 4)
    // select relevant output and apply alert() and tag()
    f = select(f, p)
    Striplog_alert(f, S.O.alert)
    Striplog_tag(f, S.O.tag)
}

void Striplog_edit(`IntR' K, `StrC' f, `BoolC' p, `IntM' idx, `Int' opt)
{
    `Int' k, j, n
    
    n = rows(idx)
    for (k=1;k<=cols(K);k++) {
        j = K[k]
        if (j<0) j = n + j + 1
        else if (j==.) j = n
        if (j<1) continue
        if (j>n) continue
        if (opt==1)      Striplog_drop(p, idx, j)
        else if (opt==2) Striplog_noo(f, p, idx, j)
        else if (opt==3) Striplog_oom(f, p, idx, j)
        else if (opt==4) Striplog_cnp(f, p, idx, j)
    }
}

void Striplog_drop(`BoolC' p, `IntM' idx, `Int' j)
{
    `Int' a, b
    
    a = idx[j,1]; b = idx[j,3]
    p[|a \ b|] = J(b-a+1, 1, `FALSE')
}

void Striplog_noo(`StrC' f, `BoolC' p, `IntM' idx, `Int' j)
{
    `Int' a, b
    
    a = idx[j,2]+1; b = idx[j,3]
    if (f[b]=="{\smallskip}") b--  // do not remove last line
    if (a>b) return
    p[|a \ b|] = J(b-a+1, 1, `FALSE')
}

void Striplog_oom(`StrC' f, `BoolC' p, `IntM' idx, `Int' j)
{
    _Striplog_oom(f, p, idx, j)
    Striplog_noo(f, p, idx, j)
}

void _Striplog_oom(`StrC' f, `BoolC' p, `IntM' idx, `Int' j)
{
    `Int' i
    
    i = idx[j,2] // last line of command
    Striplog_insertrows(f, p, i, 2)
    f[i+1] = "{\smallskip}"; f[i+2] = "\oom"
    // update index table
    idx[|j,2\j,3|] = idx[|j,2\j,3|] :+ 2
    if (j<rows(idx)) idx[|j+1,1\.,3|] = idx[|j+1,1\.,3|] :+ 2
}

void Striplog_cnp(`StrC' f, `BoolC' p, `IntM' idx, `Int' j)
{
    `Int' i
    
    i = idx[j,3]
    Striplog_insertrows(f, p, i, 1)
    f[i+1] = "\cnp"
    // update index table
    if (j<rows(idx)) idx[|j+1,1\.,3|] = idx[|j+1,1\.,3|] :+ 1
}

void Striplog_insertrows(`StrC' f, `BoolC' p, `Int' i, `Int' n)
{
    if (i==rows(p)) {
        p = p \ J(n, 1, `TRUE')
        f = f \ J(n, 1, "")
    }
    else {
        p = p[|1 \ i|] \ J(n, 1, `TRUE') \ p[|i+1 \ .|]
        f = f[|1 \ i|] \ J(n, 1, "")     \ f[|i+1 \ .|]
    }
}

// add \alert{} to specified tokens
void Striplog_alert(`StrC' f, `Str' alert)
{
    `Int' i
    
    if (alert=="") return
    alert = tokens(alert)
    for (i=1; i<=length(alert); i++) {
        f = subinstr(f, alert[i], "\alert{" + alert[i] + "}")
    }
}

// add tags to specified tokens; last two tokens are the start and end tags
void Striplog_tag(`StrC' f, `Str' tag)
{
    `Int'    i, i0, j, l
    `Str'    start, stop, s
    `TokEnv' t
    
    if (tag=="") return
    t = tokeninit()
    tokenpchars(t,"=")
    tokenset(t, tag)
    tag = tokengetall(t)
    l = length(tag)
    i0 = 1
    for (j=1; j<=l; j++) {
        if (tag[j]=="=") {
            if (j==i0) continue // first element in list is "="
            if ((j+1)>l) start = ""
            else         start = Striplog_tag_noquotes(tag[j+1])
            if ((j+2)>l) stop  = ""
            else         stop  = Striplog_tag_noquotes(tag[j+2])
            for (i=i0; i<=(j-1); i++) {
                s = Striplog_tag_noquotes(tag[i])
                f = subinstr(f, s, start + s + stop)
            }
            j = j + 2
            i0 = j + 1
        }
    }
}
`Str' Striplog_tag_noquotes(`Str' s)
{
    if      (substr(s, 1, 1)==`"""')       s = substr(s, 2, strlen(s)-2)
    else if (substr(s, 1, 2)=="`" + `"""') s = substr(s, 3, strlen(s)-4)
    return(s)
}

// read command in log and optionally strip line break comments
// (numbered command lines in loops and programs: processes the
// entire block, but only returns the first command)
`Str' Read_cmd(`Main' M, `StrC' f, `Int' i, `Int' r, 
    `Bool' inmata, `Bool' lbstrip) 
{
    `Int'  lb, cb, j, num, stub
    `Str'  s, stmp, cmd
    
    stub = 2
    j = lb = cb = num = 0
    cmd = s = Read_cmdline(M, substr(f[i],3,.), cb, lb, inmata, "")
    while (1) {
        if (lbstrip) {
            if (lb) f[i] = substr(f[i], 1, stub) + substr(f[i], stub+1, lb-2)
            stub = 2
        }
        if (i==r) return(cmd)
        stmp = f[i+1]
        if (substr(stmp,1,2)!="> ") {
            if (substr(stmp,1,2)!=". ") {
                num = Check_numcmd(stmp, num, stub)
                if (num==0) return(cmd)
                j++; s = "" // start new command
            }
            else if (num==0) return(cmd)
            else stmp = substr(stmp,3,.)
        }
        else stmp = substr(stmp,3,.)
        i++
        stmp = Read_cmdline(M, stmp, cb, lb, inmata, s)
        s = s + (cb ? "" : (s!="" ? " " : "")) + stmp
        if (j==0) cmd = s
    }
    return(cmd)
}

// check whether line starts with "  #. " (loops and program definitions)
`Int' Check_numcmd(`Str' s, `Int' num, `Int' stub)
{
    num++
    if (_Check_numcmd(s, num, stub)==0) {
        if (num>1) return(0)
        num++ // loops (e.g. foreach) start with 2, not with 1
        if (_Check_numcmd(s, num, stub)==0) return(0)
    }
    return(num)
}
`Bool' _Check_numcmd(`Str' s, `Int' num, `Int' stub)
{
    `Bool' match
    `Int'  l, w
    `Str'  n
    
    n = strofreal(num)
    l = strlen(n)
    w = max((0, 3-l))
    stub = l+w+2
    match = substr(s, 1, stub)==(w*" "+n+". ")
    if (match) s = substr(s, stub+1, .)
    return(match)
}

// read a Stata command line and strip comments taking account of quotes
`Str' Read_cmdline(
    `Main' M,
    `Str'  s,          // command line to be parsed
    `Int'  cb,         // will be set to nesting level of /*...*/
    `Int'  lb,         // will be set to position of ///...
    `Bool' nostar,     // do not parse "*..."
    `Str'  cmd0)       // piece of command from previous line
{   
    `Str' cmd; `Unset' cmd
    
    if (cb==0) {
        if (substr(s,1,3)=="///") { // line starting with ///
            lb = 1
            return("")
        }
        if (substr(s,1,2)=="//") {  // line starting with //
            lb = 0
            return("")
        }
    }
    cmd = cmd + _Read_cmdline(M.t, s, cb, lb)
    if (nostar==`FALSE') {
        if (cmd0=="") {
            if (substr(strltrim(cmd),1,1)=="*") {   // line starting with *...
                cb = 0; lb = 0
                return(substr(cmd,1,strpos(cmd,"*")-1))
            }
        }
    }
    return(cmd)
}
`Str' _Read_cmdline(`Cmdline' t, `Str' s, `Int' cb, `Int' p)
{
    `Str' res; `Unset' res
    `Str' tok
    
    p = 0
    tokenset(t.t, s)
    while ((tok = tokenget(t.t))!="") {
        if (tok==t.l) cb++
        else if (cb) {
            if (tok==t.r) cb--
        }
        else {
            if (tok==t.lb) {
                p = p + 2  // skip to first "/"
                return(res)
            }
            if (tok==t.eol) break
            res = res + tok
        }
        p = p + strlen(tok)
    }
    p = 0
    return(res)
}

// code option: get copy of commands instead of output
void Format_clog(`Main' M, `Stata' S)
{
    if (S.tex!=NULL) return // nothing changed; no need to process log
    S.newlog = `TRUE'
    if (S.log==NULL) {
        if (S.O.verb==`TRUE') S.log = S.cmd 
        else S.log = &(Format_clog_texman(*S.cmd, S.O.linesize, M.lognm))
    }
    _Format_clog(M, S)
}

// code option: apply formatting options to clog
void _Format_clog(`Main' M, `Stata' S)
{
    S.tex = S.log // replace this with formatting routines
}

// code option: process commands by log texman
`StrC' Format_clog_texman(`StrC' S, `Int' linesize, `Str' lognm)
{
    `Str' fn1, fn2, lsize, lsize0
    
    fn1 = st_tempfilename()
    fn2 = st_tempfilename()
    Fput(fn1, S)
    lsize0 = strofreal(st_numscalar("c(linesize)"))
    if (linesize<.) {
        lsize = strofreal(linesize)
        stata("set linesize " + lsize)
    }
    else lsize = lsize0
    stata("quietly log using " + "`" + `"""' + fn2 + `"""' + "'" + 
        ", smcl replace name(" + lognm + ")")
    stata("type " + "`" + `"""' + fn1 + `"""' + "'")
    stata("quietly log close " + lognm)
    if (linesize<.) stata("set linesize " + lsize0)
    stata("qui log texman " + "`" + `"""' + fn2 + `"""' + "'" +
        "`" + `"""' + fn1 + `"""' + "'" + ", replace ll(" + lsize + ")")
    return(Cat(fn1))
}

/*---------------------------------------------------------------------------*/
/* generate main output file                                                 */
/*---------------------------------------------------------------------------*/

void Weave(`Main' M)
{
    `Int'  i, t
    `Int'  p; `Unset' p
    `Str'  s
    `StrC' F
    
    F = Cat(M.tex.fn)
    for (i=1; i<=rows(F); i++) {
        s = F[i]
        while ((t = Weave_findtag(M, s, p))) {
            if      (t==1) Weave_S(M, s, p) // Stata block
            else if (t==2) Weave_G(M, s, p) // graph
            else if (t==3) Weave_I(M, s, p) // inline expression
            else break // cannot happen
            p = .
        }
        fput(M.tgt.fh, s)
    }
}

`Int' Weave_findtag(`Main' M, `Str' s, `Int' p)
{
    `Int' t, p1
    
    t = 0
    if ((p1 = strpos(s, M.Ttag.S))>0) {
        if (p1<p) {
            p = p1; t = 1
        }
    }
    if ((p1 = strpos(s, M.Ttag.G))>0) {
        if (p1<p) {
            p = p1; t = 2
        }
    }
    if ((p1 = strpos(s, M.Ttag.I))>0) {
        if (p1<p) {
            p = p1; t = 3
        }
    }
    return(t)
}

void Weave_S(`Main' M, `Str' s, `Int' a)
{
    `Int'    l, b
    `Str'    id
    `pStata' S
    
    // parsing
    l = strlen(M.Ttag.S)
    b = strpos(substr(s, a+l, .), M.Ttag.Send)
    if (b==0) { // end tag not found
        fwrite(M.tgt.fh, substr(s, 1, a+l-1))
        s = substr(s, a+l, .)
        return
    }
    id = substr(s, a+l, b-1)
    l = a + l + b + strlen(M.Ttag.Send) - 2
    // check whether id is available
    if (!asarray_contains(M.S, id)) { // no such id in database
        fwrite(M.tgt.fh, substr(s, 1, l))
        s = substr(s, l+1, .)
        return
    }
    // write start of line
    fwrite(M.tgt.fh, substr(s, 1, a-1))
    s = substr(s, l+1, .)
    // add log to LaTeX file
    S = asarray(M.S, id)
    if (S->O.nobegin!=`TRUE') {
        if (S->O.Begin=="") {
            if (S->O.code==`TRUE' & S->O.verb==`TRUE') fwrite(M.tgt.fh, "\begin{stverbatim}")
            else if (S->O.beamer==`TRUE')              fwrite(M.tgt.fh, "\begin{stlog}[beamer]")
            else                                       fwrite(M.tgt.fh, "\begin{stlog}")
        }
        else fwrite(M.tgt.fh, S->O.Begin)
        if (S->O.statc==`TRUE') fput(M.tgt.fh, "")
    }
    if (S->O.statc!=`TRUE') {
        fwrite(M.tgt.fh, (S->O.code==`TRUE'&S->O.verb==`TRUE' ?
            "\verbatiminput{" : "\input{") + 
            pathjoin(S->O.logdir0, id) + ".log.tex}")
        S->save = `TRUE' // need to save log on disc
    }
    else {
        if (S->O.code==`TRUE'&S->O.verb==`TRUE') fput(M.tgt.fh, "\begin{verbatim}") 
        _Fput(M.tgt.fh, (S->tex!=NULL ? *S->tex : ("(error: log not available)")), 1)
        if (S->O.code==`TRUE'&S->O.verb==`TRUE') {
            fput(M.tgt.fh, "")
            fwrite(M.tgt.fh, "\end{verbatim}")
        }
    }
    if (S->O.noend!=`TRUE') {
        if (S->O.statc==`TRUE') fput(M.tgt.fh, "")
        if (S->O.End=="") {
            if (S->O.code==`TRUE' & S->O.verb==`TRUE') fwrite(M.tgt.fh, "\end{stverbatim}")
            else if (S->O.beamer==`TRUE')              fwrite(M.tgt.fh, "\end{stlog}")
            else                                       fwrite(M.tgt.fh, "\end{stlog}")
        }
        else fwrite(M.tgt.fh, S->O.End)
    }
}

void Weave_G(`Main' M, `Str' s, `Int' a)
{
    `Int'    l, b
    `Str'    id
    `pGraph' G

    // parsing
    l = strlen(M.Ttag.G)
    b = strpos(substr(s, a+l, .), M.Ttag.Gend)
    if (b==0) { // end tag not found
        fwrite(M.tgt.fh, substr(s, 1, a+l-1))
        s = substr(s, a+l, .)
        return
    }
    id = substr(s, a+l, b-1)
    l = a + l + b + strlen(M.Ttag.Gend) - 2
    // check whether id is available
    if (!asarray_contains(M.G, id)) {
        fwrite(M.tgt.fh, substr(s, 1, l))
        s = substr(s, l+1, .)
        return
    }
    // write start of line
    fwrite(M.tgt.fh, substr(s, 1, a-1))
    s = substr(s, l+1, .)
    // add graph to LaTeX file
    G = asarray(M.G, id)
    if (G->O.center==`TRUE') fwrite(M.tgt.fh, "\begin{center}")
    if (fileexists(pathjoin(G->O.dir, id) + "." + G->O.as[1])==0) {
        fwrite(M.tgt.fh, "\mbox{\tt (error:\ graph not available)}")
    }
    else if (G->O.epsfig==`TRUE') {
        fwrite(M.tgt.fh, "\epsfig{file=" + pathjoin(G->O.dir0, id) +
            (G->O.suffix==`TRUE' ? "." + G->O.as[1] : "") + 
            (G->O.args!="" ? "," + G->O.args : "") + "}")
    }
    else {
        fwrite(M.tgt.fh, "\includegraphics")
        if (G->O.args!="") fwrite(M.tgt.fh, "[" + G->O.args + "]")
        fwrite(M.tgt.fh, "{" + pathjoin(G->O.dir0, id) + 
            (G->O.suffix==`TRUE' ? "." + G->O.as[1] : "") + "}")
    }
    if (G->O.center==`TRUE') fwrite(M.tgt.fh, "\end{center}")
}

void Weave_I(`Main' M, `Str' s, `Int' a)
{
    `Int'     l, b
    `Str'     id
    `pInline' I
    
    // parsing
    l = strlen(M.Ttag.I)
    b = strpos(substr(s, a+l, .), M.Ttag.Iend)
    if (b==0) {
        fwrite(M.tgt.fh, substr(s, 1, a+l-1))
        s = substr(s, a+l, .)
        return
    }
    id = substr(s, a+l, b-1)
    l = a + l + b + strlen(M.Ttag.Iend) - 2
    // check whether id is available
    if (!asarray_contains(M.I, id)) {
        fwrite(M.tgt.fh, substr(s, 1, l))
        s = substr(s, l+1, .)
        return
    }
    // write start of line
    fwrite(M.tgt.fh, substr(s, 1, a-1))
    s = substr(s, l+1, .)
    // add result to LaTeX file
    I = asarray(M.I, id)
    fwrite(M.tgt.fh, (I->log!=NULL ? *I->log : 
        ("\mbox{\tt (error:\ result not available)}")))
}

/*---------------------------------------------------------------------------*/
/* create external log files                                                 */
/*---------------------------------------------------------------------------*/

void External_logfiles(`Main' M)
{
    `Int'    i
    `Str'    id, fn
    `StrC'   keys
    `BoolC'  p
    `pStata' S
    
    keys = asarray_keys(M.S)
    p = J(rows(keys), 1, `FALSE')
    for (i=1; i<=length(keys); i++) {
        S = asarray(M.S, keys[i])
        if (S->O.statc==`TRUE') continue
        if (S->save==`TRUE') p[i] = `TRUE'
    }
    keys = select(keys, p)
    if (length(keys)==0) return // nothing to do
    for (i=1; i<=length(keys); i++) {
        id = keys[i]
        S = asarray(M.S, keys[i])
        fn = pathjoin(S->O.logdir, id) + ".log.tex"
        if (S->newlog!=`TRUE') {
            if (fileexists(fn)) continue
        }
        if (!direxists(S->O.logdir)) mkdir(S->O.logdir)
        Fput(fn, (S->tex!=NULL ? *S->tex :
            ("(error: log not available)" \ "{\smallskip}")))
    }
}

/*---------------------------------------------------------------------------*/
/* create external do files                                                  */
/*---------------------------------------------------------------------------*/

void External_dofiles(`Main' M)
{
    `Int'    i
    `Str'    id, fn
    `StrC'   keys
    `BoolC'  p
    `pStata' S

    if (M.dosave==`FALSE') return // nothing to do
    keys = asarray_keys(M.S)
    p = J(rows(keys), 1, `FALSE')
    for (i=1; i<=length(keys); i++) {
        S = asarray(M.S, keys[i])
        if (S->O.dosave!=`TRUE') continue
        p[i] = `TRUE'
    }
    keys = select(keys, p)
    if (length(keys)==0) return // nothing to do
    for (i=1; i<=length(keys); i++) {
        id = keys[i]
        S = asarray(M.S, keys[i])
        fn = pathjoin(S->O.dodir, id) + ".do"
        if (S->newcmd!=`TRUE') {
            if (fileexists(fn)) continue
        }
        if (!direxists(S->O.dodir)) mkdir(S->O.dodir)
        Fput(fn, *S->cmd)                                  // also need to apply some stripping (//SToom etc.)
    }
}

/*---------------------------------------------------------------------------*/
/* helper function for parsing etc.                                          */
/*---------------------------------------------------------------------------*/

// read argument within <l> and <r>, with <l><r> either {} or []
// - takes account of quotes and nested <l><r>
// - exits if first significant character (i.e. other than blank or char(9))
//   is not <l>
// - continues reading subsequent lines until closing <r> is found
// - return codes in optional rc: 0 ok, 1 does not start with l, 2 end not found
`Str' Get_Arg(`Main' M, `Str' l, `Str' r, `Source' F, | `Int' rc)
{
    `Int' n, i0
    `Str' tok, backup
    `Str' arg;`Unset' arg
    
    if (tokenpeek(M.t1)!=l) { // exit if no opening l
        rc = 1
        return("")
    }
    backup = tokenrest(M.t1)
    tokenset(M.t2, backup)
    n = 0
    while ((tok = tokenget(M.t2))!="") { // strip opening l
        if (tok==l) {
            n = 1
            break
        }
    }
    i0 = F.i
    while (1) {
        while ((tok = tokenget(M.t2))!="") {
            if      (tok==l) n++
            else if (tok==r) n--
            if (n==0) break
            arg = arg + tok
        }
        if (n==0) break
        if (F.i==F.n) break // end of file
        (void) F.i++
        tokenset(M.t1, F.S[F.i])
        tok = tokenget(M.t1)
        //if (tok=="") break // stop at empty line
        if (tok==M.tag.endinput) break
        tokenset(M.t2, F.S[F.i]) // get next line
        arg = arg + " " // add space for line break
    }
    if (n>0) { // end not found, move back to start and return empty string
        rc = 2
        F.i = i0
        tokenset(M.t1, backup)
        return("")
    }
    rc = 0
    tokenset(M.t1, tokenrest(M.t2)) // copy remainder of line
    return(arg)
}

// replace tabs with spaces and trim 
`Str' TabTrim(`Str' s)
{
    return(strtrim(subinstr(s, char(9), " ")))
}

// display lines of source file that caused error
void ErrorLines(`Source' F)
{
    `Int' i
    
    if (F.i0==F.i) printf("{err}error on line %g: %s\n", F.i, F.S[F.i0])
    else {
        printf("{err}error on lines %g-%g:\n", F.i0, F.i)
        for (i=F.i0; i<=F.i; i++) printf("{err}    %s\n", F.S[i])
    }
}

// complement of B in A (elements in A that are not in B)
// result: 
//     0 x 0 if A is 1 x 1 and n = 0
//     n x 1 if A is r x 1
//     1 x n if A is 1 x c
//     where n is the number of remaining elements
`StrM' Complement(`StrV' A, `StrV' B)
{
    `Int'   i, j, r, c
    `BoolV' k
    `IntC'  p
    `Str'   l, l0, s, a, b
    `StrM'  S, s0
    
    if (!length(A)) return(A)
    if (!length(B)) return(A)
    k = J(r = rows(A), c = cols(A), 0)
    a = "0"; b = "1"
    if (c==1)       S = A,  J(r, 1, a)
    else            S = A', J(c, 1, a)
    if (cols(B)==1) S = S \ (B,  J(rows(B), 1, b))
    else            S = S \ (B', J(cols(B), 1, b))
    p = order(S, (1, 2))
    l0 = b; s0 = J(0, 0, "")
    for (i=rows(p); i; i--) {
        s = S[p[i],1]; l = S[p[i],2]
        if (s!=s0)  j = 0
        if (l==b)   j++
        else if (j) j--
        else        k[p[i]] = 1
        swap(s, s0); swap(l, l0) 
    }
    if (c==1) return(select(A, k))
    return(select(A', k')')
}

// turn number into letter (1=a, 2=b, ..., 26=z, 27=aa, 28=ab, ...)
`Str' NumToLetter(`Int' n0)
{
    `Int' n
    `Str' abc
    `Str' res; `Unset'  res
    
    n = n0
    abc = "abcdefghijklmnopqrstuvwxyz"
    while (n>0) {
        res = substr(abc, mod(n-1, 26) + 1, 1) + res
        n = ceil(n/26) - 1
    }
    return(res)
}

/*---------------------------------------------------------------------------*/
/* helper functions for file I/O                                             */
/*---------------------------------------------------------------------------*/

// read file; simplified cat() that pushes file handle to local macro
`StrC' Cat(`Str' filename)
{
    `Int'  i, n, fh
    `StrM' EOF
    `StrC' res
    `Str'  line

    EOF = J(0, 0, "")
    fh = FOpen(filename, "r")
    // count lines
    i = 0
    while (1) {
        if (fget(fh)==EOF) break
        i++ 
    }
    res = J(n = i, 1, "")
    // read file
    fseek(fh, 0, -1)
    for (i=1; i<=n; i++) {
            if ((line=fget(fh))==EOF) {
                    /* unexpected EOF -- file must have changed */
                    FClose(fh)
                    if (--i) return(res[|1\i|])
                    return(J(0,1,""))
            }
            res[i] = line
    }
    FClose(fh)
    return(res)
}

// write colvector to file
void Fput(`Str' fn, `StrC' S)
{
    `Int' fh
    
    fh = FOpen(fn, "w", "", 1)
    _Fput(fh, S)
    FClose(fh, "")
}
void _Fput(`Int' fh, `StrC' S, | `Bool' nolb)
{
    `Int' i
    
    if (nolb==`TRUE') {  // leave last line open
        for (i=1; i<=rows(S)-1; i++) fput(fh, S[i])
        if (rows(S)>0)               fwrite(fh, S[i])
        return
    }
    for (i=1; i<=rows(S); i++) fput(fh, S[i])
}

// display error if file already exists (unless replace)
void Fexists(`Str' fn, `Bool' replace)
{
    if (replace) return
    if (fileexists(fn)) {
        display("{err}file " + fn + " already exists")
        exit(602)
    }
}

// return path from filename in local path
void Get_Path(`Str' fn)
{
    `Str' path;     `Unset' path
    `Str' basename; `Unset' basename
    
    pathsplit(fn, path, basename)
    st_local("path", path)
}

// open file and record file handle in local macro; also update local macro
// containing list of local macros containing file handles
real scalar FOpen(`Str' fn, `Str' mode, | `Str' id, `Bool' unlink)
{
    `Int'  fh
    `Str'  lname
    `StrR' lnames
    
    lname = "MataFH" + (id!="" ? "_" + id : "")
    lnames = tokens(st_local("MataFHs"))
    if (unlink==1) _FOpen(fn, fh, mode)
    else           fh = fopen(fn, mode)
    st_local(lname, strofreal(fh))
    if (length(Complement(lname, lnames))) {
        lnames = lnames, lname
        st_local("MataFHs", invtokens(lnames))
    }
    return(fh)
}

// robust unlink()->fopen(); based on suggestion by W. Gould; the problem is
// that, on Windows, fopen() may fail if applied directly after unlink() 
// (usually caused by a virus scanner); the function below retries
// to open the file until a maximum delay of 100 milliseconds
void _FOpen(`Str' fn, `Int' fh, `Str' mode)
{
    `Int' cnt

    if (fileexists(fn)) {
        unlink(fn)
        for (cnt=1; (fh=_fopen(fn, mode))<0; cnt++) {
            if (cnt==10) {
                fh = fopen(fn, mode)
                break
            }
            stata("sleep 10")
        }
        return
    }
    fh = fopen(fn, mode)
}

// close file and remove local macro containing file handle; also update local 
// macro containing list of local macros containing file handles
void FClose(`Int' fh, | `Str' id)
{
    `Str'  lname
    `StrR' lnames
    
    lname = "MataFH" + (id!="" ? "_" + id : "")
    lnames = tokens(st_local("MataFHs"))
    fclose(fh)
    st_local(lname, "")
    lnames = Complement(lnames, lname)
    if (length(lnames)==0) lnames = ""
    else                   lnames = invtokens(lnames)
    st_local("MataFHs", lnames)
}

// close files that may have been left open in case of break or error
void CloseOpenFHsAndExit(`Int' rc)
{
    `Int'  i, fh
    `StrR' lnames
    
    if (rc==0) return
    lnames = tokens(st_local("MataFHs"))
    for (i = length(lnames); i; i--) {
        fh = strtoreal(st_local(lnames[i]))
        if (fh<.) {
            (void) _fclose(fh)
            st_local(lnames[i], "")
        }
    }
    st_local("MataFHs", "")
    exit(rc)
}

/*---------------------------------------------------------------------------*/
/*  typesetting                                                              */
/*---------------------------------------------------------------------------*/

void PDFlatex_success(`Str' fn)
{
    `Int' fh
    
    fh = FOpen(fn, "r")
    fseek(fh, -40, 1)
    if (strpos(fget(fh),"no output PDF file produced")) st_local("success","0")
    else                                                st_local("success","1")
    FClose(fh)
}

void Checkbibtex(`Str' fn)
{
    `Int'  fh
    `Str'  line
    
    fh = FOpen(fn, "r")
    while ((line=fget(fh))!=J(0,0,"")) {
        if (strpos(line,"\citation{")) {
            st_local("bibtex","bibtex")
            break
        }
    }
    FClose(fh)
}

end

exit
