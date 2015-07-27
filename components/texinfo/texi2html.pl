#!/usr/bin/perl
'di ';
'ig 00 ';
#+##############################################################################
#                                                                              #
# File: texi2html                                                              #
#                                                                              #
# Description: Program to transform most Texinfo documents to HTML             #
#                                                                              #
#-##############################################################################

# From @(#)texi2html	1.52 01/05/98	Written (mainly) by Lionel Cons, Lionel.Cons@cern.ch
# $Id: texi2html,v 1.5 1999/02/20 20:27:00 karl Exp $
# This version of texi2html is currently maintained at
# ftp://ftp.cs.umb.edu/pub/tex/texi2html by kb@cs.umb.edu.

# The man page for this program is included at the end of this file and can be
# viewed using the command 'nroff -man texi2html'.
# Please read the copyright at the end of the man page.

#+++############################################################################
#                                                                              #
# Constants                                                                    #
#                                                                              #
#---############################################################################

$DEBUG_TOC   =  1;
$DEBUG_INDEX =  2;
$DEBUG_BIB   =  4;
$DEBUG_GLOSS =  8;
$DEBUG_DEF   = 16;
$DEBUG_HTML  = 32;
$DEBUG_USER  = 64;

$BIBRE = '\[[\w\/-]+\]';		# RE for a bibliography reference
$FILERE = '[\/\w.+-]+';			# RE for a file name
$VARRE = '[^\s\{\}]+';			# RE for a variable name
$NODERE = '[^@{}:\'`",]+';		# RE for a node name
$NODESRE = '[^@{}:\'`"]+';		# RE for a list of node names
$XREFRE = '[^@{}]+';			# RE for a xref (should use NODERE)

$ERROR = "***";			        # prefix for errors and warnings
$THISVERSION = "1.56k";
$THISPROG = "texi2html $THISVERSION";	# program name and version
$HOMEPAGE = "http://wwwinfo.cern.ch/dis/texi2html/"; # program home page
$TODAY = &pretty_date;			# like "20 September 1993"
$SPLITTAG = "<!-- SPLIT HERE -->\n";	# tag to know where to split
$PROTECTTAG = "_ThisIsProtected_";	# tag to recognize protected sections
$html2_doctype = '<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0 Strict Level 2//EN">';

#
# language dependent constants
#
#$LDC_SEE = 'see';
#$LDC_SECTION = 'section';
#$LDC_IN = 'in';
#$LDC_TOC = 'Table of Contents';
#$LDC_GOTO = 'Go to the';
#$LDC_FOOT = 'Footnotes';
# TODO: @def* shortcuts

#
# pre-defined indices
#
%predefined_index = (
		    'cp', 'c',
		    'fn', 'f',
		    'vr', 'v',
		    'ky', 'k',
		    'pg', 'p',
		    'tp', 't',
	            );

#
# valid indices
#
%valid_index = (
		    'c', 1,
		    'f', 1,
		    'v', 1,
		    'k', 1,
		    'p', 1,
		    't', 1,
		);

#
# texinfo section names to level
#
%sec2level = (
	      'top', 0,
	      'chapter', 1,
	      'unnumbered', 1,
	      'majorheading', 1,
	      'chapheading', 1,
	      'appendix', 1,
	      'section', 2,
	      'unnumberedsec', 2,
	      'heading', 2,
	      'appendixsec', 2,
	      'appendixsection', 2,
	      'subsection', 3,
	      'unnumberedsubsec', 3,
	      'subheading', 3,
	      'appendixsubsec', 3,
	      'subsubsection', 4,
	      'unnumberedsubsubsec', 4,
	      'subsubheading', 4,
	      'appendixsubsubsec', 4,
	      );

#
# accent map, TeX command to ISO name
#
%accent_map = (
	       '"',  'uml',
	       '~',  'tilde',
	       '^',  'circ',
	       '`',  'grave',
	       '\'', 'acute',
	       );

#
# texinfo "simple things" (@foo) to HTML ones
#
%simple_map = (
	       # cf. makeinfo.c
	       "*", "<BR>",		# HTML+
	       " ", " ",
	       "\t", " ",
  	       "-", "&#173;",	# soft hyphen
	       "\n", "\n",
	       "|", "",
	       'tab', '<\/TD><TD>',
	       # spacing commands
	       ":", "",
	       "!", "!",
	       "?", "?",
	       ".", ".",
	       "-", "",
	       );

#
# texinfo "things" (@foo{}) to HTML ones
#
%things_map = (
	       'TeX', 'TeX',
	       'br', '<P>',		# paragraph break
	       'bullet', '*',
	       'copyright', '(C)',
	       'dots', '...',
	       'equiv', '==',
	       'error', 'error-->',
	       'expansion', '==>',
	       'minus', '-',
	       'point', '-!-',
	       'print', '-|',
	       'result', '=>',
	       'today', $TODAY,
	       );

#
# texinfo styles (@foo{bar}) to HTML ones
#
%style_map = (
	      'asis', '',
	      'b', 'B',
	      'cite', 'CITE',
	      'code', 'CODE',
	      'ctrl', '&do_ctrl',	# special case
	      'dfn', 'EM',		# DFN tag is illegal in the standard
	      'dmn', '',		# useless
	      'email', '&do_email',     # insert a clickable email address
	      'emph', 'EM',
	      'file', '"TT',		# will put quotes, cf. &apply_style
	      'i', 'I',
	      'kbd', 'KBD',
	      'key', 'KBD',
	      'math', 'EM',
	      'r', '',			# unsupported
	      'samp', '"SAMP',		# will put quotes, cf. &apply_style
	      'sc', '&do_sc',		# special case
	      'strong', 'STRONG',
	      't', 'TT',
	      'titlefont', '',		# useless
	      'uref', '&do_uref',       # insert a clickable URL
	      'url', '&do_url',         # insert a clickable URL
	      'var', 'VAR',
	      'w', '',			# unsupported
	      );

#
# texinfo format (@foo/@end foo) to HTML ones
#
%format_map = (
	       'display', 'PRE',
	       'example', 'PRE',
	       'format', 'PRE',
	       'lisp', 'PRE',
	       'quotation', 'BLOCKQUOTE',
	       'smallexample', 'PRE',
	       'smalllisp', 'PRE',
	       # lists
	       'itemize', 'UL',
	       'enumerate', 'OL',
	       # poorly supported
	       'flushleft', 'PRE',
	       'flushright', 'PRE',
	       );

#
# texinfo definition shortcuts to real ones
#
%def_map = (
	    # basic commands
	    'deffn', 0,
	    'defvr', 0,
	    'deftypefn', 0,
	    'deftypevr', 0,
	    'defcv', 0,
	    'defop', 0,
	    'deftp', 0,
	    # basic x commands
	    'deffnx', 0,
	    'defvrx', 0,
	    'deftypefnx', 0,
	    'deftypevrx', 0,
	    'defcvx', 0,
	    'defopx', 0,
	    'deftpx', 0,
	    # shortcuts
	    'defun', 'deffn Function',
	    'defmac', 'deffn Macro',
	    'defspec', 'deffn {Special Form}',
	    'defvar', 'defvr Variable',
	    'defopt', 'defvr {User Option}',
	    'deftypefun', 'deftypefn Function',
	    'deftypevar', 'deftypevr Variable',
	    'defivar', 'defcv {Instance Variable}',
	    'defmethod', 'defop Method',
	    # x shortcuts
	    'defunx', 'deffnx Function',
	    'defmacx', 'deffnx Macro',
	    'defspecx', 'deffnx {Special Form}',
	    'defvarx', 'defvrx Variable',
	    'defoptx', 'defvrx {User Option}',
	    'deftypefunx', 'deftypefnx Function',
	    'deftypevarx', 'deftypevrx Variable',
	    'defivarx', 'defcvx {Instance Variable}',
	    'defmethodx', 'defopx Method',
	    );

#
# things to skip
#
%to_skip = (
	    # comments
	    'c', 1,
	    'comment', 1,
            'ifnothtml', 1,
	    # useless
	    'detailmenu', 1,
            'direntry', 1,
	    'contents', 1,
	    'shortcontents', 1,
	    'summarycontents', 1,
	    'footnotestyle', 1,
	    'end ifclear', 1,
	    'end ifset', 1,
	    'titlepage', 1,
	    'end titlepage', 1,
	    # unsupported commands (formatting)
	    'afourpaper', 1,
	    'cropmarks', 1,
	    'finalout', 1,
	    'headings', 1,
            'sp', 1,
	    'need', 1,
	    'page', 1,
	    'setchapternewpage', 1,
	    'everyheading', 1,
	    'everyfooting', 1,
	    'evenheading', 1,
	    'evenfooting', 1,
	    'oddheading', 1,
	    'oddfooting', 1,
	    'smallbook', 1,
	    'vskip', 1,
	    'filbreak', 1,
	    'paragraphindent', 1,
	    # unsupported formats
	    'cartouche', 1,
	    'end cartouche', 1,
	    'group', 1,
	    'end group', 1,
	    );

#+++############################################################################
#                                                                              #
# Argument parsing, initialisation                                             #
#                                                                              #
#---############################################################################

%value = ();				# hold texinfo variables, see also -D

$use_bibliography = 1;
$use_acc = 0;
$debug = 0;
$doctype = '';
$check = 0;
$expandinfo = 0;
$use_glossary = 0;
$invisible_mark = '';
$use_iso = 0;
@include_dirs = ();
$show_menu = 0;
$number_sections = 0;
$split_node = 0;
$split_chapter = 0;
$monolithic = 0;
$verbose = 0;
$usage = <<EOT;
This is $THISPROG
To convert a Texinfo file to HMTL: $0 [options] file
  where options can be:
    -expandinfo    : use \@ifinfo sections, not \@iftex
    -glossary      : handle a glossary
    -invisible name: use 'name' as an invisible anchor
    -Dname         : define name like with \@set
    -I dir         : search also for files in 'dir'
    -menu          : handle menus
    -monolithic    : output only one file including ToC
    -number        : number sections
    -split_chapter : split on main sections
    -split_node    : split on nodes
    -usage         : print usage instructions
    -verbose       : verbose output
To check converted files: $0 -check [-verbose] files
EOT

while (@ARGV && $ARGV[0] =~ /^-/) {
    $_ = shift(@ARGV);
    if (/^-acc$/)            { $use_acc = 1; next; }
    if (/^-d(ebug)?(\d+)?$/) { $debug = $2 || shift(@ARGV); next; }
    if (/^-doctype$/)        { $doctype = shift(@ARGV); next; }
    if (/^-c(heck)?$/)       { $check = 1; next; }
    if (/^-e(xpandinfo)?$/)  { $expandinfo = 1; next; }
    if (/^-g(lossary)?$/)    { $use_glossary = 1; next; }
    if (/^-i(nvisible)?$/)   { $invisible_mark = shift(@ARGV); next; }
    if (/^-iso$/)            { $use_iso = 1; next; }
    if (/^-D(.+)?$/)         { $value{$1 || shift(@ARGV)} = 1; next; }
    if (/^-I(.+)?$/)         { push(@include_dirs, $1 || shift(@ARGV)); next; }
    if (/^-m(enu)?$/)        { $show_menu = 1; next; }
    if (/^-mono(lithic)?$/)  { $monolithic = 1; next; }
    if (/^-n(umber)?$/)      { $number_sections = 1; next; }
    if (/^-s(plit)?_?(n(ode)?|c(hapter)?)?$/) {
	if ($2 =~ /^n/) {
	    $split_node = 1;
	} else {
	    $split_chapter = 1;
	}
	next;
    }
    if (/^-v(erbose)?$/)     { $verbose = 1; next; }
    die $usage;
}
if ($check) {
    die $usage unless @ARGV > 0;
    &check;
    exit;
}

if (($split_node || $split_chapter) && $monolithic) {
    warn "Can't use -monolithic with -split, -monolithic ignored.\n";
    $monolithic = 0;
}
if ($expandinfo) {
    $to_skip{'ifinfo'}++;
    $to_skip{'end ifinfo'}++;
    $to_skip{'ifnottex'}++;
    $to_skip{'end ifnottex'}++;
} else {
    $to_skip{'iftex'}++;
    $to_skip{'end iftex'}++;
}
$invisible_mark = '<IMG SRC="invisible.xbm">' if $invisible_mark eq 'xbm';
die $usage unless @ARGV == 1;
$docu = shift(@ARGV);
if ($docu =~ /.*\//) {
    chop($docu_dir = $&);
    $docu_name = $';
} else {
    $docu_dir = '.';
    $docu_name = $docu;
}
unshift(@include_dirs, $docu_dir);
$docu_name =~ s/\.te?x(i|info)?$//;	# basename of the document

$docu_doc = "$docu_name.html";		# document's contents
if ($monolithic) {
    $docu_toc = $docu_foot = $docu_doc;
} else {
    $docu_toc  = "${docu_name}_toc.html";  # document's table of contents
    $docu_foot = "${docu_name}_foot.html"; # document's footnotes
}

#
# variables
#
$value{'html'} = 1;			# predefine html (the output format)
$value{'texi2html'} = $THISVERSION;	# predefine texi2html (the translator)
# _foo: internal to track @foo
foreach ('_author', '_title', '_subtitle',
	 '_settitle', '_setfilename') {
    $value{$_} = '';		        # prevent -w warnings
}
%node2sec = ();				# node to section name
%node2href = ();			# node to HREF
%bib2href = ();				# bibliography reference to HREF
%gloss2href = ();			# glossary term to HREF
@sections = ();				# list of sections
%tag2pro = ();				# protected sections

#
# initial indexes
#
$bib_num = 0;
$foot_num = 0;
$gloss_num = 0;
$idx_num = 0;
$sec_num = 0;
$doc_num = 0;
$html_num = 0;

#
# can I use ISO8879 characters? (HTML+)
#
if ($use_iso) {
    $things_map{'bullet'} = "&bull;";
    $things_map{'copyright'} = "&copy;";
    $things_map{'dots'} = "&hellip;";
    $things_map{'equiv'} = "&equiv;";
    $things_map{'expansion'} = "&rarr;";
    $things_map{'point'} = "&lowast;";
    $things_map{'result'} = "&rArr;";
}

#
# read texi2html extensions (if any)
#
$extensions = 'texi2html.ext'; # extensions in working directory
if (-f $extensions) {
    print "# reading extensions from $extensions\n" if $verbose;
    require($extensions);
}
($progdir = $0) =~ s/[^\/]+$//;
if ($progdir && ($progdir ne './')) {
    $extensions = "${progdir}texi2html.ext"; # extensions in texi2html directory
    if (-f $extensions) {
	print "# reading extensions from $extensions\n" if $verbose;
	require($extensions);
    }
}

print "# reading from $docu\n" if $verbose;

#+++############################################################################
#                                                                              #
# Pass 1: read source, handle command, variable, simple substitution           #
#                                                                              #
#---############################################################################

@lines = ();				# whole document
@toc_lines = ();			# table of contents
$toplevel = 0;			        # top level seen in hierarchy
$curlevel = 0;				# current level in TOC
$node = '';				# current node name
$in_table = 0;				# am I inside a table
$table_type = '';			# type of table ('', 'f', 'v', 'multi')
@tables = ();			        # nested table support
$in_bibliography = 0;			# am I inside a bibliography
$in_glossary = 0;			# am I inside a glossary
$in_top = 0;				# am I inside the top node
$in_pre = 0;				# am I inside a preformatted section
$in_list = 0;				# am I inside a list
$in_html = 0;				# am I inside an HTML section
$first_line = 1;		        # is it the first line
$dont_html = 0;				# don't protect HTML on this line
$split_num = 0;				# split index
$deferred_ref = '';			# deferred reference for indexes
@html_stack = ();			# HTML elements stack
$html_element = '';			# current HTML element
&html_reset;

# build code for simple substitutions
# the maps used (%simple_map and %things_map) MUST be aware of this
# watch out for regexps, / and escaped characters!
$subst_code = '';
foreach (keys(%simple_map)) {
    ($re = $_) =~ s/(\W)/\\$1/g; # protect regexp chars
    $subst_code .= "s/\\\@$re/$simple_map{$_}/g;\n";
}
foreach (keys(%things_map)) {
    $subst_code .= "s/\\\@$_\\{\\}/$things_map{$_}/g;\n";
}
if ($use_acc) {
    # accentuated characters
    foreach (keys(%accent_map)) {
	if ($_ eq "`") {
	    $subst_code .= "s/$;3";
	} elsif ($_ eq "'") {
	    $subst_code .= "s/$;4";
	} else {
	    $subst_code .= "s/\\\@\\$_";
	}
	$subst_code .= "([aeiou])/&\${1}$accent_map{$_};/gi;\n";
    }
}
eval("sub simple_substitutions { $subst_code }");

&init_input;
while ($_ = &next_line) {
    #
    # remove \input on the first lines only
    #
    if ($first_line) {
	next if /^\\input/;
	$first_line = 0;
    }
    #
    # parse texinfo tags
    #
    $tag = '';
    $end_tag = '';
    if (/^\s*\@end\s+(\w+)\b/) {
	$end_tag = $1;
    } elsif (/^\s*\@(\w+)\b/) {
	$tag = $1;
    }
    #
    # handle @ifhtml / @end ifhtml
    #
    if ($in_html) {
	if ($end_tag eq 'ifhtml') {
	    $in_html = 0;
	} else {
	    $tag2pro{$in_html} .= $_;
	}
	next;
    } elsif ($tag eq 'ifhtml') {
	$in_html = $PROTECTTAG . ++$html_num;
	push(@lines, $in_html);
	next;
    }
    #
    # try to skip the line
    #
    if ($end_tag) {
	next if $to_skip{"end $end_tag"};
    } elsif ($tag) {
	next if $to_skip{$tag};
	last if $tag eq 'bye';
    }
    if ($in_top) {
	# parsing the top node
	if ($tag eq 'node' || $tag eq 'include' || $sec2level{$tag}) {
	    # no more in top
	    $in_top = 0;
	} else {
	    # skip it
	    next;
	}
    }
    #
    # try to remove inlined comments
    # syntax from tex-mode.el comment-start-skip
    #
    s/((^|[^\@])(\@\@)*)\@c(omment)? .*/$1/;
    # non-@ substitutions cf. texinfmt.el
    unless ($in_pre) {
	s/``/\"/g;
	s/''/\"/g;
	s/([\w ])---([\w ])/$1--$2/g;
    }
    #
    # analyze the tag
    #
    if ($tag) {
	# skip lines
	&skip_until($tag), next if $tag eq 'ignore';
	if ($expandinfo) {
	    &skip_until($tag), next if $tag eq 'iftex';
	} else {
	    &skip_until($tag), next if $tag eq 'ifinfo';
	}
	&skip_until($tag), next if $tag eq 'tex';
	# handle special tables
	if ($tag =~ /^(|f|v|multi)table$/) {
	    $table_type = $1;
	    $tag = 'table';
	}
	# special cases
	if ($tag eq 'top' || ($tag eq 'node' && /^\@node\s+top\s*,/i)) {
	    $in_top = 1;
	    @lines = (); # ignore all lines before top (title page garbage)
	    next;
	} elsif ($tag eq 'node') {
	    $in_top = 0;
	    warn "$ERROR Bad node line: $_" unless $_ =~ /^\@node\s$NODESRE$/o;
	    $_ = &protect_html($_); # if node contains '&' for instance
	    s/^\@node\s+//;
	    ($node) = split(/,/);
	    &normalise_node($node);
	    if ($split_node) {
		&next_doc;
		push(@lines, $SPLITTAG) if $split_num++;
		push(@sections, $node);
	    }
	    next;
	} elsif ($tag eq 'include') {
	    if (/^\@include\s+($FILERE)\s*$/o) {
		$file = $1;
		unless (-e $file) {
		    foreach $dir (@include_dirs) {
			$file = "$dir/$1";
			last if -e $file;
		    }
		}
		if (-e $file) {
		    &open($file);
		    print "# including $file\n" if $verbose;
		} else {
		    warn "$ERROR Can't find $file, skipping";
		}
	    } else {
		warn "$ERROR Bad include line: $_";
	    }
	    next;
	} elsif ($tag eq 'ifclear') {
	    if (/^\@ifclear\s+($VARRE)\s*$/o) {
		next unless defined($value{$1});
		&skip_until($tag);
	    } else {
		warn "$ERROR Bad ifclear line: $_";
	    }
	    next;
	} elsif ($tag eq 'ifset') {
	    if (/^\@ifset\s+($VARRE)\s*$/o) {
		next if defined($value{$1});
		&skip_until($tag);
	    } else {
		warn "$ERROR Bad ifset line: $_";
	    }
	    next;
	} elsif ($tag eq 'menu') {
	    unless ($show_menu) {
		&skip_until($tag);
		next;
	    }
	    &html_push_if($tag);
	    push(@lines, &html_debug("\n", __LINE__));
	} elsif ($format_map{$tag}) {
	    $in_pre = 1 if $format_map{$tag} eq 'PRE';
	    &html_push_if($format_map{$tag});
	    push(@lines, &html_debug("\n", __LINE__));
	    $in_list++ if $format_map{$tag} eq 'UL' || $format_map{$tag} eq 'OL' ;
	    push(@lines, &debug("<$format_map{$tag}>\n", __LINE__));
	    next;
	} elsif ($tag eq 'table') {
	    if (/^\s*\@(|f|v|multi)table\s+\@(\w+)/) {
		$in_table = $2;
		unshift(@tables, join($;, $table_type, $in_table));
		if ($table_type eq "multi") {
		    push(@lines, &debug("<TABLE BORDER>\n", __LINE__));
		    &html_push_if('TABLE');
		} else {
		    push(@lines, &debug("<DL COMPACT>\n", __LINE__));
		    &html_push_if('DL');
		}
		push(@lines, &html_debug("\n", __LINE__));
	    } else {
		warn "$ERROR Bad table line: $_";
	    }
	    next;
	} elsif ($tag eq 'synindex' || $tag eq 'syncodeindex') {
	    if (/^\@$tag\s+(\w)\w\s+(\w)\w\s*$/) {
		eval("*${1}index = *${2}index");
	    } else {
		warn "$ERROR Bad syn*index line: $_";
	    }
	    next;
	} elsif ($tag eq 'sp') {
	    push(@lines, &debug("<P>\n", __LINE__));
	    next;
	} elsif ($tag eq 'setref') {
	    &protect_html; # if setref contains '&' for instance
	    if (/^\@$tag\s*{($NODERE)}\s*$/) {
		$setref = $1;
		$setref =~ s/\s+/ /g; # normalize
		$setref =~ s/ $//;
		$node2sec{$setref} = $name;
		$node2href{$setref} = "$docu_doc#$docid";
	    } else {
		warn "$ERROR Bad setref line: $_";
	    }
	    next;
	} elsif ($tag eq 'defindex' || $tag eq 'defcodeindex') {
	    if (/^\@$tag\s+(\w\w)\s*$/) {
		$valid_index{$1} = 1;
	    } else {
		warn "$ERROR Bad defindex line: $_";
	    }
	    next;
	} elsif ($tag eq 'lowersections') {
	    local ($sec, $level);
	    while (($sec, $level) = each %sec2level) {
		$sec2level{$sec} = $level + 1;
	    }
	    next;
	} elsif ($tag eq 'raisesections') {
	    local ($sec, $level);
	    while (($sec, $level) = each %sec2level) {
		$sec2level{$sec} = $level - 1;
	    }
	    next;
	} elsif (defined($def_map{$tag})) {
	    if ($def_map{$tag}) {
		s/^\@$tag\s+//;
		$tag = $def_map{$tag};
		$_ = "\@$tag $_";
		$tag =~ s/\s.*//;
	    }
	} elsif (defined($user_sub{$tag})) {
	    s/^\@$tag\s+//;
	    $sub = $user_sub{$tag};
	    print "# user $tag = $sub, arg: $_" if $debug & $DEBUG_USER;
	    if (defined(&$sub)) {
		chop($_);
		&$sub($_);
	    } else {
		warn "$ERROR Bad user sub for $tag: $sub\n";
	    }
	    next;
	}
	if (defined($def_map{$tag})) {
	    s/^\@$tag\s+//;
	    if ($tag =~ /x$/) {
		# extra definition line
		$tag = $`;
		$is_extra = 1;
	    } else {
		$is_extra = 0;
	    }
	    while (/\{([^\{\}]*)\}/) {
		# this is a {} construct
		($before, $contents, $after) = ($`, $1, $');
		# protect spaces
		$contents =~ s/\s+/$;9/g;
		# restore $_ protecting {}
		$_ = "$before$;7$contents$;8$after";
	    }
	    @args = split(/\s+/, &protect_html($_));
	    foreach (@args) {
		s/$;9/ /g;	# unprotect spaces
		s/$;7/\{/g;	# ... {
		s/$;8/\}/g;	# ... }
	    }
	    $type = shift(@args);
	    $type =~ s/^\{(.*)\}$/$1/;
	    print "# def ($tag): {$type} ", join(', ', @args), "\n"
		if $debug & $DEBUG_DEF;
	    $type .= ':'; # it's nicer like this
	    $name = shift(@args);
	    $name =~ s/^\{(.*)\}$/$1/;
	    if ($is_extra) {
		$_ = &debug("<DT>", __LINE__);
	    } else {
		$_ = &debug("<DL>\n<DT>", __LINE__);
	    }
	    if ($tag eq 'deffn' || $tag eq 'defvr' || $tag eq 'deftp') {
		$_ .= "<U>$type</U> <B>$name</B>";
		$_ .= " <I>@args</I>" if @args;
	    } elsif ($tag eq 'deftypefn' || $tag eq 'deftypevr'
		     || $tag eq 'defcv' || $tag eq 'defop') {
		$ftype = $name;
		$name = shift(@args);
		$name =~ s/^\{(.*)\}$/$1/;
		$_ .= "<U>$type</U> $ftype <B>$name</B>";
		$_ .= " <I>@args</I>" if @args;
	    } else {
		warn "$ERROR Unknown definition type: $tag\n";
		$_ .= "<U>$type</U> <B>$name</B>";
		$_ .= " <I>@args</I>" if @args;
	    }
 	    $_ .= &debug("\n<DD>", __LINE__);
	    $name = &unprotect_html($name);
	    if ($tag eq 'deffn' || $tag eq 'deftypefn') {
		unshift(@input_spool, "\@findex $name\n");
	    } elsif ($tag eq 'defop') {
		unshift(@input_spool, "\@findex $name on $ftype\n");
	    } elsif ($tag eq 'defvr' || $tag eq 'deftypevr' || $tag eq 'defcv') {
		unshift(@input_spool, "\@vindex $name\n");
	    } else {
		unshift(@input_spool, "\@tindex $name\n");
	    }
	    $dont_html = 1;
	}
    } elsif ($end_tag) {
	if ($format_map{$end_tag}) {
	    $in_pre = 0 if $format_map{$end_tag} eq 'PRE';
	    $in_list-- if $format_map{$end_tag} eq 'UL' || $format_map{$end_tag} eq 'OL' ;
	    &html_pop_if('LI', 'P');
	    &html_pop_if();
	    push(@lines, &debug("</$format_map{$end_tag}>\n", __LINE__));
	    push(@lines, &html_debug("\n", __LINE__));
	} elsif ($end_tag =~ /^(|f|v|multi)table$/) {
	    unless (@tables) {
		warn "$ERROR \@end $end_tag without \@*table\n";
		next;
	    }
	    ($table_type, $in_table) = split($;, shift(@tables));
	    unless ($1 eq $table_type) {
		warn "$ERROR \@end $end_tag without matching \@$end_tag\n";
		next;
	    }
	    if ($table_type eq "multi") {
		push(@lines, "</TR></TABLE>\n");
		&html_pop_if('TR');
	    } else {
		push(@lines, "</DL>\n");
		&html_pop_if('DD');
	    }
	    &html_pop_if();
	    if (@tables) {
		($table_type, $in_table) = split($;, $tables[0]);
	    } else {
		$in_table = 0;
	    }
	} elsif (defined($def_map{$end_tag})) {
 	    push(@lines, &debug("</DL>\n", __LINE__));
	} elsif ($end_tag eq 'menu') {
	    &html_pop_if();
	    push(@lines, $_); # must keep it for pass 2
	}
	next;
    }
    #
    # misc things
    #
    # protect texi and HTML things
    &protect_texi;
    $_ = &protect_html($_) unless $dont_html;
    $dont_html = 0;
    # substitution (unsupported things)
    s/^\@center\s+//g;
    s/^\@exdent\s+//g;
    s/\@noindent\s+//g;
    s/\@refill\s+//g;
    # other substitutions
    &simple_substitutions;
    s/\@value{($VARRE)}/$value{$1}/eg;
    s/\@footnote\{/\@footnote$docu_doc\{/g; # mark footnotes, cf. pass 4
    #
    # analyze the tag again
    #
    if ($tag) {
	if (defined($sec2level{$tag}) && $sec2level{$tag} > 0) {
	    if (/^\@$tag\s+(.+)$/) {
		$name = $1;
		$name =~ s/\s+$//;
		$level = $sec2level{$tag};
		$name = &update_sec_num($tag, $level) . " $name"
		    if $number_sections && $tag !~ /^unnumbered/;
		if ($tag =~ /heading$/) {
		    push(@lines, &html_debug("\n", __LINE__));
		    if ($html_element ne 'body') {
			# We are in a nice pickle here. We are trying to get a H? heading
			# even though we are not in the body level. So, we convert it to a
			# nice, bold, line by itself.
			$_ = &debug("\n\n<P><STRONG>$name</STRONG>\n\n", __LINE__);
		    } else {
			$_ = &debug("<H$level>$name</H$level>\n", __LINE__);
			&html_push_if('body');
		    }
		    print "# heading, section $name, level $level\n"
			if $debug & $DEBUG_TOC;
		} else {
		    if ($split_chapter) {
			unless ($toplevel) {
			    # first time we see a "section"
			    unless ($level == 1) {
				warn "$ERROR The first section found is not of level 1: $_";
				warn "$ERROR I'll split on sections of level $level...\n";
			    }
			    $toplevel = $level;
			}
			if ($level == $toplevel) {
			    &next_doc;
			    push(@lines, $SPLITTAG) if $split_num++;
			    push(@sections, $name);
			}
		    }
		    $sec_num++;
		    $docid = "SEC$sec_num";
		    $tocid = "TOC$sec_num";
		    # check biblio and glossary
		    $in_bibliography = ($name =~ /^([A-Z]|\d+)?(\.\d+)*\s*bibliography$/i);
		    $in_glossary = ($name =~ /^([A-Z]|\d+)?(\.\d+)*\s*glossary$/i);
		    # check node
		    if ($node) {
			if ($node2sec{$node}) {
			    warn "$ERROR Duplicate node found: $node\n";
			} else {
			    $node2sec{$node} = $name;
			    $node2href{$node} = "$docu_doc#$docid";
			    print "# node $node, section $name, level $level\n"
				if $debug & $DEBUG_TOC;
			}
			$node = '';
		    } else {
			print "# no node, section $name, level $level\n"
			    if $debug & $DEBUG_TOC;
		    }
		    # update TOC
		    while ($level > $curlevel) {
			$curlevel++;
			push(@toc_lines, "<UL>\n");
		    }
		    while ($level < $curlevel) {
			$curlevel--;
			push(@toc_lines, "</UL>\n");
		    }
		    $_ = "<LI>" . &anchor($tocid, "$docu_doc#$docid", $name, 1);
		    push(@toc_lines, &substitute_style($_));
		    # update DOC
		    push(@lines, &html_debug("\n", __LINE__));
		    &html_reset;
		    $_ =  "<H$level>".&anchor($docid, "$docu_toc#$tocid", $name)."</H$level>\n";
		    $_ = &debug($_, __LINE__);
		    push(@lines, &html_debug("\n", __LINE__));
		}
		# update DOC
		foreach $line (split(/\n+/, $_)) {
		    push(@lines, "$line\n");
		}
		next;
	    } else {
		warn "$ERROR Bad section line: $_";
	    }
	} else {
	    # track variables
	    $value{$1} = $2, next if /^\@set\s+($VARRE)\s+(.*)$/o;
	    delete $value{$1}, next if /^\@clear\s+($VARRE)\s*$/o;
	    # store things
	    $value{'_setfilename'}   = $1, next if /^\@setfilename\s+(.*)$/;
	    $value{'_settitle'}      = $1, next if /^\@settitle\s+(.*)$/;
	    $value{'_author'}   .= "$1\n", next if /^\@author\s+(.*)$/;
	    $value{'_subtitle'} .= "$1\n", next if /^\@subtitle\s+(.*)$/;
	    $value{'_title'}    .= "$1\n", next if /^\@title\s+(.*)$/;
	    # index
	    if (/^\@(..?)index\s+/) {
		unless ($valid_index{$1}) {
		    warn "$ERROR Undefined index command: $_";
		    next;
		}
		$id = 'IDX' . ++$idx_num;
		$index = $1 . 'index';
		$what = &substitute_style($');
		$what =~ s/\s+$//;
		print "# found $index for '$what' id $id\n"
		    if $debug & $DEBUG_INDEX;
		eval(<<EOC);
		if (defined(\$$index\{\$what\})) {
		    \$$index\{\$what\} .= "$;$docu_doc#$id";
		} else {
		    \$$index\{\$what\} = "$docu_doc#$id";
		}
EOC
		#
		# dirty hack to see if I can put an invisible anchor...
		#
		if ($html_element eq 'P' ||
		    $html_element eq 'LI' ||
		    $html_element eq 'DT' ||
		    $html_element eq 'DD' ||
		    $html_element eq 'ADDRESS' ||
		    $html_element eq 'B' ||
		    $html_element eq 'BLOCKQUOTE' ||
		    $html_element eq 'PRE' ||
		    $html_element eq 'SAMP') {
                    push(@lines, &anchor($id, '', $invisible_mark, !$in_pre));
                } elsif ($html_element eq 'body') {
		    push(@lines, &debug("<P>\n", __LINE__));
                    push(@lines, &anchor($id, '', $invisible_mark, !$in_pre));
		    &html_push('P');
		} elsif ($html_element eq 'DL' ||
			 $html_element eq 'UL' ||
			 $html_element eq 'OL' ) {
		    $deferred_ref .= &anchor($id, '', $invisible_mark, !$in_pre) . " ";
		}
		next;
	    }
	    # list item
	    if (/^\s*\@itemx?\s+/) {
		$what = $';
		$what =~ s/\s+$//;
		if ($in_bibliography && $use_bibliography) {
		    if ($what =~ /^$BIBRE$/o) {
			$id = 'BIB' . ++$bib_num;
			$bib2href{$what} = "$docu_doc#$id";
			print "# found bibliography for '$what' id $id\n"
			    if $debug & $DEBUG_BIB;
			$what = &anchor($id, '', $what);
		    }
		} elsif ($in_glossary && $use_glossary) {
		    $id = 'GLOSS' . ++$gloss_num;
		    $entry = $what;
		    $entry =~ tr/A-Z/a-z/ unless $entry =~ /^[A-Z\s]+$/;
		    $gloss2href{$entry} = "$docu_doc#$id";
		    print "# found glossary for '$entry' id $id\n"
			if $debug & $DEBUG_GLOSS;
		    $what = &anchor($id, '', $what);
		}
		&html_pop_if('P');
		if ($html_element eq 'DL' || $html_element eq 'DD') {
		    if ($things_map{$in_table} && !$what) {
			# special case to allow @table @bullet for instance
			push(@lines, &debug("<DT>$things_map{$in_table}\n", __LINE__));
		    } else {
			push(@lines, &debug("<DT>\@$in_table\{$what\}\n", __LINE__));
		    }
		    push(@lines, "<DD>");
		    &html_push('DD') unless $html_element eq 'DD';
		    if ($table_type) { # add also an index
			unshift(@input_spool, "\@${table_type}index $what\n");
		    }
		} elsif ($html_element eq 'TABLE') {
		    push(@lines, &debug("<TR><TD>$what</TD>\n", __LINE__));
		    &html_push('TR');
		} elsif ($html_element eq 'TR') {
		    push(@lines, &debug("</TR>\n", __LINE__));
		    push(@lines, &debug("<TR><TD>$what</TD>\n", __LINE__));
		} else {
		    push(@lines, &debug("<LI>$what\n", __LINE__));
		    &html_push('LI') unless $html_element eq 'LI';
		}
		push(@lines, &html_debug("\n", __LINE__));
		if ($deferred_ref) {
		    push(@lines, &debug("$deferred_ref\n", __LINE__));
		    $deferred_ref = '';
		}
		next;
	    } elsif (/^\@tab\s+(.*)$/) {
		push(@lines, "<TD>$1</TD>\n");
		next;
	    }
	}
    }
    # paragraph separator
    if ($_ eq "\n") {
	next if $#lines >= 0 && $lines[$#lines] eq "\n";
	if ($html_element eq 'P') {
	    push(@lines, "\n");
	    $_ = &debug("\n", __LINE__);
	    &html_pop;
	}
    } elsif ($html_element eq 'body' || $html_element eq 'BLOCKQUOTE') {
	push(@lines, "<P>\n");
	&html_push('P');
	$_ = &debug($_, __LINE__);
    }
    # otherwise
    push(@lines, $_);
}

# finish TOC
$level = 0;
while ($level < $curlevel) {
    $curlevel--;
    push(@toc_lines, "</UL>\n");
}

print "# end of pass 1\n" if $verbose;

#+++############################################################################
#                                                                              #
# Pass 2/3: handle style, menu, index, cross-reference                         #
#                                                                              #
#---############################################################################

@lines2 = ();				# whole document (2nd pass)
@lines3 = ();				# whole document (3rd pass)
$in_menu = 0;				# am I inside a menu

while (@lines) {
    $_ = shift(@lines);
    #
    # special case (protected sections)
    #
    if (/^$PROTECTTAG/o) {
	push(@lines2, $_);
	next;
    }
    #
    # menu
    #
    $in_menu = 1, push(@lines2, &debug("<UL>\n", __LINE__)), next if /^\@menu\b/;
    $in_menu = 0, push(@lines2, &debug("</UL>\n", __LINE__)), next if /^\@end\s+menu\b/;
    if ($in_menu) {
	if (/^\*\s+($NODERE)::/o) {
	    $descr = $';
	    chop($descr);
	    &menu_entry($1, $1, $descr);
	} elsif (/^\*\s+(.+):\s+([^\t,\.\n]+)[\t,\.\n]/) {
	    $descr = $';
	    chop($descr);
	    &menu_entry($1, $2, $descr);
	} elsif (/^\*/) {
	    warn "$ERROR Bad menu line: $_";
	} else { # description continued?
	    push(@lines2, $_);
	}
	next;
    }
    #
    # printindex
    #
    if (/^\@printindex\s+(\w\w)\b/) {
	local($index, *ary, @keys, $key, $letter, $last_letter, @refs);
	if ($predefined_index{$1}) {
	    $index = $predefined_index{$1} . 'index';
	} else {
	    $index = $1 . 'index';
	}
	eval("*ary = *$index");
	@keys = keys(%ary);
	foreach $key (@keys) {
	    $_ = $key;
	    1 while s/<(\w+)>\`(.*)\'<\/\1>/$2/; # remove HTML tags with quotes
	    1 while s/<(\w+)>(.*)<\/\1>/$2/;     # remove HTML tags
	    $_ = &unprotect_html($_);
	    &unprotect_texi;
	    tr/A-Z/a-z/; # lowercase
	    $key2alpha{$key} = $_;
	    print "# index $key sorted as $_\n"
		if $key ne $_ && $debug & $DEBUG_INDEX;
	}
	push(@lines2, "Jump to:\n");
	$last_letter = undef;
	foreach $key (sort byalpha @keys) {
	    $letter = substr($key2alpha{$key}, 0, 1);
	    $letter = substr($key2alpha{$key}, 0, 2) if $letter eq $;;
	    if (!defined($last_letter) || $letter ne $last_letter) {
		push(@lines2, "-\n") if defined($last_letter);
		push(@lines2, "<A HREF=\"#$index\_$letter\">" . &protect_html($letter) . "</A>\n");
		$last_letter = $letter;
	    }
	}
	push(@lines2, "<P>\n");
	$last_letter = undef;
	foreach $key (sort byalpha @keys) {
	    $letter = substr($key2alpha{$key}, 0, 1);
	    $letter = substr($key2alpha{$key}, 0, 2) if $letter eq $;;
	    if (!defined($last_letter) || $letter ne $last_letter) {
		push(@lines2, "</DIR>\n") if defined($last_letter);
		push(@lines2, "<H2><A NAME=\"$index\_$letter\">" . &protect_html($letter) . "</A></H2>\n");
		push(@lines2, "<DIR>\n");
		$last_letter = $letter;
	    }
	    @refs = ();
	    foreach (split(/$;/, $ary{$key})) {
		push(@refs, &anchor('', $_, $key, 0));
	    }
	    push(@lines2, "<LI>" . join(", ", @refs) . "\n");
	}
	push(@lines2, "</DIR>\n") if defined($last_letter);
	next;
    }
    #
    # simple style substitutions
    #
    $_ = &substitute_style($_);
    #
    # xref
    #
    while (/\@(x|px|info|)ref{($XREFRE)(}?)/o) {
	# note: Texinfo may accept other characters
	($type, $nodes, $full) = ($1, $2, $3);
	($before, $after) = ($`, $');
	if (! $full && $after) {
	    warn "$ERROR Bad xref (no ending } on line): $_";
	    $_ = "$before$;0${type}ref\{$nodes$after";
	    next; # while xref
	}
	if ($type eq 'x') {
	    $type = 'See ';
	} elsif ($type eq 'px') {
	    $type = 'see ';
	} elsif ($type eq 'info') {
	    $type = 'See Info';
	} else {
	    $type = '';
	}
	unless ($full) {
	    $next = shift(@lines);
	    $next = &substitute_style($next);
	    chop($nodes); # remove final newline
	    if ($next =~ /\}/) { # split on 2 lines
		$nodes .= " $`";
		$after = $';
	    } else {
		$nodes .= " $next";
		$next = shift(@lines);
		$next = &substitute_style($next);
		chop($nodes);
		if ($next =~ /\}/) { # split on 3 lines
		    $nodes .= " $`";
		    $after = $';
		} else {
		    warn "$ERROR Bad xref (no ending }): $_";
		    $_ = "$before$;0xref\{$nodes$after";
		    unshift(@lines, $next);
		    next; # while xref
		}
	    }
	}
	$nodes =~ s/\s+/ /g; # remove useless spaces
	@args = split(/\s*,\s*/, $nodes);
	$node = $args[0]; # the node is always the first arg
	&normalise_node($node);
	$sec = $node2sec{$node};
	if (@args == 5) { # reference to another manual
	    $sec = $args[2] || $node;
	    $man = $args[4] || $args[3];
	    $_ = "${before}${type}section `$sec' in \@cite{$man}$after";
	} elsif ($type =~ /Info/) { # inforef
	    warn "$ERROR Wrong number of arguments: $_" unless @args == 3;
	    ($nn, $_, $in) = @args;
	    $_ = "${before}${type} file `$in', node `$nn'$after";
	} elsif ($sec) {
	    $href = $node2href{$node};
	    $_ = "${before}${type}section " . &anchor('', $href, $sec) . $after;
	} else {
	    warn "$ERROR Undefined node ($node): $_";
	    $_ = "$before$;0xref{$nodes}$after";
	}
    }
    
    if (/^\@image\s*{/) {
      s/\@image\s*{//;
      my (@args) = split (/,/);
      my $base = $args[0];
      my $image;
      if (-r "$base.jpg") {
        $image = "$base.jpg";
      } elsif (-r "$base.png") {
        $image = "$base.png";
      } elsif (-r "$base.gif") {
        $image = "$base.gif";
      } else {
        warn "$ERROR no image file for $base: $_";
      }
      $_ = "<IMG SRC=\"$image\" ALT=\"$base\">";
    }

    #
    # try to guess bibliography references or glossary terms
    #
    unless (/^<H\d><A NAME=\"SEC\d/) {
	if ($use_bibliography) {
	    $done = '';
	    while (/$BIBRE/o) {
		($pre, $what, $post) = ($`, $&, $');
		$href = $bib2href{$what};
		if (defined($href) && $post !~ /^[^<]*<\/A>/) {
		    $done .= $pre . &anchor('', $href, $what);
		} else {
		    $done .= "$pre$what";
		}
		$_ = $post;
	    }
	    $_ = $done . $_;
	}
	if ($use_glossary) {
	    $done = '';
	    while (/\b\w+\b/) {
		($pre, $what, $post) = ($`, $&, $');
		$entry = $what;
		$entry =~ tr/A-Z/a-z/ unless $entry =~ /^[A-Z\s]+$/;
		$href = $gloss2href{$entry};
		if (defined($href) && $post !~ /^[^<]*<\/A>/) {
		    $done .= $pre . &anchor('', $href, $what);
		} else {
		    $done .= "$pre$what";
		}
		$_ = $post;
	    }
	    $_ = $done . $_;
	}
    }
    # otherwise
    push(@lines2, $_);
}
print "# end of pass 2\n" if $verbose;

#
# split style substitutions
#
while (@lines2) {
    $_ = shift(@lines2);
    #
    # special case (protected sections)
    #
    if (/^$PROTECTTAG/o) {
	push(@lines3, $_);
	next;
    }
    #
    # split style substitutions
    #
    $old = '';
    while ($old ne $_) {
        $old = $_;
	if (/\@(\w+)\{/) {
	    ($before, $style, $after) = ($`, $1, $');
	    if (defined($style_map{$style})) {
		$_ = $after;
		$text = '';
		$after = '';
		$failed = 1;
		while (@lines2) {
		    if (/\}/) {
			$text .= $`;
			$after = $';
			$failed = 0;
			last;
		    } else {
			$text .= $_;
			$_ = shift(@lines2);
		    }
		}
		if ($failed) {
		    die "* Bad syntax (\@$style) after: $before\n";
		} else {
		    $text = &apply_style($style, $text);
		    $_ = "$before$text$after";
		}
	    }
	}
    }
    # otherwise
    push(@lines3, $_);
}
print "# end of pass 3\n" if $verbose;

#+++############################################################################
#                                                                              #
# Pass 4: foot notes, final cleanup                                            #
#                                                                              #
#---############################################################################

@foot_lines = ();			# footnotes
@doc_lines = ();			# final document
$end_of_para = 0;			# true if last line is <P>

while (@lines3) {
    $_ = shift(@lines3);
    #
    # special case (protected sections)
    #
    if (/^$PROTECTTAG/o) {
	push(@doc_lines, $_);
	$end_of_para = 0;
	next;
    }
    #
    # footnotes
    #
    while (/\@footnote([^\{\s]+)\{/) {
	($before, $d, $after) = ($`, $1, $');
	$_ = $after;
	$text = '';
	$after = '';
	$failed = 1;
	while (@lines3) {
	    if (/\}/) {
		$text .= $`;
		$after = $';
		$failed = 0;
		last;
	    } else {
		$text .= $_;
		$_ = shift(@lines3);
	    }
	}
	if ($failed) {
	    die "* Bad syntax (\@footnote) after: $before\n";
	} else {
	    $foot_num++;
	    $docid  = "DOCF$foot_num";
	    $footid = "FOOT$foot_num";
	    $foot = "($foot_num)";
	    push(@foot_lines, "<H3>" . &anchor($footid, "$d#$docid", $foot) . "</H3>\n");
	    $text = "<P>$text" unless $text =~ /^\s*<P>/;
	    push(@foot_lines, "$text\n");
	    $_ = $before . &anchor($docid, "$docu_foot#$footid", $foot) . $after;
	}
    }
    #
    # remove unnecessary <P>
    #
    if (/^\s*<P>\s*$/) {
	next if $end_of_para++;
    } else {
	$end_of_para = 0;
    }
    # otherwise
    push(@doc_lines, $_);
}
print "# end of pass 4\n" if $verbose;

#+++############################################################################
#                                                                              #
# Pass 5: print things                                                         #
#                                                                              #
#---############################################################################

$header = <<EOT;
<!-- Created by $THISPROG from $docu on $TODAY -->
EOT

$full_title = $value{'_title'} || $value{'_settitle'} || "Untitled Document";
$title = $value{'_settitle'} || $full_title;
$_ = &substitute_style($full_title);
&unprotect_texi;
s/\n$//; # rmv last \n (if any)
$full_title = "<H1>" . join("</H1>\n<H1>", split(/\n/, $_)) . "</H1>\n";

#
# print ToC
#
if (!$monolithic && @toc_lines) {
    if (open(FILE, "> $docu_toc")) {
	print "# creating $docu_toc...\n" if $verbose;
	&print_toplevel_header("$title - Table of Contents");
	&print_ruler;
	&print(*toc_lines, FILE);
	&print_toplevel_footer;
	close(FILE);
    } else {
	warn "$ERROR Can't write to $docu_toc: $!\n";
    }
}

#
# print footnotes
#
if (!$monolithic && @foot_lines) {
    if (open(FILE, "> $docu_foot")) {
	print "# creating $docu_foot...\n" if $verbose;
	&print_toplevel_header("$title - Footnotes");
	&print_ruler;
        &print(*foot_lines, FILE);
	&print_toplevel_footer;
	close(FILE);
    } else {
	warn "$ERROR Can't write to $docu_foot: $!\n";
    }
}

#
# print document
#
if ($split_chapter || $split_node) { # split
    $doc_num = 0;
    $last_num = scalar(@sections);
    $first_doc = &doc_name(1);
    $last_doc = &doc_name($last_num);
    while (@sections) {
	$section = shift(@sections);
	&next_doc;
	if (open(FILE, "> $docu_doc")) {
	    print "# creating $docu_doc...\n" if $verbose;
	    &print_header("$title - $section");
	    $prev_doc = ($doc_num == 1 ? undef : &doc_name($doc_num - 1));
	    $next_doc = ($doc_num == $last_num ? undef : &doc_name($doc_num + 1));
	    $navigation = "Go to the ";
	    $navigation .= ($prev_doc ? &anchor('', $first_doc, "first") : "first");
	    $navigation .= ", ";
	    $navigation .= ($prev_doc ? &anchor('', $prev_doc, "previous") : "previous");
	    $navigation .= ", ";
	    $navigation .= ($next_doc ? &anchor('', $next_doc, "next") : "next");
	    $navigation .= ", ";
	    $navigation .= ($next_doc ? &anchor('', $last_doc, "last") : "last");
	    $navigation .= " section, " . &anchor('', $docu_toc, "table of contents") . ".\n";
	    print FILE $navigation;
	    &print_ruler;
	    # find corresponding lines
            @tmp_lines = ();
            while (@doc_lines) {
		$_ = shift(@doc_lines);
		last if ($_ eq $SPLITTAG);
		push(@tmp_lines, $_);
	    }
            &print(*tmp_lines, FILE);
	    &print_ruler;
	    print FILE $navigation;
	    &print_footer;
	    close(FILE);
	} else {
	    warn "$ERROR Can't write to $docu_doc: $!\n";
	}
    }
} else { # not split
    if (open(FILE, "> $docu_doc")) {
	print "# creating $docu_doc...\n" if $verbose;
	if ($monolithic || !@toc_lines) {
	    &print_toplevel_header($title);
	} else {
	    &print_header($title);
	    print FILE $full_title;
	}
	if ($monolithic && @toc_lines) {
	    &print_ruler;
 	    print FILE "<H1>Table of Contents</H1>\n";
 	    &print(*toc_lines, FILE);
	}
	&print_ruler;
        &print(*doc_lines, FILE);
	if ($monolithic && @foot_lines) {
	    &print_ruler;
 	    print FILE "<H1>Footnotes</H1>\n";
 	    &print(*foot_lines, FILE);
	}
	if ($monolithic || !@toc_lines) {
	    &print_toplevel_footer;
	} else {
	    &print_footer;
	}
	close(FILE);
    } else {
	warn "$ERROR Can't write to $docu_doc: $!\n";
    }
}

print "# that's all folks\n" if $verbose;

#+++############################################################################
#                                                                              #
# Low level functions                                                          #
#                                                                              #
#---############################################################################

sub update_sec_num {
    local($name, $level) = @_;
    my $ret;

    $level--; # here we start at 0
    if ($name =~ /^appendix/) {
	# appendix style
	if (@appendix_sec_num) {
	    &incr_sec_num($level, @appendix_sec_num);
	} else {
	    @appendix_sec_num = ('A', 0, 0, 0);
	}
	$ret = join('.', @appendix_sec_num[0..$level]);
    } else {
	# normal style
	if (@normal_sec_num) {
	    &incr_sec_num($level, @normal_sec_num);
	} else {
	    @normal_sec_num = (1, 0, 0, 0);
	}
	$ret = join('.', @normal_sec_num[0..$level]);
    }
    
    $ret .= "." if $level == 0;
    return $ret;
}

sub incr_sec_num {
    local($level, $l);
    $level = shift(@_);
    $_[$level]++;
    foreach $l ($level+1 .. 3) {
	$_[$l] = 0;
    }
}

sub check {
    local($_, %seen, %context, $before, $match, $after);

    while (<>) {
	if (/\@(\*|\.|\:|\@|\{|\})/) {
	    $seen{$&}++;
	    $context{$&} .= "> $_" if $verbose;
	    $_ = "$`XX$'";
	    redo;
	}
	if (/\@(\w+)/) {
	    ($before, $match, $after) = ($`, $&, $');
	    if ($before =~ /\b[\w-]+$/ && $after =~ /^[\w-.]*\b/) { # e-mail address
		$seen{'e-mail address'}++;
		$context{'e-mail address'} .= "> $_" if $verbose;
	    } else {
		$seen{$match}++;
		$context{$match} .= "> $_" if $verbose;
	    }
	    $match =~ s/^\@/X/;
	    $_ = "$before$match$after";
	    redo;
	}
    }
    
    foreach (sort(keys(%seen))) {
	if ($verbose) {
	    print "$_\n";
	    print $context{$_};
	} else {
	    print "$_ ($seen{$_})\n";
	}
    }
}

sub open {
    local($name) = @_;

    ++$fh_name;
    if (open($fh_name, $name)) {
	unshift(@fhs, $fh_name);
    } else {
	warn "$ERROR Can't read file $name: $!\n";
    }
}

sub init_input {
    @fhs = ();			# hold the file handles to read
    @input_spool = ();		# spooled lines to read
    $fh_name = 'FH000';
    &open($docu);
}

sub next_line {
    local($fh, $line);

    if (@input_spool) {
	$line = shift(@input_spool);
	return($line);
    }
    while (@fhs) {
	$fh = $fhs[0];
	$line = <$fh>;
	return($line) if $line;
	close($fh);
	shift(@fhs);
    }
    return(undef);
}

# used in pass 1, use &next_line
sub skip_until {
    local($tag) = @_;
    local($_);

    while ($_ = &next_line) {
	return if /^\@end\s+$tag\s*$/;
    }
    die "* Failed to find '$tag' after: " . $lines[$#lines];
}

#
# HTML stacking to have a better HTML output
#

sub html_reset {
    @html_stack = ('html');
    $html_element = 'body';
}

sub html_push {
    local($what) = @_;
    push(@html_stack, $html_element);
    $html_element = $what;
}

sub html_push_if {
    local($what) = @_;
    push(@html_stack, $html_element)
	if ($html_element && $html_element ne 'P');
    $html_element = $what;
}

sub html_pop {
    $html_element = pop(@html_stack);
}

sub html_pop_if {
    local($elt);

    if (@_) {
	foreach $elt (@_) {
	    if ($elt eq $html_element) {
		$html_element = pop(@html_stack) if @html_stack;
		last;
	    }
	}
    } else {
	$html_element = pop(@html_stack) if @html_stack;
    }
}

sub html_debug {
    local($what, $line) = @_;
    return("<!-- $line @html_stack, $html_element -->$what")
	if $debug & $DEBUG_HTML;
    return($what);
}

# to debug the output...
sub debug {
    local($what, $line) = @_;
    return("<!-- $line -->$what")
	if $debug & $DEBUG_HTML;
    return($what);
}

sub normalise_node {
    $_[0] =~ s/\s+/ /g;
    $_[0] =~ s/ $//;
    $_[0] =~ s/^ //;
}

sub menu_entry {
    local($entry, $node, $descr) = @_;
    local($href);

    &normalise_node($node);
    $href = $node2href{$node};
    if ($href) {
	$descr =~ s/^\s+//;
	$descr = ": $descr" if $descr;
	push(@lines2, "<LI>" . &anchor('', $href, $entry) . "$descr\n");
    } else {
	warn "$ERROR Undefined node ($node): $_";
    }
}

sub do_ctrl { "^$_[0]" }

sub do_email {
    local($addr, $text) = split(/,\s*/, $_[0]);

    $text = $addr unless $text;
    &anchor('', "mailto:$addr", $text);
}

sub do_sc { "\U$_[0]\E" }

sub do_uref {
    local($url, $text) = split(/,\s*/, $_[0]);

    $text = $url unless $text;
    &anchor('', $url, $text);
}

sub do_url { &anchor('', $_[0], $_[0]) }

sub apply_style {
    local($texi_style, $text) = @_;
    local($style);

    $style = $style_map{$texi_style};
    if (defined($style)) { # known style
	if ($style =~ /^\"/) { # add quotes
	    $style = $';
	    $text = "\`$text\'";
	}
	if ($style =~ /^\&/) { # custom
	    $style = $';
	    $text = &$style($text);
	} elsif ($style) { # good style
	    $text = "<$style>$text</$style>";
	} else { # no style
	}
    } else { # unknown style
	$text = undef;
    }
    return($text);
}

# remove Texinfo styles
sub remove_style {
    local($_) = @_;
    s/\@\w+{([^\{\}]+)}/$1/g;
    return($_);
}

sub substitute_style {
    local($_) = @_;
    local($changed, $done, $style, $text);

    $changed = 1;
    while ($changed) {
	$changed = 0;
	$done = '';
	while (/\@(\w+){([^\{\}]+)}/) {
	    $text = &apply_style($1, $2);
	    if ($text) {
		$_ = "$`$text$'";
		$changed = 1;
	    } else {
		$done .= "$`\@$1";
		$_ = "{$2}$'";
	    }
	}
        $_ = $done . $_;
    }
    return($_);
}

sub anchor {
    local($name, $href, $text, $newline) = @_;
    local($result);

    $result = "<A";
    $result .= " NAME=\"$name\"" if $name;
    $result .= " HREF=\"$href\"" if $href;
    $result .= ">$text</A>";
    $result .= "\n" if $newline;
    return($result);
}

sub pretty_date {
    local(@MoY, $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst);

    @MoY = ('January', 'February', 'March', 'April', 'May', 'June',
	    'July', 'August', 'September', 'October', 'November', 'December');
    ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
    $year += ($year < 70) ? 2000 : 1900;
    return("$mday $MoY[$mon] $year");
}

sub doc_name {
    local($num) = @_;

    return("${docu_name}_$num.html");
}

sub next_doc {
    $docu_doc = &doc_name(++$doc_num);
}

sub print {
    local(*lines, $fh) = @_;
    local($_);

    while (@lines) {
	$_ = shift(@lines);
	if (/^$PROTECTTAG/o) {
	    $_ = $tag2pro{$_};
	} else {
	    &unprotect_texi;
	}
	print $fh $_;
    }
}

sub print_ruler {
    print FILE "<P><HR><P>\n";
}

sub print_header {
    local($_);

    # clean the title
    $_ = &remove_style($_[0]);
    &unprotect_texi;
    # print the header
    if ($doctype eq 'html2') {
	print FILE $html2_doctype;
    } elsif ($doctype) {
	print FILE $doctype;
    }
    print FILE <<EOT;
<HTML>
<HEAD>
$header
<TITLE>$_</TITLE>
</HEAD>
<BODY>
EOT
}

sub print_toplevel_header {
    local($_);

    &print_header; # pass given arg...
    print FILE $full_title;
    if ($value{'_subtitle'}) {
	$value{'_subtitle'} =~ s/\n+$//;
	foreach (split(/\n/, $value{'_subtitle'})) {
	    $_ = &substitute_style($_);
	    &unprotect_texi;
	    print FILE "<H2>$_</H2>\n";
	}
    }
    if ($value{'_author'}) {
	$value{'_author'} =~ s/\n+$//;
	foreach (split(/\n/, $value{'_author'})) {
	    $_ = &substitute_style($_);
	    &unprotect_texi;
	    s/[\w.-]+\@[\w.-]+/<A HREF="mailto:$&">$&<\/A>/g;
	    print FILE "<ADDRESS>$_</ADDRESS>\n";
	}
    }
    print FILE "<P>\n";
}

sub print_footer {
    print FILE <<EOT;
</BODY>
</HTML>
EOT
}

sub print_toplevel_footer {
    &print_ruler;
    print FILE <<EOT;
This document was generated on $TODAY using
<A HREF=\"$HOMEPAGE\">texi2html</A>&nbsp;$value{texi2html}.
EOT
    &print_footer;
}

sub protect_texi {
    # protect @ { } ` '
    s/\@\@/$;0/go;
    s/\@\{/$;1/go;
    s/\@\}/$;2/go;
    s/\@\`/$;3/go;
    s/\@\'/$;4/go;
}

sub protect_html {
    local($what) = @_;
    # protect & < >
    $what =~ s/\&/\&\#38;/g;
    $what =~ s/\</\&\#60;/g;
    $what =~ s/\>/\&\#62;/g;
    # but recognize some HTML things
    $what =~ s/\&\#60;\/A\&\#62;/<\/A>/g;	      # </A>
    $what =~ s/\&\#60;A ([^\&]+)\&\#62;/<A $1>/g;     # <A [^&]+>
    $what =~ s/\&\#60;IMG ([^\&]+)\&\#62;/<IMG $1>/g; # <IMG [^&]+>
    return($what);
}

sub unprotect_texi {
    s/$;0/\@/go;
    s/$;1/\{/go;
    s/$;2/\}/go;
    s/$;3/\`/go;
    s/$;4/\'/go;
}

sub unprotect_html {
    local($what) = @_;
    $what =~ s/\&\#38;/\&/g;
    $what =~ s/\&\#60;/\</g;
    $what =~ s/\&\#62;/\>/g;
    return($what);
}

sub byalpha {
    $key2alpha{$a} cmp $key2alpha{$b};
}

##############################################################################

	# These next few lines are legal in both Perl and nroff.

.00 ;			# finish .ig
 
'di			\" finish diversion--previous line must be blank
.nr nl 0-1		\" fake up transition to first page again
.nr % 0			\" start at page 1
'; __END__ ############# From here on it's a standard manual page ############
.TH TEXI2HTML 1 "01/05/98"
.AT 3
.SH NAME
texi2html \- a Texinfo to HTML converter
.SH SYNOPSIS
.B texi2html [options] file
.PP
.B texi2html -check [-verbose] files
.SH DESCRIPTION
.I Texi2html
converts the given Texinfo file to a set of HTML files. It tries to handle
most of the Texinfo commands. It creates hypertext links for cross-references,
footnotes...
.PP
It also tries to add links from a reference to its corresponding entry in the
bibliography (if any). It may also handle a glossary (see the
.B \-glossary
option).
.PP
.I Texi2html
creates several files depending on the contents of the Texinfo file and on
the chosen options (see FILES).
.PP
The HTML files created by
.I texi2html
are closer to TeX than to Info, that's why
.I texi2html
converts @iftex sections and not @ifinfo ones by default. You can reverse
this with the \-expandinfo option.
.SH OPTIONS
.TP 12
.B \-check
Check the given file and give the list of all things that may be Texinfo commands.
This may be used to check the output of
.I texi2html
to find the Texinfo commands that have been left in the HTML file.
.TP
.B \-expandinfo
Expand @ifinfo sections, not @iftex ones.
.TP
.B \-glossary
Use the section named 'Glossary' to build a list of terms and put links in the HTML
document from each term toward its definition.
.TP
.B \-invisible \fIname\fP
Use \fIname\fP to create invisible destination anchors for index links
(you can for instance use the invisible.xbm file shipped with this program).
This is a workaround for a known bug of many WWW browsers, including netscape.
.TP
.B \-I \fIdir\fP
Look also in \fIdir\fP to find included files.
.TP
.B \-menu
Show the Texinfo menus; by default they are ignored.
.TP
.B \-monolithic
Output only one file, including the table of contents and footnotes.
.TP
.B \-number
Number the sections.
.TP
.B \-split_chapter
Split the output into several HTML files (one per main section:
chapter, appendix...).
.TP
.B \-split_node
Split the output into several HTML files (one per node).
.TP
.B \-usage
Print usage instructions, listing the current available command-line options.
.TP
.B \-verbose
Give a verbose output. Can be used with the
.B \-check
option.
.PP
.SH FILES
By default
.I texi2html
creates the following files (foo being the name of the Texinfo file):
.TP 16
.B foo_toc.html
The table of contents.
.TP
.B foo.html
The document's contents.
.TP
.B foo_foot.html
The footnotes (if any).
.PP
When used with the
.B \-split
option, it creates several files (one per chapter or node), named
.B foo_n.html
(n being the indice of the chapter or node), instead of the single
.B foo.html
file.
.PP
When used with the
.B \-monolithic
option, it creates only one file:
.B foo.html
.SH VARIABLES
.I texi2html
predefines the following variables: \fBhtml\fP, \fBtexi2html\fP.
.SH ADDITIONAL COMMANDS
.I texi2html
implements the following non-Texinfo commands (maybe they are in Texinfo now...):
.TP 16
.B @ifhtml
This indicates the start of an HTML section, this section will passed through
without any modification.
.TP
.B @end ifhtml
This indicates the end of an HTML section.
.SH VERSION
This is \fItexi2html\fP version 1.56k, 1999-02-20.
.PP
The latest version of \fItexi2html\fP can be found in WWW, cf. URLs
http://wwwinfo.cern.ch/dis/texi2html/
.br
http://texinfo.org/texi2html/
.SH AUTHOR
The main author is Lionel Cons, CERN IT/DIS/OSE, Lionel.Cons@cern.ch.
Many other people around the net contributed to this program.
.SH COPYRIGHT
This program is the intellectual property of the European
Laboratory for Particle Physics (known as CERN). No guarantee whatsoever is
provided by CERN. No liability whatsoever is accepted for any loss or damage
of any kind resulting from any defect or inaccuracy in this information or
code.
.PP
CERN, 1211 Geneva 23, Switzerland
.SH "SEE ALSO"
GNU Texinfo Documentation Format,
HyperText Markup Language (HTML),
World Wide Web (WWW).
.SH BUGS
This program does not understand all Texinfo commands (yet).
.PP
TeX specific commands (normally enclosed in @iftex) will be
passed unmodified.
.ex
