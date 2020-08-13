#include "mex.h"
#include "mccDevice.h"
#include "usb1208FSPlusInterface.h"
#include <ctime>

#include <errno.h>

#define USETHREADS

// NOT YET IN USE

// 64 bit version

// Forward declarations of local use functions
static void cleanup_handler(void *arguments);
timespec diff(timespec start, timespec end);

// Implement TTL interface functions

void startRecording(MCCDevice *usb)
{
    // Set STARTBIT high and STOPBIT low
#ifdef DEBUG
    mexPrintf("usb1208FSPlusStartRecording thePointer = 0x%x\n",thePointer);
#endif
    char msgBuffer[256];
    sprintf(msgBuffer,"DIO{%i/%i}:VALUE=1",CTRLDIO,STARTBIT);
#ifdef DEBUG
    mexPrintf("theMsg = %s\n",msgBuffer);
#endif
    string response;
    usb->sendMessage(msgBuffer);
    sprintf(msgBuffer,"DIO{%i/%i}:VALUE=0",CTRLDIO,STOPBIT);
#ifdef DEBUG
    mexPrintf("theMsg = %s\n",msgBuffer);
#endif
    usb->sendMessage(msgBuffer);
}


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




// Functions reliant on POSIX threads to dispatch asynchronous tasks and 
// return immediately to the main processing thread

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

void * generateStrobePulse(void *arguments)
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
    } else {
        temp.tv_sec = end.tv_sec-start.tv_sec;
        temp.tv_nsec = end.tv_nsec-start.tv_nsec;
    }
    return temp;
}




