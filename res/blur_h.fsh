<%import>pre.fsh<%/>
<%import>fnoise.fsh<%/>

<%decl_fragcolor/>
<%frag_in/> vec2 vary_coord;
uniform vec2 pixel_delta;
uniform sampler2D sampler_tex;
uniform sampler2D sampler_tex_2;
uniform float option_value;
layout(binding = 0, offset = 0) uniform atomic_uint white_count;

vec3 tex_read(in vec2 delta)
{
  vec4 v = <%texture2d/>(sampler_tex, vary_coord + delta * pixel_delta);
  return v.rgb;
}

/*
*/
const int kmax = 15;
const float weight[31] = float[31](
0.0029213834155948,
0.0043703148489516,
0.0063587705844030,
0.0089984944188647,
0.0123851939264988,
0.0165795231321248,
0.0215862659443153,
0.0273350124459989,
0.0336664475923431,
0.0403284540865239,
0.0469853125683838,
0.0532413342537254,
0.0586775544607166,
0.0628972046154989,
0.0655732860169900,
0.0664903800669055,
0.0655732860169900,
0.0628972046154989,
0.0586775544607166,
0.0532413342537254,
0.0469853125683838,
0.0403284540865239,
0.0336664475923431,
0.0273350124459989,
0.0215862659443153,
0.0165795231321248,
0.0123851939264988,
0.0089984944188647,
0.0063587705844030,
0.0043703148489516,
0.0029213834155948
);

/*
const int kmax = 10;
const float weight[21] = float[21](
0.0043820751233921,
0.0079349129589169,
0.0134977416282970,
0.0215693297066279,
0.0323793989164729,
0.0456622713472555,
0.0604926811297858,
0.0752843580387011,
0.0880163316910749,
0.0966670292007123,
0.0997355701003582,
0.0966670292007123,
0.0880163316910749,
0.0752843580387011,
0.0604926811297858,
0.0456622713472555,
0.0323793989164729,
0.0215693297066279,
0.0134977416282970,
0.0079349129589169,
0.0043820751233921
);
*/

const float aberration_delta = 1.5f / 512.0f;
const float point_weight_center = 0.6f;
const float point_weight_edge = 0.6f;
const float blur_weight_center = 1.0 - point_weight_center;
const float blur_weight_edge = 1.0 - point_weight_edge;
const bool linear_flag = true;

vec3 get_tex_aberration(in vec2 coord)
{
  vec2 coord_red = coord + coord * aberration_delta;
  vec2 c_red = (coord_red + 1.0) * 0.5;
  vec2 c_green = (coord + 1.0) * 0.5;
  vec4 v_red = <%texture2d/>(sampler_tex_2, c_red);
  vec4 v_green = <%texture2d/>(sampler_tex_2, c_green);
  return vec3(v_red.r, v_green.gb) * 2.0f;
}

void main(void)
{
  // blurをかけるフィルタ。縦と横の二回適用される。ガンマ変換済みの値に適用
  // される。倍率色収差も付ける。
  if (option_value != 0.0) {
    vec4 v = <%texture2d/>(sampler_tex, vary_coord);
    // vec4 v = get_tex_aberration(vary_coord * 2.0 - 1.0);
    <%fragcolor/> = vec4(v.rgb, 1.0);
  } else {
    // vec4 v = <%texture2d/>(sampler_tex_2, vary_coord);
    <%if><%blur_direction_v/>
    vec3 v = get_tex_aberration(vary_coord * 2.0 - 1.0);
    if (linear_flag) {
      v = v * v;
    }
    <%/>
    vec3 s = vec3(0.0);
    for (int k = -kmax; k <= kmax; ++k) {
      <%if><%blur_direction_v/>
      vec3 rv = tex_read(vec2(0.0, float(k)));
      <%else/>
      vec3 rv = tex_read(vec2(float(k), 0.0));
      <%/>
      if (linear_flag) {
        rv = rv * rv;
      }
      s = s + rv * weight[k + kmax];
    }
    <%if><%blur_direction_v/>
    vec2 c = vary_coord * 2.0 - 1.0;
    float d = dot(c, c);
    float bw = mix(blur_weight_center, blur_weight_edge, d);
    float cw = 1.0f - bw;
    vec3 col = s * bw + v * cw;
    <%else/>
    vec3 col = s;
    <%/>
    if (linear_flag) {
      col = sqrt(col);
    }
    col *= 2.0f;
    float frag_randval = generate_random(vec3(gl_FragCoord.xy, 0.0));
    col += frag_randval * (1.0f / 256.0f); // reduce color banding
    <%if><%blur_direction_v/>
    if (col.r >= 1.0 && col.g >= 1.0 && col.b >= 1.0) {
      atomicCounterIncrement(white_count);
    }
    <%/>
    <%fragcolor/> = vec4(col, 1.0);
  }
}

