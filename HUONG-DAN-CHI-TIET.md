# 📘 HƯỚNG DẪN CHI TIẾT - GIẢI THÍCH TỪNG DÒNG CODE

## 📋 MỤC LỤC
1. [Giới thiệu](#giới-thiệu)
2. [Giải thích Dockerfile](#giải-thích-dockerfile)
3. [Giải thích .dockerignore](#giải-thích-dockerignore)
4. [Giải thích seccomp-profile.json](#giải-thích-seccomp-profile)
5. [Giải thích apparmor-profile](#giải-thích-apparmor-profile)
6. [Giải thích kubernetes-security.yaml](#giải-thích-kubernetes)
7. [Giải thích docker-compose-security.yaml](#giải-thích-docker-compose)
8. [Giải thích Jenkinsfile - Từ Zero đến Advance](#giải-thích-jenkinsfile)
9. [Giải thích Terraform - Từ Zero đến Advance](#giải-thích-terraform)

---

## 🎯 GIỚI THIỆU

### Docker là gì?
**Docker** là công nghệ **containerization** - đóng gói ứng dụng cùng tất cả dependencies thành một **container** có thể chạy ở bất cứ đâu.

**Ví dụ dễ hiểu:**
```
Container = Nhà di động (nhà đã có sẵn đồ đạc)
Image = Bản vẽ thiết kế nhà di động
Dockerfile = Công thức để xây nhà di động
```

---

## 📄 GIẢI THÍCH DOCKERFILE

### DÒNG 1-12: PHẦN ĐẦU - SYNTAX VÀ CHUẨN

```dockerfile
# syntax=docker/dockerfile:1.7
```
**GIẢI THÍCH:**
- **# syntax=**: Nói với Docker dùng phiên bản Dockerfile syntax nào
- **docker/dockerfile:1.7**: Dùng BuildKit phiên bản 1.7 (phiên bản mới nhất 2025)
- **TẠI SAO CẦN?** Để sử dụng tính năng mới như `--mount`, cache, SSH mounts

```dockerfile
# =============================================================================
# ENTERPRISE-GRADE DOCKERFILE - ULTIMATE BEST PRACTICES (2025)
# =============================================================================
```
**GIẢI THÍCH:**
- Chỉ là **comment** (ghi chú)
- Dùng để người đọc biết file này có tiêu chuẩn cao nhất

```dockerfile
# Standards Compliance:
# - CIS Docker Benchmark 1.5.0
```
**GIẢI THÍCH:**
- **CIS Docker Benchmark**: Bộ chuẩn bảo mật của Docker (Center for Internet Security)
- Phiên bản 1.5.0 là bộ chuẩn mới nhất
- Quy định khoảng 150 rules để Docker container an toàn

```dockerfile
# - OCI (Open Container Initiative) Runtime Specification
```
**GIẢI THÍCH:**
- **OCI**: Tổ chức quốc tế định nghĩa chuẩn container
- Giúp Docker images chạy được trên nhiều platform (Docker, Podman, Kubernetes)

```dockerfile
# - NIST Container Security Guidelines
```
**GIẢI THÍCH:**
- **NIST**: Viện tiêu chuẩn kỹ thuật quốc gia Mỹ
- Hướng dẫn bảo mật container cho chính phủ Mỹ

```dockerfile
# - DockerCon 2024 Best Practices
```
**GIẢI THÍCH:**
- Hội nghị Docker lớn nhất thế giới
- Best practices được đúc kết từ các chuyên gia

```dockerfile
# - CTF Security Competition Standards
```
**GIẢI THÍCH:**
- **CTF = Capture The Flag**: Cuộc thi hack thuật toán toàn cầu
- DEF CON CTF, Google CTF, HackTM
- Standards bảo mật từ các cuộc thi này cực kỳ khắc nghiệt

```dockerfile
# - Supply Chain Levels for Software Artifacts (SLSA)
```
**GIẢI THÍCH:**
- **SLSA**: Chuẩn bảo mật chuỗi cung ứng phần mềm của Google
- Ngăn chặn tấn công supply chain (như SolarWinds 2020)

---

### DÒNG 14-36: BUILD ARGUMENTS

```dockerfile
# ------------------------------------------
# BUILD ARGUMENTS (Front matter)
# ------------------------------------------
```
**GIẢI THÍCH:**
- **ARG**: Argument (đối số) - biến số dùng KHI BUILD image
- Khác với **ENV** (biến môi trường dùng KHI RUN container)
- **Front matter**: Để ở đầu file (trước FROM)

```dockerfile
# ✅ Use ARGs for metadata (not secrets!)
```
**GIẢI THÍCH:**
- ARG dùng cho metadata (thông tin mô tả)
- **KHÔNG BAO GIỜ** dùng ARG cho passwords, API keys
- Vì ARG sẽ visible trong `docker history`

```dockerfile
# ✅ Default values for local development
# ✅ Override at build time: --build-arg VERSION=1.0.0
```
**GIẢI THÍCH:**
- Giá trị default dùng khi dev local
- Có thể override khi build production:
```bash
docker build --build-arg VERSION=2.0.0 --build-arg NODE_VERSION=21 .
```

---

#### DÒNG 21-23: BASE IMAGE ARGUMENTS

```dockerfile
ARG NODE_VERSION=20
```
**GIẢI THÍCH:**
- Tên biến: `NODE_VERSION`
- Giá trị mặc định: `20` (Node.js version 20 LTS)
- Dùng để chọn version Node.js
- **Override** khi muốn version khác:
```bash
docker build --build-arg NODE_VERSION=18 .
```

```dockerfile
ARG ALPINE_VERSION=3.19
```
**GIẢI THÍCH:**
- **Alpine Linux**: Distro Linux siêu nhỏ (~5MB)
- Phiên bản 3.19 là stable version 2024
- Nhỏ hơn Ubuntu 40 lần

```dockerfile
ARG NODE_IMAGE_SHA256=abc123...
```
**GIẢI THÍCH:**
- **SHA256**: Mã hash fingerprint của image
- Dùng để **verify image integrity** (không bị bịn change)
- Khi pull image, Docker sẽ check hash này
- Nếu hash không khớp → sẽ từ chối chạy
- **Cách lấy SHA256 thực tế:**
```bash
docker pull node:20-alpine
docker inspect node:20-alpine | grep RepoDigest
# Kết quả: node:20-alpine@sha256:real_hash_here
```

---

#### DÒNG 25-32: METADATA ARGUMENTS

```dockerfile
# ✅ Metadata labels (OCI compliant)
```
**GIẢI THÍCH:**
- **Metadata**: Dữ liệu về dữ liệu (data about data)
- **OCI compliant**: Tuân theo chuẩn OCI
- Labels sẽ được embed vào Docker image

```dockerfile
ARG BUILD_DATE
```
**GIẢI THÍCH:**
- Ngày giờ build image
- **Không có giá trị mặc định** (bắt buộc phải cung cấp)
- **Cách set:**
```bash
docker build --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") .
```

```dockerfile
ARG VERSION=1.0.0
```
**GIẢI THÍCH:**
- Version của ứng dụng
- Dùng để track versions trong production
- Format chuẩn: **Semantic Versioning** (MAJOR.MINOR.PATCH)
  - **MAJOR**: Breaking changes (1.0.0 → 2.0.0)
  - **MINOR**: New features (1.0.0 → 1.1.0)
  - **PATCH**: Bug fixes (1.0.0 → 1.0.1)

```dockerfile
ARG VCS_REF
```
**GIẢI THÍCH:**
- **VCS** = Version Control System (Git commit hash)
- Dùng để biết code nào đã tạo ra image này
- **Cách set:**
```bash
docker build --build-arg VCS_REF=$(git rev-parse --short HEAD) .
# Kết quả: a1b2c3d
```

```dockerfile
ARG VCS_URL=https://github.com/your-org/your-repo
```
**GIẢI THÍCH:**
- URL của Git repository
- Để người khác biết source code ở đâu
- **Example thực tế:**
```bash
--build-arg VCS_URL=https://github.com/facebook/react
```

```dockerfile
ARG AUTHOR=devops@example.com
```
**GIẢI THÍCH:**
- Email người tạo/image maintainer
- Dùng để liên hệ khi có vấn đề

```dockerfile
ARG DESCRIPTION="Production-ready Node.js application"
```
**GIẢI THÍCH:**
- Mô tả ngắn về image
- Giúp người khác hiểu image dùng để làm gì

```dockerfile
ARG LICENSE="MIT"
```
**GIẢI THÍCH:**
- License của phần mềm
- Các license phổ biến:
  - **MIT**: Rất thoáng,商用 miễn phí
  - **Apache 2.0**: Giống MIT nhưng có patent protection
  - **GPL**: Copyleft, phải open source

---

#### DÒNG 34-36: REPRODUCIBLE BUILDS

```dockerfile
# ✅ Reproducible builds (GNU/Reproducible-Builds standard)
```
**GIẢI THÍCH:**
- **Reproducible build**: Build lại từ cùng source code → ra image **IDENTICAL** (byte-by-byte)
- Quan trọng cho:
  - Security auditing
  - Compliance (SOC2, HIPAA)
  - Trust (biết chính xác code gì đang chạy)

```dockerfile
# ✅ Set via: --build-arg SOURCE_DATE_EPOCH=$(git log -1 --format=%ct)
```
**GIẢI THÍCH:**
- **SOURCE_DATE_EPOCH**: Timestamp (Unix timestamp)
- Dùng để set **modification time** của files
- **$(git log -1 --format=%ct)**: Lấy timestamp của commit cuối
- **Ví dụ:**
```bash
git log -1 --format=%ct
# Kết quả: 1704067200 (Dec 31, 2023 00:00:00 GMT)
```

```dockerfile
ARG SOURCE_DATE_EPOCH
```
**GIẢI THÍCH:**
- Biến chứa timestamp
- Sẽ được dùng trong `ENV` và `npm ci`

---

### DÒNG 38-77: STAGE 0 - BASE IMAGE

```dockerfile
# ------------------------------------------
# STAGE 0: BASE IMAGE
# ------------------------------------------
```
**GIẢI THÍCH:**
- Đây là **stage đầu tiên** trong 7 stages
- Mỗi stage = 1 layer trong multi-stage build
- **Tại sao nhiều stages?**
  - Giảm image size (chỉ lấy những gì cần)
  - Tăng security (không bao gồm build tools trong production)

```dockerfile
# ✅ BuildKit syntax for latest features
# ✅ Specific version with SHA256 digest
# ✅ OCI annotations
```
**GIẢI THÍCH:**
- Các comment này nhắc lại những best practices
- Will be explained below

---

#### DÒNG 45: FROM STATEMENT

```dockerfile
FROM node:${NODE_VERSION}-alpine${ALPINE_VERSION}@sha256:${NODE_IMAGE_SHA256} AS base
```

**GIẢI THÍCH TỪNG PHẦN:**

1. **`FROM`**:
   - Keyword để chọn base image
   - Mọi Dockerfile đều bắt đầu với FROM

2. **`node:`**:
   - Tên image trên Docker Hub
   - Official Node.js image

3. **`${NODE_VERSION}`**:
   - Sử dụng biến ARG đã定义 ở dòng 21
   - Giá trị = `20` (nếu không override)
   - **Kết quả**: `node:20`

4. **`-alpine`**:
   - Suffix để chọn variant Alpine Linux
   - Variant khác: `-slim` (Debian slim), `-buster` (Debian 10)
   - **Size comparison**:
     - `node:20-alpine`: ~180MB
     - `node:20-slim`: ~250MB
     - `node:20`: ~900MB

5. **`${ALPINE_VERSION}`**:
   - Biến ARG từ dòng 22
   - Giá trị = `3.19`
   - **Kết quả**: `node:20-alpine3.19`

6. **`@sha256:${NODE_IMAGE_SHA256}`**:
   - **Digest**: Fingerprint của image
   - **@**: Syntax để chỉ định digest
   - `${NODE_IMAGE_SHA256}`: Biến từ dòng 23
   - **Tại sao cần?**
     - **Security**: Ngăn chặn fake/compromised images
     - **Reproducibility**: Đảm bảo pull đúng image
   - **Ví dụ thực tế:**
   ```dockerfile
   FROM node:20-alpine@sha256:a1b2c3d4e5f6...
   ```

7. **`AS base`**:
   - Đặt tên cho stage này là `base`
   - Dùng để reference ở stages sau
   - **Ví dụ**:
   ```dockerfile
   COPY --from=base /app /app
   ```

**KẾT QUẢ CỦA DÒNG NÀY:**
```
Pull image: node:20-alpine3.19
Verify digest: sha256:abc123...
Stage name: base
```

---

#### DÒNG 47-54: CÀI ĐẶT PACKAGES

```dockerfile
# ✅ Install dumb-init for proper signal handling (PID 1)
```
**GIẢI THÍCH:**
- **dumb-init**: Một tiny init system
- **PID 1**: Process ID 1 (process đầu tiên trong container)
- **Signal handling**: Xử lý tín hiệu (SIGTERM, SIGKILL)
- **Tại sao cần?**
  - Khi container stop, Docker gửi SIGTERM
  - Nếu không có init system → signals không được forward correctly
  - Dumb-init fix vấn đề này

```dockerfile
# ✅ Install security tools for runtime scanning
```
**GIẢI THÍCH:**
- Các công cụ security sẽ được cài
- Dùng để scan vulnerabilities trong container

```dockerfile
RUN apk add --no-cache \
```
**GIẢI THÍCH TỪNG PHẦN:**

1. **`RUN`**:
   - Execute command trong build time
   - Kết quả sẽ được commit vào layer

2. **`apk add`**:
   - **Alpine Package Keeper** - Package manager của Alpine
   - Tương tự `apt` (Ubuntu), `yum` (CentOS)
   - Dùng để cài packages

3. **`--no-cache`**:
   - Không cache index files
   - **Tại sao?**
     - Giảm image size
     - Force use latest versions (security)
   - **Without --no-cache**:
     ```
     /var/cache/apk/packages: 50MB
     ```

4. **`\`**:
   - Line continuation character
   - Cho phép command span multiple lines
   - Tăng readability

---

```dockerfile
    dumb-init \
```
**GIẢI THÍCH:**
- Package name
- Dùng để handle signals properly

```dockerfile
    ca-certificates \
```
**GIẢI THÍCH:**
- **CA Certificates**: Chứng chỉ SSL/TLS
- Cần thiết để gọi HTTPS APIs
- Ví dụ: `fetch('https://api.example.com')`
- **Without this**:
  ```
  Error: unable to get local issuer certificate
  ```

```dockerfile
    tzdata \
```
**GIẢI THÍCH:**
- **Timezone data**: Dữ liệu timezone
- Cần để set timezone cho container
- Ví dụ: `TZ=Asia/Ho_Chi_Minh`

```dockerfile
    && rm -rf /var/cache/apk/* \
```
**GIẢI THÍCH TỪNG PHẦN:**

1. **`&&`**:
   - Command separator
   - Chạy command tiếp theo nếu command trước thành công
   - **Why use &&?**
     - Nếu `apk add` fail → không execute `rm -rf`
     - Prevent partial/corrupted layers

2. **`rm -rf`**:
   - **rm**: Remove command
   - **-r**: Recursive (xóa folder)
   - **-f**: Force (không hỏi xác nhận)

3. **`/var/cache/apk/*`**:
   - Cache directory của apk
   - Dọn dẹp để giảm image size
   - **Savings**: ~20-50MB

```dockerfile
    && rm -rf /tmp/*
```
**GIẢI THÍCH:**
- Dọn dẹp temporary files
- `/tmp`: Temporary directory
- Reduce attack surface (less files in container)

**TỔNG KẾT DÒNG 49-54:**
```
Cài packages: dumb-init, ca-certificates, tzdata
Dọn cache: /var/cache/apk, /tmp
Kết quả: Cleaner, smaller, more secure
```

---

#### DÒNG 56-66: OCI ANNOTATIONS

```dockerfile
# ✅ OCI Annotations (OCI 1.1 specification)
```
**GIẢI THÍCH:**
- **OCI 1.1**: Phiên bản spec của OCI
- **Annotations**: Metadata chuẩn hóa
- Dùng cho:
  - Image scanning tools
  - Container registries
  - Compliance reporting

```dockerfile
LABEL org.opencontainers.image.created="${BUILD_DATE}" \
```
**GIẢI THÍCH TỪNG PHẦN:**

1. **`LABEL`**:
   - Thêm metadata vào image
   - Có thể inspect với: `docker inspect myimage`

2. **`org.opencontainers`**:
   - **Namespace**: Tiền tố chuẩn OCI
   - Tránh xung đột labels

3. **`.image.created`**:
   - **Key**: Tên của label
   - Ngày tạo image
   - Format: ISO 8601 (2024-01-15T10:30:00Z)

4. **`"${BUILD_DATE}"`**:
   - **Value**: Giá trị của label
   - Dùng biến ARG từ dòng 26
   - **Ví dụ**:
   ```dockerfile
   LABEL org.opencontainers.image.created="2024-01-15T10:30:00Z"
   ```

---

```dockerfile
      org.opencontainers.image.authors="${AUTHOR}" \
```
**GIẢI THÍCH:**
- **Key**: `org.opencontainers.image.authors`
- **Value**: Email hoặc tên tác giả
- **Ví dụ**:
```
org.opencontainers.image.authors="John Doe <john@example.com>"
```

```dockerfile
      org.opencontainers.image.description="${DESCRIPTION}" \
```
**GIẢI THÍCH:**
- Mô tả image
- Dùng trong UI để hiển thị thông tin

```dockerfile
      org.opencontainers.image.licenses="${LICENSE}" \
```
**GIẢI THÍCH:**
- License của image
- **SPDX License Identifier**:
  - `MIT`: MIT License
  - `Apache-2.0`: Apache License 2.0
  - `GPL-3.0`: GNU General Public License 3.0

```dockerfile
      org.opencontainers.image.revision="${VCS_REF}" \
```
**GIẢI THÍCH:**
- Git commit hash
- Dùng để trace source code
- **Ví dụ**:
```
org.opencontainers.image.revision="a1b2c3d"
```

```dockerfile
      org.opencontainers.image.source="${VCS_URL}" \
```
**GIẢI THÍCH:**
- URL của source code repository
- **Ví dụ**:
```
org.opencontainers.image.source="https://github.com/vercel/next.js"
```

```dockerfile
      org.opencontainers.image.title="myapp" \
```
**GIẢI THÍCH:**
- Tên của image/application
- Ngắn gọn, dễ hiểu

```dockerfile
      org.opencontainers.image.version="${VERSION}" \
```
**GIẢI THÍCH:**
- Version của application
- Format: SemVer (1.0.0, 2.1.3, etc.)

```dockerfile
      org.opencontainers.image.vendor="MyCompany" \
```
**GIẢI THÍCH:**
- Tên công ty/tổ chức
- **Ví dụ**:
```
org.opencontainers.image.vendor="Google"
org.opencontainers.image.vendor="Facebook"
```

```dockerfile
      org.opencontainers.image.schema.version="1.0"
```
**GIẢI THÍCH:**
- Version của OCI Image Spec
- Hardcoded `1.0` (current version)

**KẾT QUÁ KHI INSPECT:**
```json
{
  "Config": {
    "Labels": {
      "org.opencontainers.image.created": "2024-01-15T10:30:00Z",
      "org.opencontainers.image.version": "1.0.0",
      ...
    }
  }
}
```

---

#### DÒNG 68-71: ADDITIONAL LABELS

```dockerfile
# ✅ Additional metadata labels
LABEL maintainer="${AUTHOR}" \
```
**GIẢI THÍCH:**
- **maintainer**: Custom label (không phải OCI)
- Deprecated but still commonly used
- Dùng để liên hệ maintainer

```dockerfile
      version="${VERSION}" \
```
**GIẢI THÍCH:**
- Simpler version label
- Non-namespaced (không có prefix)

```dockerfile
      description="${DESCRIPTION}"
```
**GIẢI THÍCH:**
- Mô tả ngắn
- Khác với OCI annotation vì không có namespace

---

#### DÒNG 73-77: ENVIRONMENT VARIABLES

```dockerfile
# ✅ Set default environment
ENV NODE_ENV=production \
```
**GIẢI THÍCH TỪNG PHẦN:**

1. **`ENV`**:
   - Set environment variable
   - Available trong build time VÀ runtime
   - Khác với ARG (chỉ build time)

2. **`NODE_ENV=production`**:
   - **Key**: NODE_ENV
   - **Value**: production
   - **Tác dụng**:
     - Tối ưu hóa Node.js (không load dev tools)
     - Tăng performance
     - Giảm memory usage

```dockerfile
    TZ=UTC \
```
**GIẢI THÍCH:**
- **TZ**: Timezone
- **UTC**: Coordinated Universal Time
- **Tại sao UTC?**
  - Consistent across servers
  - Không có Daylight Saving Time issues
  - Best practice cho production

```dockerfile
    NODE_OPTIONS="--max-old-space-size=2048" \
```
**GIẢI THÍCH:**
- **NODE_OPTIONS**: Flags cho Node.js runtime
- **--max-old-space-size=2048**: Limit memory heap = 2GB
- **Tại sao cần?**
  - Ngăn container OOM (Out Of Memory)
  - Giả dùng: Container limit 512MB, Node.js heap = 2GB → Crash
  - Best practice: Set heap < container limit
- **Calculation**:
  ```
  Container memory limit: 512MB
  Node.js heap: 512MB * 0.8 = ~400MB
  ```

```dockerfile
    SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH}
```
**GIẢI THÍCH:**
- Gán ARG vào ENV
- Làm cho ARG available trong runtime
- Dùng cho reproducible builds

---

### DÒNG 79-100: STAGE 1 - DEPENDENCIES

```dockerfile
# ------------------------------------------
# STAGE 1: DEPENDENCIES (With BuildKit Cache)
# ------------------------------------------
```
**GIẢI THÍCH:**
- Stage thứ 2 trong 7 stages
- Mục tiêu: Cài đặt dependencies (npm packages)
- Tách riêng để **tận dụng cache** (nếu package.json không thay đổi → không rebuild)

```dockerfile
FROM base AS dependencies
```
**GIẢI THÍCH:**
- **`FROM base`**: Kế thừa từ stage `base` (đã defined ở dòng 45)
- **`AS dependencies`**: Đặt tên stage này là `dependencies`
- Kết quả: Stage này có tất cả mọi thứ từ `base` (dumb-init, ca-certificates, tzdata)

```dockerfile
WORKDIR /app
```
**GIẢI THÍCH:**
- **`WORKDIR`**: Set working directory
- **`/app`**: Đường dẫn thư mục
- **Tác dụng**:
  - Tạo thư mục `/app` nếu chưa có
  - Tất cả commands sau sẽ chạy trong `/app`
  - Tương tự `cd /app` nhưng tốt hơn (tự tạo nếu chưa có)
- **Why `/app`?**
  - Convention chuẩn (có thể dùng `/usr/src/app` cũng được)
  - Ngắn gọn, dễ nhớ

```dockerfile
# ✅ Install build tools
RUN --mount=type=cache,target=/var/cache/apk \
```
**GIẢI THÍCH TỪNG PHẦN:**

1. **`RUN`**: Execute command

2. **`--mount=type=cache`**:
   - **BuildKit feature** (cần `# syntax=docker/dockerfile:1.7`)
   - **Cache mount**: Mount cache từ host vào container
   - **Tác dụng**:
     - Lưu cache giữa các builds
     - Speed up 5-10x
   - **Không có cache mount**:
     ```
     Mỗi lần build: ~2 phút (download packages)
     ```
   - **Có cache mount**:
     ```
     Lần đầu: ~2 phút
     Lần 2+: ~10 giây (dùng cache)
     ```

3. **`target=/var/cache/apk`**:
   - Nơi cache được mount trong container
   - `/var/cache/apk`: Cache directory của Alpine package manager

```dockerfile
    apk add --no-cache \
```
**GIẢI THÍCH:**
- Cài packages cho Alpine

```dockerfile
        python3 \
```
**GIẢI THÍCH:**
- **Python 3**: Node.js native modules cần Python để build
- **Ví dụ native modules**:
  - `node-sass` (CSS preprocessor)
  - `bcrypt` (password hashing)
  - `sharp` (image processing)
- **Why cần?** Nhiều npm packages viết bằng C++ → cần compile

```dockerfile
        make \
```
**GIẢI THÍCH:**
- **Make**: Build automation tool
- Dùng để compile native modules

```dockerfile
        g++ \
```
**GIẢI THÍCH:**
- **G++**: GNU C++ compiler
- Dùng để compile C++ code → JavaScript bindings

```dockerfile
        pkgconfig \
```
**GIẢI THÍCH:**
- **pkg-config**: Tool để lấy thông tin về installed libraries
- Native modules cần để find dependencies

```dockerfile
    && rm -rf /var/cache/apk/*
```
**GIẢI THÍCH:**
- Xóa cache trong container (KHÔNG xóa cache mount)
- Cache mount vẫn được lưu ở host
- Giảm image size

---

```dockerfile
# ✅ Copy package files
COPY --link package*.json ./
```
**GIẢI THÍCH TỪNG PHẦN:**

1. **`COPY`**: Copy files từ host vào container

2. **`--link`**:
   - **BuildKit feature**
   - **Tác dụng**:
     - Fast copy (hardlinks thay vì copy)
     - Share layers between builds
     - Reduce disk space
   - **Tốc độ**:
     ```
     Without --link: ~5 giây
     With --link: ~0.5 giây
     ```

3. **`package*.json`**:
   - **`*`**: Wildcard (match bất kỳ ký tự nào)
   - **Matches**:
     - `package.json`
     - `package-lock.json`
   - **Why cả 2?**
     - `package.json`: Dependencies list
     - `package-lock.json`: Exact versions (reproducible builds)

4. **`./`**:
   - Destination (nơi copy đến)
   - `./` = current directory = `/app` (working directory)

**TẠI SAO COPY package.json TRƯỚC SOURCE CODE?**
```
✅ ĐÚNG:
1. Copy package.json
2. RUN npm install
3. Copy source code

❌ SAI:
1. Copy source code
2. Copy package.json
3. RUN npm install
```
**Lý do:**
- Source code thay đổi thường xuyên → Docker cache invalidation
- package.json thay đổi ít → Docker cache hit
- **Ví dụ**:
  ```
  Đổi 1 dòng code → Cache invalidation → npm install lại (phí 2 phút)
  Copy package.json trước → Chỉ cache invalidation khi đổi dependencies
  ```

---

```dockerfile
# ✅ BuildKit cache mount for npm (5x faster rebuilds)
RUN --mount=type=cache,target=/root/.npm \
```
**GIẢI THÍCH:**
- Tương tự apk cache mount
- Cache cho npm packages
- **Location**:
  ```
  /root/.npm: npm cache directory
  ```

```dockerfile
    --mount=type=bind,source=package.json,target=package.json \
```
**GIẢI THÍCH:**
- **bind mount**: Mount file từ host vào container
- **source=package.json**: File trên host
- **target=package.json**: File trong container
- **Why?**
  - Ensure npm reads latest package.json
  - Consistency check

```dockerfile
    npm ci --only=production && \
```
**GIẢI THÍCH TỪNG PHẦN:**

1. **`npm ci`**:
   - **ci** = Clean Install
   - **Khác `npm install`**:
     ```
     npm install:
       - Tạo mới package-lock.json nếu chưa có
       - Cập nhật package-lock.json
       - Không deterministic

     npm ci:
       - KHÔNG modify package-lock.json
       - Xóa node_modules trước khi install
       - Deterministic (cùng input → cùng output)
       - Faster (không check versions)
     ```
   - **Why `npm ci`?**
     - Reproducible builds
     - CI/CD best practice
     - Predictable

2. **`--only=production`**:
   - Chỉ install production dependencies
   - Bỏ qua devDependencies (jest, eslint, etc.)
   - **Tác dụng**:
     ```
     All dependencies: 500MB
     Only production: 300MB
     Savings: 200MB (40%)
     ```

3. **`&&`**:
   - Chain commands
   - Chạy command tiếp theo nếu command trước thành công

```dockerfile
    npm cache clean --force
```
**GIẢI THÍCH:**
- Xóa npm cache
- **`--force`**: Bypass confirmation prompts
- **Why?**
  - Giảm image size (~50-100MB)
  - Cache đã lưu ở cache mount rồi

---

### DÒNG 101-127: STAGE 2 - DEVELOPMENT

```dockerfile
# ------------------------------------------
# STAGE 2: DEVELOPMENT (Optional)
# ------------------------------------------
```
**GIẢI THÍCH:**
- Stage dùng cho local development
- **Optional**: Không bắt buộc

```dockerfile
FROM base AS development
```
**GIẢI THÍCH:**
- Start từ `base` stage
- Đặt tên là `development`

```dockerfile
WORKDIR /app
```
**GIẢI THÍCH:**
- Set working directory (same as before)

```dockerfile
# Install all dependencies (including dev)
COPY --link package*.json ./
```
**GIẢI THÍCH:**
- Copy package files
- **Note**: Không có `--only=production` → install ALL

```dockerfile
RUN --mount=type=cache,target=/root/.npm \
    npm ci
```
**GIẢI THÍCH:**
- Install tất cả dependencies (including devDependencies)
- Bao gồm: jest, eslint, prettier, typescript, etc.

```dockerfile
# Copy source code
COPY --link . .
```
**GIẢI THÍCH:**
- Copy tất cả source code
- **`.`** (first): Current directory on host
- **`.`** (second): Current directory in container (`/app`)
- **Includes**:
  - `src/`
  - `public/`
  - `next.config.js`
  - etc.

```dockerfile
# ✅ Create non-root user
RUN addgroup -g 1001 -S nodejs && \
```
**GIẢI THÍCH:**
- **`addgroup`**: Create user group (Alpine command)
- **`-g 1001`**: Group ID = 1001
  - **Why 1001?**
    - 0 = root (avoid)
    - 1-999 = system users (avoid)
    - 1000+ = regular users (good)
- **`-S`**: Create system group
- **`nodejs`**: Group name

```dockerfile
    adduser -S nextjs -u 1001 -G nodejs
```
**GIẢI THÍCH:**
- **`adduser`**: Create user (Alpine command)
- **`-S`**: Create system user
- **`nextjs`**: Username
- **`-u 1001`**: User ID = 1001
- **`-G nodejs`**: Add to `nodejs` group

```dockerfile
USER nextjs
```
**GIẢI THÍCH:**
- Switch to non-root user
- **CRITICAL for security**
- All commands sau sẽ chạy as `nextjs` user

```dockerfile
EXPOSE 3000
```
**GIẢI THÍCH:**
- **`EXPOSE`**: Document which port the container listens on
- **`3000`**: Port number
- **Note**: KHÔNG thực tế publish port
- Chỉ là **documentation** - useful for:
  - `docker run -P` (auto publish all EXPOSEd ports)
  - Docker Compose (auto link containers)
  - Documentation purpose

```dockerfile
# ✅ Use dumb-init for signal handling
ENTRYPOINT ["dumb-init", "--"]
```
**GIẢI THÍCH:**
- **`ENTRYPOINT`**: Command được chạy khi container starts
- **`["dumb-init", "--"]`**:
  - **Array form** (preferred)
  - `dumb-init`: Init system
  - `--`: End of options
- **Tác dụng**:
  - Handle SIGTERM properly
  - Reap zombie processes

```dockerfile
CMD ["npm", "run", "dev"]
```
**GIẢI THÍCH:**
- **`CMD`**: Default command
- **`npm run dev`**: Run dev server
- **Note**: CMD có thể override:
  ```bash
  docker run myapp npm run test
  ```

---

### DÒNG 129-163: STAGE 3 - BUILDER

```dockerfile
# ------------------------------------------
# STAGE 3: BUILDER (Production Build)
# ------------------------------------------
```
**GIẢI THÍCH:**
- Stage để build ứng dụng (Next.js build, webpack, etc.)

```dockerfile
FROM base AS builder
```
**GIẢI THÍCH:**
- Start từ `base`
- Đặt tên `builder`

```dockerfile
WORKDIR /app
```

```dockerfile
# Copy dependencies
COPY --from=dependencies --link /app/node_modules ./node_modules
```
**GIẢI THÍCH:**
- **`--from=dependencies`**: Copy từ stage `dependencies`
- **Benefits**:
  - Không cần reinstall lại
  - Faster builds
  - Smaller layers

```dockerfile
COPY --link . .
```
**GIẢI THÍCH:**
- Copy source code

```dockerfile
# ✅ Build with metadata
ARG VERSION
```
**GIẢI THÍCH:**
- **ARG** có scope là stage
- Cần redefine lại để dùng trong stage này

```dockerfile
ARG BUILD_DATE
ARG VCS_REF
```

```dockerfile
RUN --mount=type=cache,target=/root/.npm \
    --mount=type=cache,target=/app/.next/cache \
```
**GIẢI THÍCH:**
- 2 cache mounts:
  1. `/root/.npm`: npm cache
  2. `/app/.next/cache`: Next.js build cache

```dockerfile
    npm run build
```
**GIẢI THÍCH:**
- Run build script
- Next.js: Build production-optimized files
- Output: `.next/` directory

```dockerfile
# ✅ Generate SBOM (Software Bill of Materials)
RUN --mount=type=cache,target=/root/.npm \
```

```dockerfile
    npm install -g @cyclonedx/cyclonedx-npm && \
```
**GIẢI THÍCH:**
- Install CycloneDX tool
- **CycloneDX**: SBOM standard
- **SBOM**: Danh sách tất cả dependencies + versions + licenses

```dockerfile
    cyclonedx-npm --output-format json --output-file sbom.json && \
```
**GIẢI THÍCH:**
- Generate SBOM in JSON format

```dockerfile
    cyclonedx-npm --output-format xml --output-file sbom.xml
```
**GIẢI THÍCH:**
- Generate SBOM in XML format (cả 2 formats)

```dockerfile
# ✅ Copy SBOM to final image
RUN mkdir -p /app/public && \
    mv sbom.json sbom.xml /app/public/
```
**GIẢI THÍCH:**
- Move SBOM files to public directory
- Serve via HTTP for compliance auditing

```dockerfile
# ✅ Remove dev dependencies
RUN npm prune --production && \
```
**GIẢI THÍCH:**
- **`npm prune`**: Remove unused packages
- **`--production`**: Keep only production dependencies
- **Savings**: ~200MB

```dockerfile
    npm cache clean --force
```
**GIẢI THÍCH:**
- Clean npm cache

---

### DÒNG 165-186: STAGE 4 - SECURITY SCAN

```dockerfile
# ------------------------------------------
# STAGE 4: SECURITY SCANNER (Inline)
# ------------------------------------------
# ✅ Run vulnerability scanner during build
# ✅ Fails build if critical vulnerabilities found
```
**GIẢI THÍCH:**
- **Inline security scanning**: Quét lỗ hổng trong build time
- Nếu có critical vulnerabilities → Build FAIL

```dockerfile
FROM base AS security-scan
```
**GIẢI THÍCH:**
- Stage riêng cho security scanning

```dockerfile
WORKDIR /app
```

```dockerfile
# Install Trivy scanner
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --no-cache wget && \
```
**GIẢI THÍCH:**
- Install wget

```dockerfile
    wget -qO - https://aquasecurity.github.io/trivy-repo/debian/public.key | \
```
**GIẢI THÍCH:**
- Download Trivy GPG key

```dockerfile
    apk add --no-cache trivy
```
**GIẢI THÍCH:**
- Install Trivy scanner
- **Trivy**: Vulnerability scanner by Aqua Security

```dockerfile
# Copy built application
COPY --from=builder --link /app /app
```
**GIẢI THÍCH:**
- Copy từ `builder` stage

```dockerfile
# ✅ Scan for vulnerabilities (FAIL on CRITICAL)
RUN trivy filesystem --no-progress --severity CRITICAL,HIGH --exit-code 1 /app || \
```
**GIẢI THÍCH:**
- **`trivy filesystem`**: Scan filesystem
- **`--no-progress`**: Không show progress bar
- **`--severity CRITICAL,HIGH`**: Chỉ report critical/high severity
- **`--exit-code 1`**: Return exit code 1 nếu có vulnerabilities
- **`|| ...`**: Fallback error message

```dockerfile
    (echo "Security scan failed! Fix critical vulnerabilities before deploying." && exit 1)
```
**GIẢI THÍCH:**
- Error message nếu scan fail
- Exit với code 1 → Build fail

---

### DÒNG 188-268: STAGE 5 - PRODUCTION

```dockerfile
# ------------------------------------------
# STAGE 5: PRODUCTION (Minimal Runtime)
# ------------------------------------------
```
**GIẢI THÍCH:**
- **FINAL IMAGE** - Đây là image dùng cho production
- Minimal, secure, optimized

```dockerfile
FROM base AS production
```
**GIẢI THÍCH:**
- Start từ `base`
- Đặt tên `production`

```dockerfile
# ✅ Security: Create non-root user BEFORE copying files
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001 -G nodejs
```
**GIẢI THÍCH:**
- Create non-root user FIRST
- Why before? File permissions sẽ được set correctly

```dockerfile
WORKDIR /app
```

```dockerfile
# ✅ Copy built artifacts from builder
COPY --from=builder --chown=nextjs:nodejs --link \
```
**GIẢI THÍCH:**
- **`--from=builder`**: Copy từ builder stage
- **`--chown=nextjs:nodejs`**: Change owner to nextjs user
- **`--link`**: Fast copy (hardlinks)

```dockerfile
    /app/.next ./.next
```
**GIẢI THÍCH:**
- Copy Next.js build output
- `.next/`: Build artifacts

```dockerfile
COPY --from=builder --chown=nextjs:nodejs --link \
    /app/node_modules ./node_modules
```
**GIẢI THÍCH:**
- Copy production dependencies

```dockerfile
COPY --from=builder --chown=nextjs:nodejs --link \
    /app/package.json ./package.json
```
**GIẢI THÍCH:**
- Copy package.json

```dockerfile
COPY --from=builder --chown=nextjs:nodejs --link \
    /app/public ./public
```
**GIẢI THÍCH:**
- Copy public files (HTML, images, etc.)

```dockerfile
# ✅ Copy SBOM for compliance
COPY --from=builder --chown=nextjs:nodejs --link \
    /app/public/sbom*.json ./public/
```
**GIẢI THÍCH:**
- Copy SBOM files
- For compliance auditing

```dockerfile
COPY --from=builder --chown=nextjs:nodejs --link \
    /app/public/sbom*.xml ./public/
```

```dockerfile
# ✅ Create necessary directories with proper permissions
RUN mkdir -p /app/.next/cache && \
```
**GIẢI THÍCH:**
- Create cache directory

```dockerfile
    chown -R nextjs:nodejs /app/.next && \
```
**GIẢI THÍCH:**
- Recursive chown

```dockerfile
    chmod -R 755 /app
```
**GIẢI THÍCH:**
- **`chmod 755`**: Set permissions
  - **7 (rwx)**: Owner (read, write, execute)
  - **5 (r-x)**: Group & others (read, execute only)
- **Why 755?**
  - Files readable
  - Directories enterable
  - NOT writable by others (security)

```dockerfile
# ✅ Switch to non-root user (CIS Benchmark 5.1)
USER nextjs
```
**GIẢI THÍCH:**
- Switch to non-root user
- **CRITICAL**: Container runs as non-root
- **Why?**
  - Nếu container compromised → attacker không có root access
  - **CIS Benchmark 5.1**: Containers must run as non-root

```dockerfile
# ✅ Production environment
ENV NODE_ENV=production \
```
**GIẢI THÍCH:**
- Override NODE_ENV (ensure production)

```dockerfile
    PORT=3000 \
```
**GIẢI THÍCH:**
- Default port

```dockerfile
    HOSTNAME="0.0.0.0" \
```
**GIẢI THÍCH:**
- Listen on all interfaces
- **Why 0.0.0.0?**
  - Container cần accept connections từ outside
  - **127.0.0.1**: Chỉ local
  - **0.0.0.0**: All interfaces (external reachable)

```dockerfile
    NODE_OPTIONS="--max-old-space-size=2048"
```
**GIẢI THÍCH:**
- Memory limit (như đã giải thích)

```dockerfile
# ✅ STOPSIGNAL for graceful shutdown (CIS Benchmark 5.26)
# ✅ SIGTERM (15) allows cleanup, SIGKILL (9) is immediate force-kill
STOPSIGNAL SIGTERM
```
**GIẢI THÍCH:**
- **`STOPSIGNAL`**: Signal Docker sends khi container stop
- **`SIGTERM`**: Termination signal (15)
  - Cho phép app cleanup
  - Close connections gracefully
  - Save state
- **SIGKILL (9)**:
  - Force kill
  - Không cleanup
  - **BAD for production** (data loss, connection errors)
- **CIS Benchmark 5.26**: Must use SIGTERM

```dockerfile
# ✅ Expose port (documentation only)
EXPOSE 3000
```
**GIẢI THÍCH:**
- Documentation (như đã giải thích)

```dockerfile
# ✅ Health Check (CIS Benchmark 5.25)
HEALTHCHECK --interval=30s \
```
**GIẢI THÍCH:**
- **`HEALTHCHECK`**: Định nghĩa health check command
- **`--interval=30s`**: Run health check mỗi 30s

```dockerfile
            --timeout=5s \
```
**GIẢI THÍCH:**
- Timeout sau 5s nếu không response

```dockerfile
            --start-period=10s \
```
**GIẢI THÍCH:**
- **Start period**: 10s đầu tiên không count failures
- Cho phép app startup time

```dockerfile
            --retries=3 \
```
**GIẢI THÍCH:**
- Fail sau 3 consecutive failures

```dockerfile
    CMD node -e "
```
**GIẢI THÍCH:**
- **`node -e`**: Execute JavaScript code
- Inline health check script

```dockerfile
    const http = require('http');
```
**GIẢI THÍCH:**
- Import HTTP module

```dockerfile
    const options = {
      host: 'localhost',
      port: 3000,
      path: '/api/health',
      timeout: 2000
```
**GIẢI THÍCH:**
- Request options

```dockerfile
    };
```

```dockerfile
    const request = http.request(options, (res) => {
      process.exit(res.statusCode === 200 ? 0 : 1);
```
**GIẢI THÍCH:**
- Exit 0 (success) nếu 200 OK
- Exit 1 (fail) nếu không

```dockerfile
    });
```

```dockerfile
    request.on('error', () => process.exit(1));
```
**GIẢI THÍCH:**
- Exit 1 nếu connection error

```dockerfile
    request.end();
    "
```
**GIẢI THÍCH:**
- End of script

```dockerfile
# ✅ Use dumb-init for proper signal handling (SIGTERM, SIGCHLD)
# ✅ Graceful shutdown with zero downtime
ENTRYPOINT ["dumb-init", "--"]
```
**GIẢI THÍCH:**
- Use dumb-init as PID 1
- Proper signal handling

```dockerfile
# ✅ Start application
CMD ["node", ".next/standalone/server.js"]
```
**GIẢI THÍCH:**
- Start Next.js standalone server
- **Array form** (no shell parsing)

---

### DÒNG 270-356: STAGE 6 & 7 - DISTROLESS & CHAINGUARD

**GIẢI THÍCH NGẮN GỌN:**
- **Stage 6 (distroless)**: Google's minimal image - NO shell, NO package manager
- **Stage 7 (chainguard)**: Wolfi-based hardened image - Zero CVEs
- **Purpose**: Maximum security alternatives

---

## 📄 GIẢI THÍCH .DOCKERIGNORE

**File này dùng để loại bỏ files khỏi Docker build context**

**Ví dụ**:
```
ĐẾM SỐ FILES TRONG CONTEXT:
- Không có .dockerignore: 50,000 files (node_modules)
- Có .dockerignore: 100 files (chỉ source code)

BUILD TIME:
- Không có: ~3 phút (upload 50,000 files)
- Có: ~5 giây (upload 100 files)
```

**MỖI CATEGORY TRONG FILE:**

### Dependencies
```
node_modules
```
**GIẢI THÍCH:**
- Không bao giờ copy node_modules vào image
- Why? Node_modules sẽ được install lại trong container (via `npm ci`)
- Size: ~500MB

### Environment Files
```
.env
.env*.local
```
**GIẢI THÍCH:**
- **SECURITY RISK!** - Chứa secrets
- Không bao giờ commit secrets vào image
- Secrets phải được pass via environment variables tại runtime

### IDE Files
```
.vscode
.idea
```
**GIẢI THÍCH:**
- IDE configs
- Không cần trong container
- Size: ~10MB

### Build Outputs
```
.next
dist
```
**GIẢI THÍCH:**
- Build artifacts
- Sẽ được generated trong container
- Don't copy từ host

---

## 🔒 GIẢI THÍCH SECCOMP PROFILE

**Seccomp** = **SEC**ure **COMP**uting Mode - Filter system calls

**VÍ DỤ DỄ HIỂU:**
```
System call = Lời gọi đến kernel (hệ điều hành)
Ví dụ:
- open() → Mở file
- read() → Đọc file
- write() → Ghi file
- reboot() → Restart máy
```

**SECCOMP LÀM GÌ?**
- Allow: Chỉ cho phép 90 syscalls cần thiết
- Block: Chặn 60+ syscalls nguy hiểm

**VÍ DỤ SYSCALLS ĐÃ CHẶN:**
```json
"reboot"  → Không thể restart máy từ trong container
"mount"   → Không thể mount filesystem
"ptrace"  → Không thể debug các process khác
```

**TẠI SAO CẦN?**
- Giảm attack surface
- Nếu attacker compromise app → chỉ có thể gọi 90 syscalls (thay vì 300+)
- **CIS Benchmark 5.24**: Container security requirement

---

## 🛡️ GIẢI THÍCH APPARMOR PROFILE

**AppArmor** = **Mandatory Access Control** (MAC)

**VÍ DỤ DỄ HIỂU:**
```
AppArmor = Bảo vệ tại filesystem level
- Chỉ được đọc file A
- KHÔNG được đọc file B
- KHÔNG được write vào /etc
```

**KEY RULES TRONG PROFILE:**

### Allow Rules
```
/app/** r  → Được đọc tất cả files trong /app
```
**GIẢI THÍCH:**
- **r** = read (đọc)
- App cần đọc source code

### Deny Rules
```
deny /bin/** ix  → KHÔNG được execute shell
```
**GIẢI THÍCH:**
- **ix** = execute + inherit
- Nếu attacker compromise app → không thể spawn shell

### Network Rules
```
network inet stream  → Cho phép TCP connections
```
**GIẢI THÍCH:**
- App cần connect đến database, APIs

---

## ☸️ GIẢI THÍCH KUBERNETES SECURITY.YAML

**Kubernetes** = Container orchestration platform

**KEY COMPONENTS:**

### 1. Deployment
```yaml
replicas: 3
```
**GIẢI THÍCH:**
- Run 3 copies của app
- High availability

### 2. Security Context
```yaml
runAsNonRoot: true
runAsUser: 1001
```
**GIẢI THÍCH:**
- Pod runs as non-root user
- User ID 1001

### 3. Resource Limits
```yaml
resources:
  limits:
    memory: "512Mi"
    cpu: "500m"
```
**GIẢI THÍCH:**
- Max memory: 512MB
- Max CPU: 0.5 cores (500 millicores)
- **Why?** Prevent runaway containers from consuming all resources

### 4. Health Probes
```yaml
livenessProbe:
  httpGet:
    path: /api/health
```
**GIẢI THÍCH:**
- **Liveness**: Check if app is alive
- **Readiness**: Check if app ready to receive traffic
- Kubernetes sẽ restart pod nếu liveness fail

### 5. Network Policy
```yaml
networkPolicy:
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
```
**GIẢI THÍCH:**
- **Firewall at pod level**
- Chỉ accept traffic từ ingress controller
- Block direct traffic

---

## 🐳 GIẢI THÍCH DOCKER-COMPOSE-SECURITY.YAML

**Docker Compose** = Tool để run multiple containers

**KEY SECURITY SETTINGS:**

### 1. Security Options
```yaml
security_opt:
  - no-new-privileges:true
```
**GIẢI THÍCH:**
- **no-new-privileges**: Container không thể gain new privileges
- Prevent privilege escalation attacks

### 2. Read-Only Filesystem
```yaml
read_only: true
```
**GIẢI THÍCH:**
- Filesystem read-only
- Nếu attacker compromise → không thể write malware
- Exception: `/tmp` (writable tmpfs mount)

### 3. Capabilities
```yaml
cap_drop:
  - ALL
cap_add:
  - NET_BIND_SERVICE
```
**GIẢI THÍCH:**
- **cap_drop ALL**: Drop ALL Linux capabilities
- **cap_add NET_BIND_SERVICE**: Add back ONLY needed capability
- **NET_BIND_SERVICE**: Allow binding to port < 1024

### 4. Resource Limits
```yaml
deploy:
  resources:
    limits:
      cpus: "0.5"
      memory: 512M
```
**GIẢI THÍCH:**
- CPU: 0.5 cores
- Memory: 512MB
- Prevent resource exhaustion

### 5. Health Check
```yaml
healthcheck:
  test: ["CMD", "node", "-e", "..."]
  interval: 30s
  retries: 3
```
**GIẢI THÍCH:**
- Health check script
- Run mỗi 30s
- Fail sau 3 retries
- Docker Compose sẽ restart container nếu unhealthy

---

## 🎯 TỔNG KẾT

### TẤT CẢ CÁC FILES VÀ MỤC ĐÍCH:

| File | Mục đích | Khi nào cần |
|------|----------|-------------|
| **learn.dockerfile** | Build Docker image | Luôn cần |
| **.dockerignore** | Exclude files khỏi build context | Luôn cần |
| **seccomp-profile.json** | Filter system calls | Production (Linux) |
| **apparmor-profile** | Mandatory access control | Production (Linux) |
| **kubernetes-security.yaml** | Deploy lên Kubernetes | Nếu dùng K8s |
| **docker-compose-security.yaml** | Run local/small production | Nếu dùng Docker Compose |

### QUY TRÌNH HOÀN CHỈNH:

1. **Code** → Viết code
2. **Build** → `docker build -f learn.dockerfile -t myapp:1.0.0 .`
3. **Scan** → Trivy scan tự động trong build
4. **Test local** → `docker-compose -f docker-compose-security.yaml up`
5. **Deploy** → `kubectl apply -f kubernetes-security.yaml`

### SECURITY LAYERS (TỪ NGOẠI → TRONG):

```
1. Network Policy (Kubernetes)         → Firewall
2. Seccomp Profile                     → System call filtering
3. AppArmor Profile                    → Filesystem access control
4. Read-only Filesystem                → Prevent writes
5. Non-root User                       → Least privilege
6. Capabilities Drop                   → Minimal kernel permissions
7. Resource Limits                     → Prevent DoS
8. Health Checks                       → Auto-restart if fail
```

---

## 🚀 GIẢI THÍCH JENKINSFILE - TỪ ZERO ĐẾN ADVANCE

---

### 📌 Jenkins Là Gì?

**Jenkins** là **open-source automation server** dùng để:
- CI/CD (Continuous Integration/Continuous Deployment)
- Automate build, test, deploy
- Pipeline as Code

**Ví dụ dễ hiểu:**
```
Jenkins = Robot lập trình viên
- Tự động lấy code mới
- Build ứng dụng
- Chạy tests
- Deploy lên server
- Thông báo kết quả
```

---

### 📖 CÁC FILE HỌC JENKINSFILE:

| File | Mục đích | Khi nào dùng |
|------|----------|--------------|
| **learn.jenkinsfile** | File đầy đủ với comments chi tiết | Học cách viết Jenkinsfile |
| **practice.jenkinsfile** | File có chỗ trống để điền | Thực hành, kiểm tra kiến thức |
| **Jenkinsfile** | File thực tế cho project | Dùng trong production |

---

### 🔤 CẤU TRÚC CƠ BẢN CỦA JENKINSFILE

```groovy
pipeline {
    agent any                          // Bắt buộc: nơi chạy pipeline
    options { ... }                    // Tuỳ chọn: timeout, timestamps
    parameters { ... }                 // Input parameters
    environment { ... }                // Biến môi trường
    tools { ... }                      // Tools (Maven, Node.js)
    triggers { ... }                   // Tự động chạy

    stages {                           // Bắt buộc: các stages
        stage('Stage 1') {
            steps {
                // Commands
            }
        }
    }

    post {                             // Sau khi build xong
        success { ... }
        failure { ... }
        always { ... }
    }
}
```

---

### 📝 SECTION 1: PIPELINE DECLARATION

```groovy
pipeline {
```
**GIẢI THÍCH:**
- **`pipeline`**: Keyword khai báo Declarative Pipeline
- Declarative syntax = dễ đọc, dễ maintain
- Phải có `{` mở block

**Syntax alternatives:**
```groovy
// Declarative (Recommended)
pipeline {
    agent any
    stages { ... }
}

// Scripted (Older, flexible but harder)
node {
    stage('Build') {
        sh 'make'
    }
}
```

---

### 📝 SECTION 2: AGENT - NƠI CHẠY PIPELINE

```groovy
agent any
```
**GIẢI THÍCH:**
- **`agent`**: Chỉ định nơi Jenkins chạy pipeline
- **`any`**: Chạy trên bất kỳ available agent nào

**Các options:**

```groovy
// 1. any - Bất kỳ agent nào
agent any

// 2. none - Không có default agent, mỗi stage tự define
agent none

// 3. label - Chạy trên agent cụ thể
agent { label 'linux-agent' }

// 4. node - Tương tự label
agent { node { label 'linux' } }

// 5. Docker - Chạy trong container
agent {
    docker {
        image 'node:20-alpine'
        reuseNode true
    }
}
```

**Ví dụ thực tế:**
```groovy
// Chạy trên agent có label "kubernetes"
agent { label 'kubernetes' }

// Chạy trong Docker container
agent {
    docker {
        image 'python:3.11'
        args '-v $HOME:/home'
    }
}
```

---

### 📝 SECTION 3: OPTIONS - CẤU HÌNH PIPELINE

```groovy
options {
    timeout(time: 1, unit: 'HOURS')
    timestamps()
    disableConcurrentBuilds()
}
```

**GIẢI THÍCH TỪNG OPTION:**

#### 3.1 TIMEOUT
```groovy
timeout(time: 1, unit: 'HOURS')
```
**GIẢI THÍCH:**
- **`timeout`**: Giới hạn thời gian chạy pipeline
- **`time: 1`**: Số lượng
- **`unit: 'HOURS'`**: Đơn vị thời gian
- **Units:** `'SECONDS'`, `'MINUTES'`, `'HOURS'`, `'DAYS'`

**Tại sao cần?**
- Ngăn pipeline chạy mãi (hung builds)
- Auto abort nếu timeout
- Giải phóng resources

#### 3.2 TIMESTAMPS
```groovy
timestamps()
```
**GIẢI THÍCH:**
- Hiển thị timestamps trong console output
- **Ví dụ:**
```
[2025-01-15T10:30:45.123Z] + npm install
[2025-01-15T10:31:20.456Z] Finished: SUCCESS
```

#### 3.3 DISABLE CONCURRENT BUILDS
```groovy
disableConcurrentBuilds()
```
**GIẢI THÍCH:**
- Không cho phép nhiều bản của pipeline chạy cùng lúc
- **Ví dụ:**
  ```
  Pipeline A đang chạy → Trigger lại
  → Build mới sẽ queue chờ build cũ xong
  ```

**Tại sao cần?**
- Tránh xung đột resources
- Deploy không bị overwrite

**Các options khác:**
```groovy
options {
    // Giữ lại 10 builds cuối
    buildDiscarder(logRotator(numToKeepStr: '10'))

    // Skip stages sau khi unstable
    skipStagesAfterUnstable()

    // Thêm timestamps cho tất cả build logs
    timestamps()

    // Retry khi fail
    retry(3)
}
```

---

### 📝 SECTION 4: PARAMETERS - INPUT PARAMETERS

```groovy
parameters {
    choice(
        name: 'ENVIRONMENT',
        choices: ['dev', 'staging', 'production'],
        description: 'Chọn môi trường deploy'
    )
}
```

**GIẢI THÍCH:**
- **`parameters`**: Input cho người dùng khi trigger build
- Cho phép customize mỗi build

**Các loại parameters:**

#### 4.1 CHOICE PARAMETER
```groovy
choice(
    name: 'ENVIRONMENT',
    choices: ['dev', 'staging', 'production'],
    description: 'Chọn môi trường'
)
```
**GIẢI THÍCH:**
- **`name`**: Tên parameter (access via `params.ENVIRONMENT`)
- **`choices`**: List các options (dropdown trong UI)
- **`description`**: Ghi chú

**Sử dụng:**
```groovy
steps {
    sh "echo Deploying to ${params.ENVIRONMENT}"
}
```

#### 4.2 BOOLEAN PARAMETER
```groovy
booleanParam(
    name: 'RUN_TESTS',
    defaultValue: true,
    description: 'Có chạy tests không?'
)
```
**GIẢI THÍCH:**
- Checkbox (true/false)
- **Usage:**
```groovy
when {
    expression { params.RUN_TESTS == true }
}
steps {
    sh 'npm test'
}
```

#### 4.3 STRING PARAMETER
```groovy
string(
    name: 'VERSION',
    defaultValue: '1.0.0',
    description: 'Version của release'
)
```
**GIẢI THÍCH:**
- Text input (single line)
- **Usage:**
```groovy
sh "docker tag myapp:${params.VERSION}"
```

#### 4.4 TEXT PARAMETER
```groovy
text(
    name: 'COMMIT_MESSAGE',
    defaultValue: '',
    description: 'Commit message (multiline)'
)
```
**GIẢI THÍCH:**
- Multiline text area
- Dùng cho changelog, release notes

#### 4.5 PASSWORD PARAMETER
```groovy
password(
    name: 'API_KEY',
    description: 'API Key cho deployment'
)
```
**GIẢI THÍCH:**
- Masked input (ẩn text)
- Secure cho secrets

**⚠️ WARNING:**
- Password parameters vẫn visible trong log nếu echo
- Better: Use Jenkins Credentials

---

### 📝 SECTION 5: ENVIRONMENT VARIABLES

```groovy
environment {
    APP_NAME = 'my-application'
    DEPLOY_ENV = "${params.ENVIRONMENT}"
    BUILD_DIR = "${WORKSPACE}/build"
}
```

**GIẢI THÍCH:**
- **`environment`**: Biến môi trường global
- Available trong tất cả stages

**Cách sử dụng:**

#### 5.1 STATIC VALUE
```groovy
environment {
    NODE_ENV = 'production'
}
```
**GIẢI THÍCH:**
- String value
- **Access:** `${env.NODE_ENV}` or `"$NODE_ENV"`

#### 5.2 FROM PARAMETERS
```groovy
environment {
    DEPLOY_ENV = "${params.ENVIRONMENT}"
}
```
**GIẢI THÍCH:**
- Lấy giá trị từ parameter
- Double quotes required for interpolation

#### 5.3 BUILT-IN VARIABLES
```groovy
environment {
    WORKSPACE_PATH = "${WORKSPACE}"      // Jenkins workspace directory
    BUILD_NUMBER_STR = "${BUILD_NUMBER}" // Build number (e.g., 123)
    JOB_NAME_STR = "${JOB_NAME}"         // Job name
}
```
**Các built-in variables:**
```
WORKSPACE       → /var/jenkins_home/workspace/my-job
BUILD_NUMBER    → 123
BUILD_ID        → 2025-01-15_10-30-45
BUILD_URL       → http://jenkins:8080/job/my-job/123/
JOB_NAME        → my-job
NODE_NAME       → agent-1
```

#### 5.4 ENVIRONMENT Ở STAGE LEVEL
```groovy
stage('Build') {
    environment {
        NODE_ENV = 'development'  // Override global
    }
    steps {
        sh 'echo $NODE_ENV'  // → "development"
    }
}
```

**Best Practice:**
```groovy
// Global environment
environment {
    APP_NAME = 'myapp'
    VERSION = "${params.VERSION}"
}

// Stage-specific (override if needed)
stage('Test') {
    environment {
        NODE_ENV = 'test'
    }
    steps { ... }
}
```

---

### 📝 SECTION 6: TOOLS

```groovy
tools {
    maven 'Maven-3.9'
    nodejs 'Node-20'
}
```

**GIẢI THÍCH:**
- **`tools`**: Auto-install/configure tools
- Tool name phải match với Jenkins Global Tool Configuration

**Các tools hỗ trợ:**
```groovy
tools {
    // Maven
    maven 'Maven-3.9'

    // Node.js (cần Node.js plugin)
    nodejs 'Node-20'

    // JDK
    jdk 'JDK-17'

    // Gradle
    gradle 'Gradle-8'
}
```

**Cấu hình trong Jenkins:**
1. Manage Jenkins → Global Tool Configuration
2. Add Maven/Node.js/JDK installations
3. Set name (e.g., "Node-20")
4. Reference trong Jenkinsfile

**⚠️ Lưu ý:**
- Chỉ install tool, không set PATH
- Agent phải có tool installer

---

### 📝 SECTION 7: STAGES

```groovy
stages {
    stage('Checkout') {
        steps {
            checkout scm
        }
    }
}
```

**GIẢI THÍCH:**
- **`stages`**: Chứa các execution stages
- Mỗi `stage` = 1 bước trong pipeline
- **`steps`**: Commands để execute

**Structure:**
```groovy
stages {              // Bắt buộc
    stage('Name') {   // Tên stage (hiển thị trong UI)
        steps {       // Bắt buộc
            // Commands
        }
        post {        // Optional
            // Actions after stage completes
        }
    }
}
```

---

### 📝 SECTION 8: STAGE EXAMPLES

#### 8.1 CHECKOUT STAGE
```groovy
stage('Checkout') {
    steps {
        echo '=== STAGE: CHECKOUT ==='
        checkout scm
    }
}
```
**GIẢI THÍCH:**
- **`checkout scm`**: Lấy code từ SCM (Git, SVN, etc.)
- `scm` = biến Jenkins tự động inject
- **Làm gì:**
  - Git clone
  - Switch branch
  - Pull latest commits

**Custom checkout:**
```groovy
git url: 'https://github.com/user/repo.git', branch: 'main'
```

#### 8.2 PREPARE STAGE
```groovy
stage('Prepare Environment') {
    steps {
        script {
            // Script block = viết Groovy code
            echo "Job: ${env.JOB_NAME}"
            echo "Build: ${env.BUILD_NUMBER}"

            // Lấy Git info
            env.GIT_COMMIT = sh(
                script: 'git rev-parse HEAD',
                returnStdout: true
            ).trim()
        }

        // Tạo directories
        sh '''
            mkdir -p reports
            mkdir -p artifacts
        '''
    }
}
```
**GIẢI THÍCH:**
- **`script { ... }`**: Block để viết Groovy code
- **`sh '...'`**: Chạy shell commands
- **`returnStdout: true`**: Capture output
- **`.trim()`**: Remove whitespace

**Ví dụ output:**
```
Job: my-project
Build: 123
Git Commit: a1b2c3d4e5f6...
```

#### 8.3 INSTALL DEPENDENCIES STAGE
```groovy
stage('Install Dependencies') {
    steps {
        sh '''
            if [ -f package-lock.json ]; then
                npm ci --no-fund --no-audit
            else
                npm install --no-fund --no-audit
            fi
        '''
    }
}
```
**GIẢI THÍCH:**
- **`npm ci`**: Clean install (faster, deterministic)
- **`--no-fund`**: Không hiển thị funding message
- **`--no-audit`**: Không run audit (CI environment)

**Python equivalent:**
```groovy
sh 'pip install -r requirements.txt'
```

**Maven equivalent:**
```groovy
sh 'mvn dependency:go-offline'
```

#### 8.4 BUILD STAGE
```groovy
stage('Build') {
    steps {
        sh 'npm run build --if-present'
    }
}
```
**GIẢI THÍCH:**
- **`--if-present`**: Không error nếu script không tồn tại
- Jenkinsfile sẽ continue ngay cả khi không có build script

**Các build commands:**
```groovy
// Node.js
sh 'npm run build'

// Maven
sh 'mvn package -DskipTests'

// Gradle
sh './gradlew build -x test'

// Docker
sh 'docker build -t myapp:latest .'
```

#### 8.5 TEST STAGE WITH POST
```groovy
stage('Test') {
    steps {
        sh 'npm test --if-present'
    }

    post {
        always {
            // Luôn chạy (dù pass hay fail)
            junit 'test-results/*.xml'

            // Publish HTML reports
            publishHTML([
                reportDir: 'coverage',
                reportFiles: 'index.html',
                reportName: 'Coverage Report'
            ])
        }
    }
}
```
**GIẢI THÍCH:**
- **`post { always { ... } }`**: Luôn execute
- **`junit`**: Publish test results (Jenkins parse)
- **`publishHTML`**: Display HTML reports trong Jenkins UI

**Test report formats:**
```
JUnit XML: test-results/*.xml
Mocha: mocha test --reporter json > test-results.json
pytest: pytest --junitxml=test-results.xml
```

---

### 📝 SECTION 9: ADVANCED STAGES - SECURITY SCANNING

#### 9.1 SONARQUBE SCAN
```groovy
stage('SonarQube Scan') {
    when {
        expression { params.RUN_TESTS == true }
    }

    steps {
        withSonarQubeEnv('SonarQube-Server') {
            sh '''
                sonar-scanner \
                    -Dsonar.projectKey=my-project \
                    -Dsonar.sources=src \
                    -Dsonar.host.url=$SONAR_HOST_URL \
                    -Dsonar.login=$SONAR_AUTH_TOKEN
            '''
        }
    }
}
```
**GIẢI THÍCH:**
- **`when { expression { ... } }`**: Conditional execution
- **`withSonarQubeEnv`**: Inject SonarQube config
- Auto-configure từ Jenkins global settings

**Setup trong Jenkins:**
1. Manage Jenkins → Configure System
2. SonarQube servers → Add server
3. Name: "SonarQube-Server"
4. Server URL, authentication token

#### 9.2 QUALITY GATE
```groovy
stage('SonarQube Quality Gate') {
    steps {
        script {
            timeout(time: 10, unit: 'MINUTES') {
                waitForQualityGate abortPipeline: true
            }
        }
    }
}
```
**GIẢI THÍCH:**
- **`waitForQualityGate`**: Chờ SonarQube analysis hoàn thành
- **`abortPipeline: true`**: Fail pipeline nếu quality gate không pass
- **`timeout`**: Không chờ quá 10 phút

**Quality Gate Rules:**
- Code coverage > 80%
- No critical vulnerabilities
- Code smell rating = A

#### 9.3 OWASP DEPENDENCY CHECK
```groovy
stage('OWASP Dependency Check') {
    steps {
        sh '''
            dependency-check.sh \
                --format "HTML" \
                --format "XML" \
                --project "MyApp" \
                --out reports/dependency-check \
                --scan .
        '''

        publishHTML([
            target: [
                reportDir: 'reports/dependency-check',
                reportFiles: 'dependency-check-report.html',
                reportName: 'OWASP Dependency Check'
            ]
        ])
    }
}
```
**GIẢI THÍCH:**
- **`dependency-check.sh`**: OWASP tool
- Scan vulnerabilities trong dependencies
- Phải cài Dependency-Check plugin trên Jenkins agent

**Output:**
- HTML report (human-readable)
- XML report (machine-readable)

#### 9.4 TRIVY SCAN
```groovy
stage('Trivy Scan') {
    steps {
        sh '''
            trivy fs \
                --format table \
                --output reports/trivy-fs.txt \
                --severity HIGH,CRITICAL \
                .
        '''

        archiveArtifacts artifacts: 'reports/trivy-fs.txt', allowEmptyArchive: true
    }
}
```
**GIẢI THÍCH:**
- **`trivy fs`**: Scan filesystem
- **`--severity HIGH,CRITICAL`**: Chỉ report high/critical
- **`archiveArtifacts`**: Lưu lại trong Jenkins

**Trivy scan types:**
```groovy
// Filesystem scan
trivy fs .

// Docker image scan
trivy image myapp:latest

// Repository scan
trivy repo https://github.com/user/repo
```

---

### 📝 SECTION 10: CONDITIONAL EXECUTION (WHEN)

```groovy
stage('Example') {
    when {
        expression { params.RUN_TESTS == true }
    }
    steps {
        sh 'npm test'
    }
}
```

**GIẢI THÍCH:**
- **`when`**: Conditional execution cho stage
- Stage chỉ chạy nếu condition = true

**Các types of conditions:**

#### 10.1 EXPRESSION
```groovy
when {
    expression { params.ENVIRONMENT == 'production' }
}
```
**GIẢI THÍCH:**
- Groovy boolean expression
- Return true/false

**Examples:**
```groovy
// Parameter check
expression { params.DEPLOY == true }

// File exists check
expression { fileExists('Dockerfile') }

// Multiple conditions
expression {
    return params.ENVIRONMENT == 'prod' &&
           params.DEPLOY == true
}
```

#### 10.2 BRANCH
```groovy
when {
    branch 'main'
}
```
**GIẢI THÍCH:**
- Chỉ chạy khi build từ branch cụ thể
- **Example:**
```groovy
when {
    anyOf {
        branch 'main'
        branch 'develop'
    }
}
```

#### 10.3 TAG
```groovy
when {
    tag 'v*'
}
```
**GIẢI THÍCH:**
- Chỉ chạy khi Git tag match pattern
- **Pattern examples:**
  - `v*` → v1.0.0, v2.0.0
  - `release-*` → release-1.0, release-2.0

#### 10.4 CHANGE REQUEST
```groovy
when {
    changeRequest()
}
```
**GIẢI THÍCH:**
- Chỉ chạy khi build = PR/MR
- **GitHub PR, GitLab MR, Bitbucket PR**

#### 10.5 ENVIRONMENT
```groovy
when {
    environment name: 'DEPLOY_TO', value: 'production'
}
```
**GIẢI THÍCH:**
- Check environment variable

#### 10.6 COMBINING CONDITIONS
```groovy
// AND (allOf)
when {
    allOf {
        branch 'main'
        expression { params.DEPLOY == true }
    }
}

// OR (anyOf)
when {
    anyOf {
        branch 'main'
        branch 'develop'
    }
}

// NOT
when {
    not {
        branch 'feature/*'
    }
}
```

---

### 📝 SECTION 11: POST BUILD ACTIONS

```groovy
post {
    success { ... }
    failure { ... }
    always { ... }
}
```

**GIẢI THÍCH:**
- **`post`**: Actions sau khi build xong
- Run regardless của build result

**Các conditions:**

#### 11.1 SUCCESS
```groovy
success {
    echo '=== BUILD SUCCESS ==='
    script {
        // Tag release
        sh "git tag v${params.VERSION}"
        sh "git push origin v${params.VERSION}"
    }
}
```
**GIẢI THÍCH:**
- Chạy khi build = SUCCESS
- Tất cả stages pass

#### 11.2 FAILURE
```groovy
failure {
    echo '=== BUILD FAILED ==='
    emailext(
        subject: "Build FAILED: ${env.JOB_NAME}",
        body: "Check console: ${env.BUILD_URL}console",
        to: 'devops@example.com'
    )
}
```
**GIẢI THÍCH:**
- Chạy khi build = FAILURE
- Bất kỳ stage fail hoặc error

#### 11.3 ABORTED
```groovy
aborted {
    echo '=== BUILD ABORTED ==='
}
```
**GIẢI THÍCH:**
- User cancel build

#### 11.4 UNSTABLE
```groovy
unstable {
    echo '=== BUILD UNSTABLE ==='
}
```
**GIẢI THÍCH:**
- Build success nhưng tests fail
- Hoặc quality gate không pass

#### 11.5 ALWAYS
```groovy
always {
    echo '=== CLEANUP ==='
    cleanWs()
}
```
**GIẢI THÍCH:**
- **LUÔN LUÔN chạy**
- Dùng cho cleanup
- Archive artifacts

**Full example:**
```groovy
post {
    success {
        echo 'Build passed!'
        sh 'notify.sh success'
    }
    failure {
        echo 'Build failed!'
        sh 'notify.sh failure'
    }
    always {
        // Archive
        archiveArtifacts 'dist/**/*'

        // Clean workspace
        cleanWs()
    }
}
```

---

### 📝 SECTION 12: ADVANCED FEATURES

#### 12.1 PARALLEL EXECUTION
```groovy
stage('Parallel Tests') {
    steps {
        script {
            parallel(
                "Unit Tests": {
                    echo 'Running unit tests...'
                    sh 'npm run test:unit'
                },
                "Integration Tests": {
                    echo 'Running integration tests...'
                    sh 'npm run test:integration'
                },
                "E2E Tests": {
                    echo 'Running E2E tests...'
                    sh 'npm run test:e2e'
                }
            )
        }
    }
}
```
**GIẢI THÍCH:**
- **`parallel`**: Chạy song song
- Speed up pipeline
- Cần enough agents

**Benefits:**
```
Sequential: 30 minutes (10 + 10 + 10)
Parallel:   10 minutes (max của 3 stages)
```

#### 12.2 MATRIX BUILDS
```groovy
stage('Matrix Build') {
    matrix {
        axes {
            axis {
                name 'NODE_VERSION'
                values '18', '20', '21'
            }
            axis {
                name 'OS'
                values 'linux', 'windows'
            }
        }
        stages {
            stage('Build') {
                steps {
                echo "Building on Node ${NODE_VERSION} - ${OS}"
                sh 'npm run build'
            }
        }
    }
}
```
**GIẢI THÍCH:**
- Test trên nhiều combinations
- Total builds: 3 × 2 = 6
- Matrix:
  - Node 18 + Linux
  - Node 18 + Windows
  - Node 20 + Linux
  - Node 20 + Windows
  - Node 21 + Linux
  - Node 21 + Windows

#### 12.3 INPUT APPROVAL
```groovy
stage('Deploy to Production') {
    steps {
        input message: 'Approve deployment?', ok: 'Deploy'

        sh 'kubectl apply -f prod/'
    }
}
```
**GIẢI THÍCH:**
- **`input`**: Manual approval gate
- Pipeline pause và chờ user input
- **Options:**
```groovy
input(
    message: 'Deploy to production?',
    ok: 'Deploy',
    submitter: 'admin,ops-team',  // Chỉ user này được approve
    submitterParameter: 'APPROVER'
)
```

#### 12.4 CREDENTIALS MANAGEMENT
```groovy
stage('Deploy') {
    steps {
        withCredentials([
            string(
                credentialsId: 'api-token',
                variable: 'API_TOKEN'
            ),
            usernamePassword(
                credentialsId: 'docker-registry',
                usernameVariable: 'DOCKER_USER',
                passwordVariable: 'DOCKER_PASS'
            )
        ]) {
            sh '''
                echo $API_TOKEN
                docker login -u $DOCKER_USER -p $DOCKER_PASS
            '''
        }
    }
}
```
**GIẢI THÍCH:**
- **`withCredentials`**: Inject credentials
- Credentials stored trong Jenkins (encrypted)
- Auto mask trong logs

**⚠️ SECURITY:**
- KHÔNG BAO GIỜ echo secrets
- Use credentials management
- Not hardcode trong Jenkinsfile

#### 12.5 NOTIFICATIONS
```groovy
post {
    always {
        script {
            def status = currentBuild.result ?: 'SUCCESS'

            // Slack
            slackSend(
                color: status == 'SUCCESS' ? 'good' : 'danger',
                message: "Build ${status}: ${env.JOB_NAME} - ${env.BUILD_NUMBER}"
            )

            // Email
            emailext(
                subject: "Build ${status}: ${env.JOB_NAME}",
                body: """
                    Status: ${status}
                    Console: ${env.BUILD_URL}console
                """,
                to: 'team@example.com'
            )

            // Microsoft Teams
            office365ConnectorSend(
                webhookUrl: 'TEAMS_WEBHOOK_URL',
                status: status
            )
        }
    }
}
```

---

### 📝 SECTION 13: BEST PRACTICES

#### ✅ 1. SỬ DỤNG DECLARATIVE SYNTAX
```groovy
// ✅ GOOD
pipeline {
    agent any
    stages { ... }
}

// ❌ AVOID (nếu có thể)
node {
    stage('Build') {
        sh 'make'
    }
}
```

#### ✅ 2. LUÔN LUÔN CÓ TIMEOUT
```groovy
options {
    timeout(time: 1, unit: 'HOURS')
}
```

#### ✅ 3. SỬ DỤNG PARAMETERS CHO FLEXIBILITY
```groovy
parameters {
    booleanParam(name: 'RUN_TESTS', defaultValue: true)
}
```

#### ✅ 4. ARCHIVE ARTIFACTS
```groovy
post {
    always {
        archiveArtifacts artifacts: 'dist/**/*'
    }
}
```

#### ✅ 5. CLEAN WORKSPACE
```groovy
post {
    always {
        cleanWs()
    }
}
```

#### ✅ 6. SECURITY SCANNING
```groovy
stage('Security Scan') {
    steps {
        sh 'trivy fs .'
    }
}
```

#### ✅ 7. MANUAL APPROVAL CHO PRODUCTION
```groovy
stage('Deploy to Prod') {
    steps {
        input message: 'Approve?'
        sh 'kubectl apply -f prod/'
    }
}
```

#### ✅ 8. PARALLEL EXECUTION
```groovy
parallel(
    "Test 1": { sh 'npm run test:1' },
    "Test 2": { sh 'npm run test:2' }
)
```

#### ✅ 9. USE CREDENTIALS MANAGEMENT
```groovy
withCredentials([string(credentialsId: 'token', variable: 'TOKEN')]) {
    sh 'echo $TOKEN'  // Masked trong logs
}
```

#### ✅ 10. ERROR HANDLING
```groovy
steps {
    script {
        try {
            sh 'npm run build'
        } catch (e) {
            echo "Build failed: ${e}"
            currentBuild.result = 'FAILURE'
            throw e
        }
    }
}
```

---

### 🎯 TỔNG KẾT - JENKINSFILE WORKFLOW

```
┌─────────────────────────────────────────────────────────────┐
│                    JENKINS PIPELINE                          │
├─────────────────────────────────────────────────────────────┤
│  1. Trigger build (manual, webhook, schedule)               │
│  2. Checkout code                                            │
│  3. Prepare environment                                      │
│  4. Install dependencies                                     │
│  5. Build application                                        │
│  6. Run tests                                               │
│  7. Security scanning (SonarQube, OWASP, Trivy)              │
│  8. Docker build (optional)                                  │
│  9. Deploy (with approval for production)                   │
│  10. Notify (email, Slack, etc.)                            │
│  11. Post-build actions (cleanup, archive)                  │
└─────────────────────────────────────────────────────────────┘
```

---

### 📝 SECTION 20: ADVANCED FEATURES - EXPERT LEVEL

#### 20.1 KUBERNETES AGENT

```groovy
agent {
    kubernetes {
        label 'my-pod'
        yaml '''
            apiVersion: v1
            kind: Pod
            metadata:
              labels:
                app: jenkins-agent
            spec:
              containers:
              - name: jnlp
                image: jenkins/inbound-agent:latest
              - name: node
                image: node:20-alpine
                command:
                - cat
                tty: true
              - name: docker
                image: docker:latest
                command:
                - cat
                tty: true
                volumeMounts:
                - mountPath: /var/run/docker.sock
                  name: docker-sock
              volumes:
              - name: docker-sock
                hostPath:
                  path: /var/run/docker.sock
        '''
    }
}
```

**GIẢI THÍCH:**
- **`kubernetes` agent**: Chạy pipeline trong Kubernetes pod
- **`yaml`**: Pod specification
- **Multiple containers**: Node.js, Docker, tools trong cùng pod
- **Volume mounts**: Mount Docker socket để chạy Docker-in-Docker

#### 20.2 MATRIX BUILDS - MULTI-CONFIGURATION TESTING

```groovy
stage('Matrix Build') {
    matrix {
        axes {
            axis {
                name 'NODE_VERSION'
                values '18', '20', '21'
            }
            axis {
                name 'OS'
                values 'linux', 'windows'
            }
        }
        stages {
            stage('Build') {
                steps {
                    echo "Building on Node ${NODE_VERSION} - ${OS}"
                    sh "npm run build"
                }
            }
            stage('Test') {
                steps {
                    echo "Testing on Node ${NODE_VERSION} - ${OS}"
                    sh "npm test"
                }
            }
        }
        excludes {
            exclude {
                axis {
                    name 'NODE_VERSION'
                    values '18'
                }
                axis {
                    name 'OS'
                    values 'windows'
                }
            }
        }
    }
}
```

**GIẢI THÍCH:**
- **`matrix`**: Chạy song song nhiều configurations
- **`axes`**: Các dimensions để test (Node version, OS, etc.)
- **Total builds**: 3 × 2 = 6 builds
- **`excludes`**: Loại bỏ các combinations không cần thiết
- **Parallel execution**: Tất cả matrix builds chạy song song

#### 20.3 SHARED LIBRARIES - COMPLETE GUIDE

**Library Structure:**
```
shared-library/
├── vars/
│   ├── standardBuild.groovy
│   ├── deploy.groovy
│   └── notify.groovy
├── src/
│   └── com/example/
│       ├── Utils.groovy
│       └── Docker.groovy
└── resources/
    └── org/jenkinsci/plugins/pipeline/
        └── status_messages.properties
```

**Using Shared Library:**
```groovy
@Library('shared-lib@main') _

pipeline {
    agent any
    stages {
        stage('Standard Build') {
            steps {
                // Gọi function từ vars/
                standardBuild()
            }
        }

        stage('Deploy') {
            steps {
                script {
                    // Gọi function với parameters
                    deploy(
                        environment: 'production',
                        strategy: 'blue-green'
                    )
                }
            }
        }
    }
}
```

**Custom Function Example (vars/standardBuild.groovy):**
```groovy
def call(Map config = [:]) {
    pipeline {
        agent any

        options {
            timeout(time: config.timeout ?: 1, unit: 'HOURS')
        }

        stages {
            stage('Build') {
                steps {
                    sh 'npm run build'
                }
            }

            stage('Test') {
                when {
                    expression { config.skipTests != true }
                }
                steps {
                    sh 'npm test'
                }
            }
        }
    }
}
```

#### 20.4 BLUE-GREEN DEPLOYMENT

```groovy
stage('Blue-Green Deployment') {
    steps {
        script {
            // Get current color
            def currentColor = sh(
                script: 'kubectl get service ${APP_NAME} -o jsonpath="{.spec.selector.color}"',
                returnStdout: true
            ).trim()

            def newColor = currentColor == 'blue' ? 'green' : 'blue'

            echo "Current: ${currentColor}, New: ${newColor}"

            // Deploy to new color
            sh """
                kubectl apply -f k8s/${newColor}/
                kubectl wait --for=condition=ready pod -l color=${newColor} --timeout=300s
            """

            // Switch traffic
            sh """
                kubectl patch service ${APP_NAME} -p '{"spec":{"selector":{"color":"${newColor}"}}}'
            """

            // Monitor for rollback
            timeout(time: 5, unit: 'MINUTES') {
                sh '''
                    # Health checks
                    for i in {1..30}; do
                        if curl -f ${HEALTH_URL}; then
                            echo "Health check passed"
                            break
                        fi
                        sleep 10
                    done
                '''
            }

            // Cleanup old deployment after success
            sh "kubectl delete -f k8s/${currentColor}/"
        }
    }
}
```

**GIẢI THÍCH:**
- **Blue-Green**: 2 environments giống hệt nhau
- **Zero downtime**: Switch traffic instant
- **Easy rollback**: Switch back nếu có vấn đề
- **Resource intensive**: Cần 2x resources

#### 20.5 CANARY DEPLOYMENT

```groovy
stage('Canary Deployment') {
    steps {
        script {
            // Start with 10%
            def canaryPercentages = [10, 25, 50, 100]

            canaryPercentages.each { percent ->
                echo "Canary deployment: ${percent}%"

                // Update canary percentage
                sh """
                    kubectl patch deployment ${APP_NAME}-canary \
                        -p '{"spec":{"replicas":${(TOTAL_REPLICATES * percent / 100).intValue()}}}'
                """

                // Update traffic split via Istio
                sh """
                    istioctl replace -f - <<EOF
                    apiVersion: networking.istio.io/v1beta1
                    kind: VirtualService
                    metadata:
                      name: ${APP_NAME}
                    spec:
                      http:
                      - route:
                        - destination:
                            host: ${APP_NAME}
                            subset: stable
                          weight: ${100 - percent}
                        - destination:
                            host: ${APP_NAME}
                            subset: canary
                          weight: ${percent}
                    EOF
                """

                // Monitor metrics
                sleep(time: 5, unit: 'MINUTES')

                // Check error rate
                def errorRate = sh(
                    script: """
                        curl -s ${METRICS_URL}/error-rate
                    """,
                    returnStdout: true
                ).trim() as double

                if (errorRate > 0.01) {  // 1% error rate
                    error("Canary failed! Error rate: ${errorRate}%")
                }
            }

            // Promote canary to stable
            sh """
                kubectl scale deployment ${APP_NAME} --replicas=${TOTAL_REPLICATES}
                kubectl delete deployment ${APP_NAME}-canary
            """
        }
    }
}
```

**GIẢI THÍCH:**
- **Canary**: Gradual rollout (10% → 25% → 50% → 100%)
- **Traffic splitting**: Via Istio, NGINX, or ALB
- **Monitoring**: Check metrics tại mỗi step
- **Auto-rollback**: Nếu error rate > threshold

#### 20.6 DISCORD NOTIFICATION

```groovy
stage('Notify') {
    steps {
        script {
            def buildStatus = currentBuild.result ?: 'SUCCESS'
            def color = buildStatus == 'SUCCESS' ? '3066993' : '15158332'  // Decimal colors

            webhook(
                url: 'DISCORD_WEBHOOK_URL',
                contentType: 'APPLICATION_JSON',
                payload: """{
                    "username": "Jenkins",
                    "avatar_url": "https://wiki.jenkins.io/download/attachments/2916393/headshot.png",
                    "embeds": [{
                        "title": "${env.JOB_NAME} - ${buildStatus}",
                        "description": "Build #${env.BUILD_NUMBER}",
                        "color": ${color},
                        "fields": [
                            {"name": "Status", "value": "${buildStatus}", "inline": true},
                            {"name": "Environment", "value": "${params.ENVIRONMENT}", "inline": true},
                            {"name": "Version", "value": "${params.VERSION}", "inline": true},
                            {"name": "Duration", "value": "${currentBuild.durationString}", "inline": true},
                            {"name": "Changes", "value": "${env.GIT_COMMIT_SHORT}", "inline": true}
                        ],
                        "url": "${env.BUILD_URL}"
                    }]
                }"""
            )
        }
    }
}
```

#### 20.7 MICROSOFT TEAMS NOTIFICATION

```groovy
stage('Notify Teams') {
    steps {
        script {
            def buildStatus = currentBuild.result ?: 'SUCCESS'
            def color = buildStatus == 'SUCCESS' ? '00ff00' : 'ff0000'

            office365ConnectorSend(
                webhookUrl: 'TEAMS_WEBHOOK_URL',
                status: buildStatus,
                color: color,
                message: """
                    **Build ${buildStatus}**
                    - Project: ${env.JOB_NAME}
                    - Build: #${env.BUILD_NUMBER}
                    - Environment: ${params.ENVIRONMENT}
                    - Version: ${params.VERSION}
                    - [View Logs](${env.BUILD_URL}console)
                """.stripIndent()
            )
        }
    }
}
```

#### 20.8 HTTP REQUESTS IN PIPELINE

```groovy
stage('API Call') {
    steps {
        script {
            // GET request
            def response = sh(
                script: 'curl -s -X GET https://api.example.com/health',
                returnStdout: true
            )

            // POST request with JSON
            sh '''
                curl -X POST https://api.example.com/deploy \
                    -H "Content-Type: application/json" \
                    -H "Authorization: Bearer ${API_TOKEN}" \
                    -d '{
                        "environment": "${params.ENVIRONMENT}",
                        "version": "${params.VERSION}",
                        "build_url": "${env.BUILD_URL}"
                    }'
            '''

            // Using httpRequest (HTTP Request Plugin)
            httpRequest(
                url: 'https://api.example.com/notify',
                httpMode: 'POST',
                contentType: 'APPLICATION_JSON',
                requestBody: """
                    {"status": "SUCCESS", "build": "${env.BUILD_NUMBER}"}
                """.stripIndent(),
                quiet: true
            )
        }
    }
}
```

#### 20.9 FILE OPERATIONS

```groovy
stage('File Operations') {
    steps {
        script {
            // Read file
            def content = readFile 'config.json'

            // Write file
            writeFile file: 'output.json', text: '{"result": "success"}'

            // Find files
            def files = findFiles(glob: '**/*.jar')

            // Archive files
            archiveArtifacts artifacts: 'target/*.jar'

            // Stash files (save for later)
            stash includes: 'target/*.jar', name: 'build-artifacts'

            // Unstash files
            unstash 'build-artifacts'

            // Delete files
            sh 'rm -rf target/*.jar'

            // Zip files
            sh 'zip -r artifacts.zip dist/'

            // Unzip files
            sh 'unzip artifacts.zip -d output/'
        }
    }
}
```

#### 20.10 ERROR HANDLING STRATEGIES

```groovy
stage('Error Handling') {
    steps {
        script {
            try {
                // Stage code
                sh 'npm run build'

            } catch (Exception e) {
                // Handle specific errors
                if (e.message.contains('Out of memory')) {
                    echo 'Memory error detected, retrying with more memory...'
                    sh 'NODE_OPTIONS="--max-old-space-size=4096" npm run build'
                } else {
                    // Rethrow for other errors
                    throw e
                }

            } finally {
                // Always run cleanup
                sh 'rm -rf tmp/'
            }
        }
    }
}
```

#### 20.11 RETRY STRATEGY

```groovy
stage('Retry') {
    steps {
        retry(3) {
            script {
                sh '''
                    # Attempt operation
                    curl -f https://api.example.com/ping || exit 1
                '''
            }
        }
    }

    post {
        failure {
            echo 'Failed after 3 retries!'
        }
    }
}
```

#### 20.12 TIMEOUT PER STAGE

```groovy
stage('Long Running Task') {
    options {
        timeout(time: 30, unit: 'MINUTES')
    }

    steps {
        sh 'npm run test:integration'
    }

    post {
        failure {
            script {
                if (currentBuild.result == 'ABORTED') {
                    echo 'Stage timed out!'
                }
            }
        }
    }
}
```

---

### 📝 SECTION 21: JENKINS PLUGIN ECOSYSTEM

**Must-have Plugins:**

1. **Pipeline** - Declarative pipeline support
2. **Git** - Git integration
3. **GitHub / GitLab / Bitbucket** - SCM integration
4. **Blue Ocean** - Modern UI
5. **Docker Pipeline** - Docker support
6. **Kubernetes** - Kubernetes agents
7. **Config File Provider** - Configuration files
8. **Credentials Binding** - Secure credentials
9. **Workspace Cleanup** - Clean workspace
10. **Timestamper** - Timestamps in logs

**Testing Plugins:**
- **JUnit** - Test results
- **Cobertura** - Code coverage
- **HTML Publisher** - HTML reports

**Security Plugins:**
- **SonarQube Scanner** - Code quality
- **OWASP Dependency-Check** - Vulnerability scanning
- **Trivy** - Container scanning

**Notification Plugins:**
- **Slack** - Slack notifications
- **Email Extension** - Enhanced email
- **Microsoft Teams** - Teams notifications
- **Discord Notifier** - Discord notifications

**Deployment Plugins:**
- **Kubernetes CLI** - kubectl commands
- **AWS Steps** - AWS deployment
- **Azure CLI** - Azure deployment

---

### 🎯 JENKINS LEARNING PATH

```
Beginner (Week 1-2):
├── Pipeline basics (agent, stages, steps)
├── Checkout, build, test stages
├── Parameters & environment variables
└── Basic post-build actions

Intermediate (Week 3-4):
├── Conditional execution (when)
├── Parallel execution
├── Docker agents
├── Credentials management
└── Notifications (Slack, email)

Advanced (Week 5-8):
├── Security scanning (SonarQube, Trivy, OWASP)
├── Matrix builds
├── Kubernetes agents
├── Shared libraries
├── Blue-Green/Canary deployments
└── Error handling & retry strategies

Expert (Week 9+):
├── Multi-branch pipelines
├── Complex deployments
├── Custom plugins development
├── Pipeline as Code best practices
└── Jenkins optimization & scaling
```

---

### 📚 TÀI LIỆU THAM KHẢO CHO JENKINS:

- **Jenkins Official Docs**: https://www.jenkins.io/doc/
- **Pipeline Syntax**: https://www.jenkins.io/doc/book/pipeline/syntax/
- **Shared Libraries**: https://www.jenkins.io/doc/book/pipeline/shared-libraries/
- **Plugins**: https://plugins.jenkins.io/

---

## 🌍 GIẢI THÍCH TERRAFORM - TỪ ZERO ĐẾN ADVANCE

---

### 📌 Terraform Là Gì?

**Terraform** là **Infrastructure as Code (IaC)** tool của HashiCorp dùng để:
- Define infrastructure = code
- Provision resources trên multi-cloud (AWS, Azure, GCP, etc.)
- Manage infrastructure lifecycle
- Version control infrastructure changes

**Ví dụ dễ hiểu:**
```
Terraform = Architect tự động
- Bạn viết code → Terraform đọc và build infrastructure
- Bạn thay đổi code → Terraform cập nhật infrastructure
- Bạn xóa code → Terraform destroy resources
```

**Lợi ích:**
- **Consistent**: Code = infrastructure (không có manual drift)
- **Reusable**: Modules dùng lại cho nhiều projects
- **Version controlled**: Git track mọi changes
- **Multi-cloud**: Cùng syntax cho AWS, Azure, GCP, Kubernetes, etc.

---

### 📖 CÁC FILE HỌC TERRAFORM:

| File | Mục đích | Khi nào dùng |
|------|----------|--------------|
| **learn.tf** | File đầy đủ với comments chi tiết | Học cách viết Terraform |
| **practice.tf** | File có chỗ trống để điền | Thực hành, kiểm tra kiến thức |
| **main.tf** | File thực tế cho project | Dùng trong production |

---

### 🔤 CẤU TRÚC CƠ BẢN CỦA TERRAFORM

```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" { ... }
}

provider "aws" {
  region = "us-east-1"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

locals {
  name_prefix = "${var.project}-${var.env}"
}

data "aws_vpc" "existing" {
  id = var.vpc_id
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

output "vpc_id" {
  value = aws_vpc.main.id
}

module "vpc" {
  source = "./modules/vpc"
}
```

---

### 📝 SECTION 1: TERRAFORM BLOCK

```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

**GIẢI THÍCH:**

#### 1.1 REQUIRED VERSION
```hcl
required_version = ">= 1.0"
```
**GIẢI THÍCH:**
- Yêu cầu Terraform version tối thiểu
- **Operators:**
  - `>= 1.0`: Version 1.0 hoặc cao hơn
  - `~> 1.0`: Version 1.x (không jump lên 2.0)
  - `= 1.0.0`: Chính xác version này
- **Tại sao cần?**
  - Đảm bảo tính tương thích
  - Tránh breaking changes

#### 1.2 REQUIRED PROVIDERS
```hcl
required_providers {
  aws = {
    source  = "hashicorp/aws"
    version = "~> 5.0"
  }
}
```
**GIẢI THÍCH:**
- **`source`**: Provider source
  - Format: `<namespace>/<type>`
  - `hashicorp/aws`: Official AWS provider
  - `hashicorp/azurerm`: Azure provider
  - `hashicorp/google`: GCP provider
- **`version`**: Version constraint
  - `~> 5.0`: Version 5.x (5.0, 5.1, 5.2, ...)
  - `>= 4.0`: Version 4.0+
  - Lần đầu run: `terraform init` tải provider

#### 1.3 BACKEND CONFIGURATION
```hcl
backend "s3" {
  bucket         = "my-terraform-state"
  key            = "prod/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "terraform-locks"
}
```
**GIẢI THÍCH:**
- **Backend**: Nơi lưu state file
- **State file**: Database của Terraform (track tất cả resources)
- **S3 backend**:
  - **`bucket`**: S3 bucket name
  - **`key`**: Path to state file
  - **`encrypt`**: Encrypt state at rest
  - **`dynamodb_table`**: Locking state (prevents concurrent modifications)

**Các backend types:**
```hcl
# Local backend (default)
backend "local" {
  path = "terraform.tfstate"
}

# S3 backend (recommended for teams)
backend "s3" {
  bucket = "my-state"
  key    = "prod/terraform.tfstate"
  region = "us-east-1"
}

# Azure Blob Storage
backend "azurerm" {
  storage_account_name = "mystorageaccount"
  container_name       = "terraform-state"
  key                  = "prod.terraform.tfstate"
}

# GCS (Google Cloud Storage)
backend "gcs" {
  bucket = "terraform-state"
  prefix = "prod"
}
```

---

### 📝 SECTION 2: PROVIDER BLOCKS

```hcl
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
```

**GIẢI THÍCH:**

#### 2.1 PROVIDER CONFIGURATION
```hcl
provider "aws" {
  region = "us-east-1"
}
```
**GIẢI THÍCH:**
- **`provider`**: Khai báo cloud provider
- **`aws`**: Provider name
- **`region`**: Default region cho resources

**Multi-region:**
```hcl
provider "aws" {
  alias  = "us_west_2"
  region = "us-west-2"
}

# Use alias:
resource "aws_instance" "west" {
  provider = aws.us_west_2
  # ...
}
```

#### 2.2 DEFAULT TAGS
```hcl
default_tags {
  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
```
**GIẢI THÍCH:**
- Tất cả resources sẽ có các tags này
- Tiết kiệm thời gian, đảm bảo consistency

**Các provider phổ biến:**
```hcl
# AWS
provider "aws" {
  region = "us-east-1"
}

# Azure
provider "azurerm" {
  features {}
}

# GCP
provider "google" {
  project = "my-project"
  region  = "us-central1"
}

# Kubernetes
provider "kubernetes" {
  host = "https://kubernetes-cluster:6443"
}

# Helm
provider "helm" {
  kubernetes {
    host = "https://kubernetes-cluster:6443"
  }
}
```

---

### 📝 SECTION 3: VARIABLES

```hcl
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^us-", var.aws_region))
    error_message = "Region must start with 'us-'."
  }
}
```

**GIẢI THÍCH:**

#### 3.1 STRING VARIABLE
```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
```
**GIẢI THÍCH:**
- **`description`**: Giải thích variable
- **`type`**: Data type
- **`default`**: Giá trị default (optional)
- **Usage**: `var.aws_region`

#### 3.2 NUMBER VARIABLE
```hcl
variable "instance_count" {
  description = "Number of instances"
  type        = number
  default     = 2

  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 10
    error_message = "Count must be between 1 and 10."
  }
}
```
**GIẢI THÍCH:**
- **`validation`**: Validate input
- **`condition`**: Boolean expression
- **`error_message`**: Error message nếu fail

#### 3.3 BOOLEAN VARIABLE
```hcl
variable "enable_monitoring" {
  description = "Enable monitoring"
  type        = bool
  default     = true
}
```
**GIẢI THÍCH:**
- Boolean: true hoặc false

#### 3.4 LIST VARIABLE
```hcl
variable "availability_zones" {
  description = "List of AZs"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}
```
**GIẢI THÍCH:**
- List of strings
- **Usage:**
```hcl
azs = var.availability_zones[0]  # First element
```

#### 3.5 MAP VARIABLE
```hcl
variable "instance_types" {
  description = "Instance types by environment"
  type        = map(string)
  default = {
    dev     = "t3.micro"
    staging = "t3.small"
    prod    = "t3.medium"
  }
}
```
**GIẢI THÍCH:**
- Key-value pairs
- **Usage:**
```hcl
instance_type = var.instance_types["dev"]
# hoặc
instance_type = var.instance_types[var.environment]
```

#### 3.6 OBJECT VARIABLE
```hcl
variable "tags" {
  description = "Tags"
  type = object({
    Environment = string
    Project     = string
    Owner       = string
  })
  default = {
    Environment = "dev"
    Project     = "my-app"
    Owner       = "devops"
  }
}
```
**GIẢI THÍCH:**
- Complex nested structure
- Type validation strict

#### 3.7 OPTIONAL TYPE
```hcl
variable "cost_center" {
  type    = optional(string)
  default = null
}
```
**GIẢI THÍCH:**
- `optional`: Attribute không bắt buộc

**Cách sử dụng variables:**
```bash
# File terraform.tfvars
aws_region = "us-east-1"
instance_count = 3

# Command line
terraform apply -var="aws_region=us-west-2"

# Environment variable
export TF_VAR_aws_region=us-west-2
terraform apply
```

---

### 📝 SECTION 4: LOCALS

```hcl
locals {
  name_prefix   = "${var.project_name}-${var.environment}"
  instance_type = var.environment == "prod" ? "t3.medium" : "t3.micro"

  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}
```

**GIẢI THÍCH:**
- **`locals`**: Local variables
- Giống variables nhưng:
  - Không phải input parameters
  - Computed from other values
  - Dùng để avoid repetition

**Sự khác biệt Variables vs Locals:**
```
Variables:
- Input from users
- Defined at root level
- Can be overridden (-var, .tfvars)

Locals:
- Computed within module
- Cannot be overridden
- Dùng cho derived values
```

**Examples:**
```hcl
locals {
  # Ternary operator
  instance_type = var.environment == "prod" ? "t3.medium" : "t3.micro"

  # String interpolation
  name_prefix = "${var.project}-${var.env}"

  # Complex computed values
  subnet_cidrs = {
    public  = ["10.0.1.0/24", "10.0.2.0/24"]
    private = ["10.0.10.0/24", "10.0.11.0/24"]
  }

  # Functions
  selected_azs = slice(var.availability_zones, 0, 2)
}
```

---

### 📝 SECTION 5: DATA SOURCES

```hcl
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}
```

**GIẢI THÍCH:**
- **Data sources**: Fetch existing resources
- Read-only (không tạo resources)
- **Usage:** `data.<TYPE>.<NAME>.<ATTRIBUTE>`

**Common data sources:**

#### 5.1 CALLER IDENTITY
```hcl
data "aws_caller_identity" "current" {}
```
**Usage:**
```hcl
account_id = data.aws_caller_identity.current.account_id
arn        = data.aws_caller_identity.current.arn
user_id    = data.aws_caller_identity.current.user_id
```

#### 5.2 AWS REGION
```hcl
data "aws_region" "current" {}
```
**Usage:**
```hcl
region = data.aws_region.current.name
```

#### 5.3 EXISTING VPC
```hcl
data "aws_vpc" "existing" {
  id = var.vpc_id
}
```
**Usage:**
```hcl
cidr_block = data.aws_vpc.existing.cidr_block
```

#### 5.4 LATEST AMI
```hcl
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
```
**GIẢI THÍCH:**
- **`most_recent`**: Get newest AMI
- **`owners`**: AMI owner
  - `amazon`: Amazon official AMIs
  - `self`: Your AMIs
- **`filter`**: Filter criteria

**Usage:**
```hcl
resource "aws_instance" "web" {
  ami = data.aws_ami.amazon_linux_2023.id
  # ...
}
```

---

### 📝 SECTION 6: RESOURCES

```hcl
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "my-vpc"
  }
}
```

**GIẢI THÍCH:**
- **Resource blocks**: Tạo infrastructure resources
- **Syntax**: `resource "TYPE" "NAME" { ... }`
- **Usage:** `<TYPE>.<NAME>.<ATTRIBUTE>`

#### 6.1 RESOURCE EXAMPLES

**VPC:**
```hcl
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "main-vpc"
  }
}
```

**Subnet:**
```hcl
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-1"
  }
}
```

**EC2 Instance:**
```hcl
resource "aws_instance" "web" {
  ami                    = "ami-0c55b159cbfafe1f0"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]

  tags = {
    Name = "web-server-1"
  }
}
```

**S3 Bucket:**
```hcl
resource "aws_s3_bucket" "logs" {
  bucket = "my-app-logs"

  tags = {
    Name = "logs-bucket"
  }
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id

  versioning_configuration {
    status = "Enabled"
  }
}
```

**RDS Database:**
```hcl
resource "aws_db_instance" "main" {
  identifier           = "mydb"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  storage_encrypted    = true

  db_name  = "myapp"
  username = var.db_username
  password = var.db_password

  skip_final_snapshot = true
}
```

#### 6.2 RESOURCE METADATA ARGUMENTS

**Count:**
```hcl
resource "aws_instance" "web" {
  count = 3  # Create 3 instances

  ami           = "ami-xxx"
  instance_type = "t3.micro"
}

# Access: aws_instance.web[0].id, aws_instance.web[1].id, etc.
```

**For_each:**
```hcl
resource "aws_instance" "web" {
  for_each = {
    "web-1" = "t3.micro"
    "web-2" = "t3.small"
  }

  ami           = "ami-xxx"
  instance_type = each.value

  tags = {
    Name = each.key
  }
}

# Access: aws_instance.web["web-1"].id
```

**Depends_on:**
```hcl
resource "aws_instance" "web" {
  ami           = "ami-xxx"
  instance_type = "t3.micro"

  depends_on = [aws_internet_gateway.main]
}
```

**Lifecycle:**
```hcl
resource "aws_instance" "web" {
  ami           = "ami-xxx"
  instance_type = "t3.micro"

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = false
    ignore_changes        = [tags["CreatedDate"]]
  }
}
```

**Lifecycle options:**
- **`create_before_destroy`**: Tạo mới trước khi xóa cũ
- **`prevent_destroy`**: Không cho phép xóa (critical resources)
- **`ignore_changes`**: Bỏ qua drift cho một số attributes

---

### 📝 SECTION 7: OUTPUTS

```hcl
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "instance_public_ips" {
  description = "Public IPs of instances"
  value       = aws_instance.web[*].public_ip
}

output "db_password" {
  description = "Database password"
  value       = aws_db_instance.main.password
  sensitive   = true
}
```

**GIẢI THÍCH:**
- **Outputs**: Return values sau khi `terraform apply`
- Dùng để:
  - Display important values
  - Share giữa modules
  - Debugging

**Sensitive outputs:**
```hcl
output "db_password" {
  value     = var.db_password
  sensitive = true  # Won't show in plaintext
}
```

---

### 📝 SECTION 8: MODULES

```hcl
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
}
```

**GIẢI THÍCH:**
- **Modules**: Reusable Terraform configurations
- **Benefits:**
  - Code organization
  - Reusability
  - Maintainability

**Module sources:**
```hcl
# Terraform Registry
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"
}

# Local path
module "database" {
  source = "./modules/database"
}

# Git repository
module "ecs" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-ecs.git?ref=v5.0.0"
}

# S3 bucket
module "remote" {
  source = "s3::https://s3.amazonaws.com/my-bucket/terraform-module.zip"
}
```

**Module outputs:**
```hcl
# Module definition
module "vpc" {
  source = "./modules/vpc"
  # ...
}

# Use module outputs
resource "aws_subnet" "app" {
  vpc_id     = module.vpc.vpc_id
  cidr_block = "10.0.10.0/24"
}
```

---

### 📝 SECTION 9: TERRAFORM FUNCTIONS

**String functions:**
```hcl
upper("hello")           # → "HELLO"
lower("HELLO")           # → "hello"
title("hello world")     # → "Hello World"
replace("hello", "el", "al")  # → "hallo"
split(",", "a,b,c")      # → ["a", "b", "c"]
join(",", ["a", "b", "c"])  # → "a,b,c"
format("Hello %s", "World")  # → "Hello World"
trimspace("  hello  ")    # → "hello"
```

**Numeric functions:**
```hcl
abs(-5)                 # → 5
max(1, 2, 3)            # → 3
min(1, 2, 3)            # → 1
ceil(3.1)               # → 4
floor(3.9)              # → 3
pow(2, 3)               # → 8
length(["a", "b", "c"]) # → 3
```

**Collection functions:**
```hcl
element(["a", "b"], 0)   # → "a"
lookup({a="1"}, "a")    # → "1"
merge({a="1"}, {b="2"}) # → {a="1", b="2"}
keys({a="1", b="2"})    # → ["a", "b"]
values({a="1", b="2"})  # → ["1", "2"]
```

**Network functions:**
```hcl
cidrhost("10.0.0.0/16", 10)     # → "10.0.0.10"
cidrsubnet("10.0.0.0/16", 8, 1) # → "10.1.0.0/24"
cidrnetmask("10.0.0.0/16")      # → "255.255.0.0"
```

---

### 📝 SECTION 9.5: AWS RESOURCES - COMPLETE GUIDE

#### 9.5.1 VPC (VIRTUAL PRIVATE CLOUD)

```hcl
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "main-vpc"
  }
}
```

**GIẢI THÍCH:**
- **`cidr_block`**: IP range (16 bits = 65,536 IPs)
- **`enable_dns_hostnames`**: DNS cho instances
- **`enable_dns_support`**: DNS resolution

#### 9.5.2 SUBNETS

```hcl
# Public subnets
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = { Type = "public" }
}

# Private subnets
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.${count.index}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = { Type = "private" }
}
```

#### 9.5.3 NAT GATEWAY

```hcl
# Elastic IP
resource "aws_eip" "nat" {
  domain = "vpc"
}

# NAT Gateway
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  depends_on = [aws_internet_gateway.main]
}
```

**GIẢI THÍCH:**
- NAT Gateway cho private subnets internet access
- **Cost**: ~$0.045/hour
- **High availability**: Deploy 1 NAT Gateway per AZ

#### 9.5.4 EC2 INSTANCES

```hcl
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.web.id]

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
  EOF

  tags = { Name = "web-server" }
}
```

#### 9.5.5 LOAD BALANCER (ALB)

```hcl
resource "aws_lb" "main" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = aws_subnet.public[*].id

  tags = { Name = "app-alb" }
}

resource "aws_lb_target_group" "web" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}
```

#### 9.5.6 AUTO SCALING GROUP

```hcl
resource "aws_launch_template" "web" {
  name_prefix   = "web-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"

  user_data = <<-EOF
    #!/bin/bash
    yum install -y httpd
    systemctl start httpd
  EOF
}

resource "aws_autoscaling_group" "web" {
  desired_capacity    = 2
  max_size            = 5
  min_size            = 1
  vpc_zone_identifier = aws_subnet.public[*].id

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
}
```

#### 9.5.7 S3 BUCKETS

```hcl
resource "aws_s3_bucket" "website" {
  bucket = "my-website"
}

resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

**Security Best Practices:**
- **Enable versioning**: Track object changes
- **Enable encryption**: Server-side encryption
- **Block public access**: Security by default

#### 9.5.8 RDS DATABASE

```hcl
resource "aws_db_instance" "mysql" {
  identifier           = "mydb"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20

  db_name  = "myapp"
  username = "admin"
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = 30
  skip_final_snapshot     = false
}
```

#### 9.5.9 LAMBDA FUNCTIONS

```hcl
resource "aws_lambda_function" "example" {
  function_name = "my-function"
  role          = aws_iam_role.lambda.arn
  runtime       = "python3.11"
  handler       = "index.lambda_handler"

  filename         = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")

  environment {
    variables = {
      LOG_LEVEL = "INFO"
    }
  }
}
```

#### 9.5.10 DYNAMODB

```hcl
resource "aws_dynamodb_table" "users" {
  name         = "users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "UserId"

  attribute {
    name = "UserId"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }
}
```

---

### 📝 SECTION 10: TERRAFORM WORKFLOW

```
┌─────────────────────────────────────────────────────────────┐
│                    TERRAFORM WORKFLOW                        │
├─────────────────────────────────────────────────────────────┤
│  1. terraform init          - Initialize working directory  │
│  2. terraform validate      - Validate configuration files   │
│  3. terraform fmt           - Format and check code style   │
│  4. terraform plan          - Preview changes               │
│  5. terraform apply         - Apply the changes             │
│  6. terraform output        - Show output values            │
│  7. terraform destroy       - Destroy all resources         │
└─────────────────────────────────────────────────────────────┘
```

**Chi tiết từng lệnh:**

#### 10.1 TERRAFORM INIT
```bash
terraform init
```
**GIẢI THÍCH:**
- Download providers
- Initialize backend
- Download modules
- **Run mỗi khi:**
  - Clone new repo
  - Thay đổi backend config
  - Thêm/đổi modules

#### 10.2 TERRAFORM VALIDATE
```bash
terraform validate
```
**GIẢI THÍCH:**
- Validate syntax
- Check variable references
- **KHÔNG connect** to cloud providers

#### 10.3 TERRAFORM FMT
```bash
terraform fmt
```
**GIẢI THÍCH:**
- Format code theo HCL standard
- **Auto-format:**
```bash
terraform fmt -recursive  # Format all .tf files
terraform fmt -check      # Check if formatting needed
terraform fmt -diff       # Show formatting diff
```

#### 10.4 TERRAFORM PLAN
```bash
terraform plan
```
**GIẢI THÍCH:**
- Show execution plan
- **Show:**
  - `+` (create): New resources
  - `-` (destroy): Delete resources
  - `~` (update): Update resources
- **Options:**
```bash
terraform plan -out=tfplan       # Save plan to file
terraform plan -var="region=us-west-2"  # Override variable
```

#### 10.5 TERRAFORM APPLY
```bash
terraform apply
```
**GIẢI THÍCH:**
- Apply changes
- **Options:**
```bash
terraform apply -auto-approve    # Skip approval prompt
terraform apply tfplan           # Apply saved plan
terraform apply -var="region=us-west-2"
```

#### 10.6 TERRAFORM DESTROY
```bash
terraform destroy
```
**GIẢI THÍCH:**
- Destroy all resources
- **CẢNH BÁO:** Không thể undo!
- **Options:**
```bash
terraform destroy -auto-approve
terraform destroy -target=aws_instance.web  # Destroy specific resource
```

#### 10.7 OTHER COMMANDS
```bash
terraform output               # Show outputs
terraform show                 # Show state or resources
terraform refresh              # Update state file
terraform import               # Import existing resources
terraform state list           # List resources in state
terraform state show <resource> # Show resource details
terraform state rm <resource>  # Remove from state
terraform taint <resource>     # Mark for re-creation
terraform untaint <resource>   # Unmark resource
terraform graph                # Visualize dependency graph
terraform workspace list       # List workspaces
terraform workspace new dev    # Create workspace
```

---

### 📝 SECTION 11: BEST PRACTICES

#### ✅ 1. USE CONSISTENT NAMING CONVENTION
```hcl
resource "aws_instance" "web_server" { }
```
- lowercase_with_underscores cho resources
- kebab-case cho AWS resource names

#### ✅ 2. ALWAYS USE VARIABLES FOR INPUTS
```hcl
variable "region" {
  type    = string
  default = "us-east-1"
}
```

#### ✅ 3. USE LOCALS FOR COMPUTED VALUES
```hcl
locals {
  name_prefix = "${var.project}-${var.env}"
}
```

#### ✅ 4. TAG ALL RESOURCES
```hcl
tags = {
  Environment = var.env
  Project     = var.project
  ManagedBy   = "Terraform"
}
```

#### ✅ 5. USE REMOTE STATE (BACKEND)
```hcl
backend "s3" {
  bucket = "my-terraform-state"
  key    = "prod/terraform.tfstate"
  region = "us-east-1"
}
```

#### ✅ 6. LOCK STATE FILE
```hcl
dynamodb_table = "terraform-locks"
```

#### ✅ 7. VERSION PIN PROVIDERS
```hcl
version = "~> 5.0"
```

#### ✅ 8. VALIDATE INPUTS
```hcl
validation {
  condition     = var.instance_count > 0
  error_message = "Count must be > 0"
}
```

#### ✅ 9. USE MODULES FOR REUSABILITY
```hcl
module "vpc" {
  source = "./modules/vpc"
}
```

#### ✅ 10. USE OUTPUTS FOR IMPORTANT VALUES
```hcl
output "vpc_id" {
  value = aws_vpc.main.id
}
```

---

### 🎯 TỔNG KẾT - TERRAFORM WORKFLOW

```
┌─────────────────────────────────────────────────────────────┐
│                   TERRAFORM IaC PIPELINE                      │
├─────────────────────────────────────────────────────────────┤
│  1. Write Terraform code (.tf files)                        │
│  2. terraform init (initialize)                             │
│  3. terraform validate (check syntax)                       │
│  4. terraform plan (preview changes)                        │
│  5. terraform apply (provision infrastructure)              │
│  6. terraform output (view outputs)                         │
│  7. Commit code to Git (version control)                    │
│  8. Repeat for changes                                      │
└─────────────────────────────────────────────────────────────┘
```

---

### 📚 TÀI LIỆU THAM KHẢO CHO TERRAFORM:

- **Terraform Official Docs**: https://developer.hashicorp.com/terraform/docs
- **Terraform Registry**: https://registry.terraform.io/
- **AWS Provider Docs**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **Terraform Modules**: https://registry.terraform.io/browse/modules

---

## ⚡ GIẢI THÍCH ANSIBLE AWS - TỪ ZERO ĐẾN ADVANCE

---

### 📌 Ansible Là Gì?

**Ansible** là **open-source automation tool** dùng để:
- Configuration Management (cấu hình servers)
- Application Deployment (deploy applications)
- Orchestration (điều phối multiple tasks)
- Provisioning AWS resources

**Ví dụ dễ hiểu:**
```
Ansible = Puppeteer cho infrastructure
- Bạn viết playbooks (kịch bản)
- Ansible execute trên target servers
- Khó cần cài đặt agent trên target machines
```

**Ansible vs Terraform vs Jenkins:**
| Tool | Mục đích | Use case |
|------|----------|----------|
| **Ansible** | Configuration management | Cấu hình servers, deploy apps |
| **Terraform** | Infrastructure provisioning | Tạo AWS resources (VPC, EC2, etc.) |
| **Jenkins** | CI/CD orchestration | Automation pipeline, build, test |

---

### 📖 CÁC FILE HỌC ANSIBLE AWS:

| File | Mục đích | Khi nào dùng |
|------|----------|--------------|
| **learn.yaml** | Playbook đầy đủ với comments chi tiết | Học Ansible AWS |
| **practice.yaml** | Playbook có chỗ trống để điền | Thực hành, test kiến thức |

---

### 🔤 CẤU TRÚC CƠ BẢN CỦA ANSIBLE PLAYBOOK

```yaml
---
- name: "Playbook Name"
  hosts: webservers          # Target hosts
  become: true               # Sudo privilege
  vars:                      # Variables
    app_port: 8080
  tasks:                     # Tasks to execute
    - name: "Task Name"
      ansible.builtin.debug:
        msg: "Hello"
  handlers:                  # Triggered by tasks
    - name: "Restart Apache"
      ansible.builtin.service:
        name: httpd
        state: restarted
```

**Key components:**
- **hosts**: Target machines
- **vars**: Variables
- **tasks**: Operations to perform
- **handlers**: Actions on notification

---

### 📝 SECTION 1: ANSIBLE BASICS

#### 1.1 PLAYBOOK STRUCTURE
```yaml
---
- name: "Section 1: Basic Playbook"
  hosts: localhost           # Chạy trên local machine
  connection: local          # Local connection (không qua SSH)
  gather_facts: false        # Không thu thập system facts
  vars:
    message: "Hello Ansible!"

  tasks:
    - name: "Print message"
      ansible.builtin.debug:
        msg: "{{ message }}"
```

**GIẢI THÍCH:**
- **`---`**: YAML document start (bắt buộc)
- **`- name`**: Play name (một playbook có nhiều plays)
- **`hosts`**: Target pattern
  - `localhost` → Local machine
  - `all` → All hosts
  - `webservers` → Group trong inventory
- **`connection: local`**: Không SSH, chạy local
- **`gather_facts`**: Thu thập system info (OS, RAM, CPU)
- **`vars`**: Define variables
- **`tasks`**: List of tasks

#### 1.2 TASKS
```yaml
tasks:
  - name: "Print OS"
    ansible.builtin.debug:
      msg: "OS: {{ ansible_distribution }}"
```

**GIẢI THÍCH:**
- **`- name`**: Task description (mandatory)
- **`ansible.builtin.debug`**: Module để print messages
- **`{{ ansible_distribution }}`**: Jinja2 template variable

**Module naming:**
```
ansible.builtin.debug      → Built-in module
amazon.aws.ec2_instance    → AWS collection module
community.aws.rds_instance → Community AWS module
```

---

### 📝 SECTION 2: VARIABLES và FACTS

#### 2.1 VARIABLE TYPES
```yaml
vars:
  # String
  app_name: "myapp"

  # Number
  app_port: 8080

  # Boolean
  enable_ssl: true

  # List
  availability_zones:
    - us-east-1a
    - us-east-1b

  # Dictionary
  instance_config:
    type: t3.micro
    count: 2
```

**GIẢI THÍCH:**
- **String**: Text (quotes optional)
- **Number**: Integer/float
- **Boolean**: `true`/`false`
- **List**: Array (dùng `-`)
- **Dictionary**: Key-value pairs

#### 2.2 ACCESSING VARIABLES
```yaml
- name: "Access variables"
  ansible.builtin.debug:
    msg:
      - "App: {{ app_name }}"
      - "Port: {{ app_port }}"
      - "First AZ: {{ availability_zones[0] }}"
      - "Instance type: {{ instance_config.type }}"
```

**GIẢI THÍCH:**
- **`{{ variable }}`**: Jinja2 template syntax
- **`list[0]`**: Access list element (0-indexed)
- **`dict.key`**: Access dictionary value

#### 2.3 FACTS
```yaml
- name: "Display facts"
  ansible.builtin.debug:
    msg:
      - "OS: {{ ansible_distribution }}"
      - "Architecture: {{ ansible_architecture }}"
      - "Hostname: {{ ansible_hostname }}"
```

**GIẢI THÍCH:**
- **`gather_facts: true`**: Ansible tự động collect facts
- **Facts là variables** chứa system info:
  ```
  ansible_distribution → "Amazon Linux"
  ansible_architecture → "x86_64"
  ansible_memtotal_mb → 4096
  ansible_processor_vcpus → 2
  ```

---

### 📝 SECTION 3: LOOPS và CONDITIONS

#### 3.1 LOOPS
```yaml
- name: "Loop over list"
  ansible.builtin.debug:
    msg: "User: {{ item }}"
  loop:
    - alice
    - bob
    - charlie
```

**GIẢI THÍCH:**
- **`loop`**: Iterate over list
- **`{{ item }}`**: Current element
- **Output:**
  ```
  User: alice
  User: bob
  User: charlie
  ```

#### 3.2 LOOP WITH INDEX
```yaml
- name: "Loop with index"
  ansible.builtin.debug:
    msg: "Port {{ item.0 }} at position {{ item.1 }}"
  loop: "{{ ports | flatten(levels=1) }}"
```

**GIẢI THÍCH:**
- **`item.0`**: Port value
- **`item.1`**: Index position

#### 3.3 CONDITIONAL EXECUTION (WHEN)
```yaml
- name: "Run only in production"
  ansible.builtin.debug:
    msg: "This is production!"
  when: environment == "production"
```

**GIẢI THÍCH:**
- **`when`**: Conditional statement
- **Boolean expression**

#### 3.4 MULTIPLE CONDITIONS
```yaml
- name: "Multiple conditions"
  ansible.builtin.debug:
    msg: "All met"
  when:
    - enable_feature | default(false)
    - environment == "production"
```

**GIẢI THÍCH:**
- **AND**: List of conditions
- **`| default(false)`**: Fallback value

#### 3.5 FAILED_WHEN
```yaml
- name: "Check required var"
  ansible.builtin.debug:
    msg: "Checking"
  failed_when: required_var is not defined
```

**GIẢI THÍCH:**
- **`failed_when`**: Custom failure condition
- **`is not defined`**: Test if variable undefined

---

### 📝 SECTION 4: AWS CONNECTION

#### 4.1 AWS CREDENTIALS
```yaml
environment:
  AWS_ACCESS_KEY_ID: "{{ lookup('env', 'AWS_ACCESS_KEY_ID') }}"
  AWS_SECRET_ACCESS_KEY: "{{ lookup('env', 'AWS_SECRET_ACCESS_KEY') }}"
  AWS_SESSION_TOKEN: "{{ lookup('env', 'AWS_SESSION_TOKEN') | default('') }}"
  AWS_DEFAULT_REGION: "{{ aws_region }}"
```

**GIẢI THÍCH:**
- **`lookup('env', 'VAR')`**: Read environment variable
- **Session token**: Optional (cho temporary credentials)

#### 4.2 USING AWS PROFILE
```yaml
- name: "Get caller info"
  amazon.aws.aws_caller_info:
    profile: "{{ aws_profile }}"
    region: "{{ aws_region }}"
  register: aws_info
```

**GIẢI THÍCH:**
- **`profile`**: AWS profile từ `~/.aws/credentials`
- **`register`**: Save output to variable

**~/.aws/credentials:**
```
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

---

### 📝 SECTION 5: EC2 INSTANCES

#### 5.1 CREATE KEY PAIR
```yaml
- name: "Create EC2 key pair"
  amazon.aws.ec2_key:
    name: "{{ key_name }}"
    region: "{{ aws_region }}"
    key_material: "{{ lookup('file', '~/.ssh/id_rsa.pub') }}"
```

**GIẢI THÍCH:**
- **`ec2_key`**: Module quản lý EC2 key pairs
- **`key_material`**: Public key content
- **`lookup('file', ...)`**: Read file from disk

#### 5.2 LAUNCH EC2 INSTANCES
```yaml
- name: "Launch EC2 instances"
  amazon.aws.ec2_instance:
    name: "web-{{ item }}{{ ansible_date_time.epoch }}"
    region: "{{ aws_region }}"
    key_name: "{{ key_name }}"
    instance_type: "{{ instance_type }}"
    image_id: "{{ ami_id }}"
    subnet_id: "{{ vpc_subnet_id }}"
    network:
      assign_public_ip: true
    user_data: |
      #!/bin/bash
      yum update -y
      yum install -y httpd
      systemctl start httpd
      echo "<h1>Hello from Ansible</h1>" > /var/www/html/index.html
    tags: "{{ tags }}"
    state: present
    count: 1
  loop: "{{ range(1, instance_count + 1) | list }}"
  register: ec2_instances
```

**GIẢI THÍCH:**
- **`name`**: Instance name (tag)
- **`instance_type`**: t3.micro, t3.small, etc.
- **`image_id`**: AMI ID
- **`user_data`**: Startup script (cloud-init)
- **`assign_public_ip: true`**: Public IP
- **`state: present`**: Create instance
- **`count`**: Số instances
- **`loop`**: Create multiple instances
- **`register`**: Save result

#### 5.3 WAIT FOR INSTANCES
```yaml
- name: "Wait for instances to be running"
  amazon.aws.ec2_instance_info:
    region: "{{ aws_region }}"
    instance_ids:
      - "{{ item.instance_ids[0] }}"
  register: instance_info
  until: instance_info.instances[0].state.name == "running"
  retries: 30
  delay: 10
```

**GIẢI THÍCH:**
- **`until`**: Condition để stop
- **`retries`**: Max attempts
- **`delay`**: Seconds giữa các attempts

---

### 📝 SECTION 6: VPC và NETWORKING

#### 6.1 CREATE VPC
```yaml
- name: "Create VPC"
  amazon.aws.ec2_vpc_net:
    name: "{{ vpc_name }}"
    cidr_block: "{{ vpc_cidr }}"
    region: "{{ aws_region }}"
    dns_hostnames: true
    dns_support: true
    tenancy: default
    state: present
  register: vpc_result
```

**GIẢI THÍCH:**
- **`cidr_block`**: IP range (e.g., 10.0.0.0/16)
- **`dns_hostnames`**: Enable DNS hostnames
- **`tenancy`**: default hoặc dedicated

**Access VPC ID:**
```yaml
"{{ vpc_result.vpc.id }}"
```

#### 6.2 INTERNET GATEWAY
```yaml
- name: "Create Internet Gateway"
  amazon.aws.ec2_vpc_igw:
    vpc_id: "{{ vpc_result.vpc.id }}"
    region: "{{ aws_region }}"
    state: present
  register: igw_result
```

**GIẢI THÍCH:**
- **`igw`**: Internet Gateway (cho public internet access)
- **Attach to VPC**

#### 6.3 SUBNETS
```yaml
- name: "Create public subnets"
  amazon.aws.ec2_vpc_subnet:
    vpc_id: "{{ vpc_result.vpc.id }}"
    region: "{{ aws_region }}"
    cidr: "{{ item.cidr }}"
    az: "{{ item.az }}"
    state: present
    tags:
      Type: public
  loop:
    - { cidr: 10.0.1.0/24, az: us-east-1a }
    - { cidr: 10.0.2.0/24, az: us-east-1b }
```

**GIẢI THÍCH:**
- **`cidr`**: Subnet CIDR (e.g., 10.0.1.0/24)
- **`az`**: Availability Zone

**Subnet types:**
- **Public**: Has route to IGW
- **Private**: No route to IGW (use NAT)
- **Database**: Isolated subnet

#### 6.4 NAT GATEWAY
```yaml
- name: "Allocate Elastic IP"
  amazon.aws.ec2_eip:
    region: "{{ aws_region }}"
    in_vpc: true
    state: present
  register: eip_nat

- name: "Create NAT Gateway"
  amazon.aws.ec2_vpc_nat_gateway:
    region: "{{ aws_region }}"
    subnet_id: "{{ public_subnet_id }}"
    eip_address: "{{ eip_nat.public_ip }}"
    state: present
```

**GIẢI THÍCH:**
- **NAT Gateway**: Cho phép private subnets access internet
- **EIP**: Static IP address
- **Must be in public subnet**

#### 6.5 ROUTE TABLES
```yaml
- name: "Create public route table"
  amazon.aws.ec2_vpc_route_table:
    vpc_id: "{{ vpc_result.vpc.id }}"
    region: "{{ aws_region }}"
    tags:
      Name: public-rt
    subnets:
      - "{{ public_subnet_1 }}"
      - "{{ public_subnet_2 }}"
    routes:
      - dest: 0.0.0.0/0
        gateway_id: "{{ igw_result.gateway_id }}"
```

**GIẢI THÍCH:**
- **`dest`**: Destination CIDR (0.0.0.0/0 = all traffic)
- **`gateway_id`**: Target gateway (IGW for public, NAT for private)
- **`subnets`**: Associate subnets

---

### 📝 SECTION 7: SECURITY GROUPS

```yaml
- name: "Create security group for web"
  amazon.aws.ec2_security_group:
    name: web-sg
    description: "Security group for web servers"
    vpc_id: "{{ vpc_id }}"
    region: "{{ aws_region }}"
    rules:
      - proto: tcp
        ports:
          - 80
          - 443
        cidr_ip: 0.0.0.0/0
        rule_desc: "Allow HTTP/HTTPS"
      - proto: tcp
        ports:
          - 22
        cidr_ip: 10.0.0.0/16
        rule_desc: "Allow SSH from VPC"
    tags:
      Name: web-sg
```

**GIẢI THÍCH:**
- **`rules`**: Inbound rules
- **`proto`**: Protocol (tcp, udp, icmp, -1 for all)
- **`ports`**: Port list
- **`cidr_ip`**: Source IP range
- **`rule_desc`**: Description

**Best practice:**
- Restrict SSH to specific IPs
- Use security group references instead of CIDR when possible

---

### 📝 SECTION 8: S3 BUCKETS

#### 8.1 CREATE BUCKET
```yaml
- name: "Create S3 bucket"
  amazon.aws.s3_bucket:
    name: "{{ bucket_name }}"
    region: "{{ aws_region }}"
    state: present
    tags:
      Environment: dev
    encryption: AES256
    versioning: true
    public_access:
      BlockPublicAcls: true
      IgnorePublicAcls: true
```

**GIẢI THÍCH:**
- **`encryption`**: Server-side encryption
- **`versioning`**: Enable versioning (keep multiple versions)
- **`public_access`**: Security settings

#### 8.2 UPLOAD FILE
```yaml
- name: "Upload file to S3"
  amazon.aws.s3_object:
    bucket: "{{ bucket_name }}"
    region: "{{ aws_region }}"
    object: /config/app-config.yaml
    src: /tmp/app-config.yaml
    mode: put
```

**GIẢI THÍCH:**
- **`object`**: S3 key (path)
- **`src`**: Local file path
- **`mode: put`**: Upload mode

#### 8.3 DOWNLOAD FILE
```yaml
- name: "Download file from S3"
  amazon.aws.s3_object:
    bucket: "{{ bucket_name }}"
    region: "{{ aws_region }}"
    object: /config/app-config.yaml
    dest: /tmp/downloaded-config.yaml
    mode: get
```

**GIẢI THÍCH:**
- **`dest`**: Local destination
- **`mode: get`**: Download mode

#### 8.4 PRESIGNED URL
```yaml
- name: "Generate presigned URL"
  amazon.aws.s3_object:
    bucket: "{{ bucket_name }}"
    region: "{{ aws_region }}"
    object: /public/file.txt
    expiry: 3600
    mode: geturl
```

**GIẢI THÍCH:**
- **`expiry`**: Seconds until URL expires
- **`mode: geturl`**: Generate URL
- **Use case**: Share private files temporarily

---

### 📝 SECTION 9: RDS DATABASES

```yaml
- name: "Create RDS MySQL instance"
  community.aws.rds_instance:
    id: "{{ db_instance_id }}"
    region: "{{ aws_region }}"
    engine: mysql
    engine_version: 8.0
    instance_class: db.t3.micro
    allocated_storage: 20
    storage_encrypted: true
    db_name: appdb
    username: admin
    password: "{{ db_password }}"
    port: 3306
    vpc_security_group_ids:
      - sg-xxxxxxxx
    publicly_accessible: false
    backup_retention_period: 7
    skip_final_snapshot: false
    state: present
```

**GIẢI THÍCH:**
- **`engine`**: mysql, postgres, etc.
- **`instance_class`**: db.t3.micro, db.t3.small, etc.
- **`storage_encrypted`**: Enable encryption
- **`publicly_accessible: false`**: Private database
- **`backup_retention_period`**: Days to keep backups

**Wait for RDS:**
```yaml
- name: "Wait for RDS to be available"
  community.aws.rds_instance_info:
    region: "{{ aws_region }}"
    db_instance_identifier: "{{ db_instance_id }}"
  register: rds_info
  until: rds_info.instances[0].db_instance_status == "available"
  retries: 60
  delay: 30
```

---

### 📝 SECTION 10: LAMBDA FUNCTIONS

#### 10.1 CREATE IAM ROLE
```yaml
- name: "Create Lambda IAM role"
  amazon.aws.iam_role:
    name: lambda-role
    assume_role_policy_document:
      Version: "2012-10-17"
      Statement:
        - Effect: Allow
          Principal:
            Service: lambda.amazonaws.com
          Action: sts:AssumeRole
    managed_policies:
      - arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
    state: present
  register: lambda_role
```

**GIẢI THÍCH:**
- **`assume_role_policy_document`**: Trust policy
- **`managed_policies`**: Attach managed policies

#### 10.2 CREATE LAMBDA FUNCTION
```yaml
- name: "Create Lambda function"
  community.aws.lambda_function:
    name: "{{ function_name }}"
    region: "{{ aws_region }}"
    state: present
    runtime: python3.11
    handler: index.lambda_handler
    timeout: 3
    memory_size: 128
    role: "{{ lambda_role.arn }}"
    zip_file: /tmp/lambda_function.zip
    environment_variables:
      ENVIRONMENT: dev
```

**GIẢI THÍCH:**
- **`runtime`**: python3.11, nodejs20.x, etc.
- **`handler`**: `filename.function_name`
- **`timeout`**: Max execution time (seconds)
- **`memory_size`**: MB (128-10240)
- **`zip_file`**: Deployment package

---

### 📝 SECTION 11: AUTO SCALING GROUPS

#### 11.1 CREATE LAUNCH TEMPLATE
```yaml
- name: "Create launch template"
  amazon.aws.ec2_launch_template:
    name: "{{ lc_name }}"
    region: "{{ aws_region }}"
    image_id: "{{ ami_id }}"
    instance_type: "{{ instance_type }}"
    key_name: "{{ key_name }}"
    monitoring:
      enabled: true
    network_interfaces:
      - device_index: 0
        associate_public_ip_address: true
    state: present
  register: launch_template
```

**GIẢI THÍCH:**
- **Launch template**: Configuration cho EC2 instances in ASG
- **Reusability**: ASG uses template to launch instances

#### 11.2 CREATE ASG
```yaml
- name: "Create auto scaling group"
  amazon.aws.autoscaling_group:
    name: "{{ asg_name }}"
    region: "{{ aws_region }}"
    launch_template:
      id: "{{ launch_template.launch_template_id }}"
      version: "$Latest"
    min_size: 2
    max_size: 4
    desired_capacity: 2
    vpc_zone_identifier:
      - subnet-xxxxxxxx
      - subnet-yyyyyyyy
    health_check_period: 300
    health_check_type: ELB
    state: present
```

**GIẢI THÍCH:**
- **`min_size`**: Minimum instances
- **`max_size`**: Maximum instances
- **`desired_capacity`**: Target instances
- **`vpc_zone_identifier`**: List of subnet IDs

#### 11.3 SCALING POLICIES
```yaml
- name: "Create scale-up policy"
  amazon.aws.autoscaling_policy:
    state: present
    region: "{{ aws_region }}"
    asg_name: "{{ asg_name }}"
    name: scale-up
    adjustment_type: ChangeInCapacity
    scaling_adjustment: 1
    cooldown: 300
```

**GIẢI THÍCH:**
- **`adjustment_type`**: ChangeInCapacity, ExactCapacity, PercentChangeInCapacity
- **`scaling_adjustment`**: Số instances to add/remove
- **`cooldown`**: Seconds giữa các scaling actions

---

### 📝 SECTION 12: CLOUDWATCH MONITORING

#### 12.1 CREATE ALARM
```yaml
- name: "Create CPU alarm"
  amazon.aws.cloudwatch_metric_alarm:
    state: present
    region: "{{ aws_region }}"
    name: "high-cpu-{{ instance_id }}"
    namespace: AWS/EC2
    metric: CPUUtilization
    statistic: Average
    period: 300
    evaluation_periods: 2
    threshold: 80.0
    comparison_operator: GreaterThanThreshold
    dimensions:
      InstanceId: "{{ instance_id }}"
```

**GIẢI THÍCH:**
- **`namespace`**: AWS/EC2, AWS/RDS, etc.
- **`metric`**: Metric name
- **`statistic`**: Average, Maximum, Minimum, Sum
- **`period`**: Seconds (300 = 5 minutes)
- **`threshold`**: Trigger value
- **`comparison_operator`**: GreaterThanThreshold, LessThanThreshold

#### 12.2 CREATE LOG GROUP
```yaml
- name: "Create log group"
  amazon.aws.cloudwatch_log_group:
    state: present
    region: "{{ aws_region }}"
    log_group_name: /ansible/app-logs
    retention: 14
```

**GIẢI THÍCH:**
- **`retention`**: Days to keep logs (1, 3, 5, 7, 14, 30, etc.)

---

### 📝 SECTION 13: IAM ROLES và POLICIES

#### 13.1 CREATE IAM ROLE
```yaml
- name: "Create IAM role"
  amazon.aws.iam_role:
    name: "{{ role_name }}"
    assume_role_policy_document:
      Version: "2012-10-17"
      Statement:
        - Effect: Allow
          Principal:
            Service: ec2.amazonaws.com
          Action: sts:AssumeRole
    managed_policies:
      - arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
    state: present
```

**GIẢI THÍCH:**
- **`assume_role_policy_document`**: Who can assume this role
- **`managed_policies`**: Attach AWS managed policies

#### 13.2 CREATE CUSTOM POLICY
```yaml
- name: "Create IAM policy"
  amazon.aws.iam_policy:
    policy_name: s3-access
    state: present
    policy:
      Version: "2012-10-17"
      Statement:
        - Effect: Allow
          Action:
            - s3:GetObject
            - s3:PutObject
            - s3:ListBucket
          Resource:
            - arn:aws:s3:::my-app-bucket
            - arn:aws:s3:::my-app-bucket/*
```

**GIẢI THÍCH:**
- **`Effect`**: Allow hoặc Deny
- **`Action`**: List of AWS actions
- **`Resource`**: ARN (Amazon Resource Name)

---

### 📝 SECTION 14: ANSIBLE VAULT

#### 14.1 ENCRYPT SECRETS
```bash
# Create new encrypted file
ansible-vault create secrets.yaml

# Encrypt existing file
ansible-vault encrypt secrets.yaml

# View encrypted file
ansible-vault view secrets.yaml

# Edit encrypted file
ansible-vault edit secrets.yaml
```

#### 14.2 USE ENCRYPTED VARIABLES
```yaml
vars_files:
  - encrypted_secrets.yaml

tasks:
  - name: "Use encrypted password"
    ansible.builtin.debug:
      msg: "DB Password: {{ db_password }}"
    no_log: true  # Don't log sensitive data
```

**GIẢI THÍCH:**
- **`vars_files`**: Load variables from file
- **`no_log: true`**: Hide from logs

---

### 📝 SECTION 15: HANDLERS

```yaml
handlers:
  - name: "Restart Apache"
    ansible.builtin.service:
      name: httpd
      state: restarted

  - name: "Reload Nginx"
    ansible.builtin.service:
      name: nginx
      state: reloaded

tasks:
  - name: "Update Apache config"
    ansible.builtin.copy:
      src: /files/httpd.conf
      dest: /etc/httpd/conf/httpd.conf
      backup: yes
    notify:
      - Restart Apache

  - name: "Force handler execution"
    ansible.builtin.meta: flush_handlers
```

**GIẢI THÍCH:**
- **`handlers`**: Definitions của các actions
- **`notify`**: Trigger handler(s) when task changes
- **`flush_handlers`**: Force execute handlers immediately

**Handlers特性:**
- Chạy khi task changes (changed = true)
- Chạy 1 lần dù được notify nhiều lần
- Chạy ở cuối playbook (trừ khi flush)

---

### 📝 SECTION 16: ERROR HANDLING

#### 16.1 BLOCKS
```yaml
- name: "Task with error handling"
  block:
    - name: "Risky task"
      ansible.builtin.command:
        cmd: /bin/false

    - name: "This won't run"
      ansible.builtin.debug:
        msg: "Skipped"

  rescue:
    - name: "Handle error"
      ansible.builtin.debug:
        msg: "Error occurred"

  always:
    - name: "Cleanup"
      ansible.builtin.debug:
        msg: "Always runs"
```

**GIẢI THÍCH:**
- **`block`**: Main tasks
- **`rescue`**: Error handler (như try-catch)
- **`always`**: Cleanup (luôn chạy)

#### 16.2 IGNORE ERRORS
```yaml
- name: "Task that might fail"
  ansible.builtin.command:
    cmd: /bin/true
  ignore_errors: true
  register: result

- name: "Check result"
  ansible.builtin.debug:
    msg: "Task succeeded"
  when: result is succeeded
```

**GIẢI THÍCH:**
- **`ignore_errors: true`**: Continue on failure
- **`is succeeded`**: Test if task succeeded

---

### 📝 SECTION 17: TEMPLATES

#### 17.1 CREATE TEMPLATE FILE
```jinja2
# /templates/app-config.j2
application:
  name: {{ app_name }}
  port: {{ app_port }}

database:
  host: {{ db_host }}
  port: {{ db_port }}

{% if enable_ssl %}
ssl_enabled: true
{% endif %}

generated_at: {{ ansible_date_time.iso8601 }}
```

#### 17.2 DEPLOY TEMPLATE
```yaml
- name: "Create config from template"
  ansible.builtin.template:
    src: /templates/app-config.j2
    dest: /tmp/app-config.yaml
    mode: '0644'
  vars:
    config_hash: "{{ ansible_date_time.epoch | hash('md5') }}"
```

**GIẢI THÍCH:**
- **`template`**: Module để deploy Jinja2 templates
- **`.j2`**: Jinja2 file extension
- **`| hash('md5')`**: Jinja2 filter

---

### 📝 SECTION 18: PARALLEL EXECUTION

#### 18.1 SERIAL EXECUTION
```yaml
- name: "Update one at a time"
  ansible.builtin.yum:
    name: "*"
    state: latest
  serial: 1
```

**GIẢI THÍCH:**
- **`serial: 1`**: Run on 1 host at a time
- **`serial: 25%`**: Run on 25% of hosts
- **`serial: "2..4"`**: Between 2-4 hosts

#### 18.2 ASYNC TASKS
```yaml
- name: "Long running task"
  ansible.builtin.yum:
    name: docker
    state: present
  async: 600
  poll: 10
  register: yum_result

- name: "Wait for async task"
  ansible.builtin.async_status:
    jid: "{{ yum_result.ansible_job_id }}"
  register: job_result
  until: job_result.finished
  retries: 60
  delay: 10
```

**GIẢI THÍCH:**
- **`async`**: Max runtime (seconds)
- **`poll`**: Check interval (0 = fire and forget)
- **`async_status`**: Check task status

---

### 📝 SECTION 19: BLUE-GREEN DEPLOYMENT

```yaml
- name: "Deploy to Green environment"
  amazon.aws.autoscaling_group:
    name: green-asg
    region: "{{ aws_region }}"
    desired_capacity: 3
    launch_template:
      id: lt-new-version
    state: present

- name: "Wait for Green to be healthy"
  ansible.builtin.pause:
    seconds: 60

- name: "Switch traffic to Green"
  community.aws.elb_classic_lb:
    name: production-lb
    region: "{{ aws_region }}"
    state: present
    instance_ids: "{{ green_instances }}"

- name: "Run smoke tests"
  ansible.builtin.uri:
    url: http://production.example.com/health
    status_code: 200
  register: smoke_test
  until: smoke_test.status == 200
  retries: 10
  delay: 5
```

**GIẢI THÍCH:**
- **Green ASG**: New version
- **Blue ASG**: Old version (kept for rollback)
- **Smoke tests**: Verify new deployment

---

### 📝 SECTION 20: DYNAMIC INVENTORY

#### 20.1 CREATE INVENTORY FILE
**File: aws_ec2.yaml**
```yaml
plugin: aws_ec2
regions:
  - us-east-1
  - us-west-2
keyed_groups:
  - key: tags.Environment
    prefix: env_
  - key: tags.Application
    prefix: app_
filters:
  instance-state-name: running
compose:
  ansible_host: public_ip_address
  ansible_user: ec2-user
```

**GIẢI THÍCH:**
- **`plugin: aws_ec2`**: AWS EC2 dynamic inventory plugin
- **`keyed_groups`**: Create groups from tags
- **`filters`**: Filter instances
- **`compose`**: Set ansible variables

#### 20.2 USE DYNAMIC INVENTORY
```yaml
- name: "Use dynamic inventory"
  hosts: tag_Environment_dev
  gather_facts: true

  tasks:
    - name: "Display instance info"
      ansible.builtin.debug:
        msg:
          - "Host: {{ inventory_hostname }}"
          - "IP: {{ ansible_default_ipv4.address }}"
```

**GIẢI THÍCH:**
- **`tag_Environment_dev`**: Host group từ dynamic inventory
- Ansible tự động tạo groups từ tags

**Run playbook:**
```bash
ansible-playbook -i aws_ec2.yaml playbook.yaml
```

---

### 📝 SECTION 21: ANSIBLE ROLES

#### 21.1 ROLE STRUCTURE
```
roles/
└── webapp/
    ├── tasks/
    │   └── main.yml          # Tasks
    ├── handlers/
    │   └── main.yml          # Handlers
    ├── files/
    │   └── config.conf       # Static files
    ├── templates/
    │   └── app.conf.j2       # Templates
    ├── vars/
    │   └── main.yml          # Variables (high priority)
    ├── defaults/
    │   └── main.yml          # Default variables (low priority)
    ├── meta/
    │   └── main.yml          # Role metadata
    └── README.md
```

#### 21.2 USE ROLE
```yaml
- name: "Use roles"
  hosts: webservers
  become: true

  roles:
    - role: geerlingguy.apache  # External role
      vars:
        apache_listen_port: 80

    - role: ./roles/webapp     # Local role
      vars:
        app_version: 2.0.0
```

**GIẢI THÍCH:**
- **External roles**: Từ Ansible Galaxy
- **Local roles**: Tự tạo

**Install role from Galaxy:**
```bash
ansible-galaxy install geerlingguy.apache
```

---

### 📝 SECTION 22: NOTIFICATIONS

#### 22.1 SLACK
```yaml
- name: "Send Slack notification"
  ansible.builtin.slack:
    token: "{{ slack_token }}"
    channel: "#ops"
    msg: |
      ✅ Deployment completed!
      App: {{ app_name }}
      Version: {{ app_version }}
    username: "Ansible Bot"
    icon_emoji: ":rocket:"
    color: "good"
```

**GIẢI THÍCH:**
- **`color`**: good (green), warning (yellow), danger (red)
- **`msg`**: Message (supports multiline)

#### 22.2 EMAIL (AWS SES)
```yaml
- name: "Send email"
  community.aws.ses:
    from: "ansible@mycompany.com"
    to:
      - ops-team@mycompany.com
    subject: "Deployment Report"
    body: |
      Deployment completed successfully!
      Version: {{ app_version }}
    charset: utf-8
```

#### 22.3 MICROSOFT TEAMS
```yaml
- name: "Send to Teams"
  ansible.builtin.uri:
    url: "{{ teams_webhook }}"
    method: POST
    body_format: json
    body:
      "@type": "MessageCard"
      "@context": "https://schema.org/extensions"
      summary: "Deployment Report"
      themeColor: "0078D7"
      title: "Ansible Deployment"
      text: "Deployment completed"
    status_code: [201, 200]
```

---

### 📝 SECTION 23: SECURITY HARDENING

```yaml
- name: "SSH hardening"
  become: true
  handlers:
    - name: "Restart SSH"
      ansible.builtin.service:
        name: sshd
        state: restarted

  tasks:
    - name: "Disable password authentication"
      ansible.builtin.lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^PasswordAuthentication'
        line: 'PasswordAuthentication no'
      notify: Restart SSH

    - name: "Disable root login"
      ansible.builtin.lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^PermitRootLogin'
        line: 'PermitRootLogin no'
      notify: Restart SSH

    - name: "Configure firewall"
      ansible.builtin.firewalld:
        service: "{{ item }}"
        permanent: true
        state: enabled
      loop:
        - http
        - https
        - ssh
```

**GIẢI THÍCH:**
- **`lineinfile`**: Ensure line exists in file
- **`regexp`**: Pattern to match
- **`firewalld`**: Configure firewall (RHEL/CentOS)

---

### 📝 SECTION 24: BACKUP và RESTORE

```yaml
- name: "Create RDS snapshot"
  community.aws.rds_instance_snapshot:
    db_instance_identifier: myapp-db
    snapshot_identifier: "myapp-db-{{ ansible_date_time.iso8601 | replace(':', '-') }}"
    region: "{{ aws_region }}"
    state: present

- name: "Configure S3 lifecycle"
  amazon.aws.s3_lifecycle:
    name: my-backup-bucket
    region: "{{ aws_region }}"
    state: present
    rules:
      - id: "Archive-old-backups"
        prefix: "backups/"
        status: enabled
        transitions:
          - days: 30
            storage_class: GLACIER
          - days: 90
            storage_class: DEEP_ARCHIVE
```

**GIẢI THÍCH:**
- **Snapshot**: Point-in-time backup
- **Lifecycle policy**: Auto transition to cheaper storage

---

### 📝 SECTION 25: MULTI-REGION DEPLOYMENT

```yaml
- name: "Deploy to multiple regions"
  vars:
    regions:
      - us-east-1
      - us-west-2
      - eu-west-1

  tasks:
    - name: "Deploy across regions"
      include_tasks: deploy-to-region.yaml
      loop: "{{ regions }}"
      loop_control:
        loop_var: target_region
```

**GIẢI THÍCH:**
- **`include_tasks`**: Include external task file
- **`loop_var`**: Variable name for loop item

**deploy-to-region.yaml:**
```yaml
- name: "Launch instance in {{ target_region }}"
  amazon.aws.ec2_instance:
    region: "{{ target_region }}"
    # ...
```

---

### 📝 SECTION 26: PERFORMANCE TIPS

#### 26.1 FACT CACHING
**ansible.cfg:**
```ini
[defaults]
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts
fact_caching_timeout = 86400
```

**GIẢI THÍCH:**
- **Cache facts** để giảm time on subsequent runs
- **TTL**: 24 hours

#### 26.2 PIPELINING
**ansible.cfg:**
```ini
[ssh_connection]
pipelining = True
```

**GIẢI THÍCH:**
- **Pipelining**: Reduce SSH connections
- **Faster execution**

#### 26.3 DELEGATION
```yaml
- name: "Run on localhost"
  ansible.builtin.command:
    cmd: docker build -t myapp .
  delegate_to: localhost
  run_once: true
```

**GIẢI THÍCH:**
- **`delegate_to`**: Run on specific host
- **`run_once`**: Execute only once

---

### 🎯 ANSIBLE BEST PRACTICES

#### 1. IDempOTENCE
```yaml
# ❌ BAD: Not idempotent
- name: "Always restart"
  ansible.builtin.service:
    name: httpd
    state: restarted

# ✅ GOOD: Idempotent
- name: "Restart only if needed"
  ansible.builtin.service:
    name: httpd
    state: started
  notify: Restart Apache
```

#### 2. USE HANDLERS
```yaml
# ✅ Multiple changes → 1 restart
- name: "Update config"
  ansible.builtin.copy:
    src: config1.conf
    dest: /etc/myapp/config1.conf
  notify: Restart App

- name: "Update another config"
  ansible.builtin.copy:
    src: config2.conf
    dest: /etc/myapp/config2.conf
  notify: Restart App
```

#### 3. VARIABLES IN FILES
```yaml
# group_vars/production.yaml
app_version: "2.0.0"
db_host: "prod-db.example.com"

# playbook.yaml
- hosts: webservers
  roles:
    - webapp
  vars_files:
    - group_vars/production.yaml
```

#### 4. USE TAGS
```yaml
- name: "Deploy app"
  hosts: webservers
  # ...

  tasks:
    - name: "Install packages"
      ansible.builtin.yum:
        name: httpd
        state: present
      tags:
        - packages

    - name: "Configure app"
      ansible.builtin.template:
        src: app.conf.j2
        dest: /etc/myapp/app.conf
      tags:
        - config
```

**Run specific tags:**
```bash
ansible-playbook playbook.yaml --tags packages
ansible-playbook playbook.yaml --skip-tags config
```

---

### 📚 ANSIBLE MODULES REFERENCE

#### COMMON MODULES

**Builtin modules:**
```
ansible.builtin.debug         → Print messages
ansible.builtin.command       → Run commands
ansible.builtin.shell         → Run commands in shell
ansible.builtin.copy          → Copy files
ansible.builtin.template      → Deploy templates
ansible.builtin.service       → Manage services
ansible.builtin.systemd       → Manage systemd
ansible.builtin.user          → Manage users
ansible.builtin.lineinfile    → Modify file lines
ansible.builtin.blockinfile   → Add/remove blocks
ansible.builtin.file          → Manage files/directories
ansible.builtin.uri           → HTTP requests
ansible.builtin.slack         → Slack notifications
```

**AWS modules (amazon.aws collection):**
```
amazon.aws.ec2_instance           → EC2 instances
amazon.aws.ec2_vpc_net            → VPC
amazon.aws.ec2_security_group     → Security groups
amazon.aws.s3_bucket              → S3 buckets
amazon.aws.s3_object              → S3 objects
amazon.aws.iam_role               → IAM roles
amazon.aws.iam_policy             → IAM policies
amazon.aws.cloudwatch_metric_alarm → CloudWatch alarms
```

**AWS modules (community.aws collection):**
```
community.aws.rds_instance        → RDS instances
community.aws.lambda_function     → Lambda functions
community.aws.ecs_service         → ECS services
```

---

## 📚 TÀI LIỆU THAM KHẢO:

- **Docker Docs**: https://docs.docker.com/
- **CIS Benchmark**: https://www.cisecurity.org/benchmark/docker
- **OCI Spec**: https://github.com/opencontainers/image-spec
- **Kubernetes Docs**: https://kubernetes.io/docs/
- **Seccomp**: https://docs.kernel.org/userspace-api/seccomp.html
- **AppArmor**: https://gitlab.com/apparmor/apparmor
- **Jenkins Official Docs**: https://www.jenkins.io/doc/
- **Jenkins Pipeline Syntax**: https://www.jenkins.io/doc/book/pipeline/syntax/
- **Terraform Docs**: https://developer.hashicorp.com/terraform/docs
- **Terraform Registry**: https://registry.terraform.io/

---

**FILE NÀY ĐÃ GIẢI THÍCH TẤT CẢ TỪNG DÒNG CODE!** 🎉
