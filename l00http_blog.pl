use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_blog_proc",
              desc => "l00http_blog_desc");
my ($buffer, $lastbuf, %addtimeval);
$lastbuf = '';

%addtimeval = (
    'NewTime' => 0,
    '1h' => 3600,
    '2h' => 7200,
    '5h' => 18000,
    '10h' => 36000,
    '1d' => 86400,
    '2d' => 172800,
    '5d' => 432000,
    '28d' => 2419200);


sub blog_make_hdr {
    my ($ctrl, $style, $addtime) = @_;
    my ($buffer, $sock, $now_string);
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime (time + $addtime);
    $now_string = sprintf ("%4d%02d%02d %02d%02d%02d", $year + 1900, $mon+1, $mday, $hour, $min, $sec);

    $buffer = '';

    if ($style eq 'log') {
        # log
        $buffer = $now_string . ' ';
    } elsif ($style eq 'star') {
        # star
        $buffer = '* ' . $now_string . ' ';
    } elsif ($style eq 'blog') {
        # blog
        $buffer = "==$now_string ==\n* ";
    } elsif ($style eq 'bare') {
        # bare
        # nothing
    }

    $buffer;
}

sub blog_get_msg {
    my ($buffer, $style) = @_;

    if (!defined ($buffer)) {
        $buffer = '';
    }

    if ($style eq 'log') {
        # log
        $buffer = substr ($buffer, 16, 9999);
    } elsif ($style eq 'star') {
        # star
        $buffer = substr ($buffer, 18, 9999);
    } elsif ($style eq 'blog') {
        # blog
        $buffer = substr ($buffer, 24, 9999);
    } elsif ($style eq 'bare') {
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
## star style:
### * 20150322 120000
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
## stylecurr: indicate style for the just submitted form, 
## stylenew: transform form buffer from CurrentStyle to NewtStyle
## stylecurr and stylenew default to log style if missing



sub l00http_blog_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my (@alllines, $line, $lineno, $path, $buforg, $buforgpre, $fname, $pname);
    my ($output, $keys, $key, $space, $stylecurr, $stylenew, $addtime);

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

    $stylecurr = 'log';
    if (defined ($form->{'stylecurr'})) {
        if ($form->{'stylecurr'} eq 'log') {
            $stylecurr = 'log';
        } elsif ($form->{'stylecurr'} eq 'blog') {
            $stylecurr = 'blog';
        } elsif ($form->{'stylecurr'} eq 'bare') {
            $stylecurr = 'bare';
        } elsif ($form->{'stylecurr'} eq 'star') {
            $stylecurr = 'star';
        }
    }
    $stylenew = $stylecurr;
    if (defined ($form->{'setnewstyle'}) &&
		defined ($form->{'stylenew'})) {
        if ($form->{'stylenew'} eq 'log') {
            $stylenew = 'log';
        } elsif ($form->{'stylenew'} eq 'blog') {
            $stylenew = 'blog';
        } elsif ($form->{'stylenew'} eq 'bare') {
            $stylenew = 'bare';
        } elsif ($form->{'stylenew'} eq 'star') {
            $stylenew = 'star';
        }
    }

    $addtime = 0;
    if (defined ($form->{'newtime'})) {
        # new time
        $addtime = $addtimeval{$form->{'newtime'}};
        $buffer = &blog_get_msg ($form->{'buffer'}, $stylecurr);
        $form->{'buffer'} = &blog_make_hdr ($ctrl, $stylecurr, $addtime);
        $form->{'buffer'} .= $buffer;
    }


    if (defined ($form->{'timesave'})) {
        # update time and save form buffer
        $buffer = &blog_get_msg ($form->{'buffer'}, $stylecurr);
        $form->{'buffer'} = &blog_make_hdr ($ctrl, $stylecurr, 0);
        $form->{'buffer'} .= $buffer;
        # fake a 'Save' click
        $form->{'save'} = 1;
    }
    if (defined ($form->{'pastesave'})) {
        $form->{'buffer'} = &blog_make_hdr ($ctrl, $stylecurr, 0);
        $form->{'buffer'} .= &l00httpd::l00getCB($ctrl);
        $form->{'save'} = 1;
    }

    if (defined ($form->{'save'})) {
        if ((defined ($form->{'buffer'})) &&
            ((defined ($form->{'path'})) && 
            (length ($form->{'path'}) > 0))) {
            $buffer = $form->{'buffer'};
#           if (($buffer ne $lastbuf) &&
#               !($buffer =~ /^\d{8,8} \d{6,6} $/))
            if ($buffer ne $lastbuf) {
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
                        if ($stylecurr eq 'blog') {
                            # blog
                            &l00httpd::l00fwriteBuf($ctrl, "$line\n");
                        } else {
                            &l00httpd::l00fwriteBuf($ctrl, "$space$line");
                            $space = ' ';
                        }
                    }
                    if ($stylecurr ne 'blog') {
                        &l00httpd::l00fwriteBuf($ctrl, "\n");
                    }
                    &l00httpd::l00fwriteBuf($ctrl, $buforg);
                    &l00httpd::l00fwriteClose($ctrl);
                } else {
                    print $sock "Unable to write '$form->{'path'}'<p>\n";
                }
				# saved, clear buffer
				$form->{'buffer'} = '';
            }
        }
    }


    # make header
    $buffer = &blog_make_hdr ($ctrl, $stylenew, $addtime);

    if (defined ($form->{'paste'})) {
        $buffer .= &l00httpd::l00getCB($ctrl);
    } elsif (defined ($form->{'pasteadd'})) {
        $buffer .= &blog_get_msg ($form->{'buffer'}, $stylecurr) . ' ';
        $buffer .= &l00httpd::l00getCB($ctrl);
    } else {
        $buffer .= &blog_get_msg ($form->{'buffer'}, $stylecurr);
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
    print $sock "<br><input type=\"submit\" name=\"timesave\" value=\"TimeSave\">\n";
    print $sock "<input type=\"submit\" name=\"newtime\" value=\"NewTime\">\n";
    # display button to switch style

    print $sock "<input type=\"hidden\" name=\"stylecurr\" value=\"$stylenew\">\n";
    if ($stylenew eq 'log') {
        # log
        print $sock "<input type=\"submit\" name=\"setnewstyle\" value=\"Blog style add\">\n";
        print $sock "<input type=\"hidden\" name=\"stylenew\"    value=\"star\">\n";
    } elsif ($stylenew eq 'star') {
        # star
        print $sock "<input type=\"submit\" name=\"setnewstyle\" value=\"Star style add\">\n";
        print $sock "<input type=\"hidden\" name=\"stylenew\"    value=\"blog\">\n";
    } elsif ($stylenew eq 'blog') {
        # blog
        print $sock "<input type=\"submit\" name=\"setnewstyle\" value=\"Bare style add\">\n";
        print $sock "<input type=\"hidden\" name=\"stylenew\"    value=\"bare\">\n";
    } elsif ($stylenew eq 'bare') {
        # bare
        print $sock "<input type=\"submit\" name=\"setnewstyle\" value=\"Log style add\">\n";
        print $sock "<input type=\"hidden\" name=\"stylenew\"    value=\"log\">\n";
    }
    print $sock "<p>";
    $_ = 'style="height:1.4em; width:2.3em"';
    print $sock "<input type=\"submit\" name=\"newtime\"  value=\"1h\"  $_>\n";
    print $sock "<input type=\"submit\" name=\"newtime\"  value=\"2h\"  $_>\n";
    print $sock "<input type=\"submit\" name=\"newtime\"  value=\"5h\"  $_>\n";
    print $sock "<input type=\"submit\" name=\"newtime\" value=\"10h\" $_>\n";
    print $sock "<input type=\"submit\" name=\"newtime\"  value=\"1d\"  $_>\n";
    print $sock "<input type=\"submit\" name=\"newtime\"  value=\"2d\"  $_>\n";
    print $sock "<input type=\"submit\" name=\"newtime\"  value=\"5d\"  $_>\n";
    print $sock "<input type=\"submit\" name=\"newtime\" value=\"28d\" $_>\n";

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
