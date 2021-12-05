incdir=/usr/local/share/pxclib/:/usr/share/pxclib/:.
safe_mode=0
cxx=g++ --std=c++11
cflags=-g -O3 -DNDEBUG -Wall -Wno-empty-body -Wno-tautological-compare -Wno-overloaded-virtual -Wno-unused -Wno-unused-result -Wno-strict-aliasing -Wno-free-nonheap-object -Wno-argument-outside-range -I/usr/local/include -I../.. -I/usr/include/SDL2 -I../../bullet/src
ldflags=-L../../bullet/src/LinearMath -L../../bullet/src/BulletCollision -L../../bullet/src/BulletDynamics
