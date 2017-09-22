# [[/do.htm?do=Do&path=/sdcard/sl4a/scripts/l00httpd/docs_demo/l00_camera.pl|run l00_camera.pl]]
use l00wikihtml;

$jpgpath  = "/sdcard/DCIM/Camera/";
$doplpath = "$ctrl->{'plpath'}docs_demo/";

print $sock "Edit: <a href=\"/edit.htm?path=$doplpath"."l00_showpics.pl\">$doplpath"."l00_showpics.pl</a><br>\n";

if (defined ($ctrl->{'FORM'}->{'jpgpath'})) {
    $jpgpath = $ctrl->{'FORM'}->{'jpgpath'};
}
if (defined ($ctrl->{'FORM'}->{'first'})) {
    $first = $ctrl->{'FORM'}->{'first'};
} else {
    $first = '';
}
if (defined ($ctrl->{'FORM'}->{'last'})) {
    $last = $ctrl->{'FORM'}->{'last'};
} else {
    $last = '';
}
if (defined ($ctrl->{'FORM'}->{'width'})) {
    $width = $ctrl->{'FORM'}->{'width'};
} else {
    $width = 640;
}
if (defined ($ctrl->{'FORM'}->{'height'})) {
    $height = $ctrl->{'FORM'}->{'height'};
} else {
    $height = 360;
}

$cnt += 1;



$cnt = 1;
if ((length ($first) > 0) && (length($last) > 0)) {
    print $sock "<p>Displaying between '$first' and '$last':<br>\n";
    $disp = 0;
    if (opendir (DIR, "$jpgpath")) {
        foreach $file (sort {$b cmp $a} readdir (DIR)) {
            if (-f "$jpgpath$file") {
                if ($file =~ /$first/) {
                    $disp = 1;
                }
                if (($disp && ($file =~ /\.png$/i)) || 
                    ($disp && ($file =~ /\.jpg$/i))) {
                    ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
                     $size, $atime, $mtime, $ctime, $blksize, $blocks)
                     = stat("$jpgpath$file");
                    ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst)
                     = localtime($mtime);
                     if (($width > 10) && ($width < 5000) && ($height > 10) && ($height < 5000)) {
                         $scale = "width=\"$width\" height=\"$height\"";
                     } else {
                         $scale ='';
                     }
                     print $sock 
                        sprintf ("<a name=\"__%d__\">".
                                 "<a href=\"#__%d__\">Prev</a> ".
                                 "<a href=\"#__%d__\">Next</a> Below: ".
                                 "%4d/%02d/%02d %02d:%02d:%02d", 
                        $cnt, $cnt - 1, $cnt + 1,
                        1900+$year, 1+$mon, $mday, $hour, $min, $sec),
                        " <a href=\"/ls.htm/$file.htm?path=$jpgpath$file\">$file</a> $size bytes <a href=\"/filemgt.htm?path=$jpgpath$file\">mgt</a><br>\n".
                        " <img src=\"/ls.htm?path=$jpgpath$file\" $scale><br>";
                     $cnt++;
                }
                if ($file =~ /$last/) {
                    $disp = 0;
                }
            }
        }
    }
}


print $sock "<a href=\"/ls.htm?path=$jpgpath\">List of pictures</a><br>\n";
if (opendir (DIR, "$jpgpath")) {
    foreach $file (sort {$b cmp $a} readdir (DIR)) {
        if (-f "$jpgpath$file") {
            if (($file =~ /\.png$/i) || 
                ($file =~ /\.jpg$/i)) {
                ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
                 $size, $atime, $mtime, $ctime, $blksize, $blocks)
                 = stat("$jpgpath$file");
                ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst)
                 = localtime($mtime);
                if (defined ($ctrl->{'FORM'}->{'allpics'})) {
                     print $sock 
                        sprintf ("%4d/%02d/%02d %02d:%02d:%02d", 1900+$year, 1+$mon, $mday, $hour, $min, $sec),
                        " <a href=\"/ls.htm/$file?path=$jpgpath$file\">$file</a><br>\n".
                        " <img src=\"/ls.htm?path=$jpgpath$file\" width=\"384\" height=\"512\"><br>";
                } else {
                     print $sock 
                        sprintf ("%4d/%02d/%02d %02d:%02d:%02d", 1900+$year, 1+$mon, $mday, $hour, $min, $sec),
                        " <a href=\"/ls.htm/$file?path=$jpgpath$file\">$file</a><br>\n";
                }
            }
        }
    }
}

print $sock "<p>This script sorts *.jpg or *.png images in '$jpgpath' by name and displays all images starting when the ".
"filename matches 'First pic' regex and stops when the filename matches 'Last pic'.  This will take a while to ".
"load all images but once loaded, you can click 'Next' to instantly go to the next image, and usually with alt-left_arrow ".
"to go back<p>\n";

print $sock "<form action=\"/do.htm\" method=\"get\">\n";
print $sock "First pic:<input type=\"text\" name=\"first\" size=\"6\" value=\"$first\"> \n";
print $sock "Last pic:<input type=\"text\" name=\"last\" size=\"6\" value=\"$last\"> regex matches<br>\n";
print $sock "Each pic: width:<input type=\"text\" name=\"width\" size=\"6\" value=\"$width\"> \n";
print $sock "height:<input type=\"text\" name=\"height\" size=\"6\" value=\"$height\"> blanks for unscaled\n";
print $sock "<input type=\"hidden\" name=\"path\" value=\"$doplpath"."l00_showpics.pl\">\n";
print $sock "<br><input type=\"submit\" name=\"set\" value=\"Set\">\n";
print $sock "Pic path:<input type=\"text\" name=\"jpgpath\" size=\"16\" value=\"$jpgpath\"> (must end in '/')<br>\n";
print $sock "</form><br>\n";

print $sock "<p><a href=\"$jpgpath\">$jpgpath</a>\n";

1;
