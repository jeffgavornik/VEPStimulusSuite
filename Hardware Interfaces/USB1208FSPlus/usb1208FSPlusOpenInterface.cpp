#include "mex.h"
#include "mccDevice.h"
#include "usb1208FSPlusInterface.h"

#define DEVICE USB_1208FS_Plus

//#define DEBUG

// 64 bit version

/*
 * mex function wrapper to open and return a pointer to a USB-1208FS-Plus device
 * pointer is returned as an unsigned long integer
 * returns zero if USB errors occur
 */

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if ( nlhs != 1 ) mexErrMsgTxt("usb1208FSPlusOpenInterface: one output required");
    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(plhs[0]) = 0; // return failure if anything goes wrong
    
    // Instantiate an mccDevice object and configure for digital output
    MCCDevice *usb;
    try
    {
#ifdef DEBUG
        mexPrintf("usb = 0x%x\n",(unsigned long)usb);
#endif
        usb = new MCCDevice(DEVICE);
#ifdef DEBUG
        mexPrintf("usb = 0x%x\n",(unsigned long)usb);
        mexPrintf("Device = 0x%x\n",(unsigned long)usb->getDevice());
        string response;
        response = usb->sendMessage("DEV:RESET/DEFAULT");
        mexPrintf("%s\n",response.c_str());
        response = usb->sendMessage("DIO{0}:DIR=OUT");
        mexPrintf("%s\n",response.c_str());
        response = usb->sendMessage("DIO{1}:DIR=OUT");
        mexPrintf("%s\n",response.c_str());
        response = usb->sendMessage("DIO{0}:VALUE=0");
        mexPrintf("%s\n",response.c_str());
        response = usb->sendMessage("DIO{1}:VALUE=0");
        mexPrintf("%s\n",response.c_str());
        response = usb->sendMessage("AO{0}:VALUE=0");
        mexPrintf("%s\n",response.c_str());
        usb->sendMessage("AO{1}:VALUE=0");
#else
        usb->sendMessage("DEV:RESET/DEFAULT");
        usb->sendMessage("DIO{0}:DIR=OUT");
        usb->sendMessage("DIO{1}:DIR=OUT");
        usb->sendMessage("DIO{0}:VALUE=0");
        usb->sendMessage("DIO{1}:VALUE=0");
        usb->sendMessage("AO{0}:VALUE=0");
        usb->sendMessage("AO{1}:VALUE=0");
#endif
    }
    catch(mcc_err err)
    {
        usb = 0;
        mexPrintf("USB Device Error: %s",errorString(err).c_str());
    }
    
    // Return the address of the open device as an unsigned integer
    unsigned long thePointer;
    thePointer = (unsigned long)usb;
    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(plhs[0]) = thePointer;
#ifdef DEBUG
    mexPrintf("usb1208FSPlusOpenInterface thePointer = 0x%x\n",thePointer);
#endif
}
