repo = node['ariadne']['project']
site_url = "#{repo}.dev"

web_app site_url do
  cookbook "ariadne"
  template "sites.conf.erb"
  server_name site_url
  server_aliases [ "*.#{site_url}" ]
  docroot "/mnt/www/html/#{repo}"
  port node['apache']['listen_ports'].to_a[0]
end

if node['ariadne']['clean']
  execute "chmod -R 777 /mnt/www/html/#{repo}"
  %W{
    /vagrant/data/profiles/#{repo}
    /mnt/www/html/#{repo}
  }.each do |dir|
    directory dir do
      recursive true
      action :delete
    end
  end
end

git "/vagrant/data/profiles/#{repo}" do
  user "vagrant"
  repository "git@github.com:myplanetdigital/#{repo}.git"
  reference "develop"
  enable_submodules true
  action :sync
end

bash "Prepping site..." do
  action :nothing
  user "vagrant"
  group "vagrant"
  cwd "/mnt/www/html/#{repo}"
  code <<-EOH
    drush sql-sync @myplanet.dev @self \
      --alias-path=/vagrant/data/profiles/#{repo}/tmp/scripts \
      --structure-tables-key=myplanet \
      --yes
    drush sql-dump \
      --result-file=/tmp/#{repo}.sql
    sed -i 's/sites\\/all\\/modules/profiles\\/#{repo}\\/modules/g' /tmp/#{repo}.sql
    sed -i 's/sites\\/all\\/themes/profiles\\/#{repo}\\/themes\\/custom/g' /tmp/#{repo}.sql
    `drush sql-connect` < /tmp/#{repo}.sql
    drush vset install_profile myplanet
    drush cc all
  EOH
  environment({
    'HOME' => '/home/vagrant',
  })
end

bash "Building site..." do
  user "vagrant"
  group "vagrant"
  cwd "/vagrant/data/profiles/#{repo}"
  code <<-"EOH"
    tmp/scripts/rerun/rerun 2ndlevel:build --build-file build-#{repo}.make --destination /mnt/www/html/#{repo} --project #{repo}
  EOH
  not_if "test -d /mnt/www/html/#{repo}"
  environment({
    'HOME' => '/home/vagrant',
    'RERUN_MODULES' => "/vagrant/data/profiles/#{repo}/tmp/scripts/rerun-modules",
    #'PATH' => "${PATH}:/vagrant/data/profiles/#{repo}/tmp/scripts/rerun",
  })
  notifies :reload, "service[apache2]"
  notifies :restart, "service[varnish]"
  notifies :run, "bash[Prepping site...]", :immediately 
end
