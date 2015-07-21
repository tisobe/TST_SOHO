#! /usr/bin/perl -w

# compare measured and predicted solar wind data

# Robert Cameron
# June 2003

@dtab = ([0,0,31,60,91,121,152,182,213,244,274,305,335],
	 [0,0,31,59,90,120,151,181,212,243,273,304,334],
	 [0,0,31,59,90,120,151,181,212,243,273,304,334],
	 [0,0,31,59,90,120,151,181,212,243,273,304,334]);

# create a 100-year hash of MJDs

@ylen = (366,365,365,365);
$d = 40586;
foreach (1970..2070) { $mjd{$_} = $d; $d += $ylen[$_ % 4] };

# get ACE SWEPAM data

@acefiles = glob("*ace_swepam_1h.txt");
foreach (@acefiles) {
    open (IF, $_) or die "Cannot open input SWEPAM file: $_\n";
    while (<IF>) {
	next unless /^20/;
	($y,$m,$d,$hm,$mjd,$sod,$dum,$den,$spd,$dum) = split;
	$key = sprintf "%08d",$mjd*24 + $sod/3600;
	$doy = sprintf "%03d",$dtab[$y % 4][$m] + $d;
	$date{$key} = "$y $doy $hm";
	$aden{$key} = $den;
	$aspd{$key} = $spd;
    }
}

# get SOHO MTOF data

@mtofiles = glob("CRN_*.USED");
foreach (@mtofiles) {
    open (IF, $_) or die "Cannot open input SWEPAM file: $_\n";
    while (<IF>) {
	next unless /^20/;
	($y,$dhms,$dum,$dum,$den,$spd,$dum,$dum) = split;
	($doy,$h,$m,$dum) = split ':',$dhms;
	$key = sprintf "%08d",($mjd{$y}+$doy)*24 + $h;
	$date{$key} = "$y $doy $h$m";
	$mden{$key} = $den;
	$mspd{$key} = $spd;
    }
}

foreach $key (sort(keys(%date))) {
    $key1 = sprintf "%08d",$key - 655;
    $key2 = sprintf "%08d",$key - 1309;
    $key3 = sprintf "%08d",$key - 1964;
    @aden = ();
    @aspd = ();
    @mden = ();
    @mspd = ();
    foreach (($key,$key1,$key2,$key3)) {
	push @aden,$aden{$_} if ($aden{$_} and abs($aden{$_}) < 9900);
	push @aspd,$aspd{$_} if ($aspd{$_} and abs($aspd{$_}) < 9900);
	push @mden,$mden{$_} if ($mden{$_} and abs($mden{$_}) < 9900);
	push @mspd,$mspd{$_} if ($mspd{$_} and abs($mspd{$_}) < 9900);
    }
    if (@aden > 1) { $aden0 += ($aden[1] - $aden[0])**2; $naden0++ };
    if (@aspd > 1) { $aspd0 += ($aspd[1] - $aspd[0])**2; $naspd0++ };
    if (@mden > 1) { $mden0 += ($mden[1] - $mden[0])**2; $nmden0++ };
    if (@mspd > 1) { $mspd0 += ($mspd[1] - $mspd[0])**2; $nmspd0++ };
    if (@aden > 2) { $aden1 += ($aden[1]*2 - $aden[2] - $aden[0])**2; $naden1++ };
    if (@aspd > 2) { $aspd1 += ($aspd[1]*2 - $aspd[2] - $aspd[0])**2; $naspd1++ };
    if (@mden > 2) { $mden1 += ($mden[1]*2 - $mden[2] - $mden[0])**2; $nmden1++ };
    if (@mspd > 2) { $mspd1 += ($mspd[1]*2 - $mspd[2] - $mspd[0])**2; $nmspd1++ };
}
$naden0--;
$naspd0--;
$nmden0--;
$nmspd0--;
$naden1--;
$naspd1--;
$nmden1--;
$nmspd1--;
$aden0 = sqrt($aden0/$naden0);
$aspd0 = sqrt($aspd0/$naspd0);
$mden0 = sqrt($mden0/$nmden0);
$mspd0 = sqrt($mspd0/$nmspd0);
$aden1 = sqrt($aden1/$naden1);
$aspd1 = sqrt($aspd1/$naspd1);
$mden1 = sqrt($mden1/$nmden1);
$mspd1 = sqrt($mspd1/$nmspd1);
#print "$naspd0 $naspd1 $nmspd0 $nmspd1 $naden0 $naden1 $nmden0 $nmden1\n";
printf "%.1f %.1f %.1f %.1f %.1f %.1f %.1f %.1f\n",$aspd0,$aspd1,$mspd0,$mspd1,$aden0,$aden1,$mden0,$mden1;
