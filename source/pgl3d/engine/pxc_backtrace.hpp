
// -include "source/pgl3d/engine/pxc_backtrace.hpp"

namespace pxcrt {

struct pxc_backtrace_entry {
  const char *name;
};

extern thread_local pxc_backtrace_entry thr_pxc_backtrace_entries[1024];
extern thread_local unsigned thr_pxc_backtrace_entries_cur;

struct pxc_backtrace_entry_object {
  pxc_backtrace_entry_object(const char *name) {
    unsigned i = thr_pxc_backtrace_entries_cur++;
    if (i < 1024) {
      thr_pxc_backtrace_entries[i] = { name };
    }
  }
  ~pxc_backtrace_entry_object() {
    --thr_pxc_backtrace_entries_cur;
  }
};

};

#define PXC_FUNCTION_ENTRY(name, src) \
  pxcrt::pxc_backtrace_entry_object const pxc_function_entry_o(name ## src)
#define PXC_ENABLE_PXC_BACKTRACE

