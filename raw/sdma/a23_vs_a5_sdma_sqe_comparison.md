# A2/A3 vs A5 SDMA SQE 结构对比

> 基于实际代码的逐字段对比，用于指导将 shmem AIV 驱动 SDMA 从 A2/A3 迁移到 A5。

## 1. 信息来源

| 项目 | A2/A3 (shmem) | A5 (hcomm) |
|------|--------------|------------|
| SQE 结构体 | `stars_sdma_sqe_t` | `Rt91095StarsMemcpySqe` |
| Header 结构体 | `stars_sqe_header_t` | `Rt91095StarsSqeHeader` |
| 填充函数 | `aclshmemi_fill_sdma_sqe()` | `BuildA5SqeSdmaCopy()` |
| 定义文件 | `shmem/src/device/gm2gm/engine/shmemi_device_sdma.h` | `hcomm/src/.../aicpu/sqe_v82.h` |
| 构造文件 | `shmem/src/device/gm2gm/engine/shmem_device_sdma.hpp` | `hcomm/src/.../aicpu/sqe_build_a5.cc` |
| 运行侧 | AIV 核 | AICPU |
| 验证状态 | A2/A3 已验证成功 | A5 已验证成功 |

---

## 2. Header 结构对比 (bytes 0–7)

### 2.1 结构体定义

**A2/A3 shmem — `stars_sqe_header_t`:**

```cpp
struct stars_sqe_header_t {
    uint8_t  type : 6;       // bits [5:0]
    uint16_t res1 : 10;      // bits [15:6]  ← 所有控制标志被隐藏在 res1 中
    uint16_t block_dim;      // bytes [2:3]
    uint16_t rt_streamid;    // bytes [4:5]
    uint16_t task_id;        // bytes [6:7]
};
```

**A5 hcomm — `Rt91095StarsSqeHeader`:**

```cpp
struct Rt91095StarsSqeHeader {
    uint8_t  type : 6;       // bits [5:0]
    uint8_t  lock : 1;       // bit  [6]
    uint8_t  unlock : 1;     // bit  [7]
    uint8_t  ie : 1;         // bit  [8]
    uint8_t  preP : 1;       // bit  [9]
    uint8_t  postP : 1;      // bit  [10]
    uint8_t  wrCqe : 1;      // bit  [11]  ← 关键！
    uint8_t  ptrMode : 1;    // bit  [12]
    uint8_t  rttMode : 1;    // bit  [13]
    uint8_t  headUpdate : 1; // bit  [14]
    uint8_t  reserved : 1;   // bit  [15]
    uint16_t numBlocks;      // bytes [2:3]
    uint16_t rtStreamId;     // bytes [4:5]
    uint16_t taskId;         // bytes [6:7]
};
```

### 2.2 Header 逐位对比

| Bit 位 | A2/A3 shmem | A5 hcomm | 差异说明 |
|--------|-------------|----------|---------|
| [5:0] | `type = 11` | `type = 11` | **相同** — SDMA 类型号 |
| [6] | `res1` 的一部分 (=0) | `lock` | shmem 未设置 |
| [7] | `res1` 的一部分 (=0) | `unlock` | shmem 未设置 |
| [8] | `res1` 的一部分 (=0) | `ie` (interrupt enable) | shmem 未设置 |
| [9] | `res1` 的一部分 (=0) | `preP` | shmem 未设置 |
| [10] | `res1` 的一部分 (=0) | `postP` | shmem 未设置 |
| **[11]** | **`res1` 的一部分 (=0)** | **`wrCqe = 1`** | **关键差异！hcomm 设置 wrCqe=1，shmem 未设置** |
| [12] | `res1` 的一部分 (=0) | `ptrMode` | shmem 未设置 |
| [13] | `res1` 的一部分 (=0) | `rttMode` | shmem 未设置 |
| [14] | `res1` 的一部分 (=0) | `headUpdate` | shmem 未设置 |
| [15] | `res1` 的一部分 (=0) | `reserved` | — |
| [16:31] | `block_dim = 0` | `numBlocks = 0` | 相同（名称不同，语义相同） |
| [32:47] | `rt_streamid` | `rtStreamId` | 相同 |
| [48:63] | `task_id` | `taskId` | 相同（但 hcomm 用 taskId 的高低 16 位拆分赋值） |

**关键结论**: shmem 的 `stars_sqe_header_t` 把 bit[15:6] 统一标记为 `res1`，**没有设置 `wrCqe` 位**。hcomm 在 A5 上 **始终设置 `wrCqe = 1`**，这控制任务完成后是否向 CQ 写回 CQE。

> 注意：shmem 的 `stars_sdma_cmo_sqe_t` header 倒是展开了这些位（包括 `wr_cqe`），但 `stars_sdma_sqe_t` 没有。

---

## 3. Word 2–3 (bytes 8–15) 对比

| 字节偏移 | A2/A3 shmem | A5 hcomm | 差异 |
|---------|-------------|----------|------|
| 8–11 | `res3` (uint32_t, =0) | `res1` (uint32_t) | 相同（保留字段） |
| 12–13 | `res4` (uint16_t, =0) | `res2` (uint16_t) | 相同（保留字段） |
| 14 | `kernel_credit = 240` | `kernelCredit = 254` | **不同值！见下文** |
| 15 | `ptr_mode:1 + res5:7` | `res3` (uint8_t) | shmem 有 ptr_mode 位；hcomm 全保留 |

### 3.1 kernel_credit 值差异

| 来源 | 常量名 | 值 | 含义 |
|------|--------|---|------|
| shmem | `ACLSHMEM_STARS_DEFAULT_KERNEL_CREDIT` | **240** | 对应 960s 超时 |
| hcomm (sqe.h) | `RT_STARS_DEFAULT_KERNEL_CREDIT` | **254** | 接近最大值 |
| hcomm (aicpu_hccl_sqcq.h) | `RT_STARS_DEFAULT_KERNEL_CREDIT` | **254** (255-1) | kCreditTimeInvalid - 1 |
| 不超时 | `RT_STARS_NEVER_TIMEOUT_KERNEL_CREDIT` | **255** | 永不超时 |

shmem 用 240（约 960s），hcomm 用 254（接近永不超时）。**在 A5 上建议使用 254**。

---

## 4. Word 4 (bytes 16–19) — 关键差异：位域布局完全不同！

这是 **最大的结构性差异**。同样 32 bits，位域排列完全不同。

### 4.1 A2/A3 shmem 布局

```
bits [7:0]   opcode      : 8
bit  [8]     ie2         : 1    ← 注意 ie2 在 sssv 前面！
bit  [9]     sssv        : 1
bit  [10]    dssv        : 1
bit  [11]    sns         : 1
bit  [12]    dns         : 1
bits [16:13] qos         : 4    ← qos 在 word4
bit  [17]    sro         : 1
bit  [18]    dro         : 1
bits [26:19] partid      : 8    ← partid 在 word4
bit  [27]    mpam        : 1    ← mpam 在 word4
bits [31:28] res6        : 4
```

### 4.2 A5 hcomm 布局

```
bits [7:0]   opcode      : 8
bit  [8]     sssv        : 1    ← sssv 紧跟 opcode！
bit  [9]     dssv        : 1
bit  [10]    sns         : 1
bit  [11]    dns         : 1
bit  [12]    sro         : 1
bit  [13]    dro         : 1
bits [15:14] stride      : 2    ← A5 新增 stride 字段
bit  [16]    ie2         : 1    ← ie2 移到 bit16
bit  [17]    compEn      : 1    ← A5 新增 compEn 字段
bits [31:18] res4        : 14   ← 大量保留位（qos/partid/mpam 移走了）
```

### 4.3 Word 4 逐位差异表

| Bit | A2/A3 shmem | A5 hcomm | 影响 |
|-----|-------------|----------|------|
| [7:0] | opcode=0 | opcode=0 | **相同** |
| **[8]** | **ie2=0** | **sssv=1** | **完全不同的字段！** |
| **[9]** | **sssv=1** | **dssv=1** | **字段错位** |
| **[10]** | **dssv=1** | **sns=1** | **字段错位** |
| **[11]** | **sns=1** | **dns=1** | **字段错位** |
| **[12]** | **dns=1** | **sro=0** | **字段错位** |
| **[13]** | **qos[0]** | **dro=0** | **完全不同** |
| [14] | qos[1] | stride[0] | 不同 |
| [15] | qos[2] | stride[1] | 不同 |
| [16] | qos[3] | ie2=0 | 不同 |
| [17] | sro | compEn | 不同 |
| [18] | dro | res4 | 不同 |
| [19:26] | partid=0 | res4 | 不同 |
| [27] | mpam=0 | res4 | 不同 |
| [28:31] | res6 | res4 | 均为保留 |

**结论**: 即使设置相同的逻辑值 (sssv=1, dssv=1, sns=1, dns=1)，由于位域偏移不同，生成的二进制值完全不同。**直接使用 shmem 的 SQE 结构在 A5 上一定不能工作**。

### 4.4 二进制值对比（假设 opcode=0, sssv=1, dssv=1, sns=1, dns=1）

```
A2/A3 shmem word4 = 0x00001E00
  ie2=0 at bit8, sssv=1 at bit9, dssv=1 at bit10, sns=1 at bit11, dns=1 at bit12
  = 0b 0000_0000_0000_0000_0001_1110_0000_0000

A5 hcomm word4   = 0x00000F00
  sssv=1 at bit8, dssv=1 at bit9, sns=1 at bit10, dns=1 at bit11
  = 0b 0000_0000_0000_0000_0000_1111_0000_0000
```

---

## 5. Word 5 (bytes 20–23) — 布局完全不同

| 字节 | A2/A3 shmem | A5 hcomm |
|------|-------------|----------|
| 20–21 | `src_streamid` (uint16_t) | `sqeId` (uint16_t) |
| 22 | `src_sub_streamid` 低字节 | `mapamPartId` (uint8_t) |
| 23 | `src_sub_streamid` 高字节 | `mpamns:1, pmg:2, qos:4, d2dOffsetFlag:1` |

**关键**: A5 把 `qos` 和 `mapamPartId`(即 partid) 放在 word5，而 A2/A3 把它们放在 word4。

**shmem 填充**: `sqe->qos = 6`（在 word4 中）
**hcomm 填充**: `sqe->mapamPartId = partId`（在 word5 中），qos 未主动设置（默认 0）

---

## 6. Word 6 (bytes 24–27) — 不同语义

| 字节 | A2/A3 shmem | A5 hcomm |
|------|-------------|----------|
| 24–25 | `dst_streamid` (uint16_t) | `srcStreamId` (uint16_t) |
| 26–27 | `dst_sub_streamid` (uint16_t) | `srcSubStreamId` (uint16_t) |

shmem 放的是 **dst** stream，hcomm 放的是 **src** stream。

---

## 7. Words 7–15 (bytes 28–63) — 数据区域布局差异巨大

这是最关键的数据区域，地址和长度的位置完全不同：

| 字节偏移 | A2/A3 shmem | A5 hcomm |
|---------|-------------|----------|
| **28–31** | **`length`** (传输长度) | `dstStreamId + dstSubStreamId` |
| 32–35 | `src_addr_low` | `srcAddrLow` |
| 36–39 | `src_addr_high` | `srcAddrHigh` |
| 40–43 | `dst_addr_low` | `dstAddrLow` |
| 44–47 | `dst_addr_high` | `dstAddrHigh` |
| **48–51** | `link_type=255` + reserved[3] | **`lengthMove`** (传输长度) |
| 52–55 | `reslast[0]` | `srcOffsetLow` |
| 56–59 | `reslast[1]` | `dstOffsetLow` |
| 60–63 | `reslast[2]` | `srcOffsetHigh + dstOffsetHigh` |

### 7.1 关键差异

1. **`length` 位置**: shmem 在 **offset 28**，hcomm 在 **offset 48**！差了 20 字节。
2. **src/dst 地址**: 两者都在 offset 32–47，**这部分一致**。
3. **offset 28–31**: shmem 放 length；hcomm 放 dstStreamId/dstSubStreamId。
4. **offset 48–51**: shmem 放 link_type(=255)；hcomm 放 lengthMove。
5. **offset 52–63**: shmem 全是 reslast(=0)；hcomm 有 offset 字段。

> 如果直接用 shmem 的 SQE 结构在 A5 上，硬件会在 offset 48 读 length，但那里是 `link_type=255`（即 0x000000FF），会被当作传输长度 255 字节——而不是实际的 length 值。

---

## 8. 完整 64 字节内存布局总览

```
Offset   A2/A3 shmem                   A5 hcomm
------   -------------------------     -------------------------
 0- 1    type:6 + res1:10              type:6 + lock:1 + unlock:1 +
                                       ie:1 + preP:1 + postP:1 +
                                       wrCqe:1 + ptrMode:1 + rttMode:1 +
                                       headUpdate:1 + reserved:1
 2- 3    block_dim                     numBlocks
 4- 5    rt_streamid                   rtStreamId
 6- 7    task_id                       taskId
 8-11    res3                          res1
12-13    res4                          res2
  14     kernel_credit (240)           kernelCredit (254)
  15     ptr_mode:1 + res5:7           res3
16-19    opcode|ie2|sssv|dssv|sns|     opcode|sssv|dssv|sns|dns|
         dns|qos|sro|dro|partid|       sro|dro|stride|ie2|compEn|
         mpam|res6                     res4
20-21    src_streamid                  sqeId
22-23    src_sub_streamid              mapamPartId + mpamns|pmg|qos|d2d
24-25    dst_streamid                  srcStreamId
26-27    dst_sub_streamid              srcSubStreamId
28-31    ★ length                      dstStreamId + dstSubStreamId
32-35    src_addr_low                  srcAddrLow
36-39    src_addr_high                 srcAddrHigh
40-43    dst_addr_low                  dstAddrLow
44-47    dst_addr_high                 dstAddrHigh
48-51    link_type + reserved[3]       ★ lengthMove
52-55    reslast[0]                    srcOffsetLow
56-59    reslast[1]                    dstOffsetLow
60-63    reslast[2]                    srcOffsetHigh + dstOffsetHigh
```

---

## 9. 填充逻辑对比

### 9.1 A2/A3 shmem — `aclshmemi_fill_sdma_sqe()`

```cpp
// shmem/src/device/gm2gm/engine/shmem_device_sdma.hpp L60-93
sqe->header.type        = 11;             // ACLSHMEM_SQE_TYPE_SDMA
sqe->header.block_dim   = 0;
sqe->header.rt_streamid = channel_info->stream_id;
sqe->header.task_id     = task_id;        // 直接赋值，无高低 16 位拆分
sqe->kernel_credit      = 240;            // ACLSHMEM_STARS_DEFAULT_KERNEL_CREDIT
sqe->ptr_mode           = 0;
sqe->opcode             = 0;
sqe->ie2                = 0;
sqe->sssv               = 1;
sqe->dssv               = 1;
sqe->sns                = 1;
sqe->dns                = 1;
sqe->qos                = 6;              // HCCL QoS
sqe->partid             = 0;
sqe->mpam               = 0;
sqe->length             = length;         // ← 在 offset 28
sqe->src_addr_low       = lo32(src);
sqe->src_addr_high      = hi32(src);
sqe->dst_addr_low       = lo32(dst);
sqe->dst_addr_high      = hi32(dst);
sqe->link_type          = 255;            // ← 在 offset 48
```

### 9.2 A5 hcomm — `BuildA5SqeSdmaCopy()`

```cpp
// hcomm/src/.../aicpu/sqe_build_a5.cc L134-157
header->rtStreamId     = (uint16_t)(taskId);        // taskId 低 16 位
header->taskId         = (uint16_t)(taskId >> 16);   // taskId 高 16 位
sqe->header.type       = 11;             // RT_91095_SQE_TYPE_SDMA
sqe->header.wrCqe      = 1;              // ← 关键：写 CQE
sqe->opcode            = opcode;
sqe->kernelCredit      = 254;            // RT_STARS_DEFAULT_KERNEL_CREDIT
sqe->sssv              = 1;
sqe->dssv              = 1;
sqe->sns               = 1;
sqe->dns               = 1;
sqe->mapamPartId       = partId;         // ← 在 word5 (offset 22)
// qos 未设置 (默认 0)
sqe->u.strideMode0.lengthMove  = size;   // ← 在 offset 48
sqe->u.strideMode0.srcAddrLow  = lo32(src);
sqe->u.strideMode0.srcAddrHigh = hi32(src);
sqe->u.strideMode0.dstAddrLow  = lo32(dst);
sqe->u.strideMode0.dstAddrHigh = hi32(dst);
```

---

## 10. Doorbell / 提交机制对比

| 项目 | A2/A3 shmem (AIV) | A5 hcomm (AICPU) |
|------|-------------------|-------------------|
| SQE 写入方式 | `__gm__` 指针直接写 SQ buffer | memcpy 到局部 buf → memcpy 到 SQ VA |
| Cache 处理 | `DataCacheCleanAndInvalid<ENTIRE_DATA_CACHE>` 刷全量 | `dsb st`（ARM Store Barrier） |
| Doorbell 方式 | MTE 写 `sq_reg_base + 8`（UB→GM） | `halSqCqConfig(SQ_TAIL, newTail)` |
| Tail 更新 | 同时写回 `channel_info->sq_tail` | 由 HAL 层管理 |
| Doorbell 偏移 | **+8** | N/A（HAL 封装） |

### 10.1 shmem AIV doorbell 关键代码

```cpp
// 刷 SQE 数据到 HBM
DataCacheCleanAndInvalid<uint8_t, CacheLine::ENTIRE_DATA_CACHE, DcciDst::CACHELINE_OUT>(write_info);

// 敲 doorbell: 用 MTE (UB→GM) 写 sq_reg_base + 8
aclshmemi_set_value<uint32_t>((__gm__ uint8_t *)(channel_info->sq_reg_base) + 8,
                               sq_tail, tmp_local, sync_id);

// 更新本地 tail 记录
aclshmemi_set_value<uint32_t>(((__gm__ uint8_t *)channel_info) + 4,
                               sq_tail, tmp_local, sync_id);
```

### 10.2 hcomm AICPU doorbell 关键代码

```cpp
// 写 SQ 后 dsb st
__asm__ __volatile__("dsb st" : : : "memory");

// 敲 doorbell: halSqCqConfig
halSqCqConfigInfo ci;
ci.sqId = sqId; ci.prop = DRV_SQCQ_PROP_SQ_TAIL; ci.value[0] = newTail;
halSqCqConfig(devId, &ci);
```

---

## 11. 差异总结与迁移要点

### 11.1 必须修改的字段

| # | 差异项 | 从 A2/A3 → A5 需要的改动 | 严重程度 |
|---|--------|------------------------|---------|
| 1 | **Word4 位域布局** | 整个 word4 的位域定义必须换成 A5 版本 | **致命** |
| 2 | **length 位置** | 从 offset 28 移到 offset 48 (strideMode0.lengthMove) | **致命** |
| 3 | **wrCqe** | header 中设置 `wrCqe = 1` | **重要** |
| 4 | **qos/partid/mpam 位置** | 从 word4 移到 word5 (mapamPartId/qos) | **重要** |
| 5 | **word5 整体** | src_streamid → sqeId + mapamPartId + qos/mpam | **重要** |
| 6 | **word6 语义** | dst_streamid → srcStreamId | 中等 |
| 7 | **word7 新增** | 无 → dstStreamId/dstSubStreamId | 中等 |
| 8 | **kernel_credit** | 240 → 254 | 低（但建议改） |
| 9 | **link_type** | A2/A3 offset 48 设 255；A5 offset 48 是 length | **致命**（互斥） |
| 10 | **taskId 赋值** | 直接赋值 → 高低 16 位拆分到 rtStreamId/taskId | 中等 |

### 11.2 不需要修改的字段

| 字段 | 说明 |
|------|------|
| `type = 11` | 两代相同 |
| `src_addr_low/high` (offset 32–39) | 两代位置相同 |
| `dst_addr_low/high` (offset 40–47) | 两代位置相同 |
| `sssv=1, dssv=1, sns=1, dns=1` | 逻辑值相同（但位偏移不同！必须用 A5 结构体） |

### 11.3 Doorbell 迁移要点

从 AIV 驱动到 A5：
1. **已验证**: AICPU 上 `halSqCqConfig(SQ_TAIL)` 可以成功敲 doorbell
2. **已验证**: AICPU 上直接写 `sq_reg_base` 寄存器也可以触发任务
3. **待验证**: AIV 上通过 MTE 写 `sq_reg_base + 8` 的方式在 A5 上是否仍有效
4. AIV 侧必须用 `DataCacheCleanAndInvalid` 刷缓存后再敲 doorbell

---

## 12. 迁移建议：最小改动方案

将 shmem 的 AIV SDMA 代码从 A2/A3 迁移到 A5，核心改动是 **替换 SQE 结构体**：

```cpp
// 方案: 在 shmem 中新增 A5 版本的 SQE 结构体和填充函数

#if defined(ASCEND_910_95) || defined(ASCEND_950)  // A5 平台

// 直接使用 hcomm 的 Rt91095StarsMemcpySqe 结构体
// 或者定义一个等价的 stars_sdma_sqe_a5_t

ACLSHMEM_DEVICE void aclshmemi_fill_sdma_sqe_a5(
    __gm__ stars_channel_info_t* channel_info,
    __gm__ uint8_t* src, __gm__ uint8_t* dst,
    uint32_t length, uint32_t sq_tail, uint32_t task_id)
{
    // 用 A5 结构体布局填充
    // 关键: wrCqe=1, kernel_credit=254, length在offset48
    // 位域使用 A5 的排列方式
}

#else  // A2/A3 平台

// 继续使用现有的 stars_sdma_sqe_t 和 aclshmemi_fill_sdma_sqe

#endif
```

**不需要修改的部分**:
- SQ buffer 的写入方式（AIV `__gm__` 指针写入）
- Cache 刷新逻辑（`DataCacheCleanAndInvalid`）
- Doorbell 机制（写 `sq_reg_base + 8`，需先在 A5 上验证 AIV 侧是否可用）
- Tail 管理逻辑
