
// RFID Config:
#define rfidRxPin 10
#define rfidTxPin 11 // not used!

// Network Config:
byte mac[] = {  0xDE, 0xAD, 0xBE, 0xEF, 0xEF, 0xDE };
byte ip[] = { 192,168,111,178 }; // 178
byte gateway[] = { 192,168,111,254 };
byte subnet[] = { 255, 255, 0, 0 };
byte server[] = { 50,56,113,187 }; // gctechspace.org
//byte server[] = { 192,168,111,103 }; // local ldevl

// Other Pins:
const int buttonPin = 2;     // the number of the door magnet switch
const int ledPin =  8;      // the number of the LED debug pin
const int switchPin =  3;      // the number of the pin that goes to the garage door switch
const boolean enableSerial = true;
const String getRequestTrigger = "GET /triggerdoor";
const String getRequestStatus = "GET /get_status";

