# 기본 이미지로 Python 3.10 사용
FROM python:3.10

# 작업 디렉터리 설정
WORKDIR /backend
# Python이 백엔드 경로를 기본 경로로 인식하도록 환경 변수에 추가
ENV PYTHONPATH=/backend
# 현재 디렉터리의 모든 파일을 컨테이너의 /backend 디렉터리로 복사
COPY . /backend

# pip 업그레이드 및 의존성 설치 : OpenCV나 다른 패키지에서 필요할 수 있는 라이브러리 설치
RUN pip install --no-cache-dir --upgrade pip && pip install --no-cache-dir -r requirements.txt
RUN apt-get update && apt-get install libgl1-mesa-glx -y

# 컨테이너를 실행할 때 사용될 명령 설정
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
