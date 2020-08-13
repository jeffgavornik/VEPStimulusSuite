% Script that drives black-white screen flips with a TTL signal
% Used with an oscilliscope and light meter to test screen change times
% relative to TTL event strobe

flipFreq = 1; % Hz

phio = plxHWInterfaceClass.returnInterface;
sio = screenInterfaceClass.returnInterface;
sio.openScreen;
windowPtr = sio.getWindow;

white = WhiteIndex(windowPtr);
black = BlackIndex(windowPtr);
tDelta = 1/flipFreq - Screen(windowPtr,'GetFlipInterval')/2;
flipFlop = true;
WaitSecs(0.5);
vbl = Screen('Flip', windowPtr);

% offset = 15*1e-3;
offset = 0;

while true 
    if KbCheck()
        break;
    end
    if flipFlop
        Screen('FillRect', windowPtr, white);
    else
        Screen('FillRect', windowPtr, black);
    end
    vbl = Screen('Flip',windowPtr,vbl+tDelta);
    WaitSecs(offset)
    phio.strobeEventWord(flipFlop);
    flipFlop = ~flipFlop;
end
Screen('FillRect', windowPtr, 127)
Screen('Flip', windowPtr);
phio.setEventWord(0);