{smcl}
{* 26sep2022}{...}
{hi:help sttex}{...}
{right:{browse "http://github.com/benjann/sttex/"}}
{hline}

{title:Title}

{pstd}{hi:sttex} {hline 2} Integrate Stata results into a LaTeX document

{pstd}
    {help sttex##syntax:Syntax} -
    {help sttex##description:Description} -
    {help sttex##tags:Dynamic tags} -
    {help sttex##options:Options} -
    {help sttex##remarks:Remarks} -
    {help sttex##author:Author} -
    {help sttex##alsosee:Also see}


{marker syntax}{...}
{title:Syntax}

{pstd}
    Process a source file that contains {help sttex##tags:dynamic tags}:

{p 8 15 2}
    {cmd:sttex} [{cmd:using}] {it:srcfile} [{it:arguments}]
    [{cmd:,}
    {help sttex##gopts:{it:general_options}}
    {help sttex##doopts:{it:do_options}}
    {cmdab:gr:opts(}{help sttex##gropts:{it:graph_options}}{cmd:)}
    ]

{pmore}
    Suffix {cmd:.sttex} is assumed if {it:srcfile} is specified without
    suffix. {it:srcfile} may contain an absolute or relative path.

{pstd}
    Extract Stata code from source file:

{p 8 15 2}
    {cmd:sttex extract} {it:srcfile}
    [{cmd:,}
    {opt sav:ing(tgtfile)} {opt r:eplace}
    ]

{pstd}
    Register the location of LaTeX executables:

{p 8 15 2}
    {cmd:sttex register tex} [{it:path}]


{synoptset 22 tabbed}{...}
{marker gopts}{col 5}{help sttex##goptions:{it:general_options}}{col 29}Description
{synoptline}
{syntab :Main}
{synopt :{opt sav:ing(tgtfile)}}name of the target LaTeX file; default is
    {it:srcname}{cmd:.tex}
    {p_end}
{synopt :{opt r:eplace}}allow overwriting existing files
    {p_end}
{synopt :{opt nocd}}run Stata commands in current working directory
    {p_end}

{syntab :Stata commands}
{synopt :{opt nostop}}do not stop processing Stata commands in case of error
    {p_end}
{synopt :{opt more}}set {helpb more} on; default is to set {helpb more} off
    {p_end}
{synopt :{opt rmsg}}set {helpb rmsg} on; default is to set {helpb rsmg} off
    {p_end}

{syntab :Database}
{synopt :{opt reset}}delete existing database and create new database
    {p_end}
{synopt :{opt nodb}}do not maintain a database
    {p_end}
{synopt :{opt db:name(dbfile)}}file name of database; default is {it:srcfile}{cmd:.db}
    {p_end}

{syntab :Typesetting}
{synopt :{opt type:set}[{opt (#)}]}create a PDF (using an external LaTeX compiler)
    {p_end}
{synopt :{opt view}[{opt (#)}]}like {cmd:typeset()}, but additionally view the PDF
    {p_end}
{synopt :{opt jobname(name)}}custom base name for PDF file
    {p_end}
{synopt :{opt clean:up}}remove auxiliary files left behind by the LaTeX compiler
    {p_end}
{synopt :[{cmd:no}]{opt bibtex}}override whether BibTeX is applied or not
    {p_end}
{synopt :[{cmd:no}]{opt makeindex}}override whether makeindex is applied or not
    {p_end}
{synoptline}

{synoptset 22 tabbed}{...}
{marker doopts}{col 5}{help sttex##dooptions:{it:do_options}}{col 29}Description
{synoptline}
{syntab :Main}
{synopt:[{cmd:no}]{opt do}}enforce or suppress running the Stata commands
    {p_end}
{synopt:[{cmd:no}]{opt cert:ify}}compare results against previous
    version; default is {cmd:nocertify}
    {p_end}
{synopt:[{cmd:no}]{opt dos:ave}}store a copy of the commands in
    a do-file; default is {cmd:nodosave}
    {p_end}
{synopt:{opt logdir(path)}}where to store the log file(s)
    {p_end}
{synopt:{opt dodir(path)}}where to store the optional do-file
    {p_end}

{syntab :Runtime options}
{synopt:{opt li:nesize(#)}}set the line width for the results log
    {p_end}
{synopt:[{cmd:no}]{opt trim}[{cmd:({it:#})}]}remove indentation of code block; default
    is {cmd:trim}
    {p_end}
{synopt:[{cmd:{ul:no}}]{opt out:put}}suppress command output in results log; default is {cmd:output}
    {p_end}

{syntab :Log options}
{synopt:{help sttex##logopts:{it:log_options}}}options affecting formatting and embedding of log
    {p_end}
{synoptline}

{synoptset 22 tabbed}{...}
{marker logopts}{col 5}{help sttex##logoptions:{it:log_options}}{col 29}Description
{synoptline}
{syntab :Main}
{synopt:[{cmd:no}]{opt code}}display code log rather than
    results log; default is {cmd:nocode}
    {p_end}
{synopt:{opt range(from [to])}}select range of lines from log
    {p_end}
{synopt:{cmd:ltag(}{help sttex##ltag:{it:matchlist}}{cmd:)}}enclose lines in custom tags
    {p_end}
{synopt:{cmd:tag(}{help sttex##tag:{it:matchlist}}{cmd:)}}enclose strings in custom tags
    {p_end}
{synopt:{opt alert(strlist)}}enclose strings in {cmd:\alert{}}
    {p_end}
{synopt:{cmdab:subs:titute(}{help sttex##subst:{it:matchlist}}{cmd:)}}apply string substitutions
    {p_end}
{synopt:[{cmd:{ul:no}}]{opt lb}}remove line break comments; default is {cmd:lb}
    {p_end}
{synopt:[{cmd:{ul:no}}]{opt gt}}remove continuation symbols; default is {cmd:gt}
    {p_end}
{synopt:{opth drop(numlist)}}remove selected commands (and their output) from the log
    {p_end}
{synopt:{opth cnp(numlist)}}insert {cmd:\cnp} after selected commands
    {p_end}
{synopt:[{cmd:{ul:no}}]{opt lnum:bers}}add line numbers; requires definition of {cmd:\stlnum{}}
    {p_end}
{synopt:[{cmd:{ul:no}}]{opt lcont:inue}}continue line numbers from prior log
    {p_end}

{syntab :Results log only}
{synopt:[{cmd:{ul:no}}]{opt com:mands}}strip all command lines from results log; default is {cmd:commands}
    {p_end}
{synopt:[{cmd:{ul:no}}]{opt pr:ompt}}remove command prompts; default is {cmd:prompt}
    {p_end}
{synopt:{opth qui(numlist)}}remove output from selected commands
    {p_end}
{synopt:{opth oom(numlist)}}replace output from selected commands by {cmd:\oom}
    {p_end}

{syntab :Code log only}
{synopt:[{cmd:{ul:no}}]{opt verb:atim}}use copy of code rather than code log;
    default is {cmd:noverbatim}
    {p_end}
{synopt:{opt cl:size(#)}}set the line width for the (non-verbatim) code log
    {p_end}

{syntab :Embedding}
{synopt:[{cmd:{ul:no}}]{opt stat:ic}}copy log into target document; default is {cmd:nostatic}
    {p_end}
{synopt:[{cmd:no}]{opt begin}[{cmd:(}{it:str}{cmd:)}]}specify custom begin tag for log
    {p_end}
{synopt:[{cmd:no}]{opt end}[{cmd:(}{it:str}{cmd:)}]}specify custom end tag for log
    {p_end}
{synopt:[{cmd:no}]{opt beamer}}use begin tag for beamer class; default is {cmd:nobeamer}
    {p_end}
{synopt:{opt scale(#)}}rescale the size of the log
    {p_end}
{synopt:{opt bl:stretch(#)}}adjust line spacing in the log
    {p_end}
{synoptline}

{synoptset 22 tabbed}{...}
{marker gropts}{col 5}{help sttex##groptions:{it:graph_options}}{col 29}Description
{synoptline}
{syntab :Main}
{synopt:{opt as(fileformats)}}set output format(s); default is {cmd:as(pdf)}
    {p_end}
{synopt:{opt name(name)}}name of the graph window to be exported
    {p_end}
{synopt:{opt overr:ide(options)}}format-dependent options; see {it:override_options} in
    {helpb graph export}
    {p_end}
{synopt:{opt dir(path)}}where to store the graph files
    {p_end}

{syntab :Embedding}
{synopt:[{cmd:no}]{opt center}}center the graph; default is {cmd:nocenter}
    {p_end}
{synopt:{opt arg:s(args)}}pass-through graph arguments
    {p_end}
{synopt:[{cmd:{ul:no}}]{opt suf:fix}}type the file suffix; default is {cmd:nosuffix}
    {p_end}
{synopt:[{cmd:no}]{opt epsfig}}use {cmd:\epsfig{}} instead of
    {cmd:\includegraphics{}}; default is {cmd:noepsfig}
    {p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
    {cmd:sttex} is a command to process a LaTeX source file containing blocks
    of Stata code. {cmd:sttex} will extract the Stata commands into a do-file,
    run the do-file, and then weave the LaTeX source and the Stata output into a
    target LaTeX document. Optionally, {cmd:sttex} also typesets the LaTeX document
    and displays the resulting PDF. Various tags can be used within the LaTeX
    source file to define the information that will be processed by {cmd:sttex}; see
    {help sttex##tags:dynamic tags} below.

{pstd}
    A main feature of {cmd:sttex} is that it detects whether Stata code changed
    between calls. If the code did not change, execution of Stata commands will be skipped
    to save computer time. It is also possible to partition a source file into independent
    sections, such that only the sections affected by changes will be
    executed; see {help sttex##parts:Partition the file into sections} below.

{marker register}{...}
{pstd}
    Typesetting options of {cmd:sttex} require
    a LaTeX distribution to be installed on your computer. Use
    {cmd:sttex register tex} {it:path} to inform {cmd:sttex} about the location
    of LaTeX executables such as {cmd:pdflatex}, {cmd:makeindex}, and
    {cmd:bibtex}. To find the correct path on Mac OS or Linux, open a terminal
    and type, for example, {cmd:which pdflatex}. For windows, consult the
    documentation of your LaTeX distribution. If you use a standard MacTeX
    installation on Mac OS, the correct command will probably be

        {com}. sttex register tex "/Library/TeX/texbin/"{txt}

{pstd}
    {cmd:sttex register tex} only has to be applied once on a given system
    as {cmd:sttex} remembers the setting between Stata sessions (the setting will
    be stored in a file added to the folder in which {cmd:sttex.ado} resides). To
    delete the setting, type {cmd:sttex register tex} without argument.

{pstd}
    {cmd:sttex extract} is a utility command that can be used to collect all blocks
    of Stata code from a source file and store them in a do-file.

{pstd}
    {cmd:sttex} requires Stata 11 or newer.


{marker tags}{...}
{title:Dynamic tags}

    LaTeX commands
        {help sttex##stata:Stata or Mata code}
        {help sttex##graph:Graphs}
        {help sttex##inlexp:Inline expressions}
        {help sttex##stlog:Log copies}
        {help sttex##include:Include external file}
        {help sttex##append:Append external file}
        {help sttex##eof:End of input}

    Interpreted LaTeX comments
        {help sttex##target:Specify target file and overall options}
        {help sttex##parts:Partition the file into sections}
        {help sttex##ignore:Ignore tags}
        {help sttex##remove:Remove input}

{marker stata}{...}
{dlgtab:Stata or Mata code}

{pstd}
    To run a block of Stata commands and, optionally, display the output in the target
    file, type

        {cmd:\begin{c -(}}{it:keyword}{cmd:{c )-}}{cmd:[}{it:id}{cmd:]}{cmd:[}{help sttex##doopts:{it:do_options}}{cmd:]}
            {it:commands}
        {cmd:\end{c -(}}{it:keyword}{cmd:{c )-}}
    or
        {cmd:\do}{it:keyword}{cmd:{c -(}}{it:filename}{cmd:{c )-}}{cmd:[}{it:id}{cmd:]}{cmd:[}{help sttex##doopts:{it:do_options}}{cmd:]}

{pstd}
    where {it:id} provides a custom name for the block. The brackets do not
    need to be typed if {it:id} and options are omitted (but the brackets for {it:id}
    need to be typed if options are specified). An automatic name is assigned if {it:id}
    is omitted. The {cmd:\do}{it:keyword}{cmd:{}} syntax is equivalent to
    {cmd:\begin{c -(}}{it:keyword}{cmd:{c )-}} ... {cmd:\end{c -(}}{it:keyword}{cmd:{c )-}}, but the commands
    are read from {it:filename} rather than being provided directly within the
    document. {it:filename} may contain an absolute or relative path; extension
    {cmd:.do} is assumed if {it:filename} is specified without suffix.

{pstd}
    The {cmd:\begin{}}, {cmd:\end{}}, and {cmd:\do}{it:keyword}{cmd:{}}
    tags must start at the beginning of a line and any text in the same line after a tag is
    ignored.

{pstd}
    {it:keyword} may be one of the following:

{p2colset 9 20 22 2}{...}
{p2col:{cmd:stata}}run Stata commands and display the output in the target file
    {p_end}
{p2col:{cmd:stata*}}run Stata commands without displaying the output
    {p_end}
{p2col:{cmd:mata}}run Mata commands and display the output in the target file
    {p_end}
{p2col:{cmd:mata*}}run Mata commands without displaying the output
    {p_end}

{pstd}
    Within {it:commands} (or within {it:filename}) you can use the following tags:

{p2col:{cmd://STcnp}}include a page break and, depending on settings, a
    continued-on-next-page message; also see option {helpb sttex##cnp:cnp()}
    {p_end}
{p2col:{cmd://STqui}}suppress the output of the subsequent command (Stata code
    only); also see option {helpb sttex##qui:qui()}
    {p_end}
{p2col:{cmd://SToom}}suppress the output of the subsequent command and include
    an output-omitted message after the command (Stata code only); also see option
    {helpb sttex##oom:oom()}
    {p_end}

{pstd}
    These tags must start at the beginning of a line; text in
    the same line after a tag is ignored. {cmd://STcnp} can be used within
    Stata code and Mata code. {cmd://STqui} and {cmd://SToom} can only be used in
    Stata code; these tags will lead to error if used in Mata code.

{pstd}
    Note that {cmd:\dostata{c -(}}{it:filename}{cmd:{c )-}} copies
    the commands from {it:filename} into the main do-file that will be executed
    to evaluate the commands. That is, the commands from {it:filename} will be
    executed in the same instance as the other commands. If you want to run the
    commands from an external file in their own instance, type

        {com}\begin{stata}[][drop(1 .)]
            do {txt}{it:filename}{com}
        \end{stata}{txt}

{pstd}
    where option {helpb sttex##drop:drop()}, as specified, will make the log look like the
    commands had been copied into the main do-file.

{marker graph}{...}
{dlgtab:Graphs}

{pstd}
    To include a graph created by a prior code block, type

        {cmd:\stgraph{cmd:[}}{it:id}{cmd:]}{cmd:{c -(}}{help sttex##gropts:{it:graph_options}}{cmd:{c )-}}
    or
        {cmd:\stgraph*{cmd:[}}{it:id}{cmd:]}{cmd:{c -(}}{help sttex##gropts:{it:graph_options}}{cmd:{c )-}}

{pstd}
    where {it:id} provides a custom name for the graph. The brackets do not need to be typed if
    {it:id} is omitted. An automatic name based on the name of the prior code block
    is assigned if {it:id} is omitted. The difference
    between {cmd:\stgraph{}} and {cmd:\stgraph*{}} is that the latter
    does not write any code to the LaTeX document to embed the graph.

{pstd}
    The {cmd:\stgraph{}} tag must start at the beginning of a line;
    any text in the same line after the tag will be ignored. Furthermore,
    {cmd:\stgraph{}} is only allowed if there is at least one prior code block
    in the current part of the document. The {cmd:do}/{cmd:nodo} setting of the
    prior code block is inherited by {cmd:\stgraph{}}.

{marker inlexp}{...}
{dlgtab:Inline expressions}

{pstd}
    To add strings and values of scalar expressions in the text, use the
    {cmd:\stres{}} tag. The tag can be specified anywhere inside a line of text;
    it can also be specified multiple times in the same line or it can span multiple
    lines. {cmd:\stres{}} comes in three forms.

{pstd}
    Syntax 1: Runtime evaluation

            {cmd:\stres}{cmd:[}{it:id}{cmd:]}{cmd:{c -(}}{it:{help display:display_directive}}{cmd:{c )-}}

{pmore}
    With this syntax, {cmd:\stres{}} will be evaluated at
    runtime, i.e. when running the Stata commands found in the source
    file. {cmd:\stres{}} will apply Stata's {helpb display} command
    to {it:{help display:display_directive}} and then
    replace the tag with the output. The output will be backed up for future
    {cmd:sttex} passes, using {it:id} as an identifier. An automatic name
    is assigned if {it:id} is omitted; the brackets do not have to be typed if
    {it:id} is omitted.

{pmore}
    Within {it:{help display:display_directive}} you can type {cmd:\%} instead of
    {cmd:%} to prevent LaTeX syntax highlighting from interpreting {cmd:%} and
    subsequent text as a comment. {cmd:sttex} will replace {cmd:\%} by
    {cmd:%} before processing {it:{help display:display_directive}}.


{pstd}
    Syntax 2: Pre-processing time evaluation

            {cmd:\stres{c -(}{c -(}}{it:{help display:display_directive}}{cmd:{c )-}{c )-}}

{pmore}
    If you enclose {it:{help display:display_directive}} in curly braces, it will be
    evaluated while pre-processing the source file and not when running the Stata
    commands. This also means that evaluation occurs in each pass and not only
    in passes in which the surrounding Stata commands are run. Use this syntax to
    add results that do not depend on the other Stata commands (and might
    change between passes). For example, {cmd:\stres{{c(current_date)}}}
    adds the current date.

{pmore}
    Similar to syntax 1, {cmd:\%} within {it:{help display:display_directive}}
    will be replaced by {cmd:%} before evaluation.

{pstd}
    Syntax 3: Special functions

            {cmd:\stres{c -(}{c -(}}{it:keyword} [{it:id}]{cmd:{c )-}{c )-}}

{pmore}
    Use this syntax for custom inclusion of a Stata log or a graph. This may be
    useful, for example, in combination with {cmd:\stgraph*{}}. {it:keyword}
    is one of the following:

{p2colset 14 24 26 2}{...}
{p2col:{cmd:log}}add the log from Stata block named {it:id}; the log from the last
    code block will be used if {it:id} is omitted
    {p_end}
{p2col:{cmd:logname}}add the filename used for the log
    {p_end}
{p2col:{cmd:graph}}add the graph named {it:id}; the last graph will be used if
    {it:id} is omitted
    {p_end}
{p2col:{cmd:graphname}}add the filename used for the graph (without suffix)
    {p_end}

{pmore}
    The way in which {cmd:\stres{{log}}} puts together the LaTeX code to
    display the output depends on the {help sttex##stopts:{it:stlog_options}}
    that were applied when generating the output. Likewise, the behavior of
    {cmd:\stres{{graph}}} depends on the {help sttex##gropts:{it:graph_options}}
    that were applied when exporting the graph.

{pmore}
    Note that a log or graph can be addressed by {cmd:\stres{}} even if it does
    not yet exist. That is, you can use {cmd:\stres{}} to include a log or
    graph anywhere in the document, independently of the where in the document
    the log or graph is created.

{marker stlog}{...}
{dlgtab:Log copies}

{pstd}
    To obtain a copy of the results log or the code log from one or multiple blocks
    of Stata commands, type

        {cmd:\stlog{cmd:[}}{it:idlist}{cmd:]}{cmd:{c -(}}{help sttex##logopts:{it:log_options}}{cmd:{c )-}}
    or
        {cmd:\stlog*{cmd:[}}{it:idlist}{cmd:]}{cmd:{c -(}}{help sttex##logopts:{it:log_options}}{cmd:{c )-}}

{pstd}
    where {it:idlist} is a space-separated list of the names of the blocks
    (the blocks must already exist; referencing a future block is not allowed). The last block
    will be used if {it:idlist} is omitted. The log created by {cmd:\stlog{}}
    will be named {it:id}{cmd:.}{it:#}, where {it:id} is the name of the 
    (first) code block referenced by {it:idlist} and where {it:#} is a counter.

{pstd}
    The {cmd:*} and {cmd:?} wildcards are allowed in {it:idlist}. For example, 
    {cmd:\stlog[*]{}} will compile a log from all existing code blocks (in the
    order in which they appear in the document).

{pstd}
    {cmd:\stlog{}} is useful if you want to include multiply copies of a log with
    different options. For example, you could specify option {cmd:range(1 10)} with the main
    copy to print only lines 1-10 and then use {cmd:\stlog{}} with option
    {cmd:range(11 .)} to print the remaining lines. Likewise you could
    specify option {cmd:code} with the main copy to print the code log and then
    print the results log by applying {cmd:\stlog{}} without option {cmd:code}.

{marker include}{...}
{dlgtab:Include external file}

{pstd}
    To include contents from an external file, type

        {cmd:\stinput{c -(}}{it:filename}{cmd:{c )-}}

{pstd}
    where {it:filename} may contain an absolute
    or relative path. Dynamic tags within the external file will be
    interpreted in the same way as they are interpreted in the main
    file. {cmd:\stinput{}} must start at
    the beginning of a line; any text in the same line after the tag is
    ignored.

{marker append}{...}
{dlgtab:Append external file}

{pstd}
    To append contents from an external file, type

        {cmd:\stappend{c -(}}{it:filename}{cmd:{c )-}}{cmd:[}{it:substitutions}{cmd:]}

{pstd}
    where {it:filename} may contain an absolute
    or relative path. Dynamic tags within the external file will not be
    interpreted. {cmd:\stappend{}} must start at
    the beginning of a line; any text in the same line after the tag is
    ignored.

{pstd}
    {it:substitutions} may be specified to apply substitutions within the
    appended contents. The syntax of {it:substitutions} is

        {it:strlist} {cmd:=} {it:to} [ {it:strlist} {cmd:=} {it:to} ... ]

{pstd}
    The substitutions will be applied sequentially.

{marker eof}{...}
{dlgtab:End of input}

{pstd}
    To stop reading from the source file, specify

        {cmd:\endinput}

{pstd}
    at the beginning of a line. All remaining lines will be ignored.

{marker target}{...}
{dlgtab:Specify target file and overall options}

{pstd}
    Instead of specifying the target file and overall options when calling
    {cmd:sttex}, you can provide

{p 8 15 2}
    {cmd:%STinit} [{it:tgtfile}] [{cmd:,}
    {help sttex##gopts:{it:general_options}}
    {help sttex##doopts:{it:do_options}}
    {cmdab:gr:opts(}{help sttex##gropts:{it:graph_options}}{cmd:)} ]

{pstd}
    within the first 50 lines of the source file. {it:tgtfile} and options
    specified with {cmd:%STinit} take precedence over options specified
    with {cmd:sttex}. {cmd:%STinit} must start at
    the beginning of a line.

{pstd}
    If {cmd:%STinit} is found among the first 50 lines of the
    source file, lines before {cmd:%STinit} will be ignored.

{marker parts}{...}
{dlgtab:Partition the file into independent sections}

{pstd}
    An important feature of {cmd:sttex} is that it only runs Stata commands
    if there were changes. However, as soon as a single command changed, all
    commands will be executed. This is because {cmd:sttex} does not know how
    the different commands depend on each other. You can provide such information
    by partitioning the source file into different sections, possibly including
    declaration of dependencies between parts. The syntax is

{p 8 15 2}
    {cmd:%STpart} [{it:id} [{it:parent}]] [{cmd:,}
    {help sttex##doopts:{it:do_options}}
    {cmdab:gr:opts(}{help sttex##gropts:{it:graph_options}}{cmd:)} ]

{pstd}
    where {it:id} provides a custom name for the part. An automatic name is
    assigned if {it:id} is omitted or if {it:id} is equal to
    {cmd:.} (missing). {cmd:sttex} will decide part by part whether
    to run the commands.

{pstd}
    {it:parent} specifies the name ({it:id}) of an optional parent part. A change
    in the commands in the parent will cause execution of the code in the child,
    and vice-versa. More generally, if there is a change in the commands in a
    specific part, the code in all its ancestors and all its descendants will
    be executed.

{pstd}
    By default, that is, if {it:parent} is omitted, the (unnamed) main part
    (i.e. the section before the first {cmd:%STpart} tag) is used as parent
    part. This means that if you do not specify parents, a change in any part
    will cause the main part to be executed, and a change in the main part will
    cause all other parts to be executed.

{pstd}
    To indicate that a part has no parent, specify {it:parent} as {cmd:.} (missing). That is,
    specify {cmd:.} to create a standalone part (which, however, may have children).

{pstd}
    Specify {help sttex##doopts:{it:do_options}} and
    {help sttex##gropts:{it:graph_options}} to change overall options between
    parts.

{pstd}
    The {cmd:%STpart} tag, must start at the beginning of a line.

{marker ignore}{...}
{dlgtab:Ignore tags}

{pstd}
    To ignore dynamic tags in a section of the source file, type:

        {cmd:%STignore}
        {it:...}
        {cmd:%STendignore}

{pstd}
    The text between {cmd:%STignore} and {cmd:%STendignore} will be added
    to the target file as is.

{pstd}
    {cmd:%STignore} and {cmd:%STendignore} must start at the beginning of a
    line. Text in the same line after the tag is ignored.

{marker remove}{...}
{dlgtab:Remove input}

{pstd}
    To ignore dynamic tags in a section of the source file and omit the
    section from the target file, type:

        {cmd:%STremove}
        {it:...}
        {cmd:%STendremove}

{pstd}
    {cmd:%STremove} and {cmd:%STendremove} must start at the beginning of a
    line. Text in the same line after the tag is ignored.


{marker options}{...}
{title:Options}

    {help sttex##goptions:General options}
    {help sttex##dooptions:Do options}
    {help sttex##logoptions:Log options}
    {help sttex##groptions:Graph options}

{marker goptions}{...}
{title:General options}

{dlgtab:Main}

{phang}
    {opt saving(tgtfile)} specifies the target LaTeX file to be saved. Suffix {cmd:.tex} is
    used if {it:tgtfile} is specified without suffix; {it:srcname}{cmd:.tex} is used
    if {cmd:saving()} is omitted, where {it:srcname} is the base name of {it:srcfile}. The
    target file will be placed in the same folder as the source file unless an (absolute or relative)
    path is specified in {it:tgtfile}.

{pmore}
    For {cmd:sttex extract}, option {cmd:saving()} specifies the target dofile to
    store the Stata commands. Default suffix is {cmd:.do} in this case, and {it:srcname}{cmd:.do} is used
    if {cmd:saving()} is omitted.

{phang}
    {opt replace} allows overwriting existing files.

{phang}
    {opt nocd} runs the Stata commands in current working directory. The default
    is to change the working directory to the directory of
    {it:srcfile} for the execution of the Stata commands. In any case, the
    current working directory will be restored after termination.

{dlgtab:Stata commands}

{phang}
    {opt nostop} does not stop processing the Stata commands when an error
    occurs. This option may be useful if you want to document errors.

{pmore}
    {cmd:nostop} is a global option applied to the whole document. If you
    want to apply {cmd:nostop} to a selected code block only, then store the relevant
    commands in {it:filename} and call the file in your document about as follows:

        {com}\begin{stata}[][drop(1 .)]
            do {txt}{it:filename}{com}, nostop
        \end{stata}{txt}

{phang}
    {opt more} sets {helpb more} on for the execution of the Stata commands. The
    default is to set {helpb more} off. In any case, the current setting is
    restored after termination.

{phang}
    {opt rmsg} sets {helpb rmsg} on for the execution of the Stata commands. The
    default is to set {helpb rsmg} off. In any case, the current setting is
    restored after termination.

{dlgtab:Database}

{phang}
    {opt reset} deletes the existing database and a creates new database. This implies
    that all Stata commands will be re-evaluated (except commands for which {cmd:nodo}
    has been specified).

{phang}
    {opt nodb} requests that no database is maintain. This implies
    that all Stata commands will be evaluated in each run (except commands
    for which {cmd:nodo} has been specified).

{phang}
    {opt dbname(dbfile)} specifies the file name to be used for the database. Suffix
    {it:srcsuffix}{cmd:.db} is used if {it:dbfile} is specified without suffix,
    where {it:srcsuffix} is the suffix of the source file; {it:srcfile}{cmd:.db}
    is used if {cmd:dbname()} is omitted. The database will be placed in the
    same folder as the source file unless an (absolute or relative) path is
    specified in {it:dbfile}.

{dlgtab:Typesetting}

{phang}
    {opt typeset}[{opt (#)}] runs an external LaTeX compiler to typeset the
    resulting target document as a PDF file. This requires that the location of
    LaTeX executables has been registered using
    {helpb sttex##register:sttex register tex}. Argument {it:#} specifies the
    number of extra typesetting passes. The default depends on situation.

{phang}
    {opt view}[{opt (#)}] is like {cmd:typeset()}, but additionally views the PDF after
    typesetting.

{phang}
    {opt jobname(name)} specifies a custom base name for PDF file.

{phang}
    {opt cleanup} removes auxiliary files left behind by the LaTeX compiler. Depending
    on situation, {cmd:cleanup} may not catch all auxiliary files.

{phang}
    [{cmd:no}]{opt bibtex} overrides whether BibTeX will be applied or not. By default,
    {cmd:sttex} will decide depending on situation whether to run BibTeX.

{phang}
    [{cmd:no}]{opt makeindex} overrides whether makeindex will be applied or not. By default,
    {cmd:sttex} will decide depending on situation whether to run makeindex.

{marker dooptions}{...}
{title:Do options}

{dlgtab:Main}

{phang}
    [{cmd:no}]{opt do} enforces or suppresses evaluating the commands in a code
    block. Specify {cmd:do} if you always want
    to execute the commands, irrespective of whether there have been
    changes in the code or not; specify {cmd:nodo} if you never want to execute
    the commands.

{phang}
    [{cmd:no}]{opt certify} specifies whether to compare the results log of a code
    block against the previous version. The default is {cmd:nocertify}. Error
    will be returned, if {cmd:certify} is specified and differences are detected.

{phang}
    [{cmd:no}]{opt dosave} specifies whether to store a copy of a code block in
    an external do-file. The default is {cmd:nodosave}. File name
    {it:id}{cmd:.do} will be used for the do-file, where {it:id} is the name
    of the block.

{phang}
    {opt logdir(path)} specifies where to store the log file(s). {it:path} may be an
    absolute or relative path. The default is to store the file(s) in a subfolder
    that has the same base name as the source file. Type {cmd:logdir(.)} to store
    the file(s) directly in the folder of the source file without creating a
    subfolder. Type, for example, {cmd:logdir(log)}, to store the log file(s) in
    subfolder {cmd:log}. Whether a log file will be stored or not depends on
    situation (e.g. no file will be stored if log option {cmd:static} is specified).

{phang}
    {opt dodir(path)} specifies where to store the do-file created by
    the {cmd:dosave} option. The default is to store the file in the same place
    as the log file(s). Type {cmd:dodir(.)} to store
    the file directly in the folder of the source file. Type, for example,
    {cmd:dodir(do)}, to store the do-file in subfolder {cmd:do}.

{dlgtab:Runtime options}

{phang}
    {opt linesize(#)} sets the line width (number of characters) to be used for
    the results log of a code block, with {it:#} between 40 and 255. The
    default is to use the line width as set by {helpb set linesize}. You may
    type {cmd:linesize(.)} to select this default behavior. Changing
    the line width causes reevaluation of the commands in the code block.

{phang}
    [{cmd:no}]{opt trim}[{cmd:({it:#})}] specifies whether to remove white space
    on the left of the commands in a code block. Default is
    {cmd:trim} (i.e. to remove indentation). Argument {it:#}, if specified,
    limits the number of white-space characters to be removed. In any case, at
    most {it:k} characters will be removed, where {it:k} is the minimum number
    of characters by which the commands in the block are indented. Changing
    {cmd:trim()} causes reevaluation of the commands in the code block.

{phang}
    [{cmd:no}]{opt output} specifies whether to suppress command output in
    the results log of a code block. Default is {cmd:output}. If {cmd:nooutput}
    is specified, {cmd:sttex} will temporarily turn {cmd:set output inform} on
    for the execution of the code block, which will suppress command output. Changing
    the {cmd:output} option will cause reevaluation of the commands in the code block.

{dlgtab:Formatting}

{phang}
    {it:log_options} are options selecting the type of log to be used
    and how the log is formatted and embedded in the target file. See
    {helpb sttex##logoptions:Log options} blow.

{marker logoptions}{...}
{title:Log options}

{dlgtab:Main}

{phang}
    [{cmd:no}]{opt code} specifies whether to use the code log or the
    results log. Default is {cmd:nocode}, that is, to use the results log.

{phang}
    {opt range(from [to])} selects a specified range of the log, where {it:from}
    is the first line number and {it:to} is the last line number to be included. To
    include all remaining lines after {it:from}, you may omit {it:to} or specify
    {it:to} as {cmd:.} (missing). {cmd:range()} is applied after options
    {cmd:drop()}, {cmd:qui()}, and {cmd:oom()} have taken effect.

{marker ltag}{...}
{phang}
    {opt ltag(matchlist)} encloses the specified lines of the log in custom
    tags. The syntax of {it:matchlist} is

            {it:numlist} {cmd:=} {it:left} {it:right} [ {it:numlist} {cmd:=} {it:left} {it:right} ... ]

{pmore}
    where {help numlist:{it:numlist}} is a list of target line numbers, and {it:left} and
    {it:right} are strings to be added to the beginning and the end of each selected
    line, respectively. Enclose strings in double quotes if they contain
    spaces. Specify {it:left} or {it:right} as {cmd:""} for empty string. {cmd:ltag()} is
    applied at the end, after other formatting options have taken effect.

{marker tag}{...}
{phang}
    {opt tag(matchlist)} encloses the specified strings in custom
    tags. The syntax of {it:matchlist} is

            {it:strlist} {cmd:=} {it:left} {it:right} [ {it:strlist} {cmd:=} {it:left} {it:right} ... ]

{pmore}
    where {it:strlist} is a space separated list of target strings, and {it:left} and
    {it:right} are strings to be added to the left and right of each target
    string, respectively. Enclose strings in double quotes if they contain
    spaces. Specify {it:left} or {it:right} as {cmd:""} for empty string.

{phang}
    {opt alert(strlist)} encloses the specified strings in {cmd:\alert{}},
    where {it:strlist} is a space separated list of target strings. Enclose
    strings in double quotes if they contain spaces.

{marker subst}{...}
{phang}
    {opt substitute(matchlist)} applies string substitutions in the log. The  the syntax of
    {it:matchlist} is


            {it:strlist} {cmd:=} {it:to} [ {it:strlist} {cmd:=} {it:to} ... ]

{pmore}
    where {it:strlist} is a space separated list of target strings and {it:to}
    is the string by which the target strings are to be replaced. Enclose strings
    in double quotes if they contain spaces. Specify {it:to} as {cmd:""} for
    empty string. {cmd:substitute()} will be applied before {cmd:tag()} and
    {cmd:alert()}.

{phang}
    [{cmd:{ul:no}}]{opt lb} specifies whether to remove line break comments ({cmd:/// ...})
    from the command lines in the log. Default is {cmd:lb}, that is, to retain the
    line break comments.

{phang}
    [{cmd:{ul:no}}]{opt gt} specifies whether to remove continuation symbols ({cmd:> }) from the
    command lines in the log. Default is {cmd:gt}, that is, to retain the
    continuation symbols.

{marker drop}{...}
{phang}
    {opt drop(numlist)} removes the specified commands (and their output) from
    the log. Positive integers in {help numlist:{it:numlist}} refer to the
    positions of the commands from the start, negative integers refer to positions
    from the end. The last command can also be address by {cmd:.} (missing).

{marker cnp}{...}
{phang}
    {opt cnp(numlist)} inserts a continued-on-next-page tag ({cmd:\cnp}) after
    the specified commands. {help numlist:{it:numlist}} is as for
    {helpb sttex##drop:drop()}. Use this option as an alternative to including
    {cmd://STcnp} comments in the code. The advantage of {cmd:cnp()} is that no
    reevaluation of the code is needed if the option changes.

{pmore}
    By default, {cmd:\cnp} is defined as {cmd:\clearpage} in {cmd:stata.sty}. If you
    want to print a continued-on-next-page message, redefine {cmd:\cnp} as
    {cmd:\onnextpage}, e.g. by including {cmd:\let\cnp=\onnextpage} in the preamble
    of the document.

{phang}
    [{cmd:{ul:no}}]{opt lnumbers} specifies whether to add line numbers to the
    log. Default is {cmd:nolnumbers}. Line numbers are added at the end, after
    other formatting options have taken effect.

{pmore}
    The line numbers will be included in command {cmd:\stlnum{}}, which needs to
    be defined in the preamble of the document. For example, define 
    {cmd:\stlnum{}} as {cmd:\def\stlnum#1{\makebox[0pt][r]{#1~}}} to print right
    aligned-numbers on the left of the log. An exception is when both {cmd:code}
    and {cmd:verbatim} are specified; in this case the line numbers will be
    added to the log as is.

{phang}
    [{cmd:{ul:no}}]{opt lcontinue} specifies whether to continue
    the line number counter from the prior log. Default is {cmd:nolcontinue}. Option
    {cmd:continue} is relevant only if {cmd:lnumbers} has been specified.

{dlgtab:Results log only}

{phang}
    [{cmd:no}]{opt commands} specifies whether to remove all command lines from the
    results log. Default is {cmd:commands}, that is, to retain the command lines.

{phang}
    [{cmd:{ul:no}}]{opt prompt} specifies whether to remove command prompts ({cmd:. }) from the
    command lines in the results log. Default is {cmd:prompt}, that is, to retain the
    command prompts.

{marker qui}{...}
{phang}
    {opt qui(numlist)} removes the output from the specified commands. {help numlist:{it:numlist}}
    is as for {helpb sttex##drop:drop()}. Use this option as an alternative to including
    {cmd://STqui} comments in the code. The advantage of {cmd:qui()} is that no reevaluation of the
    code is needed if the option changes.

{marker oom}{...}
{phang}
    {opt oom(numlist)} removes the output from the specified commands and includes
    an output-omitted tag ({cmd:\oom}). {help numlist:{it:numlist}} is as for
    {helpb sttex##drop:drop()}. Use this option as an alternative to including
    {cmd://SToom} comments in the code. The advantage of {cmd:oom()} is that no
    reevaluation of the code is needed if the option changes.

{dlgtab:Code log only}

{phang}
    [{cmd:{ul:no}}]{opt verbatim} specifies whether to use a verbatim copy of
    code rather than a code log. Default is {cmd:noverbatim}, in which case the
    code will be passed through {cmd:log texman} to create a code log. The {cmd:verbatim}
    environment will be used to include the code in the target document if {cmd:verbatim}
    is specified, which implies that LaTeX commands in the code will not be
    interpreted when compiling the document.

{phang}
    {opt clsize(#)} sets the line width (number of characters) to be used
    when passing the code through {cmd:log texman}, with {it:#} between 40 and
    255. The default is to use full line width, that is,
    {cmd:clsize(255)}. You may type {cmd:clsize(.)} to select this
    default. The {cmd:clsize()} option has no effect if {cmd:verbatim}
    is specified.

{dlgtab:Embedding}

{phang}
    [{cmd:no}]{opt static} specifies whether to copy the log into the LaTeX
    document or not. Default is {cmd:nostatic}, in which case the log is stored as a
    separate file and included in the LaTeX document using the {cmd:\input{}}
    command. If the target file is a beamer class document, option {cmd:static}
    may lead to compilation issues unless the affected frame is declared as fragile.

{phang}
    [{cmd:no}]{opt begin}[{cmd:(}{it:str}{cmd:)}] specifies the begin tag of the
    environment used to embed the log in the latex file. The default begin tag
    is {cmd:\begin{stlog}} (or {cmd:\begin{stverbatim}} in case of a code log with
    option {cmd:verbatim}). Specify {cmd:nobegin} to omit the begin tag; specify
    {opt begin(str)} to set the begin tag to {it:str}.

{phang}
    [{cmd:no}]{opt end}[{cmd:(}{it:str}{cmd:)}] specifies the end tag of the
    environment used to embed the log in the latex file. The default end tag
    is {cmd:\end{stlog}} (or {cmd:\end{stverbatim}} in case of a code log with
    option {cmd:verbatim}). Specify {cmd:noend} to omit the end tag; specify
    {opt end(str)} to set the end tag to {it:str}.

{phang}
    [{cmd:no}]{opt beamer} specifies whether to set the default begin tag
    to {cmd:\begin{stlog}[beamer]} rather than {cmd:\begin{stlog}}. Specify
    {cmd:beamer} if the target file is a beamer class document. Default is
    {cmd:nobeamer}.

{phang}
    {opt scale(#)} rescales the size of the log, where {it:#} is a scaling factor
    lager than zero, by enclosing the log in a {cmd:\scalebox{}} command (this
    requires that a package providing the {cmd:\scalebox{}} command is loaded in the
    preamble of the document, e.g. the {cmd:graphicx} package). A consequence
    is that page breaks within the log will no longer be possible. By default
    the log is not included in a {cmd:\scalebox{}}. You may type
    {cmd:scale(.)} to select this default. Option
    {cmd:scale()} does not work well together with option {cmd:static}.

{phang}
    {opt blstretch(#)} adjusts the line spacing in the log (by setting the
    {cmd:\baselinestretch} command). By default no action is taken to adjust line
    spacing. Apply {cmd:blstretch()} if you want to use a
    different line spacing in the log than in the surrounding text. You may
    type {cmd:blstretch(.)} to select the default behavior.

{marker groptions}{...}
{title:Graph options}

{dlgtab:Main}

{phang}
    {opt as(fileformats)} sets the output format(s). Default is {cmd:as(pdf)} (or {cmd:as(eps)}
    if {cmd:epsfig} is specified). See help {helpb graph export} for available
    formats. Multiple graph files will be stored if multiple formats are specified.

{phang}
    {opt name(name)} specifies the name of the graph window to be exported. The default
    is to use the topmost graph.

{phang}
    {opt override(options)} are format-dependent options to modify how the
    graph is converted. See {it:override_options} in help
    {helpb graph export} for details.

{phang}
    {opt dir(path)} specifies where to store the graph files, where {it:path} is
    relative or absolute path. The default is to store the graph files in the same
    place as the log file(s). Type {cmd:dir(.)} to store
    the graph files directly in the folder of the source file. Type, for example,
    {cmd:dir(graph)}, to store the do-file in subfolder {cmd:graph}.

{dlgtab:Embedding}

{phang}
    [{cmd:no}]{opt center} specifies whether to include the graph in a {cmd:center}
    environment. Default is {cmd:nocenter}.

{phang}
    {opt args(args)} provides arguments to be passed through to {cmd:\includegraphics{}}
    or {cmd:\epsfig{}} command.

{phang}
    [{cmd:no}]{opt suffix} specifies whether to type the file suffix
    in the {cmd:\includegraphics{}} or {cmd:\epsfig{}} command. Default is
    {cmd:nosuffix}.

{phang}
    [{cmd:no}]{opt epsfig}} specifies whether to use {cmd:\epsfig{}} instead of
    {cmd:\includegraphics{}} to embed the graph in the target document. Default
    is {cmd:noepsfig}.


{marker remarks}{...}
{title:Remarks}

    {help sttex##stable:Use of stable names}
    {help sttex##preamble:Preamble of LaTeX file}
    {help sttex##fontsize:Changing the font size of Stata logs}

{marker stable}{...}
{dlgtab:Use of stable names}

{pstd}
    {cmd:sttex} generates automatic names for elements such as parts created by {cmd:%STpart},
    logs created by the {cmd:stata} or {cmd:mata} environments, graphs created by
    {cmd:\stgrapph{}}, or inline expressions created by {cmd:\stres{}}. These
    automatic names may not be stable if the order of elements is changed
    or if elements are remove or inserted, and a change in name will always cause
    the corresponding Stata commands to be executed.

{pstd}
    To assign stable names, use the {it:id} argument that can be specified when
    defining the elements. In this case, changes in order etc. will not change the
    names, and hence will not lead to unnecessary reevaluation of Stata commands.

{marker preamble}{...}
{dlgtab:Preamble of LaTeX file}

{pstd}
    To be able to compile a LaTeX file that includes Stata output inserted by
    {cmd:sttex} you should include command {cmd:\usepackage{stata}}
    in the preamble of the source file ({cmd:stata.sty} is provided by Stata Corp
    as part of {helpb sjlatex}). Furthermore, to be able to display graphs,
    you may want to include {cmd:\usepackage{graphicx}}. For example, your file
    could start about as follows:

        {com}\documentclass{article}
        \usepackage{graphicx}
        \usepackage{stata}
        ...{txt}

{marker fontsize}{...}
{dlgtab:Changing the font size of Stata logs}

{pstd}
    By default, the {cmd:stlog} environment provided by the {cmd:stata} style
    uses an 8-point font. This is appropriate for a document with a 10-point font
    for the text body. One solution to change the font size is to redefine the
    {cmd:stlog} environment in the preamble of the LaTeX document about as
    follows:

        {com}\let\oldstlog\stlog
        \let\endoldstlog\endstlog
        \renewenvironment{stlog}%
            {\bgroup\fontsize{10}{11}\selectfont\oldstlog[auto]}%
            {\endoldstlog\egroup}{txt}

{pstd}
    This will set the font size to 10 points (with 11-point baseline skip), which
    is appropriate for a document that uses a 12-point font
    for the text body.


{marker author}{...}
{title:Author}

{pstd}
    Ben Jann, University of Bern, ben.jann@unibe.ch

{pstd}
    Thanks for citing this software as follows:

{pmore}
    Jann, B. (2022). sttex: Stata module to integrate Stata results into
    a LaTeX document. Available from {browse "http://github.com/benjann/sttex/"}.


{marker alsosee}{...}
{title:Also see}

{psee}
    Online:  help for
    {helpb dyndoc}, {helpb dyntext}, {helpb texdoc} (if indstalled), {helpb webdoc} (if indstalled)
