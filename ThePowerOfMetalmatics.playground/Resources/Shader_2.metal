#include <simd/simd.h>
#include <metal_stdlib>
using namespace metal;

///////////////////////////////
/// SHADER INFINITY SPHERES ///
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

//MARK: - DEFINES
//----------------
// DEFINES
//----------------

#define FAR 100
#define EPS 0.001
#define STEPS 100
#define time (uniform.time)
#define PI 3.14159265359

//MARK: - MATERIALS
//----------------
// MATERIALS
//----------------

#define BACKGROUND_MATERIAL -1
#define CIRCLE_MATERIAL 0

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

float ambientOcclusion(float3 ray, float3 normal);
float3 getNormal(float3 ray);
RayResult rayMarch(float3 origin, float3 dir, Uniform uniform);
float3x3 camera(float3 e, float3 la);

float3 hsv2rgb (float3 hsv);
float hash(float3 uv);

//MARK: - SCENE
//----------------
// SCENE
//----------------

//Setup the current scene
RayResult scene(float3 hitRay, Uniform uniform)
{
    RayResult result = RayResult(FAR, BACKGROUND_MATERIAL);
    
    float sphereDist = sphere(fract(hitRay), float3(.5), 1./-uniform.magnitude + 0.05);
    if (sphereDist < result.dist) {
        result.material = CIRCLE_MATERIAL;
    }
    
    result.dist = sphereDist;
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
    
    float3 origin = float3( 1.2 + uniform.axis.x,
                           0.15,
                           time + 7. + uniform.axis.z);
    float3 direction = normalize(float3(uv.x,-uv.y,2.));
    direction = rotateX(direction,.15 + uniform.mouse.y);
    direction = rotateY(direction,2.8 + uniform.mouse.x);
    
    //RayMarch
    RayResult march = rayMarch(origin, direction, uniform);
    float3 hitRay = origin + march.dist * direction;
    float3 normal = getNormal(hitRay);
    
    float4 color = float4(0.);
    
    //Set the material
    switch (march.material) {
        case CIRCLE_MATERIAL:
            
            float3 angel = atan(hitRay) / PI / 2.;
            float3 c = hsv2rgb(float3(angel.x, 1., 1.));
            
            color += float4(c, 1.0);
            break;
    }
    
    color *= ambientOcclusion(hitRay, normal);
    
    output.write(float4(color / (1. + march.dist * march.dist * .1)), gid);
}
