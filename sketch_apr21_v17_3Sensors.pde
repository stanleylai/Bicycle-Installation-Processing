/********************************************************************************

  Sublime Bicycle Installation Processing
  Serial Server Code
  by Stanley Lai
  for Rachel Law
  
  version 1.7
  21 April 2011
  
  == NOTE ==
  Requires JMCVideo v1.2 Library to function.
  http://www.mat.ucsb.edu/~a.forbes/PROCESSING/jmcvideo/jmcvideo.html
  Requires Minim v2.0.2 to function.
  http://code.compartmental.net/tools/minim/
  
  == Changelog ==
  Updated direction check logic to match whats happening on the bicycle.
  ie. Forwards pedalling is a counter-clockwise motion.
  Audio is played separately on an external audio file.
  Video and Music files should now be located in the data folder. Filenames should
  be named "music.mp3" and "video.mov" respectively.


********************************************************************************/

/********************************************************************************

  == NOTE TO TSU~ ==
  Hello! Here are a list of parameters you can edit below and what they are:
  
  KEY_DEBUG_MODE      -- If 'true', you can use the keyboard inputs 'ASD' to
                         simulate triggering each of the reeds in turn.
                         Set to 'false' if you want to take Arduino input
                         over USB. 
  
  PRINT_DEBUG_MODE    -- If 'true', it will print debug messages to the console.
                         Useful to see how the speed values are responding
                         to input.
  
  FULLSCREEN          -- If 'true', video will start fullscreen.
                         Test it out, but should only be 'true' when its live,
                         so you can look at the console and adjust the settings.
                         Hit the 'ESC' key on the keyboard to quit. Or CMD-Q.
                         DEFAULT VALUE - false
                         
  SCREEN_WIDTH        -- Set to the width of your screen resolution.
                         DEFAULT VALUE - 720
  
  SCREEN_HEIGHT       -- Set to the height of your screen resolution.
                         DEFAULT VALUE - 576
                         
  VIDEO_FPS           -- Set to the frame rate of your video.
                         DEFAULT VALUE - 30
                         
////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////
  DEPRECATED. Place files in the /data folder.
  Music should be named "music.mp3"
  Video should be named "video.mov"
  
  
  MOVIE_LOCATION      -- Edit to point to the location of your video file.
                         Ensure you begin and end with " marks, and a ; at the end.

  MUSIC_LOCATION      -- Edit to point to the location of your music file.
                         Ensure you begin and end with " marks, and a ; at the end.
////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////
  
  SPEED_FACTOR        -- Change this value to make the speed changes more
                         responsive to reed triggers. Higher the value, the
                         more it speeds per reed trigger.
                         DEFAULT VALUE - 4.0
  
  ACCL_EASE_FACTOR    -- Changes the way speed eases up in speed as the cyclist
                         accelerates. The higher the value, the more slowly the
                         video speeds up.
                         DEFAULT VALUE - 60.0
  
  DEACCL_EASE_FACTOR  -- Changes the way speed eases down in speed as the cyclist
                         decelerates. The higher the value, the more slowly
                         the video slows down.
                         DEFAULT VALUE - 180.0
  
  AUDIO_GAIN_FACTOR   -- Changes the way audio is attenuated as pedalling slows
                         down. Higher value means audio gets softer.
                         DEFAULT VALUE - 25;
  
  
********************************************************************************/

// Imports  
import jmcvideo.*;
import processing.opengl.*;
import javax.media.opengl.*;
import fullscreen.*;
import japplemenubar.*;
import processing.serial.*;
import ddf.minim.*;


// Modes
final boolean KEY_DEBUG_MODE = false;     // if set to true, will ignore serial signal input
final boolean PRINT_DEBUG_MODE = true;    // if set to true, will print debug to console
final boolean FULLSCREEN = true;         // if set to true, will start fullscreen


// Serial Inits
Serial serialIO;                          // Serial object for connection to Arduino
final char DATA_REED1 = 'A';              // Signals that Reed 1 is triggered
final char DATA_REED2 = 'C';              // Signals that Reed 2 is triggered
final char DATA_REED3 = 'B';              // Signals that Reed 3 is triggered
final int DATA_FLAG_INDEX = 1;            // Constant for index position of data
final int TX_DELAY = 50;                  // Delay between serial sends. in milliseconds
final int TX_SPEED = 9600;                // Baud speed for serial connection
final int TX_PORT = 1;                    // Index of COM port to use from Serial.list()


// Screen Inits
SoftFullScreen fs;


// Movie Objects, Constants, Vars
JMCMovieGL playbackMovie;
Minim minim;
AudioPlayer audioPlayer;
final int SCREEN_WIDTH = 1280;
final int SCREEN_HEIGHT = 800;
final int VIDEO_FPS = 30;
final String MOVIE_LOCATION = "video.mov";
final String MUSIC_LOCATION = "music.mp3";
int pvw, pvh;                             // OpenGL Video Layer dimensions
float playbackRate;                       // Final processed value that will be used to modify video playback rate


// Vars
int inByte;                               // Container object for serial input data
int reed1Time;                            // Store timing of last time Reed 1 was triggered
int reed2Time;                            // Store timing of last time Reed 2 was triggered
int reed3Time;                            // Store timing of last time Reed 2 was triggered
int lastReedTriggered;                    // Store the last Reed triggered


// Speed Calculation Vars/Constants
final float SPEED_FACTOR = 100;           // Factor for calculating instantaneous speed.
                                          // Increase value for speed to increment more quickly.
final float ACCL_EASE_FACTOR = 30;        // How much easing to be applied on speed changes?
final float DEACCL_EASE_FACTOR = 30;      // How much easing to be applied on speed changes?
final float AUDIO_GAIN_FACTOR = 25;       // How much to attenuate audio when pedalling slows down
float tSpeed;                             // Store target speed value
float cSpeed;                             // Store current speed value
boolean dirForward = true;                // Store direction of pedal





/********************************************************************************
  DO NOT EDIT BEYOND THIS POINT!
  EDITOR BEWARE! WARRANTY VOID!
  - stan.
********************************************************************************/

/********************************************************************************
  Initialization Setup Method
********************************************************************************/
public void setup() {
  // init canvas
  size(SCREEN_WIDTH, SCREEN_HEIGHT, OPENGL);
  frameRate(VIDEO_FPS);
  background(0);
  
  // start fullscreen mode
  if (FULLSCREEN) {
    fs = new SoftFullScreen(this);
    fs.enter();
  } //end if ()
  
  // debug
  println(Serial.list());
  println("===");
  
  // init serial and server objects
  if(!KEY_DEBUG_MODE) { serialIO = new Serial(this, Serial.list()[TX_PORT], TX_SPEED); }
  
  // init music playback
  minim = new Minim(this);
  audioPlayer = minim.loadFile(MUSIC_LOCATION, 1024);
  audioPlayer.play();
  audioPlayer.loop();
  
  // init movie playback
  playbackMovie = movieFromDataPath(MOVIE_LOCATION);
  playbackMovie.loop();
  
  playbackRate = 1.0;
  
  inByte = 0;
  reed1Time = 0;
  reed2Time = 0;
  reed3Time = 0;
  lastReedTriggered = 0;
  
  tSpeed = 0.0;
  cSpeed = 0.0;
} //end setup()





/********************************************************************************
  Main Program Loop
********************************************************************************/
public void draw() {
  
  ////////////////////////////////////////////////
  // from VideoSpeedGL Demo
  // setup OpenGL layer for video playback
  ////////////////////////////////////////////////
  PGraphicsOpenGL pgl = (PGraphicsOpenGL) g;

  GL gl = pgl.beginGL();  
  {
    if (pvw != width || pvh != height)
    {
      background(0);
      gl.glViewport(0, 0, width, height);
      pvw = width;
      pvh = height;
    }
    playbackMovie.centerImage(gl);
  }
  pgl.endGL();
  
  
  ////////////////////////////////////////////////
  // process serial input signals  
  ////////////////////////////////////////////////
  if (!KEY_DEBUG_MODE) {
    if (serialIO.available() > 0) {
      inByte = serialIO.readChar();
    
    } //end if()
  } //end if()
  
  
  ////////////////////////////////////////////////
  // if there are available commands
  // through key input or serial buffer
  ////////////////////////////////////////////////
  if (inByte != 0 && inByte != lastReedTriggered) {
    updateReedTime(inByte);              //update reedTime with current time
    tSpeed = calSpeed(inByte);           //calculate instantaneous speed, and set as Target Speed
    updateDir(inByte);                   //update dirForward according to currently activated reed,
                                         //and update tSpeed accordingly
    
    lastReedTriggered = inByte;          //update current reed as the last triggered one
    
    if(PRINT_DEBUG_MODE) { println("==="); }
  } else {
    tSpeed = 0;
  } //end if()
  
  
  
  updateCSpeed();                        //update Playback Rate
  if(PRINT_DEBUG_MODE) { print("cSpeed : "); println(cSpeed); }
  playbackMovie.setRate(cSpeed);         // Playrate Modification
  updateAudioGain(audioPlayer);
    
    
  inByte = 0;                            // reset value of inByte
  
  
} //end draw()





/********************************************************************************
  'Stop' Event Method
********************************************************************************/

void stop() {
  audioPlayer.close();
  minim.stop();
  super.stop();
}





/********************************************************************************
  JCVideo Event Methods
********************************************************************************/
JMCMovieGL movieFromDataPath(String filename) {
  return new JMCMovieGL(this, filename, RGB);
}
