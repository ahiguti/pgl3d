<%import>pre.fsh<%/>

// このシェーダはshadowmapなどのテクスチャの内容を可視化する。
// 描画のデバッグのために使う。

<%decl_fragcolor/>
<%frag_in/> vec2 vary_coord;
uniform sampler2D sampler_sm[<%smsz/>];
uniform sampler2D sampler_tex[8];

int foo()
{
  for (int i = 0; i < 1; ++i) { }
  if (true) { return 1; }
  return 0;
}

void main(void)
{
  // discard;
  vec2 p = vary_coord.xy; /* (0.0, 1.0) */
  if (false) {
    // scaleの異なるshadowmapをrgbそれぞれに表示。shadowmap生成処理が
    // 正しければrgbで形状はほぼ一致する(ただし値は一致しない)。
    // scale=3.0前提。
    vec4 v;
    v = <%texture2d/>(sampler_sm[0], (p - 0.5) / 1.0 + 0.5);
    float r = v.r;
    v = <%texture2d/>(sampler_sm[1], (p - 0.5) / 3.0 + 0.5);
    float g = v.r;
    v = <%texture2d/>(sampler_sm[2], (p - 0.5) / 9.0 + 0.5);
    float b = v.r;
    // blendでシェーダが実行されているのでalpha値で透過率を調整できる
    <%fragcolor/> = vec4(r, g, b, 0.2);
  }
  if (true) {
    vec4 v;
    v = <%texture2d/>(sampler_tex[0], p);
    <%fragcolor/> = vec4(v.a, v.a, v.a, 0.8);
  }

  /*
  // バグ記録: nvidiaだとfoo()が0を返す。
  if (foo() == 0) {
    <%fragcolor/> = vec4(1.0);
  }
  */
}

