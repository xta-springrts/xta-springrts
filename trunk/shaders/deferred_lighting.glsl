//This code copyright of Peter Sarkozy aka Beherith. Contact mysterme@gmail.com for licensing.
//License is CC-BY-ND 3.0
// old version with calced normals is 67 fps for 10 beamers full screen at 1440p
// new version with buffered normals is 88 fps for 10 beamers full screen at 1440p
uniform sampler2D modelnormals;
uniform sampler2D modeldepths;
uniform sampler2D mapnormals;
uniform sampler2D mapdepths;

uniform vec3 eyePos;
uniform vec4 lightpos;
#ifdef BEAM_LIGHT
	uniform vec4 lightpos2;
#endif
uniform vec4 lightcolor;
uniform vec4 lightparams;
uniform mat4 viewProjectionInv;
// uniform mat4 viewProjection;

  void main(void)
  {
	vec4 mappos4 =vec4(vec3(gl_TexCoord[0].st, texture2D( mapdepths,gl_TexCoord[0].st ).x) * 2.0 - 1.0 ,1.0);
	vec4 modelpos4 =vec4(vec3(gl_TexCoord[0].st, texture2D( modeldepths,gl_TexCoord[0].st ).x) * 2.0 - 1.0 ,1.0);
	vec4 map_normals4= texture2D( mapnormals,gl_TexCoord[0].st ) *2.0 -1.0;
	vec4 model_normals4= texture2D( modelnormals,gl_TexCoord[0].st ) *2.0 -1.0;
	
	
	//gl_FragColor=vec4(fract(modelpos4.z*0.01),sign(mappos4.z-modelpos4.z),0,1);
	//return;
	float model_lighting_multiplier=1;
	if ((mappos4.z-modelpos4.z)> 0) { // this means we are processing a model fragment, not a map fragment
		map_normals4 = model_normals4;
		mappos4 = modelpos4;
		model_lighting_multiplier=1.5;
	}
	mappos4 = viewProjectionInv * mappos4;
	mappos4.xyz = mappos4.xyz / mappos4.w;
	
	#ifndef BEAM_LIGHT
		float dist_light_here = length(lightpos.xyz - mappos4.xyz);
		float cosphi = max(0.0 , dot (map_normals4.xyz, lightpos.xyz - mappos4.xyz) / dist_light_here);
		float attentuation =  max( 0,( lightparams.r - lightparams.g * (dist_light_here*dist_light_here)/(lightpos.w*lightpos.w) - lightparams.b*(dist_light_here)/(lightpos.w)) );
	#endif
	#ifdef BEAM_LIGHT
		//def dist(x1,y1, x2,y2, x3,y3): # x3,y3 is the point
		/*distance( Point P,  Segment P0:P1 ) // http://geomalgorithms.com/a02-_lines.html
		{
			   v = P1 - P0
			   w = P - P0

			   if ( (c1 = w dot v) <= 0 )  // before P0
					   return d(P, P0)
			   if ( (c2 = v dot v) <= c1 ) // after P1
					   return d(P, P1)

			   b = c1 / c2
			   Pb = P0 + bv
			   return d(P, Pb)
		}
		*/

		vec3 v=lightpos2.xyz-lightpos.xyz;
		vec3 w=mappos4.xyz-lightpos.xyz;
		float c1=dot(v,w);
		float c2=dot(v,v);
		if (c1<=0.0){
			v=mappos4.xyz;
			w=lightpos.xyz;
		}else if (c2<c1){
			v=mappos4.xyz;
			w=lightpos2.xyz;
		}else{
			w=lightpos.xyz+(c1/c2)*v;
			v=mappos4.xyz;
		}
		float dist_light_here = length(v-w);
		float cosphi = max(0.0 , dot (map_normals4.xyz, w.xyz - mappos4.xyz) / dist_light_here);
		float attentuation =  max( 0,( lightparams.r - lightparams.g * (dist_light_here*dist_light_here)/(lightpos.w*lightpos.w) - lightparams.b*(dist_light_here)/(lightpos.w)) );
	#endif

	
	//lightparams info:
	// linear funcion is (1,0,1)
	//quadratic function is (1,1,0)
	// tits function (for lasers, to avoid hotspotting) (0.5, 2, -1.5)
	attentuation *=attentuation;
	
	//TODO:
	//add a specular highlight to the lighting with eyepos
	
	//gl_FragColor=vec4(normalize(herenormal4.xyz), cosphi*(lightpos.w/(dist_light_here*dist_light_here)));
	//if (attentuation > 0.001) gl_FragColor(1,0,0,1);
	//else gl_FragColor(0,1,0,1);
	// gl_FragColor=vec4(1,1,0,0.5);
	// return;
	
	//OK, our blending func is the following: Rr=Lr*Dr+1*Dr, 
	float lightalpha=cosphi*attentuation;
	vec3 lc=lightcolor.rgb*lightalpha*model_lighting_multiplier +1.0;
	gl_FragColor=vec4(lightcolor.rgb*lightalpha*model_lighting_multiplier,1);

	
	
	return;
  }
  