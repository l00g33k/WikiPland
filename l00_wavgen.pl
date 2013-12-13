# 0 = test
# 1 = demo
# 2 = ringtone
#   ** Phone ringtone:
#   *** length of rings: 24 secs
#   *** soft with enough time to answer, / 36, 5s, ding-dong, di
#   *** midium for remaining, / 6, 5s
#   *** loudest with enough time to answer, / 1, 5s
#   *** loudest with enough time to answer, / 1, chirp, remainin
# 3 = wakeup
# 4 = hey

$type = 3;


$fname = "/sdcard/ringtones/mytone.wav";
$fs = 11025 * 2;
$PI = 3.141592653589793;

$period = $fs / 8;
$amp = 32766 / 100;


if ($type == 4) {
    $fname = "/sdcard/ringtones/myhey.wav";
    if ($ctrl{'os'} eq 'win') {
        $fname = "c:\\x\\myhey.wav";
    }
    $amp = 32766 / 50;
    $decay = 10 ** ((log (.05) / log (10)) / $fs);
    $decay2 = 10 ** ((log (.1) / log (10)) / $fs);
    $dings = sprintf ("%g,%g,%g,%g;;;%g,%g,%g,%g;", 
       8 * 440, 0, $amp, $decay,
       8 * 440, 0, $amp, $decay2);

    $cmd = "";
    $cmd .= "$dings" . (".;" x 236);    # 30 seconds long
#    $cmd .= "$dings" . (".;" x 44);
    $cmd = $cmd x 30;   # 15 minutes
    chop ($cmd);
}


if ($type == 3) {
    $fname = "/sdcard/ringtones/mywake.wav";
#    $amp = 32766 / 216;
    $amp = 32766 / 512;
    $ch0 = 440 * 5;
    $ch1 = 440 * 9;
    $decay = 10 ** ((log (.05) / log (10)) / $fs);
    $decay2 = 10 ** ((log (.1) / log (10)) / $fs);
    $cmd = "";

    for ($loop = 0; $loop < 4; $loop++) {
        $dings = sprintf ("%g,%g,%g,%g;", 
           8 * 440, 0, $amp, $decay2);
        $cmd .= ("$dings" . (".;" x 47)) x 5; # 47 15
 
        $dings = sprintf ("%g,%g,%g,%g;;%g,%g,%g,%g;;", 
           8 * 440, 0, $amp, $decay,
           6 * 440, 0, $amp, $decay);
        $dongs = sprintf ("%g,%g,%g,%g;", 
           8 * 440, 0, $amp, $decay2);
        $cmd .= ("$dings$dongs" . (".;" x 43)) x 2; # 43 11
 
        $dings = sprintf ("%g,%g,%g,%g;;%g,%g,%g,%g;;", 
           8 * 440, 0, $amp, $decay,
           6 * 440, 0, $amp, $decay);
        $dongs = sprintf ("%g,%g,%g,%g;", 
           8 * 440, 0, $amp, $decay2);
        $cmd .= ("$dings$dings$dongs" . (".;" x 39)) x 2; # 39 7
 
        $dings = sprintf ("%g,%g,%g,%g;;%g,%g,%g,%g;;".
                          "%g,%g,%g,%g;;%g,%g,%g,%g;;", 
            6 * 440, 0, $amp, $decay,
            7 * 440, 0, $amp, $decay,
            8 * 440, 0, $amp, $decay,
            9 * 440, 0, $amp, $decay);
        $cmd .= "$dings$dings" . (".;" x 16);
        $amp *= 8;
    }
    $amp = 32766 / 1;
    $dings = sprintf ("%g,%g,%g,%g;;%g,%g,%g,%g;;", 
       8 * 440, 0, $amp, $decay,
       6 * 440, 0, $amp, $decay);
    $chirp = sprintf ("%g,%g,%g,%g;%g,%g,%g,%g;", 
       $ch0, ($ch1 - $ch0) / $period, $amp, 1,
       $ch1, ($ch0 - $ch1) / $period, $amp, 1);
    $cmd .= "$dings$dings$chirp$chirp$chirp$chirp" x 30;

    chop ($cmd);
}

if ($type == 0) {
    $fname = "/sdcard/ringtones/mytest.wav";
    $amp = 32766 / 200;
    $decay = 10 ** ((log (.05) / log (10)) / $fs);
    $decay2 = 10 ** ((log (.1) / log (10)) / $fs);
    $cmd = "";
    $dings = sprintf ("%g,%g,%g,%g;", 
       8 * 440, 0, $amp, $decay2);
    $cmd .= ("$dings" . (".;" x 15)) x 2; # 47 15
    $dings = sprintf ("%g,%g,%g,%g;;%g,%g,%g,%g;;", 
        8 * 440, 0, $amp, $decay,
        6 * 440, 0, $amp, $decay);
    $dongs = sprintf ("%g,%g,%g,%g;.;.;.;", 
        8 * 440, 0, $amp, $decay2);
    $cmd .= "$dings$dings$dongs.;.;.;.;" x 2;
    $dings = sprintf ("%g,%g,%g,%g;;%g,%g,%g,%g;;".
                      "%g,%g,%g,%g;;%g,%g,%g,%g;;", 
        6 * 440, 0, $amp, $decay,
        7 * 440, 0, $amp, $decay,
        8 * 440, 0, $amp, $decay,
        9 * 440, 0, $amp, $decay);
    $cmd .= "$dings$dings" x 2;
    chop ($cmd);
}

if ($type == 1) {
    $fname = "/sdcard/ringtones/mytone.wav";
    $amp = 32766 / 36;
    $decay = 10 ** ((log (.05) / log (10)) / $fs);
    $decay2 = 10 ** ((log (.1) / log (10)) / $fs);
    $dings = sprintf ("%g,%g,%g,%g;;%g,%g,%g,%g;;", 
       10 * 440, 0, $amp, $decay,
        8 * 440, 0, $amp, $decay);
    $dongs = sprintf ("%g,%g,%g,%g;.;.;.;", 
       11 * 440, 0, $amp, $decay2);

    $cmd = "";
    $cmd .= "$dings$dings$dongs.;.;.;.;";
    chop ($cmd);
}

if ($type == 2) {
    $ch0 = 440 * 5;
    $ch1 = 440 * 9;
    $decay = 10 ** ((log (.05) / log (10)) / $fs);
    $decay2 = 10 ** ((log (.1) / log (10)) / $fs);
    $fname = "/sdcard/ringtones/myringtones.wav";
    $cmd = "";

    $amp = 32766 / 36;
    $dings = sprintf ("%g,%g,%g,%g;;%g,%g,%g,%g;;", 
       8 * 440, 0, $amp, $decay,
       6 * 440, 0, $amp, $decay);
    $dongs = sprintf ("%g,%g,%g,%g;.;.;.;", 
       8 * 440, 0, $amp, $decay2);
    $cmd .= "$dings$dings$dongs.;.;.;.;" x 3;

    $amp = 32766 / 6;
    $dings = sprintf ("%g,%g,%g,%g;;%g,%g,%g,%g;;", 
       8 * 440, 0, $amp, $decay,
       6 * 440, 0, $amp, $decay);
    $dongs = sprintf ("%g,%g,%g,%g;.;.;.;", 
       8 * 440, 0, $amp, $decay2);
    $cmd .= "$dings$dings$dongs.;.;.;.;" x 3;
    $amp = 32766 / 1;
    $dings = sprintf ("%g,%g,%g,%g;;%g,%g,%g,%g;;", 
       8 * 440, 0, $amp, $decay,
       6 * 440, 0, $amp, $decay);
    $dongs = sprintf ("%g,%g,%g,%g;.;.;.;", 
       8 * 440, 0, $amp, $decay2);
    $cmd .= "$dings$dings$dongs.;.;.;.;" x 3;
    $dings = sprintf ("%g,%g,%g,%g;;%g,%g,%g,%g;;", 
       8 * 440, 0, $amp, $decay,
       6 * 440, 0, $amp, $decay);
    $chirp = sprintf ("%g,%g,%g,%g;%g,%g,%g,%g;", 
       $ch0, ($ch1 - $ch0) / $period, $amp, 1,
       $ch1, ($ch0 - $ch1) / $period, $amp, 1);
    $cmd .= "$dings$dings$chirp$chirp" x 10;
 
    chop ($cmd);
}





$ii = 0;
$phase = 0;
$data = "";
print "cmd >$cmd<\n";
foreach $ln (split (';', $cmd)) {
    if ($ln =~ /.+,.+,.+,.+/) {
        ($fre, $inc, $amp, $decay) = split (',', $ln);
        print "$ii: ($fre, $inc, $amp, $decay)\n";
    } else {
        if ($ctrl{'os'} eq 'and') {
            print "$ii:\n";
        }
    }
    for ($jj = 0; $jj < $period; $jj++) {
        $val = $amp * sin (2 * $PI * $phase);
        substr ($data, $ii * 2, 2) = pack ('s', $val);
        $ii++;
        $amp *= $decay;
        $phase += $fre / $fs;
        $fre += $inc;
    }
}
print "$ii: (done)\n";

if ($type == 1) {
    $data = $data . $data . $data . $data;
}






$siz = length ($data);
print $sock "Generated $siz bytes at $fs Hz Fs or ", $siz / $fs, " seconds in $fname\n";

    #A A text (ASCII) string, will be space padded 
    #c A signed char (8-bit) value 
    #C An unsigned char (octet) value
    #s A signed short (16-bit) value 
    #S An unsigned short value 
    #l A signed long (32-bit) value 
    #L An unsigned long value

open (OUT, ">$fname");
binmode (OUT);

    #  Offset Size Name Description The canonical WAVE format starts with the RIFF header: 
    #0 4 ChunkID Contains the letters "RIFF" in ASCII form (0x52494646 big-endian form). 
print OUT pack ('A4', 'RIFF');
    #4 4 ChunkSize 36 + SubChunk2Size, or more precisely: 4 + (8 + SubChunk1Size) + (8 + SubChunk2Size) This is the size of the rest of the chunk following this number. This is the size of the entire file in bytes minus 8 bytes for the two fields not included in this count: ChunkID and ChunkSize. 
print OUT pack ('l', 36 + 8 + length ($data));
    #8 4 Format Contains the letters "WAVE" (0x57415645 big-endian form). The "WAVE" format consists of two subchunks: "fmt " and "data": The "fmt " subchunk describes the sound data's format: 
print OUT pack ('A4', 'WAVE');
    #12 4 Subchunk1ID Contains the letters "fmt " (0x666d7420 big-endian form). 
print OUT pack ('A4', 'fmt ');
    #16 4 Subchunk1Size 16 for PCM. This is the size of the rest of the Subchunk which follows this number. 
print OUT pack ('l', 16);
    #20 2 AudioFormat PCM = 1 (i.e. Linear quantization) Values other than 1 indicate some form of compression. 
print OUT pack ('s', 1);
    #22 2 NumChannels Mono = 1, Stereo = 2, etc. 
print OUT pack ('s', 1);
    #24 4 SampleRate 8000, 44100, etc. 
print OUT pack ('l', $fs);
    #28 4 ByteRate == SampleRate * NumChannels * BitsPerSample/8 
print OUT pack ('l', $fs * 2);
    #32 2 BlockAlign == NumChannels * BitsPerSample/8 The number of bytes for one sample including all channels. I wonder what happens when this number isn't an integer? 
print OUT pack ('s', 2);
    #34 2 BitsPerSample 8 bits = 8, 16 bits = 16, etc. 2 ExtraParamSize if PCM, then doesn't exist X ExtraParams space for extra parameters The "data" subchunk contains the size of the data and the actual sound: 
print OUT pack ('s', 16);
    #36 4 Subchunk2ID Contains the letters "data" (0x64617461 big-endian form). 
print OUT pack ('A4', 'data');
    #40 4 Subchunk2Size == NumSamples * NumChannels * BitsPerSample/8 This is the number of bytes in the data. You can also think of this as the size of the read of the subchunk following this number. 
print OUT pack ('l', length ($data));
    #44 * Data The actual sound data. 

print OUT $data;
close (OUT);
    

1;
