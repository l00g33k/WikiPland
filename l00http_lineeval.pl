#use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# do %TXTDOPL% in .txt
my ($arg, $eval, $sort, $sortdec, $wholefile);
$arg = '';
$eval = '';
$sort = '';
$sortdec = '';
$wholefile = '';

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
    my ($pname, $fname);

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
        print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\" target=\"_blank\">Path</a>: ";
        if (($pname, $fname) = $form->{'path'} =~ /^(.+\/)([^\/]+)$/) {
            # not ending in / or \, not a dir
            print $sock "<a href=\"/ls.htm?path=$pname\">$pname</a>";
            print $sock "<a href=\"/ls.htm?path=$form->{'path'}\">$fname</a>\n";
        } else {
            print $sock " <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a>\n";
        }
        print $sock " - <a href=\"/lineeval.htm?path=$form->{'path'}\">refresh</a>";
    }

    print $sock "<form action=\"/lineeval.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"text\" size=\"24\" name=\"path\" value=\"$pname$fname\">\n";
    print $sock "            <input type=\"submit\" name=\"run\" value=\"Set\"></td>\n";
    print $sock "    </tr>\n";

    print $sock "</table>\n";
    print $sock "</form>\n";


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
                    push(@evals, $2);
                }

                $lnno++;
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

            if (defined($form->{'cmd'}) && ($form->{'cmd'} eq 'eval') &&
                defined($form->{'ln'}) && defined($form->{'evalid'})) {
#print $sock "subst with $form->{'evalid'} $evals[$form->{'evalid'}] on line $form->{'ln'}<br>\n";
                $_ = $newfile[$form->{'ln'} - 1];
                eval $evals[$form->{'evalid'}];
                $newfile[$form->{'ln'} - 1] = $_;
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
                    push(@evals, $1);
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

            foreach $_ (@newfile) {
                s/\r//;
                s/\n//;

                printf $sock ("%4d: ", $lnno);
                print $sock "<a href=\"/lineeval.htm?path=$form->{'path'}&cmd=mk&ln=$lnno\">mk</a> ";
                if ($mvfrom ne '') {
                    print $sock "<a href=\"/lineeval.htm?path=$form->{'path'}&run=run&cmd=mv&mvto=$lnno$mvfrom\">mv</a> ";
                } else {
                    print $sock "mv ";
                }
                for ($tmp = 0; $tmp <= $#evals; $tmp++) {
                    print $sock "<a href=\"/lineeval.htm?path=$form->{'path'}&run=run&cmd=eval&evalid=$tmp&ln=$lnno\">$evals[$tmp]</a> ";
                }
                if (defined($form->{'cmd'}) && ($form->{'cmd'} eq 'mk') &&
                    defined($form->{'ln'})  && ($form->{'ln'} == $lnno)) {
                    print $sock ": <font style=\"color:black;background-color:lime\">$_</font>\n";
                } else {
                    print $sock ": $_\n";
                }

                $lnno++;
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
