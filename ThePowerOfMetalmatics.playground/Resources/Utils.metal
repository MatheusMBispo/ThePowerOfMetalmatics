//MARK: - UTILS
//----------------
// UTILS
//----------------

// Rotate a vector on axis Y
float3 rotateY(float3 ray, float angle)
{
    return float3(
                  cos(angle)*ray.x - sin(angle)*ray.z,
                  ray.y,
                  sin(angle)*ray.x + cos(angle)*ray.z
                  );
}

// Rotate a vector on axis X
float3 rotateX(float3 ray, float angle)
{
    return float3(
                  ray.x,
                  ray.y*cos(angle) - ray.z*sin(angle),
                  ray.y*sin(angle) + ray.z*cos(angle)
                  );
}

// Rotate a vector on axis Z
float3 rotateZ(float3 ray, float angle)
{
    return float3(
                  ray.x*cos(angle) - ray.y*sin(angle),
                  ray.x*sin(angle) + ray.y*cos(angle),
                  ray.z
                  );
}

// Calculates UV based on input texture
float2 calculateUV(texture2d<float, access::write> input, uint2 gid){
    int width = input.get_width();
    int height = input.get_height();
    
    //Ajustando coordenadas da Tela
    float2 uv = float2(gid) / float2(width, height);
    uv = uv * 2.0 - 1.0;
    
    //Ajustando a visão da camera
    uv.y = -uv.y;
    
    return uv;
}

float hash(float3 uv) {
    return fract(sin(dot(uv, float3(7.13, 157.09, 113.57))) * 48543.5453);
}

//MARK: - COLOR
//----------------
// COLOR
//----------------
float3 hsv2rgb (float3 hsv) {
    return hsv.z * (1.0 + 0.5 * hsv.y * (cos (2.0 * PI * (hsv.x + float3 (0.0, 0.6667, 0.3333))) - 1.0));
}

half3 hsv2rgb(half3 hsv){
    return hsv.z * (1.0 + 0.5 * hsv.y * (cos (2.0 * PI * (hsv.x + half3 (0.0, 0.6667, 0.3333))) - 1.0));
}

//MARK: - OBJECTS
//----------------
// OBJECTS
//----------------

//Return the distance from box (create a box)
float box(float3 hitRay, float3 pos, float3 size)
{
    return max(
               max(
                   abs(hitRay.x-pos.x)-size.x,
                   abs(hitRay.y-pos.y)-size.y),
               abs(hitRay.z-pos.z)-size.z
               );
}

float sphere(float3 hitRay, float3 position, float radius){
    return length(hitRay - position) - radius;
}

float capsule( float3 hitRay, float3 position, float3 area, float3 border, float radius )
{
    float3 hitAux = hitRay - area;
    float3 borderAux = border - area;
    float height = clamp( dot(hitAux,borderAux)/dot(borderAux,borderAux), 0.0, 1.0 );
    return length( hitAux - position - borderAux*height ) - radius;
}

half4 wave(half4 color, half amp, half velocity, half shrink, half2 uv){
    uv.x += velocity;
    float sinX = cos(uv.x * shrink) ;
    
    if ( abs( uv.y / amp) < abs(sinX) + 0.01 ) {
        return color * color.a;
    }
    
    return half4(0., 0., 0., 1.);
}

float circle(float2 center, float radius, float2 uv)
{
    return 1.0 - smoothstep(0.0, radius, length(uv - center));
}

//MARK: - RAYMARCH
//----------------
// RAYMARCH
//----------------

//Calculates the lighting on the scene
float3 lighting(float3 p, float3 l, float3 rd) {
    float3 lig = normalize(l);
    float3 n = getNormal(p);
    float3 ref = reflect(lig, n);
    
    float amb = 1.0 * clamp((p.y + 0.25)*1.2, 0.0, 1.0);
    float dif = clamp(dot(n, lig), 0.0, 1.0);
    float spe = pow(clamp(dot(ref, rd), 0.0, 1.0), 52.0);
    
    float3 lin = float3(0);
    
    lin += amb;
    lin += dif*float3(.3, .27, .25);
    lin += 2.0*spe*float3(1, .97, .1)*dif;
    
    return lin;
}

//Calculates raymarching
RayResult rayMarch(float3 origin, float3 dir, Uniform uniform)
{
    RayResult result = RayResult(0.0, -1);
    
    for(int i=0; i<STEPS; i++) {
        
        RayResult resultAux = scene( origin + result.dist * dir, uniform);
        
        result.dist += resultAux.dist;
        result.material = resultAux.material;
        
        if (resultAux.dist < EPS || resultAux.dist > FAR) break;
    }
    
    return result;
}

//Calculates the normal of ray
float3 getNormal(float3 ray)
{
    float3 eps = float3(0.01,0.0,0.0);
    return normalize(float3(
                            scene(ray+eps.xyy).dist -
                            scene(ray-eps.xyy).dist,
                            scene(ray+eps.yxy).dist -
                            scene(ray-eps.yxy).dist,
                            scene(ray+eps.yyx).dist -
                            scene(ray-eps.yyx).dist
                            ));
}

//Calculates the ambient occlusion of ray
float ambientOcclusion(float3 ray, float3 normal)
{
    float dlt = 0.1;
    float oc = 0.0, d = 1.0;
    for(int i = 0; i<6; i++)
        {
        oc += (float(i) * dlt - scene(ray + normal * float(i) * dlt).dist) / d;
        d *= 2.0;
        }
    return clamp(1.0 - oc, 0.0, 1.0);
}

//MARK: - CAMERA
//----------------
// CAMERA
//----------------
float3x3 camera(float3 e, float3 la) {
    float3 roll = float3(0, 1, 0);
    float3 f = normalize(la - e);
    float3 r = normalize(cross(roll, f));
    float3 u = normalize(cross(f, r));
    
    return float3x3(r, u, f);
}

//MARK: - POST PROCESSING
//----------------
// POST PROCESSING
//----------------
float3 gammaPostProcessing(float3 origin, float3 color) {
    float3 _color = pow( clamp(color,0.0,1.0), float3(0.4545) );
    _color += dot(origin, origin * 0.035);
    _color.r = smoothstep(0.1,1.1,_color.r);
    _color.g = pow(_color.g, 1.1);
    
    return _color;
}

//MARK: - RANDOM
//----------------
// RANDOM
//----------------
float rand(int x, int y, int z)
{
    int seed = x + y * 57 + z * 241;
    seed= (seed<< 13) ^ seed;
    return (( 1.0 - ( (seed * (seed * seed * 15731 + 789221) + 1376312589) & 2147483647) / 1073741824.0f) + 1.0f) / 2.0f;
}

float rand(float x)
{
    return fract(sin(dot(float2(x+47.49,38.2467/(x+2.3)), float2(12.9898, 78.233)))* (43758.5453));
}
