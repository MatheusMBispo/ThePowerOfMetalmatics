#include <simd/simd.h>
#include <metal_stdlib>
using namespace metal;

///////////////////////////////
///   SHADER RED LINE       ///
///////////////////////////////

//MARK: - STRUCTS
//----------------
// STRUCTS
//----------------

struct Uniform {
    float time;
    float3 mouse;
    float3 axis;
    float magnitude;
    
    Uniform() {}
};

struct RayResult{
    float dist;
    int material;
    
    RayResult(float dist, int material) {
        this->dist     = dist;
        this->material = material;
    }
};

//MARK: - MATERIALS
//----------------
// MATERIALS
//----------------

#define BACKGROUND_MATERIAL -1
#define CIRCLE_MATERIAL 0
#define CIRCLE_PURPLE_MATERIAL 1
#define GROUND_MATERIAL 2

//MARK: - DEFINES
//----------------
// DEFINES
//----------------

#define FAR 100
#define EPS 0.001
#define STEPS 100
#define time (uniform.time)
#define PI 3.14159265359

//MARK: - FUNCTION HEADER
//----------------
// FUNCTION HEADER
//----------------
float2 calculateUV(texture2d<float, access::write> input, uint2 gid);
float3 rotateY(float3 ray, float angle);
float3 rotateX(float3 ray, float angle);
float3 rotateZ(float3 ray, float angle);

float box(float3 hitRay, float3 pos, float3 size);
float sphere(float3 hitRay, float3 position, float radius);
float capsule( float3 hitRay, float3 position, float3 area, float3 border, float radius );

float ambientOcclusion(float3 ray, float3 normal);
float3 getNormal(float3 ray);
RayResult rayMarch(float3 origin, float3 dir, Uniform uniform);
float3x3 camera(float3 e, float3 la);

//MARK: - OBJECTS
//----------------
// OBJECTS
//----------------

float getCapsule1(float3 hitRay, Uniform uniform) {
    return capsule(hitRay,
                  float3(0.,
                         sin(hitRay.z + hitRay.x) * 0.5,
                         time/.5),
                  float3(-1., 0., 0.),
                  float3(-1. - time/.5, 0., 0.),
                   0.1) ;
}

float getCapsule2(float3 hitRay, Uniform uniform) {
    return capsule(hitRay,
                   float3(-0.5,
                          cos(hitRay.z + hitRay.x) * 0.5,
                          time/.5),
                   float3(-1., 0., 0.),
                   float3(-1. - time/.5, 0., 0.),
                   0.1);
}

//MARK: - SCENE
//----------------
// SCENE
//----------------

//Setup the current scene
RayResult scene(float3 hitRay, Uniform uniform)
{
    RayResult result = RayResult(FAR, BACKGROUND_MATERIAL);
    
    float scale = 1. / (-uniform.magnitude + 0.01);
    
    hitRay.z += scale;
    
    float distAux = .5 - abs(hitRay.y);
    
    float capsule1 = getCapsule1(hitRay, uniform);
    float capsule2 = getCapsule2(hitRay, uniform);
    
    if (distAux < FAR) {
        result.material = GROUND_MATERIAL;
    }
    
    if (capsule1 < distAux) {
        result.material = CIRCLE_MATERIAL;
    }
    
    if (capsule2 < capsule1) {
        result.material = CIRCLE_PURPLE_MATERIAL;
    }
    
    result.dist = min(capsule1, capsule2);
    result.dist = min(distAux, result.dist);
    
    return result;
}

//Setup the current scene without the uniform
RayResult scene(float3 hitRay)
{
    Uniform uniform = Uniform();
    
    return scene(hitRay, uniform);
}

//MARK: - KERNEL
//----------------
// KERNEL
//----------------

kernel void compute(texture2d<float, access::write> output [[texture(0)]],
                         constant Uniform &uniform [[buffer(0)]],
                         uint2 gid [[thread_position_in_grid]])
{
    
    float2 uv = calculateUV(output, gid);
//    - time/.5 * (max(abs(sin(time/5)), 0.8)) +
        //Ray Configuration
    float3 origin = float3( 1.2 + uniform.axis.x,
                            0.15,
                            time/.5 + 1. + uniform.axis.z);
    float3 direction = normalize(float3(uv.x,-uv.y,2.));
    direction = rotateX(direction,.23 + uniform.mouse.y);
    direction = rotateY(direction,1.72 + uniform.mouse.x);
    
        //RayMarch
    RayResult march = rayMarch(origin, direction, uniform);
    float3 hitRay = origin + march.dist * direction;
    float3 normal = getNormal(hitRay);
    
    float4 color = float4(0.);
    color = float4( max( dot(normal.xy*-1.,normalize(hitRay.xy-float2(.0,-.1))),.0)*.01 );
    
        //Set the material
    switch (march.material) {
        case CIRCLE_MATERIAL:
            
            color += float4(1.0,0.3,0.0,1.0)/(getCapsule1(hitRay - normal, uniform)) * 6./-uniform.magnitude;
            
            break;
        case CIRCLE_PURPLE_MATERIAL:
            
            color += float4(1.0,0.,1.0,1.0)/(getCapsule2(hitRay - normal, uniform));
            
            break;
        case GROUND_MATERIAL:
            
            color -= float4(0.1,0.1,0.1,1.0)/(.5 - abs(hitRay.y));
            break;
    }
    color *= ambientOcclusion(hitRay, normal);
    color = mix(color,float4(0.),float4((min(distance(origin, hitRay)*.05,1.0))));

    
    output.write(color, gid);
}
