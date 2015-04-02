use strict;
use warnings;
use l00Blowfish_PP;
use l00crypt;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14


my %config = (proc => "l00http_filecrypt_proc",
              desc => "l00http_filecrypt_desc");
my ($pass, $cryptto, $comment, $buffer, $newext, %cache);
$pass = '';
$comment = '';
$newext = '';
$cryptto = 0;



sub l00http_filecrypt_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/


    "filecrypt: This is a cryptography testbed";
}

sub l00http_filecrypt_proc (\%) {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($hout, $raw, $httphdr, $size, $fext, $targetfname);
    my ($line, $pre, $post, $phase, $lineno, $path, $fname, $binlen);
    my ($crypt, $plain, $plain2, $filemethod, $tmp, $action, $tnext);
    my ($filecmt, $filemeta, $encr1decy2, $bytesent, $timst);
    $crypt = '';
    $plain = '';
    $tmp = '';
    $action = '';
    $hout = '';
    $raw = 0;

    # Send HTTP and HTML headers
    $hout .= $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} .$ctrl->{'htmlhead2'};
    $hout .= "$ctrl->{'home'} $ctrl->{'HOME'} \n";
    if (defined ($form->{'path'})) {
        $hout .= "Path: <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a> \n";
        my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
        $size, $atime, $mtime, $ctime, $blksize, $blocks)
        = stat($form->{'path'});
        if (defined ($size)) {
            $tmp = $size . ' bytes/' . $size / 1147 . ' secs';
        } else {
            $tmp = 'unknown';
        }
    }
    $hout .= "Be patience, cryptography is slow in pure Perl on Android. $tmp<hr>\n";


    if ((defined ($form->{'pass1'})) && 
        (length ($form->{'pass1'}))) {
        # got one password, ok for decrypt; $comment = '' prevent encrypt
        $pass = $form->{'pass1'};
        $comment = '';
        $newext = '';
    }
    if ((defined ($form->{'pass1'})) && 
        (defined ($form->{'pass2'})) && 
        (length ($form->{'pass1'}) > 0) && 
        (length ($form->{'pass2'}) > 0) && 
        ($form->{'pass1'} eq $form->{'pass2'})) {
        # password match, remember
        $pass = $form->{'pass1'};
        if ((defined ($form->{'comment'})) && 
            (length ($form->{'comment'}) > 0)) {
            $comment = $form->{'comment'};
        }
        if ((defined ($form->{'newext'})) && 
            (length ($form->{'newext'}) > 0)) {
            $newext = $form->{'newext'};
        }
    }
    if (defined ($form->{'clear'})) {
        $pass = '';
        undef %cache;
    }
    if (($cryptto > 0) &&
        (time >= $cryptto))  {
        # timeout
        $cryptto = 0;
        $pass = '';
        undef %cache;
    }
    if (($cryptto == 0) && (defined ($form->{'cryptto'}))) {
        # if timeout not running and defined, remember
        $cryptto = time + $form->{'cryptto'} * 60;
    }

    # do we have password?
    if (($pass eq '') ||
        (!defined ($form->{'path'})) ||
        (length ($form->{'path'}) <= 0)) {
        # no password, to get password, 
        # or no target, allow to change password
        $hout .= "<form action=\"/filecrypt.htm\" method=\"post\">\n";
        $hout .= "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
        $hout .= "<tr><td>\n";
        $hout .= "Password:\n";
        $hout .= "</td><td>\n";
        $hout .= "<input type=\"password\" size=\"10\" name=\"pass1\" value=\"$pass\">\n";
        $hout .= "</td></tr>\n";
        $hout .= "<tr><td>\n";
        $hout .= "Password again:\n";
        $hout .= "</td><td>\n";
        $hout .= "<input type=\"password\" size=\"10\" name=\"pass2\" value=\"$pass\">\n";
        $hout .= "</td></tr>\n";
        $hout .= "<tr><td>\n";
        $hout .= "Comment:\n";
        $hout .= "</td><td>\n";
        $hout .= "<input type=\"text\" size=\"10\" name=\"comment\" value=\"$comment\">\n";
        $hout .= "</td></tr>\n";
        $hout .= "<tr><td>\n";
        $hout .= "Extension:\n";
        $hout .= "</td><td>\n";
        $hout .= "<input type=\"text\" size=\"10\" name=\"newext\" value=\"$newext\">\n";
        $hout .= "</td></tr>\n";
        $hout .= "<tr><td>\n";
        $hout .= "<input type=\"submit\" name=\"setpass\" value=\"Set password\">\n";
        $hout .= "</td><td>\n";
        $hout .= "password twice";
        $hout .= "</td></tr>\n";
        $hout .= "<tr><td>\n";
        $hout .= "Timeout:\n";
        $hout .= "</td><td>\n";
        if ($cryptto == 0) {
            $tmp = $ctrl->{'cryptto'};
        } else {
            $tmp = int (($cryptto - time + 30) / 60);
        }
        $hout .= "<input type=\"text\" size=\"5\" name=\"cryptto\" value=\"$tmp\"> min.\n";
        $hout .= "</td></tr>\n";
        $hout .= "</table><br>\n";
        $hout .= "</form>\n";

        $hout .= "<form action=\"/filecrypt.htm\" method=\"get\">\n";
        $hout .= "<input type=\"submit\" name=\"clear\" value=\"Clear passphrase\">\n";
        $hout .= "</form>\n";
    } else {
        # have password and target
        # we have a target
        $encr1decy2 = 0;
        if (($path, $fname, $fext) = ($form->{'path'} =~ /^(.+)\/([^\/]+)\.([^.]+)$/)) {
            if (open (IN, "<$form->{'path'}")) {
                # target exist
                binmode (IN);
                # http://www.perlmonks.org/?node_id=1952
                local $/ = undef;
                $buffer = <IN>;
                close (IN);
                # try to validate and retrieve comment
                ($plain, $binlen, $filecmt, $filemeta) = l00crypt::l00decryptbin ('', $buffer, 0, 0);
                if ($plain eq 'Invalid file') {
                    if ((length($comment) <= 1) ||
                        (length($newext) <= 1)) {
                        # need comment and file extension to encrypt
                        $encr1decy2 = 0;
                        $hout .= "Comment and Extension not set. Set them in \n";
                        $hout .= "<a href=\"/filecrypt.htm\">filecrypt password management</a>\n";
                    } else {
                        # not encrypted file, to encrypt
                        $encr1decy2 = 1;
                        $targetfname = "$path/$fname.$newext";
                    }
                } else {
                    # target is encrypted file
                    if ($filecmt eq '') {
                        # encrypted file wihtout hidden extension, to decrypt
                        $encr1decy2 = 2;
                    } else {
                        # encrypted file with hidden extension, 
                        # generate link to decrypt
                        $targetfname = "$path/$fname.$fext.$filemeta";
                        $hout .= "<a href=\"/filecrypt.htm/$fname.$fext.$filemeta?path=$targetfname\">Click this link once to decrypt: $targetfname</a><p>\n";
                        # get comment
                        $hout .= "Comment: $filecmt<p>\n";
                        $hout .= "<a href=\"/filecrypt.htm\">filecrypt password management</a>\n";
                    }
                }
            } else {
                # target not exist as provided; try to remove phantom extension
                if (open (IN, "<$path/$fname")) {
                    # target exist
                    binmode (IN);
                    # http://www.perlmonks.org/?node_id=1952
                    local $/ = undef;
                    $buffer = <IN>;
                    close (IN);
                    # try to validate and retrieve comment
                    ($plain, $binlen, $filecmt, $filemeta) = l00crypt::l00decryptbin ('', $buffer, 0, 0);
                    if ($plain eq 'Invalid file') {
                        # unexpected
                        $encr1decy2 = 0;
                    } else {
                        # encrypted file, to decrypt
                        $encr1decy2 = 2;
                        $fname = ".$fext";
                    }
                }
            }
        } else {
            $encr1decy2 = 0;
            $hout .= "Filename mush have extension\n";
        }

        if ($encr1decy2 == 1) {
            $crypt = l00crypt::l00encryptbin ($pass, $buffer, $comment, $fext, 0, 0);
            $hout .= "Encrypted  ". length ($crypt). " bytes<p>\n";
            if (open (OUT, ">$targetfname")) {
                binmode (OUT);
                print OUT $crypt;
                close (OUT);
                #unlink ($form->{'path'});
            }
            $hout .= "<a href=\"/filecrypt.htm/$fname.$fext?path=$targetfname.$fext\">To decrypt $targetfname</a>\n";
        } elsif ($encr1decy2 == 2) {
            $hout = "HTTP/1.1 200 OK\r\nContent-Type: ";
            if (($fname =~ /\.zip$/i) ||
                ($fname =~ /\.kmz$/i)) {
                $hout = "application/x-zip\r\n";
            } elsif (($fname =~ /\.jpeg$/i) ||
                     ($fname =~ /\.jpg$/i)) {
                $hout .= "image/jpeg\r\n";
            } elsif ($fname =~ /\.wma$/i) {
                $hout .= "audio/x-ms-wma\r\n";
            } elsif ($fname =~ /\.3gp$/i) {
                $hout .= "audio/3gp\r\n";
            } elsif ($fname =~ /\.mp3$/i) {
                $hout .= "audio/mpeg\r\n";
            } elsif ($fname =~ /\.gif$/i) {
                $hout .= "image/gif\r\n";
            } elsif ($fname =~ /\.png$/i) {
                $hout .= "image/png\r\n";
            } elsif (($fname =~ /\.html$/i) ||
                     ($fname =~ /\.htm$/i) ||
                     ($fname =~ /\.txt$/i)) {
                $hout .= "text/html\r\n";
            } else {
                $hout .= "application/octet-octet-stream\r\n";
            }
            $raw = 1;
            $timst = time;
            if (defined ($cache{$form->{'path'}})) {
                $binlen = length ($cache{$form->{'path'}});
                $bytesent = $binlen;
            } else {
                ($plain, $binlen, $filecmt, $filemeta) = l00crypt::l00decryptbin ($pass, $buffer, 0, 8192);
                $bytesent = length ($plain);
            }

            $hout .= "Content-Length: $binlen\r\n";
            $hout .= "Connection: close\r\nServer: l00httpd\r\n\r\n";
            print $sock $hout;

            #$off, $len, $lenttl

            if (defined ($cache{$form->{'path'}})) {
                print $sock $cache{$form->{'path'}};
            } else {
                $cache{$form->{'path'}} = $plain;
                print $sock $plain;
                $tnext = time;
                while ($bytesent < $binlen) {
                    if ((time - $tnext) >= 3) {
                        print "$binlen : $bytesent [", int (100 * $bytesent / $binlen), "%] (", time - $timst, "s)\n";
                        $tnext = time;
                    }
                    ($plain, $binlen, $filecmt, $filemeta) = l00crypt::l00decryptbin ($pass, $buffer, $bytesent, 8192);
                    $cache{$form->{'path'}} .= $plain;
                    $bytesent += length ($plain);
                    print $sock $plain;
                }
            }
            print "$bytesent\n";
        }
    }


    # send HTML footer and ends
    if ($raw == 0) {
        $hout .= $ctrl->{'htmlfoot'};
        print $sock $hout;
    }
}


\%config;

