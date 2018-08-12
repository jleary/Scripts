/*
Name:         radio.js
Written By:   [John Leary](git@jleary.cc)
Date Created: Aug 11, 2018
Version:      Aug 12, 2018
Purpose:      Sets audio tag source to the url of a pressed link
Todo: Use XHTTP Request to download and parse m3u8 and pls files
*/

function init(){
    var links = document.getElementById('content').querySelectorAll('a'),i;
    //Add Event Listener for play function
    for(i = 0; i < links.length; ++i){
        links[i].addEventListener('click',function(event){play(this,event);},false);
    }
    //Play Link with #ID
    if(window.location.hash){
        if(document.getElementById('content').querySelector(window.location.hash)){
            play(document.getElementById('content').querySelector(window.location.hash),null);    
        }
    }
}
function play(link,event){
    if(event){
        event.preventDefault();
    }
    if(link.href.endsWith('.m3u8') == false && link.href.endsWith('.pls') == false){
        var r = document.getElementById('radio_player');
        var t = document.getElementById('radio_ticker');
        r.pause();
        r.innerHTML="<source src='"+link.href+"'></source>";
        t.innerHTML="Now Playing: "
        if(link.getAttribute('data-title')){
            t.innerHTML += link.getAttribute('data-title');
        }else{
            t.innerHTML += link.innerHTML;
        }
        r.setAttribute('controls','');
        r.load();
        r.play();
    }else{
        //Have the browser deal with m3u8 or pls files
        window.location.href=link.href;
    }
}
window.onload=init;

