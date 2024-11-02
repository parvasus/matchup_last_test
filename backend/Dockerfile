# 기본 이미지로 Python 3.10 사용
#       FROM python:3.10

# 현재 디렉터리의 모든 파일을 컨테이너의 /backend 디렉터리로 복사
#       COPY . /backend

# 작업 디렉터리 설정
#       WORKDIR /backend

# Python이 백엔드 경로를 기본 경로로 인식도록 환경변수에 추가
# 이전 버전 But,
# ENV PYTHONPATH=/backend

# pip 업그레이드 및 의존성 설치
#       RUN pip install --no-cache-dir --upgrade pip && pip install --no-cache-dir -r requirements.txt

#       RUN apt-get update && apt-get install libgl1-mesa-glx -y

# 컨테이너를 실행할 때 사용될 명령 설정 (예시로 gunicorn을 사용하여 FastAPI 서버 실행)
#       CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
#############################################
FROM python:3.10

# 작업 디렉터리 설정
WORKDIR /backend

# 의존성 파일만 먼저 복사하고 설치
COPY requirements.txt .
# requirements.txt만 복사
RUN pip install --no-cache-dir --upgrade pip && pip install --no-cache-dir -r requirements.txt

# 나머지 모든 파일을 복사
COPY . .

# Python이 백엔드 경로를 기본 경로로 인식하도록 환경변수에 추가
ENV PYTHONPATH=/backend

# 필요한 추가 패키지 설치
RUN apt-get update && apt-get install -y libgl1-mesa-glx && rm -rf /var/lib/apt/lists/*

# 컨테이너를 실행할 때 사용될 명령 설정 (예시로 uvicorn을 사용하여 FastAPI 서버 실행)
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
