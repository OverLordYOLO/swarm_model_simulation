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


  Drone createDrone(int id) { 
    PVector position = new PVector(random(droneSize, worldSize-droneSize), random(droneSize, worldSize-droneSize));
    PVector velocity = new PVector();
    color droneColor = color(random(255), random(255), random(255));
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

  ArrayList<PVector> Intersect2Circles(PVector A, float a, PVector B, float b ) {
    // A, B = [ x, y ]
    // return = [ Q1, Q2 ] or [ Q ] or [] where Q = [ x, y ]

    /*
  noFill(); 
     stroke(0);
     ellipse(A.x, A.y, 2*a, 2*a);
     ellipse(B.x, B.y, 2*b, 2*b);
     */

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

    fill(255, 2, 2);
    int size = 8;
    rect (Q1x-size/2, Q1y-size/2, size, size);
    rect (Q2x-size/2, Q2y-size/2, size, size);
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

  void ShowSignal() {
    fill(255, 255, 0);
    strokeWeight(0.5);
    stroke(200, 200, 0);
    circle(signalPosition.x, signalPosition.y, signalSize);
  }
}
