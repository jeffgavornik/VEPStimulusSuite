

/*

    When inPin goes from low to high, start pulsing on outPin with a pulseHalfPeriod.
    Keep pulsing for burstDuration and abort if inPin goes low to high

    Terminology -
      a pulse is a single on-off of light with a duration specified by pulseFreq
      a burst is a bunch of pulses specified by a duration in ms
      pwm can be used to modulate laser power delivered by each pulse

    Serial connection can be used to set burstDuration and pulseFreq
    String should look like this 'burstDuration:pulseFreq', where both are integers.  Values of 0 are ignored.

    See https://forum.arduino.cc/t/serial-input-basics/278284/2

    IC2 controlled LCD (I2C 16x2) shows current set points

    A4 connects to SDA
    A5 connects to SCL
    see also:
    https://wiki.dfrobot.com/I2C_TWI_LCD1602_Module__Gadgeteer_Compatible___SKU__DFR0063_
    https://www.makerguides.com/character-i2c-lcd-arduino-tutorial/

*/

#include "serialCmdDefs.h"
#include <LiquidCrystal_I2C.h>
#include <Wire.h>

// The following values must match those used in arduinoSerialPulseGenerator.m
#define NEWLINE 10 // Linefeed LF (0x0A) sent to terminate string in Matlab, could also use CarriageReturn (CR) = 13 = 0x0D
#define BUFFERSIZE 52 // all commands will be this many bytes
#define BAUDRATE 115200 // must match matlab value

#define MAXDURATION 3600000 // one hour 4294967290 // for unsigned long

// Hardware Assignments
const int inPin = 8;
const int outPin = 9;
const int burstActivePin = LED_BUILTIN; // built in LED will show pulses

unsigned long currTime, burstEndTime, pulseToggleTime; // for use with millis timer
unsigned long burstDuration = 3000; // ms
float pulseFreq = 30; // Hz
unsigned long pulseHalfPeriod; // ms, one on-off cycle occurs every 2 pulseHalfPeriods
int laserState = LOW;
int pulseActive = LOW;
int dutyCycle = 100;
int pwmLevel = 255;

bool abortFlag = false;
bool serialTrigger = false;
bool startBurst = false;

// Variables used to process serial commands
const char startMarker = '<';
const char endMarker = '>';
char cmdBuffer[BUFFERSIZE];
bool newCommandReceived = false;


// Variables to set minimum interval before trigger pulses
unsigned long readyForTriggerTime;
int debounceWindow = 50; // ms, define minimum time between toggles

// LCD Interface
// Set the LCD address to 0x20 for a 16 chars and 2 line display
// (all address jumpers in place)
LiquidCrystal_I2C lcd(0x20, 16, 2);

bool inPinToggled = false;

int inPinState, prevInPinState;

enum programStates {
  WAITING,
  PULSING
};
int programState = WAITING;

void setup() {
  pinMode(inPin, INPUT);
  pinMode(outPin, OUTPUT);
  pinMode(burstActivePin, OUTPUT);
  inPinState = digitalRead(inPin);
  prevInPinState = inPinState;
  readyForTriggerTime = 0;

  // Calculate the pulseHalfPeriod based on frequency
  pulseHalfPeriod = 500 / pulseFreq;

  // Init the LCD
  lcd.init();
  lcd.backlight();
  lcd.clear();
  outputStateToLCD();

  // Activate the Serial interface
  Serial.begin(BAUDRATE);

}


void outputStateToLCD() {
  // Show current parameters
  lcd.home();
  lcd.print("Burst = ");
  if (burstDuration < MAXDURATION) {
    lcd.print(burstDuration);
    lcd.print(" ms     ");
  } else {
    lcd.print(" inf    ");
  }
  lcd.setCursor(0, 1);
  lcd.print("Freq = ");
  lcd.print(pulseFreq, 1);
  lcd.print(" Hz    ");
}


void loop() {

  currTime = millis();

  // Look for trigger pulses on inPin
  inPinToggled = false;
  if (currTime >= readyForTriggerTime || serialTrigger) {
    inPinState = digitalRead(inPin);
    if (inPinState != prevInPinState) { // toggle occured
      inPinToggled = true;
      prevInPinState = inPinState;
      readyForTriggerTime = currTime + debounceWindow;
      if (inPinToggled && inPinState == HIGH) startBurst = true;
    }
  }
  startBurst = (inPinToggled && inPinState == HIGH) || serialTrigger;

  // Determine when to start/stop pulse and when to turn the laser on and off
  switch (programState) {
    case WAITING:
      if (startBurst) {
        programState = PULSING;
        burstEndTime = currTime + burstDuration;
        pulseToggleTime = currTime + pulseHalfPeriod;
        laserState = HIGH;
        pulseActive = HIGH;
        Serial.println("BurstStarting");
      }
      break;
    case PULSING:
      if ((inPinToggled && inPinState == HIGH) || (currTime > burstEndTime) || abortFlag) {
        laserState = LOW;
        pulseActive = LOW;
        programState = WAITING;
        if (abortFlag) Serial.println("BurstAborted");
        else Serial.println("BurstComplete");
      } else if (currTime >= pulseToggleTime) {
        laserState = !laserState;
        pulseToggleTime = currTime + pulseHalfPeriod;
      }
      break;
  }

  //digitalWrite(outPin, laserState);
  analogWrite(outPin, laserState * pwmLevel);
  digitalWrite(burstActivePin, pulseActive);
  abortFlag = false;
  serialTrigger = false;
  processSerialCommands();
}

void processSerialCommands() {
  // Fill buffer with serial data until a complete command, delimited by <>, is received
  static bool recvInProgress = false;
  static byte iCmdBuff = 0;
  char rcvByte;
  while (Serial.available() > 0) {
    rcvByte = Serial.read();
    if (rcvByte == startMarker) {
      recvInProgress = true;
    } else if (recvInProgress) {
      if (rcvByte != endMarker) {
        cmdBuffer[iCmdBuff++] = rcvByte;
      } else {
        //cmdBuffer[iCmdBuff] == '\n';
        recvInProgress = false;
        //Serial.println(cmdBuffer);
        String commandStr(cmdBuffer);
        for (int ii = 0; ii <= iCmdBuff; ii++) cmdBuffer[ii] = 0;
        iCmdBuff = 0;
        if (!executeCommand(&commandStr)) {
          String rtrnStr("Unknown Command <");
          rtrnStr += commandStr + ">\n";
          Serial.print(rtrnStr);
        }
      }
    }
  }
}

bool executeCommand(String *commandStr) {
  // Interpret and execute complete commands
  bool success = true; // set false for unrecognized commands
  if (*commandStr == ABORTCMD) abortFlag = true;
  else if (*commandStr == VALIDATECMD) Serial.println("VALID");
  else if (*commandStr == TRIGGERCMD) serialTrigger = true;
  else {
    char *pVarName, *pVarValue;
    bool needRefresh = false;
    char cmdBuffer[commandStr->length()+1];
    commandStr->toCharArray(cmdBuffer,commandStr->length()+1);
    // Split command string at the :, 1st half is variable name 2nd half is value
    pVarName = strtok(cmdBuffer, ":");
    pVarValue = strtok(NULL, ":");
    String varName(pVarName);
    if (varName == BURSTDURATIONVAR) {
      int cmdBurstDuration = atoi(pVarValue);
      if (cmdBurstDuration == 0 && burstDuration != MAXDURATION) {
        burstDuration = MAXDURATION;
        needRefresh = true;
        burstEndTime = millis(); // end current pulse if in-progress
      } else if (cmdBurstDuration != burstDuration) {
        burstDuration = cmdBurstDuration;
        needRefresh = true;
        burstEndTime = millis(); // end current pulse if in-progress
      }
      String rtrnStr(BURSTDURATIONVAR);
      rtrnStr += "=" + String(burstDuration);
      Serial.println(rtrnStr);
    } else if (varName == PULSEFREQVAR) {
      float cmdPulseFreq = atof(pVarValue);
      if (cmdPulseFreq > 0 && pulseFreq != cmdPulseFreq) {
        needRefresh = true;
        pulseFreq = cmdPulseFreq;
        pulseHalfPeriod = 500 / pulseFreq;
        pulseToggleTime = millis();
      } else if (cmdPulseFreq == 0 && pulseFreq != 0.0) {
        needRefresh = true;
        pulseFreq = 0.0;
        pulseHalfPeriod = MAXDURATION;
        pulseToggleTime = millis();
      }
      String rtrnStr(PULSEFREQVAR);
      rtrnStr += "=" + String(pulseFreq);
      Serial.println(rtrnStr);
    } else if (varName == DUTYCYCLEVAR) {
      dutyCycle = constrain(atoi(pVarValue), 0, 100);
      pwmLevel = 255 * dutyCycle / 100;
      String rtrnStr(DUTYCYCLEVAR);
      rtrnStr += "=" + String(dutyCycle) + ":pwmLevel=" + String(pwmLevel);
      Serial.println(rtrnStr);
    } else {
      success = false;
    }
    if (needRefresh) outputStateToLCD();
  }
  return success;
}
