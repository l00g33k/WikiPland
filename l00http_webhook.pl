use strict;
use warnings;

use l00httpd;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my ($seqno, $key, $val, $msgcnt);
my %config = (proc => "l00http_webhook_proc",
              desc => "l00http_webhook_desc");
$msgcnt = 0;
$seqno = 0;

sub l00http_webhook_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "webhook: A semi public webhook for posting messages";
}

sub l00http_webhook_proc (\%) {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($delimiter, $ii, $lastlast, $secondlast);
    my ($postkey, $viewkey, $mode, $history, $store);

    # must have keys, one for posting, the other for viewing, delimiter :
    $mode = '';
    if (defined($ctrl->{'webhookpostviewkeys'})) {
        ($postkey, $viewkey) = $ctrl->{'webhookpostviewkeys'} 
            =~ /(.+):(.+)/;
    }

    if (defined ($form->{'key'})) {
        if (($form->{'key'} eq $postkey) &&
            (defined ($form->{'msg'}))) {
            # valid post key
            $mode = 'post';
        }
        if ($form->{'key'} eq $viewkey) {
            # valid view key
            $mode = 'view';
        }
    }


    if ($mode eq '') {
        # no valid keys
        print $sock '{ "result" : "failed" }';
        return;
    }

    $history = '';
    $store = "l00://webhook.txt";
	if (&l00httpd::l00freadOpen($ctrl, $store)) {
        $history = &l00httpd::l00freadAll($ctrl);
	}


    if ($mode eq 'post') {
        $seqno++;
        $_ = $ctrl->{'client_ip'};
        s/^\d+\.\d+\.//;
        $_ = sprintf("%04d: %s: %s: ", $seqno, $ctrl->{'now_string'}, $_);
        $history = "$_$form->{'msg'}\n$history";
        if (&l00httpd::l00fwriteOpen($ctrl, $store)) {
            &l00httpd::l00fwriteBuf($ctrl, $history);
            &l00httpd::l00fwriteClose($ctrl);
        }
        print $sock "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n";
        print $sock '{ "result" : "success" }';
    }

    if ($mode eq 'view') {
        if (!$ctrl->{'ishost'}) {
            print $sock "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n";
            print $sock "$history";
        } else {
            # Send HTTP and HTML headers
            print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>webhook</title>" . $ctrl->{'htmlhead2'};

            print $sock "<a name=\"top\">\n";
            print $sock "Jump to <a href=\"#end\">bottom</a> - \n";
            print $sock "View <a href=\"/view.htm?path=$store\">$store</a><p>\n";

            if ($history eq '') {
                $history = '(no messages posted)';
            }
            print $sock "<pre>\n";
            print $sock "$history\n";
            print $sock "</pre>\n";

            print $sock "Jump to <a name=\"bottom\"></a><a href=\"#top\">top</a><p>\n";

            print $sock "How to post and view using wget:<p>\n";
            print $sock "Post: wget -q -O - --user=user --password=password \"http://127.0.0.1:20338/webhook.htm?key=$postkey&msg=message+body\"<p>\n";
            print $sock "View: wget -q -O - --user=user --password=password \"http://127.0.0.1:20338/webhook.htm?key=$viewkey\"<br>\n";

            # send HTML footer and ends
            print $sock $ctrl->{'htmlfoot'};
        }
    }
}


\%config;
