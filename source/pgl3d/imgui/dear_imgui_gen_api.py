#!/usr/bin/env python3

import re

fn = "../../../../imgui/imgui.h"
outfn = 'dear_imgui_api.px'

pgl_imgui_ns = "::pgl3d$n::imgui$n::dear_imgui$n"

funcs = []
enums = []
structs = []
funcs_by_name = {}
enums_by_name = {}
structs_by_name = {}

with open(fn) as fp:
  inside_ns_imgui = False
  cur_enum = None
  cur_enum_is_bitmask = False
  cur_enum_values = []
  cur_struct = None
  cur_struct_fields = []
  for line in fp:
    line = line.strip()
    line_cmt = line.split('//')
    line = line_cmt[0]
    toks = re.split('[ \t]+', line)
    if len(toks) == 0:
      continue
    #print(toks)
    if not inside_ns_imgui:
      if len(toks) == 2 and toks[0] == 'namespace' and toks[1] == 'ImGui':
        print('namespace ImGui')
        inside_ns_imgui = True
        continue
      if cur_enum == None:
        #print(toks)
        if len(toks) >= 2 and toks[0] == 'enum' and toks[1][0:2] == 'Im' \
          and (len(toks) < 3 or toks[3][len(toks[3])-1] != ';'):
          cur_enum = toks[1]
          cur_enum_is_bitmask = True
          cur_enum_values = []
          print('enum', cur_enum)
          continue
      if cur_struct == None:
        if len(toks) == 2 and toks[0] == 'struct' and toks[1][0:2] == 'Im' \
          and toks[1][-1] != ';':
          cur_struct = toks[1]
          cur_struct_fields = []
          print('struct', cur_struct)
          continue
      if cur_enum != None:
        #print(toks)
        if len(toks) >= 3 and toks[0][0:2] == 'Im':
          #print('enumval', cur_enum, toks[0])
          ma_bm = re.match('\s*(\w+)\s*\=\s*1\s*\<\<\s*(\d+)', line)
          ma_en = re.match('\s*(\w+)\s*\=\s*(\-?\d+)', line)
          ma_or = re.match('\s*(\w+)\s*\=\s*([\w\|\s]+)', line)
          ma_en_noval = re.match('([\w\,\s]+)', line)
          if ma_bm != None:
            cur_enum_is_bitmask = True
            n = ma_bm[1]
            print('enumbm', cur_enum, n, int(ma_bm[2]))
            if not n in cur_enum_values:
              cur_enum_values.append(n)
          elif ma_en != None:
            n = ma_en[1]
            print('enumval', cur_enum, n, int(ma_en[2]))
            if not n in cur_enum_values:
              cur_enum_values.append(n)
          elif ma_or != None:
            n = ma_or[1]
            vs = re.split('[\s\|]+', ma_or[2])
            print('enumor', cur_enum, n, vs)
            if not n in cur_enum_values:
              cur_enum_values.append(n)
          elif ma_en_noval != None:
            vs = re.split('[\s\,]+', ma_en_noval[1])
            print('enumnoval', cur_enum, ma_en_noval[1], vs)
            for v in vs:
              if v != '' and not v in cur_enum_values:
                cur_enum_values.append(v)
          else:
            print('enumval skip', cur_enum, toks)
      if cur_struct != None:
        ma = re.match('^(\w+)\s+([\w\,\s]+)\;', line)
        if ma != None:
          ma_vars = re.split('[\s,]+', ma[2])
          print('field', ma[1], ma_vars)
          cur_struct_fields.append([ma[1], ma_vars])
      if len(toks) == 1 and toks[0] == '};':
        if cur_enum != None:
          e = [cur_enum, cur_enum_is_bitmask, cur_enum_values]
          if len(cur_enum_values) != 0:
            enums.append(e)
            enums_by_name[cur_enum] = e
          cur_enum = None
          print('end enum')
          continue
        if cur_struct != None:
          s = [cur_struct, cur_struct_fields]
          if len(cur_struct_fields) != 0:
            structs.append(s)
            structs_by_name[cur_struct] = s
          cur_struct = None
          print('end struct')
          continue
    else:
      if len(toks) >= 1 and toks[0] == '}':
        print('end ns')
        inside_ns_imgui = False
        continue
      ma = re.match('\s*IMGUI_API\s+([^\(]+)\(([^/]*)\);', line)
      if ma != None:
        #print(ma.group(1), ma.group(2))
        s_ret_fn = ma.group(1)
        s_args = ma.group(2)
        ma_fn = re.match('(.*[^\s]+)\s+([^\s]+)', s_ret_fn)
        s_ret = ma_fn.group(1)
        s_fn = ma_fn.group(2)
        e = [s_fn, s_ret, s_args]
        funcs.append(e)
        f = funcs_by_name.get(s_fn, [])
        f.append(e)
        funcs_by_name[s_fn] = f

def get_arg_types(s_args):
  types = []
  names = []
  arg_begin = 0
  paren = 0
  defval = None
  def add_types(s):
    s = s.strip()
    if s == '':
      return
    ma = re.match('(.+)\s+([^\s]+)', s)
    if ma != None:
      types.append(ma[1])
      names.append(ma[2])
    else:
      types.append(s)
      names.append(None)
  epos = len(s_args)
  for i in range(len(s_args)):
    ch = s_args[i]
    if ch == '(':
      paren += 1
    elif ch == ')':
      if paren == 0:
        epos = i
        break
      paren -= 1
    elif ch == ',' and paren == 0:
      if defval == None:
        add_types(s_args[arg_begin:i])
      arg_begin = i + 1
      defval = None
    elif ch == '=' and paren == 0:
      if defval == None:
        add_types(s_args[arg_begin:i])
      defval = i
  if defval == None:
    add_types(s_args[arg_begin:epos])
  return types, names

c_to_px = {
  'void': 'void',
  'bool': 'bool',
  'bool*': 'bool mutable&',
  'int': 'int',
  'int*': 'int mutable&',
  'size_t': 'size_t',
  'ImU32': 'uint',
  'const char*': 'cstrref const&',
  'ImGuiKey': 'ImGuiKey',
  'float': 'float',
  'float&': 'float mutable&',
  'ImVec2': 'ImVec2',
  'const ImVec2&': 'ImVec2 const&',
  'ImGuiCond': 'ImGuiCond',
  'ImGuiCol': 'ImGuiCol',
  'const ImVec4&': 'ImVec4 const&',
  'ImGuiStyleVar': 'ImGuiStyleVar',
  ####
  'ImGuiWindowFlags': 'ImGuiWindowFlags',
  'ImGuiChildFlags': 'ImGuiChildFlags',
  'ImGuiID': 'ImGuiID',
  'ImGuiFocusedFlags': 'ImGuiFocusedFlags',
  'ImGuiHoveredFlags': 'ImGuiHoveredFlags',
  'ImGuiButtonFlags': 'ImGuiButtonFlags',
  'ImGuiDir': 'ImGuiDir',
  'ImGuiIO&': 'ImGuiIO mutable&',
  'ImGuiStyle&': 'ImGuiStyle mutable&',
  ####
  '...': '',
  'va_list': '',
  'void*': '',
  'const void*': '',
  'ImGuiContext*': '',
  'ImFontAtlas*': '',
  'ImGuiStyle*': '',
  'ImDrawData*': '',
  'ImDrawList*': '',
  'ImGuiSizeCallback': '',
  'ImFont*': '',
}

print('output file', outfn)
fp = open(outfn, 'w')

print('''
/* this file is generated by dear_imgui_gen_api.py */
private threaded namespace pgl3d::imgui::dear_imgui_api "use-unsafe";
public import core::common -;
private import core::pointer::raw -;

extern "types" inline
#include "imgui.h"
;

public pure tsvaluetype struct extern "::ImGuiID" "extuint" ImGuiID { }
''', file=fp)

type_extattr = {
  'ImVec2': ' ',
  'ImVec4': ' ',
  'ImGuiKeyData': ' ',
  'ImGuiIO': '"nonmovable" ',
  'ImGuiStyle': '"nonmovable" ',
}

for st in structs:
  st_name = st[0]
  fields = st[1]
  extattr = type_extattr.get(st_name)
  if extattr == None:
    print('SKIP struct ' + st_name)
    continue
  print('public pure tsvaluetype struct extern "::' + st_name + '" '
    + extattr + st_name + ' {', file=fp)
  for fld in fields:
    fldtype = fld[0]
    fldvars = fld[1]
    for v in fldvars:
      ft = c_to_px.get(fldtype)
      if ft != None:
        print('  public ' + ft + ' ' + v + ';', file=fp)
  print('}', file=fp)

for en in enums:
  en_name = en[0]
  if en_name[-1] == '_':
    en_name = en_name[0:-1]
  en_is_bitmask = en[1]
  en_vals = en[2]
  if en_is_bitmask:
    print('public pure tsvaluetype struct extern "int" "extbitmask" '
      + en_name + ' { }', file=fp)
  else:
    print('public pure tsvaluetype struct extern "int" "extenum" ' +
      en_name + ' { }', file=fp)
  for v in en_vals:
    print('public extern "::ImGui::%" ' + en_name + ' ' + v + ';', file=fp)

wrapper_funcs = []

for func in funcs:
  s_fn = func[0]
  s_ret = func[1]
  s_args = func[2]
  types, names = get_arg_types(s_args)
  if types == None:
    print('SKIP FN', s_fn)
    continue
  print('FN', s_fn, '(' + s_ret + ')', s_args)
  def map_dict(s):
    r = c_to_px.get(s)
    if r != None:
      return r
    if enums_by_name.get(s + '_') != None:
      return s
    return None
  px_types = [ map_dict(s) for s in types ]
  px_ret = map_dict(s_ret)
  if None in px_types or '' in px_types or px_ret == None or px_ret == '':
    print('SKIP', s_ret, s_fn, types, 'pxret', px_ret, 'pxargs', px_types)
  elif '&' in s_ret or '*' in s_ret:
    # 参照やポインタを返す関数は、返値をpxc側でrootできないので直接呼べない
    print('SKIP REF', s_ret, s_fn, types, 'pxret', px_ret, 'pxargs', px_types)
  elif len(funcs_by_name[s_fn]) > 1:
    print('SKIP OV', s_ret, s_fn, types, 'pxret', px_ret, 'pxargs', px_types)
  else:
    print('GEN ret', s_ret, 'fn', s_fn, 'args', px_types)
    # nul終端文字列または生の配列が引数に現れるときはwrap関数を作る。
    need_wrap = 'cstrref const&' in px_types
    if True in [ '[' in s for s in names ]:
      need_wrap = True
    if True in [ s[-1:] == '*' for s in types ]:
      need_wrap = True
    extsym = pgl_imgui_ns + '::%_wrap' if need_wrap else '::ImGui::%'
    fp.write('public threaded function extern "' + extsym + '" ' + px_ret + ' '
      + s_fn + '(')
    wargs = []
    for i in range(len(px_types)):
      pt = px_types[i]
      name = names[i] if names[i] else 'a' + str(i)
      arr = None
      ma = re.match('(\w+)\[(\d+)\]', name)
      # 始点と終点を引数で渡しているものについては一つのsliceにまとめる
      skip_flag = False
      if (name[-4:] == '_end' or name[-4:] == '_max') \
        and pt == 'cstrref const&':
        skip_flag = True
      if name[-4:] == '_end' and pt == 'int mutable&':
        skip_flag = True
      if i + 1 < len(px_types) and pt == 'int mutable&' and \
        px_types[i + 1] == 'int mutable&' and names[i + 1][-4:] == '_end':
        px_types[i] = 'slice{int} const&'
        pt = px_types[i]
      if ma != None:
        pt = 'farray{' + pt + ', ' + ma[2] + '} const&'
        arr = ['farray', pt, ma[2], types[i]]
        name = ma[1]
      if not skip_flag:
        if i != 0:
          fp.write(', ')
        fp.write(pt + ' ' + name)
      wargs.append([pt, name, arr, skip_flag])
    fp.write(');\n')
    if need_wrap:
      wrapper_funcs.append(
        [s_fn, s_ret, s_args, types, px_ret, px_types, wargs]);

print('extern "implementation" inline', file=fp)
print('namespace pgl3d$n {', file=fp)
print('namespace imgui$n {', file=fp)
print('namespace dear_imgui$n {', file=fp)

for wfunc in wrapper_funcs:
  s_fn, s_ret, s_args, types, px_ret, px_types, wargs = wfunc
  fp.write(s_ret + ' ' + s_fn + '_wrap(')
  for i in range(len(wargs)):
    pxtyp, name, arr, skip_flag = wargs[i]
    if skip_flag:
      continue
    t = types[i]
    if pxtyp == 'cstrref const&':
      t = '::pxcrt::bt_cslice< ::pxcrt::bt_uchar > const&'
    elif pxtyp == 'slice{int} const&':
      t = '::pxcrt::bt_slice< ::pxcrt::bt_int > const&'
    elif arr != None:
      container, px_etyp, num, etyp = wargs[i][2]
      t = '::pxcrt::farray< ' + etyp + ', ' + num + ' >&'
    elif t[-1:] == '*':
      t = t[0:-1] + '&'
    if i != 0:
      fp.write(', ')
    fp.write(t + ' ' + name)
  fp.write(") {\n")
  names_cv = []
  for i in range(len(wargs)):
    name = wargs[i][1]
    skip_flag = wargs[i][3]
    skip_flag_next = wargs[i+1][3] if i + 1 < len(wargs) else False
    if px_types[i] == 'cstrref const&':
      if skip_flag_next:
        names_cv.append('reinterpret_cast<const char *>(' + name +
          '.rawarr())')
      elif skip_flag:
        name_prev = wargs[i - 1][1]
        names_cv.append('reinterpret_cast<const char *>(' + name_prev +
          '.rawarr()) + ' + name_prev + '.size()')
      else:
        fp.write('  PXCRT_ALLOCA_NTSTRING(' + name + '_nt, ' + name + ");\n")
        names_cv.append(name + '_nt.get()')
    elif types[i][-1:] == '*':
      if skip_flag_next:
        names_cv.append(name + '.rawarr()')
      elif skip_flag:
        name_prev = wargs[i - 1][1]
        names_cv.append(name_prev + '.rawarr() + ' + name_prev + '.size()')
      else:
        names_cv.append('&' + name)
    elif wargs[i][2] != None:
      names_cv.append(name + '.rawarr()')
    else:
      names_cv.append(name)
  fp.write('  return ')
  fp.write(' ::ImGui::' + s_fn + '(')
  for i in range(len(wargs)):
    name = names_cv[i]
    if i != 0:
      fp.write(', ')
    fp.write(name)
  fp.write(");\n")
  fp.write("}\n")

print('};', file=fp)
print('};', file=fp)
print('};', file=fp)
print(';', file=fp)

