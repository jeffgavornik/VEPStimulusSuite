#include "mex.h"
#include "mccDevice.h"
#include "usb1208FSPlusInterface.h"
#include <ctime>

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    
    if ( nrhs != 1 ) mexErrMsgTxt("testAsync: 1 inputs required");
    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
    
    unsigned long thePointer = (unsigned long)mxGetScalar(prhs[0]);
    
    if (thePointer == 0){
        mexErrMsgTxt("testAsync: invalid interface");
    }
    
    MCCDevice * usb = (MCCDevice *)thePointer;
    
    static char msgBuffer[256];
    bool value = true;
    for (int ii=0;ii<6;ii++){
        sprintf(msgBuffer,"DIO{%i}:VALUE=%i",EVNTDIO,value);
        
//         if (value)
//             sprintf(msgBuffer,"AO{%i}:VALUE=%i",0,2000);
//         else
//             sprintf(msgBuffer,"AO{%i}:VALUE=%i",0,0);
        
        usb->sendAsynchMessage(msgBuffer);
        //usb->sendMessage(msgBuffer);
        system("sleep(1)");
        value = !value;
    }
    
    *mxGetPr(plhs[0]) = (unsigned long)0; // return success
    
}


