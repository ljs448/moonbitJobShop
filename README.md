# moonbitJobShop

面向制造排程的 MoonBit 调度库：用确定性启发式算法处理多工序、可选设备、换型时间、交付期、设备日历和动态事件，并提供可复现的搜索、分析与报告接口。

## 项目定位

`moonbitJobShop` 将作业车间调度问题拆成可组合的领域模型、约束校验、派工策略、局部优化和运营分析模块。核心库保持纯 MoonBit，适合嵌入终端工具、服务端调度器和可视化应用；输入、输出和基准均使用确定性数据，便于复现实验与回归测试。

## 核心能力

- 领域模型：设备、工件、工序、可选设备路线、换型时间和交付期。
- 可行调度：工序先后、设备不重叠、设备停机日历、冻结时间和完整性检查。
- 派工策略：FIFO、最短加工时间、最早交期、最小松弛度、换型感知和 Lookahead。
- 优化搜索：局部搜索、禁忌搜索、遗传搜索、模拟退火、破坏-重建和可组合搜索组合。
- 动态场景：插单、取消、设备故障、滚动窗口重调度、版本差异与事件回放。
- 分析输出：完工时间、延期、利用率、瓶颈、关键路径、Pareto 前沿、容量投影、KPI、CSV/文本报告。
- 工程质量：确定性基准、边界测试、约束契约、跨目标检查和 GitHub Actions CI。

## 快速开始

需要 MoonBit stable 工具链（编译器 0.10.7 或更新版本）。

```bash
moon update
moon check --deny-warn
moon test --deny-warn
moon run cmd/demo
```

作为库使用时导入：

```moonbit
import {
  "ljs448/moonbitJobShop/src" @jobshop,
}

let result = @jobshop.dispatch(input)
```

`dispatch` 返回 `Result[Schedule, String]`；调度结果可继续交给 `evaluate`、`validate_schedule`、`dashboard_metrics` 或文本/CSV 渲染器。

## CLI

仓库提供两个无需参数的可执行示例：

```bash
# 最小可运行示例，打印排程和甘特事件
moon run cmd/demo

# 运行 small / medium / large 固定数据集，并打印可复现指标
moon run cmd/benchmark
```

基准 CLI 输出包括 jobs、machines、operations、repeats、makespan、tardiness、score 和 checksum 长度；完整签名可通过 `run_benchmark` 与 `BenchmarkSummary::line` 获取。

## 架构

```text
src/
├── model / schedule / validation_extra       领域模型、调度结果与硬约束
├── dispatch_options / dispatch_lookahead     派工规则与前瞻排序
├── calendar / dynamic_capacity                停机日历与容量投影
├── search_* / neighborhood / random           确定性邻域和优化搜索
├── dynamic_events / rolling_window            动态事件与滚动重调度
├── objective* / pareto* / metrics*            目标函数、多目标和运营指标
├── analysis / setup_optimizer                 瓶颈、关键路径和换型分析
├── benchmark* / sensitivity                   基准数据集与 what-if 分析
└── format_* / text_render / trace_export      机器可读和人类可读输出
```

公共 API 集中在 `src` 包；`cmd/demo` 和 `cmd/benchmark` 只负责演示和可复现实验，不把业务逻辑复制到命令行层。

## 基准

以下结果由 `moon run cmd/benchmark` 在固定生成器和确定性派工下得到；`score` 是库内置平衡目标函数的整数分数，越低越好。墙钟时间受操作系统和 CPU 影响，验收时应使用同一工具链重新运行。

| 场景 | jobs | machines | operations | repeats | makespan | tardiness | score |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| tiny-2x2 | 2 | 2 | 4 | 5 | 11 | 0 | 51 |
| small-6x3 | 6 | 3 | 24 | 3 | 70 | 74 | 681 |
| medium-12x4 | 12 | 4 | 60 | 2 | 136 | 446 | 2852 |
| large-20x5 | 20 | 5 | 120 | 1 | 219 | 1496 | 8483 |

复现实验：

```bash
moon run cmd/benchmark
```

详细的环境、校验长度和墙钟复测记录见 [`docs/benchmark.md`](docs/benchmark.md)。

## 测试与质量

测试覆盖模型校验、空输入、负时长、重复 ID、停机边界、设备路线、换型、调度完整性、动态事件、搜索确定性、Pareto 去重、容量、报告和基准稳定性。

```bash
moon fmt --check
moon check --deny-warn
moon test --deny-warn
moon test --target native --deny-warn
moon test --target all --deny-warn
moon info
```

## CI

`.github/workflows/check.yml` 在 Ubuntu、macOS 和 Windows 上安装 stable MoonBit，执行格式检查、`moon check --target all`、普通/native 测试、覆盖率摘要、接口信息检查以及 demo/benchmark CLI。提交和 Pull Request 都会触发；本地命令与 CI 保持一致。

## 许可证

本项目采用 MIT License，见 [LICENSE](LICENSE)。
