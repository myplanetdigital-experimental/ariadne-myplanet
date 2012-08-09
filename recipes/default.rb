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

bash "Building site..." do
  user "vagrant"
  group "vagrant"
  cwd "/vagrant/data/profiles/#{repo}"
  code <<-EOH
    /vagrant/data/profiles/#{repo}/tmp/scripts/rerun/rerun 2ndlevel:build --build-file build-#{repo}.make --destination /mnt/www/html/#{repo} --project #{repo}
    cd /mnt/www/html/#{repo}
    drush sql-sync @myplanet.dev @self \
      --alias-path=/vagrant/data/profiles/#{repo}/tmp/scripts \
      --structure-tables-key=myplanet
      --yes
    drush vset install_profile myplanet
    drush sql-query "UPDATE field_data_body SET body_value = REPLACE(body_value, 'sites/all', 'profiles/myplanet');"
    drush sql-query "UPDATE field_revision_body SET body_value = REPLACE(body_value, 'sites/all', 'profiles/myplanet');"
    drush sql-query "UPDATE menu_router SET include_file = REPLACE(include_file, 'sites/all', 'profiles/myplanet');"
    drush sql-query "UPDATE menu_router SET access_arguments = REPLACE(access_arguments, 'sites/all', 'profiles/myplanet');"
    drush sql-query "UPDATE panels_pane SET cache = REPLACE(cache, 'sites/all', 'profiles/myplanet');"
    drush sql-query "UPDATE panels_pane SET configuration = REPLACE(configuration, 'sites/all', 'profiles/myplanet');"
    drush sql-query "UPDATE registry SET filename = REPLACE(filename, 'sites/all', 'profiles/myplanet');"
    drush sql-query "UPDATE registry_file SET filename = REPLACE(filename, 'sites/all', 'profiles/myplanet');"
    drush sql-query "UPDATE system SET filename = REPLACE(filename, 'sites/all', 'profiles/myplanet');"
    drush sql-query "UPDATE system SET info = REPLACE(info, 'sites/all', 'profiles/myplanet');"
    drush cc all
  EOH
  not_if "test -d /mnt/www/html/#{repo}"
  environment({
    'HOME' => '/home/vagrant',
    'RERUN_MODULES' => "/vagrant/data/profiles/#{repo}/tmp/scripts/rerun-modules",
    #'PATH' => "$PATH:/vagrant/data/profiles/#{repo}/tmp/scripts/rerun",
  })
  notifies :reload, "service[apache2]"
  notifies :restart, "service[varnish]"
end
