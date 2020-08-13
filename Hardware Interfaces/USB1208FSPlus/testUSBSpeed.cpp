#include "mex.h"
#include "libusb.h"
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
    
    MCCDevice * mcc = (MCCDevice *)thePointer;
    libusb_device *usb;
    usb = mcc->getDevice();
    
//     struct libusb_device_descriptor desc;
//     libusb_get_device_descriptor(usb,&desc);
//
//     mexPrintf("Manufacturer:%s\n",&desc+desc.iManufacturer);
    
    int speed = libusb_get_device_speed(usb);
    std::string speedType = "Invalid return value";
    switch (speed) {
        case LIBUSB_SPEED_UNKNOWN:
            speedType.assign("Unknown");
            break;
        case LIBUSB_SPEED_LOW:
            speedType.assign("Low (1.5MBit/sec)");
            break;
        case LIBUSB_SPEED_FULL:
            speedType.assign("Full (12MBit/sec)");
            break;
        case LIBUSB_SPEED_HIGH:
            speedType.assign("High (480MBit/sec)");
            break;
        case LIBUSB_SPEED_SUPER:
            speedType.assign("Super (5000MBit/sec)");
            break;
        default:
            break;
    }
    
    mexPrintf("Speed: %s\n",speedType.c_str());
    
    
//     static char msgBuffer[256];
//     bool value = true;
//     for (int ii=0;ii<6;ii++){
//         sprintf(msgBuffer,"DIO{%i}:VALUE=%i",EVNTDIO,value);
//
// //         if (value)
// //             sprintf(msgBuffer,"AO{%i}:VALUE=%i",0,2000);
// //         else
// //             sprintf(msgBuffer,"AO{%i}:VALUE=%i",0,0);
//
//         usb->sendAsynchMessage(msgBuffer);
//         //usb->sendMessage(msgBuffer);
//         sleep(1);
//         value = !value;
//     }
//
//     *mxGetPr(plhs[0]) = (unsigned long)0; // return success
    
}


