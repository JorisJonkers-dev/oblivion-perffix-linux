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


# ---- 3. capture window, graphics queue only, real frames, no stats flood ------------------------------------------
# The stock layer traces every submit of every queue for the whole run, prints the range stats to stderr every
# frame (a 150 MB log in 60 s) and ends a "frame" at every submit. Here:
#   MESA_GPU_RANGES_TRIGGER=<file>   touch it to open a window (the file is removed)
#   MESA_GPU_RANGES_AFTER_SEC=<s>    or open one <s> seconds after the first present
#   MESA_GPU_RANGES_FRAMES=<n>       window length in presents (default 60)
#   neither of the first two set     trace always (old behaviour)
#   MESA_GPU_RANGES_STATS=1          print the stderr range stats again (default: off)
# Outside the window no timestamp is written and submits go straight through. Only the graphics queue is traced
# (async compute / transfer queues are left alone). A frame in the CSV is a present.
sub("layers/radv_utrace_layer.c",
    "struct radv_utrace_timestamps_bo {",
    r'''#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <unistd.h>

static int rw_frames_left;
static int rw_init;
static int rw_after_done;
static double rw_t0;

static double
rw_now(void)
{
   struct timespec ts;
   clock_gettime(CLOCK_MONOTONIC, &ts);
   return ts.tv_sec + ts.tv_nsec * 1e-9;
}

static bool
radv_utrace_window_active(void)
{
   return __atomic_load_n(&rw_frames_left, __ATOMIC_RELAXED) != 0;
}

/* once per vkQueuePresentKHR, under device->utrace.lock */
static void
radv_utrace_window_poll(void)
{
   const char *trig = getenv("MESA_GPU_RANGES_TRIGGER");
   const char *after = getenv("MESA_GPU_RANGES_AFTER_SEC");
   if (!rw_init) {
      rw_init = 1;
      rw_t0 = rw_now();
      if (!trig && !after)
         __atomic_store_n(&rw_frames_left, -1, __ATOMIC_RELAXED);
   }
   int left = __atomic_load_n(&rw_frames_left, __ATOMIC_RELAXED);
   if (left < 0)
      return;
   if (left > 0) {
      left--;
      __atomic_store_n(&rw_frames_left, left, __ATOMIC_RELAXED);
      if (!left)
         fprintf(stderr, "radv: u_trace window closed\n");
      return;
   }
   bool start = false;
   if (trig && access(trig, W_OK) == 0 && unlink(trig) == 0)
      start = true;
   if (after && !rw_after_done && rw_now() - rw_t0 >= atof(after)) {
      start = true;
      rw_after_done = 1;
   }
   if (start) {
      const char *f = getenv("MESA_GPU_RANGES_FRAMES");
      int n = f ? atoi(f) : 60;
      if (n < 1)
         n = 60;
      __atomic_store_n(&rw_frames_left, n, __ATOMIC_RELAXED);
      fprintf(stderr, "radv: u_trace window open (%d frames)\n", n);
   }
}

struct radv_utrace_timestamps_bo {''')
sub("layers/radv_utrace_layer.c",
    "if (cmd_buffer->qf != RADV_QUEUE_GENERAL && cmd_buffer->qf != RADV_QUEUE_COMPUTE &&\n"
    "       cmd_buffer->qf != RADV_QUEUE_TRANSFER)\n      return false;",
    "if (cmd_buffer->qf != RADV_QUEUE_GENERAL || !radv_utrace_window_active())\n      return false;")
sub("layers/radv_utrace_layer.c",
    "!(device->vk.capture_key_pressed || instance->vk.trace_per_submit)",
    "!(radv_utrace_window_active() || (instance->vk.trace_per_submit && 0))")
sub("layers/radv_utrace_layer.c",
    "   if (instance->vk.trace_per_submit) {\n      simple_mtx_lock(&device->utrace.lock);",
    "   if (0) {\n      simple_mtx_lock(&device->utrace.lock);")
sub("layers/radv_utrace_layer.c",
    "   simple_mtx_lock(&device->utrace.lock);\n   u_trace_context_process(device->utrace.context, true);\n   simple_mtx_unlock(&device->utrace.lock);\n\n   return result;\n}\n\nVKAPI_ATTR VkResult VKAPI_CALL\nutrace_BeginCommandBuffer",
    "   simple_mtx_lock(&device->utrace.lock);\n   radv_utrace_window_poll();\n   u_trace_context_process(device->utrace.context, true);\n   simple_mtx_unlock(&device->utrace.lock);\n\n   return result;\n}\n\nVKAPI_ATTR VkResult VKAPI_CALL\nutrace_BeginCommandBuffer")

# stats print off by default; flush the CSV every frame so a killed game keeps its data
ut = d.parent.parent / "util" / "perf" / "u_trace.c"
s = ut.read_text()
old = "      if (utctx->enabled_traces & U_TRACE_TYPE_RANGES) {\n         utctx->accumulated_frame_count++;"
if old not in s:
    raise SystemExit("patch-utrace: stats anchor not found in u_trace.c")
s = s.replace(old, "      if ((utctx->enabled_traces & U_TRACE_TYPE_RANGES) && getenv(\"MESA_GPU_RANGES_STATS\")) {\n         utctx->accumulated_frame_count++;", 1)
old = "print_csv_end_of_frame(struct u_trace_context *utctx)\n{\n}"
if old not in s:
    raise SystemExit("patch-utrace: csv anchor not found in u_trace.c")
s = s.replace(old, "print_csv_end_of_frame(struct u_trace_context *utctx)\n{\n   fflush(utctx->out);\n}", 1)
ut.write_text(s)
