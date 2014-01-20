use l00httpd;
use l00wikihtml;

if  (1) {
    $a = $ctrl->{'droid'}->smsGetMessageCount(0)->{'result'};
    print $sock "smsGetMessageCount $a <br>\n";
    $a = $ctrl->{'droid'}->smsGetMessages(0)->{'result'};
    print $sock "smsGetMessages $a <br>\n";
    $cnt = 0;
    foreach $sms (@$a) {
        print $sock "$cnt at $sms ";
        $b = &l00httpd::dumphashbuf ("sms", $sms);
        print $sock "<pre>$b</pre>\n";
        $cnt++;
    }
    print "Last cnt $cnt\n";
}

