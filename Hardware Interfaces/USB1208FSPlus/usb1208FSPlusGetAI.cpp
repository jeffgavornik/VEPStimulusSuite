#include "mex.h"
#include "mccDevice.h"
#include "usb1208FSPlusInterface.h"
#include <string.h>

#define DEVICE USB_1208FS_Plus

//#define DEBUG

// 64 bit version

/*
 * return raw value from specified AI port
 * [statusFlag,value,RtrnStr] = usb1208FSPlusGetAI(dio,channel)
 */

 float scaleAndCalibrateData(unsigned short data);

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

    // Process inputs
    if ( nrhs != 2 ) mexErrMsgTxt("usb1208FSPlusGetAI: 2 inputs required");
    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
    unsigned long thePointer = (unsigned long)mxGetScalar(prhs[0]);
    if (thePointer == 0){
        mexErrMsgTxt("usb1208FSPlusGetAI: invalid interface");
    }
    MCCDevice *usb = (MCCDevice *)thePointer;
    //usb->getScanParams();
    int theChannel =  (unsigned long)mxGetScalar(prhs[1]);
    
    // Setup outputs
    if (nlhs < 1) mexErrMsgTxt("usb1208FSPlusGetAI: 1 output is required");
    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
    plhs[1] = mxCreateDoubleMatrix(1,1,mxREAL);
    double *successFlag, *readValue;
    successFlag = mxGetPr(plhs[0]);
    readValue = mxGetPr(plhs[1]);
    
    // Get the value of the selected channel and extract numerical value
    // from the string
    string responseStr;
    char msgBuffer[256];
    *successFlag = 1;
    int offset = 0;
    try
    {
        sprintf(msgBuffer,"?AI{%i}:VALUE",theChannel);
#ifdef DEBUG
        mexPrintf("Command Message: %s\n",msgBuffer);
#endif
        responseStr = usb->sendMessage(msgBuffer);
#ifdef DEBUG
        mexPrintf("Response: %s\n",responseStr.c_str());
#endif
    }
    catch(mcc_err err)
    {
        *successFlag = err;
        responseStr = errorString(err);
        mexPrintf("USB1208FSPlusGetAI error: %s\n",responseStr.c_str());
        *readValue = 0;
        offset = 1;
    }

    int retChannel;
    //unsigned int retValue;
    sscanf(responseStr.c_str(),"AI{%d}:VALUE=%lf",&retChannel,readValue);
    //*readValue = (double)retValue;
#ifdef DEBUG
    mexPrintf("Return Channel = %i, Return Value = %f\n",retChannel,*readValue);
    //mexPrintf("Converted value = %f\n",scaleAndCalibrateData((unsigned short)retValue));
#endif
    
    // Return the actual response string if an output variable is defined
    if (nlhs > 2) {
        char *output_buf;
        output_buf = (char *)mxCalloc(256,sizeof(char));
        memcpy(output_buf,responseStr.c_str(),responseStr.size()-offset);
        plhs[2] = mxCreateString(output_buf);
    }
}

float scaleAndCalibrateData(unsigned short data){
    float calibratedData;
    float scaledAndCalibratedData;
    float offset = -54.8991508;
    float slope = 1.02434599;
    unsigned short mMaxCounts = 0xFFFF;
    int fullScale = 10 - -10;
    calibratedData = (float)data*slope+ offset;  // Gain and offset
    scaledAndCalibratedData = (calibratedData/(4095+1))*fullScale + -10;  // Scale by A2D range
    mexPrintf("dataAsFloat = %f,calibratedData = %f, maxCounts = %u, scaledAndCalibratedData = %f\n",float(data),calibratedData,mMaxCounts,scaledAndCalibratedData);    
    return scaledAndCalibratedData;
}
