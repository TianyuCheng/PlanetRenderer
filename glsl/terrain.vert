#version 330

in vec3 aVertex;

// Used in the vertex transformation
uniform mat4 uMVMatrix;
uniform mat4 uPMatrix;
uniform mat4 uNMatrix;
uniform mat4 uTransform;

uniform vec2 uOffset;
uniform vec2 uScale;
uniform float uGrid;
uniform int  uLevel;                // for debugging purpose, consider deprecated

uniform vec3 uCamera;
uniform vec2 uRange;                // (range, morphArea)

uniform sampler2D uHeightmap;
uniform sampler2D uNoisemap;

out vData
{
    vec3 pos;
    vec3 view;
    vec3 normal;
    vec2 heightUV;
    vec2 texCoords;
    float linearZ;
} vertex;

const float PI = 3.1415926;
const float SQRT2 = 1.4142;

// Transform a xz-plane to sphere
vec3 wrap(float radius, vec3 morphedPos) {
    float rho = morphedPos.y + radius;
    float theta = PI + morphedPos.x / (radius);
    float phi = PI / 2.0 - morphedPos.z / (radius);

    return vec3(
            rho * sin(phi) * cos(theta),
            rho * cos(phi),
            rho * sin(phi) * sin(theta)
    );
}

/**
 * uv: the global position
 */
float terrainHeight(vec2 uv) {
    float coarse = texture(uHeightmap, uv).x * 3200.0 - 1600.0;
    return coarse;
}

/**
 * gridPos: the global position
 */
vec3 computeNormal(vec2 gridPos) {
    float gridSize = 1.0 / uGrid;

    vec2 vx = gridPos - vec2(gridSize, 0.0);
    vec2 vy = gridPos - vec2(0.0, gridSize);

    vec3 px = vec3(uScale * vx + uOffset, 0.0).xzy;
    vec3 py = vec3(uScale * vy + uOffset, 0.0).xzy;
    vec3 p = vec3(uScale * gridPos + uOffset, 0.0).xzy;

    vec2 uvx = px.xz / 16384.0 - vec2(0.5, 0.5);
    vec2 uvy = py.xz / 16384.0 - vec2(0.5, 0.5);
    vec2 uv = p.xz / 16384.0 - vec2(0.5, 0.5);

    px.y = terrainHeight(uvx);
    py.y = terrainHeight(uvy);
    p.y  = terrainHeight(uv);
    return normalize(cross(p - py, p - px));
}

/**
 * gridPos: normalized coordinate [0,1]
 * vertex: world space position
 * morphK: morph value
 */
vec2 morphVertex(vec2 gridPos, vec2 vertex, float morphK) {
    vec2 fractPart = fract(gridPos * uGrid * 0.5) * 2.0 / uGrid;
    return vertex - fractPart * uScale * morphK;
}

float computeMorphK(vec2 gridPos, vec3 vertex) {
    vec2 uv = vertex.xz / 16384.0 - vec2(0.5, 0.5);
    vertex.y = terrainHeight(uv);      // approximate
    vec3 camera = uCamera;
    float dist = distance(camera, vertex);

    float morphStart = uRange.y * 2.0;
    float morphEnd = uRange.x * 4.0;
    morphEnd = morphEnd + (morphStart - morphEnd) * 0.01;       // lerp
    vec2 morphConsts = vec2(morphEnd / (morphEnd - morphStart), 1.0 / (morphEnd - morphStart));
    float morphLerpK = 1.0 - clamp(morphConsts.x - dist * morphConsts.y, 0.0, 1.0);
    return morphLerpK;
}

void main()
{
    float radius = 2048.0;

    vec3 pos = vec3(uScale * aVertex.xz + uOffset, 0.0).xzy;
    /* float morphK = computeMorphK(aVertex.xz, pos); */
    /* vec3 morphedPos = vec3(morphVertex(aVertex.xz, pos.xz, morphK), 0.0).xzy; */
    vec3 morphedPos = pos;
    vec2 uv = morphedPos.xz / 16384.0 - vec2(0.5, 0.5);
    morphedPos.y = terrainHeight(uv);

    vec4 noproj = uMVMatrix * uTransform * vec4(morphedPos, 1.0);
    /* vec4 noproj = uMVMatrix * uTransform * vec4(wrap(radius, morphedPos), 1.0); */
    vec4 proj = uPMatrix * noproj;
    gl_Position = proj;

    vertex.pos = morphedPos;
    vertex.normal = computeNormal(aVertex.xz);
    vertex.view = (uMVMatrix * vec4(morphedPos, 1.0)).xyz;
    vertex.heightUV = uv;
    vertex.texCoords = morphedPos.xz / 512.0;
    vertex.linearZ = (-noproj.z-1.0)/(10000.0-1.0);
}
