---
lang: Python
date: 2026-04-12
tags:
  - 工具
---
# Pixi 的 Linux 安装

## 一、Linux 安装 Pixi（推荐）

### 一键安装脚本（官方）

```bash
curl -fsSL https://pixi.sh/install.sh | bash
```

以下是可选项：

**指定 Pixi 安装路径**（默认安装路径~/.pixi）：
需要在执行安装脚本之前

```bash
# 指定安装路径
export PIXI_HOME=/data/xds/Worktools/pixi
# 指定家目录的
export PATH_HOME="
```

将 pixi 安装路径加到 PATH（若安装脚本未自动添加）：

```bash
export PIXI_HOME="" />HOME/Worktools/pixi"
export PATH="PATH"
```

### 验证

- `pixi --version` 查看版本
- `which pixi` 查看安装位置

---

# Pixi 的环境构建

## 2.1 全局的镜像环境构建

使用 prepend 加载前面，append 加载后面，--global 参数代表全局的镜像

```bash
# 1. 设置默认通道（清华镜像 + NVIDIA）
pixi config set default-channels '[
  "https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge",
  "https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/bioconda",
  "https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/pytorch",
  "nvidia"
]'

# 2. 设置 PyPI 清华镜像
pixi config set pypi-config.index-url "https://pypi.tuna.tsinghua.edu.cn/simple"

# 3. 验证配置
pixi config list
```

使用 list 查看目前的 config 设置

```bash
pixi config list --global
```

目前对于 pixi 来说,只有一个模式,就是识别 conda-forge,bioconda 等关键字,不会识别是否是镜像源 ,所以不能在环境中存在两个相同的通道会报错.
同时,之前在 conda 中的镜像环境太冗杂,经过精简后,以下环境应该可以满足大部分需求.

```toml
default-channels = [
    "https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge",
    "https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/bioconda",
    "https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/pytorch",
    "nvidia"
]

[pypi-config]
index-url = "https://pypi.tuna.tsinghua.edu.cn/simple"
```

---

## 2.2 全局的环境构建

### 1. 查看 pixi 中全局的环境：

```bash
pixi global list
# 或者简写
pixi g list
```

### 2.创建全局环境中不同的 python 环境类似于 conda：

使用 install 命令来创建新的环境，注意参数：--environment 和--expose 选择不暴露，这样就不会冲突

```bash
# 创建 Python 3.10 环境（不指定 --expose 来测试默认行为）
pixi global install --environment scanpy \
  --expose "py310_scanpy=python" \
  python=3.10 pip numpy pandas scanpy

# 创建 Python 3.11 环境
pixi global install --environment scgpt \
  --expose "py311_scgpt=python" \
  python=3.11 jupyter
```

#### 自定义命令名称示例

**--expose 语法说明**

> --expose \<EXPOSE>
> Add one or more mapping which describe which executables are exposed. 
> The syntax is `exposed_name=executable_name`, so for example `python3.10=python`. 
> Alternatively, you can input only an executable_name and `executable_name=executable_name` is assumed

**方法一：自定义别名**

```bash
# 将 python 暴露为 py311，将 pip 暴露为 pip311
pixi global install --environment python311 \
  --expose "py311=python" \
  --expose "pip311=pip" \
  --expose "jupyter311=jupyter" \
  python=3.11 pip jupyter
```

**方法二：功能性命名**

```bash
# 给命令起有意义的名字
pixi global install --environment python311 \
  --expose "python-data=python" \
  --expose "pip-data=pip" \
  --expose "notebook=jupyter" \
  python=3.11 pip jupyter matplotlib pandas
```

**方法三：版本化命名**

```bash
# 使用版本号避免冲突
pixi global install --environment python311 \
  --expose "python3.11=python" \
  --expose "pip3.11=pip" \
  --expose "jupyter3.11=jupyter" \
  python=3.11 pip jupyter
```

### 3.如果修改了 pixi-global.toml

```bash
# 按照警告提示，先同步环境
pixi global sync
```

同步环境的注意事项：

```toml
version = 1

[envs.r]
channels = ["https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge", "https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/bioconda", "https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/pytorch", "https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main", "https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free", "https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r", "nvidia"]
dependencies = { r-base = "*", r-essentials = "*", r-pak = "*", pkg-config = "*", freetype = "*", fontconfig = "*", harfbuzz = "*", fribidi = "*", libpng = "*", libjpeg-turbo = "*", libtiff = "*", glpk = "*", libgit2 = "*", pandoc = "*", imagemagick = "*", perl = "*", libarrow = "*", arrow-cpp = "*", r-arrow = "*", r-sf = "*", r-spdep = "*", gdal = "*", proj = "*", geos = "*", udunits2 = "*" }
exposed = { R = "R", Rscript = "Rscript" }

[envs.scanpy]
channels = ["https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge", "https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/bioconda", "https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/pytorch", "https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main", "https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free", "https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r", "nvidia"]
dependencies = { python = "3.10.*", pip = "*", numpy = "*", pandas = "*", scanpy = "*" }
exposed = { py310_scanpy = "python", pip310_scanpy = "pip" }
```

### 4.使用环境

这里的使用环境和 mamba 不同，全局环境是直接存在的，不需要进入 shell
想要使用只能使用 expose 暴露的虚拟环境中的接口调用对应环境中的可执行文件。

**pixi g add**

可以使用 `pixi g add` 添加包到具体的环境中,但是值得注意的是,这里 `pixi g add` 没有具体到项目中的 `pixi add` 好用,例如没有 `--pypi` 参数等。

```bash
# 添加 scanpy 包
pixi g add --environment scanpy scanpy
```

但其实，就这些就已经相当于是 mamba 的同类型替代，更何况既快速又拥有其它功能。

---

## 2.3 项目级别的环境构建

### 1. pixi init 初始化或者直接复制配置好的 pixi.toml 和 pixi.lock 到环境中

`pixi init` 初始化环境，在空白的项目中添加 pixi.toml 配置文件。

直接复制配置好的 pixi.toml 和 pixi.lock 到环境中
然后直接使用 `pixi install` 命令就可以复刻环境

### 2. pixi add 在项目中添加包

> **✏️ 注意**
> 
> 注意这里的命令必须在项目的根目录及子目录下使用，才是在项目中添加包，与 `pixi global install` 是在全局环境中添加工具包做区分。

直接使用 `pixi add [packagename]` 是通过与 conda/mamba 相同的方式检索现有的频道中的编译好的包直接安装，但是更快！
如果使用 `pixi add --pypi [packagename]` 是通过 pixi 现在内置的 uv 来进行 pip 途径可以安装的包的管理。这两种方式都会写入 pixi.toml。

### 3.通过 task 的方式在 pixi.toml 中借用 pip 来安装包

> **✏️ 注意**
> 
> 由于现在可能 pixi 的 pypi 方式不够完善，之前我配置 scgpt 环境的时候，有的包通过 pypi 途径无法下载，或者自动解析会下载 cpu 版本，例如 pytorch。而 python 中的 pip 命令，目前可以使用更加详尽的参数来控制，例如指定某个镜像包。所以需要使用在 pixi.toml 中写入 task 的方式来安装包。

```toml
[tasks]
# 一键安装命令
# 这里depends-on的意思就是运行此命令会先自动运行这些依赖的命令
setup-all = { depends-on = ["install-torch", "install-flash-attn", "check-env"] }

# 🚀 [迁移核心]：在此处统一修改系统 CUDA 路径
# 理由：编译需要系统 NVCC，运行 JAX 需要系统驱动库。pixi环境中的 CUDA 像是零件包，无法满足需求。
_system_cuda = "export CUDA_HOME=/usr/local/cuda-12.4 && export LD_LIBRARY_PATH=LD_LIBRARY_PATH"

# 1. 安装支持 CUDA 12.1 的 PyTorch
install-torch = "pip install torch==2.3.0 torchvision==0.18.0 torchaudio==2.3.0 --index-url https://mirror.nju.edu.cn/pytorch/whl/cu121"

# 2. 现场编译 Flash Attention (会自动引用 _setup_cuda 中的路径)
# 💡 迁移提示：修改 _setup_cuda 任务中的路径即可全局生效
install-flash-attn = { cmd = "pip install flash-attn==1.0.4 --no-build-isolation --no-cache-dir", depends-on = ["_system_cuda"] }

# 3. 环境全项验证
check-env = { cmd = "python -c 'import jax; import torch; print(f\"PyTorch GPU: {torch.cuda.is_available()}\"); print(f\"JAX Devices: {jax.devices()}\")'", depends-on = ["_system_cuda"] }

# 4. 使用python脚本全项验证
test-scgpt = { cmd = "python test_scgpt.py", depends-on = ["_system_cuda"] }
```

调用的 task 的命令：

`pixi run [taskname]` 例如调用上方的 task 就是 `pixi run setup-all`

这里的 `pixi run` 可以运行 pixi 中环境中系统命令。如：如果要运行 pixi 环境中的 python 就使用 `pixi run python`，可以通过查看 python 版本号等方式来验证是否正确，`pixi run python --version`

同时这里的 `pixi run` 命令必须在项目的根目录或者子目录下运行。

```bash
➜  scGPT-demo pixi run python --version 
Python 3.10.19
➜  scGPT-demo 
```

---

## 2.4 scgpt 项目配置文件示例

### 1. pixi.toml

> **✏️ 注意**
> 
> 虽然 pixi 的可迁移性非常高，而且速度非常快，但是在该项目中，由于 scgpt 只兼容 flash-attn<1.0.4 版本过于老旧，所以基本上只能靠编译。
> 
> 而编译则与系统的 cuda，cudnn，python 的版本，pytorch 等的版本息息相关。在配置过程中还发现有 jaxlib 的版本也相关。注意这里是系统的，而不是 pixi 环境中的，pixi 环境中的不具备编译功能，所以在任务中需要输入系统的 cuda 的环境变量和版本号，还需要配齐对应的 pytorch 等。

所以这里需要注意你的 linux 系统中的 cuda 和 cudnn 的版本，然后才能成功编译 flash-attn。

> **⚠️ 警告**
> 
> 这里是使用 scgpt 的环境，不是开发本地 scgpt 的环境，所以安装 scgpt 的包。

```toml
[workspace]
name = "scGPT"
version = "0.1.0"
authors = ["whynerve"]
channels = [
    "https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge",
    "https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/bioconda",
    "https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/pytorch",
    "nvidia"
]
platforms = ["linux-64"]

[pypi-options]
index-url = "https://pypi.tuna.tsinghua.edu.cn/simple"

[dependencies]
python = "3.11.*"
pip = ">=25.2,<26"
gcc_linux-64 = "12.*"
gxx_linux-64 = "12.*"
ninja = "*"
pyarrow = "<15.0"
jupyter = ">=1.1.1,<2"
ipykernel = ">=6.0,<7"

[pypi-dependencies]
torchvision = "==0.18.0"
torchaudio = "==2.3.0"
packaging = ">=25.0, <26"
ipykernel = ">=6.30.1, <7"
jax = "==0.4.13"
jaxlib = { url = "https://storage.googleapis.com/jax-releases/cuda12/jaxlib-0.4.13%2Bcuda12.cudnn89-cp311-cp311-manylinux2014_x86_64.whl" }
scgpt = ">=0.2.4, <0.3"
scvi-tools = "==0.20.3"
anndata = "==0.9.2"
scanpy = ">=1.10.0"
scipy = "<1.13.0"
wandb = ">=0.22.2, <0.23"
gseapy = ">=1.1.10, <2"
faiss-cpu = ">=1.12.0, <2"
gpustat = ">=1.1.1, <2"

[tasks]
# 一键安装命令
setup-all = { depends-on = ["install-torch", "install-flash-attn", "check-env"] }

# 🚀 [迁移核心]：在此处统一修改系统 CUDA 路径
# 理由：编译需要系统 NVCC，运行 JAX 需要系统驱动库。pixi环境中的 CUDA 像是零件包，无法满足需求。
_system_cuda = "export CUDA_HOME=/usr/local/cuda-12.4 && export LD_LIBRARY_PATH=LD_LIBRARY_PATH"

# 1. 安装支持 CUDA 12.1 的 PyTorch
install-torch = "pip install torch==2.3.0 torchvision==0.18.0 torchaudio==2.3.0 --index-url https://mirror.nju.edu.cn/pytorch/whl/cu121"

# 2. 现场编译 Flash Attention (会自动引用 _setup_cuda 中的路径)
# 💡 迁移提示：修改 _setup_cuda 任务中的路径即可全局生效
install-flash-attn = { cmd = "pip install flash-attn==1.0.4 --no-build-isolation --no-cache-dir", depends-on = ["_system_cuda"] }

# 3. 环境全项验证
check-env = { cmd = "python -c 'import jax; import torch; print(f\"PyTorch GPU: {torch.cuda.is_available()}\"); print(f\"JAX Devices: {jax.devices()}\")'", depends-on = ["_system_cuda"] }

# 4. 使用python脚本全项验证
test-scgpt = { cmd = "python test_scgpt.py", depends-on = ["_system_cuda"] }
```

### 2. test_scgpt.py

> **✏️ 注意**
> 
> 这里是使用 ai 顺手写的测试脚本，注意，这是使用 scgpt 的环境的脚本，不是开发 scgpt，如果要开发 scgpt，则不需要安装 scgpt 库，而是在上面的 pixi.toml 中将 scgpt 本地的包安装入环境中。

```python
import os
import sys
import warnings
import torch
import numpy as np

# ==========================================
# 1. 警告与日志过滤 (保持终端整洁)
# ==========================================
os.environ["TF_CPP_MIN_LOG_LEVEL"] = "3" 
try:
    import torchtext
    torchtext.disable_torchtext_deprecation_warning()
except (ImportError, AttributeError):
    pass

warnings.filterwarnings("ignore", message=".*The 'frozen' attribute with value True.*")
warnings.filterwarnings("ignore", message=".*enable_nested_tensor is True, but self.use_nested_tensor is False.*")
warnings.filterwarnings("ignore", category=UserWarning, module="lightning_fabric")

# 针对 RTX 4090 的优化设置
if torch.cuda.is_available():
    torch.set_float32_matmul_precision('high')

def test_environment():
    print(f"{'='*20} 1. 环境基础检查 {'='*20}")
    print(f"Python 路径: {sys.executable}")
    print(f"PyTorch 版本: {torch.__version__}")
    print(f"CUDA 是否可用: {torch.cuda.is_available()}")
    if torch.cuda.is_available():
        print(f"当前 GPU: {torch.cuda.get_device_name(0)}")

    # ==========================================
    # 2. JAX GPU 加速检测
    # ==========================================
    print(f"\n{'='*20} 2. JAX 后端检测 {'='*20}")
    try:
        import jax
        devices = jax.devices()
        print(f"✅ JAX 加载成功! 版本: {jax.__version__}")
        print(f"✅ JAX 识别设备: {devices}")
        if "gpu" not in str(devices[0]).lower():
            print("⚠️ 警告: JAX 未识别到 GPU，请检查 jaxlib 版本。")
    except Exception as e:
        print(f"❌ JAX 检测失败: {e}")

    # ==========================================
    # 3. 单细胞核心算法库加载
    # ==========================================
    print(f"\n{'='*20} 3. 核心算法库加载 {'='*20}")
    try:
        import scvi
        import scanpy as sc
        import scgpt
        print(f"✅ scvi-tools 版本: {scvi.__version__}")
        print(f"✅ scanpy 版本: {sc.__version__}")
        print(f"✅ scGPT 模块路径: {scgpt.__path__[0]}")
    except Exception as e:
        print(f"❌ 库加载失败: {e}")

    # ==========================================
    # 4. Flash Attention 与 scGPT 模型验证
    # ==========================================
    print(f"\n{'='*20} 4. Flash Attention 算子验证 {'='*20}")
    try:
        import flash_attn
        print(f"✅ Flash Attention 库已安装 (版本: {getattr(flash_attn, '__version__', '1.0.4')})")

        from scgpt.model import TransformerModel

        # 构造模拟词表 (ntoken=100)
        fake_vocab = {"<pad>": 0, "<mask>": 1, "<cls>": 2}
        for i in range(3, 100):
            fake_vocab[f"gene_{i}"] = i

        # 初始化模型
        model = TransformerModel(
            ntoken=100, 
            d_model=128, 
            nhead=4, 
            d_hid=128, 
            nlayers=2,
            vocab=fake_vocab,
            pad_token="<pad>",
            use_fast_transformer=True, 
            fast_transformer_backend="flash"
        ).cuda()

        # RTX 4090 性能优化：使用半精度进行前向传播测试
        model.half()

        # 准备模拟数据 (Batch=2, Seq_len=10)
        src = torch.randint(1, 100, (2, 10)).cuda()
        values = torch.randn(2, 10).cuda().half()
        # 关键修复：构造 src_key_padding_mask
        # 0 代表该位置是真实的基因，1 代表是填充位
        src_key_padding_mask = torch.zeros(2, 10, dtype=torch.bool).cuda()

        with torch.no_grad():
            # 执行前向传播
            output = model(
                src, 
                values, 
                src_key_padding_mask=src_key_padding_mask
            )

        print("✅ scGPT 模型初始化成功并已载入 GPU")
        print(f"✅ 前向传播测试成功！")
        print(f"✅ 细胞嵌入 (Cell Embedding) 形状: {output['cell_emb'].shape}")
        print("\n🚀 结论：您的 scGPT 环境已达满血状态，Flash Attention 运行正常！")

    except Exception as e:
        print(f"❌ 模型验证环节出错: {e}")
        print("💡 建议：检查 scgpt 源码版本是否与参数匹配。")

    print(f"\n{'='*50}")
    print("🌟 所有测试已完成！")
    print(f"{'='*50}")

if __name__ == "__main__":
    test_environment()
```
