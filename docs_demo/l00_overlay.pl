$fname = "$ctrl->{'FORM'}->{'L00DOPATH'}DailyTreasuryLong-TermRates.csv";

if (defined($ctrl->{'FORM'}->{'arg1'}) && (length($ctrl->{'FORM'}->{'arg1'}) > 1)) {
    $fname = $ctrl->{'FORM'}->{'arg1'};
}


$wikiout = "";
$wikiout .= "\n%TOC%\n";
$wikiout .= "=Demonstration: $fname=\n";
$wikiout .= "* Now is: $ctrl->{'now_string'}\n";
$wikiout .= "** [[/view.htm?path=l00://devlog.txt||l00://devlog.txt]]\n";
$wikiout .= "** [[/view.htm?path=l00://wikiout.txt||l00://wikiout.txt]]\n";
$wikiout .= "** [[/view.htm?path=l00://output.txt&hidelnno=on&update=S̲kip||l00://output.txt]]\n";
$wikiout .= "** view [[/picannosvg.htm?set=Set&graphdatafile=l00://output.txt&graphxoff=390&graphyoff=106&graphwidth=436&graphheight=200&path=$ctrl->{'FORM'}->{'L00DOPATH'}30YTCMR.png||overlay graph]]\n";


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
    undef @data;
    while (<IN>) {
        s/[\r\n]//g;
        $cnt++;
        if (($mo, $dy, $yr, $lt, $cmt) = /^(\d+)\/(\d+)\/(\d+)\,([0-9.]+),([0-9.]+)/) {
            $yr -= 1900;
            $mo--;
            $devlog .= "($mo, $dy, $yr, $lt, $cmt) $_\n";
            $tthis = &l00mktime::mktime ($yr, $mo, $dy, 0, 0, 0);
            $output .= "$tthis,$cmt\n";
            if ($cnt < 20) {
                $output2 = "$tthis,$cmt\n$output2";
            }
            push (@data, "$tthis,$cmt");
        }
    }
    close(IN);
    $devlog .= "</pre>\n";

    $wikiout .= "* Read $cnt lines from $fname\n";
    $devlog .= "<pre>\n";
    $devlog .= "=data=\n";
    $devlog .= "\n";
    foreach $_ (sort (@data)) {
        $devlog .= "$_\n";
    }
    $devlog .= "</pre>\n";

    &l00svg::plotsvg2 ('graph', join (' ', sort (@data)), 436, 200);
    $wikiout .= "* <a href=\"/svg2.pl?graph=graph&view=\"><img src=\"/svg.pl?graph=graph\" alt=\"alt\"></a>\n";
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
