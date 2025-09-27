$wikiout = "";

if (!defined($tmuxwincmdln)) {
    $tmuxwincmdln = "^c enter 'uname -a' enter uptime enter";
}
if (!defined($tmuxpanelen)) {
    $tmuxpanelen = 20;
}

sub tmuxpaneform {
    my ($tmuxwincmdln2) = @_;

    $wikiout .= <<EOB;
** 
<form action="/do.htm" method="get">
<input type="submit" name="submit" value="Submit" accesskey="n">
<input type="text" name="arg2" value="$tmuxwincmdln2">
<input type="hidden" name="arg1" value="$pane">
<input type="hidden" name="path" value="$ctrl->{'FORM'}->{'path'}">
<input type="hidden" name="arg3" value="">
</form>
EOB
}

if ((($ctrl->{'FORM'}->{'submit'} eq 'Submit') ||
    ($ctrl->{'FORM'}->{'submit'} eq 'Send')) &&
    defined($ctrl->{'FORM'}->{'arg1'}) && 
    defined($ctrl->{'FORM'}->{'arg2'})) {

    if (defined($ctrl->{'FORM'}->{'panelen'}) && 
        ($ctrl->{'FORM'}->{'panelen'} =~ /(\d+)/)) {
        $tmuxpanelen = $1;
    }

    $pane = $ctrl->{'FORM'}->{'arg1'};
    $paneclean = $pane;
    $paneclean =~ s/^\$/S/;
    $paneshowlast = "<a href=\"#$paneclean\">$pane</a>";
    $tmuxwincmdln = $ctrl->{'FORM'}->{'arg2'};
    $cmd = "tmux send-keys -t '$pane' $tmuxwincmdln";

    $wikiout .= "=tmux send-keys=\n";
    $wikiout .= "* Pane: <code>$paneshowlast</code>\n";
    $wikiout .= "* Shell: \n<code>$cmd</code>\n";

    $wikiout .= <<EOB;
<form action="/do.htm" method="get">
<input type="submit" name="submit" value="Send" accesskey="n">
<input type="text" name="arg2" value="$tmuxwincmdln">
tail <input type="text" name="panelen" size="3" value="$tmuxpanelen">
<input type="hidden" name="arg1" value="$pane">
<input type="hidden" name="path" value="$ctrl->{'FORM'}->{'path'}">
<input type="hidden" name="arg3" value="doit">
</form>
EOB

    &tmuxpaneform ($tmuxwincmdln);
    $wikiout .= <<EOB;
* preset: (keywords: enter escape pageup pagedown up down left right)
** spaces must be qouted or escaped
EOB

    &tmuxpaneform ("^c enter pwd enter");
    &tmuxpaneform ("^c enter 'ls -l' enter");
    &tmuxpaneform ("^c enter 'git status' enter");
    &tmuxpaneform ("^c enter gh enter");
    &tmuxpaneform ("escape");
    &tmuxpaneform ("'uname -a ; hostname ; uptime' enter");


    if (defined($ctrl->{'FORM'}->{'arg3'}) && 
        ($ctrl->{'FORM'}->{'arg3'} eq 'doit')) {
        `$cmd`;
        $wikiout .= "* Shelled: <code>$cmd</code>\n";
        sleep 1;
    }

    # print pane
    $wikiout .= "* $pane pane content:\n\n";
    $wikiout .= " \n \n";
    $cmd = "tmux capture-pane -p -t '$pane' -J -S - -E - | tail -n $tmuxpanelen";
    $buf = `$cmd`;
    foreach $out (split("\n", $buf)) {
        $wikiout .= "    $out\n";
    }
}


$wikiout .= "=tmux windows=\n";
$wikiout .= "* Now is: $ctrl->{'now_string'}\n";
$wikiout .= "** [[/view.htm?path=l00://devlog.txt||l00://devlog.txt]]\n";
$wikiout .= "** [[/view.htm?path=l00://wikiout.txt||l00://wikiout.txt]]\n";
if (defined($paneshowlast)) {
    $wikiout .= "\n* Last pane: $paneshowlast\n";
}


$devlog = '';
$devlog .= "%TOC%\n\n";
$devlog .= "=devlog=\n";
$devlog .= "* Now is: $ctrl->{'now_string'}\n";
$devlog .= "\n";


$buf = `tmux list-panes -a -F "#{session_id}:#{window_index}.#{pane_index} #{window_name} #{pane_current_command} #{pane_current_path} #{pane_width} #{pane_height}"`;


$wikiout .= "=tmux list-panes=\n";
$wikiout .= "\n";
$wikiout .= "|| **PANE** || **name** || **cmdln** || **pwd** || **wd x ht** ||\n";
foreach $out (split("\n", $buf)) {
    ($pane, $name, $cmd, $path, $wd, $ht) = split(" ", $out);
    $paneclean = $pane;
    $paneclean =~ s/^\$/S/;
    $paneshow = "<a href=\"#$paneclean\">$pane</a>";
    $wikiout .= "|| $paneshow || $name || $cmd || $path || $wd x $ht ||\n";
}

$wikiout .= "\n%TOC%\n";

foreach $line (split("\n", $buf)) {
    ($pane, $name, $cmd, $path, $wd, $ht) = split(" ", $line);
    $pathshort = substr($path, -60, 60);
    $paneclean = $pane;
    $paneclean =~ s/^\$/S/;
    $wikiout .= "<a name=\"$paneclean\"></a>\n";
    $wikiout .= "==$pane: $name -- $cmd -- $pathshort==\n";
    $wikiout .= "* PANE : $pane\n";
    $wikiout .= "* NAME : $name\n";
    $wikiout .= "* size : $wd x $ht\n";
    $wikiout .= "* Cmdl : $cmd\n";
    $wikiout .= "* PATH : $path\n";
    $wikiout .= "* Click the 'Send' button on the next page to actually send the commands.\n";
    $wikiout .= <<EOB;
<form action="/do.htm" method="get">
<input type="submit" name="submit" value="Submit" accesskey="n">
<input type="text" name="arg2" value="$tmuxwincmdln">
<input type="hidden" name="arg1" value="$pane">
<input type="hidden" name="path" value="$ctrl->{'FORM'}->{'path'}">
<input type="hidden" name="arg3" value="">
</form>
EOB
    $wikiout .= "\n";
    $cmd = "tmux capture-pane -p -t '$pane' -J -S - -E - | tail -n $ht";
    $buf = `$cmd`;
    foreach $out (split("\n", $buf)) {
        $out =~ s/</&lt;/g;
        $out =~ s/>/&lt;/g;
        $out =~ s/</&lt;/g;
        $wikiout .= "    $out\n";
    }
}


&l00httpd::l00fwriteOpen($ctrl, "l00://wikiout.txt");
&l00httpd::l00fwriteBuf($ctrl, $wikiout);
&l00httpd::l00fwriteClose($ctrl);

&l00httpd::l00fwriteOpen($ctrl, "l00://devlog.txt");
&l00httpd::l00fwriteBuf($ctrl, $devlog);
&l00httpd::l00fwriteClose($ctrl);

$ctrl->{'wikihtmlflags'} = 2;
$wikiout;
