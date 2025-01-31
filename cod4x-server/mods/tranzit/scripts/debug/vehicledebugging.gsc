#include scripts\_include;

//did not get this debug to calculate the times correctly
CalculateSpeedBehaviour()
{
	debugInfo = spawnStruct();
	debugInfo.timeStep = 0.1; //same value as used in the vehicleThink() loop
	debugInfo.timeTotal = 0;
	debugInfo.timeDriven = 0;
	debugInfo.timeStopped = 0;
	debugInfo.speed = 0;
	debugInfo.totalDist = 0;
	
	//copy the settings from the vehicle
	minSpeed = self.movementInfo.minSpeed;
	maxSpeed = self.movementInfo.maxSpeed;
	accel = self.movementInfo.accel / debugInfo.timeStep;
	decel = self.movementInfo.decel / debugInfo.timeStep;

	//copy the vehicle path and add the start point as final path node
	debugInfo.path = level.tranzitPath;
	debugInfo.path[debugInfo.path.size] = level.tranzitPath[0];

	speedbehaviour = spawnStruct();
	speedbehaviour.accel = [];
	speedbehaviour.decel = [];
	speedbehaviour.maxSpeed = [];
	speedAtNode = 0;
	for(i=0;i<(debugInfo.path.size -1);i++)
	{
		curPos = debugInfo.path[i];
		target = debugInfo.path[i+1];
		speedbehaviour.distToTarget[i] = Distance(curPos.origin, target.origin);
		
		//calculate the maximum possible speed for this movement
		//the vehicle has to accelerate and decelertate (if there is a distance left then this is driven at max speed)
		speedbehaviour.accel[i] = spawnStruct();
		speedbehaviour.accel[i].dist = 0;
		speedbehaviour.accel[i].time = 0;
		speedbehaviour.decel[i] = spawnStruct();
		speedbehaviour.decel[i].dist = 0;
		speedbehaviour.decel[i].time = 0;
		speedbehaviour.maxSpeed[i] = spawnStruct();
		
		//only calculate an acceleration when the current speed is not the maximum
		//and the vehicle has not to decelertate
		if(speedAtNode < maxSpeed && (!isDefined(target.script_wait) || target.script_wait <= 0))
		{
			speedbehaviour.accel[i].dist = sqr(maxSpeed) / (2*accel);
			speedbehaviour.accel[i].time = sqrt(2*speedbehaviour.accel[i].dist / accel);
			
			speedAtNode += (speedbehaviour.accel[i].time * accel);
		}
		
		//vehicle has to stop at the target
		if(target.script_wait > 0)
		{
			speedbehaviour.decel[i].dist = sqr(maxSpeed) / (2*decel);
			speedbehaviour.decel[i].time = sqrt(2*speedbehaviour.decel[i].dist / decel);
		}
		//vehicle has to slow down
		else if(target.speed < curPos.speed)
		{
			speedbehaviour.decel[i].dist = sqr(target.speed) / (2*decel);
			speedbehaviour.decel[i].time = sqrt(2*speedbehaviour.decel[i].dist / decel);
			
			speedAtNode -= (speedbehaviour.decel[i].time * decel);
		}
		//vehicle can pass the target without decelertation = nothing to do
		else
		{
			speedAtNode = maxSpeed;
		}
		
		speedbehaviour.maxSpeed[i].dist = speedbehaviour.distToTarget[i] - speedbehaviour.accel[i].dist - speedbehaviour.decel[i].dist;
		
		//enough space to drive with max speed
		if(speedbehaviour.maxSpeed[i].dist > 0)
		{
			posMaxSpeed = maxSpeed;
			speedbehaviour.maxSpeed[i].time = speedbehaviour.maxSpeed[i].dist / posMaxSpeed;
		}
		//not enough space to drive with max speed
		else if(speedbehaviour.maxSpeed[i].dist < 0)
		{
			//calculate the maximum possible speed by 'faking' a distance of 1 unit
			posMaxSpeed = sqrt(speedbehaviour.distToTarget[i] / ((1/(2*accel)) + (1/(2*accel))));
		
			if(i == 130)
				consolePrint("^1XXX dist " + speedbehaviour.distToTarget[i] + " speedAtNode " + speedAtNode + " posMaxSpeed " + posMaxSpeed + " -> " + (speedAtNode-posMaxSpeed) + " to fast\n");
		
			//vehicle has to decelertate before reaching its maximum speed
			if(speedAtNode < posMaxSpeed)
			{
				speedbehaviour.accel[i].dist = sqr(posMaxSpeed) / (2*accel);
				speedbehaviour.accel[i].time = sqrt(2*speedbehaviour.accel[i].dist / accel);
				
				speedbehaviour.decel[i].dist = sqr(posMaxSpeed) / (2*decel);
				speedbehaviour.decel[i].time = sqrt(2*speedbehaviour.decel[i].dist / decel);
				
				speedbehaviour.maxSpeed[i].dist = speedbehaviour.distToTarget[i] - speedbehaviour.accel[i].dist - speedbehaviour.decel[i].dist;
				speedbehaviour.maxSpeed[i].time = speedbehaviour.maxSpeed[i].dist / posMaxSpeed;
				
				speedAtNode = posMaxSpeed;
			}
			//vehicle is to fast and there is not enough space to decelertate to zero
			else
			{
				//fix the last calculated time and dist to start decelertion in the previous subpath
				speedbehaviour.decel[i-1].dist += sqr((speedAtNode-posMaxSpeed)) / (2*decel);
				speedbehaviour.decel[i-1].time += sqrt(2*speedbehaviour.decel[i].dist / decel);
				
				speedbehaviour.maxSpeed[i-1].dist = speedbehaviour.distToTarget[i-1] - speedbehaviour.accel[i-1].dist - speedbehaviour.decel[i-1].dist;
				speedbehaviour.maxSpeed[i-1].time = speedbehaviour.maxSpeed[i-1].dist / posMaxSpeed;
				
				//calculate the final decelertion
				speedbehaviour.decel[i].dist = speedbehaviour.distToTarget[i];
				speedbehaviour.decel[i].time = sqrt(2*speedbehaviour.decel[i].dist / decel);
				
				speedbehaviour.maxSpeed[i].dist = speedbehaviour.distToTarget[i] - speedbehaviour.accel[i].dist - speedbehaviour.decel[i].dist;
				speedbehaviour.maxSpeed[i].time = speedbehaviour.maxSpeed[i].dist / posMaxSpeed;
			}
		}
	}
	
	for(i=0;i<(debugInfo.path.size -1);i++)
	{
		debugInfo.timeDriven += speedbehaviour.accel[i].time;
		debugInfo.timeDriven += speedbehaviour.decel[i].time;
		debugInfo.timeDriven += speedbehaviour.maxSpeed[i].time;
		
		debugInfo.totalDist += speedbehaviour.accel[i].dist;
		debugInfo.totalDist += speedbehaviour.decel[i].dist;
		debugInfo.totalDist += speedbehaviour.maxSpeed[i].dist;

		if(debugInfo.path[i+1].script_wait > 0)
		{
			debugInfo.timeTotal = debugInfo.timeStopped + debugInfo.timeDriven;
			consolePrint("Stop at " + (i+1) + " reached after: " + debugInfo.timeTotal + "\n");
		
			if(debugInfo.path[i+1] != debugInfo.path[0])
			{
				delay = debugInfo.path[i+1].script_wait;
				if(!isDefined(delay) || delay > 30)
					delay = 30;
				
				debugInfo.timeStopped += delay;
			}
		}
	}
	
	debugInfo.timeTotal = debugInfo.timeStopped + debugInfo.timeDriven;
	
	consolePrint("Calculated total drive time: " + debugInfo.timeTotal + " (driven: " + debugInfo.timeDriven + ", stopped: " + debugInfo.timeStopped + ") dist: " + debugInfo.totalDist  + "\n");
}