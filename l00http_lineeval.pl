#use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# do %TXTDOPL% in .txt
my ($arg, $eval, $sort, $sortdec, $wholefile, $useform, $longgray);
$arg = '';
$eval = '';
$sort = '';
$sortdec = '';
$wholefile = '';
$useform = '';
$longgray = '';
my %config = (proc => "l00http_lineeval_proc",
              desc => "l00http_lineeval_desc");


sub l00http_lineeval_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "lineeval: Line Perl 'eval' processor";
}

sub l00http_lineeval_proc (\%) {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my (@newfile, $lnno, $mvfrom, $tmp, @evals);
    my ($pname, $fname, $anchor, $clipurl, $clipexp, $copy2clipboard);

    # Send HTTP and HTML headers
    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} - ";
    print $sock "<a href=\"#__end__\">Jump to end</a>\n";
    print $sock "<a name=\"__top__\"></a>\n";

    $copy2clipboard = '^(.+)$';

    $anchor = '';
    if (defined ($form->{'anchor'})) {
        $anchor = $form->{'anchor'};
    }

    if (defined ($form->{'run'})) {
        if (defined ($form->{'useform'}) && ($form->{'useform'} eq 'on')) {
            $useform = 'checked';
        } else {
            $useform = '';
        }
        if (defined ($form->{'longgray'}) && ($form->{'longgray'} eq 'on')) {
            $longgray = 'checked';
        } else {
            $longgray = '';
        }
    }

    $pname = '';
    $fname = '';
    if (defined ($form->{'path'})) {
        $form->{'path'} =~ s/\r//g;
        $form->{'path'} =~ s/\n//g;
        $tmp = $form->{'path'};
        if ($ctrl->{'os'} eq 'win') {
            $tmp =~ s/\//\\/g;
        }
        print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\" target=\"_blank\">Path</a>: ";
        if (($pname, $fname) = $form->{'path'} =~ /^(.+\/)([^\/]+)$/) {
            # not ending in / or \, not a dir
            print $sock "<a href=\"/ls.htm?path=$pname\">$pname</a>";
            print $sock "<a href=\"/ls.htm?path=$form->{'path'}\">$fname</a>\n";
        } else {
            print $sock " <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a>\n";
        }
        print $sock " - <a href=\"/view.htm?path=$form->{'path'}\">view</a>";
        print $sock " - <a href=\"/lineeval.htm?path=$form->{'path'}\">refresh</a>";
    }

    print $sock "<form action=\"/lineeval.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"text\" size=\"24\" name=\"path\" value=\"$pname$fname\">\n";
    print $sock "            <input type=\"submit\" name=\"run\" value=\"Set\">\n";
    print $sock "            <input type=\"checkbox\" name=\"useform\" $useform>Use form\n";
    print $sock "            <input type=\"checkbox\" name=\"longgray\" $longgray>Long gray</td>\n";
    print $sock "    </tr>\n";

    print $sock "</table>\n";

    if ($useform ne 'checked') {
        print $sock "</form>\n";
    }


    if ((defined ($form->{'path'})) && (defined ($form->{'run'}))) {
        if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
            undef @newfile;
            undef @evals;

            $lnno = 1;
            while ($_ = &l00httpd::l00freadLine($ctrl)) {
                s/\r//;
                s/\n//;

                push(@newfile, "$_\n");

                # %LINEEVAL~#~s/^(.)/#$1/%
                if (/^\%LINEEVAL~(.+?)~(.+)\%$/) {
                    if ($1 ne 'copy2clipboard') {
                        # don't list the user copy2clipboard regex
                        push(@evals, $2);
                    }
                }

                $lnno++;
            }

            if (defined($form->{'cmd'}) && ($form->{'cmd'} eq 'rm') &&
                defined($form->{'ln'}) && ($#newfile >= 0)) {
                # delete line
                splice (@newfile, $form->{'ln'} - 1, 1);
            }
            if (defined($form->{'cmd'}) && ($form->{'cmd'} eq 'mv') &&
                defined($form->{'mvto'}) && defined($form->{'mvfrom'}) &&
                ($#newfile >= 0)) {
                if ($form->{'mvto'} > $form->{'mvfrom'}) {
                    # first insert into target position
                    splice (@newfile, $form->{'mvto'}, 0, $newfile[$form->{'mvfrom'} - 1]);
                    # then delete original
                    # inserted line is after the original line, so index to original doesn't change
                    splice (@newfile, $form->{'mvfrom'} - 1, 1);
                } else {
                    # first insert into target position
                    splice (@newfile, $form->{'mvto'} - 1, 0, $newfile[$form->{'mvfrom'} - 1]);
                    # then delete original
                    # inserted line is before the original line, so index to original is +1
                    splice (@newfile, $form->{'mvfrom'}, 1);
                }
            }

            # find form checkbox
            if ($useform eq 'checked') {
                foreach $_ (keys %$form) {
                    # chk_evalid_3__ln_44
                    if (/chk_evalid_(\d+)__ln_(\d+)$/) {
                        $_ = $newfile[$2 - 1];
                        eval $evals[$1];
                        $newfile[$2 - 1] = $_;
                    }
                }
            } else {
                if (defined($form->{'cmd'}) && ($form->{'cmd'} eq 'eval') &&
                    defined($form->{'ln'}) && defined($form->{'evalid'})) {
                    $_ = $newfile[$form->{'ln'} - 1];
                    eval $evals[$form->{'evalid'}];
                    $newfile[$form->{'ln'} - 1] = $_;
                }
            }

            &l00backup::backupfile ($ctrl, $form->{'path'}, 1, 9);
            &l00httpd::l00fwriteOpen($ctrl, $form->{'path'});
            foreach $_ (@newfile) {
                &l00httpd::l00fwriteBuf($ctrl, $_);
            }
            &l00httpd::l00fwriteClose($ctrl);
        }
    }

    if (defined ($form->{'path'})) {
        if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
            undef @newfile;
            undef @evals;
            while ($_ = &l00httpd::l00freadLine($ctrl)) {
                s/\r//;
                s/\n//;

                push(@newfile, "$_\n");

                # %LINEEVAL~#~s/^(.)/#$1/%
                if (/^\%LINEEVAL~(.+?)~(.+)\%$/) {
                    if ($1 eq 'copy2clipboard') {
                        # remember the user copy2clipboard regex
                        $copy2clipboard = $2;
                    } else {
                        # don't list the user copy2clipboard regex
                        push(@evals, $1);
                    }
                }
            }

            $lnno = 1;
            print $sock "<pre>\n";
            if (defined($form->{'cmd'}) && ($form->{'cmd'} eq 'mk') &&
                defined($form->{'ln'})) {
                $mvfrom = "&mvfrom=$form->{'ln'}";
            } else {
                $mvfrom = '';
            }

            # compose $ctrl->{'ymddCODE'}
            my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime (time);
            $mon++;
            $year = $year % 20;
            if ($year >= 10) {
                $year = chr(0x61 + ($year - 10));
            }
            $ctrl->{'ymddCODE'} = sprintf ("$year%1x%02d", $mon, $mday);
            #printf $sock ("$ctrl->{'ymddCODE'}\n");

            foreach $_ (@newfile) {
                s/\r//;
                s/\n//;

                if (($lnno & 1) == 0) {
                    print $sock "<font style=\"color:black;background-color:lightGray\">";
                }
                printf $sock ("<a name=\"line$lnno\"></a><a href=\"/lineeval.htm?path=$form->{'path'}&anchor=line$lnno#line$lnno\">%4d</a>: ", $lnno);
                print $sock "<a href=\"/lineeval.htm?path=$form->{'path'}&run=run&cmd=rm&ln=$lnno&anchor=$anchor#$anchor\">rm</a> ";
                print $sock "<a href=\"/lineeval.htm?path=$form->{'path'}&cmd=mk&ln=$lnno&anchor=$anchor#$anchor\">mk</a> ";
                if ($mvfrom ne '') {
                    print $sock "<a href=\"/lineeval.htm?path=$form->{'path'}&run=run&cmd=mv&mvto=$lnno$mvfrom&anchor=$anchor#$anchor\">mv</a> ";
                } else {
                    print $sock "mv ";
                }
                for ($tmp = 0; $tmp <= $#evals; $tmp++) {
                    if ($useform eq 'checked') {
                        print $sock "<input type=\"checkbox\" name=\"chk_evalid_${tmp}__ln_${lnno}\">";
                    }
                    print $sock "<a href=\"/lineeval.htm?path=$form->{'path'}&run=run&cmd=eval&evalid=$tmp&ln=$lnno&anchor=$anchor#$anchor\">$evals[$tmp]</a> ";
                }
                if (($lnno & 1) == 0) {
                    print $sock "</font>";
                }
                if (/$copy2clipboard/) {
                    # paste the user regex string
                    $clipexp =  &l00httpd::urlencode ($1);
                } else {
                    $clipexp =  &l00httpd::urlencode ($_);
                }
                $clipurl = "<a href=\"/clip.htm?update=Copy+to+CB&clip=$clipexp\" target=\"_blank\">:</a>";
                if (defined($form->{'cmd'}) && ($form->{'cmd'} eq 'mk') &&
                    defined($form->{'ln'})  && ($form->{'ln'} == $lnno)) {
                    print $sock "$clipurl <font style=\"color:black;background-color:lime\">$_</font>\n";
                } else {
                    if (($longgray eq 'checked') && (($lnno & 1) == 0)) {
                        print $sock "<font style=\"color:black;background-color:WhiteSmoke\">";
                        print $sock "$clipurl $_\n";
                        print $sock "</font>";
                    } else {
                        print $sock "$clipurl $_\n";
                    }
                }

                $lnno++;
            }
            print $sock "</pre>\n";
        }
    }

    if ($useform eq 'checked') {
        print $sock "</form>\n";
    }


    print $sock "<a name=\"__end__\"></a><br>\n";
    print $sock "<a href=\"#__top__\">Jump to top</a> - \n";
    print $sock "<a href=\"#__print__\">print</a> - \n";
    print $sock "<a href=\"#__out__\">output</a>\n";


    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
