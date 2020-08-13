#include "mex.h"
#include "mccDevice.h"
#include "usb1208FSPlusInterface.h"
#include <math.h>
#include <string.h>

// 64 bit version

//#define DEBUG

/*   Send a string message to the mccDevice */

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    char *input_buf;
    if ( nrhs != 1 ) mexErrMsgTxt("usb1208FSPlusFlush: 1 inputs required");
    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
    int returnValue = 1;
    unsigned long thePointer = (unsigned long)mxGetScalar(prhs[0]);
    if (thePointer == 0){
        mexErrMsgTxt("usb1208FSPlusSendMessage: invalid interface");
    }
    #ifdef DEBUG
    mexPrintf("usb1208FSPlusSendMessage thePointer = 0x%x\n",thePointer);
    #endif
    MCCDevice *usb = (MCCDevice *)thePointer;
    unsigned int rtrnValue = 1;
    string response;
    int offset = 0;
    try
    {
        usb->flushInputData();
    }
    catch(mcc_err err)
    {
        rtrnValue = err;
        response = errorString(err);
        mexPrintf("sendMessage error: %s\n",response.c_str());
        offset = 1;
        returnValue = 0;
    }
    *mxGetPr(plhs[0]) = returnValue;
    
}