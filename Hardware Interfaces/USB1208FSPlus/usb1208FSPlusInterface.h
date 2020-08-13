
#ifndef USB1208FSPLUSINTERFACE_H
#define USB1208FSPLUSINTERFACE_H

#ifdef __cplusplus
extern "C" {
#endif

// Uncomment to include various print statements
// #define DEBUG

// enumerate DIO designation and bits for specific I/O functions
enum dataBitValues {
    // Designate DIO A for control signals
    CTRLDIO = 0,
    STARTBIT = 0,
    STOPBIT = 1,
    STROBEBIT = 2,
    // Designate DIO B for event word
    EVNTDIO = 1,
    EVNTBITS = 8,
    // Parameters for Analog channels
    MAXAOVALUE = 4095
};

// Designate DIO A for control signals
//    unsigned int ctrlDIO = 0;
//    unsigned int startBit = 0;
//    unsigned int stopBit = 1;
//    unsigned int strobeBit = 2;
// Designate DIO B for event word
//    unsigned int evntDIO = 1;
//    unsigned int evntBits = 8;

/*
// Define structures used to pass various info to interface functions
struct strobeArgs {
    MCCDevice *usb;
    double pulseWidth;        
};
    
void * generateStrobePulse(void *arguments);
*/
    
#ifdef __cplusplus
}
#endif

#endif /* _USB1208FSPLUSINTERFACE_H */
