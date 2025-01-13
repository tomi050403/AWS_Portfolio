# Webアプリケーションのデプロイ
- AWS環境構築をcloudformationテンプレートを作成し、スタックの作成にて実施する。
- 自作したCRUDアプリケーションをAWS環境に手動でデプロイする。
- 組み込みサーバで動作確認後、アプリケーションサーバとWEBサーバに分離する。

# AWS環境構築
## 構成図
![構成図](/01-APP_Deploy_Figure/figure.png)  <br>

# CFnテンプレート
上記構成図をレイヤー毎に分割することを意識し、３分割してクロススタックにて作成。<br>
cloudformationからスタックにて下記の順番で作成する。<br>

## 1,Network

---

[Networkスタック](/01-APP_Deploy_CfnTemplate/Flask-APP_01_Network.yml)<br>
Parametersにて下記項目の設定変更が可能<br>

|設定項目|デフォルト|
| :--- | :--- |
|VPC CIDR|10.10.0.0/16|
|PublicSubnet1 CIDR|10.10.1.0/24|
|PublicSubnet2 CIDR|10.10.2.0/24|
|PrivateSubnet1 CIDR|10.10.11.0/24|
|PrivateSubnet2 CIDR|10.10.12.0/24|

|作成リソース一覧|備考|
| :--- | :--- |
|VPC||
|InternetGateway||
|PublicSubnet1||
|PublicSubnet2||
|PrivateSubnet1||
|PrivateSubnet2||
|RDSSubnetGroup||
|PublicRouteTable||
|DefaultPublicRoute||
|HostZone|EC2WEB→EC2APPの名前解決のため|

## 2,Security

---

[Securityスタック](/01-APP_Deploy_CfnTemplate/Flask-APP_02_Security.yml)  <br>
Parametersで一部のSG(SecurityGroup)の送信元IPを設定可能<br>

|設定項目|デフォルト|備考|
| :--- | :--- | :--- |
|APPAllowedIP|0.0.0.0/0|アプリケーション接続用。必要に応じて設定|
|EC2SSHAllowedIP|0.0.0.0/0|EC2WEB,EC2APPへのssh接続用。基本的に自IPのみに絞る|

|作成リソース一覧|用途|許可設定|
| :--- | :--- | :--- |
|ALBSG|ALB適用|APPAllowedIPからのtcp,80|
|EC2WEBSG|EC2WEB適用|ALBSGからのtcp,80　EC2SSHAllowedIPからのssh|
|EC2APPSG|EC2APP適用|EC2WEBSGからのtcp,5000および8000 80　EC2SSHAllowedIPからのssh|
|RDSSG|RDS適用|EC2APPSGからの3306|

## 3,Application

---

[Applicationスタック](01-APP_Deploy_CfnTemplate/Flask-APP_03_Application.yml)<br>

Parametersで各EC2のAMIおよびKeyPairを設定<br>

|設定項目|デフォルト|備考|
| :--- | :--- | :--- |
|EC2AppImageID|最新版指定||
|EC2WebImageID|最新版指定||
|EC2Keypair|-|作成済みのものをプルダウンにて指定|

|作成リソース一覧|備考|
| :--- | :--- |
|EC2WEB||
|EC2APP||
|ALB||
|RecordSet|EC2WEB→EC2APPの名前解決のため|

## 4,Application(RDS)

---

[Application_RDSスタック](01-APP_Deploy_CfnTemplate/Flask-APP_04_Application_RDS.yml)<br>
RDSのみスタック実行時間を要するため分離。<br>
cfn-lint（コードを精査して、そのコードを実行したときにエラーを発生させる可能性のある構文エラーやバグがないかを探すプログラム）を実施すると`W1011 Use dynamic references over parameters for secrets`（秘密情報ハードコードの警告）が出力されるが、今回は手動スタックにて値を入力する前提のため問題なしとする。

|作成リソース一覧|備考|
| :--- | :--- |
|RDS||


### HostZoneおよびArecordsetのリソース確認

---

ホストゾーンとレコードセットが作成されていること、また、EC2WEBから名前解決できることを確認<br>
![image](/01-APP_Deploy_Figure/05-hostzone.png)  <br>
![image](/01-APP_Deploy_Figure/06-Arecordhostzone.png)  <br>
![image](/01-APP_Deploy_Figure/07-nslookup.png)  <br>


# アプリケーションデプロイ

## ⅰ APP-SV
APPサーバへの設定
## 01_Initial
### 1 yum update
~~~
sudo yum update -y
~~~

### 2 Install-Dep-Packages
必要パッケージのインストール
~~~
sudo yum install -y git gcc openssl11 openssl11-devel bzip2-devel ncurses-devel libffi-devel readline-devel sqlite-devel.x86_64 xz-devel
~~~

## 02 pyenv-install
### 1 clone pyenv
~~~
git clone https://github.com/pyenv/pyenv.git ~/.pyenv
~~~

### 2 Passing by pyenv
pyenv利用のためパスを通す
#### 2-1 Add pyenv to the PATH
~~~
echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> ~/.bashrc
~~~

#### 2-2 Add the pyenv init the shell
~~~
echo 'eval "$(pyenv init -)"' >> ~/.bashrc
~~~

#### 2-3 Run source ~/.bashrc
~~~
source ~/.bashrc
~~~

## 03_Python-install
pythonインストール
### 1 pyenv install
~~~
pyenv install 3.12.1
~~~
### 2 pyenv global set
~~~
pyenv global 3.12.1
~~~
### 3 pyenv version check
~~~
pyenv versions
~~~

### 4_Poetry install
poetryインストール
~~~
curl -sSL https://install.python-poetry.org | python3 - --version 1.8.4
~~~
### 5 Poetry install check
~~~
poetry --version
~~~

## 04_Application-install
サンプルアプリケーションのインストール
### 1 clone application
~~~
git clone https://github.com/tomi050403/flask-app.git
~~~

## 05_Application-setup
### 1 move directory
プロジェクトディレクトリへ移動
~~~
cd flask-app
~~~

### 2 Setup env file
サンプルアプリケーション用の.envファイル作成（.envについてはサンプルアプリケーションリポジトリ参照）
[自作サンプルアプリケーション](https://github.com/tomi050403/flask-app.git)<br>
~~~
nano flaskr/.env
~~~

### 3 export FLASK_APP
環境変数:FLASK_APPにアプリケーション名を設定
~~~
export FLASK_APP=flaskr
~~~

### 4 poetry install
~~~
poetry install
~~~

### 5 poetry shell
~~~
poetry shell
~~~

### 6 frusk-run
flask runコマンドでアプリケーション動作確認
~~~
flask run -h 0.0.0.0
~~~

## Flask接続確認

---

### CFnにて作成したAppServerのパブリックIPを確認。
![image](/01-APP_Deploy_Figure/01_app_ip.png)  <br>
### EC2Appにブラウザ接続し、起動出来ていることを確認
![image](/01-APP_Deploy_Figure/02_app_flaskrun.png)  <br>


続けてapサーバとwebサーバを分離する。

## 06_Set-up-gunicorn
### 1 gunicorn install
gunicornのインストール
~~~
poetry add gunicorn
~~~

### 2 gnicorn run
アプリケーションの起動
~~~
gunicorn -b 0.0.0.0 flaskr:app
~~~

## ⅱ WEB-SV
WEBサーバへの設定
## 01 set-up-websv
### 1 nginx install
~~~
sudo amazon-linux-extras install -y nginx1
~~~

### 2 set up nginx config
nginx設定ファイルの作成
~~~
sudo nano /etc/nginx/conf.d/flask-app.conf
~~~

下記のように作成。
```nginx
server {
    listen 80;
    server_name app.instance.privatelocal;

    location / {
        proxy_pass http://app.instance.privatelocal:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
    }
}
```


### 3 Start nginx
nginx起動
~~~
sudo systemctl start nginx.service
~~~

## Gunicorn接続確認

---

### CFnにて作成されたALB DNS名を確認
![image](/01-APP_Deploy_Figure/03_FLASK-APP-ALB.png)  <br>
### ブラウザ接続し、ALB経由で起動出来ていることを確認
![image](/01-APP_Deploy_Figure/04_gunicorn-run.png)  <br>