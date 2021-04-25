 //<>// //<>// //<>// //<>//
Button startButton, saveCanvasButton, loadSettingsButton, saveDefaultSettingsButton;
ArrayList<Button> allButtons;
boolean startSimulation;

Simulation simulation;

Table settings;

boolean saveScreenshot;

void setup() {
  size(10, 10);
  background(255);
  noStroke();
  smooth();
  saveScreenshot = false;

  settings = CreateDefaultSettings();
  CreateButtons();
  startSimulation = false;
  SetWindowParameters(settings);

  if (!fileExists("settings.txt")) {
    SaveSettings(CreateDefaultSettings());
  }
}

void draw() {
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

void mousePressed() {
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

void SaveScreenshot() {
  String fileName = "canvas_" + day()+"_"+month()+"_"+year()+"_"+hour()+"-"+minute()+"-"+second() + ".png";
  print(fileName);
  saveFrame(fileName);
}

void ShowParameters() {
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

void ShowButtons() {
  startButton.Show();
  saveCanvasButton.Show();
  loadSettingsButton.Show();
  saveDefaultSettingsButton.Show();
}

void CreateButtons() {
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

void PlaceButtons() {
  saveCanvasButton.SetPositionNextToOrUnder(startButton);
  loadSettingsButton.SetPositionNextToOrUnder(saveCanvasButton);
  saveDefaultSettingsButton.SetPositionNextToOrUnder(loadSettingsButton);
}

void CreateNewSimulation() {
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

float GetValueFromSettings(String property) {
  return settings.findRow(property, "property").getFloat("value");
}

Table LoadSettings() {
  Table settings = CreateDefaultSettings();
  Table newSettings = new Table();
  newSettings.addColumn("property");
  newSettings.addColumn("value");
  if (fileExists("settings.txt")) {
    String[] lines = loadStrings("settings.txt");
    for (String line : lines) {
      String[] splitLine = line.split("=");
      float newValue = float(splitLine[1]);
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

Table CreateDefaultSettings() {
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
  settings.setFloat(6, "value", 0.2);
  settings.setString(7, "property", "droneCollisionPower");
  settings.setFloat(7, "value", 0.6); // higher than droneCenterPower
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

void SaveSettings(Table settings) {
  String[] lines = new String[settings.lastRowIndex()+1];
  for (int i = 0; i <= settings.lastRowIndex(); i++) {
    String property = settings.getRow(i).getString("property");
    String value = str(settings.getRow(i).getFloat("value"));
    lines[i] = property + "=" + value;
  }
  saveStrings("settings.txt", lines);
}

boolean fileExists(String fileName) {
  File dataFolder = new File(sketchPath());
  File[] files = dataFolder.listFiles();
  if (files != null) {
    for (File file : files)
      if (file.getName().equals(fileName))
        return true;
  }
  return false;
}

void SetWindowParameters(Table settings) {
  surface.setTitle("Simple drone swarm signal detection simulation");
  int windowSize = int(settings.findRow("worldSize", "property").getFloat("value"));
  surface.setSize(windowSize, windowSize);
  surface.setLocation(10, 10);
  PlaceButtons();
}
