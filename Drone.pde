
class Drone {
  PVector position;
  PVector velocity;
  color c;
  boolean stopped;
  int id;
  int size;
  float distance;
  float centerPower, collisionRange, collisionPower, maxSpeed;
  Drone(PVector position, PVector velocity, color c, int id, int size, float centerPower, float collisionRange, float collisionPower, float maxSpeed) {
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

  void moveToPoint(PVector point, float maxDistance, float minDistance, ArrayList<Drone> drones) {
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


  void show() {
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


  float distanceBetweenDrones(Drone drone1, Drone drone2) {  
    return drone1.position.dist(drone2.position);
    // return dist(b1.x, b1.y, b2.x, b2.y);
  }

  void setDistanceToPoint(PVector point) {
    this.distance = position.dist(point);
  }
  void showFoundRadius() {
    stroke(c);
    strokeWeight(0.5);
    noFill();
    circle(position.x, position.y, distance*2);
  }
}
