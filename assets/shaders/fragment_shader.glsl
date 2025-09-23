#version 330

const int SPOT_LIGHT_TYPE = 1;
const int DIRECTIONAL_LIGHT_TYPE = 2;
const int NUMBEROFLIGHTS = 50;

struct Light {
	vec4 position;	  // xyz = position, ignoring w = TBD
	vec4 diffuse;	  // rgb = diffuse colour, w = intensity
	vec4 specular;	  // rgb = highlight colour, w = power
	vec4 attenuation; // x = constant, y = linear, z = quadratic, w = cutoff distance
	vec4 direction;   // xyz = direction (spot/directional), w = unused
	vec4 param1;	  // x = lightType (0 = Point, 1 = Spot, 2 = Directional), y = inner angle (spot), z = outer angle (spot), w = TBD
	vec4 param2;	  // x = enabled (0 = off, 1 = on), yzw = TBD
};

uniform Light theLights[NUMBEROFLIGHTS];
uniform int lightCount;

uniform vec3 eyePos;
uniform vec4 vertSpecular;

uniform bool bUseTextures; 
uniform bool bIsSkybox;
uniform bool bIsLit;

uniform vec4 ambientLight;

// Textures (Can have up to 32+ of these, not the "total number of textures", max texture PER pixelColour
uniform sampler2D textSampler2D_00;
uniform sampler2D textSampler2D_01;
uniform sampler2D textSampler2D_02;
uniform sampler2D textSampler2D_03;
uniform samplerCube skyboxCubeTexture;
uniform vec4 texMixRatios;

in vec4 vertColor;
in vec4 vertNormal;
in vec4 vertWorldPosition;
in vec2 vertTextCoords;

out vec4 pixelColour;

vec4 calculateLightContrib(vec4 vertexMaterialColour, vec3 vertexNormal, vec3 vertexWorldPos, vec4 vertexSpecular);

void main() {
	vec4 finalTextRGBA = vertColor;

	if(bIsSkybox){
		pixelColour = vec4(texture(skyboxCubeTexture, vertNormal.xyz).rgb, 1.0);
		return;
	}
	
	if(bUseTextures){
		vec4 tex00RGBA = texture( textSampler2D_00, vertTextCoords.xy );
		vec4 tex01RGBA = texture( textSampler2D_01, vertTextCoords.xy );
		vec4 tex02RGBA = texture( textSampler2D_02, vertTextCoords.xy );
		vec4 tex03RGBA = texture( textSampler2D_03, vertTextCoords.xy );

	    vec4 texMix = tex00RGBA * texMixRatios.x
					+ tex01RGBA * texMixRatios.y
					+ tex02RGBA * texMixRatios.z
					+ tex03RGBA * texMixRatios.w;

        finalTextRGBA = vec4(texMix.rgb * finalTextRGBA.rgb, texMix.a * finalTextRGBA.a);
	}

	if(!bIsLit){
		pixelColour = finalTextRGBA;
		return;
	}

	vec4 lightContrib = calculateLightContrib(finalTextRGBA, vertNormal.xyz, vertWorldPosition.xyz, vertSpecular);
	vec3 colour = lightContrib.rgb + finalTextRGBA.rgb * ambientLight.rgb * ambientLight.a;
	pixelColour = vec4(colour, finalTextRGBA.a);
};

vec4 calculateLightContrib(vec4 vertexMaterialColour, vec3 vertexNormal, vec3 vertexWorldPos, vec4 vertexSpecular) {
	vec3 light = vec3(0.0);
	vec3 n = normalize(vertexNormal);
	vec3 v = normalize(eyePos - vertexWorldPos);
	
	for (int i = 0; i < lightCount; i++) {	
		if (theLights[i].param2.x == 0.0) continue;
	
		int type = int(theLights[i].param1.x);
		vec3 dir = normalize(theLights[i].direction.xyz);

		// We will do the directional light here before the attenuation, since sunlight has no attenuation
		// Simulate sunlight. There's ONLY direction, no position -Almost always, there's only 1 of these in a scene, Cheapest light to calculate. 
		if (type == DIRECTIONAL_LIGHT_TYPE)	{
			float NdotL = max(0.0, dot(n, -dir));	
			if(NdotL <= 0.0) continue;
			if(NdotL > 0.0) { 
				vec3 lightContrib = theLights[i].diffuse.rgb * theLights[i].diffuse.a * NdotL;
				light.rgb += ( vertexMaterialColour.rgb * lightContrib /*+ (materialSpecular.rgb * lightSpecularContrib.rgb);*/);
			}

			continue;
		}
			
		// Contribution for this point/spot light
		vec3 vLightToVertex = theLights[i].position.xyz - vertexWorldPos;	
		vec3 lightVector = normalize(vLightToVertex);	
		float NdotL = max(0.0, dot(lightVector, n));	 

		// Diffuse
		vec3 lightDiffuseContrib = NdotL * theLights[i].diffuse.rgb * theLights[i].diffuse.a;
		
		// Specular -- NOT using the light specular value, just the object’s.
		vec3 reflectVector = reflect(-lightVector, n);
		float RdotV = max(0.0, dot(v, reflectVector));
		vec3 lightSpecularContrib = vec3(pow(RdotV, vertexSpecular.w)); //* theLights[lightIndex].Specular.rgb
						
		// Attenuation
		float dist = length(vLightToVertex);		
		float att = 1.0 / (theLights[i].attenuation.x + 
						   theLights[i].attenuation.y * dist + 
						   theLights[i].attenuation.z * dist * dist);  	
				  
		// total light contribution is Diffuse + Specular
		lightDiffuseContrib *= att;
		lightSpecularContrib *= att;
		
		if (type == SPOT_LIGHT_TYPE) {	
			vec3 vertexToLight = normalize(vertexWorldPos - theLights[i].position.xyz);
			float spotCosAngle = max(0.0, dot(vertexToLight, dir));

			// Is this inside the cone? 
			float outerConeAngleCos = cos(radians(theLights[i].param1.z));
			float innerConeAngleCos = cos(radians(theLights[i].param1.y));
							
			// Is it completely outside of the spot?
			if (spotCosAngle < outerConeAngleCos) { // Nope, it's in the dark
				lightDiffuseContrib = vec3(0.0);
				lightSpecularContrib = vec3(0.0);
			}
			else if (spotCosAngle < innerConeAngleCos) {
				// Angle is between the inner and outer cone (called the penumbra of the spot light)
				// This blends the brightness from,	full brightness near the inner cone, to black near the outter cone
				float penumbraRatio = (spotCosAngle - outerConeAngleCos) / (innerConeAngleCos - outerConeAngleCos);
									  
				lightDiffuseContrib *= penumbraRatio;
				lightSpecularContrib *= penumbraRatio;
			}		
		}
				
		light.rgb += (vertexMaterialColour.rgb * lightDiffuseContrib.rgb) + (vertexSpecular.rgb * lightSpecularContrib.rgb);
	}
	return vec4(light, 1.0);
}