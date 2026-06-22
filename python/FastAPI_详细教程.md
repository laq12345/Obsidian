# FastAPI 详细使用教程

> 基于 [FastAPI 官方文档](https://fastapi.tiangolo.com/) 整理 | 2026年6月

---

## 目录

1. [FastAPI 简介](#1-fastapi-简介)
2. [环境准备与安装](#2-环境准备与安装)
3. [第一个 FastAPI 应用](#3-第一个-fastapi-应用)
4. [路径参数 (Path Parameters)](#4-路径参数-path-parameters)
5. [查询参数 (Query Parameters)](#5-查询参数-query-parameters)
6. [请求体 (Request Body) 与 Pydantic 模型](#6-请求体-request-body-与-pydantic-模型)
7. [参数验证与约束](#7-参数验证与约束)
8. [响应模型与状态码](#8-响应模型与状态码)
9. [错误处理](#9-错误处理)
10. [依赖注入 (Dependency Injection)](#10-依赖注入-dependency-injection)
11. [安全与认证](#11-安全与认证)
12. [中间件 (Middleware)](#12-中间件-middleware)
13. [CORS 跨域配置](#13-cors-跨域配置)
14. [后台任务](#14-后台任务)
15. [数据库集成](#15-数据库集成)
16. [大型应用：多文件组织](#16-大型应用多文件组织)
17. [WebSocket 支持](#17-websocket-支持)
18. [测试](#18-测试)
19. [部署](#19-部署)
20. [进阶主题概览](#20-进阶主题概览)

---

## 1. FastAPI 简介

**FastAPI** 是一个现代、高性能的 Python Web 框架，基于标准 Python 类型提示构建 API。

### 核心特性

| 特性 | 说明 |
|------|------|
| **快** | 性能与 NodeJS、Go 相当，基于 Starlette 和 Pydantic |
| **快速开发** | 开发速度提升约 200%-300% |
| **减少 Bug** | 减少约 40% 的人为错误 |
| **直观** | 出色的编辑器支持，自动补全、类型检查 |
| **简洁** | 最小化代码重复 |
| **健壮** | 自动生成交互式文档 |
| **标准化** | 完全兼容 OpenAPI 和 JSON Schema |

### 底层依赖

- **Starlette**：负责 Web 部分（路由、请求/响应、中间件、WebSocket 等）
- **Pydantic**：负责数据部分（类型验证、序列化/反序列化、JSON Schema 生成）

### 业界认可

被 **Microsoft**、**Uber**、**Netflix**、**Cisco** 等公司广泛使用。

---

## 2. 环境准备与安装

### 安装 FastAPI（推荐完整安装）

```bash
pip install "fastapi[standard]"
```

> 注意：引号是必需的，以确保在各类终端中正确解析。

`[standard]` 包含以下可选依赖：
- `uvicorn`：ASGI 服务器
- `httpx`：用于 TestClient
- `jinja2`：模板引擎
- `python-multipart`：表单解析
- `email-validator`：邮件验证
- `fastapi-cli[standard]`：提供 `fastapi` 命令行工具

### 最小安装

```bash
pip install fastapi
```

### 安装 Uvicorn（如果使用最小安装）

```bash
pip install uvicorn
```

---

## 3. 第一个 FastAPI 应用

### 创建 `main.py`

```python
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
async def root():
    return {"message": "Hello World"}
```

### 运行开发服务器

```bash
fastapi dev
```

输出示例：
```
╭────────── FastAPI CLI - Development mode ───────────╮
│  Serving at: http://127.0.0.1:8000                  │
│  API docs: http://127.0.0.1:8000/docs               │
╰─────────────────────────────────────────────────────╯
```

### 代码解析（5 步法）

**第 1 步：导入 `FastAPI`**

```python
from fastapi import FastAPI
```

**第 2 步：创建应用实例**

```python
app = FastAPI()
```

这个 `app` 变量就是整个 API 应用的入口。

**第 3 步：定义路径操作装饰器**

```python
@app.get("/")
```

- **路径 (Path)**：URL 中第一个 `/` 之后的部分（也叫 "endpoint" 或 "route"）
- **操作 (Operation)**：HTTP 方法：`GET`、`POST`、`PUT`、`DELETE`、`PATCH` 等
- 常规约定：`POST` 创建、`GET` 读取、`PUT` 更新、`DELETE` 删除

**第 4 步：定义路径操作函数**

```python
async def root():
```

可用 `async def` 或普通 `def`，FastAPI 会自动处理。

**第 5 步：返回内容**

```python
return {"message": "Hello World"}
```

可返回 `dict`、`list`、Pydantic 模型、ORM 对象等，自动转为 JSON。

### 自动交互式文档

- **Swagger UI**：[http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)
- **ReDoc**：[http://127.0.0.1:8000/redoc](http://127.0.0.1:8000/redoc)
- **OpenAPI Schema**：[http://127.0.0.1:8000/openapi.json](http://127.0.0.1:8000/openapi.json)

### 完整示例（含 PUT 和 Pydantic 模型）

```python
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()

class Item(BaseModel):
    name: str
    price: float
    is_offer: bool | None = None

@app.get("/")
def read_root():
    return {"Hello": "World"}

@app.get("/items/{item_id}")
def read_item(item_id: int, q: str | None = None):
    return {"item_id": item_id, "q": q}

@app.put("/items/{item_id}")
def update_item(item_id: int, item: Item):
    return {"item_name": item.name, "item_id": item_id}
```

---

## 4. 路径参数 (Path Parameters)

### 基本用法

使用与 Python f-string 相同的语法声明路径参数：

```python
@app.get("/items/{item_id}")
async def read_item(item_id: int):
    return {"item_id": item_id}
```

访问 `http://127.0.0.1:8000/items/3` → 返回 `{"item_id": 3}`（注意：是 Python `int`，不是字符串 `"3"`）

### 类型声明效果

仅通过 `item_id: int` 就获得了：
- **编辑器支持**：自动补全、错误检查
- **数据解析**：自动将字符串转为指定类型
- **数据验证**：传入非整数时返回清晰的错误
- **自动文档**：交互式文档自动显示参数类型

### 路由顺序很重要

固定路径必须定义在参数化路径之前：

```python
@app.get("/users/me")          # 固定路径在前
async def read_user_me():
    return {"user_id": "the current user"}

@app.get("/users/{user_id}")   # 参数化路径在后
async def read_user(user_id: str):
    return {"user_id": user_id}
```

### 使用 Enum 限定可选值

```python
from enum import Enum

class ModelName(str, Enum):
    alexnet = "alexnet"
    resnet = "resnet"
    lenet = "lenet"

@app.get("/models/{model_name}")
async def get_model(model_name: ModelName):
    if model_name is ModelName.alexnet:
        return {"model_name": model_name, "message": "Deep Learning FTW!"}
    if model_name.value == "lenet":
        return {"model_name": model_name, "message": "LeCNN all the images"}
    return {"model_name": model_name, "message": "Have some residuals"}
```

### 包含路径的路径参数

```python
@app.get("/files/{file_path:path}")
async def read_file(file_path: str):
    return {"file_path": file_path}
```

`/files/home/johndoe/myfile.txt` → `file_path` = `"home/johndoe/myfile.txt"`

---

## 5. 查询参数 (Query Parameters)

不在路径中声明的函数参数，自动被视为**查询参数**。

```python
fake_items_db = [{"item_name": "Foo"}, {"item_name": "Bar"}, {"item_name": "Baz"}]

@app.get("/items/")
async def read_item(skip: int = 0, limit: int = 10):
    return fake_items_db[skip : skip + limit]
```

URL: `http://127.0.0.1:8000/items/?skip=0&limit=10`

### 默认值

查询参数可以有默认值，没有默认值时变为必填：

```python
@app.get("/items/{item_id}")
async def read_item(item_id: str, q: str | None = None):
    # q 是可选的，默认为 None
    if q:
        return {"item_id": item_id, "q": q}
    return {"item_id": item_id}
```

### 布尔类型转换

```python
@app.get("/items/{item_id}")
async def read_item(item_id: str, short: bool = False):
    item = {"item_id": item_id}
    if not short:
        item.update({"description": "Long description..."})
    return item
```

以下 URL 都表示 `short=True`：`?short=1`、`?short=True`、`?short=true`、`?short=on`、`?short=yes`

### 必填查询参数

不声明默认值即为必填：

```python
@app.get("/items/{item_id}")
async def read_user_item(item_id: str, needy: str):
    # needy 是必填参数
    return {"item_id": item_id, "needy": needy}
```

### 同时使用路径参数、查询参数

```python
@app.get("/users/{user_id}/items/{item_id}")
async def read_user_item(
    user_id: int, item_id: str,
    q: str | None = None, short: bool = False
):
    # FastAPI 自动区分：user_id、item_id 从路径取，q、short 从查询字符串取
    ...
```

---

## 6. 请求体 (Request Body) 与 Pydantic 模型

### 创建 Pydantic 模型

```python
from pydantic import BaseModel

class Item(BaseModel):
    name: str
    description: str | None = None
    price: float
    tax: float | None = None
```

等价于以下 JSON Schema：
```json
{
    "name": "str (必填)",
    "description": "str (可选)",
    "price": "float (必填)",
    "tax": "float (可选)"
}
```

### 在路径操作中使用

```python
@app.post("/items/")
async def create_item(item: Item):
    return item
```

FastAPI 会自动：
1. 读取 JSON 请求体
2. 进行类型转换
3. 数据验证（无效返回清晰错误）
4. 提供编辑器自动补全
5. 生成 JSON Schema → 加入 OpenAPI 文档

### 同时使用 Body + Path + Query

```python
@app.put("/items/{item_id}")
async def update_item(
    item_id: int,        # 路径参数
    item: Item,          # 请求体
    q: str | None = None # 查询参数
):
    result = {"item_id": item_id, **item.model_dump()}
    if q:
        result.update({"q": q})
    return result
```

FastAPI 的判断规则：
- 在路径中声明 → **路径参数**
- 是 Pydantic 模型 → **请求体**
- 是简单类型（`int`、`str` 等） → **查询参数**

### 嵌套模型

```python
class Image(BaseModel):
    url: str
    name: str

class Item(BaseModel):
    name: str
    price: float
    tags: list[str] = []
    image: Image | None = None  # 嵌套模型
    images: list[Image] | None = None  # 子模型列表
```

### model_dump() 方法

将 Pydantic 模型转为 Python dict：

```python
item_dict = item.model_dump()
```

### 不使用 Pydantic 的 Body

```python
from fastapi import Body

@app.post("/items/")
async def create_item(
    name: str = Body(),
    price: float = Body()
):
    return {"name": name, "price": price}
```

---

## 7. 参数验证与约束

### 查询参数验证

```python
from fastapi import Query
from typing import Annotated

@app.get("/items/")
async def read_items(
    q: Annotated[str, Query(
        min_length=3,
        max_length=50,
        pattern="^fixedquery$",  # 正则表达式
        title="查询字符串",
        description="在 items 中搜索"
    )] = None
):
    ...
```

常用 `Query` 参数：
| 参数 | 说明 |
|------|------|
| `min_length` / `max_length` | 字符串长度限制 |
| `pattern` | 正则表达式匹配 |
| `gt` / `ge` / `lt` / `le` | 数值比较 |
| `title` | OpenAPI 标题 |
| `description` | 字段描述 |
| `alias` | 参数别名 |
| `deprecated` | 标记为弃用 |

### 路径参数验证

```python
from fastapi import Path

@app.get("/items/{item_id}")
async def read_items(
    item_id: Annotated[int, Path(
        title="Item ID",
        ge=1,          # 大于等于 1
        le=1000        # 小于等于 1000
    )]
):
    ...
```

### Body 字段验证

```python
from pydantic import Field

class Item(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    price: float = Field(gt=0, description="价格必须大于 0")
    tax: float | None = Field(default=None, ge=0, le=0.5)
    tags: list[str] = []
```

### Cookie 与 Header 参数

```python
@app.get("/items/")
async def read_items(
    ads_id: Annotated[str | None, Cookie()] = None,
    user_agent: Annotated[str | None, Header()] = None,
    x_token: Annotated[str | None, Header()] = None
):
    ...
```

---

## 8. 响应模型与状态码

### 声明响应模型

```python
class ItemOut(BaseModel):
    name: str
    price: float
    # 不包含内部字段如 tax

@app.post("/items/", response_model=ItemOut)
async def create_item(item: Item) -> ItemOut:
    return item
```

**`response_model` 的作用：**
- 过滤输出数据（仅返回模型中声明的字段）
- 数据验证（确保返回值符合模型）
- 生成准确的 OpenAPI 文档
- 为编辑器提供返回类型提示

### 排除字段

```python
@app.get("/items/{item_id}", response_model=ItemOut)
async def read_item(item_id: int):
    ...

# 响应排除某些字段
@app.get("/items/{item_id}", response_model=Item, response_model_exclude={"tax"})
```

### 状态码

```python
from fastapi import status

@app.post("/items/", status_code=status.HTTP_201_CREATED)
async def create_item(item: Item):
    return item

# 或者直接使用数字
@app.post("/items/", status_code=201)
```

常用状态码常量：`200`、`201`、`204`、`400`、`401`、`403`、`404`、`409`、`422`、`500`

---

## 9. 错误处理

### HTTPException

```python
from fastapi import HTTPException

@app.get("/items/{item_id}")
async def read_item(item_id: int):
    if item_id not in items_db:
        raise HTTPException(
            status_code=404,
            detail="Item not found",
            headers={"X-Error": "自定义错误头"}
        )
    return items_db[item_id]
```

### 自定义异常处理器

```python
from fastapi.responses import JSONResponse

class UnicornException(Exception):
    def __init__(self, name: str):
        self.name = name

@app.exception_handler(UnicornException)
async def unicorn_exception_handler(request, exc: UnicornException):
    return JSONResponse(
        status_code=418,
        content={"message": f"Oops! {exc.name} did something."}
    )
```

---

## 10. 依赖注入 (Dependency Injection)

依赖注入是 FastAPI 最强大的功能之一。它能让你：
- 共享公共逻辑
- 共享数据库连接
- 强制执行安全、认证、角色要求等
- 减少代码重复

### 基本用法

```python
from typing import Annotated
from fastapi import Depends, FastAPI

app = FastAPI()

# 依赖函数（dependable）：结构与路径操作函数相同，但没有装饰器
async def common_parameters(
    q: str | None = None,
    skip: int = 0,
    limit: int = 100
):
    return {"q": q, "skip": skip, "limit": limit}

@app.get("/items/")
async def read_items(
    commons: Annotated[dict, Depends(common_parameters)]
):
    return commons

@app.get("/users/")
async def read_users(
    commons: Annotated[dict, Depends(common_parameters)]
):
    return commons
```

### 提取共享类型（减少重复）

```python
CommonsDep = Annotated[dict, Depends(common_parameters)]

@app.get("/items/")
async def read_items(commons: CommonsDep):
    return commons

@app.get("/users/")
async def read_users(commons: CommonsDep):
    return commons
```

### 类作为依赖

```python
class CommonQueryParams:
    def __init__(self, q: str | None = None, skip: int = 0, limit: int = 100):
        self.q = q
        self.skip = skip
        self.limit = limit

@app.get("/items/")
async def read_items(commons: Annotated[CommonQueryParams, Depends(CommonQueryParams)]):
    ...
```

### 子依赖

依赖可以依赖其他依赖，形成依赖树：

```python
def query_extractor(q: str | None = None):
    return q

def query_or_cookie_extractor(
    q: Annotated[str, Depends(query_extractor)],
    last_query: Annotated[str | None, Cookie()] = None
):
    if not q:
        return last_query
    return q

@app.get("/items/")
async def read_query(query_or_default: Annotated[str, Depends(query_or_cookie_extractor)]):
    return {"q_or_cookie": query_or_default}
```

### 依赖中 yield（类似上下文管理器）

```python
async def get_db():
    db = DBSession()
    try:
        yield db       # yield 之前 = 进入（依赖执行），yield 之后 = 退出（清理）
    finally:
        db.close()

@app.get("/items/")
async def read_items(db: Annotated[DBSession, Depends(get_db)]):
    ...
```

### 全局依赖

```python
app = FastAPI(dependencies=[Depends(verify_token), Depends(verify_key)])
```

---

## 11. 安全与认证

FastAPI 提供 `fastapi.security` 模块，简化各种安全机制。

### OAuth2 + JWT（最常用）

```python
from datetime import datetime, timedelta, timezone
from typing import Annotated
import jwt  # pip install pyjwt
from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from passlib.context import CryptContext  # pip install passlib[bcrypt]

SECRET_KEY = "your-secret-key"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

app = FastAPI()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# 密码哈希
def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

# JWT 生成
def create_access_token(data: dict, expires_delta: timedelta | None = None):
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + (expires_delta or timedelta(minutes=15))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

# 获取当前用户
async def get_current_user(token: Annotated[str, Depends(oauth2_scheme)]):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise HTTPException(status_code=401)
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401)
    return username

@app.post("/token")
async def login(form_data: Annotated[OAuth2PasswordRequestForm, Depends()]):
    # 验证用户凭据...
    access_token = create_access_token(data={"sub": form_data.username})
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/users/me")
async def read_users_me(current_user: Annotated[str, Depends(get_current_user)]):
    return {"username": current_user}
```

### OpenAPI 安全方案

FastAPI 支持 OpenAPI 的所有安全方案：

| 方案 | 来源 |
|------|------|
| `apiKey` | Query 参数 / Header / Cookie |
| `http` Bearer | `Authorization: Bearer <token>` |
| `http` Basic | HTTP Basic Auth |
| `oauth2` | OAuth2 流程（password / implicit / authorizationCode / clientCredentials） |
| `openIdConnect` | OpenID Connect 自动发现 |

---

## 12. 中间件 (Middleware)

中间件在每个请求被路径操作处理**之前**和每个响应返回**之前**执行。

### 创建中间件

```python
import time
from fastapi import FastAPI, Request

app = FastAPI()

@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start_time = time.perf_counter()
    response = await call_next(request)   # 执行路径操作
    process_time = time.perf_counter() - start_time
    response.headers["X-Process-Time"] = str(process_time)
    return response
```

### 多个中间件的执行顺序

```python
# 使用 app.add_middleware() 或 @app.middleware() 添加
# 最后添加的最外层，请求时最先执行，响应时最后执行
```

### 内置中间件

```python
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.middleware.gzip import GZipMiddleware
```

---

## 13. CORS 跨域配置

```python
from fastapi.middleware.cors import CORSMiddleware

origins = [
    "http://localhost:3000",
    "https://myfrontend.com",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,            # 或 ["*"] 允许所有
    allow_credentials=True,
    allow_methods=["GET", "POST"],    # 或 ["*"]
    allow_headers=["*"],
    expose_headers=["X-Process-Time"],
)
```

---

## 14. 后台任务

在返回响应之后执行任务，适用于邮件发送、数据处理等场景。

```python
from fastapi import BackgroundTasks, FastAPI

app = FastAPI()

def write_notification(email: str, message: str = ""):
    with open("log.txt", "a") as f:
        f.write(f"notification for {email}: {message}\n")

@app.post("/send-notification/{email}")
async def send_notification(
    email: str,
    background_tasks: BackgroundTasks
):
    background_tasks.add_task(
        write_notification,
        email,
        message="some notification"
    )
    return {"message": "Notification sent in the background"}
```

### 依赖注入中的后院任务

```python
def get_query(background_tasks: BackgroundTasks, q: str | None = None):
    if q:
        background_tasks.add_task(write_log, f"found query: {q}")
    return q

@app.post("/send-notification/{email}")
async def send_notification(
    email: str,
    background_tasks: BackgroundTasks,
    q: Annotated[str, Depends(get_query)]
):
    background_tasks.add_task(write_log, f"message to {email}")
    return {"message": "Message sent"}
```

> **注意**：对于重型后台计算（多进程/多服务器），考虑使用 Celery + Redis/RabbitMQ。

---

## 15. 数据库集成

### SQLAlchemy 集成模式

```python
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session

SQLALCHEMY_DATABASE_URL = "sqlite:///./sql_app.db"
# 或 PostgreSQL: "postgresql://user:password@localhost/dbname"

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# 依赖：获取数据库会话
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.get("/users/")
def read_users(db: Annotated[Session, Depends(get_db)]):
    users = db.query(User).all()
    return users
```

---

## 16. 大型应用：多文件组织

### 推荐目录结构

```
app/
├── __init__.py
├── main.py          # FastAPI 实例 + app.include_router()
├── dependencies.py  # 全局依赖
├── routers/
│   ├── __init__.py
│   ├── items.py     # /items/ 相关路由
│   └── users.py     # /users/ 相关路由
├── models/
│   ├── __init__.py
│   ├── item.py      # Pydantic schema
│   └── user.py
└── internal/
    ├── __init__.py
    └── admin.py     # 内部管理路由
```

### 使用 APIRouter

```python
# routers/users.py
from fastapi import APIRouter

router = APIRouter(
    prefix="/users",
    tags=["users"],
    responses={404: {"description": "Not found"}},
)

@router.get("/")
async def read_users():
    return [{"username": "Rick"}, {"username": "Morty"}]

@router.get("/{user_id}")
async def read_user(user_id: int):
    return {"user_id": user_id}
```

```python
# main.py
from fastapi import FastAPI
from app.routers import users, items

app = FastAPI()
app.include_router(users.router)
app.include_router(items.router)
```

---

## 17. WebSocket 支持

```python
from fastapi import FastAPI, WebSocket, WebSocketDisconnect

app = FastAPI()

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            data = await websocket.receive_text()
            await websocket.send_text(f"Message text was: {data}")
    except WebSocketDisconnect:
        print("Client disconnected")
```

管理多个连接：

```python
class ConnectionManager:
    def __init__(self):
        self.active_connections: list[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)

    async def broadcast(self, message: str):
        for connection in self.active_connections:
            await connection.send_text(message)

manager = ConnectionManager()

@app.websocket("/ws/{client_id}")
async def websocket_endpoint(websocket: WebSocket, client_id: int):
    await manager.connect(websocket)
    try:
        while True:
            data = await websocket.receive_text()
            await manager.broadcast(f"Client #{client_id}: {data}")
    except WebSocketDisconnect:
        manager.disconnect(websocket)
```

---

## 18. 测试

### 使用 TestClient

```python
# 安装依赖
# pip install httpx pytest

from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_read_item():
    response = client.get("/items/foo", headers={"X-Token": "coneofsilence"})
    assert response.status_code == 200
    assert response.json() == {
        "id": "foo",
        "title": "Foo",
        "description": "There goes my hero",
    }

def test_read_item_bad_token():
    response = client.get("/items/foo", headers={"X-Token": "hailhydra"})
    assert response.status_code == 400
    assert response.json() == {"detail": "Invalid X-Token header"}

def test_nonexistent_item():
    response = client.get("/items/baz", headers={"X-Token": "coneofsilence"})
    assert response.status_code == 404

def test_create_item():
    response = client.post(
        "/items/",
        headers={"X-Token": "coneofsilence"},
        json={"id": "foobar", "title": "Foo Bar", "description": "The Foo Barters"},
    )
    assert response.status_code == 200

def test_create_existing_item():
    response = client.post(
        "/items/",
        headers={"X-Token": "coneofsilence"},
        json={"id": "foo", "title": "The Foo ID Stealers"},
    )
    assert response.status_code == 409  # 409 Conflict
```

### 运行测试

```bash
pytest
# 或
pytest -v test_main.py
```

### TestClient 常用操作

```python
# GET 请求
response = client.get("/", params={"q": "test"})
# POST JSON 体
response = client.post("/items/", json={"name": "Foo", "price": 42.0})
# POST 表单数据
response = client.post("/login/", data={"username": "user", "password": "pass"})
# 设置 Header
response = client.get("/items/", headers={"Authorization": "Bearer token"})
# 设置 Cookie
response = client.get("/", cookies={"session_id": "abc123"})
```

---

## 19. 部署

### 开发模式 vs 生产模式

```bash
# 开发模式（自动重载）
fastapi dev

# 生产模式
fastapi run

# 使用 Uvicorn 直接运行
uvicorn main:app --host 0.0.0.0 --port 80 --workers 4
```

### Docker 部署

```dockerfile
FROM python:3.12
WORKDIR /code
COPY ./requirements.txt /code/requirements.txt
RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt
COPY ./app /code/app
CMD ["fastapi", "run", "app/main.py", "--port", "80"]
```

### 部署选项

- **FastAPI Cloud**：官方云平台，一键部署 `fastapi deploy`
- **Deta**、**Render**、**Railway**、**Fly.io**：支持自动部署
- **Docker + Kubernetes**：容器化部署
- **传统 VPS**：使用 Gunicorn + Uvicorn workers
- **Traefik + Let's Encrypt**：自动 HTTPS

---

## 20. 进阶主题概览

### FastAPI CLI 配置（pyproject.toml）

```toml
[tool.fastapi]
entrypoint = "app.main:app"
```

### 流式响应

```python
@app.get("/stream")
async def stream():
    async def generate():
        for i in range(10):
            yield f"data: {i}\n\n"
    return StreamingResponse(generate(), media_type="text/event-stream")
```

### 寿命事件 (Lifespan Events)

```python
from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    # 启动时执行
    print("startup")
    yield
    # 关闭时执行
    print("shutdown")

app = FastAPI(lifespan=lifespan)
```

### 静态文件

```python
from fastapi.staticfiles import StaticFiles

app.mount("/static", StaticFiles(directory="static"), name="static")
```

### 模板 (Jinja2)

```python
from fastapi.templating import Jinja2Templates

templates = Jinja2Templates(directory="templates")

@app.get("/items/{id}")
async def read_item(request: Request, id: str):
    return templates.TemplateResponse(
        "item.html",
        {"request": request, "id": id}
    )
```

### GraphQL 集成

通过 [Strawberry](https://strawberry.rocks) 或其他库与 FastAPI 集成。

### 生成客户端 SDK

基于 OpenAPI schema 自动生成前端/客户端代码（Swagger Codegen、OpenAPI Generator）。

---

## 附录：常用命令速查

| 命令 | 说明 |
|------|------|
| `pip install "fastapi[standard]"` | 完整安装（推荐） |
| `fastapi dev` | 启动开发服务器 |
| `fastapi run` | 启动生产服务器 |
| `fastapi deploy` | 部署到 FastAPI Cloud |
| `uvicorn main:app --reload` | 使用 Uvicorn 启动（开发模式） |
| `uvicorn main:app --host 0.0.0.0 --port 80 --workers 4` | 生产服务器 |
| `pytest` | 运行测试 |

## 附录：Pydantic 模型与 Python 类型速查

| Python 类型 | JSON 类型 | 示例 |
|-------------|-----------|------|
| `str` | string | `name: str` |
| `int` | integer | `age: int` |
| `float` | number | `price: float` |
| `bool` | boolean | `is_active: bool` |
| `list[T]` | array | `tags: list[str]` |
| `dict[str, T]` | object | `metadata: dict[str, str]` |
| `None` (Union) | null | `description: str \| None = None` |
| `datetime` | string (ISO 8601) | `created_at: datetime` |
| `UUID` | string (UUID) | `id: UUID` |
| `Enum` | string | `status: StatusEnum` |
| `set[T]` | array (unique) | `unique_tags: set[str]` |

## 参考资源

- [FastAPI 官方文档](https://fastapi.tiangolo.com/)
- [FastAPI GitHub](https://github.com/fastapi/fastapi)
- [Pydantic 文档](https://docs.pydantic.dev/)
- [Starlette 文档](https://www.starlette.dev/)
- [HTTPX 文档](https://www.python-httpx.org/)
- [FastAPI VS Code 扩展](https://marketplace.visualstudio.com/items?itemName=FastAPILabs.fastapi-vscode)
