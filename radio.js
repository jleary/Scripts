/*
Name:         radio.js
Written By:   [John Leary](git@jleary.cc)
Date Created: Aug 11, 2018
Version:      Feb 09, 2019
Purpose:      Sets audio tag source to the url of a pressed link
Todo: Use XHTTP Request to download and parse m3u8 and pls files
*/

function init(){
    var links = document.getElementById('content').querySelectorAll('a.stream'),i;
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
    //EndsWith Polyfill
    if(!String.prototype.endsWith){
        String.prototype.endsWith = function(endswith){
            if(this.indexOf(endswith)==(endswith.length - this.length)){
                return 1;
            }else{
                return 0;
            }
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
        var content_type = '';
        r.pause();
        if(link.getAttribute('data-type')){
            content_type = "content-type='"+link.getAttribute('data-type')+"'";
        }
        r.innerHTML="<source src='"+link.href+"' "+content_type+" crossorigin='anonymous'></source>";
        t.innerHTML="Now Playing: "
        if(link.getAttribute('data-title')){
            t.innerHTML   += link.getAttribute('data-title');
            document.title = 'JLeary: ' + link.getAttribute('data-title');
        }else{
            t.innerHTML   += link.innerHTML;
            document.title = 'JLeary: ' + link.innerHTML;
        }
        r.setAttribute('controls','');
        r.load();
        r.play();
    }else{
        //Have the browser deal with m3u8 or pls files
        window.location.href=link.href;
    }
}
//window.onload=init;
window.addEventListener("load",init);
