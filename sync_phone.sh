#!/bin/bash
# Written by:   [John Leary](git@jleary.cc)
# Date Created: 09 Dec 2018

if [[ -d /media/$USER/7D92-FFBA/Music ]]
then
     mkdir /tmp/export
     ~/Git/tunes_pls/tunes_pls.pl --action conf --conf ~/.config/tunes_pls.cfg
     rsync  -rvl --size-only --inplace --progress /tmp/export/ /media/$USER/7D92-FFBA/Music 
     #Copy Back Phone Pictures
     #rsync  -rvl --size-only --inplace --progress /media/$USER/7D92-FFBA/DCIM/Camera/ /home/$USER/Pictures/Phone 
     sync
else
    echo "Please insert the sd card and re run"
fi
