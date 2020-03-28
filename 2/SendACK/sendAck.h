/** This file contains the header for 
 *  the second hands-on activity of the
 *  course of Internet of Things, 2019/20
 *  developed by Giulio Mario Martena and
 *  Marcello Cellina, MSc's in Automation
 *  and Control Engineering.
 *  
 *  @template by Luca Pietro Borsani
 */

#ifndef SENDACK_H
#define SENDACK_H

//payload of the msg
typedef nx_struct my_msg {
	//field 1
    nx_uint8_t msg_type; 
	//field 2
    nx_uint8_t msg_counter;
	//field 3
    nx_uint16_t value;
} my_msg_t;

#define REQ 1
#define RESP 2 

enum{
AM_MY_MSG = 6,
};

#endif
