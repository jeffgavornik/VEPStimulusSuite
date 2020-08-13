#include "threadReturns.h"

threadedPulseInfoClass::threadedPulseInfoClass()
{
    onCount = 0;
    offCount = 0;
    onTime = 0;
    offTime = 0;
    threadComplete = false;
}

// Helper used to calculate elapsed time between two events
timespec diff(timespec start, timespec end)
{
    timespec delta;
    if ((end.tv_nsec-start.tv_nsec)<0) {
        delta.tv_sec = end.tv_sec-start.tv_sec-1;
        delta.tv_nsec = 1e9+end.tv_nsec-start.tv_nsec;
        // delta.tv_nsec = end.tv_nsec-start.tv_nsec;
    } else {
        delta.tv_sec = end.tv_sec-start.tv_sec;
        delta.tv_nsec = end.tv_nsec-start.tv_nsec;
    }
    return delta;
}
