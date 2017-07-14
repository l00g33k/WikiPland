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
    my ($pname, $fname, $dx, $dy, $idx, $svg, $ttlpx, $ttlrd, $x, $y);


    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>readgraph</title>" . $ctrl->{'htmlhead2'};

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
            $form->{'clicks'} .= ":$form->{'x'},$form->{'y'}";
        } else {
            $form->{'clicks'} = "$form->{'x'},$form->{'y'}";
        }
    }
    if (!defined ($form->{'y'})) {
        $form->{'y'} = 0;
    }
    if (defined ($form->{'clearclicks'})) {
        undef $form->{'clicks'};
    }
    if (defined ($form->{'setbrcorner'})) {
        $form->{'brcornerx'} = $form->{'lastx'};
        $form->{'brcornery'} = $form->{'lasty'};
        if ($form->{'clicks'} =~ /:/) {
            # more than one point, clear last point
            $form->{'clicks'} =~ s/:[^:]+$//;
        } else {
            # only one point, just clear it
            $form->{'clicks'} = '';
        }
    }

    if (defined ($form->{'path'}) &&
        (($pname, $fname) = $form->{'path'} =~ /^(.+\/)([^\/]+)$/)) {
        print $sock "<form action=\"/readgraph.htm\" method=\"get\">\n";
        print $sock "<input type=\"hidden\" name=\"path\" value=\"$pname$fname\">\n";
        print $sock "<input type=\"image\" style=\"float:none\" src=\"/ls.htm/$fname?path=$pname$fname\"><p>\n";
        #print $sock "<input type=\"image\" style=\"float:none\" src=\"/svg.htm?graph=demo\"><p>\n";
        #print $sock "<input type=\"image\" style=\"float:none\" src=\"/ls.htm/svg2.svg?path=%2fsdcard%2fz%2fsvg3.svg\"><p>\n";
        #print $sock "<input type=\"image\" style=\"float:none\" src=\"/ls.htm/svg2.svg?path=%2fsdcard%2fz%2fsvg4.svg\"><p>\n";
        if (defined ($form->{'settl'})) {
            $form->{'screentlx'} = $form->{'lastx'};
            $form->{'screently'} = $form->{'lasty'};
            if ($form->{'clicks'} =~ /:/) {
                # more than one point, clear last point
                $form->{'clicks'} =~ s/:[^:]+$//;
            } else {
                # only one point, just clear it
                $form->{'clicks'} = '';
            }
        }
        if (defined ($form->{'setbr'})) {
            $form->{'screenbrx'} = $form->{'lastx'};
            $form->{'screenbry'} = $form->{'lasty'};
            if ($form->{'clicks'} =~ /:/) {
                # more than one point, clear last point
                $form->{'clicks'} =~ s/:[^:]+$//;
            } else {
                # only one point, just clear it
                $form->{'clicks'} = '';
            }
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
            if (defined ($form->{'lastx'})) {
                $dx = $form->{'x'} - $form->{'lastx'};
                $dy = $form->{'y'} - $form->{'lasty'};
                print $sock " --- Delta: ($dx , $dy) -&gt; ";
                printf $sock ("%f , ", 
                    ($form->{'readbrx'} - $form->{'readtlx'}) * (($form->{'x'} - $form->{'lastx'}) - $form->{'screentlx'}) / ($form->{'screenbrx'} - $form->{'screentlx'}) 
                    + $form->{'readtlx'}
                );
                printf $sock ("%f", 
                    ($form->{'readbry'} - $form->{'readtly'}) * (($form->{'y'} - $form->{'lasty'}) - $form->{'screently'}) / ($form->{'screenbry'} - $form->{'screently'}) 
                    + $form->{'readtly'}
                );
            }
            print $sock "<p>\n";
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
        print $sock "BR corner</td>\n";
        print $sock "<td>\n";
        if (defined ($form->{'brcornerx'})) {
           $_ = $form->{'brcornerx'};
           print $sock "<input type=\"hidden\" name=\"brcornerx\" value=\"$form->{'brcornerx'}\">\n";
        } else {
           $_ = '&nbsp;';
        }
        print $sock "$_</td>\n";
        print $sock "<td>\n";
        if (defined ($form->{'brcornery'})) {
           $_ = $form->{'brcornery'};
           print $sock "<input type=\"hidden\" name=\"brcornery\" value=\"$form->{'brcornery'}\">\n";
        } else {
           $_ = '&nbsp;';
        }
        print $sock "$_</td>\n";
        print $sock "<td>\n";
        print $sock "<input type=\"submit\" name=\"setbrcorner\" value=\"Set BR corner\"></td>\n";
        print $sock "<td>\n";
        print $sock "&nbsp;</td>\n";
        print $sock "<td>\n";
        print $sock "<input type=\"submit\" name=\"clearclicks\" value=\"Clear clicks\"></td>\n";
        print $sock "</tr>\n";

        print $sock "</table>\n";

        print $sock "</form><br>\n";
    }


    print $sock "$ctrl->{'home'} $ctrl->{'HOME'}\n";
    if (defined ($form->{'path'})) {
        print $sock "<a href=\"readgraph.htm?path=$form->{'path'}\">Reset</a> - \n";
        print $sock "Launcher: <a href=\"launcher.htm?path=$form->{'path'}\">$form->{'path'}</a> - \n";
    }
    print $sock "Click graph above.<br>\n";

    if (defined ($form->{'clicks'}) && defined ($form->{'lastx'})) {
        $idx = 1;
        $svg = '';
        $ttlpx = 0;
        $ttlrd = 0;
        print $sock "<pre>\n";
        foreach $_ (split(":", $form->{'clicks'})) {
            if (/(.+),(.+)/) {
                print $sock "$idx: Clicked: ($1 , $2) -&gt; ";
                $x = ($form->{'readbrx'} - $form->{'readtlx'}) * ($1 - $form->{'screentlx'}) / ($form->{'screenbrx'} - $form->{'screentlx'}) 
                    + $form->{'readtlx'};
                printf $sock ("%f , ", $x);
                $y = ($form->{'readbry'} - $form->{'readtly'}) * ($2 - $form->{'screently'}) / ($form->{'screenbry'} - $form->{'screently'}) 
                    + $form->{'readtly'};
                printf $sock ("%f", $y);
                if ($idx > 1) {
                    $dx = $1 - $form->{'lastx'};
                    $dy = $2 - $form->{'lasty'};
                    print $sock " --- Delta: ($dx , $dy) -&gt; ";
                    $x = ($form->{'readbrx'} - $form->{'readtlx'}) * (($1 - $form->{'lastx'}) - $form->{'screentlx'}) / ($form->{'screenbrx'} - $form->{'screentlx'}) 
                        + $form->{'readtlx'};
                    printf $sock ("%f , ", $x);
                    $y = ($form->{'readbry'} - $form->{'readtly'}) * (($2 - $form->{'lasty'}) - $form->{'screently'}) / ($form->{'screenbry'} - $form->{'screently'}) 
                        + $form->{'readtly'};
                    printf $sock ("%f", $y);
                    $ttlpx += sqrt ($dx * $dx + $dy * $dy);
                    $ttlrd += sqrt ($x * $x + $y * $y);
                    printf $sock (" --- Total: (%f) -&gt; %f", $ttlpx, $ttlrd);
                    if (defined($form->{'brcornerx'})) {
                        if ($idx == 2) {
                            $svg  = '<?xml version="1.0" encoding="UTF-8" standalone="no"?>';
                            $svg .= '<svg  x="0" y="0" width="875" height="532" xmlns="http://www.w3.org/2000/svg" >';
                            $svg .= '<image x="0" y="0" width="';
                            $svg .= $form->{'brcornerx'}+1;
                            $svg .= '" height=';
                            $svg .= $form->{'brcornery'}+1;
                            $svg .= " href=\"/ls.htm?path=$form->{'path'}\" />";
                            $svg .= "<polyline fill=\"none\" stroke=\"#ff0000\" stroke-width=\"2\" points=\"$form->{'lastx'},$form->{'lasty'} ";
                        }
                        $svg .= "$1,$2 ";
                    }
                }
                print $sock "\n";
                $form->{'lastx'} = $1;
                $form->{'lasty'} = $2;
                $idx++;
            }
        }
        if ((defined($form->{'brcornerx'})) && ($idx > 1)) {
            $svg .= "\" /> </svg>\n";
        }
        print $sock "</pre><p>$svg<p>\n";
    }

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};

}


\%config;
