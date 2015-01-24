# vagrant-chef-sample
本チュートリアルはVagrantとChefを使って、VM上のCentOS 7にPlay FrameworkとPostgreSQLを使ったアプリケーション環境を構築する方法を紹介します。

# Vagrantのインストール
最初にVagrantでCentOSがインストールされたVMを立ち上げてみます。以下のURLからVagrantのインストーラをダウンロードし、インストールを行って下さい。
http://www.vagrantup.com/downloads

インストールしたら以下のコマンドでVagarantが実行できることを確認してください。本記事執筆時点でVagrantの最新バージョンは1.7.2です。

```
% vagrant --version
Vagrant 1.7.2
```

#Vagrantfileの作成
Vagarntを実行する際にはVagrantfileという設定ファイルでVagrantの実行方法を指定します。Vagrantfileのひな形は以下のコマンドで作成できます。

```
$ vagrant init
```

Vagrantは0から仮想マシンをインストールしません。そのかわりに仮想マシンのベースイメージを使用することで、起動時間を早くします。このベースイメージのことをBoxといいます。Boxは自分で作成する必要はありません。Vagrantbox.esというWebサイトで有志が作成したBoxが提供されています。

http://www.vagrantbox.es/

ここではVagrantbox.esに掲載されているCentOS 7のBoxのうち、「CentOS7.0 x86_64 minimal (VirtualBoxGuestAddtions 4.3.14)」を利用します。

```
$vim Vagrantfile

 Vagrant.configure(2) do |config|
   config.vm.box = "centos7"
   config.vm.box_url="https://f0fff3908f081cb6461b407be80daf97f07ac418.googledrive.com/host/0BwtuV7VyVTSkUG1PM3pCeDJ4dVE/centos7.box"
 end
```

config.vm.boxに自分のboxの名前としてboxの内容が分かるような文字列を指定します。config.vm.box_urlにはCentOS 7のBoxのURLを指定します。これらの記述により、ローカルのBox置き場に"centos7"というBoxが存在する場合、ローカルのBoxを使います。存在しない場合、指定したURLからBoxをダウンロードし、ローカルに配置します。

#仮想マシンの起動

この時点で仮想マシンが起動できるか確かめてみましょう。
なお、今回はVirtualBoxで仮想マシンを立ち上げます。VirtualBoxが手元にインストールされていない場合はインストールしてください。

http://www.oracle.com/technetwork/server-storage/virtualbox/overview/index.html

また、VagarntからVirtualBoxを利用する場合、vagrant-vbguestというVagrantのプラグインをインストールしておく必要があります。

```
$vagrant plugin install vagrant-vbguest
```

それでは以下のコマンドで仮想マシンを立ち上げてみましょう。最初はBoxのダウンロードとインストールなどが実行されるため、時間がかかる点に注意してください。。

```
$ vagrant up

==> default: Machine booted and ready!
==> default: Checking for guest additions in VM...
==> default: Mounting shared folders...
    default: /vagrant => /Users/yohei/work/vagrant-chef-sample
```

うまく起動できたら、SSHでゲストOSに接続できることも確認します。

```
$ vagrant ssh

```

その他にもよく使うコマンドとして以下があります。

- Vagarntの実行状況を確認する。

```
%vagrant status
```

- 仮想マシンを停止する。

```
% vagrant halt
```

- 仮想マシンを一時停止する。

```
% vagrant suspend
```

- 仮想マシンを再開する。

```
% vagrant resume
```

- 仮想マシンを破壊する。※仮想マシンを作り直したい時に使用する。

```
% vagrant destroy
```

# Chefのインストール
仮想マシンの起動まで確認できたため、次にChefを使ってPlay frameworkとPostgreSQLのインストールを行います。

まずChefの開発に必要なひと通りの開発環境がパッケージされたChef-DKをダウンロードして、インストールしてください。以下のURLからインストーラをダウンロードできます。画面中央にあるOSのアイコンをクリックし、OSにあったインストーラのダウンロードページを開く必要があります。

https://downloads.chef.io/chef-dk/

（注意）ホスト側ではChefは実行されませんが、ゲストOSにChefで環境設定するために必要なツール群がChef-DKでインストールされます。

以下のコマンドでChef-DKがインストールされていることを確認してください。

```
%chef -v
Chef Development Kit Version: 0.3.6
```

# Chefの実行に必要なVagrantプラグインのインストール

VagrantとChefを使ってゲストOSの設定を行う場合、以下のような流れでゲストOSの設定が行われます。これらはVagrantによって自動的に実行されるため、ユーザは特に意識する必要がありません。

- ホスト側でChef-zero serverという簡易的なサーバを立ち上げ、クックブックをサーバにアップロードする
- ゲスト側にChef-clientがインストールされる
- ゲスト側のChef-clientがホスト側のChef-zero serverからクックブックを受け取り、クックブックにそって各種設定を行う。

まず、ホスト側でChef-zero serverを立ち上げるために必要なVagrantプラグイン vagrant-chef-zero をインストールします。

```
% vagrant plugin install vagrant-chef-zero
```

次にゲストOSにChefをインストールするために必要なVagrantプラグイン vagrant-omnibus をインストールします。

```
% vagrant plugin install vagrant-omnibus
```

両プラグインを利用する設定を Vagrantfile に追記します。
以下の設定ファイルでは以下を指示しています。
- ゲストOSに最新のChefをインストールする
- Chef-zero のリポジトリとしてカレントディレクトリを設定する。

Vagrant.configure(2) do |config|
  config.omnibus.chef_version=:latest
  config.chef_zero.chef_repo_path = "."
   
  config.vm.box = "centos7"
  config.vm.box_url = "https://f0fff3908f081cb6461b407be80daf97f07ac418.googledrive.com/host/0BwtuV7VyVTSkUG1PM3pCeDJ4dVE/centos7.box"
end



```
% vagrant provision
```

今回、クックブックは可能な限り、コミュニティで開発されたものを再利用します。コミュニティで共有されているクックブックを取得するためのツールとして Berkshelf があります。この Berkshelf を Vagant から呼び出すために必要なvagrantプラグイン vagrant-berkshelf をインストールします。

```
% vagrant plugin install vagrant-berkshelf
```


Vagrant.configure(2) do |config|
  config.omnibus.chef_version=:latest
  config.chef_zero.chef_repo_path = "."

  config.vm.box = "centos7"
  config.vm.box_url = "https://f0fff3908f081cb6461b407be80daf97f07ac418.googledrive.com/host/0BwtuV7VyVTSkUG1PM3pCeDJ4dVE/centos7.box" 
end

# Install Play with a cookbook from the Chef Supermarket

There is a cookbook to install Play Framework on the Chef Supermarket, which is a website that Chef user can share own cookbooks to the other users. To download and use cookbooks on the Chef Supermarkrt, you should use Berkshelf. It is a dependency management tool for Chef cookbook. Berkshelf can download all cookbooks that depends on a cookbook you need.
 
You need to prepare Berksfile, which is a configuration file for Berkshelf. 

$ vim Berkshelf

source "https://api.berkshelf.com"
 
cookbook 'deploy-play'

  8 # Install vagrant plugins
  9 You need "vagrant-omnibus" plugin to provision chef on a VM you are launching.
 10 $ vagrant plugin install vagrant-omnibus
 11 $ vagrant plugin install vagrant-chef-zero
 12 $ vagrant plugin install vagrant-berkshelf
