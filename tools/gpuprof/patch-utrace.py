#!/usr/bin/env python3
"""Patch Mesa's RADV u_trace tracepoints (run from the Mesa source tree: patch-utrace.py src/amd/vulkan)."""
import pathlib
import sys

d = pathlib.Path(sys.argv[1])


def sub(path, old, new):
    p = d / path
    s = p.read_text()
    if old not in s:
        raise SystemExit(f"patch-utrace: anchor not found in {path}: {old[:60]!r}")
    p.write_text(s.replace(old, new, 1))


# 1. pipeline hash on draw / dispatch tracepoints
sub("radv_tracepoints.py",
    "entrypoints_builder = CodeBuilder(0)\n",
    """GFX_PIPE = ArgInfo('uint64_t', r'0x%016lx', 'pipeline',
                   'cmd_buffer->state.graphics_pipeline ? cmd_buffer->state.graphics_pipeline->base.pipeline_hash : 0')
CS_PIPE = ArgInfo('uint64_t', r'0x%016lx', 'pipeline',
                  'cmd_buffer->state.compute_pipeline ? cmd_buffer->state.compute_pipeline->base.pipeline_hash : 0')
for _name, _info in ENTRYPOINT_TRACEPOINTS.items():
    if _info.category == 'draw':
        _info.args = _info.args + [GFX_PIPE]
    elif _info.category == 'dispatch':
        _info.args = _info.args + [CS_PIPE]

entrypoints_builder = CodeBuilder(0)
""")
sub("radv_tracepoints.py",
    "entrypoints_builder.add('#include \"radv_entrypoints.h\"')\n",
    "entrypoints_builder.add('#include \"radv_entrypoints.h\"')\n"
    "entrypoints_builder.add('#include \"radv_pipeline_graphics.h\"')\n"
    "entrypoints_builder.add('#include \"radv_pipeline_compute.h\"')\n")

# 2. render area on vkCmdBeginRendering
sub("radv_tracepoints.py",
    "begin_end_tp('rendering')\n",
    "begin_end_tp('rendering', tp_args=[Arg(type='uint32_t', var='width', c_format=r'%u'),\n"
    "                                   Arg(type='uint32_t', var='height', c_format=r'%u'),\n"
    "                                   Arg(type='uint32_t', var='colors', c_format=r'%u')])\n")
sub("layers/radv_utrace_layer.c",
    "trace_radv_begin_rendering(cmd_buffer->utrace.trace, cmd_buffer);",
    "trace_radv_begin_rendering(cmd_buffer->utrace.trace, cmd_buffer, pRenderingInfo->renderArea.extent.width,\n"
    "                              pRenderingInfo->renderArea.extent.height, pRenderingInfo->colorAttachmentCount);")
