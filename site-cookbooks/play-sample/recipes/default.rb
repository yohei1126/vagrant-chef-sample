postgresql_database 'create databases' do
  connection(
    :host     => '127.0.0.1',
    :port     => 5432,
    :username => 'postgres',
    :password => node['postgresql']['password']['postgres']
  )
  database_name 'book'
  sql "create table book (
         id         bigint not null,
         title      varchar(255) not null,
         author     varchar(255) not null,
         publisher  varchar(255) not null,
         constraint pk_book primary key (id));
       create sequence book_seq;
       insert into book values('test book', 'test author', 'test publisher');
      "
  action :query
end

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

