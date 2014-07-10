use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

#l00httpd::dbp($config{'desc'}, "2 contextln $contextln\n");
my %config = (proc => "l00http_uploadfile_proc",
              desc => "l00http_uploadfile_desc");


sub l00http_uploadfile_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "uploadfile: Upload file to the server";
}

sub l00http_uploadfile_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "<a name=\"top\"></a>\n";
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} - ";
    print $sock "<a href=\"#end\">Jump to end</a>\n";

    if (defined($form->{'payload'})) {
        ##&l00httpd::l00fwriteOpen($ctrl, $form->{'path'});
        #&l00httpd::l00fwriteOpen($ctrl, 'c:\x\z.txt');
        #&l00httpd::l00fwriteBuf($ctrl, $form->{'payload'});
        #if (&l00httpd::l00fwriteClose($ctrl)) {
        #    print $sock "Unable to write '$form->{'path'}'<p>\n";
        #}
        open(DBG2,">c:\\x\\z.txt");
        binmode(DBG2);
        print DBG2 $form->{'payload'};
        close(DBG2);
    }

if (!defined($form->{'path'})) {
    $form->{'path'} = '';
}
    print $sock "<a href=\"/uploadfile.htm\">uploadfile.htm</a><p>\n";

    print $sock "<form action=\"/uploadfile.htm\" method=\"post\" enctype=\"multipart/form-data\">\n";

    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"upload\" value=\"Upload to\">\n";
    print $sock "<input type=\"text\" size=\"20\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "<input id=\"myfile\" name=\"myfile\" type=\"file\">\n";
    print $sock "</td></tr>\n";

    print $sock "</table><br>\n";
    print $sock "</form>\n";

    print $sock "Note: when launching from the 'launcher', the destination direction is ".
        "taken from the direction portion of the path, and the filename is taken from ".
        "the file being uploaded<p>\n";

    print $sock "Note: Maximum updae size is 10 MBytes<p>\n".

    print $sock "<a name=\"end\"></a>";
    print $sock "<a href=\"#top\">top</a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
