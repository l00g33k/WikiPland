use strict;
use warnings;
use l00wikihtml;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_srcdoc_proc",
              desc => "l00http_srcdoc_desc");
my ($editwd, $editht, $editsz, $root, $filter);
my ($hostpath, $contextln, $blklineno, $level, @secnos, $noheading, $devmode);
my (%writeentirefile, %entirefileorgname, %writeentirefilehighlight, $width, $lastinsert);
$hostpath = "c:\\x\\";
$editsz = 0;
$editwd = 320;
$editht = 7;
$contextln = 0;
$blklineno = 0;
$root = '';
$filter = '\.c$|||\.cpp$|||\.h$';
$level = 3;
$width = 40;
$lastinsert = 0;
$noheading = '';
$devmode = '';

my (@reccuLvlColor);
@reccuLvlColor = (
"green",
"red",
"blue",
"magenta",
"limegreen",
"teal",
"orange",
"purple",
"maroon",
"blue",
"blue",
"blue",
"blue",
"blue",
"blue",
"blue",
"blue",
"blue",
"blue",
"blue"
);


my ($localpath, @altpath);

sub l00http_srcdoc_localfname {
    my ($ctrl, $localfname) = @_;
    my ($onealtpath, $lpath, $lfname);

    if (($lpath, $lfname) = $localfname =~ /^(.+?)([^\\\/]+)$/) {
        l00httpd::dbp($config{'desc'}, "ALTPATH: localfname (\$#altpath $#altpath + 1): $lpath - $lfname\n"), if ($ctrl->{'debug'} >= 1);
        if ((! -d "$lpath") && (-d $localpath) && ($#altpath >= 0)) {
            l00httpd::dbp($config{'desc'}, "ALTPATH: substituding:\n"), if ($ctrl->{'debug'} >= 1);
            foreach $onealtpath (@altpath) {
                l00httpd::dbp($config{'desc'}, "ALTPATH: candidate: $onealtpath\n"), if ($ctrl->{'debug'} >= 1);
                if ($lpath =~ /^$onealtpath/) {
                    l00httpd::dbp($config{'desc'}, "ALTPATH: localfname was: $lpath$lfname\n"), if ($ctrl->{'debug'} >= 1);
                    $lpath =~ s/^$onealtpath/$localpath/;
                    l00httpd::dbp($config{'desc'}, "ALTPATH: localfname  is: $localfname\n"), if ($ctrl->{'debug'} >= 1);
                    $localfname = "$lpath$lfname";
                    last;
                }
            }
        } else {
            l00httpd::dbp($config{'desc'}, "ALTPATH: no substitution: exist: $lpath\n"), if ($ctrl->{'debug'} >= 1);
        }

    }

    $localfname;
}

sub l00http_srcdoc_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "srcdoc: source documentation helper";
}


sub l00http_srcdoc_secno {
    my ($level) = @_;
    my ($ii, $retval);

    $retval = '0';

    if ($level < -1) {
        @secnos = ();
        $secnos[0] = 0;
    } elsif ($level < 0) {
        $retval = join('.', @secnos);
    } else {
        for ($ii = 0; $ii < $level; $ii++) {
            if (!defined($secnos[$ii])) {
                $secnos[$ii] = 1;
            }
        }
        if (!defined($secnos[$level])) {
            $secnos[$level] = 1;
        } else {
            $secnos[$level]++;
        }
        $#secnos = $level;
        $retval = join('.', @secnos);
    }

    $retval;
}

sub l00http_srcdoc_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my (@alllines, $line, $lineno, $blkbuf, $tgtline, $tgtln, $cnt, $jj);
    my ($pname, $fname, $comment, $buffer, @buf, $tmp, $tmp2, $lnno, $uri, $ii, $cmd, $lasthdrlvl);
    my ($gethdr, $html, $html2, $title, $body, $level, $tgtfile, $tgttext, $tgttextcln);
    my ($tlevel, $prjbase, $prjname, $cpfrompath, $cpfromname, $tlnnohi, $tlnnost, $tlnnoen, $srcln, $copyname, $copyidx);
    my ($loop, $st, $hi, $en, $fileno, $orgln, $secno, %secnohash, $inpre, $localfname, $htmlfname);
    my ($efname, $entirecnt, $entirefname, @callstack, $stack, $lastlvl);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} - ";
    print $sock "<a href=\"#end\">Jump to end</a>\n";
	print $sock "<a href=\"#__toc__\">toc</a>\n";

    if (defined ($form->{'path'})) {
        $form->{'path'} =~ s/\r//g;
        $form->{'path'} =~ s/\n//g;
        ($prjbase, $prjname) = $form->{'path'} =~ /^(.+?)([^\\\/]+)$/;
        print $sock " <a href=\"/clip.htm?update=Copy+to+clipboard&clip=$prjbase\">Path:</a> ";
        print $sock "<a href=\"/ls.htm?path=$prjbase\">$prjbase</a>";
        print $sock "<a href=\"/view.htm?path=$prjbase$prjname\">$prjname</a>\n";
    }
    print $sock "<br>\n";

    if (defined ($form->{'targetupdate'}) && 
        defined ($form->{'targetname'}) && (length($form->{'targetname'}) > 3) &&
        defined ($form->{'targetlnnoold'}) && $form->{'targetlnnoold'} =~ /^\d+$/ &&
        defined ($form->{'targetlnnonew'}) && $form->{'targetlnnonew'} =~ /^\d+$/) {
        $buffer = '';
        if (open(IN, "<$prjbase$prjname")) {
            $cnt = 0;
            while (<IN>) {
                $cnt++;
                if (($st, $en) = /^$form->{'targetname'}::(\d+)::$form->{'targetlnnoold'}::(\d+)$/) {
                    print $sock "LINE $cnt WAS: $_<br>\n";
                    $st = $1 + ($form->{'targetlnnonew'} - $form->{'targetlnnoold'});
                    $en = $2 + ($form->{'targetlnnonew'} - $form->{'targetlnnoold'});
                    $_ = "$form->{'targetname'}::$st::$form->{'targetlnnonew'}::$en\n";
                    print $sock "LINE $cnt  IS: $_<br>\n";
                }
                $buffer .= $_;
            }
            close(IN);
            if (open(OU, ">$prjbase$prjname")) {
                print OU $buffer;
                close(OU);
            }
        }
    }

    # insert notes
    if (defined ($form->{'Save'}) && defined ($form->{'insertlnno'})) {
        $lastinsert = $form->{'insertlnno'} + 1;
        l00httpd::dbp($config{'desc'}, "Inserted lastinsert = $lastinsert\n"), if ($ctrl->{'debug'} >= 4);
        $title = '';
        if (defined ($form->{'title'})) {
            $title = $form->{'title'};
        }
        $body = '';
        if (defined ($form->{'body'})) {
            $body = $form->{'body'};
        }
        $level = 1;
        if (defined ($form->{'level'})) {
            $level = $form->{'level'};
        }
        $tgtfile = '(unknown)';
		if (&l00httpd::l00freadOpen($ctrl, "l00://~find_hilite.txt")) {
			if ($_ = &l00httpd::l00freadLine($ctrl)) {
				$tgtfile = "$_\n";
			}
			if ($_ = &l00httpd::l00freadLine($ctrl)) {
				$tgtfile .= "    $_";
			}
		}

        if (open (IN, "<$form->{'path'}")) {
            l00httpd::dbp($config{'desc'}, "READ: $form->{'path'}\n"), if ($ctrl->{'debug'} >= 1);
            $lnno = 0;
            $buffer = '';
            for ($ii = 0; $ii < $form->{'insertlnno'}; $ii++) {
                $buffer .= <IN>;
            }
            if (defined ($form->{'pair'})) {
                # add a pair
                $buffer .= '=' x ($level + 1) . "Calling: $title" . '=' x ($level + 1) . "\n";
                $buffer .= "$tgtfile\n";
                $buffer .= "$body\n";
                $buffer .= '=' x ($level + 1) . "Returning: $title" . '=' x ($level + 1) . "\n";
                $buffer .= "$tgtfile\n";
                $buffer .= "$body\n";
            } else {
                $buffer .= '=' x ($level + 1) . $title . '=' x ($level + 1) . "\n";
                $buffer .= "$tgtfile\n";
                $buffer .= "$body\n";
            }
            while (<IN>) {
                $buffer .= $_;
            }
            close (IN);
            if (open (OU, ">$form->{'path'}")) {
                print OU $buffer;
                close (OU);
            }
            # clear flag
            undef $form->{'insertlnno'};
        } else {
            l00httpd::dbp($config{'desc'}, "FAILED(".__LINE__.") to open: $form->{'path'}\n"), if ($ctrl->{'debug'} >= 1);
        }
    }


    $buffer = '';
    @buf = ();
    if (open (IN, "<$form->{'path'}")) {
        l00httpd::dbp($config{'desc'}, "READ: $form->{'path'}\n"), if ($ctrl->{'debug'} >= 1);
        $lnno = 0;
        $root = '';
        $lasthdrlvl = 1;
        $fileno = 0;
        l00httpd::dbp($config{'desc'}, "To insert lastinsert = $lastinsert\n"), if ($ctrl->{'debug'} >= 4);
        while (<IN>) {
            if (/^(=+)/) {
                $buffer .= "\n__SRCDOC__$lnno\n";
                $fileno = $lnno + 2;
            }
            $lnno++;
            if (($fileno == $lnno) &&
                # /sdcard/g/myram/x/Perl/srcdoc/template/go.bat::0::9::99999::
                (($cpfrompath, $cpfromname, $st, $hi, $en) = /^(.+?)([^\\\/]+?)::(\d+)::(\d+)::(.+)$/)) {
                $buffer .= "<a href=\"/ls.htm?path=$cpfrompath\">$cpfrompath</a>".
                           "<a href=\"/view.htm?path=$cpfrompath$cpfromname&hiliteln=$hi&lineno=on#line$hi\">$cpfromname</a>".
                           "::${st}::${hi}::${en}\n";
            } else {
                if ($lnno == $lastinsert) {
                    l00httpd::dbp($config{'desc'}, "Insert lastinsert = $lastinsert\n"), if ($ctrl->{'debug'} >= 4);
                    $buffer .= "<a name=\"lastinsert\"></a>\n";
                }
                $buffer .= $_;
            }
            if (($tmp) = /^%ALTPATH:(.+)%[\r\n]*$/) {
                if (-d "$tmp") {
                    $localpath = $tmp;
                    l00httpd::dbp($config{'desc'}, "altpath: localpath  : $localpath\n"), if ($ctrl->{'debug'} >= 1);
                } else {
                    push(@altpath, $tmp);
                    l00httpd::dbp($config{'desc'}, "altpath: alt-path($#altpath): $tmp\n"), if ($ctrl->{'debug'} >= 1);
                }
            }
            push(@buf, $_);
        }
        $buffer .= "\n__SRCDOC__${lnno}_end\n";
        close (IN);
    } else {
        l00httpd::dbp($config{'desc'}, "FAILED(".__LINE__.") to open: $form->{'path'}\n"), if ($ctrl->{'debug'} >= 1);
    }
    ($pname, $fname) = $form->{'path'} =~ /^(.+\/)([^\/]+)$/;


    if (defined ($form->{'refresh'})) {
        if (defined ($form->{'width'}) && $form->{'width'} =~ /(\d+)/) {
            $width = $1;
        }
    }

    if (defined ($form->{'generate'})) {
        if (defined ($form->{'width'}) && $form->{'width'} =~ /(\d+)/) {
            $width = $1;
        }
        if (defined ($form->{'noheading'}) && ($form->{'noheading'} eq 'on')) {
            $noheading = 'checked';
        } else {
            $noheading = '';
        }
        if (defined ($form->{'devmode'}) && ($form->{'devmode'} eq 'on')) {
            $devmode = 'checked';
        } else {
            $devmode = '';
        }
        $html = '';
        $html .= <<end_of_print1
<html>
<head>
<title>$pname${fname}</title>
</head>
<frameset cols="${width}%,*">
end_of_print1
;
        $html .= "    <frame name=\"nav\" src=\"${fname}_nav0.html\">";
        $html .= <<end_of_print2
<frame name="content">
</frameset>
<body bgcolor="#FFFFFF">
</body>
</html>
end_of_print2
;

        $localfname = "$pname${fname}_index.html";
        l00httpd::dbp($config{'desc'}, "Write index.html: $localfname\n"), if ($ctrl->{'debug'} >= 1);
        if (open(OU, ">$localfname")) {
            l00httpd::dbp($config{'desc'}, "WRITE: $localfname\n"), if ($ctrl->{'debug'} >= 1);
            print OU $html;
            close(OU);
        } else {
            l00httpd::dbp($config{'desc'}, "FAILED(".__LINE__.") to open: $localfname\n"), if ($ctrl->{'debug'} >= 1);
        }


        l00httpd::dbp($config{'desc'}, "generate outputs ${fname}_index.html in $pname\n"), if ($ctrl->{'debug'} >= 4);
        $html = '';

        undef %writeentirefile;
        undef %entirefileorgname;
        undef %writeentirefilehighlight;
        undef @callstack;
        $entirecnt = 0;
        &l00http_srcdoc_secno(-2);
        undef %secnohash;
        $cpfrompath = '';
        $cpfromname = '';
        $loop = 1;
        $ii = 0;
        $copyidx = 0;
        $orgln = '(not available)';
        $lastlvl = -1;
        l00httpd::dbp($config{'desc'}, "-- scan for srcdoc headers with target line numbers and insert SRCDOC tags\n"), if ($ctrl->{'debug'} >= 4);
        while ($loop) {
            $srcln = $ii + 1;
            if (($cpfrompath ne '') && (($ii > $#buf) || ($buf[$ii] =~ /^=+/))) {
                $localfname = &l00http_srcdoc_localfname($ctrl, "$cpfrompath");
                $copyidx++;
                l00httpd::dbp($config{'desc'}, "INSERT target level $tlevel line ${tlnnost}::${tlnnohi}::$tlnnoen in file $localfname\n"), if ($ctrl->{'debug'} >= 4);
                $html .= "\nSRCDOC::${srcln}::${tlevel}::${cpfrompath}::${tlnnost}::${tlnnohi}::${tlnnoen}::$orgln\n";
                l00httpd::dbp($config{'desc'}, "inSRCDOC::$copyidx:${srcln}::${tlevel}::${cpfrompath}::${tlnnost}::${tlnnohi}::${tlnnoen}::$orgln"), if ($ctrl->{'debug'} >= 4);
                $secnohash{$srcln} = $secno;
                ($cpfromname) = $localfname =~ /([^\\\/]+)$/;
                $copyname = "${fname}_${copyidx}_$cpfromname.html";
                if (!defined($writeentirefile{$localfname})) {
                    $entirecnt++;
                    $writeentirefile{$localfname} = $entirecnt;
                    $entirefileorgname{$localfname} = $cpfrompath;
                }
                l00httpd::dbp($config{'desc'}, "CODE:$copyname -- ${cpfrompath}\n"), if ($ctrl->{'debug'} >= 4);
                if ($tlevel > $lastlvl) {
                    $lastlvl = $tlevel;
                    push (@callstack, $orgln);
                } elsif ($tlevel < $lastlvl) {
                    $lastlvl = $tlevel;
                    pop (@callstack);
                }
                $html .= "<pre>\n";
                for ($jj = 0; $jj <= $#callstack; $jj++) {
                    $tmp = $jj + 1;
                    $html .= "<font color=\"". $reccuLvlColor [$jj] ."\">$tmp: $callstack[$jj]</font>";
                }
                $html .= "   $orgln";
                $html .= "</pre>\n";
                $cpfromname =~ s/^([A-Z]+[a-z0-9])/!$1/;
                $html .= "<a href=\"$copyname\" target=\"content\">[show code]</a> - <font color=\"". $reccuLvlColor [$tlevel] ."\">$cpfromname</font>\n";
                $cpfrompath = '';
                $orgln = '(not available)';
            }
            if ($ii <= $#buf) {
                if (($tmp, $tmp2) = $buf[$ii] =~ /^(=+)(.+)$/) {
                    $tlevel = length($tmp) - 1;
                    l00httpd::dbp($config{'desc'}, "newsec? line $ii ^= x $tlevel\n"), if ($ctrl->{'debug'} >= 4);
                    if (($cpfrompath, $tlnnost, $tlnnohi, $tlnnoen) = $buf[$ii + 1] =~ /^(.+?)::(\d+)::(\d+)::(\d+)/) {
                        $localfname = &l00http_srcdoc_localfname($ctrl, "$cpfrompath");
                        if (!-f $localfname) {
                            l00httpd::dbp($config{'desc'}, "target file not found: $localfname ($cpfrompath)\n"), if ($ctrl->{'debug'} >= 4);
                            $cpfrompath = '';
                            $html .= $buf[$ii];
                        } else {
                            if ($noheading ne 'checked') {
                                $tlevel = length($tmp) - 1;
                                $secno = &l00http_srcdoc_secno($tlevel);
                                $html .= "\n<a name=\"sec_$secno\"></a>\n";
                                $html .= "$tmp$secno $tmp2\n";
                            }
                            l00httpd::dbp($config{'desc'}, "NEWSEC! line $ii+1 target level $tlevel line $tlnnost-$tlnnohi-$tlnnoen in file $cpfrompath AKA $localfname\n"), if ($ctrl->{'debug'} >= 4);
                            # skip full file path, name, and offset
                            $ii++;
                            # if file exist, save original line too
                            $orgln = '';
                            if (($ii + 1) <= $#buf) {
                                # skip added 4 leading spaces
                                if ($buf[$ii + 1] =~ /^    ./) {
                                    $orgln = substr($buf[$ii + 1], 4, 2000);
                                }
                            }
                            if (!defined($orgln) || ($orgln eq '')) {
                                if (($ii + 2) <= $#buf) {
                                    # skip added 4 leading spaces
                                    if ($buf[$ii + 2] =~ /^    ./) {
                                        $orgln = substr($buf[$ii + 2], 4, 2000);
                                    }
                                }
                                if (!defined($orgln) || ($orgln eq '')) {
                                    $orgln = '(not available)';
                                } else {
                                    if ($noheading eq 'checked') {
                                        $ii += 2;
                                    }
                                }
                            } else {
                                if ($noheading eq 'checked') {
                                    $ii += 1;
                                }
                            }
                        }
                    } else {
                        $cpfrompath = '';
                        $html .= $buf[$ii];
                    }
                } else {
                    $html .= $buf[$ii];
                }
                $ii++;
            } else {
                $loop = 0;
            }
        }

        &l00httpd::l00fwriteOpen($ctrl, "l00://~srcdoc_html.txt");
        &l00httpd::l00fwriteBuf($ctrl, $html);
        &l00httpd::l00fwriteClose($ctrl);

        $html = &l00wikihtml::wikihtml ($ctrl, $pname, $html, 0, $fname);
        $html = <<end_of_print3
<html>
<head>
<title>$pname${fname}</title>
</head>
<body bgcolor="#FFFFFF">
<a  href="#__toc__">TOC</a><br>
$html
end_of_print3
;
        $html .= "</body>\n</html>\n";

        &l00httpd::l00fwriteOpen($ctrl, "l00://~srcdoc_nav_html.txt");
        &l00httpd::l00fwriteBuf($ctrl, $html);
        &l00httpd::l00fwriteClose($ctrl);

        # insert
        $html2 = '';
        $copyidx = 0;
        $srcln = 0;
        $inpre = 0;
        l00httpd::dbp($config{'desc'}, "-- scan for SRCDOC tags and generate target html\n"), if ($ctrl->{'debug'} >= 4);
        foreach $line (split("\n", $html)) {
            # SRCDOC::123::1::/sdcard/g/myram/x/Perl/srcdoc/template/go.bat::0::10::99999::orgln
            if ($line =~ /^SRCDOC::/ && 
                (($srcln, $level, $cpfrompath, $st, $hi, $en, $orgln) = 
                $line =~ /^SRCDOC::(\d+)::(\d+)::(.+?)::(\d+)::(\d+)::(\d+)::(.+)$/)) {
                $copyidx++;
                l00httpd::dbp($config{'desc'}, "SRCDOC:$copyidx($srcln, $level, $cpfrompath, $st, $hi, $en, $orgln)\n"), if ($ctrl->{'debug'} >= 4);
                $localfname = &l00http_srcdoc_localfname($ctrl, "$cpfrompath");
                $writeentirefilehighlight{$localfname} .= ":$hi,$level:";
                l00httpd::dbp($config{'desc'}, "SRCDOC:writeentirefilehighlight{$cpfrompath} = $writeentirefilehighlight{$cpfrompath}\n"), if ($ctrl->{'debug'} >= 4);
                ($cpfromname) = $localfname =~ /([^\\\/]+)$/;
                $cpfrompath =~ s/[^\\\/]+$//;

                $copyname = "${fname}_${copyidx}_$cpfromname.html";
                $localfname = "$pname$copyname";
                l00httpd::dbp($config{'desc'}, "Write COPYDEST: $localfname\n"), if ($ctrl->{'debug'} >= 1);
                if (open(COPYDEST, ">$localfname")) {
                    l00httpd::dbp($config{'desc'}, "WRITE: $localfname\n"), if ($ctrl->{'debug'} >= 1);
                    print COPYDEST "<html>\n<head>\n";
                    print COPYDEST "<title>$fname</title>\n";
                    print COPYDEST "</head>\n<body bgcolor=\"#FFFFFF\">\n\n";
                   #print COPYDEST "<h3><a href=\"$basename" . "_nav0.htm#$anchorthis\" target=\"nav\"><i>$secnum</i> "."[".$paracurlvl."]$fragcnt2</a> ";
                   #print COPYDEST "<a href=\"$basename" . "_nav1.htm#$anchorthis\" target=\"nav\">short form</a>: $title</h3>\n\n";
                   #print COPYDEST "<p>filename: <a href=\"$fnamepart.htm#_$lineno\">$fname</a>($lineno):<br>\n";
                   #print COPYDEST "original line: <i>$orgln</i></p>\n\n";
                    print COPYDEST "<pre>\n";

                    l00httpd::dbp($config{'desc'}, " - cpfromname = $cpfromname\n"), if ($ctrl->{'debug'} >= 4);
                    l00httpd::dbp($config{'desc'}, " - cpfrompath = $cpfrompath\n"), if ($ctrl->{'debug'} >= 4);
                    l00httpd::dbp($config{'desc'}, " - copyname = $copyname"), if ($ctrl->{'debug'} >= 4);
                    l00httpd::dbp($config{'desc'}, " - level = $level"), if ($ctrl->{'debug'} >= 4);
                    l00httpd::dbp($config{'desc'}, " - st = $st"), if ($ctrl->{'debug'} >= 4);
                    l00httpd::dbp($config{'desc'}, " - hi = $hi"), if ($ctrl->{'debug'} >= 4);
                    l00httpd::dbp($config{'desc'}, " - en = $en\n"), if ($ctrl->{'debug'} >= 4);

                    $tmp = &l00http_srcdoc_localfname($ctrl, "$cpfrompath$cpfromname");
                    l00httpd::dbp($config{'desc'}, "ENTIREFILE: cpfrompath=$cpfrompath$cpfromname - local \$tmp=$tmp\n"), if ($ctrl->{'debug'} >= 1);
                    # ::conti:: possibly buggy: predicting entire file index number may be wrong
                    if (defined($writeentirefile{$tmp})) {
                        $tmp = $writeentirefile{$tmp};
                    } else {
                        $tmp = $entirecnt + 1;
                    }
                    $entirefname = "${pname}${fname}_${cpfromname}_$tmp.html";
                    $entirefname = "${fname}_${cpfromname}_$tmp.html";
                    l00httpd::dbp($config{'desc'}, "ENTIREFILE: entirefname=$entirefname\n"), if ($ctrl->{'debug'} >= 1);
                    $tmp = "$localfname$cpfromname";
                    print COPYDEST "Index   : <a href=\"${fname}_nav0.html#sec_$secnohash{$srcln}\" target=\"nav\"><i>section $secnohash{$srcln}</i></a> ($copyidx:$srcln)\n";
                    $htmlfname = &l00http_srcdoc_localfname($ctrl, "$cpfrompath$cpfromname");
                    l00httpd::dbp($config{'desc'}, "ENTIREFILE: localfname=$localfname\n"), if ($ctrl->{'debug'} >= 1);
                    # ::conti:: possibly buggy: predicting entire file index number may be wrong
                    print COPYDEST "Source  <a href=\"/view.htm?path=$htmlfname\">";
                    print COPYDEST ":</a> <a href=\"$entirefname\">$cpfromname</a> in $localfname at $hi\n";
                    print COPYDEST "Original: $orgln\n";

                    $localfname = &l00http_srcdoc_localfname($ctrl, "$cpfrompath$cpfromname");
                    l00httpd::dbp($config{'desc'}, "Read COPYSRC: $localfname\n"), if ($ctrl->{'debug'} >= 1);
                    if (open (COPYSRC, "<$localfname")) {
                        l00httpd::dbp($config{'desc'}, "READ: $localfname\n"), if ($ctrl->{'debug'} >= 1);
                        $lnno = 1;
                        while (<COPYSRC>) {
                            if (($lnno >= $st) && ($lnno <= $en)) {
                                if ($hi == $lnno) {
                                    print COPYDEST "<font color=\"". $reccuLvlColor [$level] ."\">";
                                    print COPYDEST "Call level $level\n";
                                }
                                if ($devmode eq '') {
                                    print COPYDEST sprintf ("%4d: ", $lnno);
                                } else {
                                    print COPYDEST sprintf ("<a href=\"/srcdoc.htm?targetupdate=yes&path=$prjbase$prjname&targetlnnoold=%d&targetlnnonew=%d&targetname=$localfname\">%4d</a>: ", $hi, $lnno, $lnno);
                                }
                                s/</&lt;/g;
                                s/>/&gt;/g;
                                print COPYDEST;
                                if ($hi == $lnno) {
                                    print COPYDEST "</font>";
                                }
                            }
                            $lnno++;
                        }
                        close (COPYSRC);
                    } else {
                        l00httpd::dbp($config{'desc'}, "FAILED(".__LINE__.") to open: $localfname\n"), if ($ctrl->{'debug'} >= 1);
                    }


                    print COPYDEST "</pre></body></html>\n";
                    close(COPYDEST);
                    # zap the SRCDOC:: line
                    $line ='';
                } else {
                    l00httpd::dbp($config{'desc'}, "FAILED(".__LINE__.") to open: $localfname\n"), if ($ctrl->{'debug'} >= 1);
                }
            } elsif ($line =~ /^SRCDOC::/) {
                l00httpd::dbp($config{'desc'}, "ERROR:SRCDOC:$_\n"), if ($ctrl->{'debug'} >= 4);
            }
            # <a name="2_1_1__with_no_navigation"></a><h3>2.1.1. with no navigation <a href="#___top___">^</a> <a href="#__toc__">toc</a><a href="#toc_2_1_1__with_no_navigation">@</a> <a href="/blog.htm?path=/sdcard/g/myram/x/Perl/srcdoc/template/(undef)&afterline=">lg</a> <a href="/edit.htm?path=/sdcard/g/myram/x/Perl/srcdoc/template/(undef)&editline=on&blklineno=">ed</a> <a href="/view.htm?path=/sdcard/g/myram/x/Perl/srcdoc/template/(undef)&update=Skip&skip=&maxln=200"></a></h3><a name="2_1_1__with_no_navigation_"></a>
            # <a name="2_1_1__with_no_navigation"></a>
            # <h3>2.1.1. with no navigation 
            # <a href="#___top___">^</a> <a href="#__toc__">toc</a>
            # <a href="#toc_2_1_1__with_no_navigation">@</a> 
            # <a href="/blog.htm?path=/sdcard/g/myram/x/Perl/srcdoc/template/(undef)&afterline=">lg</a> 
            # <a href="/edit.htm?path=/sdcard/g/myram/x/Perl/srcdoc/template/(undef)&editline=on&blklineno=">ed</a> 
            # <a href="/view.htm?path=/sdcard/g/myram/x/Perl/srcdoc/template/(undef)&update=Skip&skip=&maxln=200"></a>
            # </h3><a name="2_1_1__with_no_navigation_"></a>
            if (($tmp) = $line =~ /<h(\d+)>.*blog.htm.*edit.htm.*view.htm.*<\/h\d+>/) {
                $line =~ s/<a href="#toc_.+?<\/a>//;
                $line =~ s/<a href="\/blog.htm.+?<\/a>//;
                $line =~ s/<a href="\/edit.htm.+?<\/a>//;
                if ($srcln > 0) {
                    # level head heading level - 1
                    $line =~ s/<a href="\/view.htm.+?<\/a>/ [$tmp] ($srcln)/;
                    $srcln = 0;
                } else {
                    $line =~ s/<a href="\/view.htm.+?<\/a>//;
                }
            }
            # <a  href="#__toc__">TOC</a><br>
            # extra space to defeat the followings
            $line =~ s/<a href="#___top___.+?<\/a>//;
            $line =~ s/<a href="#__toc__.+?<\/a>//;

            $html2 .= "$line\n";
        }
        $localfname = "$pname${fname}_nav0.html";
        l00httpd::dbp($config{'desc'}, "Write nav0.html: $localfname\n"), if ($ctrl->{'debug'} >= 1);
        if (open(OU, ">$localfname")) {
            l00httpd::dbp($config{'desc'}, "WRITE: $localfname\n"), if ($ctrl->{'debug'} >= 1);
            print OU $html2;
            close(OU);
        } else {
            l00httpd::dbp($config{'desc'}, "FAILED(".__LINE__.") to open: $localfname\n"), if ($ctrl->{'debug'} >= 1);
        }

        
        # print entire file with line number and color
        # ::conti::
        foreach $efname (keys %writeentirefile) {
            $copyname = $efname;
            l00httpd::dbp($config{'desc'}, "ENTIREFILE: writing efname=$efname\n"), if ($ctrl->{'debug'} >= 1);
            $copyname =~ s/^.+[\\\/]([^\\\/]+)$/$1/;
            $copyname = "${pname}${fname}_${copyname}_$writeentirefile{$efname}.html";
            l00httpd::dbp($config{'desc'}, "ENTIREFILE: writeentirefile = $writeentirefile{$efname} - $copyname\n"), if ($ctrl->{'debug'} >= 4);
            if (defined($writeentirefilehighlight{$efname})) {
                l00httpd::dbp($config{'desc'}, "writeentirefilehighlight{$efname} = $writeentirefilehighlight{$efname}\n"), if ($ctrl->{'debug'} >= 4);
            } else {
                l00httpd::dbp($config{'desc'}, "writeentirefilehighlight{$efname} = undef\n"), if ($ctrl->{'debug'} >= 4);
            }
            # ::conti:: possibly buggy: predicting entire file index number may be wrong
            $localfname = "$copyname";
            l00httpd::dbp($config{'desc'}, "ENTIREFILE: open > $localfname\n"), if ($ctrl->{'debug'} >= 1);
            if (open(ENTIREFILE, ">$localfname")) {
                l00httpd::dbp($config{'desc'}, "WRITE: $localfname\n"), if ($ctrl->{'debug'} >= 1);
                print ENTIREFILE "<html>\n<head>\n";
                print ENTIREFILE "<title>$efname</title>\n";
                print ENTIREFILE "</head>\n<body bgcolor=\"#FFFFFF\">\n\n";
                $localfname = &l00http_srcdoc_localfname($ctrl, "$efname");
                l00httpd::dbp($config{'desc'}, "Read COPYSRC: $localfname\n"), if ($ctrl->{'debug'} >= 1);
                if (!open (COPYSRC, "<$localfname")) {
                    l00httpd::dbp($config{'desc'}, "FAILED(".__LINE__.") to read $efname\n"), if ($ctrl->{'debug'} >= 4);
                } else {
                    l00httpd::dbp($config{'desc'}, "READ: $localfname\n"), if ($ctrl->{'debug'} >= 1);
                    $lnno = 1;
                    print ENTIREFILE "<pre>\n";
                    print ENTIREFILE "filename: $entirefileorgname{$efname}\n\n";
                    while (<COPYSRC>) {
                        if (defined($writeentirefilehighlight{$efname}) &&
                            $writeentirefilehighlight{$efname} =~ /:$lnno,(\d+):/) {
                            print ENTIREFILE "<font color=\"$reccuLvlColor[$1]\">";
                            print ENTIREFILE "Call level $1\n";
                        }

                        print ENTIREFILE "<a name=\"#_$lnno\"></a>";
                        print ENTIREFILE sprintf ("%4d: ", $lnno);
                        # use predefined for < and > -- WAL - 2009/09/21 15:30:03 Mon
                        s/</&lt;/g;
                        s/>/&gt;/g;
                        print ENTIREFILE;
                        if (defined($writeentirefilehighlight{$efname}) &&
                            $writeentirefilehighlight{$efname} =~ /:$lnno,(\d+):/) {
                            print ENTIREFILE "</font>";
                        }
                        $lnno++;
                    }
                    print ENTIREFILE "</pre>\n";
                    close (COPYSRC);
                }
                print ENTIREFILE "</body></html>\n";
                close(ENTIREFILE);
            } else {
                l00httpd::dbp($config{'desc'}, "FAILED(".__LINE__.") to open: $localfname\n"), if ($ctrl->{'debug'} >= 1);
            }
        }
    }

    &l00httpd::l00fwriteOpen($ctrl, "l00://~srcdoc_buffer.txt");
    &l00httpd::l00fwriteBuf($ctrl, $buffer);
    &l00httpd::l00fwriteClose($ctrl);

    $html = &l00wikihtml::wikihtml ($ctrl, $pname, $buffer, 2, $fname);

    &l00httpd::l00fwriteOpen($ctrl, "l00://~srcdoc_html2.txt");
    &l00httpd::l00fwriteBuf($ctrl, $html);
    &l00httpd::l00fwriteClose($ctrl);

    $buffer = "<br>\n";
    $buffer .= "<form action=\"/srcdoc.htm\" method=\"get\">\n";
    $buffer .= "<input type=\"submit\" name=\"refresh\" value=\"R&#818;efresh\" accesskey=\"r\">\n";
    $buffer .= "<input type=\"submit\" name=\"generate\" value=\"G&#818;enerate\" accesskey=\"g\">\n";
    $buffer .= "w&#818;idth% <input type=\"text\" size=\"3\" name=\"width\" value=\"$width\" accesskey=\"w\">\n";
    $buffer .= "<input type=\"checkbox\" name=\"noheading\" $noheading accesskey=\"n\"> N&#818;o headings\n";
    $buffer .= "<input type=\"checkbox\" name=\"devmode\" $devmode accesskey=\"d\"> D&#818;ev mode\n";
    $buffer .= "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
    $buffer .= "</form><br>\n";
    $buffer .= "Output on port: \n";
    $localfname = "$pname${fname}_index.html";
    l00httpd::dbp($config{'desc'}, "Links to index.html: $localfname\n"), if ($ctrl->{'debug'} >= 1);
    $buffer .= "<a href=\"http://localhost:20337$localfname\">20337</a>\n";
    $buffer .= "<a href=\"http://localhost:20347$localfname\">20347</a>\n";
    $buffer .= "<a href=\"http://localhost:30337$localfname\">30337</a>\n";
    $buffer .= "<a href=\"http://localhost:30347$localfname\">30347</a>\n";
    $buffer .= " - <input type=\"text\" accesskey=\"l\" size=\"1\">\n";
    $buffer .= "<a href=\"#lastinsert\"\">L&#818;ast inserted here</a>\n";
    if (defined ($form->{'insertlnno'})) {
        $buffer .= "<br><a href=\"#theform\"\">Jump to the Form</a><br>\n";
    }
    foreach $_ (split("\n", $html)) {
        if (($lineno) = /^__SRCDOC__(\d+)/) {
           #$buffer .= "SRCDOC FORM:$1\n";
            if (defined ($form->{'insertlnno'}) && ($form->{'insertlnno'} eq "$lineno")) {
                if (&l00httpd::l00freadOpen($ctrl, "l00://~find_hilite.txt")) {
                    $tgtfile = &l00httpd::l00freadLine($ctrl);
                    $tgttext = &l00httpd::l00freadLine($ctrl);
                }
               #$buffer .= "INSERT NOTES HERE $form->{'update'}<br>\n";
                $buffer .= "<a name=\"theform\"></a>\n";
                $buffer .= "<form action=\"/srcdoc.htm\" method=\"post\">\n";
                $buffer .= "<input type=\"submit\" name=\"Save\" value=\"S&#818;ave notes here $lineno\" accesskey=\"s\">\n";
                $buffer .= "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
                $buffer .= "<input type=\"hidden\" name=\"insertlnno\" value=\"$lineno\">\n";
                $buffer .= "<input type=\"checkbox\" name=\"pair\" accesskey=\"c\">C&#818;alling/Return From pair\n";
                $buffer .= "Level: ";
                $buffer .= "<input type=\"radio\" name=\"level\" value=\"0\" accesskey=\"0\">1&#818;\n";
                $buffer .= "<input type=\"radio\" name=\"level\" value=\"1\" accesskey=\"1\" checked>2&#818;\n";
                $buffer .= "<input type=\"radio\" name=\"level\" value=\"2\" accesskey=\"2\">3&#818;\n";
                $buffer .= "<input type=\"radio\" name=\"level\" value=\"3\" accesskey=\"3\">4&#818;\n";
                $buffer .= "<input type=\"radio\" name=\"level\" value=\"4\" accesskey=\"4\">5&#818;\n";
                $buffer .= "<input type=\"radio\" name=\"level\" value=\"5\" accesskey=\"5\">6&#818;\n";
                $buffer .= "<input type=\"radio\" name=\"level\" value=\"6\" accesskey=\"6\">6&#818;\n";
                $buffer .= "<input type=\"radio\" name=\"level\" value=\"7\" accesskey=\"7\">7&#818;\n";
                $buffer .= "<input type=\"radio\" name=\"level\" value=\"8\" accesskey=\"8\">8&#818;\n";
                $buffer .= "<input type=\"radio\" name=\"level\" value=\"9\" accesskey=\"9\">9&#818;\n";
                $tgttextcln = $tgttext;
                $tgttextcln =~ s/=/ /g;
                $tgttextcln =~ s/^ +//;
                $tgttextcln =~ s/ +$//;
                $buffer .= "<p>Title:<br><input type=\"text\" size=\"100\" name=\"title\" value=\"$tgttextcln\" accesskey=\"t\">\n";
                $buffer .= "<p>Target file: $tgtfile\n\n";
                $buffer .= "    <pre>$tgttext</pre>\n";
                $buffer .= "<p>Description:<br><textarea name=\"body\" cols=\"100\" rows=\"10\" accesskey=\"e\"></textarea>\n";
                $buffer .= "</form>\n";
            } else {
                $buffer .= "<form action=\"/srcdoc.htm\" method=\"get\">\n";
                if (/_end$/) {
                    $buffer .= "<input type=\"submit\" name=\"showform\" value=\"Show form here $lineno at b&#818;ottom\" accesskey=\"b\">\n";
                } else {
                    $buffer .= "<input type=\"submit\" name=\"showform\" value=\"Show form here $lineno\">\n";
                }
                $buffer .= "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
                $buffer .= "<input type=\"hidden\" name=\"insertlnno\" value=\"$lineno\">\n";
                $buffer .= "</form>\n";
            }
        } else {
            $buffer .= "$_\n";
        }
    }

    print $sock "$buffer";

    print $sock "<a name=\"end\"></a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
