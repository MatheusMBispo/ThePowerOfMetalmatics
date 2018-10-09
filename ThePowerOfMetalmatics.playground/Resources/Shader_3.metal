#include <simd/simd.h>
#include <metal_stdlib>
using namespace metal;

///////////////////////////////
///       WAVE SPHERE       ///
///////////////////////////////

#define PI 3.14159265359

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

float sphere(float3 hitRay, float3 position, float radius);
float circle(float2 center, float radius, float2 uv);

float3 lighting(float3 hitRay, float3 light, float3 rayDirection);
float ambientOcclusion(float3 ray, float3 normal);
float3 getNormal(float3 ray);
RayResult rayMarch(float3 origin, float3 dir, Uniform uniform);
float3x3 camera(float3 e, float3 la);

float3 hsv2rgb (float3 hsv);

float3 gammaPostProcessing(float3 origin, float3 color);

//MARK: - SCENE
//----------------
// SCENE
//----------------

//Setup the current scene
RayResult scene(float3 hitRay, Uniform uniform)
{
    
    float sphereDist = sphere(hitRay,
                              float3(0.),
                                  sin(time)/100. + 0.4 + 1./-uniform.magnitude);
    
    return RayResult(sphereDist, 0.);
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
    
    //Ray Configuration
    float3 origin = float3(0.5 + uniform.axis.x,
                           1.5,
                           1. + uniform.axis.z);
    
    origin = rotateX(origin, uniform.mouse.y);
    origin = rotateY(origin, uniform.mouse.x);
    
    float3 direction = camera(origin, float3(0.)) * normalize(float3(uv.x,-uv.y,2.));
    
    
    //RayMarch
    RayResult march = rayMarch(origin, direction, uniform);
    float3 hitRay = origin + march.dist * direction;
    float3 normal = getNormal(hitRay);
    
    float3 light = float3(5., 2., 0.);
    float3 color = float3(0.);
    
    if (march.dist < FAR) {
        
        float3 color1 = float3(.5, 0., 0.2);
        float3 color2 = float3(0.3, .1, .6);
        float3 sphereColor = mix(color1, color2, 0.5);
        
        color += sphereColor;
        
        color *= ambientOcclusion(hitRay, normal);
        color *= lighting(hitRay, light, direction);
    }
    color = gammaPostProcessing(origin, color);
    
    //Creating Waves
    float w = (uv.x) * (output.get_width() / output.get_height());
    float h = uv.y;
    
    float distanceFromCenter = sqrt(w * w + h * h);
    
    float sinArg = distanceFromCenter * 10.0 - time * 10.0;
    float slope = cos(sinArg) ;
    
    float size = (slope * 0.05);
    color -= circle(float2(0.0), size, uv )/-uniform.magnitude;
    
    output.write( float4( color, 1.0 ) , gid);
}
