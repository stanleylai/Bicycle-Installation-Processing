/********************************************************************************
  Key Debug Methods
********************************************************************************/

// key press ASD simulate REED123 hits. for debug.
public void keyPressed() {
  if (KEY_DEBUG_MODE) {
    if (key == 'A' || key == 'a') inByte = DATA_REED1;
    if (key == 'S' || key == 's') inByte = DATA_REED2;
    if (key == 'D' || key == 'd') inByte = DATA_REED3;
  } //end if()

} //end keyPressed()
