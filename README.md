# moonbitJobShop

MoonBit 制造车间调度优化器：面向多工序、多设备、换型时间和交付期约束，提供可复用的领域模型、确定性启发式调度和结果报告。

## 快速开始

需要 MoonBit 0.10.3 或更新版本。

```bash
moon check --deny-warn
moon test --deny-warn
moon run cmd/demo
```

示例输出包括每道工序的设备、开始时间和结束时间。库的核心入口位于 `src` 包：

```moonbit
let result = @jobshop.dispatch(input)
let report = @jobshop.summarize(schedule, jobs, machines)
```

## 能力边界

- 领域模型：工件、工序、设备、固定/可选设备路线、换型时间、交期。
- 调度：按最早可行时间派工，保证工序前后约束和设备区间不重叠。
- 指标：最大完工时间、总延期、设备负载、负载均衡、设备利用率。
- 输出：结构化甘特图事件，可直接交给终端、Web 或可视化前端。
- 扩展点：局部搜索、遗传算法、禁忌搜索、动态插单、故障重调度和 Pareto 多目标优化。

本项目专注制造排程基础设施，不提供机构计算、几何建模或通用数值求解器，与 MoonMech 的边界清晰。

## 生态查重与来源说明

项目立项前在 MoonCakes 以 `job shop`、`scheduling`、`manufacturing`、`optimization` 等关键词检索，未发现提供同等制造车间调度模型与启发式接口的成熟 MoonBit 包。MoonCakes 是生态包与可执行条目的发布平台；本仓库暂不复制第三方实现，所有核心源码为本项目原创，算法采用公开的作业车间调度领域常见建模方式。

## 开发与质量门禁

CI 使用 MoonBit 官方安装脚本，并执行格式、警告、接口信息、普通测试、native 测试和 demo CLI 检查。提交历史按功能和文档阶段递进，便于评审追踪公开开发过程。

```bash
moon fmt --deny-warn
moon info --deny-warn
moon check --deny-warn
moon test --deny-warn
moon test --target native --deny-warn
moon run cmd/demo
```

## 路线图

0.1 提供稳定模型、确定性派工、目标函数和报告；0.2 增加局部搜索与遗传算法；0.3 增加动态事件与故障重调度；后续评估多目标 Pareto 接口及 MoonCakes 发布。

## 许可

MIT License，见 [LICENSE](LICENSE)。
