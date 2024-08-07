#use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# do %TXTDOPL% in .txt
my ($arg, $eval, $sort, $sortdec, $wholefile, $useform, $filter, $only, $filterregex);
my ($lineevalst, $lineevalen, $lineevalln, @actionBkgn, @textBkgn);
$arg = '';
$eval = '';
$sort = '';
$sortdec = '';
$wholefile = '';
$useform = '';
$lineevalst = 0;
$lineevalen = 0;
$lineevalln = 0;
$filter = '';
$only = '';
$filterregex = '';

@textBkgn   = (
    '#F8F8F8', 
    '#D8FFD8', 
    '#FFD8FF', 
    '#D8FFFF', 
    '#F0F0D8', 
    '#FFFFFF', 
    '#D8F0D8', 
    '#F0D8F0', 
    '#D8F0F0', 
    '#FFFFD8'
);
@actionBkgn = (
    '#FFFFFF', 
    '#B0F0B0', 
    '#F0B0F0', 
    '#B0F0F0', 
    '#FFFFBF', 
    '#F0F0F0', 
    '#B0FFBF', 
    '#FFBFFF', 
    '#B0FFFF', 
    '#F0F0B0'
);


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
    my (@newfile, $lnno, $mvfrom, $tmp, $tabindex, @evals, $ii, $bkgn, $filterone, $filterhit);
    my ($pname, $fname, $anchor, $clipurl, $clipexp, $copy2clipboard, $includefile, $pnameup);

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
        if (!defined($form->{'useform'})) {
            $useform = '';
        }
        if ((defined($form->{'useform'}))
            && ($form->{'useform'} ne 'keep')) {
            $useform = '';
            if (defined ($form->{'useform'}) && ($form->{'useform'} eq 'on')) {
                $useform = 'checked';
            }
        }

        # restricting display range
        if (defined ($form->{'rngst'}) && 
            ($form->{'rngst'} =~ /(\d+)/)) {
            $lineevalst = $1;
        } else {
            $lineevalst = 0;
        }
        if (defined ($form->{'rngen'}) && 
            ($form->{'rngen'} =~ /(\d+)/)) {
            $lineevalen = $1;
        } else {
            $lineevalen = 0;
        }
        if (defined ($form->{'rngln'}) && 
            ($form->{'rngln'} =~ /(\d+)/)) {
            $lineevalln = $1;
        } else {
            $lineevalln = 0;
        }
        if (($lineevalst == 0) || ($lineevalen == 0)) {
            $lineevalst = 0;
            $lineevalen = 0;
        }

        $only = '';
        $filter = '';
        if (defined ($form->{'only'}) && ($form->{'only'} eq 'on')) {
            $only = 'checked';
        } elsif (defined ($form->{'filter'}) && ($form->{'filter'} eq 'on')) {
            $filter = 'checked';
        }


        if (defined ($form->{'filterregex'})) {
            $filterregex = $form->{'filterregex'};
        } else {
            $filterregex = '';
        }
    }

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
            print $sock "<a href=\"/ls.htm?path=$form->{'path'}\">$fname</a>\n";
        } else {
            print $sock " <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a>\n";
        }
        print $sock " - <a href=\"/view.htm?path=$form->{'path'}\">view</a>";
        print $sock " - <a href=\"/lineeval.htm?path=$form->{'path'}\">refresh</a>";
    }

    print $sock "<a name=\"#__top__\"></a>\n";
    print $sock "<form action=\"/lineeval.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"text\" size=\"24\" name=\"path\" value=\"$pname$fname\">\n";
    print $sock "            <input type=\"submit\" name=\"run\" value=\"S&#818;et\" accesskey=\"s\">\n";
    print $sock "            <input type=\"checkbox\" name=\"useform\" $useform accesskey=\"f\">Use f&#818;orm</td>\n";
    print $sock "    </tr>\n";

    print $sock "    <tr>\n";
    print $sock "        <td>\n";
    if ($lineevalst == 0) {
        $_ = '';
    } else {
        $_ = $lineevalst;
    }
    print $sock "            Range start: <input type=\"text\" size=\"6\" name=\"rngst\" value=\"$_\">\n";
    if ($lineevalen == 0) {
        $_ = '';
    } else {
        $_ = $lineevalen;
    }
    print $sock "            end: <input type=\"text\" size=\"6\" name=\"rngen\" value=\"$_\">\n";
    if ($useform ne 'checked') {
        print $sock "            <a href=\"/lineeval.htm?rngst=&rngen=&run=run&path=$form->{'path'}&run=run&cmd=\">clr</a>";
    } else {
        print $sock "            <a href=\"/lineeval.htm?rngst=&rngen=&run=run&path=$form->{'path'}&run=run&cmd=&useform=on\">clr</a>";
    }
    print $sock "        </td>\n";
    print $sock "    </tr>\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"checkbox\" name=\"filter\" $filter accesskey=\"\">Ex&#818;clude/\n";
    print $sock "            <input type=\"checkbox\" name=\"only\" $only accesskey=\"\">O&#818;nly regex ||\n";
    print $sock "            <input type=\"text\" size=\"24\" name=\"filterregex\" value=\"$filterregex\"></td>\n";
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
            $includefile = '';
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

                # %INCLUDE<./xxx.txt>%
                if (/%INCLUDE<(.+?)>%/) {
                    $includefile = $1;
                    # subst %INCLUDE<./xxx.txt> as 
                    #       %INCLUDE</absolute/path/xxx.txt>
                    $includefile =~ s/^\.[\\\/]/$pname/;
                    # drop last directory from $pname for:
                    # subst %INCLUDE<../xxx.txt> as 
                    #       %INCLUDE</absolute/path/../xxx.txt>
                    $pnameup = $pname;
                    $pnameup =~ s/([\\\/])[^\\\/]+[\\\/]$/$1/;
                    $includefile =~ s/^\.\.\//$pnameup\//;
                }

                $lnno++;
            }
            # handle include
            if (($includefile ne '') && 
                (&l00httpd::l00freadOpen($ctrl, $includefile))) {
                while ($_ = &l00httpd::l00freadLine($ctrl)) {
                    s/\r//;
                    s/\n//;
                    # %LINEEVAL~#~s/^(.)/#$1/%
                    if (/^\%LINEEVAL~(.+?)~(.+)\%$/) {
                        if ($1 ne 'copy2clipboard') {
                            # don't list the user copy2clipboard regex
                            push(@evals, $2);
                        }
                    }
                }
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

            # add default eval (x and #) if missing
            $ii = 1;
            for ($tmp = 0; $tmp <= $#evals; $tmp++) {
                if ($evals[$tmp] eq 's/^#//') {
                    $ii = 0;
                    last;
                }
            }
            if ($ii) {
                push(@evals, 's/^#//');
            }
            $ii = 1;
            for ($tmp = 0; $tmp <= $#evals; $tmp++) {
                if ($evals[$tmp] eq 's/^(.)/#$1/') {
                    $ii = 0;
                    last;
                }
            }
            if ($ii) {
                push(@evals, 's/^(.)/#$1/');
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
            $includefile = '';
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
                # %INCLUDE<./xxx.txt>%
                if (/%INCLUDE<(.+?)>%/) {
                    $includefile = $1;
                    # subst %INCLUDE<./xxx.txt> as 
                    #       %INCLUDE</absolute/path/xxx.txt>
                    $includefile =~ s/^\.[\\\/]/$pname/;
                    # drop last directory from $pname for:
                    # subst %INCLUDE<../xxx.txt> as 
                    #       %INCLUDE</absolute/path/../xxx.txt>
                    $pnameup = $pname;
                    $pnameup =~ s/([\\\/])[^\\\/]+[\\\/]$/$1/;
                    $includefile =~ s/^\.\.\//$pnameup\//;
                }
            }
            # handle include
            if (($includefile ne '') && 
                (&l00httpd::l00freadOpen($ctrl, $includefile))) {
                while ($_ = &l00httpd::l00freadLine($ctrl)) {
                    s/\r//;
                    s/\n//;
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
            }

            if ((($lineevalst == 0) || ($lineevalen == 0)) 
                && ($#newfile > 50)) {
                print $sock "jump to line: ";
                for ($ii = 50; $ii < $#newfile; $ii += 50) {
                    print $sock "<a href=\"#line$ii\">$ii</a> - ";
                }
            }

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
            for ($ii = 0; $ii < 15; $ii++) {
                my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime (time + $ii * 24 * 3600);
                $mon++;
                $year = $year % 20;
                if ($year >= 10) {
                    $year = chr(0x61 + ($year - 10));
                }
                $ctrl->{"ymddCODE$ii"} = sprintf ("$year%1x%02d", $mon, $mday);
            }
            #printf $sock ("$ctrl->{'ymddCODE'}\n");

            $lnno = 0;

            foreach $_ (@newfile) {
                s/\r//;
                s/\n//;
                $lnno++;

                if (($lineevalst > 0) && ($lineevalst <= $lineevalen)) {
                    # restricting display range
                    if (($lnno < $lineevalst) || ($lnno > $lineevalen)) {
                        next;
                    }
                }
                if (($filter eq 'checked') && ($filterregex ne '')) {
                    # if exclude filter in effect, skip if hit
                    $filterhit = 0;
                    foreach $filterone (split('\|\|', $filterregex)) {
                        if (/$filterone/) {
                            $filterhit = 1;
                            last;
                        }
                    }
                    if ($filterhit) {
                        next;
                    }
                }
                if (($only eq 'checked') && ($filterregex ne '')) {
                    # if only filter in effect, skip if no hit
                    $filterhit = 1;
                    foreach $filterone (split('\|\|', $filterregex)) {
                        if (/$filterone/) {
                            $filterhit = 0;
                            last;
                        }
                    }
                    if ($filterhit) {
                        next;
                    }
                }

                if ($lnno == $lineevalln) {
                    print $sock "<font style=\"color:black;background-color:lime\">";
                } else {
                    $bkgn = $actionBkgn[$lnno % ($#actionBkgn + 1)];
                    print $sock "<font style=\"color:black;background-color:$bkgn\">";

#                    if (($lnno & 1) == 0) {
#                        print $sock "<font style=\"color:black;background-color:lightGray\">";
#                    } else {
#                        print $sock "<font style=\"color:black;background-color:white\">";
#                    }
                }
                printf $sock ("<a name=\"line$lnno\"></a><a href=\"/lineeval.htm?rngst=$lineevalst&rngen=$lineevalen&run=run&path=$form->{'path'}&anchor=line$lnno#line$lnno\">%4d</a> ", $lnno);
                printf $sock ("<a href=\"/edit.htm?path=$form->{'path'}#line$lnno\">ed</a> ");
                print $sock "<a href=\"#__top__\">^</a> ";
                print $sock "<a href=\"/lineeval.htm?rngst=$lineevalst&rngen=$lineevalen&run=run&path=$form->{'path'}&run=run&cmd=rm&ln=$lnno&anchor=$anchor#$anchor\">rm</a> ";
                print $sock "<a href=\"/lineeval.htm?rngst=$lineevalst&rngen=$lineevalen&run=run&path=$form->{'path'}&cmd=mk&ln=$lnno&anchor=$anchor#$anchor\">mk</a> ";
                if ($mvfrom ne '') {
                    print $sock "<a href=\"/lineeval.htm?rngst=$lineevalst&rngen=$lineevalen&run=run&path=$form->{'path'}&run=run&cmd=mv&mvto=$lnno$mvfrom&anchor=$anchor#$anchor\">mv</a> ";
                } else {
                    print $sock "mv ";
                }
                # add default name (x and #) if missing
                $ii = 1;
                for ($tmp = 0; $tmp <= $#evals; $tmp++) {
                    if ($evals[$tmp] eq '(x') {
                        $ii = 0;
                        last;
                    }
                }
                if ($ii) {
                    push(@evals, '(x');
                }
                $ii = 1;
                for ($tmp = 0; $tmp <= $#evals; $tmp++) {
                    if ($evals[$tmp] eq '#)') {
                        $ii = 0;
                        last;
                    }
                }
                if ($ii) {
                    push(@evals, '#)');
                }

                for ($tmp = 0; $tmp <= $#evals; $tmp++) {
                    if ($useform eq 'checked') {
                        # use checkbox
                        $tabindex = $tmp + 1;
                        print $sock "<input type=\"checkbox\" name=\"chk_evalid_${tmp}__ln_${lnno}\" tabindex=\"$tabindex\">$evals[$tmp] ";
                    } else {
                        # no checkbox
                        print $sock "<a href=\"/lineeval.htm?rngst=$lineevalst&rngen=$lineevalen&run=run&path=$form->{'path'}&run=run&cmd=eval&evalid=$tmp&ln=$lnno&anchor=$anchor#$anchor\">$evals[$tmp]</a> ";
                    }
                }
                print $sock "</font>";

                if (/$copy2clipboard/) {
                    # paste the user regex string
                    $clipexp =  &l00httpd::urlencode ($1);
                } else {
                    $clipexp =  &l00httpd::urlencode ($_);
                }
                $clipurl = 
                sprintf ("<a href=\"/clip.htm?update=Copy+to+clipboard&clip=%s\" target=\"_blank\">:</a>", $clipexp);
               #$clipurl = "<a href=\"/edit.htm?path=$form->{'path'}&clip=${lnno}_1\" target=\"_blank\">:</a>";
                if (defined($form->{'cmd'}) && ($form->{'cmd'} eq 'mk') &&
                    defined($form->{'ln'})  && ($form->{'ln'} == $lnno)) {
                    print $sock "$clipurl <font style=\"color:black;background-color:lime\">$_</font>\n";
                } else {
                    $bkgn = $textBkgn[$lnno % ($#textBkgn + 1)];
                    print $sock "<font style=\"color:black;background-color:$bkgn\">";

#                    if (($lnno & 1) == 0) {
#                        print $sock "<font style=\"color:black;background-color:WhiteSmoke\">";
#                    } else {
#                        print $sock "<font style=\"color:black;background-color:white\">";
#                    }
                    print $sock "$clipurl $_\n";
                    print $sock "</font>";
                }
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
