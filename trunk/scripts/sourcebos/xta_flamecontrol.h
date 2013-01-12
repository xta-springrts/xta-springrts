// Author: Deadnight Warrior
// 
// Notes: Use this script if you want to make your unit burn/emit effects when taking damage, from up
//	  to 10 points on unit model
//	  This script can work with TA, TA:K, TA3D or SpringRTS
//	  If you're using Spring and you're using CEGs, add the apropriate tag in unit definition file
//	  You must define "NUM_IGNITE", "FIRE_SFX" and "IGNITE_PIECE_N" constants before including for
//	  this script to work, where N is 1..10
//
// Example usage:
// #define NUM_IGNITE 5		// 5 ignite pieces
// #define FIRE_SFX UNIT_SFX3	// Custom Explosion Generator 3, UNIT_SFX3 is defined in exptype.h, for SpringRTS
// #define IGNITE_PIECE_1 base  // Definition of each ignite piece
// #define IGNITE_PIECE_2 hull
// #define IGNITE_PIECE_3 turret1
// #define IGNITE_PIECE_4 turret2
// #define IGNITE_PIECE_5 rack
// ...
// #include "XTA_FlameControl.h"
// ...
// start-script FlameControl();
// ...

#ifdef NUM_IGNITE
#ifdef FIRE_SFX

#if NUM_IGNITE == 1
	#define FLAME1 50
#else
#if NUM_IGNITE == 2
	#define FLAME1 67
	#define FLAME2 33
#else
#if NUM_IGNITE == 3
	#define FLAME1 75
	#define FLAME2 50
	#define FLAME3 25
#else
#if NUM_IGNITE == 4
	#define FLAME1 80
	#define FLAME2 60
	#define FLAME3 40
	#define FLAME4 20
#else
#if NUM_IGNITE == 5
	#define FLAME1 83
	#define FLAME2 67
	#define FLAME3 50
	#define FLAME4 33
	#define FLAME5 17
#else
#if NUM_IGNITE == 6
	#define FLAME1 86
	#define FLAME2 71
	#define FLAME3 57
	#define FLAME4 43
	#define FLAME5 29
	#define FLAME6 14
#else
#if NUM_IGNITE == 7
	#define FLAME1 88
	#define FLAME2 75
	#define FLAME3 63
	#define FLAME4 50
	#define FLAME5 38
	#define FLAME6 25
	#define FLAME7 13
#else
#if NUM_IGNITE == 8
	#define FLAME1 89
	#define FLAME2 78
	#define FLAME3 67
	#define FLAME4 56
	#define FLAME5 44
	#define FLAME6 33
	#define FLAME7 22
	#define FLAME8 11
#else
#if NUM_IGNITE == 9
	#define FLAME1 90
	#define FLAME2 80
	#define FLAME3 70
	#define FLAME4 60
	#define FLAME5 50
	#define FLAME6 40
	#define FLAME7 30
	#define FLAME8 20
	#define FLAME9 10
#else
#if NUM_IGNITE == 10
	#define FLAME1 91
	#define FLAME2 82
	#define FLAME3 73
	#define FLAME4 64
	#define FLAME5 55
	#define FLAME6 45
	#define FLAME7 36
	#define FLAME8 27
	#define FLAME9 18
	#define FLAME10 9
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif


FlameControl(healthLeft)
{
	while( TRUE )
	{
		healthLeft = get HEALTH;
		if( healthLeft <= FLAME1 ){
			emit-sfx FIRE_SFX from IGNITE_PIECE_1;
	#if NUM_IGNITE >= 2
			if( healthLeft <= FLAME2 ){
				emit-sfx FIRE_SFX from IGNITE_PIECE_2;
		#if NUM_IGNITE >= 3
				if( healthLeft <= FLAME3 ){
					emit-sfx FIRE_SFX from IGNITE_PIECE_3;
			#if NUM_IGNITE >= 4
					if( healthLeft <= FLAME4 ){
						emit-sfx FIRE_SFX from IGNITE_PIECE_4;
				#if NUM_IGNITE >= 5
						if( healthLeft <= FLAME5 ){
							emit-sfx FIRE_SFX from IGNITE_PIECE_5;
					#if NUM_IGNITE >= 6
							if( healthLeft <= FLAME6 ){
								emit-sfx FIRE_SFX from IGNITE_PIECE_6;
						#if NUM_IGNITE >= 7
								if( healthLeft <= FLAME7 ){
									emit-sfx FIRE_SFX from IGNITE_PIECE_7;
							#if NUM_IGNITE >= 8
									if( healthLeft <= FLAME8 ){
										emit-sfx FIRE_SFX from IGNITE_PIECE_8;
								#if NUM_IGNITE >= 9
										if( healthLeft <= FLAME9 ){
											emit-sfx FIRE_SFX from IGNITE_PIECE_9;
									#if NUM_IGNITE == 10
											if( healthLeft <= FLAME10 ) emit-sfx FIRE_SFX from IGNITE_PIECE_10;
									#endif
										}
								#endif
									}
							#endif
								}
						#endif
							}	
					#endif
						}
				#endif
					}
			#endif
				}
		#endif
			}
	#endif
			sleep 100;
		}
		else
		{
			sleep 333;
		}
	}
}



#else
#endif
#else
#endif
