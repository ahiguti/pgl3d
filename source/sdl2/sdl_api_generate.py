#!/usr/bin/env python3
"""Generate PXC SDL2 bindings from SDL headers."""

from __future__ import annotations

import os
import re
from pathlib import Path
from typing import List, Tuple

SDL_INCLUDE_PATH = os.environ.get("SDL_INCLUDE_PATH", "/usr/include/SDL2")
SDL_NAMESPACE = os.environ.get("SDL_NAMESPACE", "sdl2")

type_ucount: dict[str, int] = {}
struct_defs: dict[str, Tuple[str, List[List[str]]]] = {}
enum_defs: dict[str, List[List[str]]] = {}
function_defs: dict[str, Tuple[str, List[List[str]]]] = {}
type_defs: dict[str, List[str]] = {}
unnamed_enum_defs: List[List[str]] = []
macro_defs: dict[str, int] = {}
defined_types: dict[str, int] = {}
integral_types: dict[str, str] = {}

THREAD_PATTERNS = [
    re.compile(pattern)
    for pattern in [
        r"^SDL_RW",
        r"^SDL_FreeRW",
        r"^SDL_Surface",
        r"^IMG_Load",
        r"^SDL_FreeSurface",
        r"^SDL_CreateRGBSurface",
        r"^SDL_UpperBlit",
        r"^TTF_",
    ]
]


def drop_space(value: str) -> str:
    return value.strip()


def normalize_type(value: str) -> str:
    text = drop_space(value)
    text = text.replace("*", " * ")
    text = re.sub(r"\s+", " ", text)
    text = drop_space(text)
    type_ucount[text] = type_ucount.get(text, 0) + 1
    for token in text.split(" "):
        type_ucount[token] = type_ucount.get(token, 0) + 1
    return text


def parse_arg(value: str) -> List[str]:
    text = drop_space(value)
    match = re.match(r"^(.+\W)(\w+)\s*\[\s*(\d+)\s*\]$", text)
    if match:
        type_decl = f"{match.group(1)}[{match.group(3)}]"
        return [normalize_type(type_decl), drop_space(match.group(2))]
    match = re.match(r"^(.+\W)(\w+)\s*\[\s*(\w+)\s*\]$", text)
    if match:
        type_decl = f"{match.group(1)}[]"
        return [normalize_type(type_decl), drop_space(match.group(2))]
    match = re.match(r"^(.+\W)(\w+)$", text)
    if match:
        return [normalize_type(match.group(1)), drop_space(match.group(2))]
    return [normalize_type(text), ""]


def drop_comments(lines: List[str]) -> None:
    comment_flag = False
    for idx, line in enumerate(lines):
        chars = list(line)
        prev_char = ""
        for pos, char in enumerate(chars):
            if comment_flag:
                chars[pos] = " "
                if prev_char == "*" and char == "/":
                    comment_flag = False
                    chars[pos] = " "
                    if pos > 0:
                        chars[pos - 1] = " "
            else:
                if prev_char == "/" and char == "*":
                    comment_flag = True
                    chars[pos] = " "
                    if pos > 0:
                        chars[pos - 1] = " "
            prev_char = char
        lines[idx] = "".join(chars)


def push_field_if(target: List[List[str]], value: str) -> None:
    if "(" in value:
        return
    comma_match = re.search(r"([^,]+),(.+)", value)
    if comma_match:
        head = comma_match.group(1)
        remainder = comma_match.group(2)
        head_match = re.match(r"(.+\W)(\w+)", head)
        if not head_match:
            raise RuntimeError(f"failed to parse struct field: [{value}]")
        type_spec = normalize_type(head_match.group(1))
        first_name = drop_space(head_match.group(2))
        target.append([type_spec, first_name])
        for element in remainder.split(","):
            if "[" in element or "*" in element:
                continue
            target.append([type_spec, drop_space(element)])
        return
    arg = parse_arg(value)
    if arg[1] == "function":
        return
    target.append(arg)


def pxc_type_string(type_string: str) -> str:
    tokens = drop_space(type_string).split(" ")
    result = ""
    const_flag = False
    for token in tokens:
        if token == "*":
            if result == "char":
                result = "ccharptr" if const_flag else "charptr"
            else:
                result = f"crawptr{{{result}}}" if const_flag else f"rawptr{{{result}}}"
            const_flag = False
        elif re.fullmatch(r"\[(\d+)\]", token):
            length = re.fullmatch(r"\[(\d+)\]", token).group(1)
            result = f"rawarray{{{result}, {length}}}"
            raise RuntimeError(f"rawarray type: {result}")
        elif token == "[]":
            result = f"rawarray{{{result}, 0}}"
            const_flag = False
        elif token == "const":
            const_flag = True
        elif token == "struct":
            continue
        elif result == "" or result == "unsigned":
            result = token if result == "" else f"u{token}"
            if defined_types.get(result) is None:
                raise RuntimeError(f"unknown type: [{result}]")
        else:
            raise RuntimeError(f"invalid type: [{type_string}]")
    if not result:
        raise RuntimeError(f"invalid type: [{type_string}]")
    return result


def read_header_file(path: Path) -> None:
    with path.open("r", encoding="utf-8", errors="ignore") as handle:
        raw_lines = [line.rstrip("\n") for line in handle]
    lines = [line if line else " " for line in raw_lines]
    drop_comments(lines)
    index = 0
    total = len(lines)
    while index < total:
        line = lines[index]
        func_match = re.search(r"extern\s+DECLSPEC\s+(.+?)SDLCALL\s+(.+)", line)
        if func_match:
            rettype = normalize_type(func_match.group(1))
            proto = func_match.group(2)
            while ";" not in proto:
                index += 1
                if index >= total:
                    raise RuntimeError(f"FUNCDEF {proto}")
                proto += lines[index]
            proto = proto.replace("\n", " ")
            proto = re.sub(r"\s+", " ", proto)
            proto_match = re.search(r"(\w+)\s*\(([^)]*)\)", proto)
            if proto_match:
                func_name = proto_match.group(1)
                args_str = proto_match.group(2)
                if "(" not in args_str and "." not in args_str:
                    args: List[List[str]] = []
                    if drop_space(args_str):
                        for pos, part in enumerate(args_str.split(",")):
                            parsed = parse_arg(part)
                            if not parsed[1]:
                                parsed[1] = f"_{pos}"
                            args.append(parsed)
                    if len(args) == 1 and args[0][0] == "void":
                        args = []
                    for idx_arg, arg in enumerate(args):
                        if not arg[1]:
                            arg[1] = f"_{idx_arg}"
                    function_defs[func_name] = (rettype, args)
                else:
                    pass
                print(f"FUNCDECL [{proto}]")
            else:
                print(f"can not parse funcdecl: [{proto}]")
                print(f"FUNCDECL [{proto}]")
            index += 1
            continue
        typedef_simple = re.search(r"typedef\s+([\w\s\*]+);", line)
        if typedef_simple:
            parsed = parse_arg(typedef_simple.group(1))
            tds, tdn = parsed[0], parsed[1]
            print(f"TYPEDEF STRUCT [{tds}] [{tdn}]")
            type_defs[tdn] = [tds]
            defined_types[tdn] = 1
            index += 1
            continue
        if "#define" not in line and re.search(r"typedef\s+(struct|union)", line):
            values: List[List[str]] = []
            current = line
            while "{" not in current:
                index += 1
                if index >= total:
                    return
                current = lines[index]
            brace_count = 0
            while True:
                if "}" in current:
                    if brace_count <= 1:
                        single = re.search(r"\{\s*([^;\}]+)\s*;\s*\}", current)
                        if single:
                            push_field_if(values, single.group(1))
                        break
                    brace_count -= current.count("}")
                elif brace_count == 1:
                    field_match = re.match(r"^\s*([^;\)]+);\s*$", current)
                    if field_match:
                        push_field_if(values, field_match.group(1))
                if "{" in current:
                    brace_count += current.count("{")
                index += 1
                if index >= total:
                    raise RuntimeError(f"STRUCT {line} [{brace_count}]")
                current = lines[index]
            name_match = re.search(r"\}\s*(.+);", current)
            if not name_match:
                raise RuntimeError(f"can not parse typedef struct: [{current}]")
            words = name_match.group(1).split()
            tdn = words[-1]
            fields_repr = ",".join(":".join(item) for item in values)
            print(f"TYPEDEF STRUCT {fields_repr} [{tdn}]")
            struct_defs[tdn] = (tdn, values)
            defined_types[tdn] = 1
            index += 1
            continue
        if re.search(r"(typedef\s+)?\benum", line):
            values: List[str] = []
            current = line
            while "{" not in current:
                index += 1
                if index >= total:
                    raise RuntimeError(f"enum start not found in {path}")
                current = lines[index]
            while True:
                if "}" in current:
                    single = re.search(r"\{\s*(\w+)\s*\}", current)
                    if single:
                        values.append(single.group(1))
                    break
                if "{" not in current:
                    token_match = re.match(r"^\s*(\w+)(.*)$", current)
                    if token_match:
                        word, remainder = token_match.groups()
                        if "(" not in current and ")" not in current or "=" in remainder:
                            values.append(word)
                        while True:
                            if re.search(r",\s*$", current):
                                break
                            if "}" in current:
                                index -= 1
                                break
                            index += 1
                            if index >= total:
                                raise RuntimeError(f"enum continuation failed in {path}")
                            current = lines[index]
                index += 1
                if index >= total:
                    raise RuntimeError(f"enum parse error in {path}")
                current = lines[index]
            name_match = re.search(r"\}\s*(\w*)", current)
            if not name_match:
                raise RuntimeError(f"can not parse typedef enum: [{current}] {path}")
            tdn = name_match.group(1)
            unique_vals = sorted({val for val in values})
            values_repr = ",".join(unique_vals)
            print(f"TYPEDEF ENUM {{{values_repr}}} [{tdn}]")
            if tdn:
                enum_defs[tdn] = [unique_vals]
                defined_types[tdn] = 1
            else:
                unnamed_enum_defs.append(unique_vals)
            index += 1
            continue
        if line.lstrip().startswith("#"):
            print(f"PREPROCESSOR 0 {line}")
            if line.lstrip().startswith("#if"):
                if re.search(r"(__WIN32__|__WINRT__|__IPHONEOS__|ANDROID)", line):
                    nest = 1
                    while nest > 0:
                        index += 1
                        if index >= total:
                            raise RuntimeError("endif notfound")
                        current = lines[index]
                        if current.lstrip().startswith("#endif"):
                            nest -= 1
                        elif current.lstrip().startswith("#if"):
                            nest += 1
            else:
                define_match = re.match(r"^\s*#define\s+(\w+)(.*)", line)
                if define_match:
                    name, remainder = define_match.groups()
                    if remainder.lstrip().startswith("("):
                        print(f"skip macro {line}")
                    else:
                        print(f"MACRO {name}")
                        if name.startswith("SDL_INIT_") or name.startswith("SDL_WINDOWPOS_"):
                            macro_defs[name] = 1
            index += 1
            continue
        index += 1


def initialize_types() -> None:
    for item in [
        "void",
        "uint",
        "uchar",
        "int",
        "char",
        "ulong",
        "long",
        "float",
        "double",
        "unsigned",
    ]:
        defined_types[item] = 1
    for item in [
        "int8_t",
        "int16_t",
        "int32_t",
        "int64_t",
        "Sint8",
        "Sint16",
        "Sint32",
        "Sint64",
    ]:
        integral_types[item] = "extint"
        defined_types[item] = 1
    for item in [
        "uint8_t",
        "uint16_t",
        "uint32_t",
        "uint64_t",
        "Uint8",
        "Uint16",
        "Uint32",
        "Uint64",
        "uintptr_t",
        "size_t",
    ]:
        integral_types[item] = "extuint"
        defined_types[item] = 1
    for name in integral_types:
        type_defs.pop(name, None)
        struct_defs.pop(name, None)


def write_type_file(path: Path) -> None:
    with path.open("w", encoding="utf-8") as handle:
        handle.write(
            f"/* This file is generated by sdl_px_apigen.pl */\n"
            f"public threaded namespace {SDL_NAMESPACE}::api_types \"use-unsafe\";\n"
            f"public import core::common -;\n"
            f"private import core::pointer::raw -;\n"
            f"public import core::container::raw -;\n"
            f"public import {SDL_NAMESPACE}::api_base -;\n"
            f"public import core::meta m;\n"
        )
        for tdn in sorted(type_defs):
            tds = type_defs[tdn][0]
            if not tds.endswith("*"):
                integral = integral_types.get(tds)
                if integral:
                    handle.write(
                        f"public pure multithreaded struct extern \"%\" \"{integral}\" {tdn} {{ }}\n"
                    )
                else:
                    if tdn == "SDL_bool":
                        continue
                    handle.write(
                        f"public pure multithreaded struct extern \"%\" {tdn} {{ }}\n"
                    )
            else:
                handle.write(
                    f"public pure multithreaded struct extern \"%\" \"extenum\" {tdn} {{ }}\n"
                )
        for tdn in sorted(struct_defs):
            value = struct_defs[tdn]
            handle.write(f"public pure multithreaded struct extern \"%\"\n{value[0]} {{\n")
            for field in value[1]:
                try:
                    field_type = pxc_type_string(field[0])
                    handle.write(f"  public {field_type} {field[1]};\n")
                except RuntimeError:
                    handle.write(f"  /* public {field[0]} {field[1]}; */\n")
            handle.write("}\n")
        for tdn in sorted(enum_defs):
            enum_values = enum_defs[tdn][0]
            is_typed = tdn in type_ucount
            enum_type = tdn if is_typed else "SDL_Enum"
            if is_typed:
                handle.write(
                    f"public pure multithreaded struct extern \"int\" \"extenum\" {tdn} {{ }}\n"
                )
            else:
                handle.write(f"/* enum {tdn} */\n")
            for symbol in enum_values:
                handle.write(f"public extern \"%\" {enum_type} {symbol};\n")
        for enum_list in unnamed_enum_defs:
            handle.write("/* unnamed enum */\n")
            for symbol in enum_list:
                handle.write(f"public extern \"%\" SDL_Enum {symbol};\n")
        for name in sorted(macro_defs):
            handle.write(f"public extern \"%\" SDL_Enum {name}; /* macro */\n")


def write_function_file(path: Path) -> None:
    with path.open("w", encoding="utf-8") as handle:
        handle.write(
            f"/* This file is generated by sdl_px_apigen.pl */\n"
            f"public threaded namespace {SDL_NAMESPACE}::api_functions \"export-unsafe\";\n"
            f"public import core::common -;\n"
            f"public import core::pointer::raw -;\n"
            f"public import core::container::raw -;\n"
            f"public import {SDL_NAMESPACE}::api_base -;\n"
            f"public import {SDL_NAMESPACE}::api_types -;\n"
            f"public import core::meta m;\n"
        )
        for func_name in sorted(function_defs):
            if func_name.startswith("SDL_GDK"):
                continue
            rettype_raw, args_raw = function_defs[func_name]
            try:
                retts = pxc_type_string(rettype_raw)
                parts: List[str] = []
                for argument in args_raw:
                    arg_type = pxc_type_string(argument[0])
                    arg_name = argument[1]
                    parts.append(f"{arg_type}{(' ' + arg_name) if arg_name else ''}")
                argstr = ", ".join(parts)
            except RuntimeError:
                fallback_args = ", ".join(
                    f"{argument[0]} {argument[1]}".strip()
                    for argument in args_raw
                )
                handle.write(
                    f"/* public function extern \"%\" {rettype_raw} {func_name}({fallback_args}); */\n"
                )
                continue
            attr = "public"
            for pattern in THREAD_PATTERNS:
                if pattern.search(func_name):
                    attr = "public threaded"
                    break
            handle.write(
                f"{attr} function extern \"%\" {retts} {func_name}({argstr});\n"
            )


def main() -> None:
    include_paths = [drop_space(item) for item in SDL_INCLUDE_PATH.split(":") if drop_space(item)]
    for include_path in include_paths:
        directory = Path(include_path)
        if not directory.is_dir():
            raise FileNotFoundError(include_path)
        header_names = sorted(entry.name for entry in directory.iterdir() if entry.name.endswith(".h"))
        for header in header_names:
            print(f"reading {directory / header}")
            read_header_file(directory / header)
    initialize_types()
    for name in [
        "SDL_GameControllerMappingForGUID",
        "SDL_MemoryBarrierAcquire",
        "SDL_MemoryBarrierRelease",
    ]:
        function_defs.pop(name, None)
    script_dir = Path(__file__).resolve().parent
    write_type_file(script_dir / "api_types.px")
    write_function_file(script_dir / "api_functions.px")


if __name__ == "__main__":
    main()
