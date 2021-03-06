package l00base64;




#!/usr/bin/perl
# $Id: base64.pl,v 2.4 2004/05/17 04:18:13 ehood Exp $
#
# Library based on Perl 4 code from:
#       base64.pl -- A perl package to handle MIME-style BASE64 encoding
#       A. P. Barrett <barrett@ee.und.ac.za>, October 1993
#       Revision: 1.4 Date: 1994/08/11 16:08:51
#
# Subsequent changes made by Earl Hood, earl@earlhood.com.

# Synopsis:
#       require 'base64.pl';
#
#       $binary_string = &base64::b64decode($base64_string);
#       $base64_string = &base64::b64encode($binary_string);
#
#       uuencode and base64 input strings may contain multiple lines,
#       but may not contain any headers or trailers.  (For uuencode,
#       remove the begin and end lines, and for base64, remove the MIME
#       headers and boundaries.)
#
#       uuencode and base64 output strings will be contain multiple
#       lines if appropriate, but will not contain any headers or
#       trailers.  (For uuencode, add the "begin" line and the
#       " \nend\n" afterwards, and for base64, add any MIME stuff
#       afterwards.)

####################

my $base64_alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.
                      'abcdefghijklmnopqrstuvwxyz'.
                      '0123456789+/';
my $base64_pad = '=';

my $uuencode_alphabet = q|`!"#$%&'()*+,-./0123456789:;<=>?|.
                        '@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_';


# Build some strings for use in tr/// commands.
# Some uuencodes use " " and some use "`", so we handle both.
# We also need to protect backslashes and other special characters.
my $tr_uuencode =  " ".$uuencode_alphabet;
   $tr_uuencode =~ s/(\W)/\\$1/g;
my $tr_base64   =  "A".$base64_alphabet;
   $tr_base64   =~ s/(\W)/\\$1/g;

sub b64decode
{
    # call more efficient module if available (ehood, 2003-09-28)
    if ($_have_MIME_Base64) {
 return &MIME::Base64::decode_base64;
    }

    # substr() usage added by ehood, 1996/04/16

    local($str) = shift;
    my($result, $tmp, $offset, $len);

    # zap bad characters and translate others to uuencode alphabet
    eval qq{
 \$str =~ tr|$tr_base64||cd;
 \$str =~ tr|$tr_base64|$tr_uuencode|;
    };

    # break into lines of 60 encoded chars, prepending "M" for uuencode,
    # and then using perl's builtin uudecoder to convert to binary.
    $result  = '';   # init return string
    $offset = 0;       # init offset to 0
    $len  = length($str);  # store length
    while ($offset+60 <= $len) {  # loop until < 60 chars left
 $tmp = substr($str, $offset, 60); # grap 60 char block
 $offset += 60;    # increment offset
 $result .= unpack('u', 'M' . $tmp); # decode block
    }
    # also decode any leftover chars
    if ($offset < $len) {
 $tmp = substr($str, $offset, $len-$offset);
 $result .= unpack('u',
      substr($uuencode_alphabet, length($tmp)*3/4, 1) . $tmp);
    }

    # return result
    $result;
}

sub b64encode
{
    # call more efficient module if available (ehood, 2003-09-28)
    if ($_have_MIME_Base64) {
 return &MIME::Base64::encode_base64;
    }

    local ($_) = shift;
    my ($chunk);
    my ($result);

    # break into chunks of 45 input chars, use perl's builtin
    # uuencoder to convert each chunk to uuencode format,
    # then kill the leading "M", translate to the base64 alphabet,
    # and finally append a newline.
    while (s/^([\s\S]{45})//) {
 $chunk = substr(pack('u', $1), $[+1, 60);
 eval qq{
     \$chunk =~ tr|$tr_uuencode|$tr_base64|;
 };
 $result .= $chunk . "\n";
    }

    # any leftover chars go onto a shorter line
    # with uuencode padding converted to base64 padding
    if ($_ ne '') {
 $chunk = substr(pack('u', $_), $[+1,
   int((length($_)+2)/3)*4 - (45-length($_))%3);
 eval qq{
     \$chunk =~ tr|$tr_uuencode|$tr_base64|;
 };
 $result .= $chunk . ($base64_pad x ((60 - length($chunk)) % 4)) . "\n";
    }

    # return result
    $result;
}


#       $uuencode_string = &base64::b64touu($base64_string);
#       $binary_string = &base64::b64decode($base64_string);
#       $base64_string = &base64::uutob64($uuencode_string);
#       $base64_string = &base64::b64encode($binary_string);


1;

