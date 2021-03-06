#!/usr/bin/env lua

package = "ray-http"
version = "scm-1"
source = {
    url = "git://github.com/dvv/ray-http.git"
}
description = {
    summary  = "HTTP layer for Ray.",
    detailed = "",
    homepage = "http://github.com/dvv/ray-http",
    license  = "MIT",
}
dependencies = {
    "lua >= 5.1"
}
build = {
    type = "builtin",
    modules = {
      ["ray.http"] = "http.lua",
      ["ray.utils"] = "utils.lua",
      ["ray.http.parser"] = {"parser/http_parser.c", "parser/lua-http-parser.c"},
    },
}
