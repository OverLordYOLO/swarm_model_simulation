class Simulation {
  int worldSize = 1000;
  int droneCount = 100;

  int droneSize = 3;
  float droneCollisionRange;
  int gatherCircleRadius = ceil(sqrt(droneCount) * droneCollisionRange * 1.2);

  float droneMaxSpeed = 2;

  float droneCenterPower = 0.2;
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
  
  boolean isSuccessful;


  Simulation(int worldSize, int droneCount, int droneSize, float droneCollisionRange, int gatherCircleRadius, int droneMaxSpeed, float droneCenterPower, float droneCollisionPower, int signalError, int tresholdMult, int signalSize, float maxError) {
    this.worldSize = worldSize;
    this.droneCount = droneCount;
    this.droneSize = droneSize;
    this.droneCollisionRange = droneCollisionRange;
    this.gatherCircleRadius = gatherCircleRadius == 0 ? ceil(sqrt(2) * (sqrt(droneCount)*droneCollisionRange)) : gatherCircleRadius;
    this.droneMaxSpeed = droneMaxSpeed;
    this.droneCenterPower = droneCenterPower;
    this.droneCollisionPower = droneCollisionPower;
    this.signalError = signalError;
    this.isFinished = false;
    this.stepNumber = 0;
    this.tresholdMult = tresholdMult;
    this.signalSize = signalSize;
    this.maxError = maxError;
    this.measuredError = -1;

    for (int i = 0; i < droneCount; i = i+1) {
      drones.add(createDrone(i));
    }

    this.signalPosition = new PVector(random(worldSize*2/5, worldSize*4/5), random(worldSize*2/5, worldSize*4/5));
  }


  Drone createDrone(int id) { 
    PVector position = new PVector(random(droneSize, worldSize-droneSize), random(droneSize, worldSize-droneSize));
    PVector velocity = new PVector();
    colorMode(HSB, 255);
    color droneColor = color(random(255), 255, 255);
    colorMode(RGB, 255);
    Drone newDrone = new Drone(position, velocity, droneColor, id, droneSize, droneCenterPower, droneCollisionRange, droneCollisionPower, droneMaxSpeed);
    return newDrone;
  }

  void RunStep() {
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

  void FirstStep_Gathering() {
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

  void SecondStep_LocateSignal() {
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
        Drone curDrone = drones.get(i);
      for (int j = i+1; j < drones.size(); j++) {
        ArrayList<PVector> newIntersections = IntersectTwoCircles(curDrone.position, curDrone.distance, drones.get(j).position, drones.get(j).distance);
        if (newIntersections != null) {
          allIntersections.addAll(newIntersections);
        }
      }
    }
    ShowIntersections(allIntersections);
    ArrayList<PVector> closestCluster = FindCluster(allIntersections); //<>//
    this.measuredError = CalculateMeasuredError(closestCluster);
    for (PVector intersection : closestCluster) {
      fill(0, 0, 255);
      rect (intersection.x, intersection.y, 8, 8);
    }


    stepNumber++;
    snapshot = get();
    isSuccessful = this.measuredError < this.maxError;
  }

  float CalculateMeasuredError(ArrayList<PVector> cluster) {
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

  PVector CalculateAverageDronePosition(ArrayList<Drone> drones) {
    PVector sumPosition = new PVector();
    for (Drone drone : drones) {
      sumPosition.add(drone.position);
    }
    sumPosition.div(drones.size());
    return sumPosition;
  }

  PVector GetPointPositionWithError(PVector point) {
    PVector newVector = PVector.add(point, new PVector(random(-signalError, signalError), random(-signalError, signalError)));
    return newVector;
  }

  // modified code original for JavaScript by wabis: http://walter.bislins.ch/blog/index.asp?page=Schnittpunkte+zweier+Kreise+berechnen+%28JavaScript%29
  ArrayList<PVector> IntersectTwoCircles(PVector posA, float radiusA, PVector posB, float radiusB ) { //<>//
    ArrayList<PVector> newPoints = new ArrayList<PVector>();

    float pointAB0 = posB.x - posA.x;
    float pointAB1 = posB.y - posA.y;
    if (posA.dist(posB) == 0) return null;
    float c = sqrt( pointAB0 * pointAB0 + pointAB1 * pointAB1 );
    if (c == 0) return null;

    float x = (sq(radiusA) + sq(c) - sq(radiusB)) / (2*c);
    float y = sq(radiusA) - sq(x);
    if (y < 0) return null;

    if (y > 0) {
      y = sqrt( y );
    }

    float ex0 = pointAB0 / c;
    float ex1 = pointAB1 / c;
    float ey0 = -ex1;
    float ey1 =  ex0;
    float Q1x = posA.x + x * ex0;
    float Q1y = posA.y + x * ex1;
    float Q2x;
    float Q2y;

    if (y == 0) {
      newPoints.add(new PVector(Q1x, Q1y));
    } else {
      Q2x = Q1x - y * ey0;
      Q2y = Q1y - y * ey1;
      Q1x += y * ey0;
      Q1y += y * ey1;
      newPoints.add(new PVector(Q1x, Q1y));
      newPoints.add(new PVector(Q2x, Q2y));
    }
 //<>//
    return newPoints;
  }

  ArrayList<PVector> FindCluster(ArrayList<PVector> points) {

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

  void ShowIntersections(ArrayList<PVector> positions) {
    for (PVector position : positions) {
      fill(255, 2, 2, 80);
      int size = 8;
      rect (position.x-size/2, position.y-size/2, size, size);
    }
  }

  void ShowSignal() {
    fill(255, 255, 0);
    strokeWeight(0.5);
    stroke(200, 200, 0);
    circle(signalPosition.x, signalPosition.y, signalSize);
  }
}
