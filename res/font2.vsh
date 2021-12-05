<%import>pre.vsh<%/>

uniform vec2 screen_size_px;
<%vert_in/> vec2 texture_size_px;
<%vert_in/> vec2 texture_origin_px;
<%vert_in/> vec2 char_size_px;
<%vert_in/> vec2 coord_clamp;
<%vert_in/> float char_point_size;
<%decl_instance_attr vec4 idata/>
<%vert_out/> vec2 vary_texture_size_px;
<%vert_out/> vec2 vary_texture_origin_px;
<%vert_out/> vec2 vary_char_size_px;
<%vert_out/> vec2 vary_coord_clamp;
<%vert_out/> float vary_point_size;
<%vert_out/> float vary_trev;

void main(void) {
  vec4 idata_i = <%instance_attr idata/>;
  float ch = idata_i.x;
  float trev = idata_i.y;
  vec2 screen_pos = idata_i.zw;
  vec2 screen_px = floor((screen_pos + 1.0) * screen_size_px * 0.5 + 0.5);
  screen_px += char_point_size * 0.5;
  screen_pos = screen_px / screen_size_px * 2.0 - 1.0;
  gl_Position = vec4(screen_pos, 0.0, 1.0);
  gl_PointSize = char_point_size;
  vary_texture_size_px = texture_size_px;
  vary_texture_origin_px = texture_origin_px + vec2(char_size_px.x * ch, 0.0);
  vary_char_size_px = char_size_px;
  vary_coord_clamp = coord_clamp;
  vary_point_size = char_point_size;
  vary_trev = trev;
}

