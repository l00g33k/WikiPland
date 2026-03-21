$fname = "$ctrl->{'FORM'}->{'L00DOPATH'}$ctrl->{'FORM'}->{'L00DOFILE'}";

if (defined($ctrl->{'FORM'}->{'arg1'}) && (length($ctrl->{'FORM'}->{'arg1'}) > 1)) {
    $fname = $ctrl->{'FORM'}->{'arg1'};
}


$wikiout = "";
$wikiout .= "\n%TOC%\n";
$wikiout .= "=l00_*.pl Template=\n";
$wikiout .= "=Sample Processing: $fname=\n";
$wikiout .= "* arg1: input file name ($fname)\n";
$wikiout .= "* Now is: $ctrl->{'now_string'}\n";
$wikiout .= "* Outputs:\n";
$wikiout .= "** [[/view.htm?path=l00://devlog.txt||l00://devlog.txt]]\n";
$wikiout .= "** [[/view.htm?path=l00://wikiout.txt||l00://wikiout.txt]]\n";
$wikiout .= "** [[/view.htm?path=l00://output.txt&hidelnno=on&update=S̲kip||l00://output.txt]]\n";


$devlog = '';
$devlog .= "%TOC%\n\n";
$devlog .= "=devlog=\n";
$devlog .= "* Now is: $ctrl->{'now_string'}\n";
$devlog .= "\n";

$output = '';
$output2 = '';

if (open(IN, "<$fname")) {
    $cnt = 0;
    $devlog .= "<pre>\n";
    while (<IN>) {
        s/[\r\n]//g;
        $cnt++;
        if (/devlog/) {
            $devlog .= "$cnt: $_\n";
        }
        if (/wikiout/) {
            $output .= "$cnt: $_\n";
        }
    }
    close(IN);
    $devlog .= "</pre>\n";

    $wikiout .= "* Read $cnt lines from $fname\n";
} else {
    $wikiout .= "* Failed to read $fname\n";
}




$wikiout .= "=Output=\n";
$wikiout .= "* $fname\n\n";
$wikiout .= "<pre>\n";
$wikiout .= $output2;
$wikiout .= "</pre>\n";
$wikiout .= "=END=\n";


&l00httpd::l00fwriteOpen($ctrl, "l00://wikiout.txt");
&l00httpd::l00fwriteBuf($ctrl, $wikiout);
&l00httpd::l00fwriteClose($ctrl);

&l00httpd::l00fwriteOpen($ctrl, "l00://devlog.txt");
&l00httpd::l00fwriteBuf($ctrl, $devlog);
&l00httpd::l00fwriteClose($ctrl);

&l00httpd::l00fwriteOpen($ctrl, "l00://output.txt");
&l00httpd::l00fwriteBuf($ctrl, $output);
&l00httpd::l00fwriteClose($ctrl);

$ctrl->{'wikihtmlflags'} = 2;
$wikiout;
