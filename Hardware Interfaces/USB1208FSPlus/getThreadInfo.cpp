#include "mex.h"
#include "threadReturns.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    
    if ( nrhs != 2 ) mexErrMsgTxt("threadtest: 2 inputs required");
    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL); // onCount
    plhs[1] = mxCreateDoubleMatrix(1,1,mxREAL); // offCount
    plhs[2] = mxCreateDoubleMatrix(1,1,mxREAL); // onTime
    plhs[3] = mxCreateDoubleMatrix(1,1,mxREAL); // offTime
    plhs[4] = mxCreateDoubleMatrix(1,1,mxREAL); // threadComplete
    
    // Argument 1 is a pointer to the threadInfoClass object
    // Argument 2 is true/false indicating whether the threadInfo should
    // be destroyed after returning its info
    unsigned long threadInfoPointer = (unsigned long)mxGetScalar(prhs[0]);
    bool deleteObject =  (bool)mxGetScalar(prhs[1]);
    
    if (threadInfoPointer == 0){
        mexErrMsgTxt("getThreadInfo: invalid address");
    }
#ifdef DEBUG
    mexPrintf("getThreadInfo threadInfoPointer = 0x%x\n",threadInfoPointer);
#endif
    
    // Get the threadInfoClass object
    threadedPulseInfoClass *threadInfo = 
            (threadedPulseInfoClass *)threadInfoPointer;
    
    // Set return values
    *mxGetPr(plhs[0]) = threadInfo->onCount;
    *mxGetPr(plhs[1]) = threadInfo->offCount;
    *mxGetPr(plhs[2]) = threadInfo->onTime;
    *mxGetPr(plhs[3]) = threadInfo->offTime;
    *mxGetPr(plhs[4]) = (unsigned int)threadInfo->threadComplete;
    
    if (deleteObject) {
        if (!threadInfo->threadComplete)
            mexErrMsgTxt("getThreadInfo: attempt to delete info for incomplete thread");
        delete threadInfo;
    }
    
}


