# Vagrant と Chef による仮想環境の自動構築（VirtualBox編）

AWS のようなクラウドサービスが一般に浸透したことにより、仮想環境を前提とした開発が一般的になってきました。必要になったときに必要な構成のリソースにアクセスできるクラウドの強みを活かすため、オンデマンドで仮想環境を構築し直す機会が以前よりも増えてきています。このような状況では、仮想環境をより効率的に構築する必要があります。本記事のシリーズでは効率的な仮想環境構築の手段の一つとして、Vagrant と Chef というツールを使い、環境構築を自動化する方法を紹介します。

# 1. はじめに

最初に Vagrant と Chef を使った環境構築の概要および今回の構築する仮想環境についてご紹介します。

## 環境構築の自動化に利用するツール

本記事ではタイトルにある通り、環境構築に以下の 2 つのツールを使います。元々は別のツールですが、両者を連携させることで、仮想環境の構築で必要となる一連の作業（仮想マシンの立ち上げ、OS や各種ソフトウェアのインストール、アプリケーションのビルドなど）を自動化できます。

<dl>
  <dt>Vagrant</dt>
  <dd>仮想マシンを操作する際のフロントエンドとなるツールです。指定した設定を施した仮想マシンを立ち上げることができます。また、プラグインを利用することで、機能拡張ができます。Chef の制御もプラグインによって行います。</dd>
  <dt>Chef</dt>
  <dd>ソフトウェアのインストールや各種設定作業を Cookbook と呼ばれる単位で記述し、自動化できます。本記事では、ゲスト OS の環境設定に利用しています。同様の作業はシェルスクリプトなどでもできますが、Chef を利用するメリットとして、あらかじめ決められた Ruby の DSL に沿って非常に簡潔なコードで手順を記述できます。また、Maven や Gradle といったビルドツールと同じように Cookbook の依存関係を調べて、依存する Cookbook を Cookbook 置き場から取得するといった便利な使い方もできます。</dd>
</dl>

## 仮想環境構築自動化のメリット
 
仮想環境構築を自動化するメリットとして、以下のようなことが挙げられます。

- 個人の暗黙的なノウハウに依存していた環境構築作業がコードとして形式知化できます。ノウハウの共有が容易になります。
- 構築手順がコードによって自動化できるため、何度でも同じ結果を得ることができます。環境の差分によってシステムの動作が変わるといったトラブルを防ぐことができます。

## Vagrant と Chef の連携による仮想環境構築の流れ

Vagrant と Chef の両者を連携させて仮想環境を構築する手順を紹介します。

![Vagrant と Chef による環境構築のイメージ](./img/vagrant-chef.png)

# 2. Vagrant と Chef を動かしてみよう

ここからは実際に手を動かしながら、Vagrant と Chef の利用イメージを掴んでいただきます。最初に必要なツールをひと通りインストールした後、筆者があらかじめ用意した設定ファイルを利用して、アプリケーションが起動するまでを体験していただきます。最初にインストール作業が続きますが、少々辛抱してください ^^; 

## 構築対象の仮想環境

本記事では、以下の構成の仮想環境を構築し、さらにデータベース中のデータを一覧表示する簡単な Web アプリケーションが起動するまでの作業を自動化します。

- 仮想マシン: VirtualBox 4.3.20
- OS: CentOS 7.0
- DB: PostgreSQL 9.2
- アプリケーションサーバ: Netty (Play Framework に付属）
- プログラミング言語: Java 8

今回は手元で確認できる仮想マシンとして VitualBox を利用します。次回公開する記事では、クラウドホスティングサービスとして最も人気のある Amazon EC2 での環境構築手順も紹介します。

## VirtualBoxのインストール

今回は VirtualBox で仮想マシンを立ち上げます。以下の URL から VirtualBox のインストーラを取得し、インストールしてください。

http://www.oracle.com/technetwork/server-storage/virtualbox/overview/index.html

## Vagrant のインストール

以下の URL からバージョン 1.6.5 の Vagrant のインストーラをダウンロードし、インストールを行って下さい。

http://www.vagrantup.com/downloads

（注意）本記事執筆時点での最新バージョンは 1.7.2 ですが、1.7 系を利用した場合、Vagrant プラグインの動作がまだ不安定なため、本記事では動作が安定した 1.6系 の安定バージョンを使います。

インストールしたら以下のコマンドで Vagarant が実行できることを確認してください。

```
% vagrant --version
Vagrant 1.6.5
```

## Chef のインストール

Chef-DK という Chef を利用する際に必要なツールをひとまとめにしたキットを利用します。以下の URL から Chef-DK（バージョン 0.3.5 ） のインストーラをダウンロードしてください。画面中央にある OS のアイコンをクリックし、OS に合ったインストーラのダウンロードページを開く必要がある点に注意して下さい。

https://downloads.chef.io/chef-dk/

（注意）
- 本記事執筆時点での最新バージョンは 0.3.6 ですが、Vagrantプラグインの動作が安定しないため、安定動作が確認できたバージョンを使用しています。
- ホスト側では Chef は実行されませんが、ゲスト OS に Chef で環境設定するために必要なツール群が Chef-DK でインストールされます。
- Chef-DK にバンドルされた Ruby の利用が推奨されています。以下のコマンドで Chef-DK の Ruby を使うように指定して下さい。

```
 eval "$(chef shell-init SHELL_NAME)"
```

（注意）
- SHELL_NAME の箇所は自分が使っているシェル名に置き換えてください。

以下のコマンドで Chef-DK がインストールされていることを確認してください。

```
%chef -v
Chef Development Kit Version: 0.3.5
```

## Vagrantプラグインのインストール

Vagrant は仮想環境構築のフロントエンドとなるツールです。仮想マシンを立ち上げたり、Chef でソフトウェアをインストール作業は Vagrant のプラグインから行います。

以下のコマンドで vagrant-vbguest という VirtualBox を Vagrant から利用するためのプラグインをインストールします。

```
$ vagrant plugin install vagrant-vbguest
```

次に Vagrant から Chef Zero Server を起動するためのプラグイン vagrant-chef-zero をインストールします。

```
% vagrant plugin install vagrant-chef-zero
```
 
 次にゲスト OS に Chef をインストールするために必要なプラグイン vagrant-omnibus をインストールします。
 
```
% vagrant plugin install vagrant-omnibus
```

以上で環境設定は終了です。

## アプリケーションの起動

ようやく実際に Vagrant と Chef でアプリケーションを起動してみましょう。以下のコマンドで Vagrant や Chef の設定ファイルを Github リポジトリから取得してください。

```
git clone https://github.com/yohei1126/vagrant-chef-sample.git
cd vagrant-chef-sample
```

次に以下のコマンドで仮想マシンを立ち上げてください。

```
$ vagrant up
```

Vagrant は仮想マシンの起動時間を短縮するため、Box と呼ばれる仮想マシンのベースイメージを使用します。本サンプルでは、初回の起動時に Box をダウンロードするよう指示しているため、初回のみ起動に時間がかかる点に注意してください。

以下のようなメッセージが出力されると、Chefの実行が完了し、環境構築は終了しています。

```
INFO: Chef Run complete in 0.046189483 seconds
```

Vagrant のコマンドを使って、ゲスト OS に SSH で接続できます。

```
$ vagrant ssh
```

環境構築が無事に完了していれば、以下のコマンドで PostgreSQL がインストールされ、データベースが構築されていることを確認できます。

```
$ psql -h localhost -U postgres -W
(postgres ユーザのパスワード postgres を入力)
postgres=# \connect sampledb
postgres=# select * from sample_table;
```

ゲストとホスト側はブリッジ接続しているため、ホスト側からゲスト側で動作する Netty（Play Framework の組み込み Web サーバ）にアクセスできます。ゲスト OS に SSH した状態で、ゲスト OS の IP アドレスを取得してください。

```
$ ip a show
（ネットワーク設定が表示される。）
```

http://（ゲストの IP アドレス）:9000 にアクセスすると、ゲスト OS 側で動作する Web アプリケーションにアクセスできます。

以上で環境構築が完了し、アプリケーションが立ち上がるところまで自動化できていることが確認できました。一番最初に環境構築を行うホスト側の設定に一苦労しますが、手順が一度確率していれば、簡単に環境構築できることがお分かりいただけたと思います。

動作が確認できたら、以下のコマンドで一旦作成した仮想マシンを破棄してください。

```
$ vagarnt destroy
```

# Vagrant と Chef の実践

ここからは前の節で環境構築し、動作を確認したアプリケーションについて実際に構築する手順を紹介します。なお、Vagarnt、Chef、Vagrant プラグインといったツールはひと通りホスト側にインストールされているという前提で手順を説明します。まだインストールされていない場合は、一度、前の節に戻って、ホスト側の環境設定を行って下さい。

# Vagrantfile の作成

Vagarnt を実行する際には Vagrantfile という設定ファイルで Vagrant の実行方法を指定します。Vagrantfile のひな形は以下のコマンドで作成できます。

```
$ vagrant init
```

前述のとおり、 Vagrant は Box と呼ばれる仮想マシンのベースイメージを使用して、短時間で仮想環境を立ち上げます。Vagrantfile には Box の取得場所を指定します。ここでは Vagrantbox.es という有志が作成した Box を公開する Web サイトから取得する旨を指示します。

http://www.vagrantbox.es/

$vim Vagrantfile

```
 Vagrant.configure(2) do |config|
   config.vm.box = "centos7"
   config.vm.box_url="https://f0fff3908f081cb6461b407be80daf97f07ac418.googledrive.com/host/0BwtuV7VyVTSkUG1PM3pCeDJ4dVE/centos7.box"
 end
```

- config.vm.box に自分の box の名前として box の内容が分かるような文字列を指定します。
- config.vm.box_url には CentOS 7 の Box の URL を指定します。
- Vagrantbox.es に掲載されている CentOS 7 の Box のうち、「CentOS7.0 x86_64 minimal (VirtualBoxGuestAddtions 4.3.14)」を利用します。

これらの記述により、ローカルの Box 置き場に "centos7" という Box が存在する場合、ローカルの Box を使います。存在しない場合、指定した URL から Box をダウンロードし、ローカルに配置します。

# 仮想マシンの起動

この時点で一度仮想マシンが起動できるか確かめてみましょう。

```
$ vagrant up
==> default: Machine booted and ready!
==> default: Checking for guest additions in VM...
==> default: Mounting shared folders...
    default: /vagrant => /Users/yohei/work/vagrant-chef-sample
```

うまく起動できたら、SSH でゲスト OS に接続できることも確認します。

```
$ vagrant ssh

```

# Chef Zero Server の起動および Chef Client の実行

仮想マシンの起動まで確認できたため、次に Vagrant プラグインからホストOS側で Chef Zero Server が起動出来る点、またゲスト OS 側に Chef Client がインストールされることを確認します。

```
% vagrant plugin install vagrant-omnibus
```

両プラグインを利用する設定を Vagrantfile に追記します。以下の設定ファイルでは以下を指示しています。
- ゲスト OS に最新の Chef をインストールする
- Chef Zero Server のリポジトリとしてカレントディレクトリを設定する。
- プロビジョン（各種設定を行うツール）として Chef Client を設定する。
- Cookbook は何も実行しない。

```
Vagrant.configure(2) do |config|
  config.omnibus.chef_version=:latest
  config.chef_zero.chef_repo_path = "."
  config.vm.box = "centos7"
  config.vm.box_url = "https://f0fff3908f081cb6461b407be80daf97f07ac418.googledrive.com/host/0BwtuV7VyVTSkUG1PM3pCeDJ4dVE/centos7.box"
  config.vm.provision :chef_client do |chef|
    chef.custom_config_path = "chef_custom_config"
    chef.run_list = []
  end
end
```

ここで Chef-Client の設定ファイルとして "chef_custom_config" を指定しています。カレントディレクトリに以下のようなファイルを作成します。これは SSH 関係の警告を出さないようにするための対処です。

```
% more chef_custom_config
Chef::Config.ssl_verify_mode = :verify_peer
```

それでは仮想マシンが立ち上がるところからプロセスを確認するため、一度、作成済みの仮想マシンを破棄し、再度立ち上げます。

```
% vagrant destroy
% vagrant up
```

プラグインのインストールと設定ファイルの記述が正しく行われていれば、Chef Zero Server も起動し、ゲストに Chef のインストールが行われます。今回はクックブックを指定なかったため、Chef の run list が空である旨が記載されています。

```
% vagrant up
Starting Chef Zero at http://192.168.179.4:4000
==> default: Installing Chef 12.0.3
==> default: Thank you for installing Chef!
==> default: Running provisioner: chef_client...
==> default: Warning: Chef run list is empty. This may not be what you want.
==> default: [2015-01-24T20:08:40-05:00] INFO: Chef Run complete in 0.046189483 seconds
```

# Cookbook を使った PostgreSQL のインストール

ここからようやく本題である Cookbook の作成にとりかかります。今回は以下の作業を自動化します。

- PostgreSQLの server、client、contrib パッケージのインストール
- postgres ユーザのパスワード設定
- sampledb データベースの作成

## コミュニティの Cookbook の利用

Cookbook は全て自分自分で作成する必要はなく、コミュニティの有志によって作成されたものを再利用することができます。Cookbook の共有サイトである以下の URL にアクセスし、PostgreSQL をインストールできる Cookbook を探してみましょう。

https://supermarket.chef.io/

PostgreSQL をインストールできる Cookbook である postgres を見つけました。数十万件ダウンロードされ、最近もメンテナンスされているようですので、こちらを利用しましょう。

https://supermarket.chef.io/cookbooks/postgresql

## Berkshelf による Cookbook の依存関係解決

Cookbook を利用する場合、注意する必要があるのが、Cookbook 間の依存関係です。これは一般的なソフトウェアのビルドと共通する問題です。ある Cookbook が別の Cookbook に依存している場合、目的の Cookbook を利用するために依存先の Cookbook を全て集める必要があります。さらに依存先の Cookbook に依存先の Coobook がある場合、芋づる式に必要な Cookbook が増えてしまいます。

この依存関係の問題を解決するのが Berkshelf です。Berkshelf の設定ファイルである Berksfile に必要な Cookbook を記載しておけば、Berkshelf が必要な Cookbook を自動的に集めてきてくれます。

カレントディレクトリに Berksfile というファイルを作成し、以下のように記述してください。

```
% more Berksfile
source "https://api.berkshelf.com"

cookbook 'postgresql'
```

Berkshelf は Chef-DK に入っているため、すでに利用可能です。以下のコマンドを実行し、postgresql と依存先の Cookbook をダウンロードしてください。
- 第1引数 vendor は Cookbook をダウンロードすることを意味します。
- 第2引数の coobooks は Cookbook のダウンロード先ディレクトリです。vagrant-chef-zero プラグインは Cookbooks というディレクトリに置かれた Cookbook を Chef Zero Server にアップロードします。

```
% berks vendor cookbooks
```

次に Vagrantfile を開いて、実行対象の Cookbook として postgresql を指定してください。vagrant provision を実行すると、実際に postgresql が Chef Zero Server にアップロードされた後、ゲスト側の Chef がその Cookbook を実行します。

以下では postgresql のクックブックのうち、server と client と contrib の3つのレシピを指定しています。さらに postgresql の属性として postgres ユーザのパスワードを指定しています。このように Cookbook で用意されている設定に対して、ユーザが期待する設定を上書きすることもできます。

```
% vim Vagrantfile
    config.vm.provision :chef_client do |chef|
      chef.custom_config_path = "chef_custom_config"
      chef.run_list = [
          "postgresql::server",
          "postgresql::client",
          "postgresql::contrib"
      ]
      chef.json = {
        :postgresql => {
          :password => 'postgres'
        }
      }
    end
```

実際に PostgreSQL がインストールされているか確認しましょう。無事に 9.2.7 がインストールされ、postgres ユーザでログインできることが確認できました。

```
% vagrant provision
% vagrant ssh
[vagrant@localhost ~]$ psql -h localhost -U postgres -W
psql (9.2.7)
postgres=#
```

##データベース構築 Cookbook の作成

次に PostgreSQL データベース sampledb を作成します。ここでもコミュニティのクックブック dabatase を利用して、DB の設定を行います。

https://supermarket.chef.io/cookbooks/database

ただし、 database は DB の設定を行うためのライブラリに相当する Cookbook で、実際の設定作業は自分のレシピとして実装する必要があります。Chef の慣習ではコミュニティの Cookbook と自作の Cookbook を分けて配置することが一般的です。

それでカレントディレクトリ配下に site-cookbooks というディレクトリを作成し、PostgreSQL の設定を行う Cookbook として postgresql_config を作成します。
- metadata.rb が Cookbook の情報を記載する箇所です。Cookbookの依存関係なども記載できます。
- recipes ディレクトリはレシピの配置場所です。default.rb はデフォルトで実行されるレシピです。database に定義されている postgresql_database タスクを利用して実装しています。ここでは localhost に sampledb というデータベースを作成し、 postgres ユーザからアクセスできるようにしています。

```
% more site-cookbooks/postgresql_config/metadata.rb
name             'postgresql_config'
maintainer       'Yohei Onishi'
maintainer_email 'yohei@example.co.jp'
license          'Yohei Onishi All rights reserved'
description      'Configures postgres'
long_description 'Configures postgres'
version          '0.1.0'

%more site-cookbooks/postgresql_config/recipes/default.rb
postgresql_database 'sampledb' do
  connection(
    :host     => '127.0.0.1',
    :port     => 5432,
    :username => 'postgres',
    :password => node['postgresql']['password']['postgres']
  )
  template 'DEFAULT'
  encoding 'DEFAULT'
  tablespace 'DEFAULT'
  connection_limit '-1'
  owner 'postgres'
  action :create
end
```

すでに説明した通り、Chef Zero Server で Cookbooks を利用するために、berks コマンドで依存先の Cookbooks を含めて再度ダウンロードします。以下のように dabatase および postgresql_config を追記してください。postgresql_config は自作の Cookbook であるため、取得元を指定していることに注意してください。このように Berksfile を記載することで、自作の Cookbook だけ site-cookbooks に配置して、構成管理対象にし、プロビジョニングするときだけコミュニティの Cookbook を含めて cookbooks にコピーして利用することができます。 

```
% more Berksfile                                                                                       (git)-[mast
source "https://api.berkshelf.com"

#original cookbooks
cookbook 'postgresql_config',  path: './site-cookbooks/postgresql_config'

#community cookbooks
cookbook 'database'
cookbook 'postgresql'
```

新たに利用する Cookbook をダウンロードします。

```
% berks vendor cookbooks
```

新たに追加した Cookbook を実行するため、Vagarntfile の Chef Client 設定部分の run_list に database と postgresql_config を追加してください。

```
  config.vm.provision :chef_client do |chef|
    chef.custom_config_path = "chef_custom_config"
    chef.run_list = [
        "postgresql::server",
        "postgresql::client",
        "postgresql::contrib",
        "database::postgresql",
        "postgresql_config"
    ]
    chef.json = {
      :postgresql => {
        :password => 'postgres'
      }
    }
  end
```

再度プロビジョンを行った後、SSH 接続して、PostgreSQL 上に sampledb データベースが作成されていることを確認してください。

```
% vagrant provision
% vagrant ssh
[vagrant@localhost ~]$ psql -h localhost -U postgres -W
postgres=# \connect sampledb
データベース "sampledb" にユーザ"postgres"として接続しました。
```

以上で、ゲスト側に PostgreSQL をインストールし、sampledb を作成することができました。

# Play Framework を使った Web アプリケーションのインストールと起動

次に Play Framework （Java / Scala 向け Web フレームワーク）を使った Web アプリケーションのインストールおよび起動を行います。ここでは以下の一連の作業を Chef で自動化します。

1. ソースコードを Github リポジトリから取得する。
2. コマンドラインツール activator でソースコードをビルドし、アプリケーションを起動する。

（注意）本記事は Play Framework 自体の解説は行いません。Play Framework 自体については他の Web 記事や書籍を参照してください。

Play Framework 向けの Chef でも Cookbook の最小構成として metadata.rb とレシピ (default.rb) を作成します。本 Cookbook は自作 Cookbook のため、 site-cookbooks ディレクトリ配下に作成します。

metadata.rb では Cookbook をインストールする際に必要な以下の2つ Cookbook への依存関係を記述しています。

- git: git をインストールする Cookbook です。本サンプルではソースコードを Github から取得する際に git を使います。
- java: Java をインストールする Cookbook です。Play Framework はビルド・実行に Java が必要です。

```
% more site-cookbooks/play-sample/metadata.rb
name             'play-sample'
maintainer       'Yohei Onishi'
maintainer_email 'yohei@example.co.jp'
license          'Yohei Onishi All rights reserved'
description      'clone from repo'
long_description 'clone from repo'
version          '0.1.0'

depends 'git'
depends 'java'
```

次にデフォルトの Recipe（default.rb） では、ソースコードを Github リポジトリから取得し、activator コマンドを使って Play Framework を使ったアプリケーションをビルド・起動しています。
本 Recipe を見てお分かりの通り、Ruby の DSL として簡潔に記述できます。

```
% more site-cookbooks/play-sample/recipes/default.rb
git '/home/vagrant/play-sample' do
  repository 'https://github.com/ogis-onishi/play-sample.git'
  user 'vagrant'
end

bash "activator-run" do
  user 'root'
  cwd '/home/vagrant/play-sample/'
  code <<-EOH
    ./activator clean stage
    target/universal/stage/bin/play-sample & 
  EOH
end
```

site-cookbooks に置いておくと Chef Zero Server にアップロードされないため、Berksfile に追記しておきます。

```
cookbook 'play-sample',        path: './site-cookbooks/play-sample'
```

再度、berks vendor cookbooks を実行すると、依存先の Cookbook が収集され、cookbooks ディレクトリに配置されます。

Chef Client のプロビジョン対象にするには chef.run_list に play-sample を追加しておきます。play-sample を実行する際に git と java が必要になりますが、 metadata.rb に依存関係を記述しているので、自動的に Chef がgit と java も実行対象にしてくれます。

```
    chef.run_list = [
        "postgresql::server",
        "postgresql::client",
        "postgresql::contrib",
        "database::postgresql",
        "postgresql_config",
        "play-sample"
    ]
```

Cookbook の java は yum で java のインストールを行います。本記事執筆時点で yum はまだ Java 8 のインストールに対応していないため、インストール対象の JDK バージョンとして 7 を指定します。これで Java 7 の最新バージョンがインストールされます。

```
    chef.json = {
      :postgresql => {
        :password => 'postgres'
      },
      :java => {
        :jdk_version => '7'
      }
    }
```

仮想マシンはすでに起動されているため、再度プロビジョンのみ行います。

```
$ vagrant provision
```

プロビジョンが完了したら、一度、ゲスト OS にログインし、IP アドレスを確認してください。

```
$ vagrant ssh
$ ip a show
```

ゲスト OS に対して 9000 ポートでアクセスし、Web アプリケーションが表示できれば完了です。

http://(IPアドレス):9000

# おわりに

本記事では、Vagrant と Chef を使って以下を行いました。

- 仮想マシンの起動
- ソフトウェアのインストール（PostgreSQL、git、Java など）
- Web アプリケーションのビルドと起動

一番最初にホスト側の設定（Vagrant と Chef のインストール）を行う必要がありますが、一度行ってしまうとゲスト OS の環境構築は自動できることがお分かりいただけたと思います。

今回はローカル PC 上で動作確認いただくため、VirtualBox を利用しました。次回はクラウドサービスで最も人気のある AWS 上で利用する方法について紹介します。


