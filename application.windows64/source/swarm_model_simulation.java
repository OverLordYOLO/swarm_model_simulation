import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class swarm_model_simulation extends PApplet {

 //<>// //<>// //<>// //<>//
Button startButton, saveCanvasButton, loadSettingsButton, saveDefaultSettingsButton;
ArrayList<Button> allButtons;
boolean startSimulation;

Simulation simulation;

Table settings;

boolean saveScreenshot;

public void setup() {
  
  background(255);
  noStroke();
  
  saveScreenshot = false;

  settings = CreateDefaultSettings();
  CreateButtons();
  startSimulation = false;
  SetWindowParameters(settings);

  if (!fileExists("settings.txt")) {
    SaveSettings(CreateDefaultSettings());
  }
}

public void draw() {
  background(0);
  if (startSimulation) {
    simulation.RunStep();
  }
  ShowParameters();
  if (saveScreenshot) {
   SaveScreenshot();
   saveScreenshot = false;
  }
  ShowButtons();
}

public void mousePressed() {
  if (startButton.IsHoveringOver()) {
    startSimulation = true;
    CreateNewSimulation();
  } else if (saveCanvasButton.IsHoveringOver()) {
    saveScreenshot = true;
  } else if (loadSettingsButton.IsHoveringOver()) {
    settings = LoadSettings();
    SetWindowParameters(settings);
    for (Button button : allButtons) button.Resize(floor(GetValueFromSettings("buttonFontSize")));
    PlaceButtons();
  } else if (saveDefaultSettingsButton.IsHoveringOver()) SaveSettings(CreateDefaultSettings());
}

public void SaveScreenshot() {
  String fileName = "canvas_" + day()+"_"+month()+"_"+year()+"_"+hour()+"-"+minute()+"-"+second() + ".png";
  print(fileName);
  saveFrame(fileName);
}

public void ShowParameters() {
  if (simulation == null) return;
  int posX = 5;
  int posY = height - 5;
  int fontSize = 15;
  textSize(fontSize);
  fill(57, 255, 20);
  text("Number of drones: " + simulation.droneCount, posX, posY);
  posY -= fontSize + 5;
  text("Gather circle radius: " + simulation.gatherCircleRadius, posX, posY);
  posY -= fontSize + 5;
  text("Maximum error: " + simulation.maxError, posX, posY);
  posY -= fontSize + 5;
  if (simulation.measuredError == 0) text("Measured error: N/A", posX, posY);
  else text("Measured error: " + simulation.measuredError, posX, posY);
}

public void ShowButtons() {
  startButton.Show();
  saveCanvasButton.Show();
  loadSettingsButton.Show();
  saveDefaultSettingsButton.Show();
}

public void CreateButtons() {
  int btnFontSize = floor(GetValueFromSettings("buttonFontSize"));
  startButton = new Button(10, 10, btnFontSize,  color(10, 220, 10), color(20, 255, 20), color(15), "Re/Start");
  saveCanvasButton = new Button(10, 10, btnFontSize, color(150), color(200), color(15), "Save canvas");
  loadSettingsButton = new Button(10, 10, btnFontSize, color(150), color(200), color(15), "Load settings");
  saveDefaultSettingsButton = new Button(10, 10, btnFontSize, color(150), color(200), color(15), "Save default settings");
  allButtons = new ArrayList<Button>();
  allButtons.add(startButton);
  allButtons.add(saveCanvasButton);
  allButtons.add(loadSettingsButton);
  allButtons.add(saveDefaultSettingsButton);
  PlaceButtons();
}

public void PlaceButtons() {
  saveCanvasButton.SetPositionNextToOrUnder(startButton);
  loadSettingsButton.SetPositionNextToOrUnder(saveCanvasButton);
  saveDefaultSettingsButton.SetPositionNextToOrUnder(loadSettingsButton);
}

public void CreateNewSimulation() {
  simulation = new Simulation(
    round(GetValueFromSettings("worldSize")), 
    round(GetValueFromSettings("droneCount")), 
    round(GetValueFromSettings("droneSize")), 
    GetValueFromSettings("droneCollisionRange"), 
    round(GetValueFromSettings("gatherCircleRadius")), 
    round(GetValueFromSettings("droneMaxSpeed")), 
    GetValueFromSettings("droneCenterPower"), 
    GetValueFromSettings("droneCollisionPower"), 
    round(GetValueFromSettings("signalError")), 
    round(GetValueFromSettings("tresholdMult")), 
    round(GetValueFromSettings("signalSize")), 
    GetValueFromSettings("maxError"));
}

public float GetValueFromSettings(String property) {
  return settings.findRow(property, "property").getFloat("value");
}

public Table LoadSettings() {
  Table settings = CreateDefaultSettings();
  Table newSettings = new Table();
  newSettings.addColumn("property");
  newSettings.addColumn("value");
  if (fileExists("settings.txt")) {
    String[] lines = loadStrings("settings.txt");
    for (String line : lines) {
      String[] splitLine = line.split("=");
      float newValue = PApplet.parseFloat(splitLine[1]);
      if (splitLine.length > 1 & !(newValue != newValue)) { // second check if NaN (weird processing thing)
        TableRow oldRow = settings.findRow(splitLine[0], "property"); // <---------------------------------------------------------------- what if the row does not exist???
        if (oldRow != null) {
          TableRow newRow = newSettings.addRow();
          newRow.setString("property", splitLine[0]);
          newRow.setFloat("value", newValue);
        }
      }
    }
    for (int i = 0; i <= settings.lastRowIndex(); i++) {
      TableRow oldRow = settings.getRow(i);
      String property = oldRow.getString("property");
      TableRow row = newSettings.findRow(property, "property");
      if (row == null) {
        newSettings.addRow(oldRow);
      }
    }
  } else {
    SaveSettings(settings);
  }
  SetWindowParameters(settings);
  return newSettings;
}

public Table CreateDefaultSettings() {
  Table settings = new Table();
  settings.addColumn("property");
  settings.addColumn("value");
  int rowCount = 10;
  for (int i = 0; i < rowCount; i++) settings.addRow();
  settings.setString(0, "property", "worldSize");
  settings.setFloat(0, "value", 1000);
  settings.setString(1, "property", "droneCount");
  settings.setFloat(1, "value", 10);
  settings.setString(2, "property", "droneSize");
  settings.setFloat(2, "value", 5);
  settings.setString(3, "property", "droneCollisionRange");
  settings.setFloat(3, "value", 100);
  settings.setString(4, "property", "gatherCircleRadius");
  settings.setFloat(4, "value", 320); // sqrt(droneCount) * 1.2 * droneCollisionRange
  settings.setString(5, "property", "droneMaxSpeed");
  settings.setFloat(5, "value", 2);
  settings.setString(6, "property", "droneCenterPower");
  settings.setFloat(6, "value", 0.2f);
  settings.setString(7, "property", "droneCollisionPower");
  settings.setFloat(7, "value", 0.6f); // higher than droneCenterPower
  settings.setString(8, "property", "signalError");
  settings.setFloat(8, "value", 5);
  settings.setString(9, "property", "tresholdMult");
  settings.setFloat(9, "value", 3);
  settings.setString(10, "property", "signalSize");
  settings.setFloat(10, "value", 20);
  settings.setString(11, "property", "maxError");
  settings.setFloat(11, "value", 10);
  settings.setString(12, "property", "buttonFontSize");
  settings.setFloat(12, "value", 20);

  return settings;
}

public void SaveSettings(Table settings) {
  String[] lines = new String[settings.lastRowIndex()+1];
  for (int i = 0; i <= settings.lastRowIndex(); i++) {
    String property = settings.getRow(i).getString("property");
    String value = str(settings.getRow(i).getFloat("value"));
    lines[i] = property + "=" + value;
  }
  saveStrings("settings.txt", lines);
}

public boolean fileExists(String fileName) {
  File dataFolder = new File(sketchPath());
  File[] files = dataFolder.listFiles();
  if (files != null) {
    for (File file : files)
      if (file.getName().equals(fileName))
        return true;
  }
  return false;
}

public void SetWindowParameters(Table settings) {
  surface.setTitle("Simple drone swarm signal detection simulation");
  int windowSize = PApplet.parseInt(settings.findRow("worldSize", "property").getFloat("value"));
  surface.setSize(windowSize, windowSize);
  surface.setLocation(10, 10);
  PlaceButtons();
}
class Button { //<>// //<>//

  int padding = 5;
  int posX, posY, wid, hei, textX, textY, textSize;
  int col, colHighlight, colText;
  String text;

  Button(int posX, int posY, int textSize, int col, int colHighlight, int colText, String text) {
    this.posX = posX;
    this.posY = posY;
    this.col = col;
    this.colHighlight = colHighlight;
    this.colText = colText;
    textSize(textSize);
    this.text = text;
    this.textSize = textSize;
    calculateParameters();
  }

  public void calculateParameters() {
    this.textX = posX + padding;
    this.textY = posY + textSize + padding;
    textSize(textSize);
    this.wid = (ceil(textWidth(text)) + padding * 2);
    this.hei = textSize + 2 * padding;
  }

  public Button SetPositionNextToOrUnder(Button button) {
    int x = button.posX + button.wid + 20;
    int y = button.posY;
    if ((x + wid) > width) {
      x = 10;
      y = button.posY + hei + 10;
    }
    posX = x;
    posY = y;
    calculateParameters();
    return this;
  }

  public void Resize(int size) {
    this.textSize = size;
    calculateParameters();
  }

  public void Show() {
    if (IsHoveringOver()) {
      fill(colHighlight);
    } else {
      fill(col);
    }
    rect(posX, posY, wid, hei);

    fill(colText);
    textSize(textSize);
    text(text, textX, textY);
  }

  public boolean IsHoveringOver() {
    return mouseOverRectangle(posX, posY, wid, hei);
  }
  public boolean mouseOverRectangle(int x, int y, int width, int height) {
    return mouseX <= x+width && mouseX >= x && 
      mouseY <= y+height && mouseY >= y;
  }
}

class Drone {
  PVector position;
  PVector velocity;
  int c;
  boolean stopped;
  int id;
  int size;
  float distance;
  float centerPower, collisionRange, collisionPower, maxSpeed;
  Drone(PVector position, PVector velocity, int c, int id, int size, float centerPower, float collisionRange, float collisionPower, float maxSpeed) {
    this.position = position;
    this.velocity = velocity;
    this.c=c;
    this.id = id;
    this.size = size;
    this.centerPower = centerPower;
    this.collisionRange = collisionRange;
    this.collisionPower = collisionPower;
    this.maxSpeed = maxSpeed;
    stopped = false;
  }

  public void moveToPoint(PVector point, float maxDistance, float minDistance, ArrayList<Drone> drones) {
    float distance = point.dist(position);

    stopped = distance <= ((maxDistance - minDistance) / 2);
    boolean isColliding = false;
    boolean moveTowards = stopped ? distance > maxDistance : true;
    boolean moveAway = stopped ? distance < minDistance : false;

    if (moveTowards) {
      velocity.add(PVector.sub(point, position).setMag(centerPower));
    } else if (moveAway) {
      velocity.sub(PVector.sub(point, position).setMag(centerPower));
    } else {
      velocity.setMag(0);
    }

    for (Drone i : drones) {
      PVector sumPosition = new PVector();
      if (distanceBetweenDrones(this, i) < collisionRange && i.id != this.id) {
        sumPosition.add(PVector.sub(i.position, position));
        isColliding = true;
      }
      sumPosition.mult(collisionPower);
      velocity.sub(sumPosition);
    } 
    velocity.limit(maxSpeed);
    position.add(velocity);
    stopped = !moveTowards & !moveAway & !isColliding;
  }


  public void show() {
    beginShape();
    stroke(2);
    line(position.x-size, position.y-size, position.x+size, position.y+size);
    line(position.x-size, position.y+size, position.x+size, position.y-size);
    noStroke();
    fill(c);
    circle(position.x, position.y, size); // body
    circle(position.x-size, position.y-size, size/2); // top left rotor

    circle(position.x-size, position.y+size, size/2); // bottom left rotor

    circle(position.x+size, position.y-size, size/2); // top right rotor

    circle(position.x+size, position.y+size, size/2); // bottom right rotor
    endShape();
  }


  public float distanceBetweenDrones(Drone drone1, Drone drone2) {  
    return drone1.position.dist(drone2.position);
    // return dist(b1.x, b1.y, b2.x, b2.y);
  }
  public float angleBetween(Drone b1, Drone b2) { 
    return PVector.angleBetween(b1.velocity, b2.velocity);
  }

  public void setDistanceToPoint(PVector point) {
    this.distance = position.dist(point);// * 2;
  }
  public void showFoundRadius() {
    stroke(c);
    strokeWeight(0.5f);
    noFill();
    circle(position.x, position.y, distance*2);
  }
}
class Simulation {
  int worldSize = 1000;
  int droneCount = 100;

  int droneSize = 3;
  float droneCollisionRange;
  int gatherCircleRadius = ceil(sqrt(droneCount) * droneCollisionRange * 1.2f);

  float droneMaxSpeed = 2;

  float droneCenterPower = 0.2f;
  float droneCollisionPower = droneCenterPower*2;//0.42;

  ArrayList<Drone> drones = new ArrayList<Drone>(); 

  PVector signalPosition;
  int signalError;
  int signalSize;

  boolean isFinished;
  int stepNumber;

  int tresholdMult;

  PImage snapshot;

  float maxError;
  float measuredError;


  Simulation(int worldSize, int droneCount, int droneSize, float droneCollisionRange, int gatherCircleRadius, int droneMaxSpeed, float droneCenterPower, float droneCollisionPower, int signalError, int tresholdMult, int signalSize, float maxError) {
    this.worldSize = worldSize;
    this.droneCount = droneCount;
    this.droneSize = droneSize;
    this.droneCollisionRange = droneCollisionRange;
    this.gatherCircleRadius = gatherCircleRadius;
    this.droneMaxSpeed = droneMaxSpeed;
    this.droneCenterPower = droneCenterPower;
    this.droneCollisionPower = droneCollisionPower;
    this.signalError = signalError;
    this.isFinished = false;
    this.stepNumber = 0;
    this.tresholdMult = tresholdMult;
    this.signalSize = signalSize;
    this.maxError = maxError;
    this.measuredError = 0;

    for (int i = 0; i < droneCount; i = i+1) {
      drones.add(createDrone(i));
    }

    this.signalPosition = new PVector(random(worldSize*2/5, worldSize*4/5), random(worldSize*2/5, worldSize*4/5));
  }


  public Drone createDrone(int id) { 
    PVector position = new PVector(random(droneSize, worldSize-droneSize), random(droneSize, worldSize-droneSize));
    PVector velocity = new PVector();
    colorMode(HSB, 255);
    int droneColor = color(random(255), 255, 255);
    colorMode(RGB, 255);
    Drone newDrone = new Drone(position, velocity, droneColor, id, droneSize, droneCenterPower, droneCollisionRange, droneCollisionPower, droneMaxSpeed);
    return newDrone;
  }

  public void RunStep() {
    switch (stepNumber) {
    case 0:
      FirstStep_Gathering();
      break;
    case 1: 
      SecondStep_LocateSignal();
      isFinished = true;
      break;
    default:
      image(snapshot, 0, 0);
    }
  }

  public void FirstStep_Gathering() {
    PVector averagePosition = CalculateAverageDronePosition(drones);
    for (Drone drone : drones) {
      drone.moveToPoint(new PVector(averagePosition.x, averagePosition.y), gatherCircleRadius, 0, drones);
      drone.show();
    }
    boolean moving = false;
    for (Drone drone : drones) {
      moving = moving || !drone.stopped;
    }

    if (!moving) {
      stepNumber++;
    }
  }

  public void SecondStep_LocateSignal() {
    ShowSignal();
    fill(0, 255, 0);

    for (Drone drone : drones) {
      drone.setDistanceToPoint(GetPointPositionWithError(signalPosition));
    }
    for (Drone drone : drones) {
      drone.showFoundRadius();
      drone.show();
    }
    ArrayList<PVector> allIntersections = new ArrayList<PVector>();
    for (int i = 0; i < drones.size() -1; i++) {
      for (int j = i+1; j < drones.size(); j++) {
        ArrayList<PVector> newIntersections = Intersect2Circles(drones.get(i).position, drones.get(i).distance, drones.get(j).position, drones.get(j).distance);
        if (newIntersections != null) {
          allIntersections.addAll(newIntersections);
        }
      }
    }
    ArrayList<PVector> closestCluster = FindCluster(allIntersections);
    for (PVector intersection : closestCluster) {
      fill(0, 0, 255);
      rect (intersection.x, intersection.y, 8, 8);
    }
    
    measuredError = CalculateMeasuredError(closestCluster);

    stepNumber++;
    snapshot = get();
  }

  public float CalculateMeasuredError(ArrayList<PVector> cluster) {
    float error = 0;        
    PVector sumPosition = new PVector();
    for (PVector intersection : cluster) {
      sumPosition.add(intersection);
      fill(0, 0, 255);
      rect (intersection.x, intersection.y, 8, 8);
    }
    sumPosition.div(cluster.size());
    error = sumPosition.dist(signalPosition);
    return error;
  }

  public PVector CalculateAverageDronePosition(ArrayList<Drone> drones) {
    PVector sumPosition = new PVector();
    for (Drone drone : drones) {
      sumPosition.add(drone.position);
    }
    sumPosition.div(drones.size());
    return sumPosition;
  }

  public PVector GetPointPositionWithError(PVector point) {
    PVector newVector = PVector.add(point, new PVector(random(-signalError, signalError), random(-signalError, signalError)));
    return newVector;
  }

  public ArrayList<PVector> Intersect2Circles(PVector A, float a, PVector B, float b ) {

    float AB0 = B.x - A.x;
    float AB1 = B.y - A.y;

    float c = sqrt( AB0 * AB0 + AB1 * AB1 );
    if (c == 0) {
      // same center: A = B
      return null;
    }

    float x = (a*a + c*c - b*b) / (2*c);
    float y = a*a - x*x;
    if (y < 0) {
      // no intersection
      return null;
    }
    if (y > 0) 
      y = sqrt( y );

    // compute unit vectors ex and ey
    float ex0 = AB0 / c;
    float ex1 = AB1 / c;
    float ey0 = -ex1;
    float ey1 =  ex0;
    float Q1x = A.x + x * ex0;
    float Q1y = A.y + x * ex1;

    ArrayList<PVector> newPoints = new ArrayList<PVector>();
    if (y == 0) {
      // one touch point
      newPoints.add(new PVector(Q1x, Q1y));
    }

    // two intersections
    float Q2x = Q1x - y * ey0;
    float Q2y = Q1y - y * ey1;
    Q1x += y * ey0;
    Q1y += y * ey1;
    newPoints.add(new PVector(Q1x, Q1y));
    newPoints.add(new PVector(Q2x, Q2y));

    fill(255, 2, 2, 80);
    int size = 8;
    rect (Q1x-size/2, Q1y-size/2, size, size);
    rect (Q2x-size/2, Q2y-size/2, size, size);
    return newPoints;
  }

  public ArrayList<PVector> FindCluster(ArrayList<PVector> points) {

    //1. define a treshold - 3*error
    float treshold = signalError * tresholdMult;
    //2. calculate distance between points and save points to clusters with points in close proximity (treshold)
    ArrayList<PVector> biggestCluster = new ArrayList<PVector>();
    for (int i = 0; i < points.size() -1; i++) {
      ArrayList<PVector> cluster = new ArrayList<PVector>();
      cluster.add(points.get(i));
      for (int j = i+1; j < points.size(); j++) {
        if (points.get(i).dist(points.get(j)) <= treshold) {
          cluster.add(points.get(j));
        }
      }
      if (cluster.size() > biggestCluster.size()) {
        biggestCluster = cluster;
      }
    }
    return biggestCluster;
  }

  public void ShowSignal() {
    fill(255, 255, 0);
    strokeWeight(0.5f);
    stroke(200, 200, 0);
    circle(signalPosition.x, signalPosition.y, signalSize);
  }
}

  public void settings() {  size(10, 10);  smooth(); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "swarm_model_simulation" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
