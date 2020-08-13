#include <ctime>
#include "mccDevice.h"
#include "usb1208FSPlusInterface.h"

#ifndef THREADRETURNS_H
#define THREADRETURNS_H

#ifdef __cplusplus
extern "C" {
#endif
        
    // Define a class that will be used to store info about laser pulses
    // performed within a thread
    class threadedPulseInfoClass
    {
    public:
        int onCount, offCount;
        double onTime,offTime;
        bool threadComplete;
        threadedPulseInfoClass();
    };
    
    // Structure that is used to pass arguments to threaded pulse functions
    struct pulseWidthModArgStruct {
        MCCDevice *usb;
        double pulseWidth;
        int nPulses;
        threadedPulseInfoClass *threadInfo;
    };
    
    // Function used to calculate the time between two times
    timespec diff(timespec start, timespec end);
    
#ifdef __cplusplus
}
#endif

#endif /* THREADRETURNS_H */