#include "mex.h"
#include "mccDevice.h"
#include "usb1208FSPlusInterface.h"
#include "threadReturns.h"

#include <ctime>
#include <random>

#include <errno.h>

#define USETHREADS

// 64 bit version

void * pulseWidthModThreadFnc(void *arguments);
static void cleanup_handler(void *arguments);

void * pulseWidthModThreadFnc(void *arguments)
{
    struct pulseWidthModArgStruct *args =
            (struct pulseWidthModArgStruct *)arguments;
#ifdef USETHREADS
    pthread_cleanup_push(cleanup_handler,arguments);
#endif
        
    static char msgBuffer[256];
    
    bool laserOn = true;
    
    timespec startTime, currentTime, firstStart;
    
    unsigned long long int nsWait; // = (unsigned long long int)(args->pulseWidth*1e9);
    unsigned long int secWait = args->pulseWidth;
    nsWait = (args->pulseWidth - secWait)*1000000000UL;
    
    // set up to generate random pulse widths, specify lambda in ms (pulseWidth is in sec)
    std::default_random_engine generator;
    //std::poisson_distribution<int> distribution(1e3*args->pulseWidth);
    //std::uniform_real_distribution<double> distribution(0.1,2);
    std::gamma_distribution<double> distribution(1.5,100);
    int poissWaitTime;
    double randWaitTime;
    args->threadInfo->onCount = 0;
    args->threadInfo->offCount = 0;
    args->threadInfo->onTime = 0;
    args->threadInfo->offTime = 0;
    
//     mexPrintf("sizeof(long) = %i\n",sizeof(nsWait));
//     mexPrintf("sizeof(timespec.tv_nsec) = %i\n",sizeof(startTime.tv_nsec));
    
    while (true){
#ifdef USETHREADS
        pthread_testcancel();
#endif
        // Send laser state command
        //sprintf(msgBuffer,"DIO{%i}:VALUE=%i",EVNTDIO,laserOn);
        sprintf(msgBuffer,"DIO{0/3}:VALUE=%i",(int)laserOn);
        //args->usb->sendMessage(msgBuffer);
        args->usb->sendAsynchMessage(msgBuffer);
        //startTime = clock();
        
        // Generate new random wait time that will define current pulse width
        //poissWaitTime = distribution(generator);
        randWaitTime = distribution(generator)*1e-3;
        //while (randWaitTime < 0.01) randWaitTime = distribution(generator);
        while (!laserOn && randWaitTime > 0.250) randWaitTime = distribution(generator);
        secWait = (unsigned long int)randWaitTime;
        nsWait = (randWaitTime-secWait)*1000000000UL;
        
        //if (!laserOn)
        //    mexPrintf("laserOn=%i, randWaitTime = %1.3f,secWait = %u,nsWait = %u\n",!laserOn,randWaitTime,secWait,nsWait);
        
        // Use seconds timer till there is less than a second to go, then
        // use nanoseconds
        clock_gettime(CLOCK_MONOTONIC, &startTime);
        firstStart = startTime;
        currentTime = startTime;
        while (diff(startTime,currentTime).tv_sec-secWait > 0){
#ifdef USETHREADS
            pthread_testcancel();
#endif
            clock_gettime(CLOCK_MONOTONIC, &currentTime);
        }
        clock_gettime(CLOCK_MONOTONIC, &startTime);
        currentTime = startTime;
        while (diff(startTime,currentTime).tv_nsec < nsWait){
            pthread_testcancel();
            clock_gettime(CLOCK_MONOTONIC, &currentTime);
        }
        laserOn = !laserOn;
        if (laserOn) {
            args->threadInfo->onCount++;
            args->threadInfo->onTime += randWaitTime;
        } else {
            args->threadInfo->offCount++;
            args->threadInfo->offTime += randWaitTime;
        }
        //mexPrintf("%i on pulses, average width = %1.3f, %i off pulses, average width = %1.3f\n",
        //        onCount,onTime/onCount,offCount,offTime/offCount);
    }
    
    sprintf(msgBuffer,"DIO{%i}:VALUE=%i",EVNTDIO,0);
//     mexPrintf("%i:%s\n",nP,msgBuffer);
    //args->usb->sendMessage(msgBuffer);
    args->usb->sendAsynchMessage(msgBuffer);
    
#ifdef USETHREADS
    pthread_cleanup_pop(1);
#endif
    
    return NULL;
}

static void cleanup_handler(void *arguments)
{
    struct pulseWidthModArgStruct *args =
            (struct pulseWidthModArgStruct *)arguments;
#ifdef DEBUG
    mexPrintf("cleanup_handler: usb = 0x%x, threadInfo = 0x%x, pulseWidth = %1.4f, nPulses = %i\n",
            args->usb,args->threadInfo,args->pulseWidth,args->nPulses);
    mexPrintf("cleanup_handler: %i on pulses, average width = %1.3f, %i off pulses, average width = %1.3f\n",
            args->threadInfo->onCount,
            args->threadInfo->onTime/args->threadInfo->onCount,
            args->threadInfo->offCount,
            args->threadInfo->offTime/args->threadInfo->offCount);
#endif
    char msgBuffer[256];
    sprintf(msgBuffer,"DIO{0/3}:VALUE=%i",0);
    args->usb->sendMessage(msgBuffer);
    args->threadInfo->threadComplete = true;
}


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    
    if ( nrhs != 3 ) mexErrMsgTxt("threadtest: 3 inputs required");
    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL); // pointer to thread
    plhs[1] = mxCreateDoubleMatrix(1,1,mxREAL); // pointer to threadInfo
    
    unsigned long usbPointer = (unsigned long)mxGetScalar(prhs[0]);
    double pulseWidth =  (double)mxGetScalar(prhs[1]);
    int nPulses =  (unsigned long)mxGetScalar(prhs[2]);
    
    if (usbPointer == 0){
        mexErrMsgTxt("pulseLaserPoissonThreaded: invalid interface");
    }
    
    // Create an object that will be used by the thread to store info
    // This pointer will be returned to matlab and destroyed later
    threadedPulseInfoClass *threadInfo = new threadedPulseInfoClass;
    
    if (threadInfo == NULL) mexErrMsgTxt("pulseLaserPoissonThreaded: new threadInfo failure");
    
#ifdef DEBUG
    mexPrintf("pulseLaserPoissonThreaded usbPointer = 0x%x\n",usbPointer);
    mexPrintf("pulseLaserPoissonThreaded threadInfo = 0x%x\n",threadInfo);
#endif
    
    // Create a structure that will pass arguments to the thread
    static struct pulseWidthModArgStruct args;
    args.usb = (MCCDevice *)usbPointer;
    args.pulseWidth = pulseWidth;
    args.nPulses = nPulses;
    args.threadInfo = threadInfo;
    
#ifdef DEBUG
    mexPrintf("usbPointer = 0x%x, pulseWidth = %1.4f, nPulses = %i\n",
            args.usb,args.pulseWidth,args.nPulses);
#endif
    
#ifdef USETHREADS
    pthread_t *pulse_thread = new pthread_t;
    if (pthread_create(pulse_thread, NULL,
            pulseWidthModThreadFnc,
            (void *)&args) != 0) {
        mexErrMsgTxt("threadtest: pthread_create failed");
        *mxGetPr(plhs[0]) = -1;
    }
#else
    pulseWidthModThreadFnc((void *)&args);
    pthread_t *pulse_thread = 0;
#endif
    
    // return pointers to the thread and to the threadInfo
    *mxGetPr(plhs[0]) = (unsigned long)pulse_thread; // return success
    *mxGetPr(plhs[1]) = (unsigned long)threadInfo;
    
}



