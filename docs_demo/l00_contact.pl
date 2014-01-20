use l00httpd;
use l00wikihtml;

$a = $ctrl->{'droid'}->contactsGetCount()->{'result'};
print $sock "There are $a contacts<br>\n";

# queryContent
if  (1) {
    undef %hdr;
    undef %out;
    undef %excl;
    $a = $ctrl->{'droid'}->queryContent("content://contacts/people/")->{'result'};

    $cnt = 0;
    $excl{'_sync_dirty'} = 1;
    $excl{'_sync_id'} = 1;
    $excl{'_sync_time'} = 1;
    $excl{'_sync_version'} = 1;
    $excl{'im_account'} = 1;
    $excl{'im_handle'} = 1;
    $excl{'im_protocol'} = 1;
    $excl{'is_friend'} = 1;
    $excl{'merged'} = 1;
    $excl{'mode'} = 1;
    $excl{'send_to_voicemail'} = 1;
    $excl{'sort_string'} = 1;
    $excl{'starred'} = 1;
    $excl{'status'} = 1;
    $excl{'type'} = 1;
    $excl{'number_key'} = 1;
    $excl{'upper_display_name'} = 1;
    $excl{'last_time_contacted'} = 1;

    foreach $contact (@$a) {
        foreach $item (keys %$contact) {
            $hdr{$item}++;
            $out{"$cnt\"$item"} = $contact->{$item};
            #print $sock "$item => $contact->{$item}<br>\n";
        }

        #  print $sock "queryContent $cnt ";
        $b = &l00httpd::dumphashbuf ("Cont $cnt: ", $contact);
        foreach $_ (split ("\n", $b)) {
            #print $sock "$_<br>\n";
        }
        if ($cnt >= 1) {
#            last;
        }
        $cnt++;
    }
    print $sock "Last cnt $cnt<br>\n";


    $outbuf = '||';
    foreach $key (sort keys %hdr) {
        if (!defined ($excl{$key})) {
            $outbuf .= "$key||"; 
        }
    }
    $outbuf .= "\n"; 
    for ($ii = 0; $ii <= $cnt; $ii++) {
        $outbuf .= "||"; 
        foreach $key (sort keys %hdr) {
            if (!defined ($excl{$key})) {
                $tmp = "$ii\"$key";
				if (defined ($out{$tmp})) {
					$outbuf .= "$out{$tmp}||"; 
				} else {
					$outbuf .= "&nbsp;||"; 
                }
            }
        }
        $outbuf .= "\n"; 
    }
    #print $sock "<pre>$outbuf</pre>";
    print $sock &l00wikihtml::wikihtml ($ctrl, "", $outbuf, 0);
}

# contactsGetIds
if  (1) {
    $a = $ctrl->{'droid'}->contactsGetIds()->{'result'};
    print $sock join(" ",@$a),"<br>\n";
    undef %ty;
    foreach $id (@$a) {
        $a=$ctrl->{'droid'}->contactsGetById($id),"<br>\n";
        print $sock "$id: $a->{'result'}->{'type'} ";
        print $sock "$a->{'result'}->{'name'}<br>\n";
        &l00httpd::dumphash ("$id", $a);
        $ty{$a->{'result'}->{'type'}}++;
    }
    foreach $ty (sort keys %ty) {
        print $sock "$ty = $ty{$ty}<br>\n";
    }
}
