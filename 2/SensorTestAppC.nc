#include "SensorTest.h"
configuration SensorTestAppC {}

implementation {

  components MainC, SensorTestC as App;
  components new TimerMilliC() as TimerTemp;
  components new TimerMilliC() as TimerHum;
  components new TempHumSensorC();
  components ActiveMessageC;
  components new AMSenderC(AM_SEND_MSG);
 

  //Boot interface
  App.Boot -> MainC.Boot;

  //Timer interface
  App.TempTimer -> TimerTemp;
  App.HumTimer -> TimerHum;

  //Sensor read
  App.TempRead -> TempHumSensorC.TempRead;
  App.HumRead -> TempHumSensorC.HumRead;

  //REdio
  App.SplitControl -> ActiveMessageC;
  App.AMSend -> AMSenderC;
  App.Packet -> AMSenderC;
  
}

