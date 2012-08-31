
import processing.video.*;

String inputFilename;

Movie vid = null;    // if movie
PImage img = null;   // if image
String []imgNames = null;  // image names
int inputWidth;
int inputHeight;

int videoFrame = 0;
float videoFPS = 30.0;
float videoDuration;
int numFrames;

//int videoDisplayScale = 1;
//int pixelSize = 1;

//boolean doAtStartup = false;
boolean imageSaved = false;

int sectionToDraw = 0;

boolean useMask = true;
Section []sections = new Section[14];

PFont font;

float startTime;


void loadVideo() {
  vid = null;
  img = null;
  imgNames = null;
  videoFrame = 0;
  videoDuration = 0;
  numFrames = 0;
  imageSaved = false;

  // choose file
  String inputPath = selectInput("Choose UV Texture video");

  if (inputPath != null) {
    // get Filename
    String[] inputPathParts = split(inputPath, '/');
    inputFilename = inputPathParts[inputPathParts.length-2] + "/" + inputPathParts[inputPathParts.length-1];

    // remove extension
    String[] videoFileParts = split(inputFilename, '.');
    inputFilename = videoFileParts[0];

    println("loading video: \n" + inputPath);
    vid = new Movie(this, inputPath);
    if (vid == null) {
      println("*** could not load video ***");
      exit();
      return;
    }
    vid.play();
    vid.read();
    vid.pause();
    inputWidth = vid.width;
    inputHeight = vid.height;

    numFrames = (int)(vid.duration() * videoFPS);  // hack for now, how to get actual fps or number of frames?
  } 
  else {
    inputPath = selectFolder("Choose UV Texture image sequence folder");
    if (inputPath == null) {
      exit();
      return;
    }

    // get Filename
    String[] inputPathParts = split(inputPath, '/');
    inputFilename = inputPathParts[inputPathParts.length-1];

    // get file list    
    File file = new File(inputPath);
    imgNames = file.list();
    for (int i=0; i<imgNames.length; i++) {
      imgNames[i] = inputPath + "/" + imgNames[i];
    }

    // check dimensions
    img = loadImage(imgNames[0]);
    inputWidth = img.width;
    inputHeight = img.height;

    numFrames = imgNames.length;
  } 

  videoDuration = numFrames / videoFPS;

  // check dimensions
  if (inputWidth != sections[0].imgMask.width || inputHeight != sections[0].imgMask.height) {
    println("Input size does not match mask!:" + inputWidth + " vs " + sections[0].imgMask.width + " x " + inputHeight + " vs " + sections[0].imgMask.height);
    exit();
    return;
  }




  // create output images
  for (int i=0; i<sections.length; i++) sections[i].initImage(numFrames);

  startTime = millis() * 0.001;
}


void setup() {
  size((int)(screen.width), (int)(screen.height*0.9), P2D);

  // load and set font
  font = loadFont("SansSerif-12.vlw");
  textFont(font);

  // init sections
  for (int i=0; i<sections.length; i++) sections[i] = new Section(i);

  // load video
  loadVideo();
}



void getFrame(color[] pixels) {
  for (int k=0; k<sections.length; k++) sections[k].updateImageFromVideo(pixels);
}


void draw() {
  background(70);
  smooth();

  tint(255);
  if (videoFrame < numFrames) {
    if (vid != null) {
      vid.jump(videoFrame / videoFPS);
      vid.read();

      vid.loadPixels();
      getFrame(vid.pixels);
      image(vid, 0, 0, 256, 256);
    } 
    else {
      // use image sequence
      img = loadImage(imgNames[videoFrame]);
      if (img != null) {
        img.loadPixels();
        getFrame(img.pixels);
        image(img, 0, 0, 256, 256);
      } 
      else {
        println("Could not load image: " + imgNames[videoFrame]);
      }
    }
  } 
  else {
    if (imageSaved == false) {
      imageSaved = true;
      saveImage();
      println(str((millis()*0.001 - startTime)) + " seconds");
      //      exit();
      //      return;
    }
  }

  //    for (int i=0; i<vid.width; i++) {
  //      for (int j=0; j<vid.height; j++) {
  //        color c = vid.get(i, j);
  //        fill(c);
  //        rect(i*videoDisplayScale + vid.width + 10, j*videoDisplayScale, videoDisplayScale, videoDisplayScale);
  //      }
  //    }

  if (sectionToDraw == 0 ) {
    for (int k=0; k<sections.length; k++) {
      sections[k].draw((inputWidth + 10) * k, inputHeight + 10, inputWidth);
    }
  }
  else {
    sections[sectionToDraw-1].draw(0, inputHeight + 10, width);
  }


  fill(255);
  String s = inputFilename + "\n";
  s += "duration: " + str(videoDuration) + "\n";
  s += "frame: " + str(videoFrame) + " / " + str(numFrames) + "\n";
  s += "elapsed time: " + str(millis()*0.001 - startTime) + "\n";
  s += "input: " + inputWidth + "x" + inputHeight + "\n";
  for (int k=0; k<sections.length; k++) {
    s+= "output " + str(k+1) + " : " + sections[k].imgOut.width + "x" + sections[k].imgOut.height + "\n";
  }
  text(s, inputWidth + 20, 20);

  if (videoFrame<numFrames) videoFrame++;
}


void saveImage() {
  String timeStamp = str(year()) + "." + str(month()) + "." + str(day()) + "_" + str(hour()) + "." + str(minute()) + "." + str(second());
  for (int i=0; i<sections.length; i++) sections[i].saveImage(timeStamp);
}



void keyPressed() {
  switch(key) {
  case 'l':
    loadVideo();
    break;
  case 's': 
    saveImage(); 
    break;
  case '0':
    sectionToDraw = 0;
    break;
  case '1':
    sectionToDraw = 1;
    break;
  case '2':
    sectionToDraw = 2;
    break;
  case '3':
    sectionToDraw = 3;
    break;
  case '4':
    sectionToDraw = 4;
    break;
  case '5':
    sectionToDraw = 5;
    break;
  case '6':
    sectionToDraw = 6;
    break;
  case '7':
    sectionToDraw = 7;
    break;
  }
}


//------------------------------------------

class Section {
  PImage imgMask;
  PImage imgOut;
  int numLeds;
  int index;
  int pixelCounter = 0;


  Section(int k) {
    index = k+1;
    String maskFilename = "masks/Section" + str(index) + ".png";
    imgMask = loadImage(maskFilename);
    numLeds = 0;
    for (int i=0; i<imgMask.width; i++) {
      for (int j=0; j<imgMask.height; j++) {
        if (brightness(imgMask.get(i, j)) > 0) numLeds++;
      }
      numLeds += 4;  // add an extra PCB at the end of each strip  SPACING
    }
    numLeds += 10 * 4;  // add 10 extra PCBs at end of each section SPACING
    println("Loading mask " + str(index) + ": " + maskFilename + " numLeds: " + numLeds);
  }


  void initImage(int numFrames) {
    imgOut = createImage(numLeds, numFrames, RGB);
  }



  boolean checkAndAddPixel(int videoFrame, color col, int i, int j) {
    boolean doPixel = true;
    if (useMask && brightness(imgMask.pixels[j*imgMask.width + i]) == 0) doPixel = false;
    if (doPixel) addPixel(videoFrame, col);
    return doPixel;
  }

  void addPixel(int videoFrame, color col) {
    imgOut.pixels[videoFrame * imgOut.width + pixelCounter] = col;
    pixelCounter++;
  }

  void updateImageFromVideo(color[] pixels) {
    imgOut.loadPixels();
    imgMask.loadPixels();
    pixelCounter = 0;

    for (int i=0; i<inputWidth; i+=2) {
      boolean stripExists = false;
      for (int j=inputHeight-2; j>=0; j-=2) {
        for(int si=0; si<2; si++) {
          for(int sj=0; sj<2; sj++) {
            int x = i+si;
            int y = j+sj;
            stripExists |= checkAndAddPixel(videoFrame, pixels[y*inputWidth+x], x, y);
          }
        }
      }
      if (stripExists) for (int c=0; c<4; c++) addPixel(videoFrame, color(0, 0, 0));  // SPACING
    }

    imgOut.updatePixels();
  }

  void saveImage(String timeStamp) {
    if (imgOut == null) {
      println("Section::saveImage: Image not allocated");
      return;
    }

    String s = "out/";
    //    s+= inputFilename + "/";
    //    s+= timeStamp + "/";
    s+= "section" + str(index) + "/" + inputFilename + ".bmp";
    imgOut.save(s);
    println("Section::saveImage #" + str(index) + ": " + s);
  }

  void draw(int x, int y, int w) {
    image(imgMask, x, y);
    int h = w * imgOut.height / imgOut.width;
    image(imgOut, x, y + imgMask.height + 10, w, h);
  }
};

