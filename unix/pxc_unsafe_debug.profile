incdir=/usr/local/share/pxclib/:/usr/share/pxclib/:.
safe_mode=0
cxx=g++ --std=c++11
cflags=-g -O0 -DDEBUG -Wall -Wno-unknown-warning-option -Wno-empty-body -Wno-tautological-compare -Wno-overloaded-virtual -Wno-unused -Wno-extern-c-compat -Wno-strict-aliasing -Wno-free-nonheap-object -I/usr/local/include -I../.. -I/usr/include/SDL2 -I../../bullet/src -I/opt/homebrew/include -I/opt/homebrew/include/SDL2 -I../../imgui
ldflags=-L../../bullet/src/LinearMath -L../../bullet/src/BulletCollision -L../../bullet/src/BulletDynamics -L/opt/homebrew/lib
