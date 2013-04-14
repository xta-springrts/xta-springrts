// Author: Deadnight Warrior
// 
// Notes: Use this script if you want to make ships/water units rock on waves
//	  This script works only with SpringRTS engine 0.82 and newer
//	  unit must have WindGenerator>0 tag in unit definitions set for this script to work
//
// Example usage:
// static-var windDirection,windSteady;	// determine wind direction and wind change
// #define ROCK_AMPLITUDE	<1.2>	// max 1.2 deg turn around an axis
// #define ROCK_SPEED		<1.4>	// 1.4 deg/s
// #define ROCK_PIECE  groundplate	// rock unit around "groundplate" piece
// ...
// #include "XTA_RockOnWaves.h"
// ...
// start-script RockOnWaves();
// ...

#ifdef ROCK_AMPLITUDE
#ifdef ROCK_SPEED
#ifdef ROCK_PIECE

SetDirection(heading)
{
	windDirection = heading;
	windSteady = 0;	
}

RockOnWaves(x,z,xs,zs)
{
	while(1){
		x= ROCK_AMPLITUDE * get KCOS(windDirection) / 1024;
		z= ROCK_AMPLITUDE * get KSIN(windDirection) / 1024;
		xs= get ABS(x) * ROCK_SPEED / <1.0>;
		zs= get ABS(z) * ROCK_SPEED / <1.0>;
		windSteady=1;
		while(windSteady)
		{
			if(windSteady)
			{
				turn ROCK_PIECE to z-axis z speed zs;
				turn ROCK_PIECE to x-axis x speed xs;
				wait-for-turn ROCK_PIECE around x-axis;
				wait-for-turn ROCK_PIECE around z-axis;
				turn ROCK_PIECE to z-axis 0 speed zs;
				turn ROCK_PIECE to x-axis 0 speed xs;
				wait-for-turn ROCK_PIECE around x-axis;
				wait-for-turn ROCK_PIECE around z-axis;
			}
			if(windSteady)
			{
				turn ROCK_PIECE to z-axis 0-z speed zs;
				turn ROCK_PIECE to x-axis 0-x speed xs;
				wait-for-turn ROCK_PIECE around x-axis;
				wait-for-turn ROCK_PIECE around z-axis;
				turn ROCK_PIECE to z-axis 0 speed zs;
				turn ROCK_PIECE to x-axis 0 speed xs;
				wait-for-turn ROCK_PIECE around x-axis;
				wait-for-turn ROCK_PIECE around z-axis;
			}
		}
	}
}


#else
#endif
#else
#endif
#else
#endif
