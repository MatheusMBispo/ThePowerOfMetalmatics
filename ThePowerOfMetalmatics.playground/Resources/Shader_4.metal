#include <simd/simd.h>
#include <metal_stdlib>
using namespace metal;

///////////////////////////////
///    TRIBUTE TO SIRI      ///
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

//MARK: - UTILS
//----------------
// UTILS
//----------------

#define FAR 100
#define EPS 0.001
#define STEPS 100

float2 calculateUV(texture2d<float, access::write> input, uint2 gid);
half4 wave(half4 color, half amp, half velocity, half shrink, half2 uv);
float rand(int x, int y, int z);
half3 hsv2rgb (half3 hsv);

float3 getNormal(float3 ray);
RayResult rayMarch(float3 origin, float3 dir, Uniform uniform);

    //MARK: - SCENE
    //----------------
    // SCENE
    //----------------

    //Setup the current scene
RayResult scene(float3 hitRay, Uniform uniform)
{
    RayResult result = RayResult(FAR, -1);
    
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
    
    uv.x += uniform.mouse.x;
    uv.y += uniform.mouse.y;
    
    half4 color = half4(0., 0., 0., 1.);
    
    for (float i = 0; i < 5.; i++) {
        
        half4 waveColor = half4( hsv2rgb(half3(min(max(0.2, abs(sin(0.6 * i))), 0.8),
                                               min(max(0.3, abs(cos(0.8 * i))), 0.8),
                                               min(max(0.7, abs(tan(0.4 * i))), 0.8))),
                                .3);
        color += wave( waveColor,
                      0.001 + 0.01 * (20  - min(abs(uniform.magnitude), 20.)),
                      (0.1 + i/2) * uniform.time,
                      PI * 2/i,
                      half2(uv));
    }
    
    output.write(float4(color), gid);
}
