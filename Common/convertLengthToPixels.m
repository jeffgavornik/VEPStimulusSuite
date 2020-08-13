function nPix = convertLengthToPixels(length,XorY,units)
% Convert length (measured in cm, inches, or degrees) to pixels in either
% the x or y direction.  Uses monitor resolution and screen size, reported
% by the screenInterfaceClass, to perform the conversion.

sio = screenInterfaceClass.returnInterface;
res = sio.getScreenResolution;
mp = sio.getMonitorProfile;

switch lower(XorY)
    case 'x'
        pixCount = res.width;
        screenSize = mp.screen_width*100;
    case 'y'
        pixCount = res.height;
        screenSize = mp.screen_height*100;
    otherwise
        error('convertCMToPixel: XorY must be either ''x'' or ''y''');
end

if nargin < 3
    units = 'cm';
end

switch lower(units)
    case {'cm' 'centimeter' 'centimeters'}
        conversionFactor = pixCount / screenSize;
    case {'in' 'inch' 'inches'}
        conversionFactor = 2.54 * pixCount / screenSize;
    case 'degrees'
        error('not yet for degrees')
    otherwise
        error('convertCMToPixel: units can be cm, inch, or degrees');
end

nPix = floor(length*conversionFactor);