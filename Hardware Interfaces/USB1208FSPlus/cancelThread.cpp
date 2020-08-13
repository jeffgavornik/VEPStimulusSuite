#include "mex.h"
#include "mccDevice.h"

#include <errno.h>

#define handle_error_en(en,msg) \
    do { errno = en; perror(msg); exit(EXIT_FAILURE); } while (0)

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    
    if ( nrhs != 1 ) mexErrMsgTxt("threadtest: 1 inputs required");
    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
    
    unsigned long thePointer = (unsigned long)mxGetScalar(prhs[0]);
    
    if (thePointer == 0){
        mexErrMsgTxt("cancelThread: invalid thread");
    }
        
#ifdef DEBUG
    mexPrintf("cancelThread thePointer = 0x%x\n",thePointer);
#endif
    
    pthread_t *thr = (pthread_t *)thePointer;
    int s;
    
    s = pthread_cancel(*thr);
    if (s!=0)
        handle_error_en(s,"pthread_cancel");
        //mexErrMsgTxt("cancelThread: pthread_create failed");
    
    void *res;
    s = pthread_join(*thr,&res);
    if (s!=0)
        handle_error_en(s,"pthread_join");
    
    if (res==PTHREAD_CANCELED)
        s = 1;
    else {
        s = -1;
    }
    
    delete thr;
    
    *mxGetPr(plhs[0]) = s; // return success
    
}


