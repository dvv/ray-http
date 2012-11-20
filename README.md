ray-http
========

An HTTP layer for Richard Hundt's [ray](https://github.com/richardhundt/luv/tree/ray).

```shell
sudo pacman -S luajit luarocks
luarocks make ray-http-scm-1.rockspec
luajit server.lua
```

In another console:
```shell
curl -v http://127.0.0.1/foo
```

