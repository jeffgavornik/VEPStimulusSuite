
clear

sio = screenInterfaceClass.returnInterface;

sio.openScreen;
sio.setHighPriority;

iters = 100;
deltas = zeros(1,iters);
holdTime = 0.150;
lastFlip = Screen(sio.window,'Flip');
for ii = 1:iters
    vbl = Screen(sio.window,'Flip',lastFlip + holdTime - sio.slack);
    deltas(ii) = vbl-lastFlip;
    lastFlip = vbl;
end

sio.setLowPriority;
sio.closeScreen;

fprintf('mean delta = %f\n',mean(deltas));

