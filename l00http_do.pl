#use strict;
#use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# Copy to Android 

my %config = (proc => "l00http_do_proc",
              desc => "l00http_do_desc");

sub l00http_do_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "do: Perl 'do' the destination file";
}

my ($arg1, $arg2, $arg3, $doplpath, $doplpathset, $hide, $bare);
$arg1 = '';
$arg2 = '';
$arg3 = '';
$doplpath = '';
$doplpathset = 0;
$hide = '';
$bare = '';

sub l00http_do_proc {
    my ($main);
    ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($rethash, $mypath, $refresh, $refreshtag, $fname);
    my ($doplpathnow, $overwrite $flags);

    print "MOD: $config{'desc'}: Entered do\n", if ($debug >= 5);


    $refresh = '';
    $refreshtag = '';
    if (defined ($form->{'refresh'})) {
        if ($form->{'refresh'} =~ /(\d+)/) {
            $refresh = $1;
            $refreshtag = "<meta http-equiv=\"refresh\" content=\"$refresh\"> ";
        }
    }
    if (defined ($form->{'stoprefresh'})) {
        $refresh = '';
        $refreshtag = '';
    }
    if (defined ($form->{'arg1'})) {
        $arg1 = $form->{'arg1'};
    }
    if (defined ($form->{'arg2'})) {
        $arg2 = $form->{'arg2'};
    }
    if (defined ($form->{'arg3'})) {
        $arg3 = $form->{'arg3'};
    }
    $hide = '';
    if ((defined ($form->{'hide'})) && ($form->{'hide'} eq 'on')) {
        $hide = 'checked';
    }
    $bare = '';
    if ((defined ($form->{'bare'})) && ($form->{'bare'} eq 'on')) {
        $bare = 'checked';
    }
    $overwrite = 0;
    if ((defined ($form->{'overwrite'})) && ($form->{'overwrite'} eq 'on')) {
        $overwrite = 1;
        $form->{'path'} = $form->{'arg1'};
    }


    # push args
    if (defined ($form->{'pushcb'})) {
        $arg3 = $arg2;
        $arg2 = $arg1;
        $arg1 = &l00httpd::l00getCB($ctrl);
    }
 
    $mypath = $form->{'path'};

    if ((defined ($form->{'set'})) &&
        (defined ($form->{'path'}))) {
        $doplpath = $form->{'path'};
        $doplpathset = 1;
    }
    if (defined ($form->{'clear'})) {
        $doplpath = '';
        $doplpathset = 0;
    }

    # handling Quick URL
    if ($doplpathset && ($overwrite == 0)) {
        $form->{'arg1'} = $mypath;
        $doplpathnow = $doplpath;
    } else {
        $doplpathnow = $mypath;
    }

    # Send HTTP and HTML headers
    if ($bare ne 'checked') {
		if (!(($fname) = $doplpathnow =~ /([^\/]+)$/)) {
		    $fname = '(none)';
		}
        if ($hide ne 'checked') {
            print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>$fname - do</title>\n" . $refreshtag . $ctrl->{'htmlhead2'};
            if ($refresh eq '') {
                print $sock "<a name=\"top\"></a>\n";
                print $sock "$ctrl->{'home'} $ctrl->{'HOME'} \n";
                print $sock "<a href=\"#end\">Jump to end</a>\n";
                print $sock "<a href=\"/edit.htm?path=$doplpathnow\">Ed</a>\n";
                print $sock "<a href=\"/view.htm?path=$doplpathnow\">Vw</a>\n";
            }
        } else {
            print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>$fname - do</title>\n" . $refreshtag . $ctrl->{'htmlhead2'};
        }
    }

    if ((!($doplpathnow =~ m|/|)) && (!($doplpathnow =~ m|\\|))) {
        # try default path
        $doplpathnow = $ctrl->{'plpath'} . $doplpathnow;
    }

    if ($bare ne 'checked') {
        if (($refresh eq '') && ($hide ne 'checked')) {
            print $sock "<form action=\"/do.htm\" method=\"get\">\n";
            print $sock "<input type=\"submit\" name=\"do\" value=\"Do&#818;\" accesskey=\"o\">\n";
            if ($doplpathset && ($overwrite == 0)) {
                print $sock "Arg1:<input type=\"text\" name=\"arg1\" size=\"6\" value=\"$form->{'arg1'}\"> \n";
                print $sock "<input type=\"hidden\" name=\"path\" value=\"$doplpath\">\n";
            } else {
                print $sock "Path:<input type=\"text\" name=\"path\" size=\"6\" value=\"$mypath\"> \n";
            }
            print $sock "<input type=\"text\" name=\"refresh\" size=\"2\" value=\"$refresh\"> sec. \n";
            print $sock "<input type=\"checkbox\" name=\"overwrite\">Arg1 overwrites path<br>\n";
            print $sock "</form>\n";
            if ($doplpathset && ($overwrite == 0)) {
                print $sock "<font style=\"color:black;background-color:lime\">Using Quick URL</font>: $doplpath<p>\n";
            }
        }
    }


    print "MOD: $config{'desc'}: invoking do\n", if ($debug >= 5);
    $rethash  = do $doplpathnow;
    print "MOD: $config{'desc'}: returned do\n", if ($debug >= 5);
    if (!defined ($rethash)) {
        if ($!) {
            print $sock "<hr>Can't read module: $doplpathnow: $!\n";
        } elsif ($@) {
            print $sock "<hr>Can't parse module: $@\n";
        }
    } else {
        # default to disabled to non local clients^M
        if ($rethash =~ /[a-zA-Z]+/ms) {
            $flags = 0;
            if (defined($ctrl->{'wikihtmlflags'}) && 
                ($ctrl->{'wikihtmlflags'} =~ /(\d+)/)) {
                $flags = $1;
            }
            # wikitize output if return has alphabet instead numeric only
            print $sock &l00wikihtml::wikihtml ($ctrl, "", $rethash, $flags);
        }
        if ($bare ne 'checked') {
            print $sock "<hr>Run completed<br>\n";
        }
    }
    if ($bare ne 'checked') {
        if ($hide ne 'checked') {
            print $sock "<p>'sec': insert HTML tag to automatically reload the page at specified seconds interval.<br><a href=\"#top\">Jump to top</a><p>\n";

            print $sock "<form action=\"/do.htm\" method=\"get\">\n";
            print $sock "<input type=\"submit\" name=\"do\" value=\"Do m&#818;ore\" accesskey=\"m\">\n";
            if ($refresh ne '') {
                print $sock "<input type=\"submit\" name=\"stoprefresh\" value=\"Stop\">\n";
            }
            print $sock "Path:<input type=\"text\" name=\"path\" size=\"6\" value=\"$mypath\"> \n";
            print $sock "<input type=\"text\" name=\"refresh\" size=\"2\" value=\"$refresh\"> sec.\n";
            print $sock "<input type=\"checkbox\" name=\"hide\" $hide>Hide form.\n";
            print $sock "<input type=\"checkbox\" name=\"bare\" $bare>bare<br>\n";
            print $sock "Ar&#818;g1: <input type=\"text\" name=\"arg1\" size=\"12\" value=\"$arg1\" accesskey=\"r\"> \n";
            print $sock "Arg2&#818;: <input type=\"text\" name=\"arg2\" size=\"12\" value=\"$arg2\" accesskey=\"2\"> \n";
            print $sock "Arg3&#818;: <input type=\"text\" name=\"arg3\" size=\"12\" value=\"$arg3\" accesskey=\"3\"> \n";
            print $sock "</form>\n";
        }

        if ($hide ne 'checked') {
            if ($doplpathset && ($overwrite == 0)) {
                print $sock "Quick URL is active. Full URL is:<br>\n";
                $tmp = "/do.htm?do=Do+more&path=$doplpath&arg1=$form->{'arg1'}";
                print $sock "<a href=\"$tmp\">$tmp</a><br>\n";
            }

            print $sock "<form action=\"/do.htm\" method=\"get\">\n";
            print $sock "<input type=\"submit\" name=\"pushcb\" value=\"CB\">\n";
            print $sock "-&gt; Arg1 -&gt; Arg2 -&gt; Arg3<p>\n";
            print $sock "<input type=\"submit\" name=\"clear\" value=\"Clear\">\n";
            print $sock "<input type=\"submit\" name=\"set\" value=\"Set\">\n";
            print $sock "Quick URL to: $form->{'path'}\n";
            print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
            print $sock "</form>\n";
        } else {
            if ($hide eq 'checked') {
                print $sock "$ctrl->{'home'} $ctrl->{'HOME'} \n";
                print $sock "<a href=\"#end\">Jump to end</a>\n";
                print $sock "<a href=\"/edit.htm?path=$doplpathnow\">Ed</a>\n";
                print $sock "<a href=\"/view.htm?path=$doplpathnow\">Vw</a>\n";
                print $sock "<a href=\"/do.htm?path=$doplpathnow\">form</a>\n";
            }
            if ($doplpathset && ($overwrite == 0)) {
                print $sock "Quick URL is active. Full URL is:<br>\n";
                $tmp = "/do.htm?do=Do+more&path=$doplpath&arg1=$form->{'arg1'}";
                print $sock "<a href=\"$tmp\">$tmp</a><br>\n";

                print $sock "<form action=\"/do.htm\" method=\"get\">\n";
                print $sock "<input type=\"submit\" name=\"set\" value=\"Set\">\n";
                print $sock "Quick URL to: $form->{'path'}\n";
                print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
                print $sock "</form>\n";
            }
        }


        print $sock "<a name=\"end\"></a>\n";

        # send HTML footer and ends
        print $sock $ctrl->{'htmlfoot'};
    }
}


\%config;
