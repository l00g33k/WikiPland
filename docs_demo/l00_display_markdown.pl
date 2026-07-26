$fname = "$ctrl->{'FORM'}->{'L00DOPATH'}$ctrl->{'FORM'}->{'L00DOFILE'}";

if (defined($ctrl->{'FORM'}->{'arg1'}) && (length($ctrl->{'FORM'}->{'arg1'}) > 1)) {
    $fname = $ctrl->{'FORM'}->{'arg1'};
}


$wikiout = "";
$wikiout .= "\n%TOC%\n";
$wikiout .= "=Render markdown: $fname=\n";
$wikiout .= "* arg1: input file name ($fname)\n";
$wikiout .= "** [[/view.htm?path=$fname||$fname]]\n";
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
    $inpre = 0;
    while (<IN>) {
        s/[\r\n]//g;
        $cnt++;
        $devlog .= "MD: $_\n";
        # ## 1. Executive summary
        if (/^(#+) (.+)$/) {
            $len = length($1);
            $len++;
            $tmp = '=' x $len . "$2" . '=' x $len;
            $devlog .= "$tmp\n";
            $output .= "$tmp\n";
            next;
        }
        # | File | Count | Role |
        if (/^\|.+\|$/) {
            $tmp = $_;
            $tmp =~ s/\|/\|\|/g;
            $devlog .= "$tmp\n";
            $output .= "$tmp\n";
            next;
        }
        # - `local.GNU` — what to build here (build type, libraries, includes).
        if (/^(-+) (.+)$/) {
            $len = length($1);
            $tmp = $_;
            $tmp = '*' x $len . " $2";
            $devlog .= "$tmp\n";
            $output .= "$tmp\n";
            next;
        }
        # ```
        if (/^``` *$/) {
            if ($inpre) {
                $tmp = "</pre>";
                $devlog .= "$tmp\n";
                $output .= "$tmp\n";
                $inpre = 0;
                next;
            } else {
                $tmp = "<pre>";
                $devlog .= "$tmp\n";
                $output .= "$tmp\n";
                $inpre = 1;
                next;
            }

        }
        # There are **two framework generations**; the modern one is live. 
        s/\*\*([;,.])/** $1/g;

        $output .= "$_\n";
    }
    close(IN);

    $wikiout .= "* Read $cnt lines from $fname\n";
} else {
    $wikiout .= "* Failed to read $fname\n";
}




$wikiout .= "=OUTPUT=\n";
$wikiout .= $output;
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
