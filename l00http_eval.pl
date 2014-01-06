#use strict;
#use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# Eval expression

my %config = (proc => "l00http_eval_proc",
              desc => "l00http_eval_desc");
my ($eval);
$eval = '';

sub l00http_eval_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    " C: eval: Eval expressions";
}

sub l00http_eval_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($line, $lncn, $rst);

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
    print $sock "$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">Quick</a>\n";
    print $sock "<a href=\"#end\">Jump to end</a>\n";


    if (defined ($form->{'eval'})) {
        $eval = $form->{'eval'};
    }
    if (defined ($form->{'clear'})) {
        $eval = '';
    }
    if (defined ($form->{'paste'})) {
        if ($ctrl->{'os'} eq 'and') {
            $eval = $ctrl->{'droid'}->getClipboard();
            $eval = $eval->{'result'};
        }
    }
    $lncn = 0;
    if (defined ($eval) && (length ($eval) > 1)) {
        foreach $line (split ("\n", $eval)) {
            #print $sock "eval: $line\n";
            #eval $line;
            print $sock "$lncn: ";
            eval "print \$sock $line";
            print $sock "$rst<br>\n";
            $lncn++;
        }
    }

    print $sock "<form action=\"/eval.htm\" method=\"post\">\n";
    print $sock "<input type=\"submit\" name=\"submit\" value=\"Eval\">\n";
    print $sock "<input type=\"submit\" name=\"clear\" value=\"Clear\">\n";
    print $sock "<input type=\"submit\" name=\"paste\" value=\"Paste\">\n";
    print $sock "<br><textarea name=\"eval\" cols=\"$ctrl->{'txtw'}\" rows=\"$ctrl->{'txth'}\">$eval</textarea>\n";
    print $sock "</form>\n";

    print $sock "<a name=\"end\"></a>\n";

    if (defined ($eval) && (length ($eval) > 1)) {
        print $sock "<hr><pre>$eval</pre>\n";
    }

    print $sock "<form action=\"/eval.htm\" method=\"post\">\n";
 
    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
