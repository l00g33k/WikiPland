#use strict;
#use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# Eval expression

my %config = (proc => "l00http_eval_proc",
              desc => "l00http_eval_desc");

sub l00http_eval_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    " B: eval: Eval expressions";
}

sub l00http_eval_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($line, $lncn);
    my ($eval);

#    my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l,$m);
#    my ($n,$o,$p,$q,$r,$s,$t,$u,$v,$w,$x,$y,$z);
#    my ($A,$B,$C,$D,$E,$F,$G,$H,$I,$J,$K,$L,$M);
#    my ($N,$O,$P,$Q,$R,$S,$T,$U,$V,$W,$X,$Y,$Z);
#    $a=$b=$c=$d=$e=$f=$g=$h=$i=$j=$k=$l=$m='';
#    $n=$o=$p=$q=$r=$s=$t=$u=$v=$w=$x=$y=$z='';
#    $A=$B=$C=$D=$E=$F=$G=$H=$I=$J=$K=$L=$M='';
#    $N=$O=$P=$Q=$R=$S=$T=$U=$V=$W=$X=$Y=$Z='';

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>eval</title>" . $ctrl->{'htmlhead2'};
    print $sock "<a name=\"top\"></a>\n";

    if (defined ($form->{'eval'})) {
        $eval = $form->{'eval'};
    } else {
        $eval = '';
    }
    if (defined ($form->{'clear'})) {
        $eval = '';
    }
    if (defined ($form->{'paste'})) {
        $eval = &l00httpd::l00getCB($ctrl);
        # extract URL to remove surrounding text
        if ($eval =~ /(https*:\/\/[^ \n\r\t]+)/) {
            $eval = $1;
        }
    }
    $lncn = 0;
    if (defined ($eval) && (length ($eval) > 1)) {
        print $sock "<pre>\n";
        foreach $line (split ("\n", $eval)) {
            #print $sock "eval: $line\n";
            #eval $line;
            print $sock "$lncn: ";
            eval "print \$sock $line";
            print $sock "\n";
            $lncn++;
        }
        print $sock "</pre>\n";
    }

    print $sock "<form action=\"/eval.htm\" method=\"get\">\n";
    print $sock "<input type=\"submit\" name=\"submit\" value=\"Eval\">\n";
    print $sock "<br><textarea name=\"eval\" cols=\"$ctrl->{'txtw'}\" rows=\"$ctrl->{'txth'}\">$eval</textarea><br>\n";
    print $sock "<input type=\"submit\" name=\"clear\" value=\"Clear\">\n";
    print $sock "<input type=\"submit\" name=\"paste\" value=\"Paste\">\n";
    print $sock "</form>\n";

    print $sock "$ctrl->{'home'} $ctrl->{'HOME'}\n";
    print $sock "<a href=\"#end\">Jump to end</a><p>\n";

    print $sock "<a href=\"/eval.htm?eval=%27Time+in+sec%3A+%27.time.%27+is+%27.l00httpd%3A%3Atime2now_string%28time%29&url=\">Example to invoke</a>:<br>\n";
    print $sock "<pre>\n";
    print $sock "'Time in sec: '.time.' is '.l00httpd::time2now_string(time)\n";
    print $sock "</pre>\n";

    print $sock "<a href=\"/eval.htm?eval=%24ctrl-%3E%7B%27droid%27%7D-%3EmakeToast%28%27Making+a+toast%27%29%3B\">Example to invoke</a>:<br>\n";
    print $sock "<pre>\n";
    print $sock "\$ctrl->{'droid'}->makeToast('Making a toast');\n";
    print $sock "</pre>\n";

    print $sock "<a href=\"/eval.htm?eval=%24ctrl-%3E%7B%27droid%27%7D-%3EgenerateDtmfTones%28%27%23%27%2C100%29%3B\">Example to invoke</a>:<br>\n";
    print $sock "<pre>\n";
    print $sock "\$ctrl->{'droid'}->generateDtmfTones('#',100);\n";
    print $sock "</pre>\n";

    print $sock "<a href=\"/eval.htm?eval=%26l00httpd%3A%3Adumphashbuf+%28%22wifi%22%2C+%24ctrl-%3E%7B%27droid%27%7D-%3EwifiGetConnectionInfo%28%29%29%3B\">Example to invoke</a>:<br>\n";
    print $sock "<pre>\n";
    print $sock "&l00httpd::dumphashbuf (\"wifi\", \$ctrl->{'droid'}->wifiGetConnectionInfo());\n";
    print $sock "</pre>\n";

    print $sock "<a href=\"/eval.htm?eval=%24a%3D%27eyJDb250ZXh0Q2hvb3NlclJlcSI6eyJjb3VudHJ5IjoiTUMiLCJjdXJyZW5jeSI6IlVTRCIsImxhbmd1YWdlIjoiZW4ifX0%3D%27%3B%0D%0A%26l00base64%3A%3Ab64decode+%28%24a%29%3B%0D%0A%24b%3D%27{%22ContextChooserReq%22%3A{%22country%22%3A%22MC%22%2C%22currency%22%3A%22USD%22%2C%22language%22%3A%22en%22}}%27%3B%0D%0A%26l00base64%3A%3Ab64encode+%28%24b%29%3B%0D%0A\">Example to invoke</a>:<br>\n";
    print $sock "<pre>\n";
    print $sock "\$a='eyJDb250ZXh0Q2hvb3NlclJlcSI6eyJjb3VudHJ5IjoiTUMiLCJjdXJyZW5jeSI6IlVTRCIsImxhbmd1YWdlIjoiZW4ifX0=';\n";
    print $sock "&l00base64::b64decode (\$a);\n";
    print $sock "\$b='{\"ContextChooserReq\":{\"country\":\"MC\",\"currency\":\"USD\",\"language\":\"en\"}}';\n";
    print $sock "&l00base64::b64encode (\$b);\n";
    print $sock "</pre>\n";

    if (defined ($eval) && (length ($eval) > 1)) {
        print $sock "<hr><pre>$eval</pre>\n";
    }

    print $sock "<a name=\"end\"></a>\n";
    print $sock "<a href=\"#top\">Jump to top</a><p>\n";
 
    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}

\%config;
