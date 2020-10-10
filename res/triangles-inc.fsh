
<%if><%eq><%get_config dbgval/>1<%/>
vec4 dbgval = vec4(0.0);
<%/>

const float epsilon = 1e-6;

float linear_01(in float x, in float a, in float b)
{
  return clamp((x - a) / (b - a), 0.0, 1.0);
}

float linear_10(in float x, in float a, in float b)
{
  return clamp((b - x) / (b - a), 0.0, 1.0);
}

float max_vec3(in vec3 v)
{
  return max(v.x, max(v.y, v.z));
}

float max3(in float x0, in float x1, in float x2)
{
  return max(x0, max(x1, x2));
}

vec3 div_rem(inout vec3 x, float y)
{
  vec3 r = floor(x / y);
  x -= r * y;
  return r;
}

float round_255(in float x)
{
  // return floor(x * 255.0 + 0.5);
  return round(x * 255.0);
}

vec2 round2_255(in vec2 x)
{
  // return floor(x * 255.0 + 0.5);
  return round(x * 255.0);
}

vec3 round3_255(in vec3 x)
{
  // return floor(x * 255.0 + 0.5);
  return round(x * 255.0);
}

bool pos3_inside(in vec3 pos, in float mi, in float mx)
{
  return pos.x >= mi && pos.y >= mi && pos.z >= mi &&
    pos.x < mx && pos.y < mx && pos.z < mx;
}

bool pos3_inside_3(in vec3 pos, in vec3 mi, in vec3 mx)
{
  return pos.x >= mi.x && pos.y >= mi.y && pos.z >= mi.z &&
    pos.x < mx.x && pos.y < mx.y && pos.z < mx.z;
}

bool pos3_inside_3_ge_le(in vec3 pos, in vec3 mi, in vec3 mx)
{
  return pos.x >= mi.x && pos.y >= mi.y && pos.z >= mi.z &&
    pos.x <= mx.x && pos.y <= mx.y && pos.z <= mx.z;
}

bool pos2_inside(in vec2 pos, in float mi, in float mx)
{
  return min(pos.x, pos.y) >= mi && max(pos.x, pos.y) < mx;
}

bool pos2_inside_2(in vec2 pos, in vec2 mi, in vec2 mx)
{
  return pos.x >= mi.x && pos.y >= mi.y &&
    pos.x < mx.x && pos.y < mx.y;
}

vec3 voxel_get_next(inout vec3 pos_f, in vec3 spmin,
  in vec3 spmax, in vec3 d, out vec3 npos)
{
  vec3 r = vec3(0.0);
  <%if><%is_gl3_or_gles3/>
  vec3 dpos = mix(spmin, spmax, greaterThan(d, vec3(0.0)));
  <%else/>
  vec3 gtz = vec3(greaterThan(d, vec3(0.0)));
  vec3 dpos = <%mix>spmin<%>spmax<%>gtz<%/>;
  <%/>
  vec3 delta = dpos - pos_f;
  vec3 delta_div_d = delta / d;
  vec3 c0 = pos_f.yzx + d.yzx * delta_div_d;
  vec3 c1 = pos_f.zxy + d.zxy * delta_div_d;
  if (pos2_inside_2(vec2(c0.x, c1.x), spmin.yz, spmax.yz)) {
    r.x = d.x > 0.0 ? 1.0 : -1.0;
    npos = vec3(dpos.x, c0.x, c1.x);
  } else if (pos2_inside_2(vec2(c0.y, c1.y), spmin.zx, spmax.zx)) {
    r.y = d.y > 0.0 ? 1.0 : -1.0;
    npos = vec3(c1.y, dpos.y, c0.y);
  } else {
    r.z = d.z > 0.0 ? 1.0 : -1.0;
    npos = vec3(c0.z, c1.z, dpos.z);
  }
  return r;
  /*
  float dxpos = dpos.x;
  float xdelta = delta.x;
  vec2 yz = vec2(c0.x, c1.x);
  // float dxpos = d.x > 0.0 ? spmax.x : spmin.x;
  // float xdelta = dxpos - pos_f.x;
  // vec2 yz = pos_f.yz + d.yz * xdelta / d.x;
  if (d.x != 0.0 && pos2_inside_2(yz, spmin.yz, spmax.yz)) {
    r.x = d.x > 0.0 ? 1.0 : -1.0;
    vec3 npos = vec3(dxpos, yz.xy);
    npos = clamp(npos, spmin, spmax - epsi);
    npos += pos_i;
    pos_i = floor(npos);
    pos_f = npos - pos_i;
    return r;
  }
  float dypos = dpos.y;
  float ydelta = delta.y;
  vec2 zx = vec2(c0.y, c1.y);
  // float dypos = d.y > 0.0 ? spmax.y : spmin.y;
  // float ydelta = dypos - pos_f.y;
  // vec2 zx = pos_f.zx + d.zx * ydelta / d.y;
  if (d.y != 0.0 && pos2_inside_2(zx, spmin.zx, spmax.zx)) {
    r.y = d.y > 0.0 ? 1.0 : -1.0;
    vec3 npos = vec3(zx.y, dypos, zx.x);
    npos = clamp(npos, spmin, spmax - epsi);
    npos += pos_i;
    pos_i = floor(npos);
    pos_f = npos - pos_i;
    return r;
  }
  float dzpos = dpos.z;
  float zdelta = delta.z;
  vec2 xy = vec2(c0.z, c1.z);
  // float dzpos = d.z > 0.0 ? spmax.z : spmin.z;
  // float zdelta = dzpos - pos_f.z;
  // vec2 xy = pos_f.xy + d.xy * zdelta / d.z;
  // if (d.z != 0.0 && pos2_inside_2(xy, spmin.xy, spmax.xy))
  {
    r.z = d.z > 0.0 ? 1.0 : -1.0;
    vec3 npos = vec3(xy, dzpos);
    npos = clamp(npos, spmin, spmax - epsi);
    npos += pos_i;
    pos_i = floor(npos);
    pos_f = npos - pos_i;
    return r;
  }
  */
}

float voxel_collision_sphere(in vec3 v, in vec3 a, in vec3 c,
  in vec3 mul_pt, in float rad2_pt, in bool ura, out bool hit_wall_r,
  out vec3 nor_r)
{
  hit_wall_r = false;
  nor_r = vec3(0.0);
  // vはray単位ベクトル, aは始点(-0.5,0.5)範囲, mul_ptはaからの拡大率,
  // c_ptは球の中心座標, rad2_ptは球の半径の2乗,
  // hit_wallは開始点で衝突していればtrue,
  // 返値len_aeは交点までの距離, 交点は a + v * len_aeで求まる
  vec3 a_pt = mul_pt * a;
  vec3 v_pt = mul_pt * v;
  vec3 c_pt = c;
  float len_v_pt = length(v_pt);
  vec3 v_ptn = normalize(v_pt);
  vec3 ac_pt = c_pt - a_pt; // 始点aから球の中心c
  float len2_ac_pt = dot(ac_pt, ac_pt);
  if ((len2_ac_pt > rad2_pt) == ura) {
    hit_wall_r = true; // 始点がすでに球の内側
    return 0.0;
  }
  float ac_v_pt = dot(ac_pt, v_ptn);
  vec3 d_pt = a_pt + v_ptn * ac_v_pt; // cから視線上に垂線をおろしたた点
  vec3 cd_pt = d_pt - c_pt;
  float len2_cd_pt = dot(cd_pt, cd_pt);
  if (len2_cd_pt > rad2_pt) {
    return 256.0; // 球と直線は接触しない
  }
  <%if><%eq><%get_config dbgval/>1<%/>
  // dbgval = vec4(1.0); hit_wall_r = true; return 0.0;
  <%/>
  float len_de_pt = sqrt(rad2_pt - len2_cd_pt);
  float len_ae_pt = ac_v_pt + (ura ? len_de_pt : -len_de_pt);
  vec3 e_pt = a_pt + v_ptn * len_ae_pt; // 視線が球面と接触する点
  vec3 ce_pt = e_pt - c_pt;
  nor_r = normalize(ce_pt * mul_pt);
  if (ura) {
    nor_r = -nor_r;
  }
  float len_ae = len_ae_pt / len_v_pt;
  return len_ae;
}

<%if><%eq><%stype/>1<%/>

const int tile3_size_log2 = 6;
const int tile3_size = 1 << tile3_size_log2;
  // タイルの最大スケール値。これ以上大きくすると影がピーターパンをおこす
const ivec3 pattex3_size_log2 = <%pattex3_size_log2/>;
const ivec3 pattex3_size = ivec3(1) << pattex3_size_log2;
  // タイルパターンテクスチャの大きさ
const ivec3 maptex3_size_log2 = <%maptex3_size_log2/>;
const ivec3 maptex3_size = ivec3(1) << maptex3_size_log2;
  // タイルマップテクスチャの大きさ
const int virt3_size_log2 =
  max(max(maptex3_size_log2.x, maptex3_size_log2.y), maptex3_size_log2.z)
  + tile3_size_log2;
const int virt3_size = 1 << virt3_size_log2;
  // 長辺仮想サイズ。タイルの最大スケールを使ったときのもの。

const ivec2 voxsurf_size_log2 = <%voxsurf_size_log2/>;
const ivec2 voxsurf_size = ivec2(1) << voxsurf_size_log2;
  // 表面に貼り付ける2dテクスチャの大きさ

uniform <%mediump_sampler3d/> sampler_voxtpat;
  // タイルパターンテクスチャ#0
uniform <%mediump_sampler3d/> sampler_voxtpax;
  // タイルパターンテクスチャ#1
uniform <%mediump_sampler3d/> sampler_voxtmap;
  // タイルマップテクスチャ#0
uniform <%mediump_sampler3d/> sampler_voxtmax;
  // タイルマップテクスチャ#1

uniform sampler2D sampler_voxsurf;
  // 表面に貼り付ける2dテクスチャ

int tilemap_fetch(in vec3 pos, int tmap_mip, int tpat_mip)
{
  // float distance_unit = distance_unit_tmap_mip;
  vec3 curpos_f = pos * virt3_size;
  vec3 curpos_i = div_rem(curpos_f, 1.0);
  vec3 curpos_t = floor(curpos_i / tile3_size);
  vec3 curpos_tr = curpos_i - curpos_t * tile3_size; // 0から15の整数
  <%if><%is_gl3_or_gles3/>
  vec4 value = texelFetch(sampler_voxtmap, ivec3(curpos_t) >> tmap_mip, 
    tmap_mip);
  <%else/>
  vec4 value = <%texture3d/>(sampler_voxtmap, curpos_t / map3_size);
  <%/>
  int node_type = int(round_255(value.a));
  /*
  bool is_pat = (node_type == 1);
  if (is_pat) {
    vec3 curpos_tp = round_255(value.rgb) * tile3_size;
      // 16刻み4096迄
    // distance_unit = distance_unit_tpat_mip;
    <%if><%is_gl3_or_gles3/>
    value = texelFetch(sampler_voxtpat,
      ivec3(curpos_tp + curpos_tr) >> tpat_mip, tpat_mip);
    <%else/>
    value = <%texture3d/>(sampler_voxtpat,
      (curpos_tp + curpos_tr) / pattex3_size);
    <%/>
    // value = vec4(1.0, 1.0, 1.0, 1.0);
    // value.xyz = vec3(0.0);
    node_type = int(round_255(value.a));
  }
  */
  return node_type;
}

int tilemap_fetch_debug(in vec3 pos, int tmap_mip, int tpat_mip)
{
  // float distance_unit = distance_unit_tmap_mip;
  vec3 curpos_f = pos * virt3_size + vec3(0.5);
  vec3 curpos_i = div_rem(curpos_f, 1.0);
  vec3 curpos_t = floor(curpos_i / tile3_size);
  vec3 curpos_tr = curpos_i - curpos_t * tile3_size; // 0から15の整数
  <%if><%is_gl3_or_gles3/>
  ivec3 icp = ivec3(curpos_t);
  vec4 value = texelFetch(sampler_voxtmap, icp, 0);
  <%else/>
  vec4 value = <%texture3d/>(sampler_voxtmap, curpos_t / map3_size);
  <%/>
  int node_type = int(round_255(value.a));
/*
  bool is_pat = (node_type == 1);
  if (is_pat) {
    vec3 curpos_tp = round_255(value.rgb) * tile3_size;
      // 16刻み4096迄
    // distance_unit = distance_unit_tpat_mip;
    <%if><%is_gl3_or_gles3/>
    value = texelFetch(sampler_voxtpat,
      ivec3(curpos_tp + curpos_tr) >> tpat_mip, tpat_mip);
    <%else/>
    value = <%texture3d/>(sampler_voxtpat,
      (curpos_tp + curpos_tr) / pattex3_size);
    <%/>
    // value = vec4(1.0, 1.0, 1.0, 1.0);
    // value.xyz = vec3(0.0);
    node_type = int(round_255(value.a));
  }
*/
  return node_type;
}

int raycast_waffle(inout vec3 pos, in vec3 fragpos, in vec3 ray,
  in vec3 mi, in vec3 mx, in int miplevel)
{
  // 引数の座標はすべてテクスチャ座標
  // TODO: 速くする余地あり
  int tmap_mip = clamp(miplevel - tile3_size_log2, 0, tile3_size_log2);
  int tpat_mip = min(miplevel, tile3_size_log2);
  float dist_max = length(pos - fragpos);
  float di = 2.0;
  float near = 65536.0;
  if (true) { // どっちが速い？
    vec3 d = (mx - mi) / di;
    vec3 dd = d * 0.5 / vec3(virt3_size); // FIXME????
      // voxel境界付近を拾わないようにするために少しずらす
    mi = mi + dd;
    mx = mx - dd;
    d = (mx - mi) / di;
    vec3 ad = d / ray;
    bvec3 ad_nega = lessThan(ad, vec3(0.0));
    vec3 f = mi + d * (0.5 + vec3(ad_nega) * (di - 1.0));
      // adが正ならmiから0.5, 負ならmxから0.5
    ad = abs(ad);
    vec3 a = (f - pos) / ray;
    for (float i = 0.0; i < di; i = i + 1.0, a.x = a.x + ad.x) {
      if (a.x > 0.0 && a.x < dist_max) {
        //vec3 p = pos + ray * a.x; if (!pos3_inside_3(p, mi, mx)) { break; }
        if (tilemap_fetch(pos + ray * a.x, tmap_mip, tpat_mip) != 0) {
          near = min(a.x, near);
          break;
        }
      }
    }
    for (float i = 0.0; i < di; i = i + 1.0, a.y = a.y + ad.y) {
      if (a.y > 0.0 && a.y < dist_max) {
        //vec3 p = pos + ray * a.y; if (!pos3_inside_3(p, mi, mx)) { break; }
        if (tilemap_fetch(pos + ray * a.y, tmap_mip, tpat_mip) != 0) {
          near = min(a.y, near);
          break;
        }
      }
    }
    for (float i = 0.0; i < di; i = i + 1.0, a.z = a.z + ad.z) {
      if (a.z > 0.0 && a.z < dist_max) {
        //vec3 p = pos + ray * a.z; if (!pos3_inside_3(p, mi, mx)) { break; }
        if (tilemap_fetch(pos + ray * a.z, tmap_mip, tpat_mip) != 0) {
          near = min(a.z, near);
          break;
        }
      }
    }
  } else {
    vec3 d = (mx - mi) / di;
    vec3 f = mi + d * 0.5; // + epsilon;
    vec3 ad = d / ray;
    vec3 a = (f - pos) / ray;
    for (float i = 0.0; i < di; i = i + 1.0, a = a + ad) {
      if (a.x > 0.0 && a.x < dist_max) {
        //vec3 p = pos + ray * a.x; if (!pos3_inside_3(p, mi, mx)) { break; }
        // if (tilemap_fetch(pos + ray * a.x, tmap_mip, tpat_mip) == 255) {
        if (tilemap_fetch(pos + ray * a.x, tmap_mip, tpat_mip) != 0) {
          near = min(a.x, near);
        }
      }
      if (a.y > 0.0 && a.y < dist_max) {
        //vec3 p = pos + ray * a.y; if (!pos3_inside_3(p, mi, mx)) { break; }
        // if (tilemap_fetch(pos + ray * a.y, tmap_mip, tpat_mip) == 255) {
        if (tilemap_fetch(pos + ray * a.y, tmap_mip, tpat_mip) != 0) {
          //if (p.z < 0.0001) break;
          near = min(a.y, near);
        }
      }
      if (a.z > 0.0 && a.z < dist_max) {
        //tmap_mip = 0;
        //tpat_mip = 0;
        //vec3 p = pos + ray * a.z; if (!pos3_inside_3(p, mi, mx)) { break; }
        // if (tilemap_fetch(pos + ray * a.z, tmap_mip, tpat_mip) == 255) {
        if (tilemap_fetch(pos + ray * a.z, tmap_mip, tpat_mip) != 0) {
          //if (p.y >= 0.9) break;
          //break;
          near = min(a.z, near);
        }
      }
    }
  }
  // return near < 65535 ? near : -1.0f;
  if (near < 65535.0) {
    pos = pos + ray * near;
    return 1;
  } else {
    return -1;
  } // elseの中に入れないとnvidiaのバグに当たる
}

int raycast_get_miplevel(in vec3 pos, in vec3 campos, in float dist_rnd)
{
  // テクスチャ座標でのposとcamposからmiplevelを決める
  float dist_pos_campos_2 = dot(pos - campos, pos - campos) + 0.0001;
  float dist_log2 = log(dist_pos_campos_2) * 0.5 / log(2.0);
  return int(dist_log2 * 1.0 + dist_rnd * 4.0 + float(virt3_size_log2) - 11.0);
    // TODO: LODバイアス調整できるようにする
}

vec3 tpat_sgn_rotate_tile(in vec3 value, in vec3 rot, in vec3 sgn,
  in float maxval)
{
  // rotとsgnを適用してtpat座標を返す
  if (sgn.x < 0.0) { value.x = maxval - value.x; }
  if (sgn.y < 0.0) { value.y = maxval - value.y; }
  if (sgn.z < 0.0) { value.z = maxval - value.z; }
  if (rot.x != 0.0) { value.xy = value.yx; }
  if (rot.y != 0.0) { value.yz = value.zy; }
  if (rot.z != 0.0) { value.zx = value.xz; }
  return value;
}

vec3 tpat_rotate_valuerot(in vec3 value, in vec3 rot)
{
  if (rot.z != 0.0) { value.zx = value.xz; }
  if (rot.y != 0.0) { value.yz = value.zy; }
  if (rot.x != 0.0) { value.xy = value.yx; }
  return value;
}

void swap_float(inout float a, inout float b)
{
  float t = b;
  b = a;
  a = t;
}

void tpat_sgn_valuerot(in vec3 i_p, in vec3 i_n, in vec3 sgn, out vec3 o_p,
  out vec3 o_n)
{
  o_p = i_p;
  o_n = i_n;
  if (sgn.x < 0) { swap_float(o_p.x, o_n.x); }
  if (sgn.y < 0) { swap_float(o_p.y, o_n.y); }
  if (sgn.z < 0) { swap_float(o_p.z, o_n.z); }
}

vec3 sphere_scale(vec3 v)
{
  // それぞれ2bit。拡大率3は使い道が少ないので8に変換する。
  if (v.x == 3) { v.x = 8; }
  if (v.y == 3) { v.y = 8; }
  if (v.z == 3) { v.z = 8; }
  return v;
}

bool debug_scale = false;

int raycast_tilemap(
  inout vec3 pos, in vec3 campos, in float dist_rand,
  in vec3 eye, in vec3 light,
  in vec3 aabb_min, in vec3 aabb_max, out vec4 value0_r, out vec4 value1_r,
  inout vec3 hit_nor,
  in float selfshadow_para, inout float lstr_para, inout int miplevel,
  in bool enable_variable_miplevel)
  // TODO: enable_variable_miplevel = falseのままがいいか？ 重いときにさらに
  // 重くなるのでメリット薄い。
{
  /*
  { // FIXME
    float vx = maptex3_size_log2.x == 10 ? 1.0 : 0.0;
    float vy = maptex3_size_log2.y == 12 ? 1.0 : 0.0;
    float vz = maptex3_size_log2.z == 7 ? 1.0 : 0.0;
    dbgval = vec4(vx, vy, vz, 1.0);
    return 3;
  }
  */
  // 引数の座標はすべてテクスチャ座標
  // eyeはカメラから物体への向き、lightは物体から光源への向き
  int miplevel0 = miplevel;
    // 0を超えるとtpatをmip、tile3_size_log2を超えるとtmapもmip
  bool mip_detail = false; // 詳細モードかどうか
  if (enable_variable_miplevel && max_vec3(aabb_max - aabb_min) > 0.125f) {
    // 長距離空白のイテレートを速くするために大きいmiplevelから開始する。
    // テクスチャに余白が無いと短冊状に影ができてしまう問題があるので
    // 大きいオブジェクトに限って適用する。
    miplevel = max(miplevel0, 8);
    mip_detail = miplevel0 == miplevel;
  }
  int tmap_mip = clamp(miplevel - tile3_size_log2, 0, tile3_size_log2);
  int tpat_mip = min(miplevel, tile3_size_log2);
  float distance_unit_tmap_mip = float(<%lshift>tile3_size<%>tmap_mip<%/>);
    // tmap mipの1ボクセルの大きさ
  float distance_unit_tpat_mip = float(<%lshift>1<%>tpat_mip<%/>);
    // tpat mipの1ボクセルの大きさ
  vec3 ray = eye;
  vec3 dir = -hit_nor;
  vec3 curpos_f = pos * virt3_size;
  vec3 curpos_i = div_rem(curpos_f, 1.0);
    // posはテクスチャ座標(0,1)。curpos_iはテクスチャ内位置の整数部分、
    // curpos_fは小数部分。raycast処理のあいだ、小数部分が0.0と1.0ちょうど
    // で境界を表すので、整数部分と小数部分を分離して保持する必要がある。
  value0_r = vec4(0.0, 0.0, 0.0, 1.0);
  value1_r = vec4(0.0, 0.0, 0.0, 1.0);
  int hit = -1;
  bool hit_tpat;
  int tpat_coord_mip;
  int hit_tpat_coord_mip;
  vec3 hit_coord;
  vec3 hit_coord_small;
    // 衝突したときのテクスチャ座礁のボクセル内オフセット
  vec4 hit_value = vec4(0.0);
  int node_type = 0;
  int i;
  int imax = <%raycast_iter/>;
    // raycastループ回数の上限。長い影が差すなどの場合、大きくしないと
    // 上限に到達してしまうことがあるが、見た目上大差ないかぎり問題にしない。
    // テクスチャが大きいと128くらいにする必要があるか。
  if (debug_scale) {
    imax = 512;
  }
  for (i = 0; i < imax; ++i) {
    if (mip_detail && hit < 0) {
      // 詳細モードであればカメラからの距離に応じたmiplevelでテクスチャを引く
      vec3 ppos = curpos_i / virt3_size;
      miplevel = clamp(raycast_get_miplevel(ppos, campos, dist_rand), 0, 8);
      tmap_mip = clamp(miplevel - tile3_size_log2, 0, tile3_size_log2);
      tpat_mip = min(miplevel, tile3_size_log2);
      distance_unit_tmap_mip = float(<%lshift>tile3_size<%>tmap_mip<%/>);
      distance_unit_tpat_mip = float(<%lshift>1<%>tpat_mip<%/>);
    }
    vec3 tmap_coord = floor(curpos_i / tile3_size);
      // タイルマップ座標
    vec3 tile_coord = curpos_i - tmap_coord * tile3_size;
      // タイル内座標(0以上tile3_size未満)
    // タイルマップテクスチャを引く
    <%if><%is_gl3_or_gles3/>
    vec4 value = texelFetch(sampler_voxtmap, ivec3(tmap_coord) >> tmap_mip, 
      tmap_mip);
    <%else/>
    vec4 value = <%texture3d/>(sampler_voxtmap, tmap_coord / map3_size);
    <%/>
    node_type = int(round_255(value.a));
    // if (node_type == 255 && !mip_detail && enable_variable_miplevel) {
    if (node_type != 0 && !mip_detail && enable_variable_miplevel) {
      // 詳細モードでなくてfilledと衝突したなら詳細モードに入る
      mip_detail = true;
      // if (tmap_mip == 2) { dbgval = vec4(0.0, 1.0, 1.0, 1.0); }
      continue;
    }
    bool is_pat = (node_type == 1);
    float distance_unit = distance_unit_tmap_mip;
      // 現在見ているボクセルの大きさ。パターン参照のmip0なら1, マップ即値の
      // mip0なら16になる。
    vec3 tpat_rot = vec3(0.0);
      // tpat参照時に適用する軸入れ替え。tpat参照しないときは入れ替えない。
    vec3 tpat_sgn = vec3(1.0);
      // tpat参照時に適用する反転。tpat参照しないときは反転しない。
    vec3 tpat_coord;
      // タイルパターンテクスチャ内の引いた座標を記録しておく。
    vec3 lim_dist_n = vec3(tile3_size);
    vec3 lim_dist_p = vec3(tile3_size);
    if (is_pat) {
      vec3 vp = round3_255(value.rgb);
        // vpは下で変更されてタイルパターン番号を表す
      tpat_rot = div_rem(vp, 128.0);
        // value.rgbの最上位bitがtpat_rot
      tpat_sgn = 1.0 - div_rem(vp, 64.0) * 2.0; // -1 or +1
        // value.rgbの第6bitがtpat_sgn。+1か-1。
      vec3 patscale = div_rem(vp, 32.0);
        // value.rgbの第5bitがpatscale。値が0のとき2倍、1のとき4倍
      int tilesz_log2 = int(patscale.x + patscale.y * 2.0 + patscale.z * 4.0)
        + 1;
      float tilesz = float(1 << tilesz_log2);
      // vpはタイルパターン番号を表す整数。tpat_coord_baseはタイルパターン
      // の始点のテクスチャ内座標で、tilesz刻みの値をとる。
      vec3 tpat_coord_base = vp * tilesz;
      vec3 tile_coord_sc = floor(tile_coord * tilesz / tile3_size);
      // vec3 tile_coord_sc = tile_coord * tilesz / tile3_size;
        // tile_coordはtile3_size未満の値。tile_coord_scはtilesz未満の値
      vec3 tpat_coord_offset = tpat_sgn_rotate_tile(tile_coord_sc,
        tpat_rot, tpat_sgn, tilesz - 1.0);
      tpat_coord = tpat_coord_base + tpat_coord_offset;
        // タイルパターンテクスチャの座標。
      // x tpscaleが1以上ならそのぶんmiplevelを下げる
      // tpat_mipはtilesz_log2がtile3_size_log2のときのtpat miplevelを指す。
      // tilesz_log2がtiel3_size_log2未満ならそのぶんmiplevelを下げる
      tpat_coord_mip = max(tpat_mip - (tile3_size_log2 - tilesz_log2), 0);
      // tpat_coord_mip = max(tpat_mip - tpscale_log2, 0);
      distance_unit = float(
        1 << (tpat_coord_mip + (tile3_size_log2 - tilesz_log2)));
      // distance_unit = float(1 << (tpat_coord_mip + tpscale_log2));
      // タイルパターンテクスチャを引く
      <%if><%is_gl3_or_gles3/>
      value = texelFetch(sampler_voxtpat, ivec3(tpat_coord) >> tpat_coord_mip,
        tpat_coord_mip);
      <%else/>
      value = <%texture3d/>(sampler_voxtpat, (tpat_coord) / pattex3_size);
      <%/>
      node_type = int(round_255(value.a));
      // ここの埋め込み空白値はデフォルトスケール(tile3_size)での境界まで
      // の値をとりうる。スケールされた場合にはそのグリッドまでに抑える
      // 必要がある。
      // lim_dist_n = floor(tile_coord_sc);
      // lim_dist_p = floor(tilesz - 1.0 - tile_coord_sc);
      lim_dist_n = vec3(ivec3(tile_coord_sc) >> tpat_coord_mip);
      lim_dist_p = vec3(ivec3(tilesz - 1.0 - tile_coord_sc)
        >> tpat_coord_mip);
    }
    // curpos_iとcurpos_fを、今いるボクセルの大きさ(distance_unit)を単位と
    // したもの再計算する。curpos_iはdistance_unit刻み、curpos_fは
    // 1.0以下の値になる。本来の現在座標(curpos)は
    // curpos_i + curpos_f * distance_unit で求まる。
    {
      vec3 curpos_i_du = floor(curpos_i / distance_unit);
      vec3 curpos_du_rem = curpos_i - curpos_i_du * distance_unit;
      curpos_f = (curpos_du_rem + curpos_f) / distance_unit;
      curpos_f = clamp(curpos_f, 0.0, 1.0); // FIXME: 必要？
        // curpos_fは(0, 1)範囲の値をとる。
      curpos_i = curpos_i_du * distance_unit;
        // curpos_iはdistance_unit刻みの値をとる。
    }
    // 衝突判定。spminとspmaxは今回のステップで移動可能な範囲のaabb。
    // 空白以外のボクセルでは(0,1)範囲だが、空白のときは埋め込み空白値
    // しだいで広げる。
    vec3 spmin = vec3(0.0);
    vec3 spmax = vec3(1.0);
    // valueにtpat軸入れ替えを適用したものをvaluerotとする
    vec3 valuerot = tpat_rotate_valuerot(round3_255(value.xyz),
      tpat_rot);
    // valuerotを上位下位にわける
    vec3 valuerot_h = floor(valuerot / 16.0);
    vec3 valuerot_l = valuerot - valuerot_h * 16.0;
    if (node_type == 0) { // 空白
      vec3 dist_p;
      vec3 dist_n;
      // 埋め込み空白値を取得し、spminとspmaxに反映させる。
      // valuerot上位下位にtpat反転を適用したものをdist_p, dist_nとする
      tpat_sgn_valuerot(valuerot_h, valuerot_l, tpat_sgn, dist_p, dist_n);
      // tpatスケールしたときに境界にクリップ
      dist_p = min(dist_p, lim_dist_p);
      dist_n = min(dist_n, lim_dist_n);
      if (!debug_scale) {
        spmin = vec3(0.0) - dist_n;
        spmax = vec3(1.0) + dist_p;
      }
    } else {
      bool hit_flag = true;
      bool hit_wall = false;
      if (node_type == 255) {
        // 壁(filled)ボクセル
        hit_wall = true;
      } else {
        // 平面または二次曲面で切断
        vec3 sp_nor;
        float length_ae;
        if (node_type >= 160) {
          // 平面
          float param_d = float(node_type - 208); // -48, +46
          vec3 param_abc = valuerot_h - 8.0; // valuerot_lは未使用
          param_abc = param_abc * tpat_sgn; // tpat sgnを適用
          vec3 coord = (curpos_f - 0.5) * 2.0;
          float dot_abc_p = dot(param_abc, coord);
          float pl = dot_abc_p - param_d; // 正なら現在位置では空白
          hit_wall = pl > 0.0;
          length_ae = (-pl) * 0.5 / dot(param_abc, ray);
          sp_nor = -normalize(param_abc);
        } else {
          // 楕円体
          vec3 sp_scale = floor(valuerot / 64.0); // 上位2bit
          vec3 sp_center = valuerot - sp_scale * 64.0 - 32.0; // 下位6bit
          sp_scale = sphere_scale(sp_scale);
          sp_center = sp_center * tpat_sgn; // tpat sgnを適用
          float sp_radius = float(node_type - 1);
          bool ura = (node_type - 1 > 64);
          if (ura) {
            sp_radius -= 64.0;
          }
          sp_nor = vec3(0.0);
          length_ae = voxel_collision_sphere(ray, curpos_f - 0.5,
            sp_center, sp_scale, sp_radius * sp_radius, ura, hit_wall, sp_nor);
        }
        vec3 tp = curpos_f + ray * length_ae;
        if (hit_wall) {
        } else if (!pos3_inside(tp, 0.0 - epsilon, 1.0 + epsilon)) {
          // 交点がボクセルの外側
          // (断面と境界平面の境目の誤差を見えなくするためにepsilonだけ広げる)
          hit_flag = false;
        } else if (length_ae < 0.0) {
          // 交点が現在位置より手前なので接触しない
          hit_flag = false;
        } else {
          // ボクセル内で断面に接触
          dir = -sp_nor;
          curpos_f = tp;
        }
      }
      // miplevelが0でないときは初期miplevelでのraycastのめり込み対策
      // のためi == hit + 1のときは影にしない(TODO: テストケース)
      // is_tpatのときはその処理はしない(slit1のmiplevel2でテスト)
      // -> FIXME: (11,11,7)でmiplevel autoのときそのようにすると平面切断
      // tpatの影が欠けるので元に戻す。条件詳細に調べる必要あり。
      // if (hit_flag &&
      //   (!is_pat || i != hit + 1 || hit < 0 || miplevel == 0)) {
      if (hit_flag) {
        // 接触した
        if (hit >= 0) {
          // lightが衝突したので影にする
          lstr_para = lstr_para * selfshadow_para;
          break;
        }
        hit_nor = -dir;
        hit = i;
        hit_tpat = is_pat;
        hit_tpat_coord_mip = tpat_coord_mip;
        hit_coord = is_pat ? tpat_coord : tmap_coord;
        hit_coord_small = curpos_f;
        hit_value = value;
        pos = (curpos_i + curpos_f * distance_unit) / virt3_size;
          // eyeが衝突した位置
        // 法線と光が逆向きのときは必ず影(陰)
        float cos_light_dir = dot(light, hit_nor);
        lstr_para = clamp(cos_light_dir * 64.0 - 1.0, 0.0, 1.0);
        if (lstr_para <= 0.0) {
          break;
        }
        if (i == 0 && hit_wall) {
          // raycast始点がすでに石の中にいるのでセルフシャドウは差さない
          break;
        }
        // 影判定開始
        ray = light;
        spmin = vec3(0.0); // TODO: -dir方向へ一回移動するか
        spmax = vec3(1.0);
        // 裏返し球のときは影判定開始ボクセル内で衝突する可能性があるので、
        // ここで判定する。それ以外の形状についてはその可能性はない。
        if (node_type >= 2 + 64 && node_type < 160) {
          bool ura = true;
          bool light_hit_wall = false;
          vec3 sp_scale = floor(valuerot / 64.0); // 上位2bit
          vec3 sp_center = valuerot - sp_scale * 64.0 - 32.0; // 下位6bit
          sp_scale = sphere_scale(sp_scale);
          sp_center = sp_center * tpat_sgn; // tpat sgnを適用
          float sp_radius = float(node_type - 64 - 1) * 1.0;
          vec3 sp_nor = vec3(0.0);
          float length_ae;
          curpos_f = curpos_f + light * 0.01;
          length_ae = voxel_collision_sphere(ray, curpos_f - 0.5,
            sp_center, sp_scale, sp_radius * sp_radius, ura, light_hit_wall,
            sp_nor);
          vec3 tp = curpos_f + ray * length_ae;
          if (length_ae >= 0.0 && pos3_inside(tp, 0.0, 1.0)) {
            lstr_para = lstr_para * selfshadow_para;
            break;
          }
        }
      }
    }
    // ボクセル内で衝突しなかったので、spmin, spmax範囲の境界までrayを伸ばした
    // 座標を取得し、そこへcurpos_iとcurpos_fを移動する。
    vec3 npos;
    dir = voxel_get_next(curpos_f, spmin, spmax, ray, npos);
    npos *= distance_unit;
    vec3 npos_i = min(floor(npos), spmax * distance_unit - 1.0);
    npos_i += dir; // 壁を突破
    npos = npos - npos_i; // 0, 1の範囲に収まっているはず
    curpos_i += npos_i; // ここでdistance_unit無関係の1きざみの値になる。
    curpos_f = npos; // ここでdistance_unit無関係の(0,1)範囲の値になる。
    // もしraycast範囲aabbの外に出たならばループを抜ける。
    bool is_inside_aabb = pos3_inside_3(curpos_i /* + curpos_f */,
      aabb_min * virt3_size, aabb_max * virt3_size);
    if (!is_inside_aabb) {
      break;
    }
  } // for
  if (i == imax) {
    // ループ上限に達した。eye計算中かlight計算中かは両方ありうる。
    lstr_para = 0.0;
    // hit = i; // なんでこの行有効だったのか？
  }
  if (hit >= 0) {
    if (!hit_tpat) {
      <%if><%is_gl3_or_gles3/>
      value1_r = texelFetch(sampler_voxtmax, ivec3(hit_coord) >> tmap_mip, 
        tmap_mip);
      <%else/>
      value1_r = <%texture3d/>(sampler_voxtmax, hit_coord / map3_size);
      <%/>
    } else {
      <%if><%is_gl3_or_gles3/>
      value1_r = texelFetch(sampler_voxtpax,
        ivec3(hit_coord) >> hit_tpat_coord_mip, hit_tpat_coord_mip);
      <%else/>
      value1_r = <%texture3d/>(sampler_voxtpax, (hit_coord) / pattex3_size);
      <%/>
    }
    // voxsurfテスト中。voxel表面に2dテクスチャを貼り付ける。
    if (false) {
      vec3 coord = hit_coord_small;
      coord = coord * 64.0; // voxsurfのタイルサイズ
      ivec2 icoord = clamp(ivec2(coord), 0, 63);
      // coord = vec3(0.0);
      ivec2 surf_coord = icoord + ivec2(64, 0); // タイル(1, 0)
      value1_r = texelFetch(sampler_voxsurf, surf_coord, 0);
      // value1_r = vec4(1.0);
      // value1_r.rgb = coord / 32.0;
      value1_r.a = 0;
      value0_r = value1_r;
    }
    int hit_node_type = int(round_255(hit_value.a));
    value0_r = hit_node_type == 255 ? hit_value : value1_r;
      // value0_rはemissionのrgb値を保持する。filledならprimaryから、それ以外
      // ならsecondaryの色をそのまま使う。
  }
  // if (i > 10) { dbgval = vec4(1.0, 1.0, 0.0, 1.0); }
  // if (hit == 6) { dbgval = vec4(1.0, 0.0, 0.0, 1.0); }
  return hit;
}

// 旧バージョン
int raycast_tilemap_em(
  inout vec3 pos, in vec3 campos, in float dist_rand,
  in vec3 eye, in vec3 light,
  in vec3 aabb_min, in vec3 aabb_max, out vec4 value_r, inout vec3 hit_nor,
  in float selfshadow_para, inout float lstr_para, inout int miplevel,
  in bool enable_variable_miplevel)
{
  // 引数の座標はすべてテクスチャ座標
  // eyeはカメラから物体への向き、lightは物体から光源への向き
  int tmap_mip = clamp(miplevel - tile3_size_log2, 0, tile3_size_log2);
  int tpat_mip = min(miplevel, tile3_size_log2);
  float distance_unit_tmap_mip = float(<%lshift>16<%>tmap_mip<%/>);
  float distance_unit_tpat_mip = float(<%lshift>1<%>tpat_mip<%/>);
  vec3 ray = eye;
  vec3 dir = -hit_nor;
  vec3 curpos_f = pos * virt3_size;
  vec3 curpos_i = div_rem(curpos_f, 1.0);
  value_r = vec4(0.0, 0.0, 0.0, 1.0);
  int hit = -1;
  bool hit_tpat;
  vec3 hit_coord;
  int i;
  const int imax = 256;
  for (i = 0; i < imax; ++i) {
    vec3 curpos_t = floor(curpos_i / tile3_size);
    vec3 curpos_tr = curpos_i - curpos_t * tile3_size; // 0から15の整数
    vec3 tmap_coord = curpos_t;
    <%if><%is_gl3_or_gles3/>
    vec4 value = texelFetch(sampler_voxtmap, ivec3(tmap_coord) >> tmap_mip, 
      tmap_mip);
    <%else/>
    vec4 value = <%texture3d/>(sampler_voxtmap, tmap_coord / map3_size);
    <%/>
    int node_type = int(round_255(value.a));
    bool is_pat = (node_type == 1);
    float distance_unit = distance_unit_tmap_mip;
    vec3 tpat_coord;
    if (is_pat) {
      distance_unit = 1.0;
      vec3 curpos_tp = round3_255(value.rgb) * tile3_size;
        // 16刻み4096迄
      distance_unit = distance_unit_tpat_mip;
      tpat_coord = curpos_tp + curpos_tr;
      <%if><%is_gl3_or_gles3/>
      value = texelFetch(sampler_voxtpat, ivec3(tpat_coord) >> tpat_mip,
        tpat_mip);
      <%else/>
      value = <%texture3d/>(sampler_voxtpat, (tpat_coord) / pattex3_size);
      <%/>
      node_type = int(round_255(value.a));
    }
    // ボクセルの大きさを掛ける。タイルの移動なら16倍
    curpos_t = floor(curpos_i / distance_unit);
    curpos_tr = curpos_i - curpos_t * distance_unit;
    curpos_f = (curpos_tr + curpos_f) / distance_unit;
    curpos_f = clamp(curpos_f, 0.0, 1.0); // FIXME: 必要？
    curpos_i = curpos_t * distance_unit;
      // curpos_iだけはdistance_unit単位にはしない
      // 現在座標は curpos_i + curpos_f * distance_unit で求まる
    // 衝突判定
    vec3 spmin = vec3(0.0);
    vec3 spmax = vec3(1.0);
    vec3 valuerot = round3_255(value.xyz);
    vec3 dist_p = floor(valuerot / 16.0);
    vec3 dist_n = valuerot - dist_p * 16.0;
    if (node_type == 0) { // 空白
      spmin = vec3(0.0) - dist_n;
      spmax = vec3(1.0) + dist_p;
    } else {
      bool hit_flag = true;
      bool hit_wall = false;
      if (node_type == 255) { // 壁
        hit_wall = true;
      } else { // 平面または二次曲面で切断
        // node_type = 208 + 0; 
        // dist_p = vec3(9.0,9.0,9.0);
        vec3 sp_nor;
        float length_ae;
        if (node_type >= 160) {
          // 平面
          float param_d = float(node_type - 208); // -48, +46
          vec3 param_abc = dist_p - 8.0; // dist_nは未使用
          vec3 coord = (curpos_f - 0.5) * 2.0;
          float dot_abc_p = dot(param_abc, coord);
          float pl = dot_abc_p - param_d; // 正なら現在位置では空白
          hit_wall = pl > 0.0;
          length_ae = (-pl) * 0.5 / dot(param_abc, ray);
          sp_nor = -normalize(param_abc);
        } else {
          // 楕円体
          vec3 sp_scale = floor(valuerot / 64.0); // 上位2bit
          vec3 sp_center = valuerot - sp_scale * 64.0 - 32.0; // 下位6bit
          // vec3 sp_scale = dist_p; // 拡大率
          // vec3 sp_center = dist_n - 8.0; // 球の中心の相対位置
          float sp_radius = float(node_type - 1) * 1.0;
          sp_nor = vec3(0.0);
          // ura未対応
          length_ae = voxel_collision_sphere(ray, curpos_f - 0.5,
            sp_center, sp_scale, sp_radius * sp_radius, false, hit_wall,
            sp_nor);
        }
        vec3 tp = curpos_f + ray * length_ae;
        if (hit_wall) {
        } else if (!pos3_inside(tp, 0.0 - epsilon, 1.0 + epsilon)) {
          // 断面と境界平面の境目の誤差を見えなくするためにepsilonだけ広げる
          hit_flag = false;
        } else {
          // ボクセル内で断面に接触
          dir = -sp_nor;
          curpos_f = tp;
        }
      }
      if (hit_flag) {
        // 接触した
        if (hit >= 0) {
          // lightが衝突したので影にする
          lstr_para = lstr_para * selfshadow_para;
          break;
        }
        hit_nor = -dir;
        hit = i;
        hit_tpat = is_pat;
        hit_coord = is_pat ? tpat_coord : tmap_coord;
        pos = (curpos_i + curpos_f * distance_unit) / virt3_size;
          // eyeが衝突した位置
        // 法線と光が逆向きのときは必ず影(陰)
        float cos_light_dir = dot(light, hit_nor);
        lstr_para = clamp(cos_light_dir * 64.0 - 1.0, 0.0, 1.0);
        if (lstr_para <= 0.0) {
          break;
        }
        if (i == 0 && hit_wall) {
          // raycast始点がすでに石の中にいるのでセルフシャドウは差さない
          break;
        }
        // 影判定開始
        ray = light;
        spmin = vec3(0.0); // TODO: -dir方向へ一回移動するか
        spmax = vec3(1.0);
      }
    }
    vec3 npos;
    dir = voxel_get_next(curpos_f, spmin, spmax, ray, npos);
    // if (dot(dir, ray) <= 0.0) { dbgval=vec4(1,1,1,1); return -1; }
    // npos = clamp(npos, spmin, spmax); // FIXME: ???
    npos *= distance_unit;
    vec3 npos_i = min(floor(npos), spmax * distance_unit - 1.0);
    // vec3 npos_i;
    // if (is_pat) {
    //   npos_i = min(floor(npos), spmax - 1.0); // ギリギリボクセル整数部分
    // } else {
    //   npos *= 16.0;
    //   npos_i = min(floor(npos), spmax * 16.0 - 1.0);
    // }
    npos_i += dir; // 壁を突破
    npos = npos - npos_i; // 0, 1の範囲に収まっているはず
    // if (length(npos_i) < 0.1) {
      // dbgval=vec4(0.0,1.0,1.0,1.0);  return -1;
    // }
    curpos_i += npos_i;
    curpos_f = npos;
    bool is_inside_aabb = pos3_inside_3(curpos_i, // + curpos_f
      aabb_min * virt3_size, aabb_max * virt3_size);
    if (!is_inside_aabb) {
      break;
    }
  } // for
  if (i == imax) {
    lstr_para = 0.0;
    // hit = i;
      // なんでこの行有効だったのか？ 新バージョンに合わせて無効化しておく。
  }
  if (hit >= 0) {
    if (!hit_tpat) {
      <%if><%is_gl3_or_gles3/>
      value_r = texelFetch(sampler_voxtmax, ivec3(hit_coord) >> tmap_mip, 
        tmap_mip);
      <%else/>
      value_r = <%texture3d/>(sampler_voxtmax, hit_coord / map3_size);
      <%/>
    } else {
      <%if><%is_gl3_or_gles3/>
      value_r = texelFetch(sampler_voxtpax, ivec3(hit_coord) >> tpat_mip,
        tpat_mip);
      <%else/>
      value_r = <%texture3d/>(sampler_voxtpax, (hit_coord) / pattex3_size);
      <%/>
    }
  }
  // if (i > 35) { dbgval = vec4(1.0, 1.0, 0.0, 1.0); }
  // if (hit > 32) { dbgval = vec4(1.0, 0.0, 0.0, 1.0); } // FIXME
  return hit;
}

<%/>
