UNAME := $(shell uname)

ifeq ($(UNAME),Darwin)
MEX = /Applications/MATLAB_R2014b.app/bin/mex
#MEX = /Applications/MATLAB_R2015a.app/bin/mex
INCLUDE_DIRS = -I/opt/local/include/libusb-1.0
LIB_DIRS = -L/opt/local/lib -lusb-1.0 -lpthread
DEST_DIR = /usr/local/MATLAB/Shared/usb1208FSPlusInterface
CPP_CMD = clang++
OBJECTFILE = mccDevice_MAC.o
THREADOBJECTFILE = threadInfo_MAC.o
CLEAN_CMD = rm *mexmaci64 $(OBJECTFILE)
endif

ifeq ($(UNAME),Linux)
MEX = mex
INCLUDE_DIRS = -I/lib/x86_64-linux-gnu -I/usr/local/include/libusb-1.0/
LIB_DIRS =  -L/usr/local/lib -lusb-1.0 -lpthread
DEST_DIR = /usr/local/MATLAB/Shared/usb1208FSPlusInterface
CPP_CMD = g++ -std=c++11
OBJECTFILE = mccDevice_LINUX.o
THREADOBJECTFILE = threadInfo_LINUX.o
CLEAN_CMD = rm *mexa64 $(OBJECTFILE)
endif

MEX_OPTS = -O
EXTRA_LIBS =
MEX_CMD = $(MEX) $(MEX_OPTS) $(INCLUDE_DIRS) $(LIB_DIRS) $(EXTRA_LIBS)

all:	mccDevice open close start stop strobe set get threads  
#all:	mccWithMex open close start stop strobe set get
indevelopment: threads test

mccWithMex: mccDevice.cpp mccDevice.h usb1208FSPlusInterface.h
	$(CPP_CMD) -fPIC -c -I/Applications/MATLAB_R2014b.app/extern/include -o $(OBJECTFILE) mccDevice.cpp

mccDevice: mccDevice.cpp mccDevice.h usb1208FSPlusInterface.h
	$(CPP_CMD) -fPIC -c -o $(OBJECTFILE) mccDevice.cpp

open: $(OBJECTFILE) mccDevice.h usb1208FSPlusInterface.h
	$(MEX_CMD) -output usb1208FSPlusOpenInterface usb1208FSPlusOpenInterface.cpp $(OBJECTFILE)

close: $(OBJECTFILE) mccDevice.h usb1208FSPlusInterface.h
	$(MEX_CMD) -output usb1208FSPlusCloseInterface usb1208FSPlusCloseInterface.cpp $(OBJECTFILE)

start: $(OBJECTFILE) mccDevice.h usb1208FSPlusInterface.h
	$(MEX_CMD) -output usb1208FSPlusStartRecording usb1208FSPlusStartRecording.cpp $(OBJECTFILE)

stop: $(OBJECTFILE) mccDevice.h usb1208FSPlusInterface.h
	$(MEX_CMD) -output usb1208FSPlusStopRecording usb1208FSPlusStopRecording.cpp $(OBJECTFILE)

strobe: $(OBJECTFILE) mccDevice.h usb1208FSPlusInterface.h
	$(MEX_CMD) -output usb1208FSPlusStrobe usb1208FSPlusStrobe.cpp $(OBJECTFILE)
	$(MEX_CMD) -output usb1208FSPlusSetStrobe usb1208FSPlusSetStrobe.cpp $(OBJECTFILE)

set: $(OBJECTFILE) mccDevice.h usb1208FSPlusInterface.h
	$(MEX_CMD) -output usb1208FSPlusSetEvent usb1208FSPlusSetEvent.cpp $(OBJECTFILE)
	$(MEX_CMD) -output usb1208FSPlusSetAnalog usb1208FSPlusSetAnalog.cpp $(OBJECTFILE)
	$(MEX_CMD) -output usb1208FSPlusSendMessage usb1208FSPlusSendMessage.cpp $(OBJECTFILE)
	$(MEX_CMD) -output usb1208FSPlusFlush usb1208FSPlusFlush.cpp $(OBJECTFILE)

get:$(OBJECTFILE) mccDevice.h usb1208FSPlusInterface.h
	$(MEX_CMD) -output usb1208FSPlusGetAI usb1208FSPlusGetAI.cpp $(OBJECTFILE)
	$(MEX_CMD) -output usb1208FSPlusGetDI usb1208FSPlusGetDI.cpp $(OBJECTFILE)

threads: $(OBJECTFILE) mccDevice.h usb1208FSPlusInterface.h
	$(CPP_CMD) -fPIC -c -o $(THREADOBJECTFILE) threadReturns.cpp
	$(MEX_CMD) -lrt -output threadTest threadTest.cpp $(OBJECTFILE)
	$(MEX_CMD) -lrt -output cancelThread cancelThread.cpp $(OBJECTFILE)
	$(MEX_CMD) -lrt -output usb1208FSPlusStrobeAsynch usb1208FSPlusStrobeAsynch.cpp $(OBJECTFILE)
	$(MEX_CMD) -lrt -output usb1208FSPlusStrobeEventAsynch usb1208FSPlusStrobeEventAsynch.cpp $(OBJECTFILE)
	$(MEX_CMD) -lrt -output pulseLaserThreaded pulseLaserThreaded.cpp $(OBJECTFILE) $(THREADOBJECTFILE)
	$(MEX_CMD) -lrt -output pulseLaserPoissonThreaded pulseLaserPoissonThreaded.cpp $(OBJECTFILE) $(THREADOBJECTFILE)
	$(MEX_CMD) -lrt -output getThreadInfo getThreadInfo.cpp $(THREADOBJECTFILE)
    

test: $(OBJECTFILE) mccDevice.h usb1208FSPlusInterface.h
	$(MEX_CMD) -output testAsync testAsync.cpp $(OBJECTFILE)
	$(MEX_CMD) -output testUSBSpeed testUSBSpeed.cpp $(OBJECTFILE)
	$(CPP_CMD)  $(INCLUDE_DIRS) -output asynchTest_nonMex asynchTest_nonMex.cpp $(OBJECTFILE)

clean:
	$(CLEAN_CMD)

install:
	@[ -d $(DEST_DIR) ] || mkdir -p $(DEST_DIR)
	cp *.m *.mexa64 *.sh $(DEST_DIR)
