#use strict;
#use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules
my ($blkbytes);
$blkbytes = 100000000;

my %config = (proc => "l00http_split_proc",
              desc => "l00http_split_desc");

sub l00http_split_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "split: Binary split or combine files";
}


sub l00http_split_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($buffer, $tmp);
	my ($pname, $fname, $actual, $blkcnt);

    $sock = $ctrl->{'sock'};     # dereference network socket

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} - ";
    print $sock "<a href=\"#end\">Jump to end</a><hr>\n";
    
    if (defined ($form->{'blkbytes'})) {
        if ($form->{'blkbytes'} =~ /(\d+)/) {
            $blkbytes = $1;
        }
    }

    if ((defined ($form->{'path'})) && (length ($form->{'path'}) > 0)) {
        ($pname, $fname) = $form->{'path'} =~ /^(.+[\\\/])([^\\\/]+)$/;
        print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=:hide+edit+$form->{'path'}%0D\">Path</a>: ";
        print $sock " <a href=\"/ls.htm?path=$pname\">$pname</a>";
        print $sock "<a href=\"/hexview.htm?path=$form->{'path'}\">$fname</a> - \n";
        print $sock "<a href=\"/split.htm?path=$form->{'path'}\">refresh</a> - \n";
        print $sock "<a href=\"/launcher.htm?path=$form->{'path'}\">launcher</a><p>\n";
    } else {
        print $sock "Path: <a href=\"/launcher.htm?path=$ctrl->{'workdir'}\">Select solver equation file</a> and 'Set' to 'solver'<p>\n";
        # send HTML footer and ends
        print $sock $ctrl->{'htmlfoot'};
        return;
    }
    $form->{'path'} =~ s/\r//g;
    $form->{'path'} =~ s/\n//g;


    # read the file
    if (defined ($form->{'path'}) && 
        (-f $form->{'path'})) {
        if (defined ($form->{'split'}) &&
            open (IN, "<$form->{'path'}")) {
            $blkcnt = 0;
            binmode (IN);
            while (1) {
                $actual = read (IN, $buffer, $blkbytes);
                if ($actual > 0) {
                    $tmp = sprintf("%s.%04d", $form->{'path'}, $blkcnt);
                    if (open (OU, ">$tmp")) {
                        binmode (OU);
                        syswrite (OU, $buffer, $actual);
                        close (OU);
                        printf $sock ("$blkcnt: Wrote %d bytes to %s<br>\n", $actual, $tmp)
                    }
                } else {
                    last;
                }
                $blkcnt++;
            }
            close (IN);
        }
        if (defined ($form->{'combi'})) {
            $fname =~ s/\.\d\d\d\d$//;
            if (open (OU, ">$pname$fname.combi")) {
                binmode (OU);
                $blkcnt = 0;
                local $/ = undef;
                while (1) {
                    $tmp = sprintf("%s.%04d", "$pname$fname", $blkcnt);
                    if (open (IN, "<$tmp")) {
                        binmode (IN);
                        $buffer = <IN>;
                        close(IN);
                        $actual = length($buffer);
                        if ($actual > 0) {
                            syswrite (OU, $buffer, $actual);
                            printf $sock ("$blkcnt: Read %d bytes from %s<br>\n", $actual, $tmp);
                            $blkcnt++;
                        } else {
                            last;
                        }
                    } else {
                        last;
                    }
                }
                close (OU);
            }
        }
    }


    print $sock "<hr><form action=\"/split.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"1\" cellspacing=\"1\">\n";
    print $sock "<tr><td>\n";
    if ($form->{'path'} =~ /\.\d\d\d\d$/) {
        print $sock "<input type=\"submit\" name=\"combi\" value=\"Combine\">\n";
    } else {
        print $sock "<input type=\"submit\" name=\"split\" value=\"Split\">\n";
    }
    print $sock "</td><td>\n";
    print $sock "<input type=\"text\" name=\"path\" size=16 value=\"$form->{'path'}\">\n";
    print $sock "</td></tr>\n";

    print $sock "<tr><td>\n";
    print $sock "Block size\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"text\" name=\"blkbytes\" size=8 value=\"$blkbytes\"> btyes\n";
    print $sock "</td></tr>\n";

    print $sock "</table>\n";
    print $sock "</form><p>\n";

    print $sock "<a name=\"end\"></a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
