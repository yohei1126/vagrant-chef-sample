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

