use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my ($key, $val, $msgcnt);
my %config = (proc => "l00http_hello_proc",
              desc => "l00http_hello_desc");
$msgcnt = 0;

sub l00http_hello_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    " 1: hello: A trivial chat server without auto refresh";
}

sub l00http_hello_proc (\%) {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($hellomsg, $delimiter, $history, $ii, $lastlast, $secondlast);

    #$history = "$ctrl->{'workdir'}l00_hello.txt";
    $history = "l00://hello.txt";
    if (defined($ctrl->{'hello'})) {
        $history = $ctrl->{'hello'};
print "history $ctrl->{'hello'}\n";
    }

    $hellomsg = '';
    if (defined ($form->{'clear'})) {
        if (&l00httpd::l00fwriteOpen($ctrl, $history)) {
            &l00httpd::l00fwriteClose($ctrl);
        }
    } else {
        # load from file
		if (&l00httpd::l00freadOpen($ctrl, $history)) {
            $hellomsg = &l00httpd::l00freadAll($ctrl);
		}
    }

    if (defined ($form->{'paste'})) {
        $form->{'submit'} = 1;
        $form->{'message'} = &l00httpd::l00getCB($ctrl);
    }
    if ((defined ($form->{'message'})) && 
        (length ($form->{'message'}) > 0) && 
        (defined ($form->{'submit'}))) {
        $form->{'message'} =~ s/</&lt;/g;
        $form->{'message'} =~ s/>/&gt;/g;
        $form->{'message'} =~ s/\r//g;
        $form->{'message'} =~ s/\n/<br>\n/g;
        # shows only last 6 IP digits
        $_ = substr ($ctrl->{'client_ip'}, length ($ctrl->{'client_ip'}) - 6, 6);
        $msgcnt++;
        $hellomsg = "<code>$msgcnt: $ctrl->{'now_string'}, $_ said:</code> $form->{'message'}\n<br>$hellomsg";
        if (&l00httpd::l00fwriteOpen($ctrl, $history)) {
            &l00httpd::l00fwriteBuf($ctrl, $hellomsg);
            &l00httpd::l00fwriteClose($ctrl);
        }
    }

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>hello</title>" . $ctrl->{'htmlhead2'};
    if ($ctrl->{'ishost'}) {
        print $sock "$ctrl->{'home'} \n";
    }

    print $sock "<a name=\"top\"></a><form action=\"/hello.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "        <tr>\n";
    print $sock "            <td>Your message&#818;:</td>\n";
    print $sock "            <td><textarea name=\"message\" cols=\"16\" rows=\"4\" accesskey=\"e\"></textarea></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"submit\" value=\"S&#818;ubmit\" accesskey=\"s\"></td>\n";
    if ($ctrl->{'ishost'}) {
        print $sock "        <td><input type=\"submit\" name=\"refresh\" value=\"R&#818;efresh\" accesskey=\"r\">\n";
        print $sock "        <input type=\"submit\" name=\"clear\" value=\"C&#818;lear\" accesskey=\"c\">\n";
        print $sock "        <input type=\"submit\" name=\"paste\" value=\"P&#818;aste\" accesskey=\"p\"></td>\n";
    } else {
        print $sock "        <td><input type=\"submit\" name=\"refresh\" value=\"R&#818;efresh\" accesskey=\"r\"></td>\n";
    }
    print $sock "    </tr>\n";

    print $sock "</table>\n";
    print $sock "<INPUT TYPE=\"hidden\" NAME=\"ip\" VALUE=\"$ctrl->{'client_ip'}\">\n";
    print $sock "</form>\n";

    print $sock "System uptime: $ctrl->{'uptime'}. Jump to <a href=\"#end\">bottom</a><p>\n";
    if (defined($ctrl->{'demomsg'})) {
        print $sock "$ctrl->{'demomsg'}<p>\n";
    }
    if ($ctrl->{'ishost'}) {
        print $sock "View <a href=\"/view.htm?path=$history\">$history</a><p>\n";
        print $sock "Change history file: <a href=\"/eval.htm?eval=%23+++%24ctrl-%3E%7B%27hello%27%7D%3D%22%24ctrl-%3E%7B%27workdir%27%7Dhello.text.local%22%3B\" target=\"_blank\">modify 'hello'</a> (remove # then Eval<p>\n";
    }

    # get submitted name and print greeting
    $ii = 400;
    $lastlast = '';
    $secondlast = '';
    foreach $_ (split("\n", $hellomsg)) {
        if ($ii-- >= 0) {
            print $sock "$_\n";
        } else {
            # so we can display the last two lines;
            $secondlast = $lastlast;
            $lastlast = $_;
        }
    }
    # display the last two lines if exist
    print $sock "<p>Some messages are left out due to length<p>\n", if ($lastlast ne '');
    print $sock "$secondlast\n", if ($secondlast ne '');
    print $sock "$lastlast\n", if ($lastlast ne '');

    # dump all form data\
    print $sock "<a name=\"end\"></a><p>Jump to <a href=\"#top\">top</a>. All HTTP form parameters supplied in the URL:<p>".
        "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    for $key (keys %$form) {
        $val = $form->{$key};
        if (!defined ($val) || ($val =~ /^ *$/)) {
            $val = '&nbsp;';
        }
        print $sock "<tr><td>$key</td><td>$val</td>\n";
    }
    print $sock "</table>\n";


    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
