# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

use strict;
use warnings;
use l00Blowfish_PP;
use l00base64;

package l00crypt;


sub l00encrypt {
    my ($phrase, $buffer, $method) = @_;
    my ($out, $ln);

    $out = $buffer;
    
    if ($method eq 'blow') {
        # blowfish; make passphrase >= i bytes; <= ty bytes
        while (length ($phrase) < 8) {
            $phrase .= $phrase;
        }
        my ($len);
        $len = length ($buffer);
        # prepend with control and append with paddings
        $buffer = sprintf ("blowfish%8dbytes:", $len) . 
            $buffer . "       ";
        $len += 22 + 7;
        $out = $buffer;
        my ($ii);
        my $cipher = new l00Blowfish_PP $phrase;
        # encrypt in i bytes block
        for ($ii = 0; $ii < $len; $ii += 8) {
            substr ($out,$ii,8) =
                $cipher->encrypt(substr ($buffer,$ii,8));
        }
        # chop off extra paddings
        $out = substr ($out,0,$ii);
        # base64 to make it printable
        $out = l00base64::b64encode($out);
    }

    if ($method eq 'base') {
        $out = l00base64::b64encode($buffer);
    }

    if ($method eq 'rot') {
        $out = "";
        $buffer =~ s/\r//g;
        foreach $ln (split ("\n", $buffer)) {
            $ln =~ s/(.)/pack("C",unpack("C",$1)+$phrase)/seg;
            if ($out ne "") {
                $out .= "\n";
            }
            $out .= $ln;
        }
    }
    
    $out;
}


sub l00decrypt {
    my ($phrase, $buffer, $method) = @_;
    my ($out, $ln);

    $out = $buffer;
    
    if ($method eq 'blow') {
        while (length ($phrase) < 8) {
            $phrase .= $phrase;
        }
        # base64 back to binary
        $out = l00base64::b64decode($buffer);
        my $cipher = new l00Blowfish_PP $phrase;
        my ($ii, $len);
        $len = length ($out);
        # decrypt
        for ($ii = 0; $ii < $len; $ii += 8) {
            substr ($out,$ii,8) =
                $cipher->decrypt(substr ($out,$ii,8));
        }
        # check control header; does not protect against corrupted  cipher text!
        if (substr ($out,0,22) =~ /^blowfish *(\d+)bytes:$/) {
            $len = $1;
            if (length ($out) >= $len + 22) {
                # seems to be in order, return it
                $out = substr ($out, 22, $len);
            } else {
                $out = "Decrypted length too short.  Unable to decrypt.\n";
            }
        } else {
            $out = "Passphrase incorrect.  Unable to decrypt.\n";
        }
    }

    if ($method eq 'base') {
        $out = l00base64::b64decode($buffer);
    }

    if ($method eq 'rot') {
        $out = "";
        $buffer =~ s/\r//g;
        foreach $ln (split ("\n", $buffer)) {
            $ln =~ s/(.)/pack("C",unpack("C",$1)-$phrase)/seg;
            if ($out ne "") {
                $out .= "\n";
            }
            $out .= $ln;
        }
    }
    
    $out;
}



sub l00encryptbin {
    my ($phrase, $buffer, $comment, $meta, $encoff, $enclen) = @_;
    my ($out, $ln, $cmtlen, $hdrbuf);
    my ($len, $ii, $hdrlen, $metalen);
    my ($timst, $tnext, $more);


    # blowfish; make passphrase >= i bytes; <= ty bytes
    while (length ($phrase) < 8) {
        $phrase .= $phrase;
    }
    $len = length ($buffer);
    $cmtlen = length ($comment) + 1;
    $metalen = length ($meta) + 1;
    if (0) {
        $out = pack ("A4NnnZ$cmtlen"."Z$metalen", 'fHdR', $len, $cmtlen, $metalen, $comment, $meta);
        $hdrlen = length ($out);
    } else {
        my $cipherhdr = new l00Blowfish_PP 'l00crypt';
        # bytes 0-3
        $out = pack ("A4", 'fHDr');
        $hdrbuf = pack ("Nnn", $len, $cmtlen, $metalen);
        # bytes 4-11
        substr ($out, 4, 8) = $cipherhdr->encrypt($hdrbuf);
        $hdrbuf = pack ("Z$cmtlen"."Z$metalen"."Z8", $comment, $meta, '        ');
        $hdrlen = $cmtlen + $metalen + 7;
        $hdrlen &= 0xfff8;
        # bytes 12-15...
        for ($ii = 0; $ii < $hdrlen; $ii += 8) {
            substr ($out, $ii + 12, 8) =
                $cipherhdr->encrypt(substr ($hdrbuf,$ii,8));
        }
        $hdrlen += 12;
    }
    my $cipher = new l00Blowfish_PP $phrase;
    # encrypt in i bytes block
    $timst = time;
    $tnext = time;
    for ($ii = 0; $ii < $len; $ii += 8) {
        substr ($out, $ii + $hdrlen, 8) =
            $cipher->encrypt(substr ($buffer,$ii,8));
        if ((time - $tnext) >= 3) {
            if ($ii > 3) {
                $more = int ((time - $timst) / ($ii / $len) + 0.5) - (time - $timst);
            } else {
                $more = 'inf';
            }
            print "$len: [", int(100 * $ii / $len), "%] (", time - $timst, "s/${more}s)\n";
            $tnext = time;
        }
    }

    $out;
}


sub l00decryptbin {
    my ($phrase, $buffer, $off, $len) = @_;
    my ($out, $ln, $ii, $hdrbuf);
    my ($hdr, $hdrlen, $filelen, $cmtlen, $comment, $meta, $metalen);

    $out = '';
    $comment = '';
    $meta = '';

    ($hdr, $filelen, $cmtlen, $metalen) = unpack ("A4Nnn", $buffer);
    if ($hdr eq 'fHdR') {
        ($hdr, $filelen, $cmtlen, $metalen, $comment, $meta) = 
            unpack ("A4NnnZ$cmtlen"."Z$metalen", $buffer);
        if ($phrase ne '') {
            # password supplied, decrypt
            while (length ($phrase) < 8) {
                $phrase .= $phrase;
            }
            my $cipher = new l00Blowfish_PP $phrase;
            $hdrlen = 12 + length ($comment) + 1 + length ($meta) + 1;
            # decrypt
            $out = '';
            if (($off + $len) > $filelen) {
                $len = $filelen - $off;
            }
            for ($ii = $off; $ii < $off + $len; $ii += 8) {
                substr ($out,$ii - $off,8) =
                    $cipher->decrypt(substr ($buffer, $ii + $hdrlen, 8));
            }
            $out = substr ($out, 0, $filelen);
        }
    } elsif ($hdr eq 'fHDr') {
        my $cipherhdr = new l00Blowfish_PP 'l00crypt';
        $hdrbuf = $cipherhdr->decrypt(substr ($buffer, 4, 8));
        ($filelen, $cmtlen, $metalen) = unpack ("Nnn", $hdrbuf);
        $hdrlen = $cmtlen + $metalen + 7;
        $hdrlen &= 0xfff8;
        $hdrbuf = '';
        for ($ii = 0; $ii < $hdrlen; $ii += 8) {
            substr ($hdrbuf, $ii, 8) =
                $cipherhdr->decrypt(substr ($buffer, 12 + $ii, 8));
        }
        ($comment, $meta) = 
            unpack ("Z$cmtlen"."Z$metalen", $hdrbuf);
        $hdrlen += 12;

        if ($phrase ne '') {
            # password supplied, decrypt
            while (length ($phrase) < 8) {
                $phrase .= $phrase;
            }
            my $cipher = new l00Blowfish_PP $phrase;
            # decrypt
            $out = '';
            if (($off + $len) > $filelen) {
                $len = $filelen - $off;
            }
            for ($ii = $off; $ii < $off + $len; $ii += 8) {
                substr ($out,$ii - $off,8) =
                    $cipher->decrypt(substr ($buffer, $ii + $hdrlen, 8));
            }
            $out = substr ($out, 0, $filelen);
        }
    } else {
        $out = 'Invalid file';
    }

    ($out, $filelen, $comment, $meta);
}


1;
