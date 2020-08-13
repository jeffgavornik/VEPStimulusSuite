
#include "mex.h"
#include "mccDevice.h"
#include "usb1208FSPlusInterface.h"
#include <math.h>

// 64 bit version

/*   mex function wrapper to set a bit value on the specified channel of
     the specified device */

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    
    if ( nrhs != 3 ) mexErrMsgTxt("usb1208FSPlusSetAnalog: 3 inputs required");
    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
    unsigned long thePointer = (unsigned long)mxGetScalar(prhs[0]);
    int theChannel =  (unsigned long)mxGetScalar(prhs[1]);
    int theValue =  (unsigned long)floor(mxGetScalar(prhs[2])*MAXAOVALUE);
    if (thePointer == 0){
        mexErrMsgTxt("usb1208FSPlusSetEvent: invalid interface");
    }
#ifdef DEBUG
    mexPrintf("usb1208FSPlusSetAnalog thePointer = 0x%x\n",thePointer);
#endif
    MCCDevice *usb = (MCCDevice *)thePointer;
    char msgBuffer[256];
    unsigned int rtrnValue = 1;
    try
    {
        sprintf(msgBuffer,"AO{%i}:VALUE=%i",theChannel,theValue);
        //mexPrintf("%s\n",msgBuffer);
        usb->sendMessage(msgBuffer);
        //usb->sendAsynchMessage(msgBuffer);
    }
    catch(mcc_err err)
    {
        rtrnValue = err;
        mexPrintf("AO set value error: %s\n",errorString(err).c_str());
    }
    *mxGetPr(plhs[0]) = rtrnValue;
    
}   