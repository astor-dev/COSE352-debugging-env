FROM ubuntu:24.04

# Ubuntu 패키지 저장소를 Kakao 미러로 변경
RUN sed -i 's|archive.ubuntu.com|mirror.kakao.com|g' /etc/apt/sources.list

# 필수 패키지 설치
RUN apt update && apt install -y --no-install-recommends \
    software-properties-common curl \
    build-essential cmake g++ \
    libssl-dev libbz2-dev libreadline-dev libsqlite3-dev \
    libffi-dev zlib1g-dev libncurses5-dev libncursesw5-dev \
    xz-utils tk-dev pkg-config \
    libzmq3-dev \
    gcc g++ make \
    && apt clean && rm -rf /var/lib/apt/lists/*

# Python 3.12.3 소스 다운로드 및 빌드
RUN curl -fSL "https://www.python.org/ftp/python/3.12.3/Python-3.12.3.tgz" -o Python-3.12.3.tgz \
    && tar -xzf Python-3.12.3.tgz \
    && cd Python-3.12.3 \
    && ./configure --enable-optimizations --with-ensurepip=install --enable-shared \
    && make -j$(nproc) \
    && make altinstall \
    && cd .. && rm -rf Python-3.12.3 Python-3.12.3.tgz

# Python3 심볼릭 링크 생성
RUN ln -s /usr/local/bin/python3.12 /usr/local/bin/python3

# /usr/local/lib를 시스템 라이브러리 경로에 추가 및 ldconfig 실행
RUN echo "/usr/local/lib" > /etc/ld.so.conf.d/python3.12.conf && ldconfig

# 공유 라이브러리 경로 설정
ENV LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"

# venv를 /opt/venv에 생성
RUN /usr/local/bin/python3.12 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# venv 안에 설치
RUN /opt/venv/bin/pip install --no-cache-dir --upgrade pip setuptools wheel && \
    /opt/venv/bin/pip install --no-cache-dir notebook==6.5.7

# 작업 디렉토리 설정
WORKDIR /workspace

# Jupyter Notebook 실행
CMD ["/opt/venv/bin/jupyter", "notebook", "--ip=0.0.0.0", "--port=8888", "--allow-root", "--NotebookApp.token=''", "--NotebookApp.password=''"]