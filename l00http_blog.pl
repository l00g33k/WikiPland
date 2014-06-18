use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_blog_proc",
              desc => "l00http_blog_desc");
my ($buffer, $lastbuf);
$lastbuf = '';


sub l00http_blog_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "blog: Simple blogger: must be invoked through ls.pl file view";
}

sub l00http_blog_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my (@alllines, $line, $lineno, $path, $buforg, $fname);
    my ($output, $keys, $key, $space);

    if (defined ($form->{'path'})) {
        $path = $form->{'path'};
        ($fname) = $path =~ /[\\\/]([^\\\/]+)$/;
    } else {
        $path = '(none)';
        $fname = '(none)';
    }

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>$fname blog</title>" .$ctrl->{'htmlhead2'};
    print $sock "<a name=\"__top__\"></a>";
    print $sock "$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">Quick</a> <a href=\"#end\">Jump to end</a><br>\n";
    if (defined ($form->{'path'})) {
        print $sock "Path: <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a> %BLOG:key%:<br>\n";
    } else {
        print $sock "%BLOG:key% quick save link:<br>\n";
    }
    if (defined ($form->{'pastesave'})) {
        $_ = $ctrl->{'droid'}->getClipboard()->{'result'};
        print $sock "<hr>$_<hr>\n";
    }

    $buffer = '';
    if (defined ($form->{'timesave'})) {
        if (defined ($form->{'buffer'})) {
            if (defined ($form->{'blog'})) {
                if ($form->{'blog'} eq "on") {
                    $buffer = substr ($form->{'buffer'}, 25, 9999);
                } else {
                    $buffer = $form->{'buffer'};
                }
            } else {
                $buffer = substr ($form->{'buffer'}, 16, 9999);
            }
        } else {
            $buffer = '';
        }
        if (defined ($form->{'blog'})) {
            if ($form->{'blog'} eq "on") {
                $form->{'buffer'} = "==$ctrl->{'now_string'} ==\n* ";
            } else {
                # 'blog' = none
                $form->{'buffer'} = "";
            }
        } else {
            $form->{'buffer'} = $ctrl->{'now_string'} . ' ';
        }
        $form->{'buffer'} .= $buffer;
        $form->{'save'} = 1;
    }
    if (defined ($form->{'pastesave'})) {
        if (defined ($form->{'blog'})) {
            if ($form->{'blog'} eq "on") {
                $form->{'buffer'} = "==$ctrl->{'now_string'} ==\n* ";
            } else {
                # 'blog' = none
                $form->{'buffer'} = "";
            }
        } else {
            $form->{'buffer'} = $ctrl->{'now_string'} . ' ';
        }
        $form->{'buffer'} .= $ctrl->{'droid'}->getClipboard()->{'result'};
        $form->{'save'} = 1;
    }
    if (defined ($form->{'save'})) {
        if ((defined ($form->{'buffer'})) &&
            ((defined ($form->{'path'})) && 
            (length ($form->{'path'}) > 0))) {
            $buffer = $form->{'buffer'};
            if (($buffer ne $lastbuf) &&
                !($buffer =~ /^\d{8,8} \d{6,6} $/)) {
                $lastbuf = $buffer;
                # don't backup when just appending
                local $/ = undef;
#               if (open (IN, "<$form->{'path'}")) {
#                   # http://www.perlmonks.org/?node_id=1952
#                   local $/ = undef;
#                   $buforg = <IN>;
#                   close (IN);
                if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
                    $buforg = &l00httpd::l00freadAll($ctrl);
                } else {
                    $buforg = '';
                    print $sock "Unable to read original '$form->{'path'}'<p>\n";
                }
                &l00backup::backupfile ($ctrl, $form->{'path'}, 1, 9);
#               &l00httpd::l00fwriteOpen($ctrl, $form->{'path'});
#               &l00httpd::l00fwriteBuf($ctrl, $outbuf);
#               &l00httpd::l00fwriteClose($ctrl);
#               if (open (OUT, ">$form->{'path'}")) {
                if (&l00httpd::l00fwriteOpen($ctrl, $form->{'path'})) {
                    @alllines = split ("\n", $buffer);
                    $space = '';
                    foreach $line (@alllines) {
                        $line =~ s/\r//g;
                        $line =~ s/\n//g;
                        if (defined ($form->{'blog'})) {
                            if ($form->{'blog'} eq "on") {
#                               print OUT "$line\n";
                                &l00httpd::l00fwriteBuf($ctrl, "$line\n");
                            } else {
                                # all on one line
#                               print OUT "$line ";
                                &l00httpd::l00fwriteBuf($ctrl, "$space$line");
                                $space = ' ';
                            }
                        } else {
                            # all on one line
#                           print OUT "$line ";
                            &l00httpd::l00fwriteBuf($ctrl, "$space$line");
                            $space = ' ';
                        }
                    }
                    if (!defined ($form->{'blog'}) || ($form->{'blog'} ne "on")) {
#                       print OUT "\n";
                        &l00httpd::l00fwriteBuf($ctrl, "\n");
                    }
#                   print OUT $buforg;
                    &l00httpd::l00fwriteBuf($ctrl, $buforg);
#                   close (OUT);
                    &l00httpd::l00fwriteClose($ctrl);
                } else {
                    print $sock "Unable to write '$form->{'path'}'<p>\n";
                }
            }
        }
    }
    # do funny tricks to switch log style
    if (defined ($form->{'logstyle'})) {
        $form->{'cancel'} = 'NewTime';
        $form->{'blog'} = undef;
    }
    if (defined ($form->{'blogstyle'})) {
        $form->{'cancel'} = 'NewTime';
        $form->{'blog'} = 'on';
    }
    if (defined ($form->{'blog'})) {
        if ($form->{'blog'} eq "on") {
            $buffer = "==$ctrl->{'now_string'} ==\n* ";
        } else {
            $buffer = "";
        }
    } else {
        $buffer = $ctrl->{'now_string'} . ' ';
    }
    if (defined ($form->{'cancel'}) && defined ($form->{'buffer'})) {
        # do funny tricks to switch log style
        if (defined ($form->{'logstyle'})) {
            $buffer .= substr ($form->{'buffer'}, 25, 9999);
        } elsif (defined ($form->{'blogstyle'})) {
            $buffer .= substr ($form->{'buffer'}, 16, 9999);
        } elsif (defined ($form->{'blog'})) {
            if ($form->{'blog'} eq "on") {
                $buffer .= substr ($form->{'buffer'}, 25, 9999);
            } else {
                $buffer = $form->{'buffer'};
            }
        } else {
            $buffer .= substr ($form->{'buffer'}, 16, 9999);
        }
    }
    if (defined ($form->{'paste'})) {
        $buffer .= $ctrl->{'droid'}->getClipboard()->{'result'};
    }
    if (defined ($form->{'pasteadd'})) {
        $buffer = $form->{'buffer'} . ' ';
        $buffer .= $ctrl->{'droid'}->getClipboard()->{'result'};
    }

    # dump content of file in formatted text
    $output = '';
    $keys = 0;
    if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
        $lineno = 1;
        $output .= "<pre>\n";
        while ($_ = &l00httpd::l00freadLine($ctrl)) {
            s/\r//g;
            s/\n//g;
            # extract special keywords
            if (($key) = /^%BLOG:([^%]+)%/) {
                if ($keys == 0) {
#                   print $sock "<br>";
                } else {
                    print $sock " - ";
                }
                $key =~ s/ /+/g;
                # /blog.htm?timesave=&buffer=20140307+135828+key&save=Save&path=C%3A%2Fx%2Fdel.txt
                print $sock "<a href=\"/blog.htm?timesave=&buffer=20140101+000000+$key&save=Save&path=$form->{'path'}\">$key</a>\n";
                $keys++;
            }
            # trim width
            if ($lineno < $ctrl->{'blogmaxln'}) {
                if (length($_) > $ctrl->{'blogwd'}) {
                    $_ = substr($_, 0, $ctrl->{'blogwd'});
                }
                $output .= sprintf ("%04d: ", $lineno) . "$_\n";
            } else {
                $line = $_;
            }
            $lineno++;
        }
        if ($lineno >= $ctrl->{'blogmaxln'}) {
            $output .= sprintf ("(lines skipped)\n");
            $output .= sprintf ("%04d: ", $lineno) . "$line\n";
        }
        $output .= "</pre>\n";
        if ($lineno >= $ctrl->{'blogmaxln'}) {
            $output .= "Path: <a href=\"/view.htm?path=$form->{'path'}\">View full formatted text</a><br>\n";
        }
        if ($keys > 0) {
            print $sock "<br>\n";
        }
    }

    print $sock "<form action=\"/blog.htm\" method=\"get\">\n";
    print $sock "<textarea name=\"buffer\" cols=\"$ctrl->{'txtw'}\" rows=\"$ctrl->{'txth'}\">$buffer</textarea>\n";
    print $sock "<p>\n";
    print $sock "<input type=\"submit\" name=\"save\" value=\"Save\">\n";
    print $sock "<input type=\"submit\" name=\"pastesave\" value=\"PasteSave\">\n";
    print $sock "<input type=\"submit\" name=\"paste\" value=\"Paste\">\n";
    print $sock "<input type=\"submit\" name=\"pasteadd\" value=\"PasteAdd\">\n";
    print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
    if (defined ($form->{'blog'})) {
        print $sock "<input type=\"hidden\" name=\"blog\" value=\"$form->{'blog'}\">\n";
    }
    print $sock "<br><input type=\"submit\" name=\"timesave\" value=\"TimeSave\">\n";
    print $sock "<input type=\"submit\" name=\"cancel\" value=\"NewTime\">\n";
    if (defined ($form->{'blog'})) {
        print $sock "<input type=\"submit\" name=\"logstyle\" value=\"Log style add\">\n";
    } else {
        print $sock "<input type=\"submit\" name=\"blogstyle\" value=\"Blog style add\">\n";
    }
    print $sock "</form><br>Append '&blog=' to URL for bare style\n";


    print $sock $output;

    print $sock "<hr><a name=\"end\"></a>";
    print $sock "<a href=\"/recedit.htm?record1=.&path=$form->{'path'}\"># quick mark</a>\n";
# [[/blogtag.pl?path=./sample.txt|log blogtag]] 
# [[/ls.pl?path=./sample.txt#blogtag|view blogtag]] 
# [[/tableedit.pl?edit=Edit&path=./sample.txt|tableedit]] 
# [[/do.pl?do=Do&path=./l00_donow.pl|Filtered]]
# [[/table.pl?path=$&sort=Sort&keys=1%7C%7C0|@+$+]] 
# [[/table.pl?path=$&sort=Sort&keys=0%7C%7C1|$+@+]]
    print $sock " - <a href=\"#__top__\">top</a>\n";
    print $sock "<br>\n";
    print $sock "<br>\n";
    print $sock "<br>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
