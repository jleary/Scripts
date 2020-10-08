#!/usr/bin/perl -w 
use warnings;
use strict;
use Config::Tiny;

# Written by:   [John Leary](git@jleary.cc)
# Date Created: 02 Jul 2020
# Dependencies: perl, Config::Tiny
# Deb Packages: perl, libconfig-tiny-perl, clamav

#Takes an file called ~/zoom_updater.cfg
#with the contents: md5=something
#Updates zoom if the above md5 hash does not match the hash of the downlaoded deb file
#Updates the ~/.zoom_updater.cfg file with the proper hash

#Create the config file if it doesn't exist
`touch "$ENV{HOME}/.zoom_updater.cfg"`;

#Read in the config file and find the md5 key
my $cfg = Config::Tiny->new;
$cfg = Config::Tiny->read($ENV{HOME}.'/.zoom_updater.cfg');
my $md5_current = ($cfg->{_}->{md5} or '');

#Download the latest dpkg for Zoom and get its md5 hash.
print `wget https://zoom.us/client/latest/zoom_amd64.deb -O /tmp/zoom_amd64.deb`;
print `clamscan --remove /tmp/zoom_amd64.deb` if -e '/tmp/zoom_amd64.deb';
print "\n";
if(-e '/tmp/zoom_amd64.deb'){
    my $md5_new = `md5sum /tmp/zoom_amd64.deb`; 
    $md5_new = (split /\s/, $md5_new)[0];

    #Upgrade Zoom if the hashes don't match.
    if($md5_current ne $md5_new){
        print "Updating Zoom\n";
        print `sudo dpkg -i /tmp/zoom_amd64.deb`;
        $cfg->{_}->{md5}=$md5_new;
        $cfg->write($ENV{HOME}.'/.zoom_updater.cfg');
    }else{
        print "No Zoom Updates Availible\n";
    }
}else{
    print "Zoom dpkg file not found.\n";
}
