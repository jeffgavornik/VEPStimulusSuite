DEST_DIR = /usr/local/MATLAB/Shared/StimulusSuite/ScrnCtrlApp

all: tar

tar:
	tar -cf ScrnCtrlApp.tar *.m *.fig README Makefile

install:
	@[ -d $(DEST_DIR) ] || mkdir -p $(DEST_DIR)
	cp *.m *.fig $(DEST_DIR)
