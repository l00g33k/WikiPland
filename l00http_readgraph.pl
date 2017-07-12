use strict;
use warnings;
use l00wikihtml;
use l00svg;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# read graph


my %config = (proc => "l00http_readgraph_proc",
              desc => "l00http_readgraph_desc");


sub l00http_readgraph_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "readgraph: Read out values from a graph";
}

sub l00http_readgraph_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($pname, $fname, $dx, $dy, $idx, $lastx, $lasty);


    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>l00httpd</title>" . $ctrl->{'htmlhead2'};

    if (!defined ($form->{'readtlx'})) {
        $form->{'readtlx'} = 0;
    }
    if (!defined ($form->{'readtly'})) {
        $form->{'readtly'} = 0;
    }
    if (!defined ($form->{'readbrx'})) {
        $form->{'readbrx'} = 1;
    }
    if (!defined ($form->{'readbry'})) {
        $form->{'readbry'} = 1;
    }
    if (!defined ($form->{'screentlx'})) {
        $form->{'screentlx'} = 0;
    }
    if (!defined ($form->{'screently'})) {
        $form->{'screently'} = 0;
    }
    if (!defined ($form->{'screenbrx'})) {
        $form->{'screenbrx'} = 1;
    }
    if (!defined ($form->{'screenbry'})) {
        $form->{'screenbry'} = 1;
    }
    if (!defined ($form->{'lastx'})) {
        $form->{'lastx'} = 0;
    }
    if (!defined ($form->{'lasty'})) {
        $form->{'lasty'} = 0;
    }
    if (!defined ($form->{'x'})) {
        $form->{'x'} = 0;
    } else {
        if (defined ($form->{'clicks'})) {
            $form->{'clicks'} .= ":$form->{'x'},$form->{'x'}";
        } else {
            $form->{'clicks'} = "$form->{'x'},$form->{'x'}";
        }
    }
    if (!defined ($form->{'y'})) {
        $form->{'y'} = 0;
    }
    if (defined ($form->{'clearclicks'})) {
        undef $form->{'clicks'};
    }

    if (defined ($form->{'path'}) &&
        (($pname, $fname) = $form->{'path'} =~ /^(.+\/)([^\/]+)$/)) {
        print $sock "<form action=\"/readgraph.htm\" method=\"get\">\n";
        print $sock "<input type=\"hidden\" name=\"path\" value=\"$pname$fname\">\n";
        print $sock "<input type=image style=\"float:none\" src=\"/ls.htm/$fname?path=$pname$fname\"><p>\n";
        if (defined ($form->{'settl'})) {
            $form->{'screentlx'} = $form->{'lastx'};
            $form->{'screently'} = $form->{'lasty'};
        }
        if (defined ($form->{'setbr'})) {
            $form->{'screenbrx'} = $form->{'lastx'};
            $form->{'screenbry'} = $form->{'lasty'};
        }

        if (defined ($form->{'x'})) {
            print $sock "<div style=\"position: absolute; left:$form->{'x'}"."px; top:$form->{'y'}"."px;\">\n";
            print $sock "<font color=\"red\">+</font></div>\n";

            print $sock "Clicked: ($form->{'x'} , $form->{'y'}) -&gt; \n";
            printf $sock ("%f , ", 
                ($form->{'readbrx'} - $form->{'readtlx'}) * ($form->{'x'} - $form->{'screentlx'}) / ($form->{'screenbrx'} - $form->{'screentlx'}) 
                + $form->{'readtlx'}
            );
            printf $sock ("%f", 
                ($form->{'readbry'} - $form->{'readtly'}) * ($form->{'y'} - $form->{'screently'}) / ($form->{'screenbry'} - $form->{'screently'}) 
                + $form->{'readtly'}
            );
            print $sock "<br>\n";
            if (defined ($form->{'lastx'})) {
                $dx = $form->{'x'} - $form->{'lastx'};
                $dy = $form->{'y'} - $form->{'lasty'};
                print $sock "Delta: ($dx , $dy) -&gt; ";
                printf $sock ("%f , ", 
                    ($form->{'readbrx'} - $form->{'readtlx'}) * (($form->{'x'} - $form->{'lastx'}) - $form->{'screentlx'}) / ($form->{'screenbrx'} - $form->{'screentlx'}) 
                    + $form->{'readtlx'}
                );
                printf $sock ("%f", 
                    ($form->{'readbry'} - $form->{'readtly'}) * (($form->{'y'} - $form->{'lasty'}) - $form->{'screently'}) / ($form->{'screenbry'} - $form->{'screently'}) 
                    + $form->{'readtly'}
                );
                print $sock "<br>\n";
            }
        }
        print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
        print $sock "<tr>\n";
        print $sock "<td>\n";
        print $sock "Corners</td>\n";
        print $sock "<td>\n";
        print $sock "Screen X</td>\n";
        print $sock "<td>\n";
        print $sock "Screen Y</td>\n";
        print $sock "<td>\n";
        print $sock "Reading X</td>\n";
        print $sock "<td>\n";
        print $sock "Reading Y</td>\n";
        print $sock "<td>\n";
        print $sock "Set cursor as</td>\n";
        print $sock "</tr>\n";

        print $sock "<tr>\n";
        print $sock "<td>\n";
        print $sock "Top left</td>\n";
        print $sock "<td>\n";
        print $sock "$form->{'screentlx'}</td>\n";
        print $sock "<td>\n";
        print $sock "$form->{'screently'}</td>\n";
        print $sock "<td>\n";
        print $sock "<input type=\"text\" size=\"6\" name=\"readtlx\" value=\"$form->{'readtlx'}\"></td>\n";
        print $sock "<td>\n";
        print $sock "<input type=\"text\" size=\"6\" name=\"readtly\" value=\"$form->{'readtly'}\"></td>\n";
        print $sock "<td>\n";
        print $sock "<input type=\"submit\" name=\"settl\" value=\"Set TL\"></td>\n";
        print $sock "</tr>\n";

        print $sock "<tr>\n";
        print $sock "<td>\n";
        print $sock "Bottom right</td>\n";
        print $sock "<td>\n";
        print $sock "$form->{'screenbrx'}</td>\n";
        print $sock "<td>\n";
        print $sock "$form->{'screenbry'}</td>\n";
        print $sock "<td>\n";
        print $sock "<input type=\"text\" size=\"6\" name=\"readbrx\" value=\"$form->{'readbrx'}\"></td>\n";
        print $sock "<td>\n";
        print $sock "<input type=\"text\" size=\"6\" name=\"readbry\" value=\"$form->{'readbry'}\"></td>\n";
        print $sock "<td>\n";
        print $sock "<input type=\"submit\" name=\"setbr\" value=\"Set BR\"></td>\n";

        if (defined ($form->{'x'})) {
            print $sock "<input type=\"hidden\" name=\"lastx\" value=\"$form->{'x'}\">\n";
            print $sock "<input type=\"hidden\" name=\"lasty\" value=\"$form->{'y'}\">\n";
        }
        if (defined ($form->{'clicks'})) {
            print $sock "<input type=\"hidden\" name=\"clicks\" value=\"$form->{'clicks'}\">\n";
        }
        print $sock "<input type=\"hidden\" name=\"screentlx\" value=\"$form->{'screentlx'}\">\n";
        print $sock "<input type=\"hidden\" name=\"screently\" value=\"$form->{'screently'}\">\n";
        print $sock "<input type=\"hidden\" name=\"screenbrx\" value=\"$form->{'screenbrx'}\">\n";
        print $sock "<input type=\"hidden\" name=\"screenbry\" value=\"$form->{'screenbry'}\">\n";
        print $sock "</tr>\n";

        print $sock "<tr>\n";
        print $sock "<td>\n";
        print $sock "&nbsp;</td>\n";
        print $sock "<td>\n";
        print $sock "&nbsp;</td>\n";
        print $sock "<td>\n";
        print $sock "&nbsp;</td>\n";
        print $sock "<td>\n";
        print $sock "&nbsp;</td>\n";
        print $sock "<td>\n";
        print $sock "&nbsp;</td>\n";
        print $sock "<td>\n";
        print $sock "<input type=\"submit\" name=\"clearclicks\" value=\"Clear clicks\"></td>\n";
        print $sock "</tr>\n";

        print $sock "</table>\n";

        print $sock "</form>\n";
    }


    print $sock "$ctrl->{'home'} $ctrl->{'HOME'}\n";
    print $sock "Click graph above.<br>\n";

    if (defined ($form->{'clicks'})) {
        $idx = 1;
        print $sock "<pre>\n";
        foreach $_ (split(":", $form->{'clicks'})) {
            if (/(.+),(.+)/) {
                print $sock "$idx: Clicked: ($1 , $2) -&gt; ";
                printf $sock ("%f , ", 
                    ($form->{'readbrx'} - $form->{'readtlx'}) * ($1 - $form->{'screentlx'}) / ($form->{'screenbrx'} - $form->{'screentlx'}) 
                    + $form->{'readtlx'}
                );
                printf $sock ("%f", 
                    ($form->{'readbry'} - $form->{'readtly'}) * ($2 - $form->{'screently'}) / ($form->{'screenbry'} - $form->{'screently'}) 
                    + $form->{'readtly'}
                );
                if ($idx > 1) {
                    $dx = $1 - $lastx;
                    $dy = $2 - $lasty;
                    print $sock " Delta: ($dx , $dy) -&gt; ";
                    printf $sock ("%f , ", 
                        ($form->{'readbrx'} - $form->{'readtlx'}) * (($1 - $lastx) - $form->{'screentlx'}) / ($form->{'screenbrx'} - $form->{'screentlx'}) 
                        + $form->{'readtlx'}
                    );
                    printf $sock ("%f", 
                        ($form->{'readbry'} - $form->{'readtly'}) * (($2 - $lasty) - $form->{'screently'}) / ($form->{'screenbry'} - $form->{'screently'}) 
                        + $form->{'readtly'}
                    );
                }
                print $sock "\n";
                $lastx = $1;
                $lasty = $2;
                $idx++;
            }
        }
        print $sock "</pre>\n";
    }

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};

}


\%config;
