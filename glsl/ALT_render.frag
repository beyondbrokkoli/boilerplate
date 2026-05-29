#version 460
#extension GL_GOOGLE_include_directive : require
#include "shared.glsl"

layout(location = 0) in vec3 fragColor;
layout(location = 1) in vec3 v_worldPos;
layout(location = 2) flat in uint v_shapeID;
layout(location = 3) flat in float v_colorIdx;

layout(location = 0) out vec4 outColor;

void main() {
    if (v_shapeID == MODE_POINT_CLOUD_PASS) {
        vec2 ptc = gl_PointCoord - vec2(0.5);
        float distSq = dot(ptc, ptc);
        float circle_mask = 1.0 - smoothstep(0.15, 0.25, distSq);
        float glow = pow(max(0.0, 1.0 - (sqrt(distSq) * 2.0)), 1.2);

        outColor = vec4(fragColor * 2.8, circle_mask * glow);
    } else {
        // Calculate flat face normals
        vec3 dpdx = dFdx(v_worldPos);
        vec3 dpdy = dFdy(v_worldPos);
        vec3 normal = normalize(cross(dpdx, dpdy));
        
        // IRIDESCENT MODIFICATION: Use the normal as the base color, animate it with time
        vec3 animated_normal = normal * 0.5 + 0.5; 
        vec3 trippy_color = 0.5 + 0.5 * cos(pc.total_time * 2.0 + v_worldPos.xyz * 0.0005 + vec3(0.0, 2.0, 4.0));
        
        vec3 lightDir = normalize(vec3(0.5, 1.0, 0.8));
        float diffuse = max(dot(normal, lightDir), 0.2);
        
        // Mix the original color with the trippy normal colors
        vec3 final_color = mix(fragColor, trippy_color * animated_normal, 0.85);

        outColor = vec4(final_color * diffuse * 2.0, 1.0);
    }
}
