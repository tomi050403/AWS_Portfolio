# Flaskアプリ手動構築（CloudFormation）

## 概要

本構成は、AWS上にFlaskアプリケーションを動作させるインフラを、CloudFormationテンプレートを用いて手動で構築する内容となっています。<br>
以下の4つのテンプレートに分割し、段階的に構成を進めていきます。

- ネットワーク（VPC / Subnet / IGW / RouteTable / RDS用SubnetGroup / HostedZone）
- セキュリティ（ALB / EC2 / RDS のセキュリティグループ）
- アプリケーション（Web/App サーバー、ALB、Route53レコード）
- RDS（MySQLデータベース）

---

## 製作目的

- cloudformation学習の振り返りとアウトプット
- クロススタック参照の活用
- 後続の自動デプロイ手順整理

---

##  ディレクトリ構成

```bash
01-APP_Deploy/01-CfnTemplate/
├── Flask-APP_01_Network.yml         # VPC / Subnet / Route / HostedZone
├── Flask-APP_02_Security.yml        # セキュリティグループ
├── Flask-APP_03_Application.yml     # EC2 / ALB / Route53レコード
└── Flask-APP_04_Application_RDS.yml # RDS
```

---

## インフラ構成図

![構成図](01-APP_Deploy/01-Figure/figure.png)  <br>


---

## 構成テンプレートと主な役割


### 1. Flask-APP_01_Network.yml

[Networkスタック](01-APP_Deploy/01-CfnTemplate/Flask-APP_01_Network.yml)<br>

- VPCとサブネット（Public/Private）を構成
- IGW / RouteTable / HostedZone（Private）
- RDS用のSubnetGroupもこのテンプレートで定義

| 項目 | 説明 |
|------|------|
| VPC | 10.10.0.0/16 のCIDRブロック |
| Public Subnet（2AZ） | Webサーバー/ALB用（1a,1c） |
| Private Subnet（2AZ） | Appサーバー/RDS用（1a,1c） |
| IGW / RouteTable | インターネット通信用設定 |
| HostedZone | `privatelocal` ドメイン向けPrivateゾーン |

### 2. Flask-APP_02_Security.yml

[Securityスタック](01-APP_Deploy/01-Figure/Flask-APP_02_Security.yml)  <br>

- ALB / Web / App / RDS 用のセキュリティグループを定義
- IP制限付きのインバウンドルール（HTTP, SSH など）

| SG名 | 説明 |
|------|------|
| ALB-SG | 外部からのHTTPアクセス | 80 |
| Web-SG | ALBからのトラフィックのみ許可 | 80 |
| App-SG | Webサーバーからの通信のみ許可 | 8000 |
| RDS-SG | AppサーバーからのMySQL通信のみ許可 | 3306 |


### 3. Flask-APP_03_Application.yml

[Applicationスタック](01-APP_Deploy/01-Figure/Flask-APP_03_Application.yml)<br>

- Web用とApp用の2つのEC2インスタンスを作成
- Amazon Linux AMI の選択（固定AMI or SSM最新）に対応
- ALB + TargetGroup + Listener の作成
- app.instance.privatelocal に対する Route53レコード登録


| リソース | 説明 |
|----------|------|
| EC2（Websv） | PublicSubnet、ALB経由でアクセス |
| EC2（Appsv） | PrivateSubnet、Websvから接続 |
| ALB | Websvをターゲットとしてリスニング（HTTP） |
| Route53 Record | `app.instance.privatelocal` のAレコード作成（Appsv） |


### 4. Flask-APP_04_Application_RDS.yml

[Application_RDSスタック](01-APP_Deploy/01-Figure/Flask-APP_04_Application_RDS.yml)<br>

- MySQL 8.0 を Multi-AZで起動
- SecretsManager などは使わず、テンプレートで直接定義（学習目的の簡易構成）

| リソース | 説明 |
|----------|------|
| RDS（MySQL8.0） | Multi-AZ構成（1a,1c） |
| DBパラメータ | テンプレート上で定義（学習用途のため簡略） |

cfn-lint（コードを精査して、そのコードを実行したときにエラーを発生させる可能性のある構文エラーやバグがないかを探すプログラム）を実施すると`W1011 Use dynamic references over parameters for secrets`（秘密情報ハードコードの警告）が出力されるが、今回はAWSコンソールからの手動スタックにて値を入力することを前提としているため、対処せず。<br>


## HostZoneおよびArecordsetのリソース確認
![image](01-APP_Deploy/01-Figure/08-stack.png)  <br>
スタック作成後にホストゾーンとレコードセットが作成されていること、また、EC2WEBから名前解決できることを確認<br>
![image](01-APP_Deploy/01-Figure/05-hostzone.png)  <br>
![image](01-APP_Deploy/01-Figure/06-Arecordhostzone.png)  <br>
![image](01-APP_Deploy/01-Figure/07-nslookup.png)  <br>

---

## 手動構築手順（AWSマネジメントコンソール）

1. **AWSマネジメントコンソールにログイン**
2. **CloudFormation > スタックの作成** を開く
3. 各テンプレート（Flask-APP_01 ～ 04）を **順番にアップロード**
4. パラメータを入力し「スタックの作成」実行

### スタック別パラメータ例
#### Flask-APP_01_Network.yml
- `EnvironmentName`: Flask-APP-Product

#### Flask-APP_02_Security.yml
- `EnvironmentName`: Flask-APP-Product
- `ALBAccessFrom`: グローバルIP例 `xxx.xxx.xxx.xxx/32`
- `SSHAccessFrom`: グローバルIP例 `xxx.xxx.xxx.xxx/32`

#### Flask-APP_03_Application.yml
- `EnvironmentName`: Flask-APP-Product
- `EC2Keypair`: 作成済みのキーペア名
- `UseEC2APPLatest`, `UseEC2WEBLatest`: false（AMI固定）
- `AppServerAmiId`, `WebServerAmiId`: 利用したいAMI ID

#### Flask-APP_04_Application_RDS.yml
- `EnvironmentName`: Flask-APP-Product
- `RDSDBUserName`: （DBユーザ名）
- `RDSDBUserPass`: （DBパスワード）
- `RDSDataBaseName`: (データベース名)

> `Outputs` を活用し、後続テンプレート間の依存関係も管理しています。

---

## アプリケーションデプロイ（手動）

> 本構成では Ansible や自動化ツールを使用していないため、**EC2インスタンスへ手動ログインしアプリケーションをセットアップ** します。  
（次フェーズのAnsibleでこの手順を自動化します）

### ⅰ APP-SV
APPサーバへの設定
### 01_Initial
#### 1 dnf update
dnfのアップデート
~~~
sudo dnf update -y
~~~

#### 2 Install-Dep-Packages
必要パッケージのインストール
~~~
sudo dnf install -y git gcc zlib-devel bzip2-devel readline-devel sqlite sqlite-devel openssl-devel tk-devel libffi-devel xz-devel
~~~

### 02_pyenv-install
#### 1 clone pyenv
pyenvのインストール
~~~
git clone https://github.com/pyenv/pyenv.git ~/.pyenv
~~~

#### 2 Passing by pyenv
##### 2-1 Add pyenv to the PATH
pyenv利用のためパスを通す_1
~~~
echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> ~/.bashrc
~~~

##### 2-2 Add the pyenv init the shell
pyenv利用のためパスを通す_2
~~~
echo 'eval "$(pyenv init -)"' >> ~/.bashrc
~~~

##### 2-3 Run source ~/.bashrc
pyenv利用のためパスを通す_3
~~~
source ~/.bashrc
~~~

### 03_Python-install
#### 1 pyenv install
python 3.12.1のインストール
~~~
pyenv install 3.12.1
~~~
#### 2 pyenv global set
python 3.12.1のグローバル設定
~~~
pyenv global 3.12.1
~~~
#### 3 python version check
python 3.12.1がグローバル設定されていることの確認
~~~
pyenv versions
~~~

#### 4 Poetry install
poetryインストール
~~~
curl -sSL https://install.python-poetry.org | python3 - --version 1.8.4
~~~
#### 5 Poetry install check
poetryバージョンチェック
~~~
poetry --version
~~~

### 04_Application-install
#### 1 clone application
サンプルアプリケーションのインストール
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
サンプルアプリケーション用の.envファイル作成（.envについてはサンプルアプリケーションリポジトリ参照）
[自作サンプルアプリケーション](https://github.com/tomi050403/flask-app.git)<br>
~~~
nano flaskr/.env
~~~

#### 3 export FLASK_APP
環境変数:FLASK_APPにアプリケーション名を設定
~~~
export FLASK_APP=flaskr
~~~

#### 4 poetry install
プロジェクトで利用されるpythonパッケージをインストール
~~~
poetry install
~~~

#### 5 poetry shell
仮想環境起動
~~~
poetry shell
~~~

#### 6 frusk-run
flask runコマンドでアプリケーション動作確認
~~~
flask run -h 0.0.0.0
~~~

### Flask接続確認

#### CFnにて作成したAppServerのパブリックIPを確認。
![image](/01-APP_Deploy/01-Figure/01_app_ip.png)  <br>
#### EC2Appにブラウザ接続し、起動出来ていることを確認
![image](/01-APP_Deploy/01-Figure/02_app_flaskrun.png)  <br>


### 続けてapサーバとwebサーバを分離する。
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
### 01_set-up-websv
#### 1 nginx install
nginxのインストール
~~~
sudo dnf -y install nginx
~~~

#### 2 set up nginx config
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


#### 3 Start nginx
nginx起動
~~~
sudo systemctl start nginx.service
~~~

---

## 確認事項

- 各CloudFormationスタックが「CREATE_COMPLETE」であること
- `app.instance.privatelocal` の名前解決が成功すること
- ALB のDNSにアクセスしてFlaskアプリが表示されること

### CFnにて作成されたALB DNS名を確認

![image](01-APP_Deploy/01-Figure/03_FLASK-APP-ALB.png)  <br>
### ブラウザ接続し、ALB経由で起動出来ていることを確認

![image](01-APP_Deploy/01-Figure/04_gunicorn-run.png)  <br>