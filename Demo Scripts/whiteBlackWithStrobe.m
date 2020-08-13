% Example script that uses the screen interface but not the ScnrCtrlApp to
% toggle between black and white screen and stobe the TTL system while
% doing so

sio = screenInterfaceClass.returnInterface;
sio.openScreen;
win = sio.getWindow;

ttl = ttlInterfaceClass.getTTLInterface;

whiteColor = sio.monProfile.white * [1 1 1];
blackColor = sio.monProfile.black * [1 1 1];

color = 'white';
cmdLuminance = whiteColor;
Screen('FillRect',win,cmdLuminance);
vbl = sio.flipScreen();
strobe(ttl);

for ii = 1:49
    switch lower(color)
        case 'white'            
            Screen('FillRect',win,whiteColor);
            vbl = sio.flipScreen(vbl+0.5-sio.slack);
            strobe(ttl);
            color = 'black';
        case 'black'
            Screen('FillRect',win,blackColor);
            vbl = sio.flipScreen(vbl+0.5-sio.slack);
            strobe(ttl);
            color = 'white';
    end
end