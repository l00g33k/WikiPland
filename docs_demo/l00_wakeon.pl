my $form = $ctrl->{'FORM'};

$ctrl->{'droid'}->wakeLockAcquirePartial();

print $sock "wakeLockAcquirePartial<br>";

1;
