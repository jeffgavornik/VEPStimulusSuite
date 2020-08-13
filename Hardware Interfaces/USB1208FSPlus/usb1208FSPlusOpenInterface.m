%   devID = plxDaqOpenInterface()
%
%   Returns a pointer to a comedi device structure opend using the 
%   parameters from plxDaqInterface.h.  Checks to make sure that the
%   specified subdevice is type DIO and sets all channels for output.
%   devID is set to 0 if anything goes wrong.
%
%   Function implemented as mex wrapper in plxDaqOpenInterface.cpp
%
%   J. Gavornik September 2013