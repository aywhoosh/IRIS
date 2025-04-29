#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform float uAmplitude;
uniform vec3 uColor1;
uniform vec3 uColor2;
uniform vec3 uColor3;

out vec4 fragColor;

// Improved Perlin noise for liquid effect
vec2 fade(vec2 t) { return t * t * t * (t * (t * 6.0 - 15.0) + 10.0); }

vec4 permute(vec4 x) { return mod(((x * 34.0) + 1.0) * x, 289.0); }

float cnoise(vec2 P) {
    vec4 Pi = floor(P.xyxy) + vec4(0.0, 0.0, 1.0, 1.0);
    vec4 Pf = fract(P.xyxy) - vec4(0.0, 0.0, 1.0, 1.0);
    Pi = mod(Pi, 289.0);
    vec4 ix = Pi.xzxz;
    vec4 iy = Pi.yyww;
    vec4 fx = Pf.xzxz;
    vec4 fy = Pf.yyww;
    vec4 i = permute(permute(ix) + iy);
    vec4 gx = 2.0 * fract(i * 0.0243902439) - 1.0;
    vec4 gy = abs(gx) - 0.5;
    vec4 tx = floor(gx + 0.5);
    gx = gx - tx;
    vec2 g00 = vec2(gx.x, gy.x);
    vec2 g10 = vec2(gx.y, gy.y);
    vec2 g01 = vec2(gx.z, gy.z);
    vec2 g11 = vec2(gx.w, gy.w);
    vec4 norm = 1.79284291400159 - 0.85373472095314 * vec4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11));
    g00 *= norm.x;
    g01 *= norm.y;
    g10 *= norm.z;
    g11 *= norm.w;
    float n00 = dot(g00, vec2(fx.x, fy.x));
    float n10 = dot(g10, vec2(fx.y, fy.y));
    float n01 = dot(g01, vec2(fx.z, fy.z));
    float n11 = dot(g11, vec2(fx.w, fy.w));
    vec2 fade_xy = fade(Pf.xy);
    vec2 n_x = mix(vec2(n00, n01), vec2(n10, n11), fade_xy.x);
    float n_xy = mix(n_x.x, n_x.y, fade_xy.y);
    return 2.3 * n_xy;
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord/uSize.xy;
    
    float slowTime = uTime * 0.25; // Slower, more graceful movement
    
    // Concentrate effect at the top
    float verticalIntensity = smoothstep(1.0, 0.0, uv.y * 2.0);
    
    // Adjusted noise scale for top-focused effect
    float noise1 = cnoise(uv * vec2(2.0, 1.0) + vec2(slowTime * 0.5, slowTime * 0.3)) * (uAmplitude * verticalIntensity);
    float noise2 = cnoise(uv * vec2(1.5, 0.8) + vec2(-slowTime * 0.4, slowTime * 0.2)) * (uAmplitude * verticalIntensity);
    float noise3 = cnoise(uv * vec2(3.0, 1.5) + vec2(slowTime * 0.3, -slowTime * 0.4)) * (uAmplitude * verticalIntensity);
    
    float finalNoise = noise1 * 0.5 + noise2 * 0.3 + noise3 * 0.2;
    
    vec3 color = mix(uColor1, uColor2, uv.y + finalNoise);
    color = mix(color, uColor3, smoothstep(0.3, 0.7, uv.y + finalNoise));
    
    float pulse = sin(slowTime) * 0.15 + 0.85;
    
    // Stronger effect at the top, fading to white
    vec3 backgroundColor = vec3(1.0, 1.0, 1.0);
    color = mix(backgroundColor, color, 0.7 * verticalIntensity * pulse);
    
    fragColor = vec4(color, 1.0);
}