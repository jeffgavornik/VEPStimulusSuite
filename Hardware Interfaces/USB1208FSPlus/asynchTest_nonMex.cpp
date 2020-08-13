#include "mccDevice.h"
#include <ctime>
#include <unistd.h>
#include <stdio.h>
#include "usb1208FSPlusInterface.h"

#define DEVICE USB_1208FS_Plus

int main(void)
{
	
    MCCDevice *usb;
    try 
      {
          usb = new MCCDevice(DEVICE);
          usb->sendMessage("DEV:RESET/DEFAULT");
          usb->sendMessage("DIO{0}:DIR=OUT");
          usb->sendMessage("DIO{1}:DIR=OUT");
          usb->sendMessage("DIO{0}:VALUE=0");
          usb->sendMessage("DIO{1}:VALUE=0");
          //usb->sendMessage("AO:SCALE=DISABLE");
          usb->sendMessage("AO{0}:VALUE=0");
          //usb->sendMessage("AO{1}:VALUE=0");
      }
    catch(mcc_err err)
      {
          delete usb;
          usb = 0;
          printf("USB Device Error\n"); //: %s\n",errorString(err));	
      }
    
    static char msgBuffer[256];
    bool value = true;
    for (int ii=0;ii<6;ii++){
        sprintf(msgBuffer,"DIO{%i}:VALUE=%i",EVNTDIO,value);
        usb->sendAsynchMessage(msgBuffer);
        //usb->sendMessage(msgBuffer);
        usleep(1*1e-3*1e6); // value is ms
//         sleep(1);
        value = !value;
    }
    
    delete usb;
    // printf("Bye bye\n");
    
    return 0;
}