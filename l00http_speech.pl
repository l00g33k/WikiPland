use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# Interface to speech to text and back

my %config = (proc => "l00http_speech_proc",
              desc => "l00http_speech_desc");
my ($speech);

$speech = '';

sub l00http_speech_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "speech: Speech to text and text to speech";
}

sub l00http_speech_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my (@alllines, $line, $stt, $scratch);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>speech</title>" . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">Quick</a><br>\n";
    print $sock "<a href=\"#end\">Jump to end</a>\n";


    if (defined ($form->{'append'})) {
        if (defined ($form->{'speech'})) {
            $speech = "$form->{'speech'} ";
        } else {
            $speech = '';
        }
        if ($ctrl->{'os'} eq 'and') {
            $stt = $ctrl->{'droid'}->recognizeSpeech (); 
            $speech .= $stt->{'result'};
            $ctrl->{'droid'}->setClipboard ($speech); 
        }
    }
    if (defined ($form->{'paste'})) {
        $speech = '';
        if ($ctrl->{'os'} eq 'and') {
            $scratch = $ctrl->{'droid'}->getClipboard();
            $scratch = $scratch->{'result'};
            $speech .= $scratch;
        }
    }
    if (defined ($form->{'pasteappend'})) {
        if (defined ($form->{'speech'})) {
            $speech = "$form->{'speech'} ";
        } else {
            $speech = '';
        }
        if ($ctrl->{'os'} eq 'and') {
            $scratch = $ctrl->{'droid'}->getClipboard();
            $scratch = $scratch->{'result'};
            $speech .= $scratch;
        }
    }
    if (defined ($form->{'new'})) {
        if ($ctrl->{'os'} eq 'and') {
            $stt = $ctrl->{'droid'}->recognizeSpeech (); 
            $speech = $stt->{'result'};
            $ctrl->{'droid'}->setClipboard ($speech); 
        }
    }
    if (defined ($form->{'speak'})) {
        if ($ctrl->{'os'} eq 'and') {
            $ctrl->{'droid'}->ttsSpeak ($speech); 
        }
    }

    print $sock "<form action=\"/speech.htm\" method=\"post\">\n";
    print $sock "<textarea name=\"speech\" cols=\"$ctrl->{'txtw'}\" rows=\"$ctrl->{'txth'}\">$speech</textarea>\n";
    print $sock "<p>Recognize speech: <input type=\"submit\" name=\"new\" value=\"New\">\n";
    print $sock "<input type=\"submit\" name=\"append\" value=\"Append\"> and put into clipboard\n";
    print $sock "<p><input type=\"submit\" name=\"speak\" value=\"Speak\">\n";
    print $sock "<input type=\"submit\" name=\"paste\" value=\"Paste\">\n";
    print $sock "<input type=\"submit\" name=\"pasteappend\" value=\"PasteAdd\">\n";
    print $sock "</form>\n";


    print $sock "<hr>$speech\n";

    print $sock "<a name=\"end\"></a>\n";

 
    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
