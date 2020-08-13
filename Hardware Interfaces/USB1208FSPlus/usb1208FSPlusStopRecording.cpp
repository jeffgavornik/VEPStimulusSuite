#include "mex.h"
#include "mccDevice.h"
#include "usb1208FSPlusInterface.h"

// 64 bit version

/*   mex function wrapper to set a bit value on the specified channel of
 * the specified device */

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if ( nrhs != 1 ) mexErrMsgTxt("usb1208FSPlusStopRecording: 1 inputs required");
    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
    unsigned long thePointer = (unsigned long)mxGetScalar(prhs[0]);
    if (thePointer == 0){
        mexErrMsgTxt("usb1208FSPlusStopRecording: invalid interface");
    }
    #ifdef DEBUG
    mexPrintf("usb1208FSPlusStopRecording thePointer = 0x%x\n",thePointer);
    #endif
    MCCDevice *usb = (MCCDevice *)thePointer;
    char msgBuffer[256];
    sprintf(msgBuffer,"DIO{%i/%i}:VALUE=0",CTRLDIO,STARTBIT);
    #ifdef DEBUG
    mexPrintf("theMsg = %s\n",msgBuffer);
    #endif
    usb->sendMessage(msgBuffer);
    sprintf(msgBuffer,"DIO{%i/%i}:VALUE=1",CTRLDIO,STOPBIT);
    #ifdef DEBUG
    mexPrintf("theMsg = %s\n",msgBuffer);
    #endif
    usb->sendMessage(msgBuffer);
    *mxGetPr(plhs[0]) = 1; // return success 
}
