# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

$gen_dir = "x97a_pic";

if (defined($ctrl->{'FORM'}->{'arg1'}) && (length($ctrl->{'FORM'}->{'arg1'}) > 1)) {
    $gen_dir = $ctrl->{'FORM'}->{'arg1'};
}


$wikiout = "";
$wikiout .= "\n%TOC%\n";
$wikiout .= "=Demonstration: $gen_dir=\n";
$wikiout .= "* Now is: $ctrl->{'now_string'}\n";
$wikiout .= "** whoami: $ctrl->{'whoami'}\n";
$wikiout .= "** [[/view.htm?path=l00://devlog.txt||l00://devlog.txt]]\n";
$wikiout .= "** [[/view.htm?path=l00://wikiout.txt||l00://wikiout.txt]]\n";
$wikiout .= "** [[/view.htm?path=l00://output.txt&hidelnno=on&update=S̲kip||l00://output.txt]]\n";


$devlog = '';
$devlog .= "%TOC%\n\n";
$devlog .= "=devlog=\n";
$devlog .= "* Now is: $ctrl->{'now_string'}\n";
$devlog .= "\n";


$output = <<EOB;
# cd to photo/
DTSTAMP=$ctrl->{'now_string'}; \\
OUTDIR=$gen_dir; \\
pwd > \${OUTDIR}m5_\${DTSTAMP}\${DESC}.m5sz; \
EOB


$wikiout .= "=Output=\n";
$wikiout .= "* $gen_dir\n\n";
$wikiout .= "<pre>\n";
$wikiout .= $output;
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
