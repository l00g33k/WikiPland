use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

#l00httpd::dbp($config{'desc'}, "2 contextln $contextln\n");
my %config = (proc => "l00http_colortext_proc",
              desc => "l00http_colortext_desc");


sub l00http_colortext_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "colortext: color text file";
}

sub l00http_colortext_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($buf, $pname, $fname);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "<a name=\"top\"></a>\n";
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} - ";
    print $sock "<a href=\"#end\">Jump to end</a>\n";

    if (defined ($form->{'path'})) {
        ($pname, $fname) = $form->{'path'} =~ /^(.+[\\\/])([^\\\/]+)$/;
        print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=:hide+edit+$form->{'path'}%0D\">Path</a>: ";
        print $sock " <a href=\"/ls.htm?path=$pname\">$pname</a>";
        print $sock "<a href=\"/ls.htm?path=$form->{'path'}\">$fname</a> \n";
        print $sock " <a href=\"/ls.htm?path=$form->{'path'}&editline=on\">Edit line link</a>\n";
    }
    print $sock "<br>\n";



    if (defined ($form->{'path'})) {
        print $sock "<form action=\"/adb.htm\" method=\"get\">\n";
        print $sock "<input type=\"submit\" name=\"backup\" value=\"Make backup\">\n";
        print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
        print $sock "</form>\n";

        if ($form->{'path'} =~ /^(.+\/)([^\/]+)$/) {
            if (defined ($form->{'backup'})) {
                # make backup
                &l00backup::backupfile ($ctrl, $form->{'path'}, 1, 5);
            }
            $_ = "$form->{'path'}";
            s / /%20/g;
            print $sock "<br><a href=\"/clip.htm?update=Copy+to+clipboard&clip=$_\">Copy path</a><p>\n";

            $buf = &l00httpd::pcSyncCmdline($ctrl, $form->{'path'});
            print $sock $buf;
        }
    }


    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
