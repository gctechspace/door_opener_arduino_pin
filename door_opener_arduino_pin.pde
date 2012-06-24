/*
  
 Web Server / Door Open Status / Opener
 
 */

#include <SPI.h>
#include <Ethernet.h>
#include <config.h>  

//rfid stuff:
#include <SoftwareSerial.h>
SoftwareSerial rfid = SoftwareSerial( rfidRxPin, rfidTxPin );
int incomingByte = 0;    // To store incoming serial data

// Initialize the Ethernet server library
// with the IP address and port you want to use 
// (port 80 is default for HTTP):
Server door_server(8081);

// variables will change:
int buttonState = 0;         // variable for reading the pushbutton status
boolean doorOpen = false;         // variable for reading the door status
int lastStatusUpdate = 0;
int statusUpdateDelay = 60; 


void setup()
{
  // start the Ethernet connection:
  Ethernet.begin(mac, ip, gateway, subnet);
  // start the serial library:
  if(enableSerial)Serial.begin(9600);
  // give the Ethernet shield a second to initialize:
  delay(1000);
  
  // initialize the LED pin as an output:
  pinMode(ledPin, OUTPUT);      
  // initialize the pushbutton pin as an input:
  pinMode(buttonPin, INPUT);    
  // initialize the door switch pin as an output:
  pinMode(switchPin, OUTPUT);    
  // and pin off by default.
  digitalWrite(switchPin, LOW); 
  
  
  if(enableSerial)Serial.println("\n\nDoor Control:");
  // start the Ethernet connection and the server:
  //door_server.begin();
}

void loop()
{
  
  check_door_state();
  check_for_http_request();
  /*if(lastStatusUpdate + statusUpdateDelay < now()){
    // if the last status update was performed more than 60 seconds ago
    // send a new "hello! im here" to our server.
    postback_server_door_status();
    lastStatusUpdate = now();
  }*/
}


void check_for_http_request(){
  
  String requestLine;
  String currentPassword = "";
  boolean triggerDoorFinal = false;
  // listen for incoming clients
  Client client = door_server.available();
  if (client) {
    // an http request ends with a blank line
          if(enableSerial)Serial.println("got connect ");
    boolean currentLineIsBlank = true;
    boolean has_door_control = false; // if we are controlling door or not.
    int requestType = 0; // 1 = trigger, 2 = status.
    while (client.connected()) {
      if (client.available()) {
        char c = client.read();
          //if(enableSerial)Serial.println(" got: "+c);
        // if you've gotten to the end of the line (received a newline
        // character) and the line is blank, the http request has ended,
        // so you can send a reply
        if (c == '\n' && currentLineIsBlank) {
          // send a standard http response header
          // process the
          if(enableSerial)Serial.println("Responding to request: "+requestLine);
          switch(requestType){
            case 1: // it's a trigger request
              if(enableSerial)Serial.println(" - trigger request ");
              requestType = 0; // reset request type.. 
              client.println("HTTP/1.1 200 OK");
              client.println("Content-Type: text/html");
              client.println();
              client.print("Authorising your pin number, please wait...");
              // we post this data back to the server to verify the pin number
              // if we get a success then we trigger the door.
              triggerDoorFinal=true;
  
              client.println();
              //byte rip[4];
              //ccc.getRemoteIP(rip);
              //if(enableSerial)Serial.println(" remote ip address: "+rip[0]+"."+rip[1]+"."+rip[2]+"."+rip[3]);
              
              break;
            case 2: // it's status request
              if(enableSerial)Serial.println(" - status request ");
              // return the status as a string so we can process.
              client.println("HTTP/1.1 200 OK");
              client.println("Content-Type: text/html");
              client.println();
              client.println("Door Status: Active");
              if(doorOpen){
                client.println("Open or Closed: Open");
              }else{
                client.println("Open or Closed: Closed");
              }
              break;
            default:
              if(enableSerial)Serial.println("Unknown request type");
              client.println("HTTP/1.1 505 Error");
              client.println("Content-Type: text/html");
              client.println();
              client.print("Auth failed...");
          }
          client.println("<br />");
          // ifnished with the response.
          break;
        }else if (c == '\n') {
          // you're starting a new line
          // check if this line matches our acceptable GET requests.
          if(requestLine.length() > getRequestTrigger.length()){
            String checkRequest = requestLine.substring(0,getRequestTrigger.length());
            //if(enableSerial)Serial.println("Checking the request line: "+checkRequest);
            if(checkRequest.equals(getRequestTrigger)){
              // handle the request to trigger the door.
              if(enableSerial)Serial.println(" - got a trigger request");
              requestType = 1;
              // start parsing GET requests:
              
              int cc = 0;
              int cf = 0;
              char ca;
              String lookingfor = "pin=";
              String checkbit = "";
              // find the "pin=" argument. terminated by end of line or &
              for(cc=0; cc<requestLine.length()-lookingfor.length(); cc++){
                checkbit = requestLine.substring(cc,cc+lookingfor.length());
                
                if(cf==1){
                  // we're recording our check bit.
                  ca = requestLine.charAt(cc);
                  if(ca == '\n' || ca == '\r' || ca == NULL || ca == ' '){
                    cf = 2; // finished recording.
                    break;
                  }else{
                    currentPassword = currentPassword + ca;
                    if(enableSerial)Serial.println(" - Recording: "+currentPassword);
                  }
                }else if(cf==2){
                  // finished recording!
                  // will never reach here.
                }else{
                  if(enableSerial)Serial.println(" - checking: "+checkbit);
                  if(checkbit.equals(lookingfor)){
                    if(enableSerial)Serial.println(" - FOUND IT!");
                    cf=1;
                    cc+=(lookingfor.length()-1);
                  }
                }
              }
              // end parsing GET requests:
            }
          }
          if(requestLine.length() > getRequestStatus.length()){
            String checkRequest = requestLine.substring(0,getRequestStatus.length());
            //if(enableSerial)Serial.println("Checking get request: "+checkRequest);
            if(checkRequest.equals(getRequestStatus)){
              // handle the request to get the status.
              if(enableSerial)Serial.println(" - got a status request: "+checkRequest);
              requestType = 2;
            }
          }
          currentLineIsBlank = true;
          requestLine="";
        }else if (c != '\r') {
          // you've gotten a character on the current line
          currentLineIsBlank = false;
          // add it to our requestLine string so we can process on it.
          requestLine+=c;
             // if(enableSerial)Serial.println("GEt: "+requestLine);
        }
      }
    }
    // give the web browser time to receive the data
    delay(1);
    // close the connection:
    client.stop();
  }
  if(triggerDoorFinal){
    
    postback_server_door_trigger(currentPassword); //
  }
}


void check_door_state(){
  // read the state of the pushbutton value:
  buttonState = digitalRead(buttonPin);

  // check if the pushbutton is pressed.
  // if it is, the buttonState is HIGH:
  if (buttonState == HIGH) {     
    // turn debug LED on:
    digitalWrite(ledPin, HIGH);  
    // notify our server that the door is open.
    // only norify if the door wasn't prevoiusly open
    if(!doorOpen){
      if(enableSerial)Serial.println("door is now open");
      doorOpen = true;
      postback_server_door_status();
      
    }
  } 
  else {
    // turn LED off:
    digitalWrite(ledPin, LOW); 
    // notify server that door is now closed.
    if(doorOpen){
      if(enableSerial)Serial.println("door is now closed");
      doorOpen = false;
      postback_server_door_status();
    }
  }
}

void postback_server_door_status(){
  
  Client client(server, 80);
  if(enableSerial)Serial.println("connecting...");
  delay(100);
  
  // if you get a connection, report back via serial:
  if (client.connect()) {
    if(enableSerial)Serial.println("connected");
    // Make a HTTP request:
    if(doorOpen){
      if(enableSerial)Serial.println("door is open - sending status");
      client.println("GET /door/postback.php?door=open HTTP/1.0");
    }else{
      if(enableSerial)Serial.println("door is closed - sending status");
      client.println("GET /door/postback.php?door=closed HTTP/1.0");
    }
    client.println("Host: gctechspace.org");
    client.println();
  } 
  else {
    // kf you didn't get a connection to the server:
    if(enableSerial)Serial.println("connection failed");
  }
  delay(2);
  if(enableSerial)Serial.println("disconnecting.");
  client.stop();
}


void postback_server_door_trigger(String currentPassword){
  
  Client client(server, 80);
  boolean passwordValid = false;
  char cr;
  String serverGet;
  
  if(enableSerial)Serial.println("Checking pin number on door trigger - with pass: "+currentPassword);
  //if(enableSerial)Serial.println("connecting");
  delay(200);
  
  // if you get a connection, report back via serial:
  if (client.connect()) {
    if(enableSerial)Serial.println(" - client connected");
    // Make a HTTP request:
    
    if(doorOpen){
      serverGet = "GET /door/postback.php?door=open&trigger=1&pin=";
    }else{
      serverGet = "GET /door/postback.php?door=closed&trigger=1&pin=";
    }
    serverGet.concat(currentPassword);
    serverGet.concat(" HTTP/1.0");
    
    if(enableSerial)Serial.println(serverGet);
    client.println(serverGet);
    client.println("Host: gctechspace.org");
    client.println();
    
    boolean currentLineIsBlank;
    String requestLine;
    while (client.connected()) {
      if (client.available()) {
        cr = client.read();
          //if(enableSerial)Serial.println("POSTBACK CHECK: "+cr);
        // if you've gotten to the end of the line (received a newline
        // character) and the line is blank, the http request has ended,
        // so you can send a reply
        if (cr == '\n' && currentLineIsBlank) {
          // nothing.
          break;
        }else if (cr == '\n') {
          // you're starting a new line
          currentLineIsBlank = true;
          if(enableSerial)Serial.println("POSTBACK CHECK: "+requestLine);
          if(requestLine.equals("HTTP/1.1 200 OK")){
            if(enableSerial)Serial.println("Got a successful status from server. Opening door.");
            passwordValid = true;
          }
          requestLine="";
        }else if (cr != '\r') {
          // you've gotten a character on the current line
          currentLineIsBlank = false;
          // add it to our requestLine string so we can process on it.
          requestLine+=cr;
        }
      }
    }
  }
  else {
    // kf you didn't get a connection to the server:
    if(enableSerial)Serial.println("connection failed");
  }
  delay(2);
  if(enableSerial)Serial.println("disconnecting.");
  client.stop();
  
  
  if(passwordValid){
    if(enableSerial)Serial.println("password valid, opening the door.");
          digitalWrite(switchPin, HIGH); 
          delay(1000);
          digitalWrite(switchPin, LOW); 
  }else{
    if(enableSerial)Serial.println("password invalid, not opening the door.");
  }
    
}

