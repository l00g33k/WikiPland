# [[/do.htm?do=Do&path=/sdcard/sl4a/scripts/l00httpd/docs_demo/l00_camera.pl|run l00_camera.pl]]
use l00wikihtml;

$jpgpath  = "$ctrl->{'workdir'}pub/";
$doplpath = "$ctrl->{'plpath'}docs_demo/";

print $sock "Edit: <a href=\"/edit.htm?path=$doplpath"."l00_camera.htm\">$doplpath"."l00_camera.pl</a><br>\n";

if (!defined ($ctrl->{'FORM'}->{'piconly'})) {
    $ctrl->{'droid'}->wakeLockAcquireDim();
    $ctrl->{'droid'}->cameraCapturePicture("$jpgpath"."l00_cam.jpg");
#   $ctrl->{'droid'}->wakeLockRelease();
    $ctrl->{'droid'}->wakeLockAcquirePartial();
    if (open (IN, "<$jpgpath"."l00_cam.jpg")) {
        binmode (IN);
        sysread (IN, $_, 10000000);
        close (IN);

        $fname = "$jpgpath"."l00_cam_$ctrl->{'now_string'}.jpg";
        $fname =~ s / /_/g;
        if (open (OU, ">$fname")) {
            binmode (OU);
            print OU $_;
            close (OU);
        }
    }
}
print $sock "Picture: <a href=\"/ls.htm?path=$jpgpath"."l00_cam.jpg\">l00_cam.jpg</a><br>\n";
print $sock "Do not take Picture: <a href=\"/do.htm?do=Do&path=$doplpath"."l00_camera.pl&piconly=on\">l00_cam.jpg</a>\n";
print $sock " <a href=\"/do.htm?do=Do&path=$doplpath"."l00_camera.pl&piconly=on&allpics=on\">all jpg</a><p>\n";

$cnt += 1;
print $sock "<img src=\"/ls.htm?path=$jpgpath"."l00_cam.jpg&cnt=$cnt\" width=\"384\" height=\"512\"><br>";




print $sock "<a href=\"/ls.htm?path=$jpgpath\">List of pictures</a><br>\n";
if (opendir (DIR, "$jpgpath")) {
    foreach $file (sort readdir (DIR)) {
        if (-f "$jpgpath$file") {
            if ($file =~ /l00_cam.*\.jpg/) {
                ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
                 $size, $atime, $mtime, $ctime, $blksize, $blocks)
                 = stat("$jpgpath$file");
                ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst)
                 = localtime($mtime);
                if (defined ($ctrl->{'FORM'}->{'allpics'})) {
                     print $sock 
                        sprintf ("%4d/%02d/%02d %02d:%02d:%02d", 1900+$year, 1+$mon, $mday, $hour, $min, $sec),
                        " <a href=\"/ls.htm?path=$jpgpath$file\">$file</a><br>\n".
                        " <img src=\"/ls.htm?path=$jpgpath$file\" width=\"384\" height=\"512\"><br>";
                } else {
                     print $sock 
                        sprintf ("%4d/%02d/%02d %02d:%02d:%02d", 1900+$year, 1+$mon, $mday, $hour, $min, $sec),
                        " <a href=\"/ls.htm?path=$jpgpath$file\">$file</a><br>\n";
                }
            }
        }
    }
}

1;
