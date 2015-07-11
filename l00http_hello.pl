use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my ($key, $val, $hellomsg);
my %config = (proc => "l00http_hello_proc",
              desc => "l00http_hello_desc");

$hellomsg = '';

sub l00http_hello_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    " 1: hello: Hello, World! And listing all FORM data";
}

sub l00http_hello_proc (\%) {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data

    if (defined ($form->{'clear'})) {
        $hellomsg = '';
    }

    if ((defined ($form->{'message'})) && 
        (length ($form->{'message'}) > 0) && 
        (defined ($form->{'submit'}))) {
        $form->{'message'} =~ s/</&lt;/g;
        $form->{'message'} =~ s/>/&gt;/g;
        # shows only last 6 IP digits
        $_ = substr ($ctrl->{'client_ip'}, length ($ctrl->{'client_ip'}) - 6, 6);
        $hellomsg = "<pre>$ctrl->{'now_string'}, $_ said:</pre>\n$form->{'message'}\n<p>$hellomsg";
    }

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>hello</title>" . $ctrl->{'htmlhead2'};
    if ($ctrl->{'ishost'}) {
        print $sock "$ctrl->{'home'} \n";
    }

    print $sock "<form action=\"/hello.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "        <tr>\n";
    print $sock "            <td>Your message:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"message\" value=\"\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"submit\" value=\"Submit\"></td>\n";
    if ($ctrl->{'ishost'}) {
        print $sock "        <td><input type=\"submit\" name=\"refresh\" value=\"Refresh\">\n";
        print $sock "        <input type=\"submit\" name=\"clear\" value=\"Clear\"></td>\n";
    } else {
        print $sock "        <td><input type=\"submit\" name=\"refresh\" value=\"Refresh\"></td>\n";
    }
    print $sock "    </tr>\n";

    print $sock "</table>\n";
    print $sock "<INPUT TYPE=\"hidden\" NAME=\"ip\" VALUE=\"$ctrl->{'client_ip'}\">\n";
    print $sock "</form>\n";

    # get submitted name and print greeting
    print $sock "$hellomsg\n";

    # dump all form data\
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    for $key (keys %$form) {
        $val = $form->{$key};
        if (!defined ($val) || ($val =~ /^ *$/)) {
            $val = '&nbsp;';
        }
#        if (!$ctrl->{'ishost'}) {
#            # show only last 6 ip to public
#            if ($key eq 'ip') {
#                $val = substr ($val, length ($val) - 6, 6);
#            }
#        }
        print $sock "<tr><td>$key</td><td>$val</td>\n";
    }
    print $sock "</table>\n";


    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
