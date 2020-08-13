#include "mex.h"
#include "mccDevice.h"
#include "usb1208FSPlusInterface.h"
#include "threadReturns.h"

#include <ctime>
#include <errno.h>

#define USETHREADS

// 64 bit version

static void cleanup_handler(void *arguments);
void * pulseWidthModThreadFnc(void *arguments);

void * pulseWidthModThreadFnc(void *arguments)
{
    struct pulseWidthModArgStruct *args =
            (struct pulseWidthModArgStruct *)arguments;
#ifdef USETHREADS
    pthread_cleanup_push(cleanup_handler,arguments);
#endif
    
    static char msgBuffer[256];
    
    bool laserOn = true;
    //int iterations = CLOCKS_PER_SEC * args->pulseWidth;
        
    args->threadInfo->onCount = 0;
    args->threadInfo->offCount = 0;
    args->threadInfo->onTime = 0;
    args->threadInfo->offTime = 0;
    
    timespec startTime, currentTime, firstStart;
    
    unsigned long long int nsWait; // = (unsigned long long int)(args->pulseWidth*1e9);
    unsigned long int secWait = args->pulseWidth;
    nsWait = (args->pulseWidth - secWait)*1000000000UL;
    
    //mexPrintf("pulseCount=%i, targetPulses=%i\n",args->threadInfo->onCount,args->nPulses);
    //mexPrintf("sizeof(long) = %i\n",sizeof(nsWait));
    //mexPrintf("sizeof(timespec.tv_nsec) = %i\n",sizeof(startTime.tv_nsec));
    //mexPrintf("nsWait = %u\n",nsWait);
    //mexPrintf("secWait = %u\n",secWait);
    
    while (true){
#ifdef USETHREADS
        pthread_testcancel();
#endif

        if (args->threadInfo->onCount > args->nPulses && args->nPulses != 0) break;
        
        // Send laser state command
        //sprintf(msgBuffer,"DIO{%i}:VALUE=%i",EVNTDIO,laserOn);
        sprintf(msgBuffer,"DIO{0/3}:VALUE=%i",(int)laserOn);
        //args->usb->sendMessage(msgBuffer);
        args->usb->sendAsynchMessage(msgBuffer);
                
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
#ifdef USETHREADS
            pthread_testcancel();
#endif
            clock_gettime(CLOCK_MONOTONIC, &currentTime);
        }
        
        if (laserOn) {
            args->threadInfo->onCount++;
            args->threadInfo->onTime += args->pulseWidth;
        } else {
            args->threadInfo->offCount++;
            args->threadInfo->offTime += args->pulseWidth;
        }
        laserOn = !laserOn;
    }
    
    //sprintf(msgBuffer,"DIO{%i}:VALUE=%i",EVNTDIO,0);
    //sprintf(msgBuffer,"DIO{0/3}:VALUE=0");
    //args->usb->sendAsynchMessage(msgBuffer);
    
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
    // sprintf(msgBuffer,"DIO{%i}:VALUE=%i",EVNTDIO,0);
    sprintf(msgBuffer,"DIO{0/3}:VALUE=%i",0);
    args->usb->sendMessage(msgBuffer);
    args->usb->flushInputData();
    args->threadInfo->threadComplete = true;
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    
    if ( nrhs != 3 ) mexErrMsgTxt("threadtest: 3 inputs required");
    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL); // pointer to thread
    plhs[1] = mxCreateDoubleMatrix(1,1,mxREAL); // pointer to threadInfo
    
    unsigned long thePointer = (unsigned long)mxGetScalar(prhs[0]);
    double pulseWidth =  (double)mxGetScalar(prhs[1]);
    int nPulses =  (unsigned long)mxGetScalar(prhs[2]);
    
    if (thePointer == 0){
        mexErrMsgTxt("pulseLaserThreaded: invalid interface");
    }

    
    // Create an object that will be used by the thread to store info
    // This pointer will be returned to matlab and destroyed later
    threadedPulseInfoClass *threadInfo = new threadedPulseInfoClass;
    if (threadInfo == NULL) mexErrMsgTxt("pulseLaserPoissonThreaded: new threadInfo failure");
    
    static struct pulseWidthModArgStruct args;
    args.usb = (MCCDevice *)thePointer;
    args.pulseWidth = pulseWidth;
    args.nPulses = nPulses;
    args.threadInfo = threadInfo;
    
#ifdef DEBUG
    mexPrintf("thePointer = 0x%x, pulseWidth = %1.4f, nPulses = %i\n",
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
    
//     sleep(1);
//     int s = pthread_cancel(*pulse_thread);
//     if (s!=0)
//         mexErrMsgTxt("threadtest: pthread_cancel failed");
        
    // return pointers to the thread and to the threadInfo
    *mxGetPr(plhs[0]) = (unsigned long)pulse_thread; // return success
    *mxGetPr(plhs[1]) = (unsigned long)threadInfo;
    
}


