my $form = $ctrl->{'FORM'};

$ctrl->{'droid'}->wakeLockRelease();

print $sock "wakeLockRelease<br>";

1;
