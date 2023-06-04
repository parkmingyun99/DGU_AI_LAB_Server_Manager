#!/bin/bash

echo "hello entrypoint!"

# readme 안내문 생성
if [ ! -f /home/decs/readme_decs.txt ]; then
    echo "Hello, Decs" > /home/decs/readme_decs.txt
fi

# jupyter_lab 파일을 저장할 폴더가 없는 경우, 생성
if [ ! -d "/home/decs/decs_jupyter_lab" ]; then
  mkdir -p /home/decs/decs_jupyter_lab
  echo "Created /home/decs/decs_jupyter_lab directory."
fi
# jupyter_lab 기동
echo "trying jupyter lab..."
nohup /opt/anaconda3/bin/jupyter lab --NotebookApp.token=decs --config=/jupyter_config/jupyter_notebook_config.py >/dev/null 2>&1 &
echo "jupyter lab listening!"

# xrdp의 터미널이 안켜지는 오류 자동 해결 : 터미널로 xface 를 선택
# update-alternatives --set x-terminal-emulator /usr/bin/xfce4-terminal

# xrdp를 자동으로 시작
# service xrdp-sesman start
# service xrdp start


# 재시작 오류를 자동으로 해결
pid_file="/var/run/xrdp/xrdp.pid"
if [ -f "$pid_file" ]; then
    rm -f "$pid_file"
fi
sesman_file="/var/run/xrdp/xrdp-sesman.pid"
if [ -f "$sesman_file" ]; then
    rm -f "$sesman_file"
fi

#decs 를 사용자가 입력한 id 로 변경(가장 마지막에 수행되어야함.)

if ! id "$USER_ID" >/dev/null 2>&1; then
    echo "No User account detected..."

    # 유저 계정을 생성, 홈폴더는 decs폴더로 설정
    useradd -s /bin/bash -M "$USER_ID"
    
    # 홈폴더 생성
    # skeleton 파일을 복사하여, 유저명이 tf-docker 로 표시되는 것을 방지
    cp -R /etc/skel/. "/home/decs"
    usermod -d /home/decs "$USER_ID"

    # 입력받은 비밀번호로 유저 계정 변경
    echo "$USER_ID:$USER_PW" | chpasswd

    echo "user account config done..."

    # sshd 설정도 바꾼다.
    # 서버관리자와 유저계정의 ssh 접속을 허용
    sed -i "/^#PermitRootLogin/a AllowUsers svmanager" /etc/ssh/sshd_config
    sed -i "/^#PermitRootLogin/a AllowUsers $USER_ID" /etc/ssh/sshd_config
    service ssh restart
    echo "ssh change done..."

    # decs 폴더의 소유자를 유저로 변경. 시간이 약간 소요됨(재귀로 decs의 모든 파일의 권한을 변경한다.)
    chown -R "$USER_ID:$USER_ID" /home/decs

    # sudo docker logs [container_name] 으로 로그 확인 가능
    echo "decs chown change done..."

fi


#entrypoint.sh 를 실행하고 나서 컨테이너가 Exit 하지 않게함
tail -F /dev/null