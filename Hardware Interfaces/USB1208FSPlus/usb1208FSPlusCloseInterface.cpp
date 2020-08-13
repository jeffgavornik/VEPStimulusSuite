#include "mex.h"
#include "mccDevice.h"

// 64 bit version

/*   mex function wrapper to close passed USB-1208FS-Plus DAQ */

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if ( nrhs != 1 ) mexErrMsgTxt("usb1208FSPlusCloseInterface: one input required");
    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(plhs[0]) = 0; // return failure if anything goes wrong
    try
    {
        unsigned long thePointer;
        thePointer = (unsigned long)mxGetScalar(prhs[0]);
#ifdef DEBUG
        mexPrintf("usb1208FSPlusCloseInterface thePointer =0x%x\n",thePointer);
#endif
        if (thePointer == 0){
            mexErrMsgTxt("usb1208FSPlusCloseInterface: invalid interface");
        }
        MCCDevice *usb = (MCCDevice *)thePointer;
        try {
            usb->sendMessage("DIO{0}:VALUE=0");
            usb->sendMessage("DIO{1}:VALUE=0");
        } catch (mcc_err err) {
            mexPrintf("USB-1208FS-Plus failed to set all bits to zero"); // %s",errorString(err));
        }
        delete usb;
        *mxGetPr(plhs[0]) = 1; // return success
    }
    catch (mcc_err err)
    {
        mexPrintf("USB Device Error: %s",errorString(err).c_str());
    }
}
