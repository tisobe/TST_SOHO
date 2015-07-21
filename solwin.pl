#! /usr/bin/perl -w

$wd = '/data/mta4/proj/rac/ops/SOHO';

#`rm $wd/PE.EPH.dat; $wd/lephem.pl < $wd/PE.EPH > $wd/PE.EPH.dat; $wd/cocochan`;

system("$wd/get_sw.pl"); 
system("$wd/plot_sw2.pl");
