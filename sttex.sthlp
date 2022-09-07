{smcl}
{* 07sep2022}{...}
{hi:help sttex}{...}
{right:{browse "http://github.com/benjann/sttex/"}}
{hline}

{title:Title}

{pstd}{hi:sttex} {hline 2} Integrate Stata results into a LaTeX document

{pstd}
    {help sttex##syntax:Syntax} -
    {help sttex##description:Description} -
    {help sttex##tags:Dynamic tags} -
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
    {help sttex##opts:{it:general_options}}
    {help sttex##stopts:{it:stlog_options}}
    {cmdab:gr:opts(}{help sttex##gropts:{it:graph_options}}{cmd:)}
    ]

{pmore}
    Suffix {cmd:.sttex} is assumed if {it:srcfile} is specified without
    suffix. {it:srcfile} may contain an absolute or relative path.

{pstd}
    Register the location of LaTeX executables:

{p 8 15 2}
    {cmd:sttex register tex} [{it:path}]


{synoptset 20 tabbed}{...}
{marker opts}{synopthdr:general_options}
{synoptline}
{syntab :Main}
{synopt :{opt sav:ing(tgtfile)}}the target LaTeX file to be saved; suffix {cmd:.tex} is
    used if {it:tgtfile} is specified without suffix; {it:srcname}{cmd:.tex} is used
    if {cmd:saving()} is omitted, where {it:srcname} is the base name of {it:srcfile}; the
    target file will be placed in the same folder as the source file unless an (absolute or relative)
    path is specified in {it:tgtfile}
    {p_end}
{synopt :{opt r:eplace}}allow overwriting existing files
    {p_end}
{synopt :{opt nocd}}do not change to the directory of {it:srcfile} for the execution of
    Stata commands
    {p_end}

{syntab :Stata commands}
{synopt :{opt nostop}}do not stop processing the Stata commands when an error occurs
    {p_end}
{synopt :{opt more}}set {helpb more} on; the default is to set {helpb more} off
    {p_end}
{synopt :{opt rmsg}}set {helpb rmsg} on; the default is to set {helpb rsmg} off
    {p_end}

{syntab :Database}
{synopt :{opt reset}}delete existing database and create new database; this implies
    that all Stata commands will be executed
    {p_end}
{synopt :{opt nodb}}do not maintain a database; this implies
    that all Stata commands will be executed in each run
    {p_end}
{synopt :{opt db:name(dbfile)}}file name to be used for the database; suffix
    {it:srcsuffix}{cmd:.db} is used if {it:dbfile} is specified without suffix,
    where {it:srcsuffix} is the suffix of the source file; {it:srcfile}{cmd:.db}
    is used if {cmd:dbname()} is omitted; the database will be placed in the
    same folder as the source file unless an (absolute or relative) path is
    specified in {it:dbfile}
    {p_end}

{syntab :Typesetting}
{synopt :{opt type:set}[{opt (#)}]}typset a PDF file using an external LaTeX compiler
    (# specifies the number of extra typesetting passes); this requires that the
    location of the LaTeX executables has been registered using {cmd:sttex register tex}
    {p_end}
{synopt :{opt view}[{opt (#)}]}like {cmd:typeset()}, but additionally view the PDF after typesetting
    {p_end}
{synopt :{opt jobname(name)}}specify a custom base name for PDF file
    {p_end}
{synopt :{opt clean:up}}remove auxiliary files left behind by the LaTeX compiler
    {p_end}
{synopt :[{cmd:no}]{opt bibtex}}override whether BibTeX is applied or not
    {p_end}
{synopt :[{cmd:no}]{opt makeindex}}override whether makeindex is applied or not
    {p_end}
{synoptline}

{synoptset 20 tabbed}{...}
{marker stopts}{synopthdr:stlog_options}
{synoptline}
{syntab :Main}
{synopt:{opt li:nesize(#)}}set the line width to be used in the output log
    (number of characters); the default is to use the line width as set by
    {helpb set linesize}
    {p_end}
{synopt:[{cmd:no}]{opt trim}[{cmd:({it:#})}]}whether to remove white space on the left
    of commands; default is {cmd:trim}; argument {it:#}, if specified, limits the number of
    white-space characters to be removed; in any case, at most {it:k} characters
    will be removed, where {it:k} is the minimum number of indentation characters in
    the current block of commands
    {p_end}
{synopt:[{cmd:no}]{opt code}}whether to display a plain copy of the commands
    (while still running the commands) rather than a log of the results; default is {cmd:nocode}
    {p_end}
{synopt:[{cmd:{ul:no}}]{opt verb:atim}}whether to use verbatim copy of code;
    default is {cmd:noverbatim}; if {cmd:verbatim} is specified,
    the preamble of the document should include command
    \usepackage{c -(}verbatim{c )-} (unless {cmd:static} is also specified)
    {p_end}

{syntab :Formatting}
{synopt:[{cmd:{ul:no}}]{opt com:mands}}whether to strip all command lines from the
    results log; default is {cmd:commands}
    {p_end}
{synopt:[{cmd:{ul:no}}]{opt out:put}}whether to suppress command output in
    the results log; default is {cmd:output}
    {p_end}
{synopt:[{cmd:{ul:no}}]{opt lb}}whether to strip line break comments from the
    commands in the log; default is {cmd:lb}
    {p_end}
{synopt:[{cmd:{ul:no}}]{opt gt}}whether to strip continuation symbols from the
    commands in the log; default is {cmd:gt}
    {p_end}
{synopt:[{cmd:{ul:no}}]{opt pr:ompt}}whether to strip command prompts in the
    results log; default is {cmd:prompt}
    {p_end}
{synopt:{opt alert(strlist)}}enclose all occurrences of the specified strings
    in \alert{}; use double quotes to specify strings that contain blanks
    {p_end}
{synopt:{opt tag(matchlist)}}enclose all occurrences of the specified strings in custom
    tags; the syntax of {it:matchlist} is {it:strlist} {cmd:=} {it:left} {it:right} [ {it:strlist} {cmd:=} {it:left} {it:right} ... ]
    {p_end}
{synopt:{opth drop(numlist)}}remove specified commands and their output from
    the results log; positive number refer to the positions of the commands from
    the start, negative numbers refers to positions from the end (can also specify {cmd:.} for the last command)
    {p_end}
{synopt:{opth noout:put(numlist)}}remove the output from the specified commands; {it:numlist} is as for {cmd:drop()}
    {p_end}
{synopt:{opth oom(numlist)}}remove the output from the specified commands and include
output-omitted message; {it:numlist} is as for {cmd:drop()}
    {p_end}
{synopt:{opth cnp(numlist)}}insert a page break (continued-on-next-page message) after
    the specified commands; {it:numlist} is as for {cmd:drop()}
    {p_end}

{syntab :Embedding}
{synopt:[{cmd:{ul:no}}]{opt stat:ic}}whether to copy the log into the LaTeX
    document; default is {cmd:nostatic}, in which case the log is stored as a
    separate file and included in the LaTeX document using \input{c -(}{c )-}
    {p_end}
{synopt:[{cmd:{ul:no}}]{opt begin}[{cmd:(}{it:str}{cmd:)}]}omit or specify a custom
    begin command to be included before the results log; the default begin command
    is \begin{c -(}stlog{c )-}
    {p_end}
{synopt:[{cmd:{ul:no}}]{opt end}[{cmd:(}{it:str}{cmd:)}]}omit or specify a custom
    end command to be included after the results log; the default end command
    is \end{c -(}stlog{c )-}
    {p_end}
{synopt:[{cmd:no}]{opt beamer}}whether to use a default begin command
    appropriate the beamer class; default is {cmd:nobeamer}
    {p_end}

{syntab :Other}
{synopt:[{cmd:no}]{opt do}}enforce or suppress running the Stata commands
    {p_end}
{synopt:[{cmd:no}]{opt cert:ify}}whether to compare results against previous
    version; default is {cmd:nocertify}
    {p_end}
{synopt:[{cmd:no}]{opt dos:ave}}whether to store a copy of the commands in
    a do-file; default is {cmd:nodosave}
    {p_end}
{synopt:{opt logdir(path)}}where to store the log files; {it:path} may be an
    absolute or relative path; the default is to store the files in a subfolder
    that has the same base name as the source file;
    type {cmd:path("")} to store the files directly in the directory
    of the source file
    {p_end}
{synopt:{opt dodir(path)}}where to store the optional do-files; the default is to
    store the files in the same place as the log files
    {p_end}
{synoptline}

{synoptset 20 tabbed}{...}
{marker gropts}{synopthdr:graph_options}
{synoptline}
{syntab :Main}
{synopt:{opt as(fileformats)}}set the output format(s); default is {cmd:as(pdf)} (or {cmd:as(eps)}
    if {cmd:epsfig} is specified); dee help {helpb graph export} for available
    formats; multiple graph files will be stored if multiple formats are specified
    {p_end}
{synopt:{opt name(name)}}name of the graph window to be exported; default is to use the topmost graph
    {p_end}
{synopt:{opt overr:ide(options)}}format-dependent options to modify how the
    graph is converted.; see {it:override_options} in help
    {helpb graph export} for details
    {p_end}
{synopt:{opt dir(path)}}where to store the graph files; the default is to
    store the files in the same place as the log files
    {p_end}

{syntab :Embedding}
{synopt:[{cmd:{ul:no}}]{opt center}}whether to include the graph in a center environment; default is
    {cmd:nocenter}
    {p_end}
{synopt:{opt arg:s(args)}}arguments to be passed through to \includegraphics or
    \epsfig command
    {p_end}
{synopt:[{cmd:{ul:no}}]{opt suf:fix}}whether to type the file suffix
    in the \includegraphics or \epsfig command; default is {cmd:nosuffix}
    {p_end}
{synopt:[{cmd:no}]{opt epsfig}}whether to use \epsfig instead of
    \includegraphics; default is {cmd:noepsfig}
    {p_end}
{synopt:[{cmd:no}]{opt cust:om}}whether to skip embedding the graph
    in the LaTeX document; default is {cmd:nocustom}
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

{pstd}
    Typesetting options require
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
    {cmd:sttex} requires Stata 11 or newer.


{marker tags}{...}
{title:Dynamic tags}

    LaTeX commands
        {help sttex##stata:Stata or Mata output}
        {help sttex##graph:Graphs}
        {help sttex##inlexp:Inline expressions}
        {help sttex##include:Include external file}
        {help sttex##eof:End of input}

    Interpreted LaTeX comments
        {help sttex##target:Specify target file and overall options}
        {help sttex##parts:Partition the file into sections}
        {help sttex##ignore:Ignore tags}
        {help sttex##remove:Remove input}

{marker stata}{...}
{dlgtab:Stata or Mata output}

{pstd}
    To run a block of Stata commands and display the output in the target
    file, type

        {cmd:\begin{c -(}}{it:keyword}{cmd:{c )-}}{cmd:[}{it:id}{cmd:]}{cmd:[}{help sttex##stopts:{it:stlog_options}}{cmd:]}
            {it:commands}
        {cmd:\end{c -(}}{it:keyword}{cmd:{c )-}}

{pstd}
    where {it:id} provides a custom name for the block. The brackets do not
    need to be typed if {it:id} and {it:options} are omitted (but the brackets for {it:id}
    need to be typed if {it:options} are specified). An
    automatic name is assigned if {it:id} is omitted.

{pstd}
    The {cmd:\begin{c -(}{c )-}} and {cmd:\end{c -(}{c )-}} tags must start at
    the beginning of a line and any text in the same line after a tag is
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
    Within {it:commands} you can use the following tags:

{p2col:{cmd://STqui}}suppress the output of the subsequent command
    {p_end}
{p2col:{cmd://SToom}}suppress the output of the subsequent command and include
    an output-omitted message after the command
    {p_end}
{p2col:{cmd://STcnp}}include a page break and, depending on settings, a
    continued-on-next-page message
    {p_end}

{pstd}
    These tags must start at the beginning of a line; text in
    the same line after a tag is ignored.

{marker graph}{...}
{dlgtab:Graphs}

{pstd}
    To include a graph created by prior commands, type

        {cmd:\stgraph{cmd:[}}{it:id}{cmd:]}{cmd:{c -(}}{help sttex##gropts:{it:graph_options}}{cmd:{c )-}}

{pstd}
    where {it:id} provides a custom name for the graph. The brackets do not need to be typed if
    {it:id} is omitted. An automatic name is assigned if {it:id} is omitted.

{pstd}
    The {cmd:\stgraph{c -(}{c )-}} tag must start at the beginning of a line;
    any text in the same line after the tag will be ignored.

{marker inlexp}{...}
{dlgtab:Inline expressions}

{pstd}
    To add strings and values of scalar expressions in the text, use the
    {cmd:\stres{c -(}{c )-}} tag. The tag can be specified anywhere inside a line of text;
    it can also be specified multiple times in the same line or it can span multiple
    lines. {cmd:\stres{c -(}{c )-}} comes in three forms.

{pstd}
    Syntax 1: Runtime evaluation

            {cmd:\stres}{cmd:[}{it:id}{cmd:]}{cmd:{c -(}}{it:{help display:display_directive}}{cmd:{c )-}}

{pmore}
    With this syntax, {cmd:\stres{c -(}{c )-}} will be evaluated at
    runtime, i.e. when running the Stata commands found in the source
    file. {cmd:\stres{c -(}{c )-}} will apply Stata's {helpb display} command
    to {it:{help display:display_directive}} and then
    replace the tag with the output. The output will be backed up for future
    {cmd:sttex} passes, using {it:id} as an identifier. An automatic name is assigned if {it:id} is omitted;
    the brackets do not have to be typed if {it:id} is omitted.

{pstd}
    Syntax 2: Pre-processing time evaluation

            {cmd:\stres{c -(}{c -(}}{it:{help display:display_directive}}{cmd:{c )-}{c )-}}

{pmore}
    If you enclose {it:{help display:display_directive}} in curly braces, it will be
    evaluated while pre-processing the source file and not when running the Stata
    commands. This also means that evaluation occurs in each pass and not only
    in passes in which the surrounding Stata commands are run. Use this syntax to
    add results that do not depend on the other Stata commands (and might
    change between passes). For example, {cmd:\stres{c -(}{c -(}c(current_date){c )-}{c )-}}
    adds the current date.

{pstd}
    Syntax 3: Special functions

            {cmd:\stres{c -(}{c -(}}{it:keyword}{cmd:{c )-}{c )-}}

{pmore}
    Use this syntax for custom inclusion of Stata output and graphs (e.g. after
    applying option {cmd:custom} to a graph). {it:keyword} may be one of the following:

{p2colset 14 24 26 2}{...}
{p2col:{cmd:log}}add the output of last Stata block
    {p_end}
{p2col:{cmd:logname}}add the filename used for the output of the last Stata block
    {p_end}
{p2col:{cmd:graph}}add the last graph
    {p_end}
{p2col:{cmd:graphname}}add the filename used for the last graph (without suffix)
    {p_end}

{pmore}
    The way in which {cmd:\stres{c -(}{c -(}log{c )-}{c )-}} puts together the
    LaTeX code to display the output depends on the {help sttex##stopts:{it:stlog_options}}
    that were applied when generating the output. Likewise, the behavior of
    {cmd:\stres{c -(}{c -(}graph{c )-}{c )-}} depends on the
    {help sttex##gropts:{it:graph_options}} that were applied when exporting the graph.

{pstd}
    With syntax 1 and syntax 2, you can type {cmd:\%} instead of
    {cmd:%} within {it:{help display:display_directive}} to prevent LaTeX
    syntax highlighting from interpreting {cmd:%} and
    subsequent text as a comment. {cmd:sttex} will replace {cmd:\%} by
    {cmd:%} before processing {it:{help display:display_directive}}.

{marker include}{...}
{dlgtab:Include external file}

{pstd}
    To include contents from an external file, type

        {cmd:\stinput{c -(}}{it:filename}{cmd:{c )-}}

{pstd}
    where {it:filename} may contain an absolute
    or relative path. Dynamic tags within the external file will be
    interpreted in the same way as they are interpreted in the main
    file. {cmd:\stinput{c -(}{c )-}} must start at
    the beginning of a line; any text in the same line after the tag is
    ignored.

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
    {help sttex##opts:{it:general_options}}
    {help sttex##stopts:{it:stlog_options}}
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
    {help sttex##stopts:{it:stlog_options}}
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
    Specify {help sttex##stopts:{it:stlog_options}} and 
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


{marker remarks}{...}
{title:Remarks}

    {help sttex##stable:Use of stable names}
    {help sttex##preamble:Preamble of LaTeX file}

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
    {cmd:sttex} you should include command {cmd:\usepackage{c -(}stata{c )-}}
    in the preamble of the source file ({cmd:stata.sty} is provided by Stata Corp
    as part of {helpb sjlatex}). For example, the preamble in your file
    could look about as follows:

        \documentclass{c -(}article{c )-}
        \usepackage{c -(}graphicx{c )-}
        \usepackage{c -(}stata{c )-}
        ...
        \begin{c -(}document{c )-}
        ...


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
