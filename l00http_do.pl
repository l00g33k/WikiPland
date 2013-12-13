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

my ($arg1, $arg2, $arg3);

sub l00http_do_proc {
    my ($main);
    ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($rethash, $mypath, $refresh, $refreshtag, $notbare, $fname);

    $notbare = 1;
    if (defined ($form->{'bare'})) {
        $notbare = 0;
    }

    $refresh = '';
    $refreshtag = '';
    if (defined ($form->{'refresh'})) {
        if ($form->{'refresh'} =~ /(\d+)/) {
            $refresh = $1;
            $refreshtag = "<meta http-equiv=\"refresh\" content=\"$refresh\"> ";
        }
    }
#    $arg1 = '';
#    $arg2 = '';
#    $arg3 = '';
    if (defined ($form->{'arg1'})) {
        $arg1 = $form->{'arg1'};
    }
    if (defined ($form->{'arg2'})) {
        $arg2 = $form->{'arg2'};
    }
    if (defined ($form->{'arg3'})) {
        $arg3 = $form->{'arg3'};
    }
 
    $mypath = $form->{'path'};

    # Send HTTP and HTML headers
    if ($notbare) {
		if (!(($fname) = $mypath =~ /([^\/]+)$/)) {
		    $fname = '(none)';
		}
        print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>$fname - do</title>\n" . $refreshtag . $ctrl->{'htmlhead2'};
        if ($refresh eq '') {
            print $sock "<a name=\"top\"></a>\n";
            print $sock "$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">Quick</a> \n";
            print $sock "<a href=\"#end\">Jump to end</a>\n";
            print $sock "<a href=\"/edit.htm?path=$mypath\">Edit</a>\n";
        }
    }

    if ((!($mypath =~ m|/|)) && (!($mypath =~ m|\\|))) {
        # try default path
        $mypath = $ctrl->{'plpath'} . $mypath;
    }

    if ($notbare) {
        if ($refresh eq '') {
            print $sock "<form action=\"/do.htm\" method=\"get\">\n";
            print $sock "<input type=\"submit\" name=\"do\" value=\"Do\">\n";
            print $sock "Path:<input type=\"text\" name=\"path\" size=\"6\" value=\"$mypath\"> \n";
            print $sock "<input type=\"text\" name=\"refresh\" size=\"2\" value=\"$refresh\"> sec<br>\n";
            print $sock "</form>\n";
        }
    }

#`"busybox wget -O /sdcard/l00httpd/del/405S.htm \"http://107.22.209.201/W/RoadDetails.asp?nav=prev&road=104052&p=7.74010&lat=33.699693&lon=-117.800023&z=1\""`;
#`"busybox wget -O /sdcard/l00httpd/del/405S.htm \"http://107.22.209.201\""`;

    $rethash  = do $mypath;
    if (!defined ($rethash)) {
        if ($!) {
            print $sock "<hr>Can't read module: $mypath: $!\n";
        } elsif ($@) {
            print $sock "<hr>Can't parse module: $@\n";
        }
    } else {
        # default to disabled to non local clients^M
        if ($notbare) {
            print $sock "<hr>Run completed\n";
        }
    }
    if ($notbare) {
        print $sock "<p>'sec': insert HTML tag to automatically reload the page at specified seconds interval.<br><a href=\"#top\">Jump to top</a><p>\n";

        print $sock "<form action=\"/do.htm\" method=\"get\">\n";
        print $sock "<input type=\"submit\" name=\"do\" value=\"Do more\">\n";
        print $sock "Path:<input type=\"text\" name=\"path\" size=\"6\" value=\"$mypath\"> \n";
        print $sock "<input type=\"text\" name=\"refresh\" size=\"2\" value=\"$refresh\"> seci<br>\n";
        print $sock "Arg1: <input type=\"text\" name=\"arg1\" size=\"12\" value=\"$arg1\"> \n";
        print $sock "Arg2: <input type=\"text\" name=\"arg2\" size=\"12\" value=\"$arg2\"> \n";
        print $sock "Arg3: <input type=\"text\" name=\"arg3\" size=\"12\" value=\"$arg3\"> \n";
        print $sock "</form>\n";

        print $sock "<a name=\"end\"></a>\n";

        # send HTML footer and ends
        print $sock $ctrl->{'htmlfoot'};
    }
}


\%config;
