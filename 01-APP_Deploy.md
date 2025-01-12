# Webアプリケーションのデプロイ
- AWS環境構築をcloudformationテンプレートを作成し、スタックの作成にて実施する。
- 自作したCRUDアプリケーションをAWS環境に手動でデプロイする。
- 組み込みサーバで動作確認後、アプリケーションサーバとWEBサーバに分離する。

## AWS環境構築
### 構成図
![image](/01-APP_Deploy_Figure/figure.png)  <br>

### CFnテンプレート
Network
VPC

Security
SG

Application
EC2
RDS
Route

## アプリケーションデプロイ

### ⅰ APP-SV
APPサーバへの設定
### 01_Initial
#### 1 yum update
~~~
sudo yum update -y
~~~

#### 2 Install-Dep-Packages
必要パッケージのインストール
~~~
sudo yum install -y git gcc openssl11 openssl11-devel bzip2-devel ncurses-devel libffi-devel readline-devel sqlite-devel.x86_64 xz-devel
~~~

### 02 pyenv-install
#### 1 clone pyenv
~~~
git clone https://github.com/pyenv/pyenv.git ~/.pyenv
~~~

#### 2 Passing by pyenv
pyenv利用のためパスを通す
##### 2-1 Add pyenv to the PATH
~~~
echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> ~/.bashrc
~~~

##### 2-2 Add the pyenv init the shell
~~~
echo 'eval "$(pyenv init -)"' >> ~/.bashrc
~~~

##### 2-3 Run source ~/.bashrc
~~~
source ~/.bashrc
~~~

### 03_Python-install
pythonインストール
#### 1 pyenv install
~~~
pyenv install 3.12.1
~~~
#### 2 pyenv global set
~~~
pyenv global 3.12.1
~~~
#### 3 pyenv version check
~~~
pyenv versions
~~~

#### 4_Poetry install
poetryインストール
~~~
curl -sSL https://install.python-poetry.org | python3 - --version 1.8.4
~~~
#### 5 Poetry install check
~~~
poetry --version
~~~

### 04_Application-install
サンプルアプリケーションのインストール
#### 1 clone application
~~~
git clone https://github.com/tomi050403/flask-app.git
~~~

### 05_Application-setup
#### 1 move directory
プロジェクトディレクトリへ移動
~~~
cd flask-app
~~~

#### 2 Setup env file
サンプルアプリケーション用の.envファイル作成
~~~
nano flaskr/.env
~~~

#### 3 export FLASK_APP
環境変数:FLASK_APPにアプリケーション名を設定
~~~
export FLASK_APP=flaskr
~~~

#### 4 poetry install
~~~
poetry install
~~~

#### 5 poetry shell
~~~
poetry shell
~~~

#### 6 frusk-run
flask runコマンドでアプリケーション動作確認
~~~
flask run -h 0.0.0.0
~~~

## Flask接続確認
### CFnにて作成したAppServerのパブリックIPを確認。
![image](/01-APP_Deploy_Figure/01_app_ip.png)  <br>
### EC2Appにブラウザ接続し、起動出来ていることを確認
![image](/01-APP_Deploy_Figure/02_app_flaskrun.png)  <br>


続けてapサーバとwebサーバを分離する。

### 06_Set-up-gunicorn
#### 1 gunicorn install
gunicornのインストール
~~~
poetry add gunicorn
~~~

#### 2 gnicorn run
アプリケーションの起動
~~~
gunicorn -b 0.0.0.0 flaskr:app
~~~

### ⅱ WEB-SV
WEBサーバへの設定
### 01 set-up-websv
#### 1 nginx install
~~~
sudo amazon-linux-extras install -y nginx1
~~~

#### 2 set up nginx config
nginx設定ファイルの作成
~~~
sudo nano /etc/nginx/conf.d/flask-app.conf
~~~

#### 3 Start nginx
nginx起動
~~~
sudo systemctl start nginx.service
~~~

## Gunicorn接続確認
### CFnにて作成されたALB DNS名を確認
![image](/01-APP_Deploy_Figure/03_FLASK-APP-ALB.png)  <br>
### ブラウザ接続し、ALB経由で起動出来ていることを確認
![image](/01-APP_Deploy_Figure/04_gunicorn-run.png)  <br>