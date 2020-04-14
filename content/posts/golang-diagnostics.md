---
title: "Golang Diagnostics"
date: 2020-04-14T21:17:03+08:00
---

> 原文：https://golang.org/doc/diagnostics.html


---

## 介绍

go 语言提供了大量的 api 和工具套件帮助定位 go 程序中的逻辑和性能问题。本文总结了一些工具，帮助 gopher 找到适用于他们特定问题的
正确工具。

诊断方案可以分为以下几类：

* **Profiling** :帮助分析 go 程序的复杂度和消耗，例如内存消耗和频繁调用的函数，以定位程序的性能瓶颈
* **Tracing** :通过跟踪代码来分析整个代码生命周期内的延时，每个部分的延时和总延时的关系。Traces 可以跨越多个 go 进程。
* **Debugging** :可以暂停 go 程序，检查执行状态。程序的运行时状态和流程可以通过 debug 来验证。
* **Runtime statistics and events** :收集运行是状态和事件，提供 go 程序健康状态的概览。指标的尖刺/下降帮助我们确认吞吐量、
利用率和性能上变化。


注意：不同的诊断工具可能会互相影响。例如，精确的内存 profile 会影响 CPU profile；goroutine blocking profile 会影响调度
器 trace。我们应该独立使用诊断工具，以获得更精确的结果。

## Profiling

性能剖析对定位代码中消耗最大或频繁调用的部分非常有效。go 的运行时会提供特定格式的 profiling 数据供[pprof 可视化工具](https://github.com/google/pprof/blob/master/doc/README.md)使用。profiling 数据可以通过测试或者使用[net/http/pprof](https://golang.org/pkg/net/http/pprof/)来收集。用户需要收集 profiling 数据，通过 pprof 工具过滤、可视化关键的代码路径。

[runtime/pprof](https://golang.org/pkg/runtime/pprof)提供以下预设的性能剖析：

* cpu
CPU profile 用于确认程序是如何消耗 CPU 的始终周期的，即 CPU 消耗花费在哪些地方了。
* heap
heap profile 会采样报告内存分配信息，可以用来监控当前和历史的内存使用，也可以用来检测内存泄漏
* threadcreate
threadcreate profile 会报告程序的哪些部分导致创建了新的系统线程
* goroutine
goroutine profile 报告当前所有的 goroutine 的堆栈跟踪信息
* block
block profile 展示 goroutine 阻塞在哪里等待同步。block profile 默认是不开启的，通过设置 runtime.SetBlockProfileRate 来开启。
* mutex
mutex profile 报告锁争用的情况。如果你认为你的 CPU 由于锁争用而没有被充分利用，使用 mutex profile。mutex profile 默认没有开启，通过设置 runtime.SetMutexProfileFraction 来开启。

### 还有其他工具可以用于调优 go 程序么

linux 平台还可以使用[perf tools](https://perf.wiki.kernel.org/index.php/Tutorial)分析 go 程序。

### 可以分析生产环境的服务么

可以。在生产环境 profile 服务是安全的，但是可能会对增加一些性能消耗，服务可预见的出现性能下降。可以在生产环境开启前先评估一下 profiler 的性能开销。

### 可视化 profiling 数据的最好方式是什么

go tool pprof 提供了 text、graph 和[callgrind](http://valgrind.org/docs/manual/cl-manual.html)、[flame graph](http://www.brendangregg.com/flamegraphs.html)等方式。

## Tracing

* 检测和分析 go 程序的延迟。
* 评估一长串调用中某个特定调用的消耗。
* 找出利用率和性能优化。有些性能瓶颈，不依靠 trace 数据很难找到。

在单一系统上收集诊断信息是相对容易的。所有的代码模块都运行在一个进程中，共享资源，报告日志、error 和其他诊断信息。一旦你的系统演变到超出单进程，开始变成一个分布式系统，沿着请求链路从前端的 web server 到所有后端变得困难。分布式 tracing 系统在这样的场景下，在检测和分析线上系统中扮演了重要的角色。

分布式 tracing，通过 context 实现？
... 扯淡？


## Debugging

广泛使用的两个 debugger：

* [dlv](https://github.com/derekparker/delve) 推荐
* [GDB](https://golang.org/doc/gdb)

### debugger 怎么用

因为 gc 编译器会做一些性能优化，例如函数内联和变量注册。这些优化有时候会让 debug 变得更难。所以当 debug 时，推荐禁用优化。

```shell
go build -gcflags=all="-N -l"
```

go 1.10 后新增一个编译器 flag `-dwarflocationlists`。 [dwarf 参考](http://dwarfstd.org/)

```shell
go build -gcflags="-dwarflocationlists=true"
```

### postmortem debugging

[postmortem debugging 参考](https://www.drdobbs.com/architecture-and-design/post-mortem-debugging-revisited/227900186)

core dump 文件包含了一个运行中进程的内存 dump 和进程状态。

[coreDumpDebugging](https://github.com/golang/go/wiki/CoreDumpDebugging)


## Runtime statistics and events

常用的 runtime 数据

* [runtime.ReadMemStats](https://golang.org/pkg/runtime/#ReadMemStats)

堆分配和 gc，可以用来监控内存使用情况，内存泄漏等

* [debug.ReadGCStats](https://golang.org/pkg/runtime/debug/#ReadGCStats)

gc，多少资源花费在 GC pause，gc pause 的时间线，暂停时间百分比

* [debug.Stack](https://golang.org/pkg/runtime/debug/#Stack)

堆栈信息，goroutine 运行状态

* [debug.WriteHeapDump](https://golang.org/pkg/runtime/debug/#WriteHeapDump)

挂起全部 goroutine，dump heap 到一个文件，内存快照

* [runtime.NumGoroutine](https://golang.org/pkg/runtime#NumGoroutine)

goroutine 数量，goroutine 泄漏

### Execution tracer

识别并发度低的并发运行 `go tool trace`

### GODEBUG

[GODEBUG env](https://golang.org/pkg/runtime/#hdr-Environment_Variables)

* GODEBUG=gctrace=1 输出 gc 事件的信息
* GODEBUG=schedtrace=X 每 X milliseconds 输出一次调度事件 

下面这俩基本用不上

* GODEBUG=cpu.all=all 禁用可选指令集扩展
* GODEBUG=cpu.*extension*=off 禁用指令集扩展
