postgresql_connection_info = {
  :host     => '127.0.0.1',
  :port     => 5432,
  :username => 'postgres',
  :password => 'postgres'
}

postgresql_database 'sampledb' do
  connection postgresql_connection_info
  template 'DEFAULT'
  encoding 'DEFAULT'
  tablespace 'DEFAULT'
  connection_limit '-1'
  owner 'postgres'
  action :create
end

postgresql_database 'create table' do
  connection postgresql_connection_info
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

