*! version 1.1.9  19jan2024  Ben Jann

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
    version `caller': Process process `macval(0)'
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
    _parse comma args opts: 0
    gettoken tgt args : args
    if `"`args'"'!="" error 198
    Process extract `macval(0)'
end

program Process, rclass
    local caller : di _caller()
    // syntax
    gettoken extract 0 : 0   // strip process/extract
    if `"`extract'"'!="extract" local extract ""
    _parse comma args 0 : 0
    gettoken src args : args // source file
    mata: AddSuffixToSourcefile()
    confirm file `"`src'"'
    _collect_overall_options `0'
    _collect_typeset_options, `macval(options)'
    local options0 `macval(options)'
    local StartAtLine 1
    nobreak {
        if "`extract'"!="" {
            local savingextract `"`saving'"'
            local savingreplace `"`replace'"'
        }
        capt n break mata: GetInitFromSourcefile()  // parse %STinit
        mata: CloseOpenFHsAndExit(`=_rc')
        if "`extract'"!="" {
            // ignore saving() and replace from %STinit in case of sttex extract
            local saving `"`savingextract'"'
            local replace `"`savingreplace'"'
        }
    }
    local options1 `macval(options)'
    local typeset `typeset' `typeset2' `view' `view2'
    local typesetopts `jobname' `cleanup' `nobibtex' `bibtex' /*
        */ `nomakeindex' `makeindex'
    mata: PrepareFilenames()
    // run main routine
    if "`extract'"!="" {
        // extract stata code; do not maintain db, do not typeset
        local nodb nodb
        local typeset ""
    }
    local pwd     `"`c(pwd)'"'
    local cmore   `"`c(more)'"'
    local crmsg   `"`c(rmsg)'"'
    local clisize `"`c(linesize)'"'
    nobreak {
        if "`more'"=="" set more off
        else            set more on
        if "`rmsg'"=="" set rmsg off
        else            set rmsg on
        capt n break mata: Process()
        local rc = _rc
        if `"`lognm'"'!="" {
            capt log close `lognm'
        }
        capt cd `pwd'
        capt set more `cmore'
        capt set rmsg `crmsg'
        capt set linesize `clisize'
        if `rc' set output proc  // make sure that output is on
        mata: CloseOpenFHsAndExit(`rc')
    }
    // returns
    _make_displaylink `"`tgt'"' // returns local link
    di as txt `"(target file saved as {`link':`tgt'})"'
    // typeset
    if `"`typeset'"'!="" {
        Typeset using `"`tgt'"', `typeset' `typesetopts'
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
    local opts Replace NOCD NOSTOP more rmsg reset NODB
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

program _collect_do_options
    local opts DO CERTify DOSave TRIM OUTput EXTRact GAP TItle
    foreach o of local opts {
        local noopts `noopts' NO`o'
    }
    syntax [, `noopts' `opts' ///
        logdir(str) ///
        dodir(str) ///
        LInesize(numlist int max=1 >=40 missingok) ////
        TRIM2(numlist int max=1 >=0 missingok) ///
        TItle2(str) GRopts(str asis) FILEopts(str asis) * ]
    if "`linesize'"!="" {
        if `linesize'>255 & `linesize'<. {
            di as err "linesize() invalid -- invalid number, outside of allowed range"
            exit 125
        }
    }
    if `"`trim2'"'!=""   local trim trim
    else if "`trim'"!="" local trim2 .
    if `"`title2'"'!=""  local title title
    foreach o of local opts {
        local opt = strlower("`o'")
        if "``opt''"!="" & "`no`opt''"!="" {
            di as err "`opt' and no`opt' not both allowed"
            exit 198
        }
        c_local `opt' `no`opt'' ``opt''
    }
    c_local logdir   `"`logdir'"'
    c_local dodir    `"`dodir'"'
    c_local linesize `linesize'
    c_local trim2    `trim2'
    c_local title2   `"`macval(title2)'"'
    c_local gropts   `"`macval(gropts)'"'
    c_local fileopts `"`macval(fileopts)'"'
    c_local options  `"`macval(options)'"'
end

program _collect_log_options
    local opts CODE LB GT LNUMbers LCONTinue COMmands PRompt /*
        */ LSkip TEXman VERBatim STATic BEGIN END BEAMER
    foreach o of local opts {
        local noopts `noopts' NO`o'
    }
    syntax [, `noopts' `opts' ///
        range(numlist int max=2 >=0 missingok ascending) ///
        ltag(str asis) ///
        tag(str asis) ///
        alert(str asis) ///
        SUBStitute(str asis) ///
        LNUMbers2(passthru) ///
        drop(numlist int missingokay) ///
        cnp(numlist int missingokay) ///
        qui(numlist int missingokay) ///
        oom(numlist int missingokay) ///
        CLsize(numlist int max=1 >=40 <=255) ////
        BEGIN2(str asis) ///
        END2(str asis) ///
        scale(numlist max=1 >0 missingok) ///
        BLstretch(numlist max=1 missingok) ]
    _collect_parse_range `range'
    if `"`lnumbers2'"'!=""  local lnumbers lnumbers
    if `"`begin2'"'!=""     local begin begin
    if `"`end2'"'!=""       local end   end
    foreach o of local opts {
        local opt = strlower("`o'")
        if "``opt''"!="" & "`no`opt''"!="" {
            di as err "`opt' and no`opt' not both allowed"
            exit 198
        }
        c_local `opt' `no`opt'' ``opt''
    }
    c_local range      `range'
    c_local ltag       `"`macval(ltag)'"'
    c_local tag        `"`macval(tag)'"'
    c_local alert      `"`macval(alert)'"'
    c_local substitute `"`macval(substitute)'"'
    c_local drop       `drop'
    c_local cnp        `cnp'
    c_local qui        `qui'
    c_local oom        `oom'
    c_local clsize     `clsize'
    c_local begin2     `"`macval(begin2)'"'
    c_local end2       `"`macval(end2)'"'
    c_local scale      `scale'
    c_local blstretch  `blstretch'
    // handle lsuffix
    if `"`lnumbers2'"'!="" {
        local 0 `", `lnumbers2'"'
        syntax [, lnumbers2(str) ]
        local haslsuffix haslsuffix
        c_local haslsuffix haslsuffix
    }
    c_local lnumbers2  `"`macval(lnumbers2)'"'
    c_local haslsuffix `haslsuffix'
end

program _collect_graph_options
    local opts CENTER SUFfix EPSFIG
    foreach o of local opts {
        local noopts `noopts' NO`o'
    }
    syntax [, `noopts' `opts' ///
        as(str) ///
        name(str) ///
        dir(str) ///
        OVERRide(passthru) ///
        ARGs(passthru) ]
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
    c_local gr_dir  `"`dir'"'
    local 0 ","
    foreach o in override args {
        c_local gr_has`o' `"``o''"'
        local 0 `"`0' ``o''"'
    }
    syntax [, override(str) args(str) ]
    c_local gr_args     `"`args'"'
    c_local gr_override `"`override'"'
end

program _collect_cfile_options
    local opts ERASE STATIC 
    foreach o of local opts {
        local noopts `noopts' NO`o'
    }
    syntax [, `noopts' `opts' ///
        range(numlist int max=2 >=0 missingok ascending) ///
        SUBStitute(str asis) ]
    _collect_parse_range `range'
    foreach o of local opts {
        local opt = strlower("`o'")
        if "``opt''"!="" & "`no`opt''"!="" {
            di as err "`opt' and no`opt' not both allowed"
            exit 198
        }
        c_local `opt' `no`opt'' ``opt''
    }
    c_local range      `range'
    c_local substitute `"`macval(substitute)'"'
end

program _collect_parse_range
    if `"`0'"'=="" exit
    gettoken from : 0
    if `from'>=. {
        di as err "range() invalid -- {it:from} may not be missing"
        exit 127
    }
    if `: list sizeof 0'==1 {
        c_local range `0' .
    }
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
                local exts aux bbl blg ilg ind lof log lot nav out snm toc vrb
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
// - real
local Real      real scalar
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
local pM        pointer matrix
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
local ETAG      ETAG
local Etag      struct `ETAG' scalar
// - structures for parts and inserts
local PARTS     PARTS
local Parts     struct `PARTS' scalar
// - structures for code blocks 
local CODE      CODE
local Code      struct `CODE' scalar
local pCode     pointer(`Code') scalar
local COPT      COPT
local Copt      struct `COPT' scalar
local CODE0     CODE0
local Code0     struct `CODE0' scalar
local pCode0    pointer(`Code0') scalar
// - structures for logs
local LOG       LOG
local Log       struct `LOG' scalar
local pLog      pointer(`Log') scalar
local LOPT      LOPT
local Lopt      struct `LOPT' scalar
local LNUM      LNUM
local Lnum      struct `LNUM' scalar
// - structures for graphs
local GRAPH     GRAPH
local Graph     struct `GRAPH' scalar
local pGraph    pointer(`Graph') scalar
local GOPT      GOPT
local Gopt      struct `GOPT' scalar
// - structures for collected files
local CFILE     CFILE
local CFile     struct `CFILE' scalar
local pCFile    pointer(`CFile') scalar
local CFOPT     CFOPT
local CFopt     struct `CFOPT' scalar
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
    `File'      tgt,        // target file
                db,         // database file
                dof,        // temporary do file
                tex,        // temporary tex file
                log         // temporary log file
    `Bool'      nocd,       // do not change directory for execution of do-file
                replace,    // whether replace was specified
                reset,      // eliminate preexisting database
                nodb,       // do not keep database
                update,     // whether database needs updating
                logsave,    // whether any logs need saving
                cfsave,     // whether any collected files need saving
                dosave,     // whether dosave option active for any code block
                run         // whether to run sttex or only extract code
    `Int'       c,          // counter for code blocks (within part)
                g,          // counter for graphs (within block)
                cf,         // counter for collected files (within block)
                i,          // counter for inline expressions (within part)
                lnum        // line number counter
    `Str'       lognm,      // Stata name of main log
                srcdir,     // path of source file
                tgtdir,     // path of output file
                punct       // punctuation for composite names
    `Tag'       tag         // input tags
    `Itag'      Itag        // inline expression tags
    `Ltag'      Ltag        // weaving tags in log file
    `Ttag'      Ttag        // weaving tags in LaTeX file
    `Etag'      Etag        // default log environment tags
    `Parts'     P           // info on parts
    `Copt'      Copt        // default options for code blocks
    `Lopt'      Lopt        // default options for logs
    `Gopt'      Gopt        // default options for graphs
    `CFopt'     CFopt       // default options for collected files
    `TokEnv'    t1,         // tokeninit() for reading first token of input lines
                t2          // tokeninit() for reading argument within {} or []
    `Cmdline'   t           // tokeninit() for reading Stata command lines
    `AsArray'   C,          // associative array for code blocks
                C0,         // associative array for certification
                L,          // associative array for logs
                G,          // associative array for graphs
                CF,         // associative array for collected files
                I,          // associative array for inline expressions
                Lcnt,       // log counter (number of logs per code block)
                Ltex        // tex-formated log of code block
    `StrC'      Ckeys,  Ckeys0,   // keys of code blocks
                Lkeys,  Lkeys0,   // keys of logs
                Gkeys,  Gkeys0,   // keys of graphs
                CFkeys, CFkeys0,  // keys of collected files
                Ikeys,  Ikeys0    // keys of inline expressions
    `Int'       ckeys,      // length of Ckeys
                lkeys,      // length of Lkeys
                gkeys,      // length of Gkeys
                cfkeys,     // length of CFkeys
                ikeys       // length of Ikeys
}

// structure for files
struct `FILE' {
    `Str'       fn,         // file name
                id          // id for local macro containing file handle
    `Int'       fh          // file handle
}

// structure for contents of input file
struct `SOURCE' {
    `Str'       fn          // file name
    `Int'       i,          // current line
                i0,         // first line of current parsing block
                n           // number of lines
    `StrC'      S           // file contents
}

// structure for input tags
struct `TAG' {
    `Str'       st,         // prefix of %ST-tags
                part,       // %STpart
                set,        // %STset
                ignore,     // %STignore
                endignore,  // %STendignore
                remove,     // %STremove
                endremove,  // %STendremove
                cs,         // LaTeX command start (backslash)
                Begin,      // \begin{}
                End,        // \end{}
                stdo,       // \do<keyword>{}
                stlog,      // \stlog{}
                stlogq,     // \stlog*{}
                stgraph,    // \stgraph{}
                stgraphq,   // \stgraph*{}
                stcfile,    // \stfile{}
                stcfileq,   // \stfile*{}
                stres,      // \stres{}
                stinput,    // \stinput{}
                stappend,   // \stappend{}
                endinput,   // \endinput
                ST,         // prefix of //ST-tags
                cnp,        // STcnp
                qui,        // STqui
                oom         // SToom
    `StrC'      env         // keyword in \begin{}...\end{}
}

// inline expression tags: tags within \stres{{}}
struct `ITAG' {
    `Str'       log,        // log include
                lognm,      // log name
                graph,      // graph include
                graphnm,    // graph name (without suffix)
                cfile,      // collected file include
                cfilenm     // collected file name
}

// weaving tags in log file
struct `LTAG' {
    `Str'       C,          // code block start
                Cend,       // code block end
                G,          // graph
                CF,         // collected file
                I,          // inline result start
                Iend,       // inline result stop
                ST,         // log prefix of //STtags
                cnp,        // STcnp
                qui,        // STqui
                oom         // SToom
}

// weaving tags in LaTeX file
struct `TTAG' {
    `Str'       L,          // log start
                Lend,       // log end
                G,          // graph start
                Gend,       // graph end
                CF,         // collected file start
                CFend,      // collected file end
                I,          // inline result start
                Iend        // inline result stop
}

// default log environment tags
struct `ETAG' {
    `StrR'      log,        // results log
                logb,       // results log beamer
                code,       // code log
                codeb,      // code log beamer
                verb,       // verbatim code
                verbb       // verbatim code beamer
}

// structure for information on parts
struct `PARTS' {
    `Int'       j           // part counter
    `StrC'      id,         // part ids
                pid         // id of parent part
    `BoolC'     run         // whether to run part
    `IntC'      l           // length (bytes) of part in do-file
}

// structure for code blocks
struct `CODE' {
    `Bool'      newcmd,     // whether commands changed
                newlog,     // whether log was refreshed
                mata        // is Mata code
    `Copt'      O           // settings and options
    `pStrC'     cmd,        // commands
                log         // smcl log
}

// structure of code blocks for certfication
struct `CODE0' {
    `pStrC'     cmd,        // commands
                log         // smcl log
    `Int'       linesize    // width of output log
}

// struct for code block options
struct `COPT' {
    `Bool'      nodo,       // do not run the commands
                certify,    // compare results against existing version
                dosave,     // whether to store commands in a do-file
                notrim,     // do not remove indentation
                nooutput    // set output proc / set output inform
    `Int'       trim,       // max. levels of indentation to remove
                linesize    // width of output log
    `Str'       logdir,     // path of log file
                dodir       // path of do file
    // extract options (added in version 1.1.9; the options are only used
    // by -sttex extract-, which does not read the db; this implies that use of
    // sb written by version 1.1.8 does not lead to error in current version)
    `Bool'      noextract,  // omit from extract
                nogap,      // omit empty line before code block
                notitle     // omit name or title of code block
    `Str'       title       // use specified title instead of name
}

// structure for logs
struct `LOG' {
    `Bool'      newlog,    // whether log changed
                save       // whether log needs to be saved on disc
    `Lopt'      O          // options
    `pStrC'     log        // processed LaTeX log
    `Lnum'      Lnum       // line numbers
    `StrC'      ids,       // list if ids of relevant code blocks
                lhs,       // line suffix from ltag()
                rhs        // line prefix from ltag()
}

// structure for line numbers
struct `LNUM' {
    `Int'       i0         // offset
    `IntC'      idx,       // line numbers
                p          // permutation vector of lines that have line numbers
}

// structure for log options
struct `LOPT' {
    `Bool'      code,       // include copy of commands instead of output log
                nolb,       // strip line break comments from log
                nogt,       // strip line continuation symbols from log
                lnumbers,   // add line numbers
                lcont,      // continued line numbers
                nocommands, // strip commands from log
                noprompt,   // strip command prompt
                nolskip,    // do not replace blank lines in code log
                notex,      // do not apply log texman to code log
                verb,       // enclode codel log in verbatim environment
                statc,      // copy log into LaTeX file 
                nobegin,    // omit stlog environment begin
                noend,      // omit stlog environment end
                beamer      // use environment tags for beamer
    `IntR'      range,      // range of lines to be included
                drop,       // indices of commands to be removed
                cnp,        // indices of commands after which to insert \cnp
                qui,        // indices of commands from which to delete output
                oom         // indices of commands for which to insert \oom
    `StrM'      ltag,       // apply custom tags to specified lines
                tag,        // apply custom tags to specified strings
                subst       // apply specified substitutions 
    `StrC'      alert       // enclose specified strings in \alert{}
    `Str'       Begin,      // environment begin
                End,        // environment end
                logdir,     // path of log file
                lsuffix     // suffix for line numbers
    `Int'       clsize      // linesize for (non-verbatim) code log
    `Real'      scale,      // rescaling factor
                blstretch   // line spacing
}

// structure for graphs
struct `GRAPH' {
    `Gopt'      O          // options
    `StrC'      fn         // tempfiles containing graph
}

// structure for graph options
struct `GOPT' {
    `Bool'      center,    // whether to include in center environment
                suffix,    // whether to add file suffix
                epsfig     // whether to use \epsfig{}
    `StrC'      as         // graph formats
    `Str'       name,      // name of graph window
                override,  // override options for graph command
                dir,       // path of graph files
                args       // arguments for \includegraphics
}

// structure for collected files
struct `CFILE' {
    `Bool'      newfile,   // whether file changed
                save       // whether file needs to be saved on disc
    `CFopt'     O          // options
    `Str'       fn         // tempfile containing collected file
    `pStrC'     S0,        // contents of collected file
                S          // edited contents of collected file
}

// structure for collected files
struct `CFOPT' {
    `Bool'      erase,     // whether to erase original
                nostatic   // whether to copy contents into LaTeX file
    `IntR'      range      // range of lines to be included
    `StrM'      subst      // apply specified substitutions
    `Str'       fn,        // name of original file
                logdir     // path to store edited file
}

// structure for inline expressions
struct `INLINE' {
    `pStr'      cmd,  // command
                log   // LaTeX log
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
    `Str' suf
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
    suf = st_local("extract")!="" ? ".do" : ".tex"
    tgt = st_local("saving")
    if (tgt=="")                  tgt = pathrmsuffix(srcnm) + suf
    else if (pathsuffix(tgt)=="") tgt = tgt + suf
    if (!pathisabs(tgt)) tgt = pathjoin(srcdir, tgt)
    if (src==tgt) {
        errprintf("target file can not be the same as the source file\n")
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
    ParseSrc(M = Initialize(),
        ImportSrc(st_local("src"), strtoreal(st_local("StartAtLine"))))
    
    // truncate containers
    M.P.id  = M.P.id[|1\M.P.j|]
    M.P.pid = M.P.pid[|1\M.P.j|]
    M.P.run = M.P.run[|1\M.P.j|]
    M.P.l   = M.P.l[|1\M.P.j|]
    if (M.ckeys)  M.Ckeys  = M.Ckeys[|1\M.ckeys|]
    if (M.lkeys)  M.Lkeys  = M.Lkeys[|1\M.lkeys|]
    if (M.gkeys)  M.Gkeys  = M.Gkeys[|1\M.gkeys|]
    if (M.cfkeys) M.CFkeys = M.CFkeys[|1\M.cfkeys|]
    if (M.ikeys)  M.Ikeys  = M.Ikeys[|1\M.ikeys|]

    // extract stata code
    if (!M.run) {
        Extract_code(M)
        return // done
    }
    else {
        M.P.l[M.P.j] = ftell(M.dof.fh) - M.P.l[M.P.j] // length of last part
        FClose(M.dof.fh, M.dof.id)
        FClose(M.tex.fh, M.tex.id)
    }

    // remove old keys
    if (!M.nodb & !M.reset) {
        DeleteOldKeys(M)
        if (!M.update) {
            // check whether order of elements changed
            if      (M.Ckeys !=M.Ckeys0)  M.update = `TRUE'
            else if (M.Lkeys !=M.Lkeys0)  M.update = `TRUE'
            else if (M.Gkeys !=M.Gkeys0)  M.update = `TRUE'
            else if (M.CFkeys!=M.CFkeys0) M.update = `TRUE'
            else if (M.Ikeys !=M.Ikeys0)  M.update = `TRUE'
        }
    }
    
    // run do-file and collect log
    run = sum(M.P.run)
    if (run) {
        // determine parts of dofile to be executed if not all (non-empty)
        // parts need execution
        if (run!=sum(M.P.l:!=0)) {
            UpdateRunFlags(M.P)
            RemovePartsFromDofile(M, M.P.run, M.P.l, M.P.j)
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
    
    // format logs and collected files
    Format(M)
    
    // weave
    M.tgt.fh = FOpen(M.tgt.fn, "w", M.tgt.id, 1)
    Weave(M)
    FClose(M.tgt.fh, M.tgt.id)
    
    // store logs in external files
    External_logfiles(M)
    
    // store collected files if in external files
    External_cfiles(M)
    
    // store external do-files if needed
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
    
    // Whether to run sttex or just extract stata code
    M.run = st_local("extract")!="extract"
    
    // temporary do-file and tex-file; main log file
    if (M.run) {
        M.dof.fh = FOpen(M.dof.fn = st_tempfilename(), "rw", M.dof.id = "dof")
        M.tex.fh = FOpen(M.tex.fn = st_tempfilename(), "w" , M.tex.id = "tex")
        M.log.fn = st_tempfilename()
        M.lognm  = st_tempname()
        st_local("lognm", M.lognm)
    }
    
    // part setup
    M.P.j   = 1 
    M.P.id  = ""
    M.P.pid = "."
    M.P.run = `FALSE'
    M.P.l   = 0
    
    // other
    M.lnum = 0
    M.c = M.ckeys = M.lkeys = M.gkeys = M.cfkeys = M.i = M.ikeys = 0
    M.logsave = M.cfsave = M.dosave = `FALSE'
    M.punct = "_"
    
    // default for lsuffix
    M.Lopt.lsuffix = ": "
    
    // code block options and graph options specified with sttex (adding a
    // blank to the options so that the routines will run through even if no
    // options are specified; this ensures that the defaults will be set)
    _collect_do_options(M, M.Copt, st_local("options0")+" ", `SOURCE'())
    _collect_log_options(M.Lopt, st_local("options")+" ", `SOURCE'())
    _collect_graph_options(M.Gopt, st_local("gropts")+" ", `SOURCE'())
    _collect_cfile_options(M.CFopt, st_local("fileopts")+" ", `SOURCE'())
    
    // code block options and graph options specified with %STinit
    _collect_do_options(M, M.Copt, st_local("options1"), `SOURCE'(), 1)
    _collect_log_options(M.Lopt, st_local("options")+" ", `SOURCE'(), 1)
    _collect_graph_options(M.Gopt, st_local("gropts"), `SOURCE'(), 1)
    _collect_cfile_options(M.CFopt, st_local("fileopts"), `SOURCE'(), 1)
    
    // initialize logdir
    if (M.Copt.logdir=="") M.Copt.logdir = pathrmsuffix(pathbasename(M.tgt.fn))
    
    // input tags
    M.tag.st        = "%ST"
    M.tag.part      = M.tag.st + "part"
    M.tag.set       = M.tag.st + "set"
    M.tag.ignore    = M.tag.st + "ignore"
    M.tag.endignore = M.tag.st + "endignore"
    M.tag.remove    = M.tag.st + "remove"
    M.tag.endremove = M.tag.st + "endremove"
    M.tag.cs        = "\"
    M.tag.Begin     = M.tag.cs + "begin"
    M.tag.End       = M.tag.cs + "end"
    M.tag.stdo      = M.tag.cs + "do"
    M.tag.stlog     = M.tag.cs + "stlog"
    M.tag.stlogq    = M.tag.cs + "stlog*"
    M.tag.stgraph   = M.tag.cs + "stgraph"
    M.tag.stgraphq  = M.tag.cs + "stgraph*"
    M.tag.stcfile   = M.tag.cs + "stfile"
    M.tag.stcfileq  = M.tag.cs + "stfile*"
    M.tag.stres     = M.tag.cs + "stres"
    M.tag.stinput   = M.tag.cs + "stinput"
    M.tag.stappend  = M.tag.cs + "stappend"
    M.tag.endinput  = M.tag.cs + "endinput"
    M.tag.ST        = "//ST"
    M.tag.cnp       = M.tag.ST + "cnp"
    M.tag.qui       = M.tag.ST + "qui"
    M.tag.oom       = M.tag.ST + "oom"
    M.tag.env       = ("stata", "stata*", "mata", "mata*")'
    
    // inline expression tags
    M.Itag.log      = "log"
    M.Itag.lognm    = "logname"
    M.Itag.graph    = "graph"
    M.Itag.graphnm  = "grname"
    M.Itag.cfile    = "file"
    M.Itag.cfilenm  = "fname"
      
    // weaving tags in log file
    M.Ltag.C    = "//stTeX// --> stlog start:"
    M.Ltag.Cend = "//stTeX// --> stlog stop"
    M.Ltag.G    = "//stTeX// --> stgraph:"
    M.Ltag.CF   = "//stTeX// --> stcfile:"
    M.Ltag.I    = "//stTeX// --> inline expression start:"
    M.Ltag.Iend = "//stTeX// --> inline expression stop"
    M.Ltag.ST   = "/*ST"
    M.Ltag.cnp  = M.Ltag.ST + "cnp -->*/"
    M.Ltag.qui  = M.Ltag.ST + "qui -->*/ quietly ///"
    M.Ltag.oom  = M.Ltag.ST + "oom -->*/ quietly ///"

    // weaving tags in LaTeX file
    M.Ttag.L     = "%%stTeX-stlog:"
    M.Ttag.Lend  = ":golts-XeTts%%"
    M.Ttag.G     = "%%stTeX-stgraph:"
    M.Ttag.Gend  = ":hpargts-XeTts%%"
    M.Ttag.CF    = "%%stTeX-stcfile:"
    M.Ttag.CFend = ":elifcts-XeTts%%"
    M.Ttag.I     = "%%stTeX-stres:"
    M.Ttag.Iend  = ":serts-XeTts%%"
    
    // default log environment tags
    M.Etag.log    = ("\begin{stlog}", "\end{stlog}")
    M.Etag.logb   = ("\begin{stlog}[beamer]", "\end{stlog}")
    M.Etag.code   = M.Etag.log
    M.Etag.codeb  = M.Etag.logb
    M.Etag.verb   = ("\begin{stverbatim}", "\end{stverbatim}")
    M.Etag.verbb  = M.Etag.verb
    
    // tokeninit() 
    // - for reading first token of input lines
    M.t1 = tokeninit((" "+char(9)), (",", "{", "["))
    // - for reading argument within {} or []
    M.t2 = tokeninit("", ("{", "}", "[", "]"))
    // - command-line tokeninit()
    M.t.l = "/*"; M.t.r = "*/"; M.t.lb = " ///"; M.t.eol  = " //"
    M.t.t = tokeninit("", (M.t.l, M.t.r, M.t.lb, M.t.eol))
    
    // db and associative arrays for code, logs, graphs, and inline expressions
    M.update = `FALSE'
    M.db.fn = st_local("dbname")
    if (M.db.fn=="") M.db.fn = st_local("src") + ".db"
    else {
        if (pathsuffix(M.db.fn)=="")
            M.db.fn = M.db.fn + pathsuffix(st_local("src")) + ".db"
        if (!pathisabs(M.db.fn))
            M.db.fn = pathjoin(M.srcdir, M.db.fn)
    }
    M.reset = (st_local("reset")!="")
    M.nodb  = (st_local("nodb")!="")
    if (!M.nodb) {
        Fexists(M.db.fn, M.replace)
    }
    if (!DatabaseRead(M)) {
        M.update = `TRUE'
        M.C  = asarray_create()
        M.L  = asarray_create()
        M.G  = asarray_create()
        M.CF = asarray_create()
        M.I  = asarray_create()
    }
    M.C0   = asarray_create()
    M.Lcnt = asarray_create()
    M.Ltex = asarray_create()
    return(M)
}

// collect do options
void _collect_do_options(`Main' M, `Copt' O, `Str' opts, `Source' F,
    | `Bool' init)
{
    `Bool' rc
    
    if (opts=="") {
        if (O.nodo==`FALSE') M.P.run[M.P.j] = `TRUE' // forced do
        st_local("options", "")
        return
    }
    // run Stata parser
    rc = _stata("_collect_do_options, " + opts)
    if (rc) {
        if (init==1)     errprintf("error in %%STinit\n")
        else if (F.i0<.) ErrorLines(F)
        exit(rc)
    }
    // collect on/off options (1 = on, 0 = off, . = not specified)
    _collect_onoff_option("nodo"     , O.nodo)
    _collect_onoff_option("certify"  , O.certify)
    _collect_onoff_option("dosave"   , O.dosave)
    _collect_onoff_option("notrim"   , O.notrim)
    _collect_onoff_option("nooutput" , O.nooutput)
    _collect_onoff_option("noextract", O.noextract)
    _collect_onoff_option("nogap"    , O.nogap)
    _collect_onoff_option("notitle"  , O.notitle)
    // numeric options (. if not specified)
    if (st_local("trim2")!="")    O.trim     = strtoreal(st_local("trim2"))
    if (st_local("linesize")!="") O.linesize = strtoreal(st_local("linesize"))
    // title
    if (st_local("title2")!="") O.title = st_local("title2")
    // logdir
    if (st_local("logdir")!="") O.logdir = st_local("logdir")
    // dodir
    if (st_local("dodir")!="")  O.dodir = st_local("dodir")
    // forced do
    if (O.nodo==`FALSE') M.P.run[M.P.j] = `TRUE'
}

// collect log options
void _collect_log_options(`Lopt' O, `Str' opts, `Source' F, | `Bool' init)
{
    `Bool' rc
    
    if (opts=="") return
    // run Stata parser
    rc = _stata("_collect_log_options, " + opts)
    if (rc) {
        if (init==1)     errprintf("error in %%STinit\n")
        else if (F.i0<.) ErrorLines(F)
        exit(rc)
    }
    // collect on/off options (1 = on, 0 = off, . = not specified)
    _collect_onoff_option("code"      , O.code)
    _collect_onoff_option("nolb"      , O.nolb)
    _collect_onoff_option("nogt"      , O.nogt)
    _collect_onoff_option("lnumbers"  , O.lnumbers)
    _collect_onoff_option("lcontinue" , O.lcont)
    _collect_onoff_option("nocommands", O.nocommands)
    _collect_onoff_option("noprompt"  , O.noprompt)
    _collect_onoff_option("nolskip"   , O.nolskip)
    _collect_onoff_option("notexman"  , O.notex)
    _collect_onoff_option("verbatim"  , O.verb)
    _collect_onoff_option("static"    , O.statc)
    _collect_onoff_option("nobegin"   , O.nobegin)
    _collect_onoff_option("noend"     , O.noend)
    _collect_onoff_option("beamer"    , O.beamer)
    // scalar options (. if not specified)
    if (st_local("clsize")!="")     O.clsize = strtoreal(st_local("clsize"))
    if (st_local("scale")!="")      O.scale = strtoreal(st_local("scale"))
    if (st_local("blstretch")!="")  O.blstretch = strtoreal(st_local("blstretch"))
    // multivalued numeric option (J(1,0,.) if not specified)
    if (st_local("range")!="") O.range = strtoreal(tokens(st_local("range")))
    if (st_local("drop")!="")  O.drop  = strtoreal(tokens(st_local("drop")))
    if (st_local("cnp")!="")   O.cnp   = strtoreal(tokens(st_local("cnp")))
    if (st_local("qui")!="")   O.qui   = strtoreal(tokens(st_local("qui")))
    if (st_local("oom")!="")   O.oom   = strtoreal(tokens(st_local("oom")))
    // suffix for line numbers: set to empty string if specified as ""
    if (st_local("haslsuffix")!="") O.lsuffix = st_local("lnumbers2")
    // string options ("" if not specified)
    if (st_local("begin2")!="")     O.Begin   = st_local("begin2")
    if (st_local("end2")!="")       O.End     = st_local("end2")
    // multivalues string options (J(1,0,"") if not specified)
    if (st_local("alert")!="")      O.alert = tokens(st_local("alert"))'
    // dictionary string options (J(0,0,"") if not specified)
    if (st_local("ltag")!="") O.ltag =
        _parse_ltag_option(st_local("ltag"), F, init)
    if (st_local("tag")!="") O.tag =
        _parse_matchist_expand(_parse_matchlist(st_local("tag"), 2))
    if (st_local("substitute")!="") O.subst =
        _parse_matchist_expand(_parse_matchlist(st_local("substitute"), 1))
}

// collect graph options
void _collect_graph_options(`Gopt' O, `Str' opts, `Source' F, | `Bool' init)
{
    `Bool' rc
    
    if (opts=="") return
    // run Stata parser
    rc = _stata("_collect_graph_options, " + opts)
    if (rc) {
        if (init==1)     errprintf("error in %%STinit\n")
        else if (F.i0<.) ErrorLines(F)
        exit(rc)
    }
    // collect on/off options (1 = on, 0 = off, . = not specified)
    _collect_onoff_option("center", O.center, "gr_")
    _collect_onoff_option("suffix", O.suffix, "gr_")
    _collect_onoff_option("epsfig", O.epsfig, "gr_")
    // multivalued string option (J(,1,"") if not specified)
    if (st_local("gr_as")!="")          O.as       = tokens(st_local("gr_as"))'
    // string options ("" if not specified)
    if (st_local("gr_name")!="")        O.name     = st_local("gr_name")
    if (st_local("gr_hasoverride")!="") O.override = st_local("gr_override")
    if (st_local("gr_hasargs")!="")     O.args     = st_local("gr_args")
    // grdir option
    if (st_local("gr_dir")!="") O.dir = st_local("gr_dir")
}

// collect cfile options
void _collect_cfile_options(`CFopt' O, `Str' opts, `Source' F, | `Bool' init)
{
    `Bool' rc
    
    if (opts=="") return
    // run Stata parser
    rc = _stata("_collect_cfile_options, " + opts)
    if (rc) {
        if (init==1)     errprintf("error in %%STinit\n")
        else if (F.i0<.) ErrorLines(F)
        exit(rc)
    }
    // collect on/off options (1 = on, 0 = off, . = not specified)
    _collect_onoff_option("erase"    , O.erase)
    _collect_onoff_option("nostatic" , O.nostatic)
    // multivalued numeric option (J(1,0,.) if not specified)
    if (st_local("range")!="") O.range = strtoreal(tokens(st_local("range")))
    // dictionary string options (J(0,0,"") if not specified)
    if (st_local("substitute")!="") O.subst =
        _parse_matchist_expand(_parse_matchlist(st_local("substitute"), 1))
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

// parse matchlist: lhs = rhs [lhs = rhs ... ]; argument k is number of tokens
// in rhs; output contains one row per specification: <lhs> <rhs1> [<rhs2> ...]
`StrM' _parse_matchlist(`Str' s, `Int' k)
{
    `Int'    i, j, l, r
    `Str'    lhs
    `StrR'   S
    `StrM'   dict
    `TokEnv' t
    
    // cut input at "="
    S = _parse_matchlist_eqtok(s)
    // split lhs and rhs
    l = length(S)
    dict = J(l, 1+k, "")
    if (l==0) return(dict)
    i = 0
    if (S[1]=="=") i++
    else           lhs = S[1]
    t = tokeninit()
    for (j=2;j<=l;j++) {
        if (S[j]=="=") {
            i++
            continue
        }
        dict[i,1] = lhs
        tokenset(t, S[j])
        for (r=1;r<=k;r++) dict[i,1+r] = _parse_stripquotes(tokenget(t))
        lhs = strtrim(tokenrest(t))
    }
    if (lhs!="") dict[++i,1] = lhs
    return(dict[|1,1 \ i,.|])
}

`StrR' _parse_matchlist_eqtok(`Str' s)
{
    `Int'    i, j
    `StrR'   S0, S
    `TokEnv' t
    
    t = tokeninit("", "=")
    tokenset(t, s)
    S0 = tokengetall(t)
    i = j = length(S0)
    S = J(1, i ,"")
    if (S0[i]=="=") j++
    for (;i;i--) {
        if (S0[i]=="=") {
            S[--j] = S0[i]
            j--
            continue
        }
        S[j] = S0[i] + S[j]
    }
    if (j>1) return(strtrim(S[|j\.|]))
    return(strtrim(S))
}

// expand matchlist; one row for each token in lhs, skipping empty tokens
`StrM' _parse_matchist_expand(`StrM' dict0)
{
    `Int'  r, i, l
    `StrR' lhs
    `StrM' dict
    
    // count expanded rows
    r = 0
    for (i=rows(dict0);i;i--) {
        l = length(tokens(dict0[i,1]))
        r = r + l
    }
    if (!r) return(J(0, 0, ""))
    // expand
    dict = J(r, cols(dict0), "")
    for (i=rows(dict0);i;i--) {
        lhs = tokens(dict0[i,1])
        for (l=length(lhs); l; l--) {
            dict[r,]  = dict0[i,]
            dict[r,1] = _parse_stripquotes(lhs[l])
            if (dict[r,1]!="") r-- 
        }
    }
    if (r) { // has empty lhs tokens
        if (r==rows(dict)) return(J(0, 0, ""))
        return(dict[|r+1,1 \ .,.|])
    }
    return(dict)
}

`Str' _parse_stripquotes(`Str' s)
{
    if      (substr(s, 1, 1)==`"""')       s = substr(s, 2, strlen(s)-2)
    else if (substr(s, 1, 2)=="`" + `"""') s = substr(s, 3, strlen(s)-4)
    return(s)
}

// expand ltag() option into a matrix with one specification per row:
//   <numlist> <left tag> <right tag>
`StrM' _parse_ltag_option(`Str' ltag, `Source' F, | `Bool' init)
{
    `Int'  i, rc
    `StrM' dict
    
    dict = _parse_matchlist(ltag, 2)
    for (i=rows(dict); i; i--) {
        rc = _stata("numlist " + "`" + `"""' + dict[i,1] + `"""' +  "'" +
            ", int range(>=0) sort")
        if (rc) {
            errprintf("invalid specification of ltag() option\n")
            if (init==1) errprintf("error in %%STinit\n")
            else if (F.i0<.) ErrorLines(F)
            exit(rc)
        }
        stata("local ltag_numlist \`r(numlist)'")
        stata("local ltag_numlist: list uniq ltag_numlist")
        dict[i,1] = st_local("ltag_numlist")
    }
    return(dict)
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
    fput(M.db.fh, "stTeX database version 1.1.7")
    // write keys and associative arrays
    fputmatrix(M.db.fh, M.Ckeys);  fputmatrix(M.db.fh, M.C)
    fputmatrix(M.db.fh, M.Lkeys);  fputmatrix(M.db.fh, M.L)
    fputmatrix(M.db.fh, M.Gkeys);  fputmatrix(M.db.fh, M.G)
    fputmatrix(M.db.fh, M.Ikeys);  fputmatrix(M.db.fh, M.I)
    fputmatrix(M.db.fh, M.CFkeys); fputmatrix(M.db.fh, M.CF)
    // close DB
    FClose(M.db.fh, "")
    printf("{txt}(sttex database saved as %s)\n", M.db.fn)
    // push update status to Stata
    st_local("dbupdate","1")
}

`Bool' DatabaseRead(`Main' M)
{
    `Int' v
    `Str' s
    
    if (M.nodb | M.reset) return(0)
    if (!fileexists(M.db.fn)) return(0)
    // open DB and read header
    M.db.fh = FOpen(M.db.fn, "r")
    s = fget(M.db.fh)
    v = strtoreal(substr(s, -1, .))
    s = substr(s, 1, strlen(s)-1)
    if (s!="stTeX database version 1.1." | v<6) {
        printf("{txt}(database %s not compatible; ", M.db.fn)
        printf("{txt}generating new database)\n")
        FClose(M.db.fh)
        return(0)
    }
    // read associative arrays
    M.Ckeys0 = fgetmatrix(M.db.fh); M.C = fgetmatrix(M.db.fh)
    M.Lkeys0 = fgetmatrix(M.db.fh); M.L = fgetmatrix(M.db.fh)
    M.Gkeys0 = fgetmatrix(M.db.fh); M.G = fgetmatrix(M.db.fh)
    M.Ikeys0 = fgetmatrix(M.db.fh); M.I = fgetmatrix(M.db.fh)
    if (v>6) { // M.CF does not exist in db version 1.1.6
        M.CFkeys0 = fgetmatrix(M.db.fh); M.CF = fgetmatrix(M.db.fh)
    }
    else M.CF = asarray_create()
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
    if (substr(line,1,strlen("stTeX database"))!="stTeX database") return
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

    F.fn = fn
    F.S = Cat(F.fn)
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
                Parse_Part(M, F)
                continue
            }
            if (s==M.tag.set) {
                Parse_Set(M, F)
                continue
            }
            if (s==M.tag.ignore) { 
                if (Parse_Ignore(M, F)) break
                continue
            }
            if (s==M.tag.remove) { 
                if (Parse_Remove(M, F)) break
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
            if (Parse_C(M, F)) continue
        }
        else if (s==M.tag.stlog) {
            if (Parse_L(M, F, `FALSE')) continue
        }
        else if (s==M.tag.stlogq) {
            if (Parse_L(M, F, `TRUE')) continue
        }
        else if (s==M.tag.stgraph) {
            if (Parse_G(M, F, `FALSE')) continue
        }
        else if (s==M.tag.stgraphq) {
            if (Parse_G(M, F, `TRUE')) continue
        }
        else if (s==M.tag.stcfile) {
            if (Parse_CF(M, F, `FALSE')) continue
        }
        else if (s==M.tag.stcfileq) {
            if (Parse_CF(M, F, `TRUE')) continue
        }
        else if (s==M.tag.stinput) {
            Parse_Input(M, F)
            continue
        }
        else if (s==M.tag.stappend) {
            Parse_Append(M, F)
            continue
        }
        else if (substr(s,1,strlen(M.tag.stdo))==M.tag.stdo) {
            if (Parse_C_do(M, F, substr(s,strlen(M.tag.stdo)+1,.))) continue
        }
        Parse_I(M, F)
    }
}

/*---------------------------------------------------------------------------*/
/* helper function to append elemen to colvector; will expand the length of  */
/* the vector in junks of 100 elements; this should be more efficient than   */
/* expanding one-by-one                                                      */
/*---------------------------------------------------------------------------*/

void AppendElement(transmorphic colvector v, `Int' j, transmorphic scalar el)
{
    _AppendElement(v, ++j, el)
}

void _AppendElement(transmorphic colvector v, `Int' j, transmorphic scalar el)
{
    if (j>length(v)) v = v \ J(100, 1, missingof(v))
    v[j] = el
}

/*---------------------------------------------------------------------------*/
/* function to handle parts                                                  */
/*---------------------------------------------------------------------------*/

void Parse_Part(`Main' M, `Source' F)
{
    `Str' id, pid, tok, opts
    
    // collect id and pid
    F.i0 = F.i
    if ((tok=tokenget(M.t1))!="") {
        if (tok!=",") {
            id = tok
            if (id==".") id = ""
            else if (!st_islmname(id)) {
                errprintf("'%s' invalid name\n", id)
                ErrorLines(F)
                exit(7)
            }
            tok = tokenget(M.t1)
        }
        if (tok!=",") {
            pid = tok
            if (pid!="." & pid!="") {
                if (!st_islmname(pid)) {
                    errprintf("'%s' invalid name\n", pid)
                    ErrorLines(F)
                    exit(7)
                }
            }
            tok = tokenget(M.t1)
        }
        if (tok==",") opts = tokenrest(M.t1)
        else if (tok!="") {
            errprintf("'%s' not allowed\n", tok)
            ErrorLines(F)
            exit(499)
        }
    }
    if (id=="") id = strofreal(M.P.j) // j is offet by one (j=1 for part 0)
    if (anyof(M.P.id[|1\M.P.j|], id)) {
        errprintf("'%s' already taken; part names must be unique\n", id)
        ErrorLines(F)
        exit(499)
    }
    // initialize part
    M.c = M.i = 0 // reset element counters 
    AppendElement(M.P.id, M.P.j, id) // increases counter by 1
    _AppendElement(M.P.pid, M.P.j, pid)
    _AppendElement(M.P.run, M.P.j, `FALSE') 
    _AppendElement(M.P.l, M.P.j, M.run ? ftell(M.dof.fh) : 0) // current pos
    M.P.l[M.P.j-1] = M.P.l[M.P.j] - M.P.l[M.P.j-1] // length of prev part
    // collect options
    _collect_do_options(M, M.Copt, opts, F)
    _collect_log_options(M.Lopt, st_local("options"), F)
    _collect_graph_options(M.Gopt, st_local("gropts"), F)
    _collect_cfile_options(M.CFopt, st_local("fileopts"), F)
}

/*---------------------------------------------------------------------------*/
/* function to %STset                                                        */
/*---------------------------------------------------------------------------*/

void Parse_Set(`Main' M, `Source' F)
{
    `Int'  l, i
    `Str'  tag
    `StrC' opts
    
    tag  = tokenget(M.t1)
    opts = tokens(tokenrest(M.t1))
    i    = min((length(opts),2)) // extra tokens will be ignored
    if (tag=="log") {
        for (;i;i--) M.Etag.log[i] = opts[i]
        return
    }
    if (tag=="code") {
        for (;i;i--) M.Etag.code[i] = opts[i]
        return
    }
    if (tag=="verb") {
        for (;i;i--) M.Etag.verb[i] = opts[i]
        return
    }
    l = strlen(tag)
    if (tag==substr("logbeamer", 1, max((4,l)))) {
        for (;i;i--) M.Etag.logb[i] = opts[i]
        return
    }
    if (tag==substr("codebeamer", 1, max((5,l)))) {
        for (;i;i--) M.Etag.codeb[i] = opts[i]
        return
    }
    if (tag==substr("verbbeamer", 1, max((5,l)))) {
        for (;i;i--) M.Etag.verbb[i] = opts[i]
        return
    }
    errprintf("keyword '%s' not allowed\n", tag)
    F.i0 = F.i; ErrorLines(F)
    exit(198)
}

/*---------------------------------------------------------------------------*/
/* functions to parse code blocks                                            */
/*---------------------------------------------------------------------------*/

// main function; return code: 0 not a code block, 1 else
`Bool' Parse_C(`Main' M, `Source' F)
{
    `Str'   tag
    `Str'   id;      `Unset' id
    `Bool'  quietly; `Unset' quietly
    `Bool'  mata;    `Unset' mata
    `Copt'  O;       `Unset' O
    `Lopt'  LO

    // get keyword
    F.i0 = F.i
    tag = TabTrim(Get_Arg(M, "{", "}", F))
    if (!anyof(M.tag.env, tag)) return(`FALSE')
    // determine mode, parse id and options
    _Parse_C_opts(M, F, tag, id, quietly, mata, O)
    LO = M.Lopt
    _collect_log_options(LO, st_local("options"), F)
    // read code and process the block
    _Parse_C(M, id, mata, O, _Parse_C_read(M, F, tag))
    // create log instance
    if (M.run) _Parse_L(M, F, "", LO, quietly)
    return(`TRUE')
}
`StrC' _Parse_C_read(`Main' M, `Source' F, `Str' tag)
{
    `Int' i0, rc
    
    // find end of block
    i0 = F.i = F.i + 1
    for (; F.i<=F.n; F.i=F.i+1) {
        if (rc = _Parse_C_read_end(M, F, tag)) break
    }
    if (rc!=1) {
        errprintf("line %g in %s: %s\n", F.i0, F.fn, F.S[F.i0])
        if (rc==0)  errprintf("end not found\n")
        else        errprintf("ended on line %g with: %s\n", F.i, F.S[F.i])
        exit(499)
    }
    // copy commands
    if (F.i>i0) return(F.S[|i0 \ F.i-1|])
    return(J(0,1,""))
}
`Int' _Parse_C_read_end(`Main' M, `Source' F, `Str' tag)
{   // return code: 0 continue, 1 end found, -1 wrong end tag, -2 \endinput
    // also handles //STcnp, //STqui, //SToom
    `Str' s
    
    tokenset(M.t1, F.S[F.i])
    s = tokenget(M.t1)
    if (s==M.tag.cnp) {
        F.S[F.i] = substr(F.S[F.i],1,strpos(F.S[F.i],M.tag.cnp)-1) + M.Ltag.cnp
        return(0)
    }
    if (s==M.tag.qui) {
        F.S[F.i] = substr(F.S[F.i],1,strpos(F.S[F.i],M.tag.qui)-1) + M.Ltag.qui
        return(0)
    }
    if (s==M.tag.oom) {
        F.S[F.i] = substr(F.S[F.i],1,strpos(F.S[F.i],M.tag.oom)-1) + M.Ltag.oom
        return(0)
    }
    if (s==M.tag.End) {
        if (TabTrim(Get_Arg(M, "{", "}", F))==tag) return(1)
        else return(-1) // wrong \end tag
    }
    if (s==M.tag.endinput) return(-2)
    return(0)
}

// \stdo-variant of main function; return code: 0 not a code block, 1 else
`Bool' Parse_C_do(`Main' M, `Source' F, `Str' tag)
{
    `Str'  fn
    `Str'  id;      `Unset' id
    `Bool' quietly; `Unset' quietly
    `Bool' mata;    `Unset' mata
    `Copt' O;       `Unset' O
    `Lopt' LO
    
    // check tag
    if (!anyof(M.tag.env, tag)) return(`FALSE')
    // get filename
    F.i0 = F.i
    fn = TabTrim(Get_Arg(M, "{", "}", F))
    if (fn=="") {
        errprintf("invalid syntax; {it:filename} required\n")
        ErrorLines(F)
        exit(601)
    }
    if (!pathisabs(fn)) fn = pathjoin(M.srcdir, fn)
    if (!fileexists(fn)) {
        errprintf("file %s not found\n", fn)
        ErrorLines(F)
        exit(601)
    }
    // determine mode, parse id and options
    _Parse_C_opts(M, F, tag, id, quietly, mata, O)
    LO = M.Lopt
    _collect_log_options(LO, st_local("options"), F)
    // read code and process the block
    _Parse_C(M, id, mata, O, _Parse_C_do_read(M, fn))
    // create log instance
    if (M.run) _Parse_L(M, F, "", LO, quietly)
    return(`TRUE')
}
`StrC' _Parse_C_do_read(`Main' M, `Str' fn)
{   // also handles //STcnp, //STqui, //SToom
    `Int'  i
    `Str'  s
    `StrC' S
    
    S = Cat(fn)
    for (i=rows(S); i; i--) {
        tokenset(M.t1, S[i])
        s = tokenget(M.t1)
        if (s==M.tag.cnp) {
            S[i] = substr(S[i],1,strpos(S[i],M.tag.cnp)-1) + M.Ltag.cnp
        }
        else if (s==M.tag.qui) {
            S[i] = substr(S[i],1,strpos(S[i],M.tag.qui)-1) + M.Ltag.qui
        }
        else if (s==M.tag.oom) {
            S[i] = substr(S[i],1,strpos(S[i],M.tag.oom)-1) + M.Ltag.oom
        }
    }
    return(S)
}

// determine mode, parse id and options
void _Parse_C_opts(`Main' M, `Source' F, `Str' tag, `Str' id, `Bool' quietly,
    `Bool' mata, `Copt' O)
{
    `Int' mode
    `Str' opts
    
    mode = select(1::length(M.tag.env), M.tag.env:==tag)
    quietly = !mod(mode,2)
    mata    = anyof((3,4), mode)
    // parse id and options
    (void) M.c++; M.g = M.cf = 0 // initialize code instance
    id = TabTrim(Get_Arg(M, "[", "]", F))
    opts = TabTrim(Get_Arg(M, "[", "]", F))
    O = M.Copt
    _collect_do_options(M, O, opts, F)
    if (id=="") id = (M.P.j>1 ? M.P.id[M.P.j] + M.punct : "") + 
                     strofreal(M.c)
    else if (!st_islmname(id)) {
        errprintf("'%s' invalid name\n", id)
        ErrorLines(F)
        exit(7)
    }
    if (M.ckeys ? anyof(M.Ckeys[|1\M.ckeys|], id) : 0) {
        errprintf("'%s' already taken; log names must be unique\n", id)
        ErrorLines(F)
        exit(499)
    }
}

// process code block
void _Parse_C(`Main' M, `Str' id, `Bool' mata, `Copt' O, `StrC' S)
{
    `Int' lsize0
    
    // get rid of indentation
    if (O.notrim!=`TRUE') _Parse_C_trim(M, S, O.trim)
    // prepare do-file
    if (M.run & O.nodo!=`TRUE') { // M.run=FALSE if -sttex extract-
        // - set line size and output mode
        if (O.linesize<.) {
            lsize0 = st_numscalar("c(linesize)")
            fput(M.dof.fh, sprintf("set linesize %g", O.linesize))
        }
        if (O.nooutput==`TRUE') fput(M.dof.fh, "set output inform")
        // - start mata if needed
        if (mata==`TRUE') fput(M.dof.fh, "mata:")
        // - write the commands
        fput(M.dof.fh, M.Ltag.C + id)
        _Fput(M.dof.fh, S)
        fput(M.dof.fh, M.Ltag.Cend)
        // - end mata if needed
        if (mata==`TRUE') fput(M.dof.fh, "end")
        // - restore line size and output mode
        if (O.linesize<.) {
            fput(M.dof.fh, sprintf("set linesize %g", lsize0))
        }
        if (O.nooutput==`TRUE') fput(M.dof.fh, "set output proc")
    }
    // update database
    _Parse_C_store(M, id, O, S, mata)
    AppendElement(M.Ckeys, M.ckeys, id) // increases counter by 1
}

// trim indentation
void _Parse_C_trim(`Main' M, `StrC' S, `Int' trim)
{
    `Int' t, i, l

    t = trim
    for (i=1; i<=rows(S); i++) {
        tokenset(M.t1, S[i])
        if ((l = strlen(tokenget(M.t1)))==0) continue // empty line
        l = tokenoffset(M.t1) - l - 1 // size of indentation
        if (l<t) t = l
        if (t<1) return // zero indentation
    }
    if (t>=.) return // can happen if all lines only contain white space
    S = substr(S, t+1, .)
}

// update info on code block in database and determine whether code needs to be run
void _Parse_C_store(`Main' M, `Str' id, `Copt' O, `StrC' S, `Bool' mata)
{
    `Bool'   chflag
    `pCode'  C
    `pCode0' C0
    
    // update M.P.run if forced do
    if (O.nodo==`FALSE') M.P.run[M.P.j] = `TRUE'
    // set overall dosave flag
    if (O.dosave==`TRUE') M.dosave = `TRUE'
    // no preexisting version
    if (!asarray_contains(M.C, id)) {
        if (O.nodo!=`TRUE') M.P.run[M.P.j] = `TRUE' // not forced nodo
        C = &(`CODE'())
        C->newcmd = C->newlog = `TRUE'
        C->mata = mata
        C->O = O
        C->cmd = &S
        asarray(M.C, id, C)
        M.update = `TRUE'
        return
    }
    // update preexisting version
    C = asarray(M.C, id)
    C->newcmd = C->newlog = `FALSE'
    chflag = `FALSE'
    // - hold on to previous cmd and log for certification
    if (O.certify==`TRUE') {
        C0 = &(`CODE0'())
        C0->cmd = C->cmd
        C0->log = C->log
        C0->linesize = C->O.linesize
        asarray(M.C0, id, C0)
    }
    // - change in commands
    if (*C->cmd!=S) {
        C->cmd = &S; C->newcmd = C->newlog = `TRUE';            chflag = `TRUE'
    }
    // - change in type of code (Stata vs. Mata)
    else if (C->mata!=mata) {
        C->mata = mata;                                         chflag = `TRUE'
    }
    // - check whether options changed
    if (C->O!=O) {
        if (!chflag) {
            if ((C->O.nooutput==`TRUE')!=(O.nooutput==`TRUE'))  chflag = `TRUE'
            else if (C->O.linesize!=O.linesize)                 chflag = `TRUE'
        }
        // copy current options (not all changes in options will cause the
        // db on disk to be updated; this is on purpose)
        C->O = O
    }
    // - final check for missing log (can happen if nodo has been specified
    //   in an earlier run)
    if (!chflag) {
        if (O.nodo!=`TRUE') {
            if (C->log==NULL)                                   chflag = `TRUE'
        }
    }
    // - clear log and update M.P.run
    if (chflag) {
        if (O.nodo!=`TRUE') M.P.run[M.P.j] = `TRUE' // not forced nodo
        C->log = NULL
        M.update = `TRUE'
    }
}

/*---------------------------------------------------------------------------*/
/* functions to handle \stlog                                                */
/*---------------------------------------------------------------------------*/

// return code: 0 not a valid \stlog command; 1 else
`Bool' Parse_L(`Main' M, `Source' F, `Bool' quietly)
{
    `Bool' rc; `Unset' rc
    `Str'  idlist, opts
    `Lopt' O
    
    F.i0 = F.i
    idlist = TabTrim(Get_Arg(M, "[", "]", F)) // ignore errors
    opts = TabTrim(Get_Arg(M, "{", "}", F, rc))
    if (rc) return(`FALSE')
    O = M.Lopt
    _collect_log_options(O, opts, F)
    if (!M.run) return(`TRUE')
    _Parse_L(M, F, idlist, O, quietly)
    return(`TRUE')
}

void _Parse_L(`Main' M, `Source' F, `Str' idlist, `Lopt' O, `Bool' quietly)
{
    `Int'   j
    `Str'   key
    `StrC'  ids
    
    // find code block(s)
    if (idlist=="") {
        if (M.ckeys) ids = M.Ckeys[M.ckeys] // get last id
        if (ids=="") {
            errprintf("cannot create log; no code block found\n")
            ErrorLines(F)
            exit(499)
        }
    }
    else ids = _Parse_L_getids(F, M.Ckeys[|1\M.ckeys|], M.ckeys, tokens(idlist))
    // update log counter and generate log id
    if (asarray_contains(M.Lcnt, ids[1])) j = asarray(M.Lcnt, ids[1]) + 1
    else                                  j = 0
    asarray(M.Lcnt, ids[1], j)
    if (j) key = ids[1] + "." + strofreal(j)
    else   key = ids[1]
    if (M.lkeys ? anyof(M.Lkeys[|1\M.lkeys|], key) : 0) { // can this happen?
        errprintf("'%s' already taken; log names must be unique\n", key)
        ErrorLines(F)
        exit(499)
    }
    // write tags to LaTeX file
    if (quietly!=`TRUE') fput(M.tex.fh, M.Ttag.L + key + M.Ttag.Lend)
    // set begin/end environment
    _Parse_L_env(M, O, O.Begin, 1)
    _Parse_L_env(M, O, O.End,   2)
    // update database
    _Parse_L_store(M, ids, O, key)
    AppendElement(M.Lkeys, M.lkeys, key) // increases counter by 1
}

`StrC' _Parse_L_getids(`Source' F, `StrC' keys, `Int' nkeys, `StrR' idlist)
{
    `Int'   i, j, k, n
    `IntC'  idx, p
    `BoolC' p0 // whether id already used
    `StrC'  ids
    
    idx = nkeys ? 1::nkeys : J(0,1,.)
    ids = J(nkeys, 1, "")
    p0  = J(nkeys, 1, 0)
    k   = 0
    n   = length(idlist)
    for (i=1;i<=n;i++) {
        p = select(idx, strmatch(keys, idlist[i]))
        if (!length(p)) {
            errprintf("no code block found that matches '%s'\n", idlist[i])
            ErrorLines(F)
            exit(499)
        }
        p = select(p, !p0[p])
        j = length(p)
        if (!j) continue
        p0[p] = J(j, 1, 1)
        ids[|k+1 \ k+j|] = keys[p]
        k = k + j
    }
    return(ids[|1 \ k|])
}

// set begin/end environment 
void _Parse_L_env(`Main' M, `Lopt' O, `Str' tag, `Int' j)
{
    if (tag!="") return
    if (O.code==`TRUE') {
        if (O.verb==`TRUE') {
            if (O.beamer==`TRUE') tag = M.Etag.verbb[j]
            else                  tag = M.Etag.verb[j]
        }
        else {
            if (O.beamer==`TRUE') tag = M.Etag.codeb[j]
            else                  tag = M.Etag.code[j]
        }
    }
    else {
        if (O.beamer==`TRUE')     tag = M.Etag.logb[j]
        else                      tag = M.Etag.log[j]
    }
}

// update info on log in database and determine whether log needs to be refreshed
void _Parse_L_store(`Main' M, `StrC' ids, `Lopt' O, `Str' key)
{
    `Bool'  chflag
    `pLog'  L
    `pCode' C
    
    // get logdir from (first) code block
    C = asarray(M.C, ids[1])
    O.logdir = C->O.logdir
    // no preexisting version
    if (!asarray_contains(M.L, key)) {
        L = &(`LOG'())
        L->ids = ids
        L->O = O
        asarray(M.L, key, L)
        M.update = `TRUE'
        return
    }
    // update preexisting version
    L = asarray(M.L, key)
    chflag = `FALSE'
    // - check whether definition of log changed
    if (L->ids!=ids) {
        L->ids = ids;                                            chflag = `TRUE'
    }
    // - check whether options changed
    if (L->O!=O) {
        if (!chflag) {
            if      ((L->O.code==`TRUE')!=(O.code==`TRUE'))      chflag = `TRUE'
            else if  (L->O.range!=O.range)                       chflag = `TRUE'
            else if  (L->O.ltag!=O.ltag)                         chflag = `TRUE'
            else if  (L->O.tag!=O.tag)                           chflag = `TRUE'
            else if  (L->O.alert!=O.alert)                       chflag = `TRUE'
            else if  (L->O.subst!=O.subst)                       chflag = `TRUE'
            else if ((L->O.nolb==`TRUE')!=(O.nolb==`TRUE'))      chflag = `TRUE'
            else if ((L->O.nogt==`TRUE')!=(O.nogt==`TRUE'))      chflag = `TRUE'
            else if  (L->O.drop!=O.drop)                         chflag = `TRUE'
            else if  (L->O.cnp!=O.cnp)                           chflag = `TRUE'
            else if ((L->O.lnumbers==`TRUE')!=
                        (O.lnumbers==`TRUE'))                    chflag = `TRUE'
            else if (O.lnumbers==`TRUE') {
                if ((L->O.lcont==`TRUE')!=(O.lcont==`TRUE'))     chflag = `TRUE'
            }
        }
        if (!chflag) {
            if (O.code==`TRUE') {
                if ((L->O.notex==`TRUE')!=(O.notex==`TRUE'))     chflag = `TRUE'
                else if ((L->O.verb==`TRUE')!=(O.verb==`TRUE'))  chflag = `TRUE'
                else if (O.verb!=`TRUE' & O.notex!=`TRUE') {
                    if       (L->O.clsize!=O.clsize)             chflag = `TRUE'
                    else if ((L->O.nolskip==`TRUE')!=(O.nolskip==`TRUE'))
                                                                 chflag = `TRUE'
                }
            }
            else {
                if      ((L->O.nocommands==`TRUE')!=
                            (O.nocommands==`TRUE'))              chflag = `TRUE'
                else if ((L->O.noprompt==`TRUE')!=
                         (O.noprompt==`TRUE'))                   chflag = `TRUE'
                else if  (L->O.qui!=O.qui)                       chflag = `TRUE'
                else if  (L->O.oom!=O.oom)                       chflag = `TRUE'
            }
        }
        // copy current options (not all changes in options will cause the
        // db on disk to be updated; this is on purpose)
        L->O = O
    }
    // - clear log if there were changes
    if (chflag) {
        _Parse_L_clear(*L)
        M.update = `TRUE'
    }
}

void _Parse_L_clear(`Log' L)
{
    L.log  = NULL
    L.Lnum = `LNUM'()
    L.lhs  = L.rhs = J(0,1,"")
}

/*---------------------------------------------------------------------------*/
/* functions to handle graphs                                                */
/*---------------------------------------------------------------------------*/

// return code: 0 not a valid \stgraph command, 1 else
`Bool' Parse_G(`Main' M, `Source' F, `Bool' quietly)
{
    `Bool' rc; `Unset' rc
    `Str'  id, opts
    
    F.i0 = F.i
    id = TabTrim(Get_Arg(M, "[", "]", F)) // ignore errors
    if (id!="") {
        if (!st_islmname(id)) {
            errprintf("'%s' invalid name\n", id)
            ErrorLines(F)
            exit(7)
        }
    }
    opts = TabTrim(Get_Arg(M, "{", "}", F, rc))
    if (rc) return(`FALSE')
    if (!M.run) return(`TRUE')
    _Parse_G(M, F, id, opts, quietly)
    return(`TRUE')
}

void _Parse_G(`Main' M, `Source' F, `Str' id, `Str' opts, `Bool' quietly)
{
    `Bool'   nodo
    `StrC'   fn
    `pCode'  C
    `Gopt'   O
    
    // options
    O = M.Gopt
    _collect_graph_options(O, opts, F)
    if (length(O.as)==0) {
        if (O.epsfig==`TRUE') O.as = "eps"
        else                  O.as = "pdf"
    }
    // part must have at least one preceding code block
    if (!M.c) {
        errprintf("no preceding code block found within current part\n")
        ErrorLines(F)
        exit(499)
    }
    // determine id and update graph counter
    if (id=="") {
        id = M.Ckeys[M.ckeys] // get id of preceding code block
        if (M.g) id = id + NumToLetter(M.g)
    }
    if (M.gkeys ? anyof(M.Gkeys[|1\M.gkeys|], id) : 0) {
        errprintf("'%s' already taken; graph names must be unique\n", id)
        ErrorLines(F)
        exit(499)
    }
    (void) M.g++
    // inherit do option and dir from preceding code block
    C = asarray(M.C, M.Ckeys[M.ckeys])
    nodo = C->O.nodo
    if (O.dir=="") O.dir = C->O.logdir
    // prepare do-file
    if (nodo!=`TRUE') {
        fn = st_tempfilename(length(O.as))'
        _Parse_G_dof(M, O, fn)
        fput(M.dof.fh, M.Ltag.G + id)
    }
    // write tags to LaTeX file
    if (quietly!=`TRUE') fput(M.tex.fh, M.Ttag.G + id + M.Ttag.Gend)
    // update database
    _Parse_G_store(M, id, O, fn, nodo)
    AppendElement(M.Gkeys, M.gkeys, id) // increases counter by 1
}

void _Parse_G_dof(`Main' M, `Gopt' O, `StrC' fn)
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
void _Parse_G_store(`Main' M, `Str' id, `Gopt' O, `StrC' fn, `Bool' nodo)
{
    `Bool'   chflag
    `Int'    i
    `StrC'   f, fold
    `pGraph' G
    
    // no preexisting version
    if (!asarray_contains(M.G, id)) {
        if (nodo!=`TRUE') M.P.run[M.P.j] = `TRUE'
        G = &(`GRAPH'())
        G->fn = fn
        G->O = O
        asarray(M.G, id, G)
        M.update = `TRUE'
        return
    }
    // update preexisting version
    G = asarray(M.G, id)
    G->fn = fn
    // - determine whether code needs to be run
    chflag = `FALSE'
    // file format(s) changed
    if (length(Complement(O.as, G->O.as))) chflag = `TRUE'
    // graph window changed
    else if (G->O.name!=O.name)            chflag = `TRUE'
    // override() option changed
    else if (G->O.override!=O.override)    chflag = `TRUE'
    // look for graph file(s)
    else if (nodo!=`TRUE' | G->O.dir!=O.dir) {
        fold = J(0, 1, "")
        for (i=length(O.as); i; i--) {
            // look for gaph file in current graph folder
            f = pathjoin(MkDir(M.tgtdir, O.dir), id)+"."+O.as[i]
            if (!fileexists(f)) {
                if (G->O.dir==O.dir) {
                    // graph file is missing
                    chflag = `TRUE'
                    break
                }
                // find graph file in old location
                f = pathjoin(MkDir(M.tgtdir, G->O.dir), id)+"."+O.as[i]
                if (!fileexists(f)) {
                    // graph file is missing
                    chflag = `TRUE'
                    break
                }
                fold = fold \ f
            }
        }
        if (!chflag & rows(fold)) {
            // copy graph files from old location
            Copy_GRfiles(fold, MkDir(M.tgtdir, O.dir), id, O.as, M.replace)
        }
    }
    if (chflag) {
        if (nodo!=`TRUE') M.P.run[M.P.j] = `TRUE'
        M.update = `TRUE'
    }
    // - copy options (not all changes in options will cause the db on disk to
    //   be updated; this is on purpose)
    if (G->O!=O) {
        if (G->O.dir!=O.dir) M.update = `TRUE'
        G->O = O
    }
}

/*---------------------------------------------------------------------------*/
/* functions to handle collected files                                       */
/*---------------------------------------------------------------------------*/

// return code: 0 not a valid \stfile command, 1 else
`Bool' Parse_CF(`Main' M, `Source' F, `Bool' quietly)
{
    `Bool' rc; `Unset' rc
    `Str'  id, fn, opts
    
    F.i0 = F.i
    id = TabTrim(Get_Arg(M, "[", "]", F)) // ignore errors
    if (id!="") {
        if (!st_islmname(id)) {
            errprintf("'%s' invalid name\n", id)
            ErrorLines(F)
            exit(7)
        }
    }
    fn = TabTrim(Get_Arg(M, "{", "}", F, rc))
    if (rc) return(`FALSE')
    if (fn=="") {
        errprintf("invalid syntax; {it:filename} required\n")
        ErrorLines(F)
        exit(601)
    }
    opts = TabTrim(Get_Arg(M, "[", "]", F))
    if (!M.run) return(`TRUE')
    _Parse_CF(M, F, id, fn, opts, quietly)
    return(`TRUE')
}

void _Parse_CF(`Main' M, `Source' F, `Str' id, `Str' fn0, `Str' opts,
    `Bool' quietly)
{
    `Bool'  nodo
    `Str'   fn
    `pCode' C
    `CFopt' O
    
    // options
    O = M.CFopt
    _collect_cfile_options(O, opts, F)
    // name of file to be collected
    if (pathsuffix(fn0)=="") O.fn = fn0 + ".tex"
    else                     O.fn = fn0
    // part must have at least one preceding code block
    if (!M.c) {
        errprintf("no preceding code block found within current part\n")
        ErrorLines(F)
        exit(499)
    }
    // determine id and update cfile counter
    if (id=="") {
        id = M.Ckeys[M.ckeys] // get id of preceding code block
        if (M.cf) id = id + NumToLetter(M.cf)
    }
    if (M.cfkeys ? anyof(M.CFkeys[|1\M.cfkeys|], id) : 0) {
        errprintf("'%s' already taken; \stfile{} names must be unique\n", id)
        ErrorLines(F)
        exit(499)
    }
    (void) M.cf++
    // inherit do option and logdir from preceding code block
    C = asarray(M.C, M.Ckeys[M.ckeys])
    nodo     = C->O.nodo
    O.logdir = C->O.logdir
    // prepare do-file
    if (nodo!=`TRUE') {
        fn = st_tempfilename()
        fput(M.dof.fh, "copy " + "`" + `"""' + O.fn + `"""' + "'" + " " +
            "`" + `"""' + fn + `"""' + "'")
        if (O.erase==`TRUE') {
            fput(M.dof.fh, "erase " + "`" + `"""' + O.fn + `"""' + "'")
        }
        fput(M.dof.fh, M.Ltag.CF + id)
    }
    // write tags to LaTeX file
    if (quietly!=`TRUE') fput(M.tex.fh, M.Ttag.CF + id + M.Ttag.CFend)
    // update database
    _Parse_CF_store(M, id, O, fn, nodo)
    AppendElement(M.CFkeys, M.cfkeys, id) // increases counter by 1
}

// update info on file in database and determine whether code needs to be run
void _Parse_CF_store(`Main' M, `Str' id, `CFopt' O, `Str' fn, `Bool' nodo)
{
    `Bool'   chflag
    `pCFile' CF
    
    // no preexisting version
    if (!asarray_contains(M.CF, id)) {
        if (nodo!=`TRUE') M.P.run[M.P.j] = `TRUE'
        CF = &(`CFILE'())
        CF->fn = fn
        CF->O = O
        asarray(M.CF, id, CF)
        M.update = `TRUE'
        return
    }
    // update preexisting version
    CF = asarray(M.CF, id)
    CF->fn = fn
    // - determine whether code needs to be run
    chflag = `FALSE'
    if       (CF->O.fn!=O.fn)                          chflag = `TRUE'
    else if ((CF->O.erase==`TRUE')!=(O.erase==`TRUE')) chflag = `TRUE'
    if (chflag) {
        if (nodo!=`TRUE') M.P.run[M.P.j] = `TRUE'
        CF->S0 = CF->S = NULL
        CF->O = O
        M.update = `TRUE'
        return
    }
    // - determine whether edited copy need refreshing
    chflag = `FALSE'
    if (CF->O!=O) {
        if      (CF->O.range!=O.range) chflag = `TRUE'
        else if (CF->O.subst!=O.subst) chflag = `TRUE'
        CF->O = O
    }
    // (not all changes in options will cause the db on disk to
    //  be updated; this is on purpose)
    if (chflag) {
        CF->S = NULL
        M.update = `TRUE'
    }
}

/*---------------------------------------------------------------------------*/
/* functions to handle inline expressions                                    */
/*---------------------------------------------------------------------------*/

// main function
void Parse_I(`Main' M, `Source' F)
{
    `Int' p
    `Str' s
    
    if (!M.run) return
    if (!(p = _Parse_I_find(M, F.S[F.i]))) {
        fput(M.tex.fh, F.S[F.i])
        return
    }
    s = F.S[F.i]
    while (p) {
        _Parse_I(M, s, p, F)
        p = _Parse_I_find(M, s)
    }
    fput(M.tex.fh, s) // write remainder of line + line break
}

// return position of inline expression, 0 if not found
`Int' _Parse_I_find(`Main' M, `Str' s)
{
    `Int' p
    
    p = strpos(s, M.tag.stres)
    if (!p) return(0)
    if (p>=_Parse_I_texcomment(s)) return(0)
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
        _Parse_I_immediate(M, exp, F)   // immediate expression
        return
    }
    (void) M.i++ // inline expression counter
    if (id=="") id = (M.P.j>1 ? M.P.id[M.P.j] + M.punct : "") + strofreal(M.i)
    else if (!st_islmname(id)) {
        errprintf("'%s' invalid name\n", id)
        ErrorLines(F)
        exit(7)
    }
    if (M.ikeys ? anyof(M.Ikeys[|1\M.ikeys|], id) : 0) {
        errprintf("'%s' already taken; inline expression names must be unique\n", id)
        ErrorLines(F)
        exit(499)
    }
    // prepare do-file
    if (M.Copt.nodo!=`TRUE') {          // should also depend on last C->O.nodo?
        fput(M.dof.fh, M.Ltag.I + id)
        fput(M.dof.fh, "display " + exp)
        fput(M.dof.fh, M.Ltag.Iend)
    }
    // add insert tag to LaTeX file
    fwrite(M.tex.fh, M.Ttag.I + id + M.Ttag.Iend)
    // update database
    _Parse_I_store(M, id, exp)
    AppendElement(M.Ikeys, M.ikeys, id) // increases counter by 1
}

void _Parse_I_immediate(`Main' M, `Str' exp, `Source' F)
{
    `Bool'   rc
    `Str'    nm, id
    
    exp = TabTrim(substr(exp,2,strlen(exp)-2)) // strip outer { }
    tokenset(M.t1, exp)
    nm = tokenget(M.t1)
    if (anyof((M.Itag.log, M.Itag.lognm), nm)) {
        id = _Parse_I_imid(F, tokenrest(M.t1), M.Lkeys, M.lkeys, "log")
        if (nm==M.Itag.log) fwrite(M.tex.fh, M.Ttag.L + id + M.Ttag.Lend)
        else                fwrite(M.tex.fh, M.Ttag.L+"?" + id + M.Ttag.Lend)
        return
    }
    if (anyof((M.Itag.graph, M.Itag.graphnm), nm)) {
        id = _Parse_I_imid(F, tokenrest(M.t1), M.Gkeys, M.gkeys, "graph")
        if (nm==M.Itag.graph) fwrite(M.tex.fh, M.Ttag.G + id + M.Ttag.Gend)
        else                  fwrite(M.tex.fh, M.Ttag.G+"?" + id + M.Ttag.Gend)
        return
    }
    if (anyof((M.Itag.cfile, M.Itag.cfilenm), nm)) {
        id = _Parse_I_imid(F, tokenrest(M.t1), M.CFkeys, M.cfkeys,
            "collected file")
        if (nm==M.Itag.cfile) fwrite(M.tex.fh, M.Ttag.CF + id + M.Ttag.CFend)
        else                  fwrite(M.tex.fh, M.Ttag.CF+"?" + id + M.Ttag.CFend)
        return
    }
    if ((rc = _stata("local sttex_value: display " + exp))) {
        ErrorLines(F)
        exit(rc)
    }
    fwrite(M.tex.fh, strtrim(st_local("sttex_value")))
}

`Str' _Parse_I_imid(`Source' F, `Str' id, `StrC' keys, `Int' n, `Str' el)
{
    id = TabTrim(id)
    if (id=="") {
        if (n) id = keys[n] // get id of preceding el
        if (id=="") {
            errprintf("no prior %s found\n", el)
            ErrorLines(F)
            exit(499)
        }
    }
    else if (!st_islmname(subinstr(id,".","_"))) {
        errprintf("'%s' invalid name\n", id)
        ErrorLines(F)
        exit(7)
    }
    return(id)
}

// return position of tex comment; missing if not found
`Int' _Parse_I_texcomment(`Str' s)
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

// update info on inline expression in database and determine whether code
// needs to be run
void _Parse_I_store(`Main' M, `Str' id, `Str' exp)
{
    `pInline' I
    
    // (updating M.P.run not needed; is done when creating M.Copt)
    // no preexisting version
    if (!asarray_contains(M.I, id)) {
        if (M.Copt.nodo!=`TRUE') M.P.run[M.P.j] = `TRUE'
        I = &(`INLINE'())
        I->cmd = &exp
        asarray(M.I, id, I)
        M.update = `TRUE'
        return
    }
    // update preexisting version
    I = asarray(M.I, id)
    if (*I->cmd!=exp) {
        if (M.Copt.nodo!=`TRUE') M.P.run[M.P.j] = `TRUE'
        I->cmd = &exp
        I->log = NULL
        M.update = `TRUE'
    }
}

/*---------------------------------------------------------------------------*/
/* further functions for input processing                                    */
/*---------------------------------------------------------------------------*/

// handle STignore; returns 1 if \endinput encountered
`Bool' Parse_Ignore(`Main' M, `Source' F)
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
        if (M.run) fput(M.tex.fh, F.S[F.i])
    }
    return(`FALSE')
}

// handle STremove; returns 1 if \endinput encountered
`Bool' Parse_Remove(`Main' M, `Source' F)
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
void Parse_Input(`Main' M, `Source' F)
{
    `Str'  fn
    
    F.i0 = F.i
    fn = TabTrim(Get_Arg(M, "{", "}", F))
    if (fn=="") {
        errprintf("invalid syntax; {it:filename} required\n")
        ErrorLines(F)
        exit(601)
    }
    if (!pathisabs(fn)) fn = pathjoin(M.srcdir, fn)
    if (!fileexists(fn)) {
        errprintf("file %s not found\n", fn)
        ErrorLines(F)
        exit(601)
    }
    ParseSrc(M, ImportSrc(fn, 1))
}

// handle \stappend{}
void Parse_Append(`Main' M, `Source' F)
{
    `Str'  fn, opts
    `StrC' S
    
    F.i0 = F.i
    fn = TabTrim(Get_Arg(M, "{", "}", F))
    if (fn=="") {
        errprintf("invalid syntax; {it:filename} required\n")
        ErrorLines(F)
        exit(601)
    }
    if (!pathisabs(fn)) fn = pathjoin(M.srcdir, fn)
    if (!fileexists(fn)) {
        errprintf("file %s not found\n", fn)
        ErrorLines(F)
        exit(601)
    }
    opts = TabTrim(Get_Arg(M, "[", "]", F))
    if (!M.run) return
    S = Cat(fn)
    if (opts!="") _Format_subst(S,
        _parse_matchist_expand(_parse_matchlist(opts, 1)))
    _Fput(M.tex.fh, S)
}

/*---------------------------------------------------------------------------*/
/* Delete old keys from associative arrays                                   */
/*---------------------------------------------------------------------------*/

void DeleteOldKeys(`Main' M)
{
    _DeleteOldKeys(M, M.C,  M.Ckeys)
    _DeleteOldKeys(M, M.L,  M.Lkeys)
    _DeleteOldKeys(M, M.G,  M.Gkeys)
    _DeleteOldKeys(M, M.CF, M.CFkeys)
    _DeleteOldKeys(M, M.I,  M.Ikeys)
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
    `BoolC'   up, dwn
    `AsArray' A
    
    up = dwn = P.run
    // upstream updating
    A = asarray_create()
    asarray_notfound(A, .)
    for (j = P.j; j; j--) asarray(A, P.id[j], j)
    for (j = P.j; j; j--) {
        if (P.run[j]==`FALSE') continue // nothing to do
        UpdateUpstream(P.pid, A, up, j)
    }
    // downstream updating
    A = asarray_create()
    asarray_notfound(A, J(0,1,.))
    for (j = P.j; j; j--) {
        // collect children
        pid = P.pid[j]
        if (pid==".") continue
        if (asarray_contains(A, pid)) continue
        asarray(A, pid, select(1::P.j, P.pid:==pid))
    }
    for (j = P.j; j; j--) {
        if (P.run[j]==`FALSE') continue // nothing to do
        UpdateDwnstream(P.id, A, dwn, j)
    }
    // store result
    P.run = (up+dwn):!=0
}

void UpdateUpstream(`StrC' pid, `AsArray' A, `BoolC' up, `Int' j0)
{
    `Int' j

    if (pid[j0]==".")  return // no parent
    j = asarray(A, pid[j0])
    if (j>=.)          return // parent not found; maybe issue error/warning?
    if (up[j]==`TRUE') return // already active
    up[j] = `TRUE'
    UpdateUpstream(pid, A, up, j)
}

void UpdateDwnstream(`StrC' id, `AsArray' A, `BoolC' dwn, `Int' j0)
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

void RemovePartsFromDofile(`Main' M, `BoolC' run, `IntC' l, `Int' J)
{
    `Int'  j, fh
    `StrC' S
    
    // read
    S = J(J, 1, "")
    fh = FOpen(M.dof.fn, "r")
    for (j=1; j<=J; j++) {
        if (run[j]) S[j] = fread(fh, l[j])      // read part
        else               fseek(fh, l[j], 0)   // skip part
    }
    FClose(fh)
    // write
    fh = FOpen(M.dof.fn, "w", "", 1)
    for (j=1; j<=J; j++) {
        if (run[j]) fwrite(fh, S[j])
    }
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
        // look for code block start
        if ((p=strpos(s, M.Ltag.C))) {
            // - get id
            id = substr(s, p+strlen(M.Ltag.C), .)
            if (!asarray_contains(M.C, id)) continue // no valid id
            // - collect results
            Collect_C(M, F, id)
        }
        // look for Graph
        else if ((p=strpos(s, M.Ltag.G))) {
            // - get id
            id = substr(s, p+strlen(M.Ltag.G), .)
            if (!asarray_contains(M.G, id)) continue // no valid id
            // - collect results
            Collect_G(M, id)
        }
        // look for collected file
        else if ((p=strpos(s, M.Ltag.CF))) {
            // - get id
            id = substr(s, p+strlen(M.Ltag.CF), .)
            if (!asarray_contains(M.CF, id)) continue // no valid id
            // - collect results
            Collect_CF(M, id)
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

// collect output form code block and apply log texman
void Collect_C(`Main' M, `Source' F, `Str' id)
{
    `StrC'   S
    `pCode'  C
    
    // find end
    (void) F.i++
    F.i0 = F.i
    for (; F.i<=F.n; F.i++) {
        if (strpos(F.S[F.i], M.Ltag.Cend)) break
    }
    // copy log
    if (F.i>F.i0) {
        S = F.S[|F.i0 \ F.i-1|]
        S[1] = "{com}" + S[1]
    }
    else S = J(0, 1, "")
    // apply texman and add pointer to database
    C = asarray(M.C, id)
    C->log = &S
    C->newlog = `TRUE'
    // - certify
    if (C->O.certify==`TRUE') Collect_C_cert(M, *C, id)
}

// certify that output is still the same
void Collect_C_cert(`Main' M, `Code' C, `Str' id)
{
    `pCode0' C0
    `StrC'   L0, L1
    
    if (!asarray_contains(M.C0, id)) {
        printf("(%s: no previous log available; certification skipped)\n", id)
        return
    }
    C0 = asarray(M.C0, id)
    if (C0->log==NULL) {
        printf("(%s: no previous log available; certification skipped)\n", id)
        return
    }
    if (*C.cmd!=*C0->cmd) {
        printf("(%s: code changed; certification skipped)\n", id)
        return
    }
    if (C.log==C0->log) {
        printf("(%s: log not updated; certification skipped)\n", id)
        return
    }
    if (*C.log!=*C0->log) {
        L0 = Translate_to_txt(*C0->log, C0->linesize)
        L1 = Translate_to_txt(*C.log, C.O.linesize)
        if (L1!=L0) {
            stata("set linesize 255") // linesize will be restored at end
            display("")
            errprintf("new version of log %s is different from previous version\n", id)
            Collect_C_cert_di(L1, L0)
            display("")
            errprintf("certification error\n")
            exit(499)
        }
    }
    printf("(%s: certification successful)\n", id)
}

// compare logs and display (first) difference
void Collect_C_cert_di(`StrC' L1, `StrC' L0)
{
    `Int' i, j, r, r1, r0, a, b, l
    `Str' fmt
    
    r1 = rows(L1); r0 = rows(L0); r = max((r1,r0))
    for (i=1; i<=r; i++) {
        if (i>r0) break
        if (i>r1) break
        if (L1[i]!=L0[i]) break
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
        display(sprintf(fmt + ": %s", strofreal(j), L0[j]), 1)
    }
    printf("\n{err}extract from new version:\n")
    for (j=a; j<=b; j++) {
        if (j>r1) {
            display("end of file", 1)
            break
        }
        display(sprintf(fmt + ": %s", strofreal(j), L1[j]), 1)
    }
}

void Collect_G(`Main' M, `Str' id)
{
    `pGraph' G

    G = asarray(M.G, id)
    Copy_GRfiles(G->fn, MkDir(M.tgtdir, G->O.dir), id, G->O.as, M.replace)
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

// import collected file from tempfile
void Collect_CF(`Main' M, `Str' id)
{
    `Str'    fn
    `pCFile' CF

    CF = asarray(M.CF, id)
    fn = CF->fn
    if (fn=="")          return // no tempfile created
    if (!fileexists(fn)) return // tempfile not found
    CF->S0 = &Cat(fn)
    CF->S  = NULL
}

// collect output form inline expression and apply log texman
void Collect_I(`Main' M, `Source' F, `Str' id)
{
    `Int'     i
    `StrC'    S
    `pInline' I
    
    // find end
    (void) F.i++
    F.i0 = F.i
    for (; F.i<=F.n; (void) F.i++) {
        if (strpos(F.S[F.i], M.Ltag.Iend)) break
    }
    // copy log
    if (F.i>F.i0) {
        S = F.S[|F.i0 \ F.i-1|]
        S[1] = "{com}"+S[1]
    }
    else S = J(0, 1, "")
    // apply texman and add to database
    S = Apply_Texman(S, 255)
    // find first line of output
    (void) _Format_log_read_cmd(M, S, i = 1, rows(S), `FALSE', `FALSE')
    i++
    if (i<=rows(S)) {
        S = strtrim(S[i])
        if (S=="{\smallskip}") S = "" // display evaluated to empty string
    }
    else S = ""
    // add to database
    I = asarray(M.I, id)
    I->log = &S
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

// translate log from smcl to text
`StrC' Translate_to_txt(`StrC' S, `Int' linesize)
{
    `Str' fn1, fn2, lsize
    
    fn1 = st_tempfilename()
    fn2 = st_tempfilename()
    Fput(fn1, S)
    if (linesize<.) lsize = strofreal(linesize)
    else            lsize = strofreal(st_numscalar("c(linesize)"))
    stata("qui translate " + "`" + `"""' + fn1 + `"""' + "'" +
        "`" + `"""' + fn2 + `"""' + "'" + 
        ", replace translator(smcl2log) linesize(" + lsize + ")")
    return(Cat(fn2))
}

/*---------------------------------------------------------------------------*/
/* apply formatting options / obtain command log                             */
/*---------------------------------------------------------------------------*/

void Format(`Main' M)
{
    `Int' i
    
    // need to use subfunction so that pointer to S will be distinct
    for (i=M.lkeys;  i; i--) _Format(M, M.Lkeys[i])
    for (i=M.cfkeys; i; i--) _Format_CF(M, M.CFkeys[i])
}

void _Format(`Main' M, `Str' id)
{
    `pLog'  L
    `StrC'  S;  `Unset' S
    `pStrC' S0; `Unset' S0

    // initialize
    L = asarray(M.L, id)
    // clear log if needs updating (because code block was evaluated)
    if (L->log!=NULL) _Format_check_newlog(M, *L)
    // exit if log does not need updating
    if (L->log!=NULL) {
        _Format_check_lnum(M, *L) // update line numbers counter
        return
    }
    L->newlog = `TRUE'
    // obtain raw log; S0 will contain pointer to raw log of (first) block
    if (_Format_get_log(M, *L, S, S0)) return // exit if raw log not available
    // basic formatting
    if (L->O.code!=`TRUE') _Format_log(M, *L, S)  // results log
    else                   _Format_clog(M, *L, S) // code log
    // apply tags and substitutions
    _Format_subst(S, L->O.subst)
    _Format_alert(S, L->O.alert)
    _Format_tag(S, L->O.tag)
    // add line numbers, select range, apply line tags
    _Format_lnum(S, *L, M.lnum)
    // check whether edited log needs to be saved
    if (S!=*S0) L->log = &S
    else        L->log = S0
}

// clear results log if raw log of code block was refreshed; clear code log if
// commands in code block changed 
void _Format_check_newlog(`Main' M, `Log' L)
{
    `Int'   i
    `pCode' C

    if (L.O.code!=`TRUE') {
        for (i=length(L.ids); i; i--) {
            C = asarray(M.C, L.ids[i])
            if (C->newlog==`TRUE') {
                _Parse_L_clear(L)
                return
            }
        }
        return
    }
    for (i=length(L.ids); i; i--) {
        C = asarray(M.C, L.ids[i])
        if (C->newcmd==`TRUE') {
            _Parse_L_clear(L)
            return
        }
    }
}

// check whether line numbers need updating (e.g. if order of elements changed
// or locnt status changed for preceding elements); also updates M.lnum
void _Format_check_lnum(`Main' M, `Log' L)
{
    `Int' r
    
    if (L.O.lnumbers!=`TRUE') return
    r = rows(L.Lnum.idx)
    if (!r) return
    if (L.O.lcont==`TRUE') {
        if (L.Lnum.i0!=M.lnum) { // offset changed
            L.Lnum.idx = L.Lnum.idx :+ (M.lnum - L.Lnum.i0)
            L.Lnum.i0 = M.lnum
            L.newlog = `TRUE'
            M.update = `TRUE'
        }
    }
    M.lnum = L.Lnum.idx[r]
}

// copy raw logs from referenced code blocks; working from bottom to top such
// that first block will be processed last (i.e. the function will return with
// S0 set to the pointer off the raw log of the first code block)
`Bool' _Format_get_log(`Main' M, `Log' L, `StrC' S, `pStrC' S0)
{
    `Int'   i
    `pCode' C
    
    // number of keys
    i = length(L.ids)
    // results log
    if (L.O.code!=`TRUE') {
        for (; i; i--) {
            C = asarray(M.C, L.ids[i])
            S0 = _Format_get_log_tex(M, *C, L.ids[i])
            if (S0==NULL) return(1) // no log available
            S = *S0 \ S
        }
        return(0)
    }
    // code log
    for (; i; i--) {
        C = asarray(M.C, L.ids[i])
        S0 = C->cmd
        S = *S0 \ S
    }
    return(0)
}

// translate SMCL log to tex
`pStrC' _Format_get_log_tex(`Main' M, `Code' C, `Str' id)
{
    `pStrC' S
    
    if (asarray_contains(M.Ltex, id)) return(asarray(M.Ltex, id))
    if (C.log==NULL) return(NULL)
    S = &(Apply_Texman(*C.log, C.O.linesize))
    asarray(M.Ltex, id, S)
    return(S)
}

// formatting of results log --------------------------------------------------

// process log file
void _Format_log(`Main' M, `Log' L, `StrC' S)
{
    `Bool'  inmata, hasoom
    `BoolC' p
    `Int'   i, j, r, k, K
    `IntM'  idx
    `Str'   s, prompt

    if ((r=rows(S))<1) return
    p = J(r, 1, `TRUE')
    idx = J(r, 4, .) // index table: start of cmd, end of cmd, end of output, has oom
    prompt = substr(S[1], 1, 2)
    if       (prompt==": ") inmata = `TRUE'
    else if  (prompt==". ") inmata = `FALSE'
    else                    exit(499)   // should never happen
    j = 0 // command counter
    hasoom = `FALSE'
    for (i=1; i<=r; i++) {
        s = strltrim(substr(S[i],3,.)) // strip prompt
        // handle STcnp
        if (s==M.Ltag.cnp) {
            if (i<r) S[i+1] = substr(S[i],1,2) + substr(S[i+1],3,.) // copy prompt
            S[i] = "\cnp"
            continue
        }
        if (!inmata) {
            // handle STqui
            if (s==M.Ltag.qui) {
                if (i<r) S[i+1] = substr(S[i],1,2) + substr(S[i+1],3,.) // copy prompt
                p[i] = `FALSE'
                continue
            }
            // handle SToom
            if (s==M.Ltag.oom) {
                if (i<r) S[i+1] = substr(S[i],1,2) + substr(S[i+1],3,.) // copy prompt
                p[i] = `FALSE'
                idx[j+1, 4] = 1
                hasoom = `TRUE'
                continue
            }
        }
        // read command line (and strip line break comments)
        ++j
        idx[j, 1] = i   // first line of commands
        s = _Format_log_read_cmd(M, S, i, r, inmata, L.O.nolb==`TRUE')
        idx[j, 2] = i   // last line of command
        // nocommands option
        if (L.O.nocommands==`TRUE') {
            p[|idx[j,1] \ i|] = J(i-idx[j,1]+1, 1, `FALSE')
        }
        // nogt/noprompt option
        else {
            if (L.O.noprompt==`TRUE') {
                // remove prompt in first line of command
                k = idx[j, 1]
                if (substr(S[k],1,2)==prompt) S[k] = substr(S[k],3,.)
            }
            if (L.O.nogt==`TRUE') {
                // remove "> " in second and following lines of command
                k = idx[j, 1] + 1
                K = idx[j, 2]
                for (; k<=K; k++) {
                    if (substr(S[k],1,2)=="> ") S[k] = "  " + substr(S[k],3,.)
                }
            }
        }
        // update mata status
        s = strtrim(s)
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
            if (substr(S[i+1],1,2)==prompt) break
            i++
        }
        idx[j, 3] = i   // last line of output
    }
    idx = idx[|1,1\j,.|]
    // handle SToom
    if (hasoom) {
        r = rows(idx)
        for (j=1;j<=r;j++) {
            if (idx[j,4]!=1) continue
            __Format_log_oom(S, p, idx, j)
        }
    }
    // handle drop(), qui(), oom(), cnp()
    if (length(L.O.drop)) _Format_log_edit(L.O.drop, S, p, idx, 1)
    if (length(L.O.cnp))  _Format_log_edit(L.O.cnp,  S, p, idx, 2)
    if (length(L.O.qui))  _Format_log_edit(L.O.qui,  S, p, idx, 3)
    if (length(L.O.oom))  _Format_log_edit(L.O.oom,  S, p, idx, 4)
    // select relevant output
    S = select(S, p)
}

void _Format_log_edit(`IntR' K, `StrC' S, `BoolC' p, `IntM' idx, `Int' opt)
{
    `Int' k, j, n
    
    n = rows(idx)
    for (k=1;k<=cols(K);k++) {
        j = K[k]
        if (j<0) j = n + j + 1
        else if (j==.) j = n
        if (j<1) continue
        if (j>n) continue
        if (opt==1)      _Format_log_drop(p, idx, j)
        else if (opt==2) _Format_log_cnp(S, p, idx, j)
        else if (opt==3) _Format_log_qui(S, p, idx, j)
        else if (opt==4) _Format_log_oom(S, p, idx, j)
    }
}

void _Format_log_drop(`BoolC' p, `IntM' idx, `Int' j)
{
    `Int' a, b
    
    a = idx[j,1]; b = idx[j,3]
    p[|a \ b|] = J(b-a+1, 1, `FALSE')
}

void _Format_log_qui(`StrC' S, `BoolC' p, `IntM' idx, `Int' j)
{
    `Int' a, b
    
    a = idx[j,2]+1; b = idx[j,3]
    if (S[b]=="{\smallskip}") b--  // do not remove last line
    if (a>b) return
    p[|a \ b|] = J(b-a+1, 1, `FALSE')
}

void _Format_log_oom(`StrC' S, `BoolC' p, `IntM' idx, `Int' j)
{
    __Format_log_oom(S, p, idx, j)
    _Format_log_qui(S, p, idx, j)
}

void __Format_log_oom(`StrC' S, `BoolC' p, `IntM' idx, `Int' j)
{
    `Int' i
    
    i = idx[j,2] // last line of command
    _Format_log_insertrows(S, p, i, 2)
    S[i+1] = "{\smallskip}"; S[i+2] = "\oom"
    // update index table
    idx[|j,2\j,3|] = idx[|j,2\j,3|] :+ 2
    if (j<rows(idx)) idx[|j+1,1\.,3|] = idx[|j+1,1\.,3|] :+ 2
}

void _Format_log_cnp(`StrC' S, `BoolC' p, `IntM' idx, `Int' j)
{
    `Int' i
    
    i = idx[j,3]
    _Format_log_insertrows(S, p, i, 1)
    S[i+1] = "\cnp"
    // update index table
    if (j<rows(idx)) idx[|j+1,1\.,3|] = idx[|j+1,1\.,3|] :+ 1
}

void _Format_log_insertrows(`StrC' S, `BoolC' p, `Int' i, `Int' n)
{
    if (i==rows(p)) {
        p = p \ J(n, 1, `TRUE')
        S = S \ J(n, 1, "")
    }
    else {
        p = p[|1 \ i|] \ J(n, 1, `TRUE') \ p[|i+1 \ .|]
        S = S[|1 \ i|] \ J(n, 1, "")     \ S[|i+1 \ .|]
    }
}

// read command in log and optionally strip line break comments
// (numbered command lines in loops and programs: processes the
// entire block, but only returns the first command)
`Str' _Format_log_read_cmd(`Main' M, `StrC' S, `Int' i, `Int' r, 
    `Bool' inmata, `Bool' lbstrip) 
{
    `Int'  lb, cb, j, num, stub
    `Str'  s, stmp, cmd
    
    stub = 2
    j = lb = cb = num = 0
    cmd = s = _Format_log_read_cmdline(M, substr(S[i],3,.), cb, lb, inmata, "")
    while (1) {
        if (lbstrip) {
            if (lb) S[i] = substr(S[i], 1, stub) + substr(S[i], stub+1, lb-2)
            stub = 2
        }
        if (i==r) return(cmd)
        stmp = S[i+1]
        if (substr(stmp,1,2)!="> ") {
            if (substr(stmp,1,2)!=". ") {
                num = _Format_log_check_numcmd(stmp, num, stub)
                if (num==0) return(cmd)
                j++; s = "" // start new command
            }
            else if (num==0) return(cmd)
            else stmp = substr(stmp,3,.)
        }
        else stmp = substr(stmp,3,.)
        i++
        stmp = _Format_log_read_cmdline(M, stmp, cb, lb, inmata, s)
        s = s + (cb ? "" : (s!="" ? " " : "")) + stmp
        if (j==0) cmd = s
    }
    return(cmd)
}

// check whether line starts with "  #. " (loops and program definitions)
`Int' _Format_log_check_numcmd(`Str' s, `Int' num, `Int' stub)
{
    num++
    if (__Format_log_check_numcmd(s, num, stub)==0) {
        if (num>1) return(0)
        num++ // loops (e.g. foreach) start with 2, not with 1
        if (__Format_log_check_numcmd(s, num, stub)==0) return(0)
    }
    return(num)
}
`Bool' __Format_log_check_numcmd(`Str' s, `Int' num, `Int' stub)
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
`Str' _Format_log_read_cmdline(
    `Main' M,
    `Str'  s,          // command line to be parsed
    `Int'  cb,         // will be set to nesting level of /*...*/
    `Int'  lb,         // will be set to position of ///...
    `Bool' nostar,     // do not parse "*..."
    `Str'  cmd0)       // piece of command from previous line
{   
    `Str' cmd
    
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
    cmd = __Format_log_read_cmdline(M.t, s, cb, lb)
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

`Str' __Format_log_read_cmdline(`Cmdline' t, `Str' s, `Int' cb, `Int' p)
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

// formatting of code log -----------------------------------------------------

// apply formatting options to clog
void _Format_clog(`Main' M, `Log' L, `StrC' S)
{
    _Format_clog_striptags(M, S)
    if (L.O.nolb==`TRUE') _Format_clog_nolb(M, S)
    if (L.O.verb!=`TRUE' & L.O.notex!=`TRUE') {
        S = _Format_clog_texman(S, L.O.clsize, M.lognm)
        if (L.O.nogt==`TRUE')    _Format_clog_nogt(S)
        if (L.O.nolskip==`TRUE') _Format_clog_nolskip(S)
    }
}

// remove qui/oom/cnp tags
void _Format_clog_striptags(`Main' M, `StrC' S)
{
    `Int'  i
    `Str'  s
    `IntC' p
    
    if (any(strpos(S, M.Ltag.ST))) {
        i = rows(S)
        p = J(i,1,1)
        for (; i; i--) {
            s = TabTrim(S[i])
            if      (s==M.Ltag.qui) p[i] = 0
            else if (s==M.Ltag.oom) p[i] = 0
            else if (s==M.Ltag.cnp) p[i] = 0
        }
        S = select(S, p)
    }
}

// remove line break comments
void _Format_clog_nolb(`Main' M, `StrC' S)
{
    `Int'  i, r, lb, cb

    r = rows(S)
    if (!r) return
    lb = cb = 0
    for (i=1;i<=r;i++) {
        (void) __Format_log_read_cmdline(M.t, S[i], cb, lb)
        if (lb) S[i] = substr(S[i], 1, lb-2)
        else if (substr(S[i],1,3)=="///") S[i] = ""
    }
}

// code option: process commands by log texman
`StrC' _Format_clog_texman(`StrC' S, `Int' linesize, `Str' lognm)
{
    `Str' fn1, fn2, lsize, lsize0
    
    fn1 = st_tempfilename()
    fn2 = st_tempfilename()
    Fput(fn1, S)
    lsize0 = strofreal(st_numscalar("c(linesize)"))
    lsize  = linesize<. ? strofreal(linesize) : "255"
    stata("set linesize " + lsize)
    stata("quietly log using " + "`" + `"""' + fn2 + `"""' + "'" + 
        ", smcl replace name(" + lognm + ")")
    stata("type " + "`" + `"""' + fn1 + `"""' + "'")
    stata("quietly log close " + lognm)
    stata("set linesize " + lsize0)
    stata("qui log texman " + "`" + `"""' + fn2 + `"""' + "'" +
        "`" + `"""' + fn1 + `"""' + "'" + ", replace ll(" + lsize + ")")
    return(Cat(fn1))
}

// remove "> " at beginning of line
void _Format_clog_nogt(`StrC' S)
{
    `Int'  r
    `IntC' p
    
    r = rows(S)
    if (!r) return
    p = select(1::r, substr(S,1,2):=="> ")
    if (length(p)) S[p] = "  " :+ substr(S[p], 3, .)
}

// restore blank lines
void _Format_clog_nolskip(`StrC' S)
{
    `Int'  r
    `IntC' p
    
    r = rows(S)
    if (!r) return
    p = select(1::r, S:=="{\smallskip}")
    r = length(p)
    if (r) S[p] = J(r, 1, "")
}

// format collected files -----------------------------------------------------

void _Format_CF(`Main' M, `Str' id)
{
    `pCFile' CF
    `StrC'   S
    `IntR'   range

    // initialize
    CF = asarray(M.CF, id)
    // nothing to do
    if (CF->S!=NULL) return
    // exit if original file not available
    if (CF->S0==NULL) return
    // check whether any editing needed
    CF->newfile = `TRUE'
    if (!cols(CF->O.range) & !rows(CF->O.subst)) {
        CF->S = CF->S0
        return
    }
    // select range and apply substitutions
    S = *CF->S0
    range = CF->O.range
    if (cols(range)) {
        range[2] = min((range[2], rows(S)))
        if (range[1]<=rows(S)) S = S[|range'|]
    }
    _Format_subst(S, CF->O.subst)
    // check whether edited file needs to be saved
    if (S!=*CF->S0) CF->S = &S
    else            CF->S = CF->S0
}

// common formatting functions ------------------------------------------------

// apply substitutions 
void _Format_subst(`StrC' f, `StrM' subst) // also used by Parse_Append()
{
    `Int' i, k
    
    k = rows(subst)
    if (!k) return
    for (i=1; i<=k; i++) f = subinstr(f, subst[i,1], subst[i,2])
}

// add \alert{} to specified tokens
void _Format_alert(`StrC' f, `StrC' alert)
{
    `Int' i, k
    
    k = length(alert)
    if (!k) return
    for (i=1; i<=k; i++) f = subinstr(f, alert[i], "\alert{"+alert[i]+"}")
}

// add tags to specified tokens
void _Format_tag(`StrC' f, `StrM' tag)
{
    `Int' i, k
    
    k = rows(tag)
    if (!k) return
    for (i=1; i<=k; i++) f = subinstr(f, tag[i,1], tag[i,2]+tag[i,1]+tag[i,3])
}

// add select range, apply line numbers, apply line tags
void _Format_lnum(`StrC' f, `Log' L, `Int' l0)
{
    `BoolC' tag
    `IntC'  idx
    
    // whether to do anything
    if (!length(L.O.range)) {
        if (L.O.lnumbers!=`TRUE') {
            if (!rows(L.O.ltag)) return
        }
    }
    // generate line index
    tag = !((f:=="\cnp") + (f:=="\oom") + (f:=="{\smallskip}"))
    idx = runningsum(tag)
    // select range (also updates tag and idx)
    if (length(L.O.range)) _Format_lnum_range(f, tag, idx, L.O.range)
    // add line numbers
    if (L.O.lnumbers==`TRUE') _Format_lnum_lnum(tag, idx, L.Lnum, L.O.lcont, l0)
    // apply line tags
    if (rows(L.O.ltag)) _Format_lnum_ltag(tag, idx, L, L.O.ltag)
}

void _Format_lnum_range(`StrC' f, `BoolC' tag, `IntC' idx, `IntR' range)
{
    `IntC'  p
    
    p   = select(1::rows(idx), idx:>=range[1] :& idx:<=range[2])
    f   = f[p]
    tag = tag[p]
    idx = idx[p]
    if (rows(p)) {
        if (idx[1]>1) idx = idx :- (idx[1]-1) // shift idx if necessary
    }
}

void _Format_lnum_lnum(`BoolC' tag, `IntC' idx, `Lnum' Lnum, `Bool' lcont,
    `Int' i0)
{
    if (lcont==`TRUE') Lnum.i0 = i0 // offset
    else               Lnum.i0 = 0
    if  (rows(tag)) {
        Lnum.p   = select(1::rows(tag), tag)
        Lnum.idx = idx[Lnum.p] :+ Lnum.i0
        if (rows(Lnum.idx)) i0 = Lnum.idx[rows(Lnum.idx)] // update line counter
    }
}

void _Format_lnum_ltag(`BoolC' tag, `IntC' idx, `Log' L, `StrM' ltag)
{
    `Int'  i, r, j, c, n
    `IntR' lnum
    `IntC' p

    n = rows(idx)
    L.lhs = L.rhs = J(n, 1, "")
    if (!n) return
    r = rows(ltag)
    for (i=1;i<=r;i++) {
        lnum = strtoreal(tokens(ltag[i,1]))
        c = cols(lnum)
        for (j=1;j<=c;j++) {
            p = select(1::n, (idx:==lnum[j]) :& tag)
            if (!length(p)) continue // no matching lines
            L.lhs[p] = ltag[i,2] :+ L.lhs[p]
            L.rhs[p] = L.rhs[p] :+ ltag[i,3]
        }
    }
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
            if      (t==1) Weave_L(M, s, p)  // log
            else if (t==2) Weave_G(M, s, p)  // graph
            else if (t==3) Weave_CF(M, s, p) // collected file
            else if (t==4) Weave_I(M, s, p)  // inline expression
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
    if ((p1 = strpos(s, M.Ttag.L))>0) {
        if (p1<p) {
            p = p1; t = 1
        }
    }
    if ((p1 = strpos(s, M.Ttag.G))>0) {
        if (p1<p) {
            p = p1; t = 2
        }
    }
    if ((p1 = strpos(s, M.Ttag.CF))>0) {
        if (p1<p) {
            p = p1; t = 3
        }
    }
    if ((p1 = strpos(s, M.Ttag.I))>0) {
        if (p1<p) {
            p = p1; t = 4
        }
    }
    return(t)
}

void Weave_L(`Main' M, `Str' s, `Int' a)
{
    `Bool' fnonly
    `Int'  l, b
    `Str'  id
    `pLog' L
    
    // parsing
    l = strlen(M.Ttag.L)
    b = strpos(substr(s, a+l, .), M.Ttag.Lend)
    if (b==0) { // end tag not found
        fwrite(M.tgt.fh, substr(s, 1, a+l-1))
        s = substr(s, a+l, .)
        return
    }
    // check whether whether \stres{{logname}}
    fnonly = substr(s,a+l,1)=="?"
    if (fnonly) {
        l++
        b--
    }
    // get id
    id = substr(s, a+l, b-1)
    l = a + l + b + strlen(M.Ttag.Lend) - 2
    // write start of line
    fwrite(M.tgt.fh, substr(s, 1, a-1))
    s = substr(s, l+1, .)
    // add log to LaTeX file
    L = asarray(M.L, id)
    if (!length(L)) { // no such id in database
        fwrite(M.tgt.fh, Weave_id_err(id, "log"))
        return
    }
    if (fnonly) { // if \stres{{logname}}: add filename only
        fwrite(M.tgt.fh, MkTexfn(L->O.logdir, id, ".log.tex"))
        M.logsave = L->save = `TRUE' // need to save log on disc
        return
    }
    if (L->O.scale<.) {
        if (L->O.beamer!=`TRUE') fwrite(M.tgt.fh, "\noindent")
        fput(M.tgt.fh, "\scalebox{" + sprintf("%g", L->O.scale) + "}{%")
        if (L->O.blstretch<.) {
            fput(M.tgt.fh, "\renewcommand{\baselinestretch}{" +
            sprintf("%g", L->O.blstretch) + "}%")
        }
        if (L->O.scale==1) fput(M.tgt.fh, "\begin{minipage}{\linewidth}%")
        else {
            if (L->O.beamer!=`TRUE') {
                fput(M.tgt.fh, "\setlength{\leftmargini}{\leftmargini/\real{" +
                    sprintf("%g", L->O.scale) + "}}%")
            }
            fput(M.tgt.fh, "\begin{minipage}{\linewidth/\real{" +
                sprintf("%g", L->O.scale) + "}}%")
        }
    }
    else if (L->O.blstretch<.) {
        fput(M.tgt.fh, "\begingroup\renewcommand{\baselinestretch}{" +
            sprintf("%g", L->O.blstretch) + "}%")
    }
    if (L->O.nobegin!=`TRUE') fwrite(M.tgt.fh, L->O.Begin)
    if (L->O.statc!=`TRUE') {
        fwrite(M.tgt.fh, "\input{" + MkTexfn(L->O.logdir, id, ".log.tex") + "}")
        M.logsave = L->save = `TRUE' // need to save log on disc
    }
    else {
        fput(M.tgt.fh, "")
        _Fput(M.tgt.fh, Weave_L_log(*L))
    }
    if (L->O.noend!=`TRUE') fwrite(M.tgt.fh, L->O.End)
    if (L->O.scale<.) {
        fwrite(M.tgt.fh, sprintf("\n\end{minipage}}"))
    }
    else if (L->O.blstretch<.) fwrite(M.tgt.fh, "\endgroup")
}

`StrC' Weave_L_log(`Log' L)
{
    `Int'  r
    `StrC' S, lnum
    
    if (L.log==NULL) {
        if (L.O.code==`TRUE') return("(error: log not available)")
        return("(error: log not available)" \ "{\smallskip}")
    }
    S = *L.log
    if (L.O.code==`TRUE' & L.O.verb==`TRUE') {
        if (L.O.lnumbers==`TRUE') {
            r = rows(L.Lnum.idx)
            if (r) {
                lnum = strofreal(L.Lnum.idx)
                lnum = (strlen(lnum[r]) :- strlen(lnum)) :* " " + lnum
                S[L.Lnum.p] = lnum :+ L.O.lsuffix :+ S[L.Lnum.p]
            }
        }
        if (rows(L.O.ltag)) S = L.lhs + S + L.rhs
        S = "\begin{verbatim}" \ S \ "\end{verbatim}"
    }
    else {
        if (L.O.lnumbers==`TRUE') S[L.Lnum.p] = 
            ("\stlnum{":+strofreal(L.Lnum.idx):+L.O.lsuffix:+"}") :+ S[L.Lnum.p]
        if (rows(L.O.ltag)) S = L.lhs + S + L.rhs
    }
    return(S)
}

void Weave_G(`Main' M, `Str' s, `Int' a)
{
    `Bool'   fnonly
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
    // check whether whether \stres{{graphname}}
    fnonly = substr(s,a+l,1)=="?"
    if (fnonly) {
        l++
        b--
    }
    // get id
    id = substr(s, a+l, b-1)
    l = a + l + b + strlen(M.Ttag.Gend) - 2
    // write start of line
    fwrite(M.tgt.fh, substr(s, 1, a-1))
    s = substr(s, l+1, .)
    // add graph to LaTeX file
    G = asarray(M.G, id)
    if (!length(G)) { // no such id in database
        fwrite(M.tgt.fh, Weave_id_err(id, "graph"))
        return
    }
    if (fnonly) { // if \stres{{graphname}}: add filename only (without suffix)
        fwrite(M.tex.fh, MkTexfn(G->O.dir, id))
        return
    }
    if (G->O.center==`TRUE') fwrite(M.tgt.fh, "\begin{center}")
    if (!fileexists(pathjoin(MkDir(M.tgtdir, G->O.dir), id)+"."+G->O.as[1])) {
        fwrite(M.tgt.fh, "\textbf{(error:\ graph not available)}")
    }
    else if (G->O.epsfig==`TRUE') {
        fwrite(M.tgt.fh, "\epsfig{file=" + MkTexfn(G->O.dir, id) +
            (G->O.suffix==`TRUE' ? "." + G->O.as[1] : "") + 
            (G->O.args!="" ? "," + G->O.args : "") + "}")
    }
    else {
        fwrite(M.tgt.fh, "\includegraphics")
        if (G->O.args!="") fwrite(M.tgt.fh, "[" + G->O.args + "]")
        fwrite(M.tgt.fh, "{" + MkTexfn(G->O.dir, id) + 
            (G->O.suffix==`TRUE' ? "." + G->O.as[1] : "") + "}")
    }
    if (G->O.center==`TRUE') fwrite(M.tgt.fh, "\end{center}")
}

void Weave_CF(`Main' M, `Str' s, `Int' a)
{
    `Bool'   fnonly
    `Int'    l, b
    `Str'    id, fn
    `pCFile' CF
    
    // parsing
    l = strlen(M.Ttag.CF)
    b = strpos(substr(s, a+l, .), M.Ttag.CFend)
    if (b==0) { // end tag not found
        fwrite(M.tgt.fh, substr(s, 1, a+l-1))
        s = substr(s, a+l, .)
        return
    }
    // check whether whether \stres{{fname}}
    fnonly = substr(s,a+l,1)=="?"
    if (fnonly) {
        l++
        b--
    }
    // get id
    id = substr(s, a+l, b-1)
    l = a + l + b + strlen(M.Ttag.CFend) - 2
    // write start of line
    fwrite(M.tgt.fh, substr(s, 1, a-1))
    s = substr(s, l+1, .)
    // add collected file to LaTeX file
    CF = asarray(M.CF, id)
    if (!length(CF)) { // no such id in database
        fwrite(M.tgt.fh, Weave_id_err(id, "collected file"))
        return
    }
    if (fnonly | CF->O.nostatic==`TRUE') { // add filename
        fn = MkTexfn(CF->O.logdir, id, pathsuffix(CF->O.fn))
        if (fnonly) fwrite(M.tgt.fh, fn)
        else        fwrite(M.tgt.fh, "\input{" +  fn + "}")
        M.cfsave = CF->save = `TRUE' // need to save log on disc
        return
    }
    if (CF->S==NULL) _Fput(M.tgt.fh, "(error: file contents not available)", 1)
    else             _Fput(M.tgt.fh, *CF->S, 1)
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
    // get id
    id = substr(s, a+l, b-1)
    l = a + l + b + strlen(M.Ttag.Iend) - 2
    // write start of line
    fwrite(M.tgt.fh, substr(s, 1, a-1))
    s = substr(s, l+1, .)
    // add result to LaTeX file
    I = asarray(M.I, id)
    if (!length(I)) { // no such id in database (cannot happen, can it?)
        fwrite(M.tgt.fh, Weave_id_err(id, "result"))
        return
    }
    fwrite(M.tgt.fh, (I->log!=NULL ? *I->log : 
        ("\textbf{(error:\ result not available)}")))
}

`Str' Weave_id_err(`Str' id, `Str' el)
{
    `Str' msg
    
    msg = subinstr(id, "_", "\_")
    return(sprintf("\\textbf{(error:\ %s %s not found)}", el, msg))
}

/*---------------------------------------------------------------------------*/
/* create external log files                                                 */
/*---------------------------------------------------------------------------*/

void External_logfiles(`Main' M)
{
    `Int'   i
    `Str'   id, dir, fn
    `StrC'  keys
    `BoolC' p
    `pLog'  L
    
    if (M.logsave==`FALSE') return // nothing to do
    keys = M.Lkeys
    i = M.lkeys
    p = J(i, 1, `FALSE')
    for (; i; i--) {
        L = asarray(M.L, keys[i])
        if (L->save==`TRUE') p[i] = `TRUE'
    }
    keys = select(keys, p)
    i = length(keys)
    if (i==0) return // nothing to do
    for (; i; i--) {
        id = keys[i]
        L = asarray(M.L, id)
        dir = MkDir(M.tgtdir, L->O.logdir)
        fn = pathjoin(dir, id) + ".log.tex"
        if (L->newlog!=`TRUE') {
            if (fileexists(fn)) continue
        }
        if (!direxists(dir)) mkdir(dir)
        Fput(fn, Weave_L_log(*L))
    }
}

/*---------------------------------------------------------------------------*/
/* create external files for collected files                                 */
/*---------------------------------------------------------------------------*/

void External_cfiles(`Main' M)
{
    `Int'    i
    `Str'    id, dir, fn
    `StrC'   keys
    `BoolC'  p
    `pCFile' CF
    
    if (M.cfsave==`FALSE') return // nothing to do
    keys = M.CFkeys
    i = M.cfkeys
    p = J(i, 1, `FALSE')
    for (; i; i--) {
        CF = asarray(M.CF, keys[i])
        if (CF->save==`TRUE') p[i] = `TRUE'
    }
    keys = select(keys, p)
    i = length(keys)
    if (i==0) return // nothing to do
    for (; i; i--) {
        id = keys[i]
        CF = asarray(M.CF, id)
        dir = MkDir(M.tgtdir, CF->O.logdir)
        fn = pathjoin(dir, id) + pathsuffix(CF->O.fn)
        if (CF->newfile!=`TRUE') {
            if (fileexists(fn)) continue
        }
        if (!direxists(dir)) mkdir(dir)
        if (CF->S==NULL) Fput(fn, "(error: file contents not available)")
        else             Fput(fn, *CF->S)
    }
}

/*---------------------------------------------------------------------------*/
/* create external do files                                                  */
/*---------------------------------------------------------------------------*/

void External_dofiles(`Main' M)
{
    `Int'    i
    `Str'    id, dir, fn
    `StrC'   keys
    `BoolC'  p
    `pCode'  C

    if (M.dosave==`FALSE') return // nothing to do
    i = M.ckeys
    keys = M.Ckeys
    p = J(i, 1, `FALSE')
    for (; i; i--) {
        C = asarray(M.C, keys[i])
        if (C->O.dosave==`TRUE') p[i] = `TRUE'
    }
    keys = select(keys, p)
    i = length(keys)
    if (i==0) return // nothing to do
    for (; i; i--) {
        id = keys[i]
        C = asarray(M.C, id)
        dir = C->O.dodir
        if (dir=="") dir = C->O.logdir
        dir = MkDir(M.tgtdir, dir)
        fn = pathjoin(dir, id) + ".do"
        if (C->newcmd!=`TRUE') {
            if (fileexists(fn)) continue
        }
        if (!direxists(dir)) mkdir(dir)
        Fput(fn, Get_cmd(M, *C))
    }
}

`StrC' Get_cmd(`Main' M, `Code' C)
{
    `StrC' cmd
    
    cmd = *C.cmd
    _Format_clog_striptags(M, cmd)
    if (C.mata==`TRUE') cmd = "mata:" \ cmd \ "end"
    return(cmd)
}

/*---------------------------------------------------------------------------*/
/* extract stata code                                                        */
/*---------------------------------------------------------------------------*/

void Extract_code(`Main' M)
{
    `Int'    i, j
    `Str'    title
    `pCode'  C
    
    j = 0
    M.tgt.fh = FOpen(M.tgt.fn, "w", "", 1)
    for (i=1;i<=M.ckeys;i++) {
        C = asarray(M.C, M.Ckeys[i])
        if (C->O.noextract==`TRUE') continue
        if (C->O.nogap!=`TRUE') {
            if (j) fput(M.tgt.fh, "") // empty line (unless to of file)
        }
        j++
        if (C->O.notitle!=`TRUE') {
            title = C->O.title
            if (title=="") title = M.Ckeys[i]
            fput(M.tgt.fh, "// " + title)
        }
        _Fput(M.tgt.fh, Get_cmd(M, *C))
    }
    FClose(M.tgt.fh, "")
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
    
    if (F.i0==F.i) {
        errprintf("error on line %g in %s:\n", F.i, F.fn)
        errprintf("    %s\n", F.S[F.i0])
    }
    else {
        errprintf("error on lines %g-%g in %s:\n", F.i0, F.i, F.fn)
        for (i=F.i0; i<=F.i; i++) errprintf("    %s\n", F.S[i])
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

// compile path for log files, graphs, and dofiles
`Str' MkDir(`Str' tgtdir, `Str' dir)
{
    if (dir==".")         return(tgtdir)
    if (!pathisabs(dir))  return(pathjoin(tgtdir, dir))
    return(dir) // absolute path
}

// compile path/filename for inclusion in LaTeX
`Str' MkTexfn(`Str' dir, `Str' fn, | `Str' suffix)
{
    `Str' path
    
    if (dir==".") return(fn + suffix)
    path = pathjoin(dir, fn)
    if (st_global("c(os)")=="Windows") path = subinstr(path, "\", "/")
    return(path + suffix)
}

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
    `Int' i, n
    
    n = rows(S)
    if (nolb==`TRUE') {  // leave last line open
        for (i=1; i<n; i++) fput(fh, S[i])
        if (n>0)            fwrite(fh, S[i])
        return
    }
    for (i=1; i<=n; i++) fput(fh, S[i])
}

// display error if file already exists (unless replace)
void Fexists(`Str' fn, `Bool' replace)
{
    if (replace) return
    if (fileexists(fn)) {
        errprintf("file %s already exists\n", fn)
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
`Int' FOpen(`Str' fn, `Str' mode, | `Str' id, `Bool' unlink)
{
    `Int'  fh
    `Str'  lname
    `StrR' lnames
    
    lname = "MataFH" + (id!="" ? "_" + id : "")
    lnames = tokens(st_local("MataFHs"))
    if (unlink==1) fh = _FOpen(fn, mode)
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
`Int' _FOpen(`Str' fn,  `Str' mode)
{
    `Int' fh, cnt

    if (fileexists(fn)) {
        unlink(fn)
        for (cnt=1; (fh=_fopen(fn, mode))<0; cnt++) {
            if (cnt==10) {
                fh = fopen(fn, mode)
                break
            }
            stata("sleep 10")
        }
        return(fh)
    }
    return(fopen(fn, mode))
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
