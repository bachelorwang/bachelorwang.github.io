---
layout: post
title: perf counter
tags:
  - c
  - linux
  - nginx
---

./auto/configure --with-debug --with-threads --with-cc-opt='-O0 -g'

conf

daemon off;
master_process off;

http {
    aio threads;
}