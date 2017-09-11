my $a;
if (defined($ctrl)) {
    $a = $ctrl->{'droid'};
} else {
    use Android;
    $a = Android->new();
}

if ($a->getScreenBrightness ()->{'result'} == 255) {
    $a->setScreenBrightness (20);
} else {
    $a->setScreenBrightness (255);
}

