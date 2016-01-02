use strict;
use warnings;
use l00backup;
use l00httpd;
use l00diff;


# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# deletes files for now, rename, move and copy possible

my %config = (proc => "l00http_diff_proc",
              desc => "l00http_diff_desc");


my ($width, $oldfile, $newfile);
my ($hide, $maxline, $debug);
$width = 20;
$oldfile = '';
$newfile = '';
$hide = '';
$maxline = 4000;
$debug = 0;


sub l00http_diff_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "diff: diff between two files";
}

sub l00http_diff_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($htmlout, $OA, $NA);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} - ";
    if ((defined ($form->{'path'}) && 
        (length ($form->{'path'}) > 0))) {
        $form->{'path'} =~ s/\r//g;
        $form->{'path'} =~ s/\n//g;
        $_ = $form->{'path'};
        # keep path only
        s/\/[^\/]+$/\//;
        print $sock " Path: <a href=\"/ls.htm?path=$_\">$_</a>";
        $_ = $form->{'path'};
        # keep name only
        s/^.+\/([^\/]+)$/$1/;
        print $sock "<a href=\"/ls.htm?path=$form->{'path'}\">$_</a>\n";
    }
    print $sock "<a href=\"/diff.htm\">Refresh</a>\n";
    print $sock "<p>\n";


    if (defined ($form->{'debug'})) {
        if ($form->{'debug'} =~ /(\d+)/) {
            $debug = $1;
        } else {
            $debug = 5;
        }
    }

    if (defined ($form->{'hide'}) && ($form->{'hide'} eq 'on')) {
        $hide = 'checked';
    } else {
        $hide = '';
    }

    if (defined ($form->{'width'})) {
        if ($form->{'width'} =~ /(\d+)/) {
            $width = $1;
        }
    }
    if (defined ($form->{'maxline'})) {
        if ($form->{'maxline'} =~ /(\d+)/) {
            $maxline = $1;
        }
    }

    # copy paste target
    if (defined ($form->{'swap'})) {
        $_ = $newfile;
        $newfile = $oldfile;
        $oldfile = $_;
    } elsif (defined ($form->{'pasteold'})) {
        # if pasting old file
        # this takes precedence over 'path'
        $oldfile = &l00httpd::l00getCB($ctrl);
    } elsif (defined ($form->{'pastenew'})) {
        # if pasting new file
        # this takes precedence over 'path'
        $newfile = &l00httpd::l00getCB($ctrl);
    } elsif (defined ($form->{'path'})) {
        # could be 'compare' or from launcher.htm
        if (defined ($form->{'pathold'})) {
            # 'compare' clicked, old file from oldfile field
            $oldfile = $form->{'pathold'};
        } else {
            # from ls.htm, push first file to be oldfile
            $oldfile = $newfile;
        }
        # new file always from 'path' (field or from ls.htm)
        $newfile = $form->{'path'};
    }

    if (defined ($form->{'compare'})) {
        # 'compare' clicked
        if ((defined ($form->{'pathold'})) && (length($form->{'pathold'}) > 2)) {
            $oldfile = $form->{'pathold'};
        }
        if ((defined ($form->{'pathnew'})) && (length($form->{'pathnew'}) > 2)) {
            $newfile = $form->{'pathnew'};
        }
    }

    print $sock "<form action=\"/diff.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"compare\" value=\"Compare\">\n";
    print $sock "Width: <input type=\"text\" size=\"4\" name=\"width\" value=\"$width\">\n";
    print $sock "</td></tr>\n";

    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"pastenew\" value=\"CB>New:\">";
    print $sock "<br><textarea name=\"pathnew\" cols=$ctrl->{'txtw'} rows=$ctrl->{'txth'}>$newfile</textarea>\n";
    print $sock "</td></tr>\n";

    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"pasteold\" value=\"CB>Old:\">";
    print $sock "<br><textarea name=\"pathold\" cols=$ctrl->{'txtw'} rows=$ctrl->{'txth'}>$oldfile</textarea>\n";
    print $sock "</td></tr>\n";

    print $sock "<tr><td>\n";
    print $sock "<input type=\"checkbox\" name=\"debug\">debug";
    print $sock "<input type=\"checkbox\" name=\"hide\" $hide>Hide same lines\n";
    print $sock "</td></tr>\n";

    print $sock "<tr><td>\n";
    print $sock "&nbsp;";
    print $sock "<input type=\"submit\" name=\"swap\" value=\"Swap\"> ";
    print $sock "<input type=\"text\" size=\"4\" name=\"maxline\" value=\"$maxline\"> lines max\n";
    print $sock "</td></tr>\n";
    print $sock "</table><br>\n";
    print $sock "</form>\n";


    if (defined ($form->{'compare'})) {
        ($htmlout, $OA, $NA) = &l00diff::l00http_diff_compare ($ctrl, $sock, 
            $width, $oldfile, $newfile, $hide, $maxline, $debug);
        print $sock $htmlout;
#print $sock "<pre>\nOA ";
#print $sock join(",", @$OA);
#print $sock "\nNA ";
#print $sock join(",", @$NA);
#print $sock "</pre>\n";
    }


    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
