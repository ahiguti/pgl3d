<%import>pre.vsh<%/>

<%vert_in/> vec2 vert;            /* (-1.0, 1.0) */
<%vert_out/> vec2 vary_coord;     /* (0.0, 1.0) */
void main(void)
{
  vary_coord = (vert + 1.0) * 0.5;     /* (-1.0, 1.0) to (0.0, 1.0) */
  gl_Position = vec4(vert, 0.0, 1.0);  /* xy : (-1.0, 1.0) */
}
