# WebアプリケーションのAnsibleデプロイ
- 自作したCRUDアプリケーションをAWS環境にAnsibleにてデプロイする。

# 手動デプロイとの主な変更点
- Ansibleでコントロールノード（自宅ローカル端末）からターゲットノード（AWS EC2インスタンス）にPlaybookを実行する際、通常ssh接続を利用するが、SSMを経由してPlaybookを実行する形とする。
- APP-SVについて、プライベートサブネットに移行。
- RDSについてパスワード管理をsecret managerを利用する。

# AWS環境構築
変更点を踏まえた、今回実施の構成図は下記のとおり
## 構成図
![構成図](02-Ansible_APP_Deploy/02-Figure/figure.png)  <br>

# CFnテンプレート
## 1,Network

[Networkスタック](02-Ansible_APP_Deploy/02-CfnTemplate/Flask-APP_01_Network.yml)<br>

|主な変更点||備考|
| :--- | :--- | :--- |
|NATGateway|追加|プライベートサブネットに配置変更したAPP-SVのインターネット接続のため|

## 2,Security

[Securityスタック](02-Ansible_APP_Deploy/02-CfnTemplate/Flask-APP_02_Security.yml)  <br>

|主な変更点||備考|
| :--- | :--- | :--- |
|IAMRole|追加|EC2にSSM接続するため|
|Secret Manager|追加|RDS設定情報管理のため|
|SG(各EC2)<br>ssh許可設定|削除|SSM利用に伴い許可設定が不要になったため|
|SG(APP)<br>5000ポート許可設定|削除|完成版について5000ポートを利用しないため|

## 3,Application

[Applicationスタック](02-Ansible_APP_Deploy/02-CfnTemplate/Flask-APP_03_Application.yml)<br>

|主な変更点||備考|
| :--- | :--- | :--- |
|各EC2インスタンス<br>IamInstanceProfile|追加|EC2へのSSM接続のため|
|Prameters<br>EC2APPのInstanceType選択|追加|テストデプロイ時にリソース不足を示唆するエラーが発生したため選択式に変更<br>デフォルト:t2.small|


## 4,Application(RDS)

[Application_RDSスタック](02-Ansible_APP_Deploy/02-CfnTemplate/Flask-APP_04_Application_RDS.yml)<br>
RDSのみスタック実行時間を要するため分離。<br>

|主な変更点||備考|
| :--- | :--- | :--- |
|RDS<br>Username,UserPassword|変更|Parametersを削除し、Secret Manager利用設定の追加|



# Ansibleアプリケーションデプロイ


01の部分を置き換える
→手動デプロイとansibleデプロイの対比


|||
| :--- | :--- |
|||


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
#### 2-1 Add pyenv to the PATH
pyenv利用のためパスを通す_1
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