use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_blog_proc",
              desc => "l00http_blog_desc");
my ($buffer, $lastbuf);
$lastbuf = '';


sub blog_get_msg {
    my ($buffer, $currstyle) = @_;

    if ($currstyle eq 'log') {
        # log
        $buffer = substr ($buffer, 16, 9999);
    } elsif ($currstyle eq 'blog') {
        # blog
        $buffer = substr ($buffer, 25, 9999);
    } elsif ($currstyle eq 'bare') {
        # bare
        # no header, no change
    }

    $buffer;
}


sub l00http_blog_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "blog: Simple blogger: must be invoked through ls.pl file view";
}


# Button actions:
# Blog style/Log style/Bare style: cycle through different style of prepend header
## Blog style:
### 20150322 120000
## Log style: 
### ==20150322 233225 ==
### * 
## Bare style:
### (nothing)
# Save: save form buffer
# PasteSave: paste clipboard with current style header and save
# Paste: paste clipboard with current style header, no save
# PasteAdd: append clipboard to current form buffer, no save
# TimeSave: save form buffer with current time in current style
# NewTime: update time in current style and keep form message

# two hidden fields
## currstyle: indicate style for the just submitted form, 
## newstyle: transform form buffer from CurrentStyle to NewtStyle
## currstyle and newstyle default to log style if missing

#::here::


sub l00http_blog_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my (@alllines, $line, $lineno, $path, $buforg, $buforgpre, $fname, $pname);
    my ($output, $keys, $key, $space, $currstyle, $newstyle);

    if (defined ($form->{'path'})) {
        $path = $form->{'path'};
        ($pname, $fname) = $path =~ /^(.+[\\\/])([^\\\/]+)$/;
    } else {
        $path = '(none)';
        $fname = '(none)';
        $pname = '(none)';
    }

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>$fname blog</title>" .$ctrl->{'htmlhead2'};
    print $sock "<a name=\"__top__\"></a>";
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} <a href=\"#end\">Jump to end</a><br>\n";

    if (defined ($form->{'path'})) {
        print $sock "<a href=\"/launcher.htm?path=$path\">Launch</a>: <a href=\"/ls.htm?path=$pname\">$pname</a>";
        print $sock "<a href=\"/ls.htm?path=$form->{'path'}\">$fname</a> ";
        print $sock "<a href=\"/recedit.htm?record1=.&path=$form->{'path'}\">+ #</a> ";
        print $sock "%BLOG:key%:<br>\n";
    } else {
        print $sock "%BLOG:key% quick save link:<br>\n";
    }

    # display what will be pasted
    if (defined ($form->{'pastesave'})) {
        $_ = &l00httpd::l00getCB($ctrl);
        print $sock "<hr>$_<hr>\n";
    }

    $currstyle = 'log';
    if (defined ($form->{'currstyle'})) {
        if ($form->{'currstyle'} eq 'log') {
            $currstyle = 'log';
        } elsif ($form->{'currstyle'} eq 'blog') {
            $currstyle = 'blog';
        } elsif ($form->{'currstyle'} eq 'bare') {
            $currstyle = 'bare';
        }
    }
    $newstyle = $currstyle;
    if (defined ($form->{'newstyle'})) {
        if ($form->{'newstyle'} eq 'log') {
            $newstyle = 'log';
        } elsif ($form->{'newstyle'} eq 'blog') {
            $newstyle = 'blog';
        } elsif ($form->{'newstyle'} eq 'bare') {
            $newstyle = 'bare';
        }
    }

print $sock "<p>currstyle = $currstyle<p>\n";
print $sock "<p>newstyle = $newstyle<p>\n";
$currstyle = '';
$newstyle = '';
#::here::
if ($currstyle eq 'log') {
    # log
} elsif ($currstyle eq 'blog') {
    # blog
} elsif ($currstyle eq 'bare') {
    # bare
}


    $buffer = '';
    if (defined ($form->{'timesave'})) {
        # update time and save form buffer
        if (defined ($form->{'buffer'})) {
#::here::
            $buffer = &blog_get_msg ($form->{'buffer'}, $currstyle);
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
#::here::
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
#::here::
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
        $form->{'buffer'} .= &l00httpd::l00getCB($ctrl);
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
                $buforgpre = '';
                if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
                    $lineno = 1;
                    while ($_ = &l00httpd::l00freadLine($ctrl)) {
                        s/\r//g;
                        s/\n//g;
                        if (defined($form->{'afterline'})) {
                            if ($lineno <= $form->{'afterline'}) {
                                $buforgpre .= "$_\n";
                            } else {
                                $buforg .= "$_\n";
                            }
                        } else {
                            $buforg .= "$_\n";
                        }
                        $lineno++;
                    }
                } else {
                    $buforg = '';
                    print $sock "Unable to read original '$form->{'path'}'<p>\n";
                }
                &l00backup::backupfile ($ctrl, $form->{'path'}, 1, 9);
                if (&l00httpd::l00fwriteOpen($ctrl, $form->{'path'})) {
                    if ($buforgpre ne '') {
                        &l00httpd::l00fwriteBuf($ctrl, $buforgpre);
                    }
                    @alllines = split ("\n", $buffer);
                    $space = '';
                    foreach $line (@alllines) {
                        $line =~ s/\r//g;
                        $line =~ s/\n//g;
#::here::
                        if (defined ($form->{'blog'})) {
                            if ($form->{'blog'} eq "on") {
                                &l00httpd::l00fwriteBuf($ctrl, "$line\n");
                            } else {
                                # all on one line
                                &l00httpd::l00fwriteBuf($ctrl, "$space$line");
                                $space = ' ';
                            }
                        } else {
                            # all on one line
                            &l00httpd::l00fwriteBuf($ctrl, "$space$line");
                            $space = ' ';
                        }
                    }
#::here::
                    if (!defined ($form->{'blog'}) || ($form->{'blog'} ne "on")) {
                        &l00httpd::l00fwriteBuf($ctrl, "\n");
                    }
                    &l00httpd::l00fwriteBuf($ctrl, $buforg);
                    &l00httpd::l00fwriteClose($ctrl);
                } else {
                    print $sock "Unable to write '$form->{'path'}'<p>\n";
                }
            }
        }
    }

    # do funny tricks to switch log style
#::here::
    if (defined ($form->{'logstyle'})) {
        $form->{'cancel'} = 'NewTime';
        $form->{'blog'} = undef;
    }
    if (defined ($form->{'blogstyle'})) {
        $form->{'cancel'} = 'NewTime';
        $form->{'blog'} = 'on';
    }

    # make header
    if ($currstyle eq 'log') {
        # log
        $buffer = $ctrl->{'now_string'} . ' ';
    } elsif ($currstyle eq 'blog') {
        # blog
        $buffer = "==$ctrl->{'now_string'} ==\n* ";
    } elsif ($currstyle eq 'bare') {
        # bare
        $buffer = "";
    }
#::here::
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
        $buffer .= &blog_get_msg ($form->{'buffer'}, $currstyle);
#::here::
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
        $buffer .= &l00httpd::l00getCB($ctrl);
    }
    if (defined ($form->{'pasteadd'})) {
        $buffer = $form->{'buffer'} . ' ';
        $buffer .= &l00httpd::l00getCB($ctrl);
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
                if ($keys != 0) {
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
            $output .= "Path: <a href=\"/view.htm?path=$form->{'path'}\">View formatted text</a><br>\n";
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
    if (defined($form->{'afterline'})) {
        print $sock "<input type=\"text\" size=\"4\" name=\"afterline\" value=\"$form->{'afterline'}\">\n";
    }
    print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
    if (defined ($form->{'blog'})) {
        print $sock "<input type=\"hidden\" name=\"blog\" value=\"$form->{'blog'}\">\n";
    }
    print $sock "<br><input type=\"submit\" name=\"timesave\" value=\"TimeSave\">\n";
    print $sock "<input type=\"submit\" name=\"cancel\" value=\"NewTime\">\n";
    # display button to switch style
#::here::
    if (defined ($form->{'blog'})) {
        print $sock "<input type=\"submit\" name=\"logstyle\" value=\"Log style add\">\n";
        print $sock "<input type=\"hidden\" name=\"currstyle\" value=\"log\">\n";
    } else {
        print $sock "<input type=\"submit\" name=\"blogstyle\" value=\"Blog style add\">\n";
        print $sock "<input type=\"hidden\" name=\"currstyle\" value=\"blog\">\n";
    }
    print $sock "</form><br>\n";

    print $sock $output;

    print $sock "<hr><a name=\"end\"></a>";
    print $sock "<a href=\"#__top__\">top</a>\n";
    print $sock "<br>\n";
    print $sock "<br>\n";
    print $sock "<br>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
