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
    if ( nrhs != 2 ) mexErrMsgTxt("usb1208FSPlusSendMessage: 2 inputs required");
    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
    unsigned long thePointer = (unsigned long)mxGetScalar(prhs[0]);
    if (thePointer == 0){
        mexErrMsgTxt("usb1208FSPlusSendMessage: invalid interface");
    }
    #ifdef DEBUG
    mexPrintf("usb1208FSPlusSendMessage thePointer = 0x%x\n",thePointer);
    #endif
    MCCDevice *usb = (MCCDevice *)thePointer;
    char msgBuffer[256];
    unsigned int rtrnValue = 1;
    char *theMessage = mxArrayToString(prhs[1]);
    if(theMessage == NULL)
      mexErrMsgIdAndTxt( "MATLAB:revord:conversionFailed",
              "Could not convert input to string.");
    string response;
    int offset = 0;
    try
    {
        #ifdef DEBUG
        mexPrintf("%s\n",theMessage);
        #endif
        response = usb->sendMessage(theMessage);
        #ifdef DEBUG
        mexPrintf("Response: %s\n",response.c_str());
        #endif
    }
    catch(mcc_err err)
    {
        rtrnValue = err;
        response = errorString(err);
        mexPrintf("sendMessage error: %s\n",response.c_str());
        offset = 1;
    }
    *mxGetPr(plhs[0]) = rtrnValue;
    // Pass the return value back as a char array
    if (nlhs > 1) {
        char *output_buf;
        output_buf = (char *)mxCalloc(256,sizeof(char));
        memcpy(output_buf,response.c_str(),response.size()-offset);
        plhs[1] = mxCreateString(output_buf);
    }
    
}