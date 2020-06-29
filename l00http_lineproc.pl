#use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# do %TXTDOPL% in .txt
my ($arg, $eval, $sort, $sortdec, $dedup, $wholefile, $rmnewline, $nolnno);
$arg = '';
$eval = '';
$sort = '';
$sortdec = '';
$dedup = '';
$wholefile = '';
$rmnewline = '';
$nolnno = '';

my %config = (proc => "l00http_lineproc_proc",
              desc => "l00http_lineproc_desc");


sub l00http_lineproc_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "lineproc: Perl 'eval' on target file";
}

sub l00http_lineproc_proc (\%) {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($dopl, $dorst, @newfile, $lnno);
    my ($last, $this, $next, $perl, $buf, $tmp, $pname, $fname, $cnt, @evals, $eval1);

    # Send HTTP and HTML headers
    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} - ";
    print $sock "<a href=\"#__end__\">Jump to end</a>\n";
    print $sock "<a name=\"__top__\"></a>\n";


    $pname = '';
    $fname = '';
    if (defined ($form->{'path'})) {
        $form->{'path'} =~ s/\r//g;
        $form->{'path'} =~ s/\n//g;
        $tmp = $form->{'path'};
        if (($ctrl->{'os'} eq 'win') || ($ctrl->{'os'} eq 'cyg')) {
            $tmp =~ s/\//\\/g;
        }
        print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\" target=\"_blank\">Path</a>: ";
        if (($pname, $fname) = $form->{'path'} =~ /^(.+\/)([^\/]+)$/) {
            # not ending in / or \, not a dir
            print $sock "<a href=\"/ls.htm?path=$pname\">$pname</a>";
            print $sock "<a href=\"/view.htm?path=$form->{'path'}\">$fname</a>\n";
        } else {
            print $sock " <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a>\n";
        }
    }
    print $sock "<br>\n";

    if (defined ($form->{'eval'})) {
        $eval = $form->{'eval'};
    }
    if (defined ($form->{'pasteeval'})) {
        $eval = &l00httpd::l00getCB($ctrl);
    }

    if ((defined ($form->{'path'})) && (defined ($form->{'run'}))) {
        if (defined ($form->{'sort'}) && ($form->{'sort'} eq 'on')) {
            $sort = 'checked';
        } else {
            $sort = '';
        }
        if (defined ($form->{'sortdec'}) && ($form->{'sortdec'} eq 'on')) {
            $sortdec = 'checked';
        } else {
            $sortdec = '';
        }
        if (defined ($form->{'dedup'}) && ($form->{'dedup'} eq 'on')) {
            $dedup = 'checked';
        } else {
            $dedup = '';
        }
        if (defined ($form->{'nolnno'}) && ($form->{'nolnno'} eq 'on')) {
            $nolnno = 'checked';
        } else {
            $nolnno = '';
        }
        if (defined ($form->{'wholefile'}) && ($form->{'wholefile'} eq 'on')) {
            $wholefile = 'checked';
        } else {
            $wholefile = '';
        }
        if (defined ($form->{'rmnewline'}) && ($form->{'rmnewline'} eq 'on')) {
            $rmnewline = 'checked';
        } else {
            $rmnewline = '';
        }
    }

    print $sock "<a href=\"/lineproc.htm?path=$form->{'path'}\">Refresh</a> - ";
    print $sock "View: <a href=\"/view.htm?path=l00://lineproc_out.txt\" target=\"_blank\">l00://lineproc_out.txt</a>; \n";
    print $sock "<a href=\"/filemgt.htm?path=l00://lineproc_out.txt&path2=$pname$fname\" target=\"_blank\">copy it to</a>...<br>\n";
    print $sock "<a href=\"#__top__\">Jump to top</a> - \n";
    print $sock "<a href=\"#__print__\">print</a> - \n";
    print $sock "<a href=\"#__out__\">output</a> - \n";
    print $sock "<a href=\"#__end__\">end</a><br>\n";

    print $sock "<form action=\"/lineproc.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"text\" size=\"24\" name=\"path\" value=\"$pname$fname\">\n";
    print $sock "            <input type=\"checkbox\" name=\"wholefile\" $wholefile>whole file.\n";
    print $sock "            <input type=\"submit\" name=\"run\" value=\"P&#818;rocess\" accesskey=\"p\">\n";
    print $sock "            <input type=\"checkbox\" name=\"rmnewline\" $rmnewline>remove newline.</td>\n";
    print $sock "    </tr>\n";

    print $sock "    <tr>\n";
    print $sock "        <td><textarea name=\"eval\" cols=$ctrl->{'txtw'} rows=$ctrl->{'txth'} accesskey=\"e\">$eval</textarea>\n";
    print $sock "            <br><input type=\"submit\" name=\"pasteeval\" value=\"CB to eval\">\n";
    print $sock "            <input type=\"checkbox\" name=\"sort\" $sort>Sort after processing; \n";
    print $sock "            <input type=\"checkbox\" name=\"sortdec\" $sortdec>in decresing order. \n";
    print $sock "            <input type=\"checkbox\" name=\"dedup\" $dedup>dedup. \n";
    print $sock "            <input type=\"checkbox\" name=\"nolnno\" $nolnno>no line number. \n";
    print $sock "    </td>\n";
    print $sock "    </tr>\n";

    print $sock "</table>\n";
    print $sock "</form>\n";

    if ((defined ($form->{'path'})) && (defined ($form->{'run'}))) {
        if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
            undef @newfile;
            undef $last;
            undef $this;
            undef $next;
            print $sock "<a name=\"__print__\"></a>\n";
            print $sock "<a href=\"#__top__\">Jump to top</a> - \n";
            print $sock "<a href=\"#__print__\">print</a> - \n";
            print $sock "<a href=\"#__out__\">output</a> - \n";
            print $sock "<a href=\"#__end__\">end</a><br>\n";
            print $sock "'print \$sock' from the script appears below:<p>\n<pre>\n";
            # when $eval is eval'ed, $_ is this line, $next is what will be the next line
            # $last is what was $_.
            # There are two special cases:
            # 1) at the very start, only  $next is the first line in the input, $_ and $this is undef
            # 2) at the very end, only $last is the last line in the input, $_ and $next is undef
            $eval =~ s/\r//g;
            @evals = split("\n", $eval);
            if ($wholefile eq 'checked') {
                $_ = &l00httpd::l00freadAll($ctrl);
                $lnno = 0;
                foreach $eval1 (@evals) {
                    eval $eval1;
                }
                push(@newfile, "$_\n");
            } else {
                $lnno = 0;
                while ($_ = &l00httpd::l00freadLine($ctrl)) {
                    s/\r//;
                    s/\n//;
                    if (!defined ($next)) {
                        # first ever line was just read and is going to be the $next line, current $_ is undef.
                        $next = $_;
                        $_ = undef;
                    } elsif (!defined ($this)) {
                        # second ever line was just read
                        $this = $next;
                        $next = $_;
                        $_ = $this;
                    } else {
                        $last = $this;
                        $this = $next;
                        $next = $_;
                        $_ = $this;
                    }
                    foreach $eval1 (@evals) {
                        eval $eval1;
                    }
                    if (defined($_)) {
                        if ($rmnewline eq 'checked') {
                            push(@newfile, "$_");
                        } else {
                            push(@newfile, "$_\n");
                        }
                    }
                    $lnno++;
                }
                # last line from file has just been processed, so $next will be undef
                $last = $this;
                $this = $next;
                $next = undef;
                $_ = $this;
                eval $eval;
                if (defined($_)) {
                    push(@newfile, "$_\n");
                }
                # last line from file has been processed once, so $_ will be undef
                $last = $this;
                $next = undef;
                $_ = undef;
                eval $eval;
                if (defined($_)) {
                    push(@newfile, "$_\n");
                }
            }
            print $sock "</pre>\n";

            # sort
            if ($sort eq 'checked') {
                if ($sortdec eq 'checked') {
                    # decreasing
                    @newfile = sort {$b cmp $a} (@newfile);
                } else {
                    # increasing
                    @newfile = sort {$a cmp $b} (@newfile);
                }
            }

            # write new file only if changed
            &l00httpd::l00fwriteOpen($ctrl, 'l00://lineproc_out.txt');
            $last = '';
            foreach $_ (@newfile) {
                if ($dedup eq 'checked') {
                    if ($last eq $_) {
                        next;
                    }
                }
                &l00httpd::l00fwriteBuf($ctrl, $_);

                $last = $_;
            }
            &l00httpd::l00fwriteClose($ctrl);
        }

        if (&l00httpd::l00freadOpen($ctrl, 'l00://lineproc_out.txt')) {
            $cnt = 1;
            print $sock "<a name=\"__out__\"></a>\n";
            print $sock "<a href=\"#__top__\">Jump to top</a> - \n";
            print $sock "<a href=\"#__print__\">print</a> - \n";
            print $sock "<a href=\"#__out__\">output</a> - \n";
            print $sock "<a href=\"#__end__\">end</a><br>\n";
            print $sock "The 'eval' script is:\n<pre>$eval</pre><br>\n";
            print $sock "The first 1000 lines of output follows. (View <a href=\"/view.htm?path=l00://lineproc_out.txt\" target=\"_blank\">l00://lineproc_out.txt</a>):\n";
            print $sock "<pre>\n";

            while ($_ = &l00httpd::l00freadLine($ctrl)) {
                s/</&lt;/g;
                s/>/&gt;/g;
                if ($nolnno eq '') {
                    printf $sock ("%04d: %s", $cnt, $_);
                } else {
                    printf $sock ("%s", $_);
                }
                $cnt++;
                if ($cnt > 1000) {
                    last;
                }
            }
            print $sock "</pre>\n";
        }
    } else {
        if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
            $cnt = 1;
            print $sock "<a name=\"__out__\"></a>\n";
            print $sock "<a href=\"#__top__\">Jump to top</a> - \n";
            print $sock "<a href=\"#__print__\">print</a> - \n";
            print $sock "<a href=\"#__out__\">output</a> - \n";
            print $sock "<a href=\"#__end__\">end</a><br>\n";
            print $sock "The first 1000 lines of the input file follows. (View <a href=\"/view.htm?path=$form->{'path'}\" target=\"_blank\">$form->{'path'}</a>):\n";
            print $sock "<pre>\n";

            while ($_ = &l00httpd::l00freadLine($ctrl)) {
                s/</&lt;/g;
                s/>/&gt;/g;
                if ($nolnno eq '') {
                    printf $sock ("%04d: %s", $cnt, $_);
                } else {
                    printf $sock ("%s", $_);
                }
                $cnt++;
                if ($cnt > 1000) {
                    last;
                }
            }
            print $sock "</pre>\n";
        }
    }


    print $sock "<a name=\"__end__\"></a><br>\n";
    print $sock "<a href=\"#__top__\">Jump to top</a> - \n";
    print $sock "<a href=\"#__print__\">print</a> - \n";
    print $sock "<a href=\"#__out__\">output</a>\n";


    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
