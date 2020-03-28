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
	 // We initialze the message structure 
	 my_msg_t* message=(my_msg_t*)(call Packet.getPayload(&packet, sizeof(my_msg_t)));
	 if (message == NULL) {
		return;
	  }
	  // We fill the fields of the message structure as we are sending a REQ message and 
	  // then the value field is set to zero arbitrarely as it will not be considered
	  message -> msg_type = REQ;
	  message -> msg_counter = count;
	  message -> value=0;
	  dbg("radio_send","message assembled ready to be transmitted\n");
	  // Now it is time to implement the acknowledgement, which is done through this function that 
	  // enables the use of the acknowledgements in the communication protocol. The function requestAck returns
	  // an error, that if it is SUCCESS means that the communication protocol supports the acknowledgement and
	  // it has been enabled.
	  if(call PackAck.requestAck(&packet)==SUCCESS){
	  	dbg("radio_send","enabled acknowledgement for transmission\n");
	  		// we are now ready to send the packet with enabled acknowledgement.
	  		if (call AMSend.send(rec_id, &packet,sizeof(my_msg_t))==SUCCESS){
				dbg("radio_send", "Packet with destination node %d passed to lower layer successfully!\n",rec_id);
	     		dbg("radio_pack","Packet Sent!\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
	     		dbg_clear("radio_pack","\t Payload Sent\n" );
		 		dbg_clear("radio_pack", "\t\t type: %hhu \n ", message->msg_type);
		 		dbg_clear("radio_pack", "\t\t counter: %hhu \n ", message->msg_counter);
		 		dbg_clear("radio_pack", "\t\t value: %hhu \n ", message->value);
	  			
	  			
	  		}
	  }
 }        



  //***************** Boot interface ********************//
  event void Boot.booted() {
  //once booted, the fisrt thing to do is to turn on the radio, both for mote 1 and for mote 2
	dbg("boot","Application booted.\n");
	call SplitControl.start();					
  }

  //***************** SplitControl interface ********************//
  event void SplitControl.startDone(error_t err){
 	if (err == SUCCESS) {
 	//we have successfully turned on the radio. Now mote 1 will start sending requests to mote 2, which
 	//instead doesn' do anything right now as it waits until it receives a request
 		dbg("radio","radio on\n");
		if(TOS_NODE_ID==1){
		//set mote 1 to send messages to mote 2 and starts the timer at which requests will be sent.
			rec_id=2;
			dbg("boot","this is node %d that will send messages to node %d\n",TOS_NODE_ID,rec_id);	
			call MilliTimer.startPeriodic(1000);
			dbg("boot","started timer  at 1 Hz on mote 1\n");
		}
		else{
		//set mote 2 to send messages to mote 1 (supposing there is no mote 3)
		rec_id=1;
		dbg("boot","this is node %d that will send messages to node %d\n",TOS_NODE_ID,rec_id);	
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
	 *
	 *
	 *When the timer is fierd (every 1 second) we increase the counter by one and 
	 *then we call the function that sends the request
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
	 // First of all, let's check is the packet was sent succesfully
	 if(&packet == buf && err == SUCCESS){
	 	dbg("radio_send","packet was sent successfully");
	 	dbg_clear("radio_send", " at time %s \n", sim_time_string());
	 }
	 else{
	 dbgerror("radio_send","Problem occurred while sending packet\n");
	 }
	 // Now it is time to check if the packet was acknowledged. Notice that this operation
	 // is done exclusively on the sender side, as from the receiver side there is no need
	 // to implement anything as the acknowledgements are taken care of inside the transmission protocol.
	 if (call PackAck.wasAcked(&packet)==TRUE){
		dbg("radio_ack","packet was acknowledged\n");
		if(TOS_NODE_ID==1){
			// Once mote 1 sends a packet that is acknowledged, it must send no more.
			// The simplest way to do that is just to stop the timer
			call MilliTimer.stop();
			dbg("boot","timer was stopped\n");
	  	}
	  	else{ //when mote 2 sends packet to mote 1 and it was acknowledged, it has finished its job
	  		return;
	  	}
	}
	else{
		dbg("radio_ack","Packet was not acknowledged!!!\n");
		dbgerror("radio_ack","packet not acknowledged, timer was not stopped\nS");
		//If packet is not acknowledged since mote 2 still has to boot, ti will just send another one
		//next time the timer is fired.
		dbg("radio_send","Another packet will be sent in 1 second\n");
		
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
	 if(len!=sizeof(my_msg_t)){
	 	dbgerror("radio_rec","received packet with unexpected length\n");
	 	return buf;
	 }
	 else{
	 // We decompose the message, show it into the debugger in order to read its fields. 
	 	my_msg_t* message=(my_msg_t*)payload;
	 	dbg("radio_rec", "Received packet at time %s\n", sim_time_string());
      	dbg("radio_pack"," Payload length %hhu \n", call Packet.payloadLength(buf));
      	dbg("radio_pack", ">>>Packet content: \n");
      	dbg_clear("radio_pack","\t\t Payload Received\n" );
      	dbg_clear("radio_pack", "\t\t type: %hhu \n ", message->msg_type);
 		dbg_clear("radio_pack", "\t\t counter: %hhu \n ", message->msg_counter);
 		dbg_clear("radio_pack", "\t\t value: %hhu \n ", message->value);
 		if(message->msg_type==REQ){
 			// If we have received a request, now it is time to act for mote 2 and to send a RESP
 			dbg("radio_rec","received REQ message, reading sensor\n");
 			counter=message->msg_counter; //now this saves the counter received from mote 1 into the counter of mote 2.
 			// this is done to save memory as the counter in mote 2 is never used as the timer is never fired.
 			sendResp(); //call the function in order to send the response.
			
 		}
 		return buf;
	 }

  }
  
    //****************** Task send response *****************//
  void sendResp() {
  	/* This function is called when we receive the REQ message.
  	 * Nothing to do here. 
  	 * `call Read.read()` reads from the fake sensor.
  	 * When the reading is done it raise the event read one.
  	 */
  	 //Call the function in order to read the sensor
	call Read.read();

	
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
	 //initialize message structure (must be done first otherwise there is a compiler error 
	my_msg_t* message=(my_msg_t*)(call Packet.getPayload(&packet, sizeof(my_msg_t)));
	 //NOw, let's see what was the result of the sensor reading.
	if(result==SUCCESS){
 		dbg("radio_rec","Sensor read correctly, preparing response\n");}
	else{ // if there is trouble reading the sensor, just do it again.
		dbgerror("radio_rec","trouble reading sensor\n");
		call Read.read();
		return;}
	// We assemble the message exactly as we did in the sendReq function on top.
	message -> msg_type = RESP;
	message -> msg_counter = counter;
	message -> value=data;
	dbg("radio_send","message assembled ready to be transmitted\n");
	if(call PackAck.requestAck(&packet)==SUCCESS){
	  	dbg("radio_send","enabled acknowledgement for transmission\n");
	  		// we are now ready to send the packet with enabled acknowledgement.
  		if (call AMSend.send(rec_id, &packet,sizeof(my_msg_t))==SUCCESS){
			dbg("radio_send", "Packet with destination node %d passed to lower layer successfully!\n",rec_id);
     		dbg("radio_pack","Packet Sent!\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
     		dbg_clear("radio_pack","\t Payload Sent\n" );
	 		dbg_clear("radio_pack", "\t\t type: %hhu \n ", message->msg_type);
	 		dbg_clear("radio_pack", "\t\t counter: %hhu \n ", message->msg_counter);
	 		dbg_clear("radio_pack", "\t\t value: %hhu \n ", message->value);
 			

	}

}

}
}
