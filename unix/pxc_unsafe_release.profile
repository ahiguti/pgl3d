incdir=/usr/local/share/pxclib/:/usr/share/pxclib/:../../source/
safe_mode=0
detail_error=1
cxx=g++ --std=c++11
cflags=-g -O3 -DNDEBUG -Wall -Wno-empty-body -Wno-tautological-compare -Wno-overloaded-virtual -Wno-unused -Wno-unused-result -Wno-strict-aliasing -Wno-free-nonheap-object -Wno-argument-outside-range -Wno-deprecated-builtins -Wno-deprecated-declarations -I/usr/local/include -I../../.. -I/usr/include/SDL2 -I../../../bullet/src -I/opt/homebrew/include -I/opt/homebrew/include/SDL2 -I../../../imgui -I../../../imgui/backends
ldflags=imgui.cpp imgui_demo.cpp imgui_draw.cpp imgui_impl_opengl3.cpp imgui_impl_sdl2.cpp imgui_tables.cpp imgui_widgets.cpp -L../../../bullet/src/LinearMath -L../../../bullet/src/BulletCollision -L../../../bullet/src/BulletDynamics -L/opt/homebrew/lib -lpthread
