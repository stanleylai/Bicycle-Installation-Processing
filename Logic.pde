/********************************************************************************
  Helper Methods
********************************************************************************/

///////////////////////////////////////////////////////////
// update reedtime vars with current time 
///////////////////////////////////////////////////////////
public void updateReedTime(int inByte) {
  switch (inByte) {
    case DATA_REED1:
      reed1Time = millis();
    break;
    
    case DATA_REED2:
      reed2Time = millis();
    break;
    
    case DATA_REED3:
      reed3Time = millis();
    break;
  } //end switch()
  
} //end updateReedTime()





///////////////////////////////////////////////////////////
// calculates instantaneous speed
// returns speed value
// inByte - currently activated Reed
///////////////////////////////////////////////////////////
public float calSpeed(int inByte) {
  float delta;              //store timing difference values
  float speed = 0;        //store speed value 
  
  if (inByte != 0) {  
    delta = returnMillis(inByte) - returnMillis(lastReedTriggered);
    if(PRINT_DEBUG_MODE) { print("delta : "); println(delta); }
    
    speed = SPEED_FACTOR*( 120 / delta );
  } //end if()
  
  if(PRINT_DEBUG_MODE) { print("tSpeed : "); println(speed); }
    
  return speed;
  
} //end calSpeed()





///////////////////////////////////////////////////////////
// returns millis value of specified DATA_REED constant
//////////////////////////////////////////////////////////
public int returnMillis(int inByte) {
  int r = 0;
  
  switch(inByte) {
    case DATA_REED1:
        r = reed1Time;
        break;
      
      case DATA_REED2:
        r = reed2Time;
        break;
      
      case DATA_REED3:
        r = reed3Time;
        break;
  } //end switch()
  
  return r;
  
} //end returnMillis()





///////////////////////////////////////////////////////////
// updates directions based on input value and comparing
// with lastReedTriggered. Modify tSpeed accordingly.
//////////////////////////////////////////////////////////
public void updateDir(int inByte) {
  switch(inByte) {
    case DATA_REED1:
      if (lastReedTriggered == DATA_REED3) dirForward = true;
      if (lastReedTriggered == DATA_REED2) dirForward = false;
      break;
    case DATA_REED2:
      if (lastReedTriggered == DATA_REED1) dirForward = true;
      if (lastReedTriggered == DATA_REED3) dirForward = false;
      break;
    case DATA_REED3:
      if (lastReedTriggered == DATA_REED2) dirForward = true;
      if (lastReedTriggered == DATA_REED1) dirForward = false;
      break;
  }
  
  if (dirForward) {
    tSpeed *= -1;
  }
  
  if(PRINT_DEBUG_MODE) { print("dirForward : "); println(dirForward); }
}





///////////////////////////////////////////////////////////
// updates value of Current Speed, so acc/dacc
// is smoother
//////////////////////////////////////////////////////////
public void updateCSpeed() {
  if (tSpeed != 0) { cSpeed = cSpeed + ( (tSpeed - cSpeed)/ACCL_EASE_FACTOR ); };
  if (tSpeed == 0) { cSpeed = cSpeed + ( (tSpeed - cSpeed)/DEACCL_EASE_FACTOR ); };
}





///////////////////////////////////////////////////////////
// updates audio gain according to cSpeed 
//////////////////////////////////////////////////////////
public void updateAudioGain(AudioPlayer iPlayer) {
  float speed = abs(cSpeed);        // Holder value for cSpeed after treated with abs()
  
  if (speed >= 1.0) {
    // if speed is HIGHER then threshold, do not attenuate
    iPlayer.setGain(0.0);
  } else {
    // if speed is LOWER then threshold, then attenuate
    float i = AUDIO_GAIN_FACTOR - (speed * AUDIO_GAIN_FACTOR);
    iPlayer.setGain(-i);
  }
  
}
