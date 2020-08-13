#include "mex.h"
#include "mccDevice.h"
#include "usb1208FSPlusInterface.h"
#include <ctime>

#include <errno.h>

#define USETHREADS

// 64 bit version

struct pulseWidthModArgStruct {
    MCCDevice *usb;
    double pulseWidth;
    int nPulses;
};

timespec diff(timespec start, timespec end);
void * pulseWidthModThreadFnc(void *arguments);
static void cleanup_handler(void *arguments);

static void cleanup_handler(void *arguments)
{
    struct pulseWidthModArgStruct *args =
            (struct pulseWidthModArgStruct *)arguments;
    
    mexPrintf("cleanup_handler: usb = 0x%x, pulseWidth = %1.4f, nPulses = %i\n",
            args->usb,args->pulseWidth,args->nPulses);
    
    char msgBuffer[256];
    // sprintf(msgBuffer,"DIO{%i}:VALUE=%i",EVNTDIO,0);
    sprintf(msgBuffer,"DIO{0/3}:VALUE=%i",0);
    args->usb->sendMessage(msgBuffer);
}

void * pulseWidthModThreadFnc(void *arguments)
{
    struct pulseWidthModArgStruct *args =
            (struct pulseWidthModArgStruct *)arguments;
#ifdef USETHREADS
    pthread_cleanup_push(cleanup_handler,arguments);
#endif
    
//     mexPrintf("inThread: usb = 0x%x, pulseWidth = %1.4f, nPulses = %i\n",
//             args->usb,args->pulseWidth,args->nPulses);
    
    //static clock_t startTime;
    static char msgBuffer[256];
    
    bool laserOn = true;
    //int iterations = CLOCKS_PER_SEC * args->pulseWidth;
    
//     mexPrintf("iterations = %i, CLOCKS_PER_SEC = %i\n",
//             iterations,CLOCKS_PER_SEC);
    
    timespec startTime, currentTime, firstStart;
    
    int nP;
    unsigned long long int nsWait; // = (unsigned long long int)(args->pulseWidth*1e9);
    unsigned long int secWait = args->pulseWidth;
    nsWait = (args->pulseWidth - secWait)*1000000000UL;
    
//     mexPrintf("sizeof(long) = %i\n",sizeof(nsWait));
//     mexPrintf("sizeof(timespec.tv_nsec) = %i\n",sizeof(startTime.tv_nsec));
    mexPrintf("nsWait = %u\n",nsWait);
    mexPrintf("secWait = %u\n",secWait);
    
    time_t rawTime;
    
    for (nP = 0; nP < 2*args->nPulses-1; nP++ ){
#ifdef USETHREADS
        pthread_testcancel();
#endif
        // Send laser state command
        //sprintf(msgBuffer,"DIO{%i}:VALUE=%i",EVNTDIO,laserOn);
        sprintf(msgBuffer,"DIO{0/3}:VALUE=%i",(int)laserOn);
        //args->usb->sendMessage(msgBuffer);
        args->usb->sendAsynchMessage(msgBuffer);
        //startTime = clock();
        
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
        while (diff(startTime,currentTime).tv_nsec < nsWait)
            clock_gettime(CLOCK_MONOTONIC, &currentTime);
        
//         timespec wt = diff(firstStart,currentTime);
//         mexPrintf("%i nsDiff = %u.%0.9u\n",nP,wt.tv_sec,wt.tv_nsec);
        
        laserOn = !laserOn;
        //time(&rawTime);
//         mexPrintf("%i:%s @ %s",nP,msgBuffer,ctime(&rawTime));
        //mexPrintf("%i:%s\n",nP,msgBuffer);
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

timespec diff(timespec start, timespec end)
{
    timespec temp;
    if ((end.tv_nsec-start.tv_nsec)<0) {
        temp.tv_sec = end.tv_sec-start.tv_sec-1;
        temp.tv_nsec = 1e9+end.tv_nsec-start.tv_nsec;
//         temp.tv_nsec = end.tv_nsec-start.tv_nsec;
    } else {
        temp.tv_sec = end.tv_sec-start.tv_sec;
        temp.tv_nsec = end.tv_nsec-start.tv_nsec;
    }
    return temp;
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    
    if ( nrhs != 3 ) mexErrMsgTxt("threadtest: 3 inputs required");
    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
    
    unsigned long thePointer = (unsigned long)mxGetScalar(prhs[0]);
    double pulseWidth =  (double)mxGetScalar(prhs[1]);
    int nPulses =  (unsigned long)mxGetScalar(prhs[2]);
    
    if (thePointer == 0){
        mexErrMsgTxt("threadtest: invalid interface");
    }
#ifdef DEBUG
    mexPrintf("threadtest thePointer = 0x%x\n",thePointer);
#endif
    
    static struct pulseWidthModArgStruct args;
    args.usb = (MCCDevice *)thePointer;
    args.pulseWidth = pulseWidth;
    args.nPulses = nPulses;
    
//     mexPrintf("thePointer = 0x%x, pulseWidth = %1.4f, nPulses = %i\n",
//             args.usb,args.pulseWidth,args.nPulses);
        
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
        
    *mxGetPr(plhs[0]) = (unsigned long)pulse_thread; // return success
    
}


