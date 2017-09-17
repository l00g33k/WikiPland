#use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# do %TXTDOPL% in .txt
my ($arg, $eval, $sort, $sortdec);
$arg = '';
$eval = '';
$sort = '';
$sortdec = '';

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
    my ($dopl, $dorst, @newfile);
    my ($last, $this, $next, $perl, $buf, $tmp, $pname, $fname, $cnt);

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
        if ($ctrl->{'os'} eq 'win') {
            $tmp =~ s/\//\\/g;
        }
        print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\" target=\"newclip\">Path</a>: ";
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
    }

    print $sock "<a href=\"/lineproc.htm?path=$form->{'path'}\">Refresh</a> - ";
    print $sock "View: <a href=\"/view.htm?path=l00://lineproc_out.txt\" target=\"newlineproc\">l00://lineproc_out.txt</a>; \n";
    print $sock "<a href=\"/filemgt.htm?path=l00://lineproc_out.txt&path2=$pname$fname\" target=\"newfilemgt\">copy it to</a>...<br>\n";
    print $sock "<a href=\"#__top__\">Jump to top</a> - \n";
    print $sock "<a href=\"#__print__\">print</a> - \n";
    print $sock "<a href=\"#__out__\">output</a> - \n";
    print $sock "<a href=\"#__end__\">end</a><br>\n";

    print $sock "<form action=\"/lineproc.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"text\" size=\"24\" name=\"path\" value=\"$pname$fname\">\n";
    print $sock "            <input type=\"submit\" name=\"run\" value=\"Process\"></td>\n";
    print $sock "    </tr>\n";

    print $sock "    <tr>\n";
    print $sock "        <td><textarea name=\"eval\" cols=$ctrl->{'txtw'} rows=$ctrl->{'txth'}>$eval</textarea>\n";
    print $sock "            <br><input type=\"submit\" name=\"pasteeval\" value=\"CB to eval\">\n";
    print $sock "            <input type=\"checkbox\" name=\"sort\" $sort>Sort after processing; \n";
    print $sock "            <input type=\"checkbox\" name=\"sortdec\" $sortdec>in decresing order. \n";
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
                eval $eval;
                if (defined($_)) {
                    push(@newfile, "$_\n");
                }
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
            foreach $_ (@newfile) {
                &l00httpd::l00fwriteBuf($ctrl, $_);
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
            print $sock "The first 1000 lines of output follows. (View <a href=\"/view.htm?path=l00://lineproc_out.txt\" target=\"newlineproc\">l00://lineproc_out.txt</a>):\n";
            print $sock "<pre>\n";

            while ($_ = &l00httpd::l00freadLine($ctrl)) {
                printf $sock ("%04d: %s", $cnt, $_);
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
            print $sock "The first 1000 lines of the input file follows. (View <a href=\"/view.htm?path=$form->{'path'}\" target=\"newlineproc\">$form->{'path'}</a>):\n";
            print $sock "<pre>\n";

            while ($_ = &l00httpd::l00freadLine($ctrl)) {
                printf $sock ("%04d: %s", $cnt, $_);
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
