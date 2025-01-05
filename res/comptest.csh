#version 430

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;
layout(rgba8, binding = 0) uniform image2D img_io;

<%comment>
void main() {
  ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
  vec4 col = imageLoad(img_io, coord);
  col.rgb = col.grb;
  imageStore(img_io, coord, col);
}
<%/>

const int iter_max = 16384;
// const int iter_max = 65536;

void main() {
  uvec2 sz = gl_NumWorkGroups.xy * gl_WorkGroupSize.xy;
  uvec2 coord = gl_GlobalInvocationID.xy;
  vec2 c = (vec2(coord) / vec2(sz - 1)) * 2.0 - 1.0; // [-1, +1]
  uint i = 0;
  float x = 0.0;
  float y = 0.0;
  for (; i < iter_max; ++i) {
    float cxx = x * x + c.x;
    float x2 = x * 2.0;
    x = cxx - y * y;
    y = x2 * y + c.y;
    // float x1 = x * x - y * y + c.x;
    // y = x * y * 2.0 + c.y;
    // x = x1;
    // if (x * x + y * y > 4.0) { break; }
  }
  vec4 col = imageLoad(img_io, ivec2(coord));
  // col.r = float(i) / float(iter_max);
  col.r = (x * x + y * y < 4.0) ? 1.0 : 0.0;
  imageStore(img_io, ivec2(coord), col);
}
