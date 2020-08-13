function [grating,phase_reverse] = make_PR_gratings(sf,con,screenNumber)
% Function to make static phase reversed gratings at a passed spatial
% frequency using parameters specified by the monitor profile
% Always returns a horizontal grating large enough to be rotated to any
% angle on the current monitor
%
% v2. modified from original function to get information dynamically from
% the screenInterfaceClass

% Define some default Values
if nargin == 0
    sf = 0.05; % cycles/deg
end
if nargin < 1
    con = 100;
end

% Get dimensions from the monitor profile
sio = screenInterfaceClass.returnInterface;
mp = sio.getMonitorProfile;
mH = mp.screen_height;
md = mp.viewing_distance;
% Get the monitor resolution
if nargin < 3
    screenNumber = mp.number;
end
resolution = sio.getScreenResolution(screenNumber);
cols = resolution.width;
rows = resolution.height;

% Spatial Period, in meters, is Pm = md*C/sf
% The number of cycles on the screen is MonitorHeight/Pm
C = 0.017455064928218; % tan of 1 degree, approx 1 deg in radians
nCycles = mH*sf/(md*C);

% Make grating large enough to rotate without clipping on the monitor
nPix = ceil(sqrt(cols^2+rows^2)); % minimal size required to rotate without clipping
fp = nCycles*nPix/rows; % spacial frequency in pixels
phase_shift = mod(fp*pi,pi); % phase shift to center zero crossing on screen

% Create the gratings
pixelvec = fp*linspace(0,2*pi,nPix) - phase_shift;
grating = sio.gray*(1+(con/100)*repmat(sin(pixelvec)',1,nPix));
phase_reverse = sio.gray*(1+(con/100)*repmat(sin(pixelvec+pi)',1,nPix));



