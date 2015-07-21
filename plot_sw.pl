#!/usr/bin/env /proj/sot/ska/bin/perl
use warnings;

# Use monthly ACE SWEPAM and SOHO MTOF files
# to extrapolate solar wind into the future

# Robert Cameron
# May 2003

#from: http://quake.stanford.edu/~wso/words/Coordinates.html
#Lord Carrington determined the solar rotation rate 
#by watching low-latitude sunspots in the 1850s. 
#He defined a fixed solar coordinate system that rotates
#in a sidereal frame exactly once every 25.38 days 
#(Carrington, Observations of the Spots on the Sun, 1863, p 221, 244). 
#The synodic rotation rate varies a little during the year 
#because of the eccentricity of the Earth's orbit; 
#the mean synodic value is about 27.2753 days. 
#See the back of an Astronomical Almanac for details. 

use PGPLOT;

$wdir = "/proj/rac/ops/SOHO";

#pgbegin (0,'/xs',1,3);
pgbegin (0,"$wdir/solwin.gif/vgif",1,5);
pgsch(2.4);

@dtab = ([0,0,31,60,91,121,152,182,213,244,274,305,335],
	 [0,0,31,59,90,120,151,181,212,243,273,304,334],
	 [0,0,31,59,90,120,151,181,212,243,273,304,334],
	 [0,0,31,59,90,120,151,181,212,243,273,304,334]);

# create a 100-year hash of MJDs

@ylen = (366,365,365,365);
$d = 40586;
foreach (1970..2070) { $mjd{$_} = $d; $d += $ylen[$_ % 4] };

# get ACE SWEPAM data

open (IF, "$wdir/swepam") or die "Cannot open input SWEPAM file\n";
@l = <IF>;
foreach (@l) {
  next unless /^20/;
  ($y,$m,$d,$hm,$mjd,$sod,$dum,$den,$spd,$dum) = split;
  $key = sprintf "%08d",$mjd*24 + $sod/3600;
  $doy = sprintf "%03d",$dtab[$y % 4][$m] + $d;
  $adate{$key} = "$y $doy $hm";
  $aden0{$key} = $den;
  $aden1{$key} = $den;
  $aspd0{$key} = $spd;
  $aspd1{$key} = $spd;
}
@ak = sort keys %adate;
$rak = $ak[-1]-$ak[0];
print "SWEPAM time range = $rak\n";

# get SOHO MTOF data

open (IF, "$wdir/mtof") or die "Cannot open input MTOF file\n";
@l = <IF>;
foreach (@l) {
  next unless /^20/;
  ($y,$dhms,$dum,$dum,$den,$spd,$dum,$dum) = split;
  ($doy,$h,$m,$dum) = split ':',$dhms;
  $key = sprintf "%08d",($mjd{$y}+$doy)*24 + $h;
  $mdate{$key} = "$y $doy $h$m";
  $mden0{$key} = $den;
  $mden1{$key} = $den;
  $mspd0{$key} = $spd;
  $mspd1{$key} = $spd;
}
@mk = sort keys %mdate;
$rmk = $mk[-1]-$mk[0];
print "MTOF time range = $rmk\n";

# read Chandra ephemeris

open (IF, "$wdir/PE.EPH.gsme") or die "Cannot open input Chandra ephemeris file\n";
@l = <IF>;
foreach (@l) {
  ($dum,$rkm,$tgsm,$pgsm,$dum,$dum,$fy,$mon,$d,$h,$min,$dum) = split;
  next if ($min);
  $y = int($fy);
  $h = sprintf "%02d",$h;
  $min = sprintf "%02d",$min;
  $doy = sprintf "%03d",$dtab[$y % 4][$mon] + $d;
  $key = sprintf "%08d",($mjd{$y}+$doy)*24 + $h;
  $edate{$key} = "$y $doy $h$min";
  $rkm{$key} = $rkm;
  $tgsm{$key} = $tgsm;
  $pgsm{$key} = $pgsm;
}
@ek = sort keys %edate;
$rek = $ek[-1]-$ek[0];
print "ephemeris time range = $rek\n";

# get current time, and extrapolate 28 days into the future

$now = time;
for $fh (0..28*24) {
    ($h,$y,$doy) = (gmtime($now + $fh*3600))[2,5,7];
#    $ydh = sprintf "%04d %03d %02d00",$y+1900,$doy,$h;
    $key = sprintf "%08d",($mjd{$y+1900}+$doy)*24 + $h;
    $key1 = sprintf "%08d",$key - 655;
    $key2 = sprintf "%08d",$key - 1309;
    $key3 = sprintf "%08d",$key - 1964;
    $key4 = sprintf "%08d",$key - 2618;
#    $adate{$key} = $ydh;
#    $mdate{$key} = $ydh;
    @aden=();
    @aspd=();
    @mden=();
    @mspd=();
    foreach (($key1,$key2,$key3,$key4)) {
	push @aden,$aden0{$_} if ($aden0{$_} and abs($aden0{$_}) < 9900);
	push @aspd,$aspd0{$_} if ($aspd0{$_} and abs($aspd0{$_}) < 9900);
	push @mden,$mden0{$_} if ($mden0{$_} and abs($mden0{$_}) < 9900);
	push @mspd,$mspd0{$_} if ($mspd0{$_} and abs($mspd0{$_}) < 9900);
    }
    push @aden0,(@aden < 1)? -9999 : $aden[0];
    push @aspd0,(@aspd < 1)? -9999 : $aspd[0];
    push @mden0,(@mden < 1)? -9999 : $mden[0];
    push @mspd0,(@mspd < 1)? -9999 : $mspd[0];
    push @aden1,(@aden < 2)? -9999 : $aden[0]*2 - $aden[1];
    push @aspd1,(@aspd < 2)? -9999 : $aspd[0]*2 - $aspd[1];
    push @mden1,(@mden < 2)? -9999 : $mden[0]*2 - $mden[1];
    push @mspd1,(@mspd < 2)? -9999 : $mspd[0]*2 - $mspd[1];
    push @dd,$doy+$h/24;
    push @rkm,$rkm{$key}/1000;
    push @mlat,90-$tgsm{$key};
    push @mlon,$pgsm{$key};
    push @adenu0,(@aden < 2)? -9999 : $aden[1] - $aden[0];
    push @aspdu0,(@aspd < 2)? -9999 : $aspd[1] - $aspd[0];
    push @mdenu0,(@mden < 2)? -9999 : $mden[1] - $mden[0];
    push @mspdu0,(@mspd < 2)? -9999 : $mspd[1] - $mspd[0];
    push @adenu1,(@aden < 3)? -9999 : $aden[1]*2 - $aden[2] - $aden[0];
    push @aspdu1,(@aspd < 3)? -9999 : $aspd[1]*2 - $aspd[2] - $aspd[0];
    push @mdenu1,(@mden < 3)? -9999 : $mden[1]*2 - $mden[2] - $mden[0];
    push @mspdu1,(@mspd < 3)? -9999 : $mspd[1]*2 - $mspd[2] - $mspd[0];
    if (@aden > 1) { $adens0 += ($aden[1] - $aden[0])**2; $nadens0++ };
    if (@aspd > 1) { $aspds0 += ($aspd[1] - $aspd[0])**2; $naspds0++ };
    if (@mden > 1) { $mdens0 += ($mden[1] - $mden[0])**2; $nmdens0++ };
    if (@mspd > 1) { $mspds0 += ($mspd[1] - $mspd[0])**2; $nmspds0++ };
    if (@aden > 2) { $adens1 += ($aden[1]*2 - $aden[2] - $aden[0])**2; $nadens1++ };
    if (@aspd > 2) { $aspds1 += ($aspd[1]*2 - $aspd[2] - $aspd[0])**2; $naspds1++ };
    if (@mden > 2) { $mdens1 += ($mden[1]*2 - $mden[2] - $mden[0])**2; $nmdens1++ };
    if (@mspd > 2) { $mspds1 += ($mspd[1]*2 - $mspd[2] - $mspd[0])**2; $nmspds1++ };
}
$nadens0--;
$naspds0--;
$nmdens0--;
$nmspds0--;
$nadens1--;
$naspds1--;
$nmdens1--;
$nmspds1--;
$adens = sprintf "%.1f,%.1f",sqrt($adens0/$nadens0),sqrt($adens1/$nadens1);
$aspds = sprintf "%d,%d",sqrt($aspds0/$naspds0),sqrt($aspds1/$naspds1);
$mdens = sprintf "%.1f,%.1f",sqrt($mdens0/$nmdens0),sqrt($mdens1/$nmdens1);
$mspds = sprintf "%d,%d",sqrt($mspds0/$nmspds0),sqrt($mspds1/$nmspds1);

$npt = @dd;

$tstamp = `date`;
chomp $tstamp;

pgsci(1);
pgpage;
pgsvp(0.05,0.95,0.15,0.9);
pgswin($dd[0], $dd[-1], -200, 200);
pgbox('BCTSN',0.0,0,'BCTN',0.0,0);
#pgenv ($dd[0], $dd[-1], -200, 200, 0, 0);
pglab ("", "degrees,Mm", "");
pgtext ($dd[0]+13, 210, "GSM Coordinates");
pgtext ($dd[-1]-8, 210, $tstamp);
pgsci(3);
pgline ($npt, \@dd, \@rkm);
pgsci(2);
pgline ($npt, \@dd, \@mlat);
pgsci(1);
pgpoint ($npt, \@dd, \@mlon, 1);

pgsci(1);
pgpage;
pgsvp(0.05,0.95,0.1,0.95);
pgswin($dd[0], $dd[-1], 0, 1000);
pgbox('BCTSN',0.0,0,'BCTN',0.0,0);
#pgenv ($dd[0], $dd[-1], 0, 1000, 0, 0);
pglab ("", "km/s", "");
pgtext ($dd[0]+13, 1020, "Solar Wind Speed");
pgtext ($dd[-1]-6, 1020, ". 0th order, + 1st order");
pgsci(3);
pgpoint ($npt, \@dd, \@aspd0, 1);
pgpoint ($npt, \@dd, \@aspd1, 2);
pgtext ($dd[0], 1020, "ACE SWEPAM");
pgsci(2);
pgpoint ($npt, \@dd, \@mspd0, 1);
pgpoint ($npt, \@dd, \@mspd1, 2);
pgtext ($dd[0]+3, 1020, "SOHO MTOF");

pgsci(1);
pgpage;
pgsvp(0.05,0.95,0.1,0.95);
pgswin($dd[0], $dd[-1], -1000, 1000);
pgbox('BCTSN',0.0,0,'BCTN',0.0,0);
#pgenv ($dd[0], $dd[-1], -1000, 1000, 0, 0);
pglab ("", "km/s", "");
pgtext ($dd[0]+9, 1040, "Solar Wind Speed Uncertainty (Predicted - Measured)");
#pgtext ($dd[-1]-5, 1040, ". 0th order, + 1st order");
pgsci(3);
pgpoint ($npt, \@dd, \@aspdu0, 1);
pgpoint ($npt, \@dd, \@aspdu1, 2);
pgtext ($dd[0], 1040, $aspds);
pgsci(2);
pgpoint ($npt, \@dd, \@mspdu0, 1);
pgpoint ($npt, \@dd, \@mspdu1, 2);
pgtext ($dd[0]+2, 1040, $mspds);

pgsci(1);
pgpage;
pgsvp(0.05,0.95,0.1,0.95);
pgswin($dd[0], $dd[-1], 0, 40);
pgbox('BCTSN',0.0,0,'BCTN',0.0,0);
#pgenv ($dd[0], $dd[-1], 0, 40, 0, 0);
pglab ("", "p/cc", "");
pgtext ($dd[0]+12, 41, "Solar Wind Proton Density");
#pgtext ($dd[-1]-5, 41, ". 0th order, + 1st order");
pgsci(3);
pgpoint ($npt, \@dd, \@aden0, 1);
pgpoint ($npt, \@dd, \@aden1, 2);
#pgtext ($dd[0], 41, "ACE SWEPAM");
pgsci(2);
pgpoint ($npt, \@dd, \@mden0, 1);
pgpoint ($npt, \@dd, \@mden1, 2);
#pgtext ($dd[0]+3, 41, "SOHO MTOF");

pgsci(1);
pgpage;
pgsvp(0.05,0.95,0.2,0.95);
pgswin($dd[0], $dd[-1], -40, 40);
pgbox('BCTSN',0.0,0,'BCTN',0.0,0);
#pgenv ($dd[0], $dd[-1], -40, 40, 0, 0);
pglab ("Day of Year", "p/cc", "");
pgtext ($dd[0]+7, 42, "Solar Wind Proton Density Uncertainty  (Predicted - Measured)");
#pgtext ($dd[-1]-5, 42, ". 0th order, + 1st order");
pgsci(3);
pgpoint ($npt, \@dd, \@adenu0, 1);
pgpoint ($npt, \@dd, \@adenu1, 2);
pgtext ($dd[0], 42, $adens);
pgsci(2);
pgpoint ($npt, \@dd, \@mdenu0, 1);
pgpoint ($npt, \@dd, \@mdenu1, 2);
pgtext ($dd[0]+2, 42, $mdens);

pgend;
