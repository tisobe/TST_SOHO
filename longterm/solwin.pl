#! /usr/bin/perl -w

$wd = '/proj/rac/ops/SOHO';
`rm $wd/PE.EPH.dat; $wd/lephem.pl < $wd/PE.EPH > $wd/PE.EPH.dat; $wd/cocochan`;
`$wd/get_sw.pl; $wd/plot_sw.pl`;
