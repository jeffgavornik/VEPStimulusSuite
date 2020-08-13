#include "mex.h"
#include "mccDevice.h"
#include "usb1208FSPlusInterface.h"
#include <ctime>

#include <errno.h>

#define USETHREADS

// Implement fixed-width strobe on USB1208FSPlus where timing loop is 
// executed in an asynchronous thread with emx function returning immediately
// Right now, there is no checking to make sure the strobe worked or to
// clean up in the event of an error
// Does return a pointer to the thread that could be used to verify
// success, kill the thread, etc.

// 64 bit version

struct strobeArgs {
    MCCDevice *usb;
    double pulseWidth;        
};

timespec diff(timespec start, timespec end);
void * pulseWidthModThreadFnc(void *arguments);
static void cleanup_handler(void *arguments);

static void cleanup_handler(void *arguments)
{
    struct strobeArgs *args =
            (struct strobeArgs *)arguments;
#ifdef DEBUG
    mexPrintf("cleanup_handler: usb = 0x%x, pulseWidth = %1.4f\n",
            args->usb,args->pulseWidth);
#endif
/*    char msgBuffer[256];
    sprintf(msgBuffer,"DIO{%i}:VALUE=%i",EVNTDIO,0);
    args->usb->sendMessage(msgBuffer);
 */
}

void * strobeFunction(void *arguments)
{
    struct strobeArgs *args =
            (struct strobeArgs *)arguments;
#ifdef USETHREADS
    pthread_cleanup_push(cleanup_handler,arguments);
#endif
#ifdef DEBUG
    mexPrintf("inThread: usb = 0x%x, pulseWidth = %1.4f\n",
            args->usb,args->pulseWidth);
#endif
    static char msgBuffer[256];
    timespec startTime, currentTime, firstStart;
    unsigned long long int nsWait;
    unsigned long int secWait = args->pulseWidth;
    nsWait = (args->pulseWidth - secWait)*1000000000UL;
#ifdef DEBUG
    mexPrintf("nsWait = %u\n",nsWait);
    mexPrintf("secWait = %u\n",secWait);
#endif
    time_t rawTime;
#ifdef USETHREADS
    pthread_testcancel();
#endif
    // Send command to set the bit high
    sprintf(msgBuffer,"DIO{%i/%i}:VALUE=1",CTRLDIO,STROBEBIT);
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
    while (diff(startTime,currentTime).tv_nsec < nsWait)
        clock_gettime(CLOCK_MONOTONIC, &currentTime);
    
    // Send command to set the bit low
    sprintf(msgBuffer,"DIO{%i/%i}:VALUE=0",CTRLDIO,STROBEBIT);
    args->usb->sendAsynchMessage(msgBuffer);
    pthread_cleanup_pop(1);
    
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
    
    if ( nrhs != 3 ) mexErrMsgTxt("usb1208FSPlusStrobeAsynch: 3 inputs required (usb device, event value and strobe time)");
    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
    
    unsigned long thePointer = (unsigned long)mxGetScalar(prhs[0]);
    int theValue =  (unsigned long)mxGetScalar(prhs[1]);
    double pulseWidth =  (double)mxGetScalar(prhs[2]);
    
    if (thePointer == 0){
        mexErrMsgTxt("usb1208FSPlusStrobeAsynch: invalid interface");
    }
    
    static struct strobeArgs args;
    args.usb = (MCCDevice *)thePointer;
    args.pulseWidth = pulseWidth;
    
#ifdef DEBUG
    mexPrintf("thePointer = 0x%x, pulseWidth = %1.4f\n",
            args.usb,args.pulseWidth);
#endif
        
#ifdef USETHREADS
    
    char msgBuffer[256];
    sprintf(msgBuffer,"DIO{%i}:VALUE=%i",EVNTDIO,theValue);
    args.usb->sendAsynchMessage(msgBuffer);
    
    int rc;
    pthread_t *pulse_thread = new pthread_t;
    rc = pthread_create(pulse_thread, NULL,strobeFunction,(void *)&args);
    if (rc != 0) {
        mexErrMsgTxt("usb1208FSPlusStrobeAsynch: pthread_create failed");
        *mxGetPr(plhs[0]) = -1;
        return;
    }
    rc = pthread_detach(*pulse_thread);
    if (rc != 0){
        mexErrMsgTxt("usb1208FSPlusStrobeAsynch: pthread_detach failed");
        *mxGetPr(plhs[0]) = -1;
        return;
    }
#else
    pulseWidthModThreadFnc((void *)&args);
    pthread_t *pulse_thread = 0;
#endif
        
    *mxGetPr(plhs[0]) = (unsigned long)pulse_thread; // return success
    
}


