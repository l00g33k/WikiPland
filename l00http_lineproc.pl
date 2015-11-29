#use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# do %TXTDOPL% in .txt
my ($arg, $debugcheck, $script);
$arg = '';
$debugcheck = '';
$script = 'l00://lineproc.pl';

my %config = (proc => "l00http_lineproc_proc",
              desc => "l00http_lineproc_desc");


sub l00http_lineproc_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "lineproc: Perl 'do' l00://lineproc.pl on target file";
}

sub l00http_lineproc_proc (\%) {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($dopl, $dolncnt, $dorst, $newfile);
    my ($last, $this, $next, $perl, $perladd, $buf, $tmp, $pname, $fname);

    # Send HTTP and HTML headers
    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} - ";
    print $sock "<a href=\"#end\">Jump to end</a>\n";
    print $sock "<a name=\"top\"></a>\n";


    if (defined ($form->{'arg'})) {
        $arg = $form->{'arg'};
    }
    if (defined ($form->{'debug'}) && ($form->{'debug'} eq 'on')) {
        $debugcheck = 'checked';
    } else {
        $debugcheck = '';
    }

    if (defined ($form->{'script'})) {
        $script = $form->{'script'};
    } else {
        $script = 'l00://lineproc.pl';
    }
    if (defined ($form->{'pastescript'})) {
        $script = &l00httpd::l00getCB($ctrl);
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
        print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\" target=\"newclip\">Path</a>: ";
        if (($pname, $fname) = $form->{'path'} =~ /^(.+\/)([^\/]+)$/) {
            # not ending in / or \, not a dir
            print $sock "<a href=\"/ls.htm?path=$pname\">$pname</a>";
            print $sock "<a href=\"/ls.htm?path=$form->{'path'}\">$fname</a>\n";
        } else {
            print $sock " <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a>\n";
        }
    }


    print $sock "<form action=\"/lineproc.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"run\" value=\"Run\">\n";
    print $sock "            <input type=\"checkbox\" name=\"debug\" $debugcheck>debug</td>\n";
    print $sock "    </tr>\n";

    print $sock "    <tr>\n";
    print $sock "        <td>target:<br>\n";
    print $sock "            <textarea name=\"path\" cols=$ctrl->{'txtw'} rows=$ctrl->{'txth'}>$pname$fname</textarea></td>\n";
    print $sock "    </tr>\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"pastescript\" value=\"script\">:<br>\n";
    print $sock "            <textarea name=\"script\" cols=$ctrl->{'txtw'} rows=$ctrl->{'txth'}>$script</textarea></td>\n";
    print $sock "    </tr>\n";

    print $sock "    <tr>\n";
    print $sock "        <td>Arg:\n";
    print $sock "            <input type=\"text\" size=\"10\" name=\"arg\" value=\"$arg\"></td>\n";
    print $sock "    </tr>\n";

    print $sock "</table>\n";
    print $sock "</form>\n";

    print $sock "View: <a href=\"/view.htm?path=$pname$fname\">$pname$fname</a><br>\n";
    print $sock "View: <a href=\"/view.htm?path=$script\">$script</a><br>\n";
    print $sock "Copy: lineproc.pl to <a href=\"/filemgt.htm?path=/sdcard/lineproc.pl&path2=l00://lineproc.pl\">l00://lineproc.pl</a><p>\n";
    print $sock "View: <a href=\"/view.htm?path=l00://lineprocout.txt\">l00://lineprocout.txt</a><br>\n";
    print $sock "Copy: <a href=\"/filemgt.htm?path=l00://lineprocout.txt&path2=$pname$fname\">l00://lineprocout.txt to $pname$fname</a><p>\n";

    if ((defined ($form->{'path'})) && (defined ($form->{'run'}))) {
        if (&l00httpd::l00freadOpen($ctrl, $script)) {
            $buf = &l00httpd::l00freadAll($ctrl);
        } else {
            # create sample script
            $buf = <<samplelineproc;
sub lineproc {
    my (\$sock, \$ctrl, \$arg, \$lnno, \$last, \$this, \$next) = \@_;
    \$this;
}
1;
samplelineproc
            &l00httpd::l00fwriteOpen($ctrl, $script);
            &l00httpd::l00fwriteBuf($ctrl, $buf);
            &l00httpd::l00fwriteClose($ctrl);
        }
        $dopl = "$ctrl->{'plpath'}.l00_lineproc.tmp";
        open (OU, ">$dopl");
        print OU "#$dopl\n$buf\n";
        close (OU);

        $dorst = do $dopl;
        if (!defined ($dorst)) {
            if ($!) {
                print $sock "<hr>Can't read module: $dopl: $!<p>\n";
            } elsif ($@) {
                print $sock "<hr>Can't parse module: $@<p>\n";
            } else {
                print $sock "<hr>Unknown error in $dopl<p>\n";
            }
        } else {
            if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
                $dolncnt = 0;
                $newfile = '';
                $perl = '';
                $perladd = 0;
                undef $last;
                undef $this;
                undef $next;
                if ($debugcheck ne '') {
                    print $sock "Debug output:<br>\n";
                    print $sock "<pre>\n";
                }
                while ($_ = &l00httpd::l00freadLine($ctrl)) {
                    s/\r//;
                    if ($debugcheck ne '') {
                        print $sock "$_";
                    }
                    if (!defined ($next)) {
                        $next = $_;
                    } elsif (!defined ($this)) {
                        $this = $next;
                        $next = $_;
                        $newfile .= &lineproc ($sock, $ctrl, $arg, $dolncnt, $last, $this, $next);
                    } else {
                        $last = $this;
                        $this = $next;
                        $next = $_;
                        $newfile .= &lineproc ($sock, $ctrl, $arg, $dolncnt, $last, $this, $next);
                    }
                    if ($perladd > 0) {
                        $perladd = 0;
                        $newfile .= $perl;
                        $perl = '';
                    }
                    $dolncnt++;
                }
                if ($debugcheck ne '') {
                    print $sock "</pre>\n";
                }
                $newfile .= &lineproc ($sock, $ctrl, $arg, $dolncnt, $this, $next, undef);

                # write new file only if changed
                &l00httpd::l00fwriteOpen($ctrl, 'l00://lineprocout.txt');
                &l00httpd::l00fwriteBuf($ctrl, $newfile);
                &l00httpd::l00fwriteClose($ctrl);
            }
        }
    }

    print $sock "<a href=\"#__top__\">Jump to top</a>\n";
    print $sock "<a name=\"__end__\"></a><br>\n";


    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
