#use strict;
#use warnings;
use l00httpd;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_quickdev_proc",
              desc => "l00http_quickdev_desc");


sub l00http_quickdev_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition

    if (!&l00httpd::l00freadOpen($ctrl, 'l00://quickdev.htm')) {
        # make default
        &l00httpd::l00fwriteOpen($ctrl, 'l00://quickdev.htm');
        &l00httpd::l00fwriteBuf($ctrl, '/sdcard/sl4a/scripts/l00httpd/l00http_toast.pl');
        &l00httpd::l00fwriteClose($ctrl);
    }


    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "quickdev: Execute module without restarting. Specify full path in ".
    "<a href=\"/edit.htm?path=l00://quickdev.htm\">quickdev.htm</a> -- ".
    "<a href=\"/clip.htm?update=Copy+to+CB&clip=%2Fsdcard%2Fsl4a%2Fscripts%2Fl00httpd%2Fl00http_toast.pl\">clip example</a>";
}

sub l00http_quickdev_proc (\%) {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($target, $mod);



    if (&l00httpd::l00freadOpen($ctrl, 'l00://quickdev.htm')) {
        $target = &l00httpd::l00freadLine($ctrl);
        $target =~ s/\n//;
        $target =~ s/\r//;
        l00httpd::dbp($config{'desc'}, "target is $target\n");

        $rethash = do $target;

        if (!defined ($rethash)) {
            # Send HTTP and HTML headers
            print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>quickdev</title>" . $ctrl->{'htmlhead2'};
            print $sock "$ctrl->{'home'} \n";
            if ($!) {
                l00httpd::dbp($config{'desc'}, "Can't read module '$httpmods{$mod}': $!\n");
                print $sock "<p>Can't read module '$httpmods{$mod}': $!<p>\n";
            } elsif ($@) {
                l00httpd::dbp($config{'desc'}, "Can't parse module '$httpmods{$mod}': $@\n");
                print $sock "<p>Can't parse module '$httpmods{$mod}': $@<p>\n";
            }

            # send HTML footer and ends
            print $sock $ctrl->{'htmlfoot'};
        } else {
            # default to disabled to non local clients
            $mod = $rethash->{'proc'};
            $ctrl{'msglog'} = "";
            $retval = __PACKAGE__->$mod($ctrl);
        }
    } else {
        # Send HTTP and HTML headers
        print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>quickdev</title>" . $ctrl->{'htmlhead2'};
        print $sock "$ctrl->{'home'} \n";


        # get submitted name and print greeting
        print $sock "<p>Specify full path in <a href=\"/edit.htm?path=l00://quickdev.htm\">quickdev.htm</a><p>\n";

        # send HTML footer and ends
        print $sock $ctrl->{'htmlfoot'};
    }


}


\%config;
