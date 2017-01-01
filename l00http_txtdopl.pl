use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# do %TXTDOPL% in .txt
my ($sel, $arg);
$sel = '';
$arg = '';

my %config = (proc => "l00http_txtdopl_proc",
              desc => "l00http_txtdopl_desc");


sub l00http_txtdopl_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "txtdopl: Perl 'do' %TXTDOPL% in file";
}

sub l00http_txtdopl_proc (\%) {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($dopl, $dolncnt, $dorst, $newfile, $oldfile);
    my ($last, $this, $next, $perl, $perladd);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>txtdopl</title>" . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} \n";
    print $sock "<a name=\"__top__\"></a>";
    if (defined ($form->{'path'})) {
        print $sock "Path: <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a>\n";
    }
    print $sock "<a href=\"#__end__\">Jump to end</a><br>\n";

    if (defined ($form->{'sel'})) {
        # selecting %TXTDOPLspecial%
        $sel = $form->{'sel'};
    }

    if (defined ($form->{'arg'})) {
        $arg = $form->{'arg'};
    }

    print $sock "<form action=\"/txtdopl.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"runbare\" value=\"RunBare\"></td>\n";
    print $sock "        <td><input type=\"submit\" name=\"run\" value=\"Run\"></td>\n";
    print $sock "        <td>arg: <input type=\"text\" size=\"4\" name=\"arg\" value=\"$arg\"></td>\n";
    print $sock "    </tr>\n";
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"refresh\" value=\"Refresh\"></td>\n";
    print $sock "        <td>tag: <input type=\"text\" size=\"4\" name=\"sel\" value=\"$sel\"></td>\n";
    print $sock "        <td>&nbsp;</td>\n";
    print $sock "    </tr>\n";
    print $sock "</table>\n";
    print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "</form>\n";

    if ((defined ($form->{'path'})) && 
        (defined ($form->{'run'}) || defined ($form->{'runbare'}))) {
        if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
            $dopl = "$ctrl->{'plpath'}.l00_txtdopl.tmp";
            open (OU, ">$dopl");
            print OU "#$dopl: extracted from: $form->{'path'}\n";
            $dolncnt = -1;
            $oldfile = '';
            print "txtdopl: sel=>$sel<\n", if ($ctrl->{'debug'} >= 3);
            while ($_= &l00httpd::l00freadLine($ctrl)) {
                s/\r//;
                $oldfile .= $_;
                if (/^\%TXTDOPL$sel\%/) {
                    if ($dolncnt == -1) {
                        # start collecting first do line
                        $dolncnt = 0;
                        next;
                    } else {
                        # end collecting do lines
                        print $sock "Parsed $dolncnt line of Perl code\n<br>";
                        # stop collecting do lines
                        $dolncnt = -1;
                    }
                } elsif (/^\%TXTDOPL.*\%/) {
                    # %TXTDOPLother% not selected
                    while ($_= &l00httpd::l00freadLine($ctrl)) {
                        s/\r//;
                        $oldfile .= $_;
                        # skip not selected do lines
                        if (/^\%TXTDOPL.*\%/) {
                            last;
                        }
                    }
                } elsif ($dolncnt >= 0) {
                    # continue to collect do line
                    print OU "$_";
                    $dolncnt++;
                }
            }
            close (OU);
            close (IN);
            $dorst = do $dopl;
            if (!defined ($dorst)) {
                if ($!) {
                    print $sock "<hr>Can't read module: $dopl: $!\n";
                } elsif ($@) {
                    print $sock "<hr>Can't parse module: $@\n";
                }
            } else {
                print $sock "<pre>\n";
                open (TXTDOPLIN, "<$form->{'path'}");
                $dolncnt = 0;
                $newfile = '';
                $perl = '';
                $perladd = 0;
                undef $last;
                undef $this;
                undef $next;
                while (<TXTDOPLIN>) {
                    s/\r//;
                    $dolncnt++;
                    if (/^\%TXTDOPL$sel\%/) {
                        $perl .= $_;
                        while (<TXTDOPLIN>) {
                            s/\r//;
                            $dolncnt++;
                            $perl .= $_;
                            if (/^\%TXTDOPL$sel\%/) {
                                $_ = <TXTDOPLIN>;
                                s/\r//;
                                $dolncnt++;
                                $perladd = 1;
                                last;
                            }
                        }
                    } elsif (/^\%TXTDOPL.*\%/) {
                        # %TXTDOPLother% not selected
                        $perl .= $_;
                        while (<TXTDOPLIN>) {
                            s/\r//;
                            $perl .= $_;
                            # skip not selected do lines
                            if (/^\%TXTDOPL.*\%/) {
                                $_ = <TXTDOPLIN>;
                                s/\r//;
                                $perladd = 1;
                                last;
                            }
                        }
                    }
                    s/\n//g;
                    s/\r//g;
                    if (!defined ($next)) {
                        $next = $_;
                    } elsif (!defined ($this)) {
                        $this = $next;
                        $next = $_;
                        $newfile .= &txtdopl ($sock, $ctrl, $dolncnt - 1, $last, $this, $next) . "\n";
                    } else {
                        $last = $this;
                        $this = $next;
                        $next = $_;
                        $newfile .= &txtdopl ($sock, $ctrl, $dolncnt - 1, $last, $this, $next) . "\n";
                    }
                    if ($perladd > 0) {
                        $perladd = 0;
                        $newfile .= $perl;
                        $perl = '';
                    }
                }
                $newfile .= &txtdopl ($sock, $ctrl, $dolncnt - 1, $this, $next, undef) . "\n";
                close (TXTDOPLIN);
                if ($newfile ne $oldfile) {
                    # write new file only if changed
                    &l00backup::backupfile ($ctrl, $form->{'path'}, 1, 5);
                    open (OU, ">$form->{'path'}");
                    print OU $newfile;
                    close (OU);
                }
                print $sock "</pre>\n";
            }
        }
    }

    if ((defined ($form->{'run'})) && (defined ($form->{'path'}))) {
        if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
            print $sock "<hr><pre>\n";
            while ($_= &l00httpd::l00freadLine($ctrl)) {
                print $sock "$_";
            }
            print $sock "</pre>\n";
            close (IN);
        }
    }
    print $sock "<a href=\"#__top__\">Jump to top</a>\n";
    print $sock "<a name=\"__end__\"></a><br>\n";


    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
