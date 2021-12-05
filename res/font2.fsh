<%import>pre.fsh<%/>

uniform sampler2D sampler_font;
<%frag_in/> vec2 vary_texture_size_px;
<%frag_in/> vec2 vary_texture_origin_px;
<%frag_in/> vec2 vary_char_size_px;
<%frag_in/> vec2 vary_coord_clamp;
<%frag_in/> float vary_point_size;
<%frag_in/> float vary_trev;
<%decl_fragcolor/>

void main(void) {
  vec2 xy = gl_PointCoord;
  if (xy.x > vary_coord_clamp.x) { discard; }
  vec2 pcoord = vary_point_size * xy;
  vec2 texcoord = (vary_texture_origin_px + pcoord) / vary_texture_size_px;
  vec4 col = <%texture2d/>(sampler_font, texcoord);
  float a = ((col.a * 2. - 1.) * (1. - vary_trev * 2.) + 1.) * 0.5;
  <%fragcolor/> = vec4(1.0, 0.0, 0.3, a);
}
