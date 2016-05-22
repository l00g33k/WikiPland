my $a;
if (defined($ctrl)) {
    $a = $ctrl->{'droid'};
} else {
    use Android;
    $a = Android->new();
}

if ($a->getScreenBrightness ()->{'result'} == 255) {
    $a->setScreenBrightness (50);
} else {
    $a->setScreenBrightness (255);
}

#           $vol = $ctrl->{'droid'}->getScreenBrightness ();
#           l00httpd::dbp($config{'desc'}, "'dec10' was $vol->{'result'} ");
#           $vol = $vol->{'result'} - 10;
#           l00httpd::dbp($config{'desc'}, "new $vol\n");
#           $ctrl->{'droid'}->setScreenBrightness ($vol);
