use strict;
use warnings;
# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14


sub l00_crypt_ex_entry (\%) {
    my ($main, $ctrl, $plain, $path) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my ($plain2, $_, $name, $buffer, $mkclip, $needsnewline);
    my ($anchor, $title);

#    $anchor = '';
    $plain2 = "";
    $mkclip = 0;
    foreach $_ (split ("\n", $plain)) {
        s/\r//g;
        s/\n//g;
        if ($mkclip == 0) {
            if (/^\[\[!l00_crypt_ex/) {
                $mkclip = 1;
                $name = "";
                $buffer = "";
                $needsnewline = 0;
            } else {
                $plain2 .= "$_\n";
            }
        } else {
            if (/^##/) {
                # comment
            } elsif (/^\[\[!l00_crypt_ex/) {
                $plain2 .= "\n";
                $mkclip = 0;
            } elsif (/^#(<.*)/) {
                # HTML tags
                $plain2 .= "$1";
                $name = "";
                $buffer = "";
            } elsif (/^#(=.*)/) {
                $title = $1;
#                $anchor = $title;
#                $anchor =~ s/[^0-9A-Za-z]/_/g;
#                $anchor = "#$anchor";
                if (($name ne "") && ($buffer ne "")) {
                    $plain2 .= "<a href=\"/clip.htm?clip=$buffer&update=y\">$name</a> ";
 
                }
                # wiki tags
                if ($needsnewline == 0) {
                    $plain2 .= "$title\n";
                } else {
                    $needsnewline = 0;
                    $plain2 .= "\n$title\n";
                }
                $name = "";
                $buffer = "";
            } elsif (/^#(\*.*)/) {
                if (($name ne "") && ($buffer ne "")) {
                    $plain2 .= "<a href=\"/clip.htm?clip=$buffer&update=y\">$name</a> ";
                }
                # wiki bullet
                if ($needsnewline == 0) {
                    $plain2 .= "$1 ";
                } else {
                    $plain2 .= "\n$1 ";
                }
                $needsnewline = 1;
                $name = "";
                $buffer = "";
            } elsif (/^#(.*)/) {
                if (($name ne "") && ($buffer ne "")) {
                    $plain2 .= "<a href=\"/clip.htm?clip=$buffer&update=y\">$name</a> ";
                }
                $name = $1;
                $buffer = "";
            } else {
                s/\\r/%0D/g;
                s/\\n/%0A/g;
                s/ /+/g;
                $buffer .= $_;
            }
        }
    }

    #print $sock "<pre>aaaaaaa\n$plain2\n</pre>bbbbbbb\n";
    $plain2;
}


1;
