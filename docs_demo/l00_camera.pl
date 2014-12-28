# [[/do.htm?do=Do&path=/sdcard/sl4a/scripts/l00httpd/docs_demo/l00_camera.pl|run l00_camera.pl]]
use l00wikihtml;

if (defined ($ctrl->{'FORM'}->{'takepic'})) {
    # this is a trick: a img src points back to this URL with takepic=takepic
	# so it lands in this clause to kick start the camera. This allows
	# the main page to be completely sent and start the camera 
	# later.
    $ctrl->{'droid'}->wakeLockAcquireDim();
    $ctrl->{'droid'}->cameraCapturePicture("${jpgpath}l00_cam.jpg");
    $ctrl->{'droid'}->wakeLockAcquirePartial();
} else {
# initialize $cnt if not defined
if (!defined ($cnt)) {
    $cnt = 0;
}

$jpgpath  = "$ctrl->{'workdir'}pub/";
$doplpath = "$ctrl->{'plpath'}docs_demo/";

if ((defined ($ctrl->{'FORM'}->{'refresh'})) &&
    ($ctrl->{'FORM'}->{'refresh'} =~ /^\d+$/)) {
    # detects that this page is being repeatedly auto refreshed
    $autoloading = 1;
} else {
    $autoloading = 0;
}



print $sock "Edit: <a href=\"/edit.htm?path=$doplpath"."l00_camera.htm\">$doplpath"."l00_camera.pl</a><br>\n", if (!$autoloading);

if (!defined ($ctrl->{'FORM'}->{'piconly'}) && !$autoloading) {
    # Take picture, if not autoloading
    $ctrl->{'droid'}->wakeLockAcquireDim();
    $ctrl->{'droid'}->cameraCapturePicture("${jpgpath}l00_cam.jpg");
    $ctrl->{'droid'}->wakeLockAcquirePartial();
    if (open (IN, "<${jpgpath}l00_cam.jpg")) {
        # not auto loading, save it
        binmode (IN);
        sysread (IN, $_, 10000000);
        close (IN);

        $fname = "${jpgpath}l00_cam_$ctrl->{'now_string'}.jpg";
        $fname =~ s / /_/g;
        if (open (OU, ">$fname")) {
            binmode (OU);
            print OU $_;
            close (OU);
        }
    }
}

print $sock "Picture: <a href=\"/ls.htm?path=$jpgpath"."l00_cam.jpg\">l00_cam.jpg</a><br>\n", if (!$autoloading);
print $sock "Do not take Picture: <a href=\"/do.htm?do=Do&path=$doplpath"."l00_camera.pl&piconly=on\">l00_cam.jpg</a>\n", if (!$autoloading);
print $sock " <a href=\"/do.htm?do=Do&path=$doplpath"."l00_camera.pl&piconly=on&allpics=on\">all jpg</a><p>\n", if (!$autoloading);


if ($autoloading) {
    # print date/time stamp if autoloading
    ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
     $size, $atime, $mtime, $ctime, $blksize, $blocks)
     = stat("${jpgpath}l00_cam.jpg");
    ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst)
     = localtime($mtime);
     print $sock 
        sprintf ("%4d/%02d/%02d %02d:%02d:%02d", 1900+$year, 1+$mon, $mday, $hour, $min, $sec),
        " <a href=\"/ls.htm?path=$jpgpath$file\">$file</a><br>\n";
}

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

if ($autoloading) {
    # this is a trick: a img src points back to this URL with takepic=takepic
	# so it lands in this clause to kick start the camera. This allows
	# the main page to be completely sent and start the camera 
	# later.
    print $sock "<img src=\"/do.htm?path=$ctrl->{'FORM'}->{'path'}&takepic=takepic\"><br>";
}
}
1;
