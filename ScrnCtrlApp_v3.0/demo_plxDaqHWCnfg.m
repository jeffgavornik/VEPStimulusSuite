function dioConfigStruct = demo_plxDaqHWCnfg
% Example of a hardware configuration file for the plxDaqInterface
% If this were real, the name of the file should be hostname_plxDaqHWCnfg.m
% where hostname is the name of the computer host (see /etc/hostname on linux or 
% the system control panel in windows)

dioConfigStruct.startStopBit = 6;
dioConfigStruct.eventWord = [0 1 2 3 4 5];
dioConfigStruct.strobeBit = 7;
