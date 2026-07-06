# python-office — 一行代码搞定自动化办公

> 官网：https://www.python-office.com/
> 安装：`pip install python-office`
> 作者：程序员晚枫

---

## 核心理念

把办公自动化操作封装为**一行函数调用**，让 Python 自动化办公像 Excel 公式一样简单。

```python
import office

office.excel.fake2excel(...)    # 生成模拟数据
office.pdf.pdf2docx(...)        # PDF 转 Word
office.email.send_email(...)    # 发邮件
```

---

## 13 大模块一览

| 模块              | 功能                    | 对你实用度 |
| --------------- | --------------------- | ----- |
| 📊 **Excel**    | 生成、合并、拆分、搜索、转 PDF     | ⭐⭐⭐⭐⭐ |
| 📝 **Word**     | 转 PDF、合并、图片提取         | ⭐⭐⭐   |
| 📑 **PDF**      | 转 Word/图片、合并、拆分、加密、水印 | ⭐⭐⭐⭐⭐ |
| 📊 **PPT**      | 转 PDF、转图片、合并          | ⭐⭐    |
| 🖼️ **Image**   | 压缩、水印、词云、二维码、去水印      | ⭐⭐⭐   |
| 📁 **File**     | 批量重命名、文件搜索            | ⭐⭐⭐⭐  |
| 📧 **Email**    | 发送/接收邮件、附件、群发         | ⭐⭐⭐   |
| 💬 **WeChat**   | 微信消息、定时、群发（需登录）       | ⭐⭐    |
| 🔍 **OCR**      | 发票识别→Excel（需百度 API）   | ⭐⭐    |
| 🎬 **Video**    | 音视频转换、水印、字幕           | ⭐     |
| 📝 **Markdown** | Excel 转 Markdown      | ⭐     |
| 💰 **Finance**  | 股票 T+0 收益计算           | ⭐     |
| 🛠️ **Tools**   | 翻译、二维码、密码、天气等         | ⭐⭐⭐   |

---

## 📊 Excel 模块

### 生成模拟数据

```python
import office

office.excel.fake2excel(
    columns=['name', 'phone', 'email', 'address'],   # 字段名
    rows=1000,                                        # 行数
    path='./test_users.xlsx'                          # 保存路径
)
```

**可用字段**：name, phone, email, address, company, job, country, city, postcode, ssn, credit_card_number, user_agent, text, sentence

### 合并多个 Excel

```python
# 合并一个目录下所有 Excel
office.excel.merge2excel(
    dir_path='./部门报表/',
    output_file='月度汇总.xlsx'
)
```

### 拆分 / 合并 Sheet

```python
# 把一个多 sheet Excel 拆成多个文件
office.excel.sheet2excel(
    file_path='./multi_sheet.xlsx',
    output_path='./拆分后/'
)

# 合并多个 Excel 到同一个 Sheet
office.excel.merge2sheet(
    dir_path='./excels/',
    output_sheet_name='汇总',
    output_excel_name='all_merged'
)
```

### 搜索 & 按列拆分

```python
# 在所有 Excel 中搜索关键词
office.excel.find_excel_data(
    search_key='客户A',
    target_dir='./历史合同/'
)

# 按列值拆分 Excel 为多个文件
office.excel.split_excel_by_column(
    filepath='./员工信息.xlsx',
    column=2
)
```

### Excel 转 PDF

```python
office.excel.excel2pdf(
    excel_path='./月报.xlsx',
    pdf_path='./月报.pdf',
    sheet_id=0
)
```

---

## 📑 PDF 模块（功能最丰富，13 个函数）

### 转 Word / 图片

```python
# PDF 转 Word
office.pdf.pdf2docx(
    input_file='./合同.pdf',
    output_file='./合同.docx'
)

# PDF 转图片（每页一张）
office.pdf.pdf2imgs(
    input_file='./产品手册.pdf',
    output_file='./images/'
)

# 合并为一张长图
office.pdf.pdf2imgs(
    input_file='./产品手册.pdf',
    output_file='./long_image.png',
    merge=True
)
```

### 合并 & 拆分

```python
# 合并多个 PDF
office.pdf.merge2pdf(
    input_file_list=['./封面.pdf', './正文.pdf', './附录.pdf'],
    output_file='./完整文档.pdf'
)

# 拆分（提取指定页码范围）
office.pdf.split4pdf(
    input_file='./大型文档.pdf',
    output_file='./前10页.pdf',
    from_page=1,
    to_page=10
)

# 删除指定页面
office.pdf.del4pdf(
    input_file='./原文档.pdf',
    output_file='./处理后.pdf',
    page_nums=[1, 3, 5]
)
```

### 加密 / 解密

```python
# 加密
office.pdf.encrypt4pdf(
    password='mypassword',
    input_file='./机密.pdf',
    output_file='./机密_加密.pdf'
)

# 解密
office.pdf.decrypt4pdf(
    password='mypassword',
    input_file='./机密_加密.pdf',
    output_file='./机密_解密.pdf'
)
```

### 加水印

```python
# 文本水印
office.pdf.add_text_watermark(
    input_file='./文档.pdf',
    text='机密 - 仅供内部使用',
    output_file='./带水印.pdf',
    fontsize=30,
    color=(1, 0, 0)
)

# 图片水印
office.pdf.add_img_water(
    input_file='./文档.pdf',
    mark_file='./logo.png',
    output_file='./带水印.pdf'
)
```

---

## 📝 Word 模块

```python
# Word 转 PDF（支持批量）
office.word.docx2pdf(
    path='./合同.docx',           # 单个文件或文件夹路径
    output_path='./pdf_files/'
)

# 合并多个 Word
office.word.merge4docx(
    input_path='./周报/',
    output_path='./汇总/',
    new_word_name='全组周报'
)

# Doc ↔ Docx 互转
office.word.doc2docx(input_path='./旧版报告.doc', output_path='./modern/')
office.word.docx2doc(input_path='./新版报告.docx', output_path='./legacy/')

# 提取 Word 中的图片
office.word.docx4imgs(
    word_path='./产品手册.docx',
    img_path='./extracted_images/'
)
```

> ⚠️ Word/PDF 互转依赖 LibreOffice：
> - Linux: `sudo apt install libreoffice`
> - macOS: `brew install --cask libreoffice`

---

## 📊 PPT 模块

```python
# PPT 转 PDF
office.ppt.ppt2pdf(path='./产品介绍.pptx', output_path='./pdf_files/')

# PPT 转图片
office.ppt.ppt2img(input_path='./产品介绍.pptx', output_path='./images/', merge=False)
office.ppt.ppt2img(input_path='./产品介绍.pptx', output_path='./长图.png', merge=True)

# 合并多个 PPT
office.ppt.merge4ppt(input_path='./分章节PPT/', output_path='./完整版/', output_name='完整产品介绍.pptx')
```

---

## 🖼️ Image 模块

```python
# 图片压缩
office.image.compress_image(
    input_file='./原始大图.jpg', output_file='./压缩后.jpg', quality=85
)

# 加水印
office.image.add_watermark(
    file='./photo.jpg', mark='@python-office',
    color='#eaeaea', size=30, opacity=0.35, angle=30
)

# 词云
office.image.txt2wordcloud(
    filename='./文章.txt', color='white', result_file='./词云.png'
)

# 图片转卡通
office.image.img2Cartoon(path='./photo.jpg')

# 二维码识别
result = office.image.decode_qrcode(qrcode_path='./qr.png')

# 下载网络图片
office.image.down4img(
    url='https://example.com/image.jpg', output_path='./images/',
    output_name='photo', type='jpg'
)

# 铅笔画效果
office.image.pencil4img(input_img='./photo.jpg', output_path='./art/', output_name='pencil.jpg')

# 去水印
office.image.del_watermark(input_image='./带水印.jpg', output_image='./无水印.jpg')
```

---

## 📁 File 模块

```python
# 批量重命名（替换关键词）
office.file.replace4filename(
    path='./照片/', del_content='IMG_', replace_content='旅行_'
)

# 加前缀/后缀
office.file.file_name_add_prefix(file_path='./文档/', prefix_content='2026_')
office.file.file_name_add_postfix(file_path='./文档/', postfix_content='_v1')

# 文件名导出到 Excel
office.file.output_file_list_to_excel(dir_path='./文档/')

# 按后缀搜索文件
files = office.file.get_files(path='./', suffix='.xlsx', sub=True)
```

---

## 📧 Email 模块

```python
# 简单发送
office.email.send_email(
    key='你的邮箱授权码',          # 不是登录密码！
    msg_from='your@qq.com',
    msg_to='target@qq.com',
    msg_subject='会议通知',
    content='明天下午 3 点开会。'
)

# 带附件 + 抄送
office.email.send_email(
    key='你的邮箱授权码',
    msg_from='your@qq.com',
    msg_to='主要@qq.com',
    msg_cc='抄送1@qq.com, 抄送2@qq.com',
    msg_subject='项目周报',
    content='请查收。',
    attach_files=['./周报.pdf', './数据.xlsx']
)

# 接收邮件
office.email.receive_email(
    key='你的邮箱授权码',
    msg_from='your@qq.com',
    msg_to='sender@qq.com',
    output_path='./received_emails/',
    status='UNSEEN'
)
```

**邮箱配置**：

| 邮箱 | host | 端口 |
|------|------|------|
| QQ | smtp.qq.com | 465 |
| 163 | smtp.163.com | 465 |
| Gmail | smtp.gmail.com | 587 |

> ⚠️ `key` 是**邮箱授权码**，不是登录密码。

---

## 🔍 OCR 模块

需要**百度智能云** API Key（免费额度够用）：

1. 注册 [百度智能云](https://ai.baidu.com/)
2. 创建「文字识别 OCR」应用
3. 获取 API Key 和 Secret Key

```python
# 单张发票
office.ocr.VatInvoiceOCR2Excel(
    input_path='./invoice_001.jpg',
    output_path='./output/'
)

# 批量识别
office.ocr.VatInvoiceOCR2Excel(
    input_path='./所有发票/',
    output_path='./output/',
    output_excel='本月发票汇总.xlsx',
    file_name=True
)

# 网络图片
office.ocr.VatInvoiceOCR2Excel(
    img_url='https://example.com/invoice.jpg',
    output_path='./output/'
)
```

识别结果自动包含：发票代码、号码、开票日期、销售方/购买方信息、金额、税额等。

---

## 🛠️ Tools 模块

```python
# 翻译
result = office.tools.transtools(to_lang='en', content='你好，世界！')

# 二维码生成
office.tools.qrcodetools(url='https://www.python-office.com', output='./qrcode.png')

# 密码生成
password = office.tools.passwordtools(len=16)

# URL 转 IP
ip = office.tools.url2ip(url='www.baidu.com')

# 天气查询
office.tools.weather()

# 网速测试
office.tools.net_speed_test()

# AI 生成文章
office.tools.create_article(theme='Python 自动化办公', line_num=200)
```

---

## 实战场景：生信分析报告自动化

```python
import office
from datetime import datetime
import pandas as pd

# ① Excel：合并 DEG 结果和样本信息
office.excel.merge2excel(
    dir_path='./analysis_results/',
    output_file=f'DEG_汇总_{datetime.now():%Y%m}.xlsx'
)

# ② PDF：转成可分享的报告
office.excel.excel2pdf(
    excel_path=f'DEG_汇总_{datetime.now():%Y%m}.xlsx',
    pdf_path=f'分析报告_{datetime.now():%Y%m}.pdf'
)

# ③ 加水印防泄露
office.pdf.add_text_watermark(
    input_file=f'分析报告_{datetime.now():%Y%m}.pdf',
    text='内部结果 - 未经授权不得转发',
    output_file=f'分析报告_最终版.pdf'
)

# ④ 发送给合作者
office.email.send_email(
    key='你的授权码',
    msg_from='your@qq.com',
    msg_to='collaborator@university.edu',
    msg_subject=f'分析报告 {datetime.now():%Y%m}',
    content='请查收本月的分析结果。',
    attach_files=[f'分析报告_最终版.pdf']
)
```

## 注意事项

1. **依赖 LibreOffice** — Word/PDF/PPT 转换需要系统安装 LibreOffice
2. **Excel 操作** — 底层基于 openpyxl/pandas，大文件（>10万行）会慢
3. **合并仅保留数据** — 不保留原始 Excel 格式
4. **邮箱 key** — 是授权码，不是登录密码
5. **OCR** — 必须申请百度智能云 API key
