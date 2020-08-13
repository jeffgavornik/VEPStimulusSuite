function TurnOptoStimLaserOff
% Generic wrapper that makes it easy to turn optogenetic stimulus off
optoInt = optoStimHWInterfaceClass.getInterface;
optoInt.turnLightOff;
