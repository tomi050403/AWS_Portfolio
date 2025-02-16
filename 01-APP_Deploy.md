# Webアプリケーションのデプロイ
- AWS環境構築をcloudformationテンプレートを作成し、スタックの作成にて実施する。
- 自作したCRUDアプリケーションをAWS環境に手動でデプロイする。
- 組み込みサーバで動作確認後、アプリケーションサーバとWEBサーバに分離する。

# AWS環境構築
## 構成図
![構成図](/01-APP_Deploy/01-Figure/figure.png)  <br>

# CFnテンプレート
上記構成図をレイヤー毎に分割することを意識し、３分割してクロススタックにて作成。<br>
cloudformationからスタックにて下記の順番で作成する。<br>

## 1,Network

[Networkスタック](/01-APP_Deploy/01-Figure/Flask-APP_01_Network.yml)<br>

|作成リソース一覧|備考|
| :--- | :--- |
|VPC|スタック作成時設定変更可能<br>デフォルト：10.10.0.0/16|
|InternetGateway||
|PublicSubnet1|スタック作成時設定変更可能<br>デフォルト：10.10.1.0/24|
|PublicSubnet2|スタック作成時設定変更可能<br>デフォルト：10.10.2.0/24|
|PrivateSubnet1|スタック作成時設定変更可能<br>デフォルト：10.10.11.0/24|
|PrivateSubnet2|スタック作成時設定変更可能<br>デフォルト：10.10.12.0/24|
|RDSSubnetGroup||
|HostZone|プライベートドメイン定義<br>EC2WEB→EC2APPの名前解決のため|

## 2,Security

[Securityスタック](/01-APP_Deploy/01-Figure/Flask-APP_02_Security.yml)  <br>
Parametersで一部のSG(SecurityGroup)の送信元IPを設定可能<br>

|設定項目|デフォルト|備考|
| :--- | :--- | :--- |
|APPAllowedIP|0.0.0.0/0|アプリケーション接続用。必要に応じて設定|
|EC2SSHAllowedIP|0.0.0.0/0|EC2WEB,EC2APPへのssh接続用。基本的に自IPのみに絞る|

|作成リソース一覧|用途|許可設定（ソース）|許可設定（ポート）|
| :--- | :--- | :--- | :--- |
|ALBSG|ALB用|APPAllowedIP|TCP 80|
|EC2WEBSG|EC2WEB用|ALBSG<br>EC2SSHAllowedIP|TCP 80<br>ssh|
|EC2APPSG|EC2APP用|APPAllowedIP<br>EC2WEBSG<br>EC2SSHAllowedIP|TCP 5000<br>TCP 8000<br>ssh|
|RDSSG|RDS用|EC2APPSG|TCP 3306|

## 3,Application

[Applicationスタック](/01-APP_Deploy/01-Figure/Flask-APP_03_Application.yml)<br>
Parametersで各EC2インスタンス(AMAZON Linux 2023)にて任意のバージョンのAMIを使うか、最新版のAMIを使うか選択できるようにしている。<br>

"UseEC2APPLatest"および"UseEC2WEBLatest"にてtrueを選択するとAmazonLinux2023最新版のAMIを使用してEC2が作成される。<br>
![image](/01-APP_Deploy/01-Figure/09_stack-app-02.png)  <br>

デフォルトがflaseとしており、"ECAPPCustomAmi""ECWEBCustomAmi"（記入例：ami-007add8d6b8a5fb81）に設定されているAMIにてEC2が作成される。<br>
![image](/01-APP_Deploy/01-Figure/09_stack-app-01.png)  <br>

|作成リソース一覧|備考|
| :--- | :--- |
|EC2WEB|スタック作成時AMIの設定変更可能<br>"true"選択時：AmazonLinux2023最新版<br>"false"選択時（デフォルト）：ami-007add8d6b8a5fb81|
|EC2APP|スタック作成時AMIの設定変更可能<br>"true"選択時：AmazonLinux2023最新版<br>"false"選択時（デフォルト）：ami-007add8d6b8a5fb81|
|ALB||
|RecordSet|EC2APP用Aレコード<br>EC2WEB→EC2APPの名前解決のため|

## 4,Application(RDS)

[Application_RDSスタック](/01-APP_Deploy/01-Figure/Flask-APP_04_Application_RDS.yml)<br>
RDSのみスタック実行時間を要するため分離。<br>
cfn-lint（コードを精査して、そのコードを実行したときにエラーを発生させる可能性のある構文エラーやバグがないかを探すプログラム）を実施すると`W1011 Use dynamic references over parameters for secrets`（秘密情報ハードコードの警告）が出力されるが、今回はAWSコンソールからの手動スタックにて値を入力することを前提としているため、対処せず。<br>

Parametersで下記項目を設定可能<br>

|設定項目|備考|
| :--- |:--- |
|RDSDBUserName|データベースユーザ名|
|RDSDBUserPass|データベースパスワード|
|RDSDataBaseName|アプリケーション用データベース名|

|作成リソース一覧|備考|
| :--- | :--- |
|RDS||


## HostZoneおよびArecordsetのリソース確認
![image](/01-APP_Deploy/01-Figure/08-stack.png)  <br>
スタック作成後にホストゾーンとレコードセットが作成されていること、また、EC2WEBから名前解決できることを確認<br>
![image](/01-APP_Deploy/01-Figure/05-hostzone.png)  <br>
![image](/01-APP_Deploy/01-Figure/06-Arecordhostzone.png)  <br>
![image](/01-APP_Deploy/01-Figure/07-nslookup.png)  <br>


# アプリケーションデプロイ

## ⅰ APP-SV
APPサーバへの設定
## 01_Initial
### 1 dnf update
dnfのアップデート
~~~
sudo dnf update -y
~~~

### 2 Install-Dep-Packages
必要パッケージのインストール
~~~
sudo dnf install -y git gcc zlib-devel bzip2-devel readline-devel sqlite sqlite-devel openssl-devel tk-devel libffi-devel xz-devel
~~~

## 02 pyenv-install
### 1 clone pyenv
pyenvのインストール
~~~
git clone https://github.com/pyenv/pyenv.git ~/.pyenv
~~~

### 2 Passing by pyenv
pyenv利用のためパスを通す_1
#### 2-1 Add pyenv to the PATH
~~~
echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> ~/.bashrc
~~~

#### 2-2 Add the pyenv init the shell
pyenv利用のためパスを通す_2
~~~
echo 'eval "$(pyenv init -)"' >> ~/.bashrc
~~~

#### 2-3 Run source ~/.bashrc
pyenv利用のためパスを通す_3
~~~
source ~/.bashrc
~~~

## 03_Python-install
### 1 pyenv install
python 3.12.1のインストール
~~~
pyenv install 3.12.1
~~~
### 2 pyenv global set
python 3.12.1のグローバル設定
~~~
pyenv global 3.12.1
~~~
### 3 python version check
python 3.12.1がグローバル設定されていることの確認
~~~
pyenv versions
~~~

### 4 Poetry install
poetryインストール
~~~
curl -sSL https://install.python-poetry.org | python3 - --version 1.8.4
~~~
### 5 Poetry install check
poetryバージョンチェック
~~~
poetry --version
~~~

## 04_Application-install
### 1 clone application
サンプルアプリケーションのインストール
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
プロジェクトで利用されるpythonパッケージをインストール
~~~
poetry install
~~~

### 5 poetry shell
仮想環境起動
~~~
poetry shell
~~~

### 6 frusk-run
flask runコマンドでアプリケーション動作確認
~~~
flask run -h 0.0.0.0
~~~

## Flask接続確認

### CFnにて作成したAppServerのパブリックIPを確認。
![image](/01-APP_Deploy/01-Figure/01_app_ip.png)  <br>
### EC2Appにブラウザ接続し、起動出来ていることを確認
![image](/01-APP_Deploy/01-Figure/02_app_flaskrun.png)  <br>


## 続けてapサーバとwebサーバを分離する。<br>06_Set-up-gunicorn
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
nginxのインストール
~~~
sudo dnf -y install nginx
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

# Gunicorn接続確認

## CFnにて作成されたALB DNS名を確認

![image](/01-APP_Deploy/01-Figure/03_FLASK-APP-ALB.png)  <br>
## ブラウザ接続し、ALB経由で起動出来ていることを確認

![image](/01-APP_Deploy/01-Figure/04_gunicorn-run.png)  <br>