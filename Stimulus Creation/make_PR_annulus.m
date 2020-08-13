function [annulus,annulus_phase_reverse] = ...
    make_PR_annulus(sf,con,screenNumber,phaseShift)

% Define some default Values
if nargin == 0
    sf = 0.05; % cycles/deg
end
if nargin < 1
    con = 100;
end
if nargin < 4
    phaseShift = 0;
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
% nCycles = mH*sf/(md*C);

% Create grid of all pixels on the screen and calculate the radius of each
% pixel from the center of the screen
% [x,y] = meshgrid((0:cols-1)-cols/2,(0:rows-1)-rows/2);
nPix = ceil(sqrt(cols^2+rows^2)); % minimal size required to rotate without clipping
[x,y] = meshgrid((0:nPix-1)-nPix/2,(0:nPix-1)-nPix/2);
r = sqrt(x.^2 + y.^2);
r_max = max(max(r));

% Spatial Period, in meters, is Pm = md*C/sf
% The number of cycles along the diagonal is r_max/Pm
pixelSize = (mH/rows);
nCycles = r_max*pixelSize*sf/(md*C);
%r_hat = nCycles*2*pi*(r./r_max);
fp = nCycles*nPix/rows; % spacial frequency in pixels - correct for expanded xy
r_hat = fp*pi*(r./r_max);
annulus = sio.gray * (1+(con/100)*sin(r_hat+phaseShift));
annulus_phase_reverse = sio.gray * (1+(con/100)*sin(r_hat+pi+phaseShift));
