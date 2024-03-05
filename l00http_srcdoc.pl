use strict;
use warnings;
use l00wikihtml;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_srcdoc_proc",
              desc => "l00http_srcdoc_desc");
my ($editwd, $editht, $editsz, $root, $filter);
my ($hostpath, $contextln, $blklineno, $level, @secnos);
my (%writeentirefile, %writeentirefilehighlight);
$hostpath = "c:\\x\\";
$editsz = 0;
$editwd = 320;
$editht = 7;
$contextln = 0;
$blklineno = 0;
$root = '';
$filter = '\.c$|||\.cpp$|||\.h$';
$level = 3;

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
    my (@alllines, $line, $lineno, $blkbuf, $tgtline, $tgtln, $cnt);
    my ($pname, $fname, $comment, $buffer, @buf, $tmp, $tmp2, $lnno, $uri, $ii, $cmd, $lasthdrlvl);
    my ($gethdr, $html, $html2, $title, $body, $level, $tgtfile, $tgttext, $tgttextcln);
    my ($tlevel, $tfullpath, $tfullname, $tlnnohi, $tlnnost, $tlnnoen, $srcln, $copyname, $copyidx);
    my ($loop, $st, $hi, $en, $fileno, $orgln, $secno, %secnohash);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} - ";
    print $sock "<a href=\"#end\">Jump to end</a>\n";
	print $sock "<a href=\"#__toc__\">toc</a>\n";

    if (defined ($form->{'path'})) {
        $form->{'path'} =~ s/\r//g;
        $form->{'path'} =~ s/\n//g;
        ($tfullpath, $tfullname) = $form->{'path'} =~ /^(.+?)([^\\\/]+)$/;
        print $sock " <a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tfullpath\" target=\"_blank\">Path: </a>";
        print $sock "<a href=\"/ls.htm?path=$tfullpath\">$tfullpath</a>";
        print $sock "<a href=\"/view.htm?path=$tfullpath$tfullname\">$tfullname</a>\n";
    }
    print $sock "<br>\n";


    # insert notes
    if (defined ($form->{'Save'}) && defined ($form->{'insertlnno'})) {
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
            $lnno = 0;
            $buffer = '';
            for ($ii = 0; $ii < $form->{'insertlnno'}; $ii++) {
                $buffer .= <IN>;
            }
            $buffer .= '=' x ($level + 1) . $title . '=' x ($level + 1) . "\n";
            $buffer .= "$tgtfile\n";
            $buffer .= "$body\n";
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
        }
    }


    $buffer = '';
    @buf = ();
    if (open (IN, "<$form->{'path'}")) {
        $lnno = 0;
        $root = '';
        $lasthdrlvl = 1;
        $fileno = 0;
        while (<IN>) {
            if (/^(=+)/) {
                $buffer .= "\n__SRCDOC__$lnno\n";
                $fileno = $lnno + 2;
            }
            $lnno++;
            if (($fileno == $lnno) &&
                # /sdcard/g/myram/x/Perl/srcdoc/template/go.bat::0::9::99999::
                (($tfullpath, $tfullname, $st, $hi, $en) = /^(.+?)([^\\\/]+?)::(\d+)::(\d+)::(.+)$/)) {
                $buffer .= "<a href=\"/ls.htm?path=$tfullpath\">$tfullpath</a>".
                           "<a href=\"/view.htm?path=$tfullpath$tfullname&hiliteln=$hi&lineno=on#line$hi\">$tfullname</a>".
                           "::${st}::${hi}::${en}\n";
            } else {
                $buffer .= $_;
            }
            push(@buf, $_);
        }
        $buffer .= "\n__SRCDOC__${lnno}_end\n";
        close (IN);
    }
    ($pname, $fname) = $form->{'path'} =~ /^(.+\/)([^\/]+)$/;


    if (defined ($form->{'generate'})) {
        $html = '';
        $html .= <<end_of_print1
    <html>
    <head>
    <title>$pname${fname}</title>
    </head>
    <frameset cols="40%,*">
end_of_print1
;
        $html .= "    <frame name=\"nav\" src=\"$pname${fname}_nav0.html\">";
        $html .= <<end_of_print2

    <frame name="content">
    </frameset>
    <body bgcolor="#FFFFFF">
    </body>
    </html>
end_of_print2
;

        if (open(OU, ">$pname${fname}_index.html")) {
            print OU $html;
            close(OU);
        }


        l00httpd::dbp($config{'desc'}, "generate outputs ${fname}_index.html in $pname\n"), if ($ctrl->{'debug'} >= 1);
        $html = '';

        undef %writeentirefile;
        undef %writeentirefilehighlight;
        $cnt = 0;
        &l00http_srcdoc_secno(-2);
        undef %secnohash;
        $tfullpath = '';
        $tfullname = '';
        $loop = 1;
        $ii = 0;
        $copyidx = 1;
        $orgln = '(unavailable)';
        while ($loop) {
            $srcln = $ii + 1;
            if (($tfullpath ne '') && (($ii > $#buf) || ($buf[$ii] =~ /^=+/))) {
                l00httpd::dbp($config{'desc'}, "INSERT target level $tlevel line ${tlnnost}::${tlnnohi}::$tlnnoen in file $tfullpath\n"), if ($ctrl->{'debug'} >= 1);
                l00httpd::dbp($config{'desc'}, "ORGLN:$orgln\n"), if ($ctrl->{'debug'} >= 1);
                $html .= "SRCDOC::${srcln}::${tlevel}::${tfullpath}::${tlnnost}::${tlnnohi}::${tlnnoen}::$orgln\n";
                $secnohash{$srcln} = $secno;
                $orgln = '(unavailable)';
                ($tfullname) = $tfullpath =~ /([^\\\/]+)$/;
                $copyname = "${fname}_${copyidx}_$tfullname.html";
                if (!defined($writeentirefile{$tfullpath})) {
                    $cnt++;
                    $writeentirefile{$tfullpath} = $cnt;
                }
                $copyidx++;
#               $html .= "<br><a href=\"$pname$copyname\" target=\"content\">[show code]</a> ($pname${fname}:$srcln$pname$copyname)\n";
                $html .= "<br><a href=\"$copyname\" target=\"content\">[show code]</a>\n";
                $tfullpath = '';
            }
            if ($ii <= $#buf) {
                if (($tmp, $tmp2) = $buf[$ii] =~ /^(=+)(.+)$/) {
                    $tlevel = length($tmp) - 1;
                    $secno = &l00http_srcdoc_secno($tlevel);
                    $html .= "\n<a name=\"#sec_$secno\"></a>\n";
                    $html .= "$tmp$secno $tmp2\n";
                } else {
                    $html .= $buf[$ii];
                }
                if (($tmp) = $buf[$ii] =~ /^(=+)/) {
                    $tlevel = length($tmp) - 1;
                    l00httpd::dbp($config{'desc'}, "this line ^= x $tlevel\n"), if ($ctrl->{'debug'} >= 1);
                    if (($tfullpath, $tlnnost, $tlnnohi, $tlnnoen) = $buf[$ii + 1] =~ /^(.+?)::(\d+)::(\d+)::(\d+)/) {
                        l00httpd::dbp($config{'desc'}, "next line target level $tlevel line $tlnnost-$tlnnohi-$tlnnoen in file $tfullpath\n"), if ($ctrl->{'debug'} >= 1);
                        if (!-f $tfullpath) {
                            l00httpd::dbp($config{'desc'}, "target file not found\n"), if ($ctrl->{'debug'} >= 1);
                            $tfullpath = '';
                        } else {
                            # if file exist, save original line too
                            if (($ii + 3) <= $#buf) {
                                # skip added 4 leading spaces
                                $orgln = substr($buf[$ii + 3], 4, 9999);
                            }
                        }
                    } else {
                        $tfullpath = '';
                    }
                }
                $ii++;
            } else {
                $loop = 0;
            }
        }

        $html .= "%TOC%\n";

        $html = &l00wikihtml::wikihtml ($ctrl, $pname, $html, 0, $fname);
            $html = <<end_of_print3
        <html>
        <head>
        <title>$pname${fname}</title>
        </head>
        <body bgcolor="#FFFFFF">
        $html
end_of_print3
;
        $html .= "</body>\n</html>\n";

        &l00httpd::l00fwriteOpen($ctrl, "l00://~srcdoc_html.txt");
        &l00httpd::l00fwriteBuf($ctrl, $html);
        &l00httpd::l00fwriteClose($ctrl);

        # insert
        $html2 = '';
        $copyidx = 1;
        $srcln = 0;
        foreach $_ (split("\n", $html)) {
            # SRCDOC::123::1::/sdcard/g/myram/x/Perl/srcdoc/template/go.bat::0::10::99999::orgln
#           if (/^SRCDOC::/ && (($tmp, $srcln, $level, $tfullpath, $st, $hi, $en) = split('::', $_))) {
            if (/^SRCDOC::/ && (($srcln, $level, $tfullpath, $st, $hi, $en, $orgln) = 
                /^SRCDOC::(\d+)::(\d+)::(.+?)::(\d+)::(\d+)::(\d+)::(.+)$/)) {
                $writeentirefilehighlight{$tfullpath} .= ":$hi,$reccuLvlColor[$level]:";
l00httpd::dbp($config{'desc'}, "writeentirefilehighlight{$tfullpath} = $writeentirefilehighlight{$tfullpath}\n"), if ($ctrl->{'debug'} >= 1);
                ($tfullname) = $tfullpath =~ /([^\\\/]+)$/;
                $tfullpath =~ s/[^\\\/]+$//;
                $copyname = "${fname}_${copyidx}_$tfullname.html";

                $copyidx++;
                if (open(COPYDEST, ">$pname$copyname")) {
                    print COPYDEST "<html>\n<head>\n";
                    print COPYDEST "<title>$fname</title>\n";
                    print COPYDEST "</head>\n<body bgcolor=\"#FFFFFF\">\n\n";
                   #print COPYDEST "<h3><a href=\"$basename" . "_nav0.htm#$anchorthis\" target=\"nav\"><i>$secnum</i> "."[".$paracurlvl."]$fragcnt2</a> ";
                   #print COPYDEST "<a href=\"$basename" . "_nav1.htm#$anchorthis\" target=\"nav\">short form</a>: $title</h3>\n\n";
                   #print COPYDEST "<p>filename: <a href=\"$fnamepart.htm#_$lineno\">$fname</a>($lineno):<br>\n";
                   #print COPYDEST "original line: <i>$orgln</i></p>\n\n";
                    print COPYDEST "<pre>\n";

                    print COPYDEST "index   : <a href=\"${fname}_nav0.html#sec_$secnohash{$srcln}\" target=\"nav\"><i>section $secnohash{$srcln}</i></a>\n";
                    print COPYDEST "Source  : $tfullpath$tfullname ($hi)\n";
                    print COPYDEST "Original: $orgln\n";
                    l00httpd::dbp($config{'desc'}, " - tfullname = $tfullname\n"), if ($ctrl->{'debug'} >= 1);
                    l00httpd::dbp($config{'desc'}, " - tfullpath = $tfullpath\n"), if ($ctrl->{'debug'} >= 1);
                    l00httpd::dbp($config{'desc'}, " - copyname = $copyname\n"), if ($ctrl->{'debug'} >= 1);
                    l00httpd::dbp($config{'desc'}, " - level = $level\n"), if ($ctrl->{'debug'} >= 1);
                    l00httpd::dbp($config{'desc'}, " - st = $st\n"), if ($ctrl->{'debug'} >= 1);
                    l00httpd::dbp($config{'desc'}, " - hi = $hi\n"), if ($ctrl->{'debug'} >= 1);
                    l00httpd::dbp($config{'desc'}, " - en = $en\n"), if ($ctrl->{'debug'} >= 1);

                    open (COPYSRC, "<$tfullpath$tfullname");
                    $lnno = 1;
                    while (<COPYSRC>) {
                        if (($lnno >= $st) && ($lnno <= $en)) {
                                if ($hi == $lnno) {
                                print COPYDEST "<font color=\"". $reccuLvlColor [$level] ."\">";
                                print COPYDEST "Call level $level\n";
                            }
                            print COPYDEST sprintf ("%4d: ", $lnno);
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


                    print COPYDEST "</pre></body></html>\n";
                    close(COPYDEST);
                }
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
            if (/<h\d+>.*blog.htm.*edit.htm.*view.htm.*<\/h\d+>/) {
                s/<a href="#toc_.+?<\/a>//;
                s/<a href="\/blog.htm.+?<\/a>//;
                s/<a href="\/edit.htm.+?<\/a>//;
                if ($srcln > 0) {
                    s/<a href="\/view.htm.+?<\/a>/ ($srcln)/;
                    $srcln = 0;
                } else {
                    s/<a href="\/view.htm.+?<\/a>//;
                }
            }
            s/<a href="#___top___.+?<\/a>//;
            s/<a href="#__toc__.+?<\/a>//;
            $html2 .= "$_\n";
        }
        if (open(OU, ">$pname${fname}_nav0.html")) {
            print OU $html2;
            close(OU);
        }

        
        # print entire file with line number and color
        # ::conti::
        foreach $fname (keys %writeentirefile) {
            $copyname = $fname;
            $copyname =~ s/^.+[\\\/]([^\\\/]+)$/$1/;
            $copyname = "${pname}${copyname}_$writeentirefile{$fname}.html";
#::conti::
l00httpd::dbp($config{'desc'}, "writeentirefile = $fname -- $writeentirefile{$fname} : $copyname\n"), if ($ctrl->{'debug'} >= 1);
l00httpd::dbp($config{'desc'}, "writeentirefilehighlight = $writeentirefilehighlight{$fname}\n"), if ($ctrl->{'debug'} >= 1);
#           if (open(OU, ">$copyname")) {
#               print OU "$fname";
#               close(OU);
#           }
        }
    }


    $html = &l00wikihtml::wikihtml ($ctrl, $pname, $buffer, 2, $fname);
    $buffer = "<br>\n";
    $buffer .= "<form action=\"/srcdoc.htm\" method=\"get\">\n";
    $buffer .= "<input type=\"submit\" name=\"refresh\" value=\"R&#818;efresh\" accesskey=\"r\">\n";
    $buffer .= "<input type=\"submit\" name=\"generate\" value=\"G&#818;enerate\" accesskey=\"g\">\n";
    $buffer .= "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
    $buffer .= "</form>\n";
    $buffer .= "Outout on port: \n";
    $buffer .= "<a href=\"http://localhost:20337/$pname${fname}_index.html\" target=\"_blank\">20337</a>\n";
    $buffer .= "<a href=\"http://localhost:20347/$pname${fname}_index.html\" target=\"_blank\">20347</a>\n";
    $buffer .= "<a href=\"http://localhost:30337/$pname${fname}_index.html\" target=\"_blank\">30337</a>\n";
    $buffer .= "<a href=\"http://localhost:30347/$pname${fname}_index.html\" target=\"_blank\">30347</a>\n";
    foreach $_ (split("\n", $html)) {
        if (($lineno) = /^__SRCDOC__(\d+)/) {
           #$buffer .= "SRCDOC FORM:$1\n";
            if (defined ($form->{'insertlnno'}) && ($form->{'insertlnno'} eq "$lineno")) {
                if (&l00httpd::l00freadOpen($ctrl, "l00://~find_hilite.txt")) {
                    $tgtfile = &l00httpd::l00freadLine($ctrl);
                    $tgttext = &l00httpd::l00freadLine($ctrl);
                }
               #$buffer .= "INSERT NOTES HERE $form->{'update'}<br>\n";
                $buffer .= "<form action=\"/srcdoc.htm\" method=\"post\">\n";
                $buffer .= "<input type=\"submit\" name=\"Save\" value=\"S&#818;ave notes here $lineno\" accesskey=\"s\">\n";
                $buffer .= "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
                $buffer .= "<input type=\"hidden\" name=\"insertlnno\" value=\"$lineno\">\n";
                $buffer .= "<input type=\"checkbox\" name=\"pair\">Calling/Return From pair\n";
                $buffer .= "Level: ";
                $buffer .= "<input type=\"radio\" name=\"level\" value=\"0\" accesskey=\"0\">0&#818;\n";
                $buffer .= "<input type=\"radio\" name=\"level\" value=\"1\" accesskey=\"1\" checked>1&#818;\n";
                $buffer .= "<input type=\"radio\" name=\"level\" value=\"2\" accesskey=\"2\">2&#818;\n";
                $buffer .= "<input type=\"radio\" name=\"level\" value=\"3\" accesskey=\"3\">3&#818;\n";
                $buffer .= "<input type=\"radio\" name=\"level\" value=\"4\" accesskey=\"4\">4&#818;\n";
                $buffer .= "<input type=\"radio\" name=\"level\" value=\"5\" accesskey=\"5\">5&#818;\n";
                $tgttextcln = $tgttext;
                $tgttextcln =~ s/=/ /g;
                $buffer .= "<p>Title:<br><input type=\"text\" size=\"100\" name=\"title\" value=\"$tgttextcln\" accesskey=\"t\">\n";
                $buffer .= "<p>Target file: $tgtfile\n\n";
                $buffer .= "    <pre>$tgttext</pre>\n";
                $buffer .= "<p>Description:<br><textarea name=\"body\" cols=\"100\" rows=\"10\" accesskey=\"e\"></textarea>\n";
                $buffer .= "</form>\n";
            } else {
                $buffer .= "<form action=\"/srcdoc.htm\" method=\"get\">\n";
                if (/_end$/) {
                    $buffer .= "<input type=\"submit\" name=\"showform\" value=\"Show form here $lineno l&#818;ast\" accesskey=\"l\">\n";
                } else {
                    $buffer .= "<input type=\"submit\" name=\"showform\" value=\"Show form here $lineno\">\n";
                }
                $buffer .= "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
                $buffer .= "<input type=\"hidden\" name=\"insertlnno\" value=\"$lineno\">\n";
                $buffer .= "</form>\n";
            }
        } else {
            $buffer .= "$_";
        }
    }
    print $sock "$buffer";

    print $sock "<a name=\"end\"></a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
