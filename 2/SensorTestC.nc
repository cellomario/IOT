#include "Timer.h"
#include "SensorTest.h"

module SensorTestC {

  uses {
	interface Boot;

    interface Timer<TMilli> as TempTimer;
    interface Timer<TMilli> as HumTimer;

	interface Read<uint16_t> as TempRead;
	interface Read<uint16_t> as HumRead;
	
	interface SplitControl;
	interface Packet;
	interface AMSend;
	
  }

} implementation {
  message_t packet;
  uint8_t counter=0;
  uint8_t rec_id;

  

  //***************** Boot interface ********************//
  event void Boot.booted() {
    
	dbg("boot","Application booted.\n");
      	
        call SplitControl.start();
  }
  
  event void SplitControl.startDone(error_t err){
  	if (err==SUCCESS){
  	dbg("radio", "Radio Started Successfully!\n");
  	 if (TOS_NODE_ID==0){
        // sink
        }
        
        if (TOS_NODE_ID==1){
        call TempTimer.startPeriodic( 1000 );
        dbg("temp", "Temperature timer started at 1 Hz\n");
        // Temp
        }
        
        if (TOS_NODE_ID==2){
        call HumTimer.startPeriodic( 2000 );
        dbg("hum","Humidity timer started at 2 Hz\n");
        // Hum
        }
  	}
  	else{
  		dbgerror("radio","Was not able to turn onn the radio, trouble somewhere, restarting radio\n\n");
  		call SplitControl.start();}
  }

  event void SplitControl.stopDone(error_t err){
  		// no interest here in stopping the radio
  }
  
  event void AMSend.sendDone(message_t* buf, error_t error){
  if(&packet == buf && error == SUCCESS){
 	 dbg("radio_send","packet sent correctly\n");
  }
  else
  {
  	dbg("redio_send","sending error packet\n");
  }
  
  //ci arriviamo
  }

  //***************** MilliTimer interface ********************//
  event void TempTimer.fired() {
	call TempRead.read();

  }
  event void HumTimer.fired(){
  	call HumRead.read();
  }
  
  //************************* Read interface **********************//
  event void TempRead.readDone(error_t result, uint16_t data) {
	double temp = ((double)data/65535)*100;
	dbg("temp","temp read done %f\n",temp);
  }

  event void HumRead.readDone(error_t result, uint16_t data) {
	double hum = ((double)data/65535)*100;
	dbg("hum","hum read done %f\n",hum);
  }



}

