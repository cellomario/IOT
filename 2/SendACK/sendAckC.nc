/**
 *  Source file for implementation of module sendAckC in which
 *  the node 1 send a request to node 2 until it receives a response.
 *  The reply message contains a reading from the Fake Sensor.
 *
 *  @author Luca Pietro Borsani
 */

#include "sendAck.h"
#include "Timer.h"

module sendAckC {

  uses {
  /****** INTERFACES *****/
	interface Boot; 
	//timer
	interface Timer<TMilli> as MilliTimer;
	//radio
	interface SplitControl;
	interface AMSend;
	interface Packet;
	interface PacketAcknowledgements as PackAck;
	interface Receive;

	
    //interfaces for communication
	//interface for timer
    //other interfaces, if needed
	
	//interface used to perform sensor reading (to get the value from a sensor)
	interface Read<uint16_t>;
  }

} implementation {

  uint8_t counter=0;
  uint8_t rec_id;
  message_t packet;

  void sendReq(uint8_t count);
  void sendResp();
  
  
  //***************** Send request function ********************//
  void sendReq(uint8_t count) {
	/* This function is called when we want to send a request
	 *
	 * STEPS:
	 * 1. Prepare the msg
	 * 2. Set the ACK flag for the message using the PacketAcknowledgements interface
	 *     (read the docs)
	 * 3. Send an UNICAST message to the correct node
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
	 my_msg_t* message=(my_msg_t*)(call Packet.getPayload(&packet, sizeof(my_msg_t)));
	 if (message == NULL) {
		return;
	  }
	  message -> msg_type = REQ;
	  message -> msg_counter = count;
	  message -> value=0;
	  dbg("radio_send","message assembled ready to be transmitted\n");
	  if(call PackAck.requestAck(&packet)==SUCCESS){
	  	dbg("radio_send","enabled acknowledgement for transmission\n");
	  		if (call AMSend.send(2, &packet,sizeof(my_msg_t))==SUCCESS){
				dbg("radio_send", "Packet passed to lower layer successfully!\n");
	     		dbg("radio_pack","Packet Sent!\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
	     		dbg_clear("radio_pack","\t Payload Sent\n" );
		 		dbg_clear("radio_pack", "\t\t type: %hhu \n ", message->msg_type);
		 		dbg_clear("radio_pack", "\t\t counter: %hhu \n ", message->msg_counter);
		 		dbg_clear("radio_pack", "\t\t value: %hhu \n ", message->value);
	  			
	  			
	  		}
	  }
 }        

  //****************** Task send response *****************//
  void sendResp() {
  	/* This function is called when we receive the REQ message.
  	 * Nothing to do here. 
  	 * `call Read.read()` reads from the fake sensor.
  	 * When the reading is done it raise the event read one.
  	 */
	call Read.read();
  }

  //***************** Boot interface ********************//
  event void Boot.booted() {
	dbg("boot","Application booted.\n");
	call SplitControl.start();
//	if(TOS_NODE_ID==1){
//		call MilliTimer.startPeriodic(1000);
//		dbg("boot","started timer  at 1 Hz on mote 1\n");
//	}
	/* Fill it ... */
  }

  //***************** SplitControl interface ********************//
  event void SplitControl.startDone(error_t err){
 	if (err == SUCCESS) {
 		dbg("radio","radio on\n");
		if(TOS_NODE_ID==1){
			call MilliTimer.startPeriodic(1000);
			dbg("boot","started timer  at 1 Hz on mote 1\n");
		}
    }
    else {
      call SplitControl.start();
    }
  }
  
  event void SplitControl.stopDone(error_t err){
    /* Fill it ... */
  }

  //***************** MilliTimer interface ********************//
  event void MilliTimer.fired() {
	/* This event is triggered every time the timer fires.
	 * When the timer fires, we send a request
	 * Fill this part...
	 */
	 counter++;
	 dbg("radio_send","incremented counter by 1, counter value %d\n",counter);
	 sendReq(counter);
  }
  

  //********************* AMSend interface ****************//
  event void AMSend.sendDone(message_t* buf,error_t err) {
	/* This event is triggered when a message is sent 
	 *
	 * STEPS:
	 * 1. Check if the packet is sent
	 * 2. Check if the ACK is received (read the docs)
	 * 2a. If yes, stop the timer. The program is done
	 * 2b. Otherwise, send again the request
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
	 if(&packet == buf && err == SUCCESS){
	 	dbg("radio_send","packet was sent successfully");
	 	dbg_clear("radio_send", " at time %s \n", sim_time_string());
	 }
	 else{
	 dbgerror("radio_send","Problem occurred while sending packet\n");
	 }
	 if (call PackAck.wasAcked(&packet)==TRUE){
		dbg("radio_ack","packet was acknowledged\n");
		call MilliTimer.stop();
		dbg("boot","timer was stopped");
	  				
	}
	else{
		dbg("radio_ack","Packet was not acknowledged!!!\n");
		dbgerror("radio_ack","packet not acknowledged, timer was not stopped");
		dbg("radio_ack","\nAnother packet will be sent in 1 second\n");
		
	}
  }

  //***************************** Receive interface *****************//
  event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
	/* This event is triggered when a message is received 
	 *
	 * STEPS:
	 * 1. Read the content of the message
	 * 2. Check if the type is request (REQ)
	 * 3. If a request is received, send the response
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */

  }
  
  //************************* Read interface **********************//
  event void Read.readDone(error_t result, uint16_t data) {
	/* This event is triggered when the fake sensor finish to read (after a Read.read()) 
	 *
	 * STEPS:
	 * 1. Prepare the response (RESP)
	 * 2. Send back (with a unicast message) the response
	 * X. Use debug statement showing what's happening (i.e. message fields)
	 */
}

}
