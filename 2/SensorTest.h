#ifndef SENSOR_TEST_H
#define SENSOR_TEST_H

typedef nx_struct sensor_msg{
	nx_uint8_t type;
	nx_uint16_t data;
} sensor_msg_t;

enum{
	AM_SEND_MSG = 6,
};

#endif
