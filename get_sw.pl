#! /usr/bin/perl -w

# Fetch the monthly ACE SWEPAM and SOHO MTOF files

# Robert Cameron
# May 2003

$lynx = "/usr/bin/lynx";

$odir = "/data/mta4/proj/rac/ops/SOHO";

# get ACE SWEPAM files

print "Fetching monthly ACE SWEPAM files:\n";
$site = "ftp://ftp.swpc.noaa.gov/pub/lists/ace2/";
$l = `$lynx -crawl -dump $site`;
@l = split / /,$l;
@f = grep /_ace_swepam_1h.txt/, @l;
open (OF, ">$odir/swepam") or die "Cannot open output file $odir/swepam\n";
foreach ((sort(@f))[-4..-1]) {
    $f = `$lynx -source $site/$_`;
    open (OFF, ">$odir/longterm/$_") or die "Cannot open output file $odir/longterm/$_\n";
    print OFF $f;
    print OF $f;
    print "   $_\n";
}

# get SOHO MTOF files

print "Fetching SOHO MTOF files:\n";
$site = "http://umtof.umd.edu/pm/crn/archive/";
$l = `$lynx -crawl -dump $site`;
@l = split "\n",$l;
@f = map { (/(CRN_\S+\.USED)/) ? $1 : () } @l; 
open (OF, ">$odir/mtof") or die "Cannot open output file $odir/mtof\n";
foreach ((sort(@f))[-6..-1]) {
    $f = `$lynx -source $site/$_`;
    open (OFF, ">$odir/longterm/$_") or die "Cannot open output file $odir/longterm/$_\n";
    print OFF $f;
    print OF $f;
    print "   $_\n";
}
$f = `$lynx -source http://umtof.umd.edu/pm/pmsw_2week.used`;
print OF $f;
print "   pmsw_2week.used\n";
