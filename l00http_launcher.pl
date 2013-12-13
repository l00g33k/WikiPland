use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_launcher_proc",
              desc => "l00http_launcher_desc");

my @targets;


sub l00http_launcher_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "launcher: to start other modules";
}

sub l00http_launcher_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my (@alllines, $line, $lineno, $file, $name, $col);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">Quick</a>\n";
    if (defined ($form->{'path'})) {
#       print $sock " Path: <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a>\n";
        print $sock " <a href=\"/clip.htm?update=Copy+to+clipboard&clip=$form->{'path'}\">Path</a>:";
        print $sock " <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a>\n";
    }
    print $sock "<p>\n";
    $form->{'path'} =~ s/\r//g;
    $form->{'path'} =~ s/\n//g;


    if ($#targets == -1) {
        if (opendir (DIR, "$ctrl->{'plpath'}")) {
            foreach $file (sort readdir (DIR)) {
                if ($file =~ /^l00http_(\w+)\.pl$/) {
                    $name = $1;
                    if (open (IN, "<$ctrl->{'plpath'}$file")) {
                        while (<IN>) {
                            if (/\$form->\{'path'\}/) {
                                push (@targets, $name);
                                last;
                            }
                        }
                        close (IN);
                    }
                }
            }
        }
    }


    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";


    $col = 0;
    foreach $name (@targets) {
        if ($col == 0) {
            print $sock "<tr><td>\n";
        }
        print $sock "<a href=\"/$name.htm?path=$form->{'path'}\">$name</a>\n";
        $col++;
        # change number of column here and below
        if ($col >= 3) {
            $col = 0;
            print $sock "</td></tr>\n";
        } else {
            print $sock "</td><td>\n";
        }
    }

    while ($col != 0) {
        print $sock "&nbsp;\n";
        $col++;
        # change number of column here and above
        if ($col >= 3) {
            $col = 0;
            print $sock "</td></tr>\n";
        } else {
            print $sock "</td><td>\n";
        }
    }

    print $sock "</table>\n";

    print $sock "<p>Update l00http_launcher.pl to add new target<p>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
