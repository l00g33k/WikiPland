use strict;
use warnings;
use l00Blowfish_PP;
use l00crypt;
use l00backup;
use l00httpd;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14


my %config = (proc => "l00http_crypt_proc",
              desc => "l00http_crypt_desc");
my ($name, $key, $val, $findtext, $block, $blocktext);
my ($pass, $cryptbound, $method, $found, $hit, $cryptto);
my ($cryptex);
$pass = "";
$method = "rot";
$cryptbound = "---===###crypt";
$findtext = "";
$block = "^=";
$cryptto = 0;
$cryptex = ':';


sub l00http_crypt_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/

    if (defined ($ctrl->{'cryptmethod'})) {
        $method = $ctrl->{'cryptmethod'};
    }

    "crypt: This is a cryptography testbed";
}

sub l00http_crypt_proc (\%) {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($buffer, $line, $pre, $post, $phase, $lineno);
    my ($crypt, $plain, $plain2, $filemethod, $tmp);
    $crypt = "";
    $plain = "";
    $tmp = '';


    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} .$ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} \n";
    if (defined ($form->{'path'})) {
        print $sock "Path: <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a> \n";
        my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
        $size, $atime, $mtime, $ctime, $blksize, $blocks)
        = stat($form->{'path'});
        $tmp = $size . ' bytes/' . $size / 2000 . ' secs';
    }
    print $sock "<a href=\"#end\">Jump to end</a> \n";
    print $sock "<a href=\"#pass\">pass</a> \n";
    print $sock "<a href=\"#__toc__\">TOC</a>\n";

    print $sock "<a href=\"#find\">find</a> Be patience, cryptography is slow in pure Perl on Android. $tmp.\n";


    if (defined ($form->{'save'}) ||
        defined ($form->{'edittocb'}) ||
        defined ($form->{'cbtoedit'}) ||
        defined ($form->{'fromram'}) ||
        defined ($form->{'toram'})) {
        if ((defined ($form->{'pass1'})) && 
            (defined ($form->{'pass2'})) && 
            ($form->{'pass1'} eq $form->{'pass2'})) {
            $pass = $form->{'pass1'};
        }
    } else {
        if (time >= $cryptto)  {
            # timeout
            $cryptto = 0;
            $pass = "";
        }
    }
    if (defined ($form->{'decrypt'})) {
        if (defined ($form->{'pass1'}))  {
            $pass = $form->{'pass1'};
        }
    }
    if (($cryptto == 0) && (defined ($form->{'cryptto'}))) {
        $cryptto = time + $form->{'cryptto'} * 60;
    }
    if (defined ($form->{'method'})) {
        $method = $form->{'method'};
    }

    if (defined ($form->{'clear'})) {
        $pass = "";
    }

    $buffer = '';
    $plain = '';
    if (defined ($form->{'fromram'})) {
        # retrieve from ram buffer, save, then clear ram buffer
        if (&l00httpd::l00freadOpen($ctrl, "l00://crypt.htm")) {
            $form->{'buffer'} = &l00httpd::l00freadAll($ctrl);
            $form->{'save'} = 1;
            # clear ram buffer
            &l00httpd::l00fwriteOpen($ctrl, 'l00://crypt.htm');
            &l00httpd::l00fwriteBuf($ctrl, '');
            &l00httpd::l00fwriteClose($ctrl);
		}
    }
    if (defined ($form->{'save'}) ||
        defined ($form->{'edittocb'}) ||
        defined ($form->{'cbtoedit'}) ||
        defined ($form->{'fromram'}) ||
        defined ($form->{'toram'})) {
        if (($pass ne '') &&
            (defined ($form->{'buffer'})) &&
            ((defined ($form->{'path'})) && 
            (length ($form->{'path'}) > 0))) {
            # get from browser
            $buffer = $form->{'buffer'};
            $plain = "true";
        }
    } else {
        # read from file
        if ((defined ($form->{'path'})) && 
            (length ($form->{'path'}) > 0)) {
            if (&l00httpd::l00freadOpen($ctrl, "$form->{'path'}")) {
                $buffer = &l00httpd::l00freadAll($ctrl);
            }
        }
    }

    # extract texts before and after table 
    $pre = "";
    $crypt = "";
    $post = "";
    $buffer =~ s/\r//g;
    $phase = 0;
    foreach $line (split ("\n", $buffer)) {
        if ($phase == 0) {
            if ($line =~ /^$cryptbound:(.+):/) {
                $filemethod = $1;
                $phase = 1;
            } else {
                if ($pre ne "") {
                    $pre .= "\n";
                }
                $pre .= $line;
            }
        } elsif ($phase == 1) {
            if ($line =~ /^$cryptbound/) {
                $phase = 2;
            } else {
                if ($crypt ne "") {
                    $crypt .= "\n";
                }
                $crypt .= $line;
            }
        } elsif ($phase == 2) {
            if ($post ne "") {
                $post .= "\n";
            }
            $post .= "$line";
        }
    }

    if ($pass eq "") {
        $plain = $crypt;
        print $sock "<hr><h1>Passphrase not set!</h1></p><hr>\n";
    } else {
        print $sock "Jump to <a href=\"#toram\">save to RAM</a>, then ".
            "<a href=\"/edit.htm?path=l00://crypt.htm\" target=\"newwin\">edit RAM</a><hr>\n";

        if ($plain eq "true") {
            $plain = $crypt;
            $crypt = l00crypt::l00encrypt ($pass, $plain, $method);
        } else {
            $method = $filemethod;
            $plain = l00crypt::l00decrypt ($pass, $crypt, $method);
        }
    }


    # if convert, save to file
    if ((defined ($form->{'save'}) &&
        (defined ($form->{'path'})) && 
        (length ($form->{'path'}) > 0))) {
        if ($pass eq "") {
            print $sock "<p><h1>Passphrases do not match.  Content not saved!</h1></p>";
        } else {
            if (defined ($form->{'save'})) {
                if (!($form->{'path'} =~ /^l00:\/\//)) {
                    &l00backup::backupfile ($ctrl, $form->{'path'}, 1, 5);
                }
                if (&l00httpd::l00fwriteOpen($ctrl, $form->{'path'})) {
                    &l00httpd::l00fwriteBuf($ctrl, "$pre\n$cryptbound:$method:\n$crypt\n$cryptbound:$method:\n$post");
                    &l00httpd::l00fwriteClose($ctrl);
                } else {
                    print $sock "Unable to write '$form->{'path'}'<p>\n";
                }
            }
        }
    }

    $found = '';
    if (defined ($form->{'find'})) {
        $found = "Find in file results:\n";
        if (defined ($form->{'findtext'})) {
            $findtext = $form->{'findtext'};
        }
        if (defined ($form->{'block'})) {
            $block = $form->{'block'};
        }
        $found .= &l00httpd::findInBuf ($findtext, $block, $plain);
        $found .= "<hr>Find in file results\n";
    }

    # $plain extender
    $plain2 = $plain;
    foreach $line (split ("\n", $plain)) {
        if ($line =~ /^\[\[!(l00_crypt_ex_.*\.pl)\]\]/) {
            if ($cryptex ne $1) {
                $cryptex = $1;
                #print $sock "Extender: $ctrl->{'plpath'}$cryptex<br>\n";
                my ($rethash);
                $rethash = do $ctrl->{'plpath'}.$cryptex;
                if (!defined ($rethash)) {
                    if ($!) {
                        print $sock "Can't read module: $!\n";
                    } elsif ($@) {
                        print $sock "Can't parse module: $@\n";
                    }
                } else {
                    # Invoke extender to convert $plain
                    $plain2 = __PACKAGE__->l00_crypt_ex_entry(\%$ctrl, $plain, $form->{'path'});
                }
            } else {
                # Invoke extender to convert $plain
                $plain2 = __PACKAGE__->l00_crypt_ex_entry(\%$ctrl, $plain, $form->{'path'});
            }
        }
    }

    # Render HTML with found text and translated plain2
    if ((defined ($form->{'savedecrypt'})) && 
        (length($form->{'savedecrypt'}) > 0) &&
        (!($form->{'savedecrypt'} =~ /^ *$/))) {
        # save decrypted to file
        if (&l00httpd::l00fwriteOpen($ctrl, $form->{'savedecrypt'})) {
            &l00httpd::l00fwriteBuf($ctrl, $plain);
            &l00httpd::l00fwriteClose($ctrl);
            print $sock "Decrypted content saved to: ".
                "<a href=\"/ls.htm?path=$form->{'savedecrypt'}\">$form->{'savedecrypt'}</a><p>\n";
        }
    } else {
        $buffer = "$found$pre\n$cryptbound:$method:\n$plain2\n$cryptbound:$method:\n$post";
        print $sock &l00wikihtml::wikihtml ($ctrl, $ctrl->{'plpath'}, $buffer, 0);
    }

    $buffer = "$pre\n$cryptbound:$method:\n$plain\n$cryptbound:$method:\n$post";
    # copy to clipboard
    if (defined ($form->{'edittocb'})) {
        &l00httpd::l00setCB($ctrl, $buffer);
    }
    if (defined ($form->{'cbtoedit'})) {
        # paste from clipboard
        $buffer = &l00httpd::l00getCB($ctrl);
    }
    if (defined ($form->{'toram'})) {
        &l00httpd::l00fwriteOpen($ctrl, 'l00://crypt.htm');
        &l00httpd::l00fwriteBuf($ctrl, $buffer);
        &l00httpd::l00fwriteClose($ctrl);
    }

    print $sock "<hr><a name=\"end\"></a>\n";

    print $sock "<form action=\"/crypt.htm\" method=\"post\">\n";
    print $sock "<textarea name=\"buffer\" cols=\"$ctrl->{'txtw'}\" rows=\"$ctrl->{'txth'}\">$buffer</textarea>\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"save\" value=\"Save\">\n";
    print $sock "</td><td>\n";
    print $sock "password twice";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"password\" size=\"10\" name=\"pass1\" value=\"$pass\">\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"password\" size=\"10\" name=\"pass2\" value=\"$pass\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"text\" size=\"10\" name=\"method\" value=\"$method\">\n";
    print $sock "</td><td>\n";
    print $sock "Method: rot, base, blow\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "Path:\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"text\" size=\"16\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "<a name=\"toram\"></a><input type=\"submit\" name=\"toram\" value=\"edit to ram\">\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"submit\" name=\"fromram\" value=\"save ram\">\n";
    print $sock "<a href=\"/edit.htm?path=l00://crypt.htm\" target=\"newwin\">edit ram</a> \n";
    print $sock "</td></tr>\n";
    if ($ctrl->{'os'} eq 'and') {
        print $sock "<tr><td>\n";
        print $sock "<input type=\"submit\" name=\"edittocb\" value=\"edit to CB\">\n";
        print $sock "</td><td>\n";
        print $sock "<input type=\"submit\" name=\"cbtoedit\" value=\"CB to edit\">\n";
        print $sock "</td></tr>\n";
    }
    print $sock "</table><br>\n";
    print $sock "</form>\n";

    # decrypt
    print $sock "<hr><a name=\"pass\"></a>\n";
    print $sock "<form action=\"/crypt.htm\" method=\"post\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"password\" size=\"10\" name=\"pass1\" value=\"$pass\">\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"submit\" name=\"decrypt\" value=\"Decrypt file\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "Timeout:\n";
    print $sock "</td><td>\n";
    if ($cryptto == 0) {
        $tmp = $ctrl->{'cryptto'};
    } else {
        $tmp = int (($cryptto - time + 30) / 60);
    }
    print $sock "<input type=\"text\" size=\"5\" name=\"cryptto\" value=\"$tmp\"> min.\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "Path:\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"text\" size=\"16\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "Save decrypt:\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"text\" size=\"16\" name=\"savedecrypt\" value=\"\">\n";
    print $sock "</td></tr>\n";
    print $sock "</table>\n";
    print $sock "</form>\n";

    print $sock "<br><form action=\"/crypt.htm\" method=\"get\">\n";
    print $sock "<input type=\"submit\" name=\"clear\" value=\"Clear passphrase\">\n";
    print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "<a href=\"#__toc__\">TOC</a>\n";
    print $sock "<a href=\"#___top___\">Top</a>\n";
    print $sock "</form>\n";

    print $sock " <form action=\"/crypt.htm\" method=\"get\">\n";
    print $sock "<input type=\"submit\" name=\"raw\" value=\"Dump raw file\">\n";
    print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "</form>\n";

    # find
    print $sock "<hr><a name=\"find\"></a>\n";
    print $sock "<br><form action=\"/crypt.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"find\" value=\"Find\">\n";
    print $sock "</td><td>\n";
    print $sock "Find in file\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "RegEx:\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"text\" size=\"16\" name=\"findtext\" value=\"$findtext\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "Blockmark:\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"text\" size=\"16\" name=\"block\" value=\"$block\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "File:\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"text\" size=\"16\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "</td></tr>\n";
    print $sock "</table>\n";
    print $sock "</form>\n";
    print $sock "Blockmark: Regex matching start of block. e.g. '^=' or '^\\* '\n";


    # print raw ASCII texts
    if (defined ($form->{'raw'})) {
        print $sock "<pre>\n";
        $lineno = 1;
        foreach $line (split ("\n", "$pre\n$cryptbound:$method:\n$crypt\n$cryptbound:$method:\n$post")) {
            $line =~ s/</&lt;/g;
            $line =~ s/>/&gt;/g;
            print $sock sprintf ("%04d: ", $lineno++) . "$line\n";
        }
        print $sock "</pre>\n";
    }


    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
