
# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_shell_proc",
              desc => "l00http_shell_desc");
my ($buffer, $out, $cmd, $cnt, $res, $cmdpart, $redirec, $file, $noredirect);
$noredirect = '';

sub l00http_shell_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    " C: shell: Be very careful.  You could brick your phone!";
}

sub l00http_shell_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my (@alllines, $line, $lineno);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} .$ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'}<br>\n";
    print $sock "Warning: you are executing shell commands which could ".
                "cause you to lose data.  You are warned. ".
                "Note: pipe doesn't work, but > and >> are simulated.".
                " Please wait...<p>\n";

    if (defined ($form->{'nodirect'}) && ($form->{'nodirect'} eq 'on')) {
        $noredirect = 'checked';
    } else {
        $noredirect = '';
    }


    $buffer = "";
    $out = "";
    if (defined ($form->{'buffer'})) {
        $buffer = $form->{'buffer'};
        $buffer =~ s/\r//g;
        $cnt = 1;
        foreach $cmd (split ("\n", $buffer)) {
            $out .= "$cnt&gt; $cmd\n";
            $res = "";
            if (($noredirect eq '') &&
                (($cmdpart, $redirec, $file) = ($cmd =~ /^(.+) *(>+) *(.+)$/)))  {
                if (defined ($form->{'exec'})) {
                    $res = `$cmdpart`;
                    open (OUT, "$redirec$file");
                    print OUT $res;
                    close (OUT);
                } else {
                    $res = "NOT EXECUTED: $cmdpart";
                }
            } else {
                if (defined ($form->{'exec'})) {
                    $res = `$cmd`;
                } else {
                    $res = "NOT EXECUTED: $cmdpart";
                }
            }
            $res =~ s/\r//g;
            #$res =~ s/\n/<br>/g;
            $out .= "$res\n";
            $cnt++;
        }
    }
    if (defined ($form->{'clear'})) {
        $buffer = '';
	} elsif ($buffer eq "")  {
        $buffer = "echo a safe examples for Slide\n".
                  "uptime\n\n";
    }

    print $sock "<form action=\"/shell.htm\" method=\"get\">\n";
    print $sock "<textarea name=\"buffer\" cols=\"$ctrl->{'txtw'}\" rows=\"$ctrl->{'txth'}\" accesskey=\"e\">$buffer</textarea>\n";
    print $sock "<p><input type=\"submit\" name=\"exec\" value=\"Ex&#818;ec\" accesskey=\"x\">\n";
    print $sock " <input type=\"submit\" name=\"clear\" value=\"Clear\">\n";
    print $sock " <input type=\"checkbox\" name=\"nodirect\" $noredirect> Do not simulate redirect\n";
    print $sock "</form>\n";

    print $sock "<p><a href=\"/view.htm?path=l00://shell.txt\" target=\"_blank\">Output</a> of shell commands:<p>\n";

    # print output
    print $sock "<pre>$out</pre>\n";

    $out =~ s/&gt;/>/gms;
    $out =~ s/&lt;/</gms;
    &l00httpd::l00fwriteOpen($ctrl, "l00://shell.txt");
    &l00httpd::l00fwriteBuf($ctrl, $out);
    &l00httpd::l00fwriteClose($ctrl);

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
