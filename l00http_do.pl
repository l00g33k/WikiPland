#use strict;
#use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# Copy to Android 

my %config = (proc => "l00http_do_proc",
              desc => "l00http_do_desc");
my($doplpath);
$doplpath = '';

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
    my ($quickon, $doplpathnow);

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

    # a lone /do.htm?path=c:/x/del5.pl sets $doplpath
    if (( defined ($form->{'path'})) &&
        (!defined ($form->{'arg1'})) &&
        (!defined ($form->{'arg2'})) &&
        (!defined ($form->{'arg3'})) &&
        ($form->{'path'} =~ /\.pl$/)) {
        $doplpath = $mypath;
    }

    # handling shortcut
    if ((!($mypath =~ /\.pl$/)) && ($doplpath ne '')) {
        # not supplying a .pl
        # copy path to arg1
        $form->{'arg1'} = $mypath;
        $doplpathnow = $doplpath;
        $quickon = 1;
    } else {
        $doplpathnow = $mypath;
        $quickon = 0;
    }

    # Send HTTP and HTML headers
    if ($notbare) {
		if (!(($fname) = $doplpathnow =~ /([^\/]+)$/)) {
		    $fname = '(none)';
		}
        print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>$fname - do</title>\n" . $refreshtag . $ctrl->{'htmlhead2'};
        if ($refresh eq '') {
            print $sock "<a name=\"top\"></a>\n";
            print $sock "$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">Quick</a> \n";
            print $sock "<a href=\"#end\">Jump to end</a>\n";
            print $sock "<a href=\"/edit.htm?path=$doplpathnow\">Edit</a>\n";
        }
    }

    if ((!($doplpathnow =~ m|/|)) && (!($doplpathnow =~ m|\\|))) {
        # try default path
        $doplpathnow = $ctrl->{'plpath'} . $doplpathnow;
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


    $rethash  = do $doplpathnow;
    if (!defined ($rethash)) {
        if ($!) {
            print $sock "<hr>Can't read module: $doplpathnow: $!\n";
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
        print $sock "<input type=\"text\" name=\"refresh\" size=\"2\" value=\"$refresh\"> sec<br>\n";
        print $sock "Arg1: <input type=\"text\" name=\"arg1\" size=\"12\" value=\"$arg1\"> \n";
        print $sock "Arg2: <input type=\"text\" name=\"arg2\" size=\"12\" value=\"$arg2\"> \n";
        print $sock "Arg3: <input type=\"text\" name=\"arg3\" size=\"12\" value=\"$arg3\"> \n";
        print $sock "</form>\n";

        if ($quickon) {
            print $sock "Quick path is active. Permanent line:<br>\n";
            $tmp = "/do.htm?do=Do+more&path=$doplpath&arg1=$form->{'arg1'}";
            print $sock "<a href=\"$tmp\">$tmp</a><br>\n";
        }

        print $sock "<a name=\"end\"></a>\n";

        # send HTML footer and ends
        print $sock $ctrl->{'htmlfoot'};
    }
}


\%config;
