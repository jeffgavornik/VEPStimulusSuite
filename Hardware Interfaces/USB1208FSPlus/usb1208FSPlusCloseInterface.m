%   success = usb1208PlusCloseInterface(devID)
%
%   Closes the USB-1208FS-Plus device specified by devID.  
%   Will not attempt to close NULL but might seg fault if 
%   an invalid address is passed.
%
%   Function implemented as mex wrapper in usb1208PlusCloseInterface.cpp
%
%   J. Gavornik 13 September 2013
