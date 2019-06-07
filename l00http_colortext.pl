use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

#l00httpd::dbp($config{'desc'}, "2 contextln $contextln\n");
my %config = (proc => "l00http_colortext_proc",
              desc => "l00http_colortext_desc");
my ($rules);
$rules = 'l00://colortext_rules.txt';

my ($fore, $back, $stRegex, $enCnt, $enRegex, $remark);
$fore = 1;
$back = 2;
$stRegex = 3;
$enCnt = 4;
$enRegex = 5;
$remark = 6;

sub l00http_colortext_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "colortext: color text file";
}

sub l00http_colortext_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($buf, $pname, $fname, @alllines, $lineno, $buffer, $line, @rules, $ii);
    my (@allrules, $norules, $ruleidx, $rulestable, $foundRuleN, $foundCnt, $forecolor, $backcolor);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "<a name=\"top\"></a>\n";
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} - ";
    print $sock "<a href=\"#end\">Jump to end</a>\n";

    if (defined ($form->{'path'})) {
        ($pname, $fname) = $form->{'path'} =~ /^(.+[\\\/])([^\\\/]+)$/;
        print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=:hide+edit+$form->{'path'}%0D\">Path</a>: ";
        print $sock " <a href=\"/ls.htm?path=$pname\">$pname</a>";
        print $sock "<a href=\"/ls.htm?path=$form->{'path'}\">$fname</a> \n";
        print $sock " <a href=\"/ls.htm?path=$form->{'path'}&editline=on\">Edit line link</a>\n";
    }
    print $sock "<br>\n";

    if (defined ($form->{'color'}) && defined ($form->{'rules'})) {
        $rules = $form->{'rules'};
    }

    if (defined ($form->{'sample'})) {
        if (&l00httpd::l00fwriteOpen($ctrl, 'l00://colortext_rules.txt')) {
            $_ =    "|| Foreground || Background || Start Regex                  || End Count || End Regex || Remark ||\n".
                    "|| yellow     || magenta    || [l]00http_colortext_desc     || 1         || }         || start of function to end of function       ||\n".
                    "|| black      || cyan       || [l]00http_colortext_proc     || 1         || .         || one line only       ||\n".
                    "|| black      || gray       || print[ ]\\\$sock             || 1         || .         || note \\ to escape \$       ||\n".
                    "|| black      || silver     || \\\$foundRuleN = \\\$ruleidx || 3         || .         || three line block       ||\n".
                    "|| black      || lime       || #(15)                        || 1         || #(19)     || by line numbers       ||\n".
                    "* Sample rules. Leading and trailing whitespaces are trimmed from regex.\n".
                    "* [[/colortext.htm?path=$ctrl->{'plpath'}l00http_colortext.pl=l00%3A%2F%2Fcolortext_rules.txt&color=on|Take a test drive]]\n";
            &l00httpd::l00fwriteBuf($ctrl, $_);
            &l00httpd::l00fwriteClose($ctrl);
        }
    }

    print $sock "<form action=\"/colortext.htm\" method=\"get\">\n";
    print $sock "Target: <input type=\"text\" size=\"10\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "Rules: <input type=\"text\" size=\"10\" name=\"rules\" value=\"$rules\">\n";
    print $sock "<input type=\"submit\" name=\"color\" value=\"Color Text\"> \n";
    print $sock "<input type=\"checkbox\" name=\"sample\">\n";
    print $sock "Create <a href=\"/ls.htm?path=l00://colortext_rules.txt\">l00://colortext_rules.txt</a>\n";
    print $sock "</form>\n";


    if (&l00httpd::l00freadOpen($ctrl, $rules)) {
        $norules = 0;
        while ($_ = &l00httpd::l00freadLine($ctrl)) {
            s/[\r\n]//g;

            if ((/^ *\|\|.*\|\| *$/) && !(/Foreground \|\| Background/)) {
                # Looks like rule entry
                @rules = split('\|\|', $_);
                if ($#rules == ($remark)) {
                    # as expected
                    # remote leading and trialing spaces from Regex
                    for ($ii = 1; $ii <= $remark; $ii++) {
                        $rules[$ii] =~ s/^ +//;
                        $rules[$ii] =~ s/ +$//;
                    }
                    # http://perldoc.perl.org/perldsc.html#ARRAYS-OF-ARRAYS
                    $allrules[$norules] = [ @rules ];
                    $norules++;
                }
            }
        }
    }

    if (defined ($form->{'path'})) {
        print $sock "<p><pre>\n";
        $lineno = 1;
        $buffer = '';
        if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
            $buffer = &l00httpd::l00freadAll($ctrl);
        }
        $buffer =~ s/\r//g;
        @alllines = split ("\n", $buffer);
        $foundRuleN = -1;
        $foundCnt = 0;
        $forecolor = 'black';
        $backcolor = 'white';
        foreach $line (@alllines) {
            $line =~ s/\r//g;
            $line =~ s/\n//g;

            # apply coloring rules
            if ($foundRuleN >= 0) {
                # a rule was found, search for end condition
                if ($allrules[$ruleidx][$enRegex] =~ /^#\((\d+)\)$/) {
                    if ($lineno == $1) {
                        # match
                        $foundCnt++;
                        if ($foundCnt >= $allrules[$ruleidx][$enCnt]) {
                            # met hit count, clear coloring
                            $foundRuleN = -1;
                            $forecolor = 'black';
                            $backcolor = 'white';
                        }
                    }
                } else {
                    if ($line =~ /$allrules[$ruleidx][$enRegex]/) {
                        # match
                        $foundCnt++;
                        if ($foundCnt >= $allrules[$ruleidx][$enCnt]) {
                            # met hit count, clear coloring
                            $foundRuleN = -1;
                            $forecolor = 'black';
                            $backcolor = 'white';
                        }
                    }
                }
            } else {
                # reset colors
                $forecolor = 'black';
                $backcolor = 'white';
                # search for a rule for start condition
                for ($ruleidx = 0; $ruleidx < $norules; $ruleidx++) {
                    if ($allrules[$ruleidx][$stRegex] =~ /^#\((\d+)\)$/) {
                        if ($lineno == $1) {
                            # match
                            $foundRuleN = $ruleidx;
                            $foundCnt = 0;
                            $forecolor = $allrules[$foundRuleN][$fore];
                            $backcolor = $allrules[$foundRuleN][$back];
                            last;
                        }
                    } else {
                        if ($line =~ /$allrules[$ruleidx][$stRegex]/) {
                            # match
                            $foundRuleN = $ruleidx;
                            $foundCnt = 0;
                            $forecolor = $allrules[$foundRuleN][$fore];
                            $backcolor = $allrules[$foundRuleN][$back];
                            last;
                        }
                    }
                }
            }

            $line =~ s/</&lt;/g;
            $line =~ s/>/&gt;/g;

            # color line
            $line = "<font style=\"color:$forecolor;background-color:$backcolor\">$line</font>";

            printf $sock ("%04d: %s\n", $lineno, $line);
            $lineno++;
        }

        print $sock "</pre>\n";
        print $sock "<hr><a name=\"end\"></a>";
        print $sock "<a href=\"#top\">top</a>\n";
    }

    # print parsed rule table
    $rulestable = "|| Foreground || Background || Start Regex || End Count || End Regex || Remark ||\n";
    for ($ruleidx = 0; $ruleidx < $norules; $ruleidx++) {
        $rulestable .=  "|| $allrules[$ruleidx][$fore] || $allrules[$ruleidx][$back] ".
                        "|| $allrules[$ruleidx][$stRegex] || $allrules[$ruleidx][$enCnt] ".
                        "|| $allrules[$ruleidx][$enRegex] ".
                        "|| <font style=\"color:$allrules[$ruleidx][$fore];background-color:$allrules[$ruleidx][$back]\">".
                        "$allrules[$ruleidx][$remark] ||\n";
    }
    $rulestable .= "* List of rules\n";
    print $sock &l00wikihtml::wikihtml ($ctrl, "", $rulestable, 0);

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
