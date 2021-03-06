require 'bundler/capistrano'

set :default_environment, {
    'PATH' => "/usr/local/bin:/bin:/usr/bin:/bin:/usr/local/rvm/gems/ruby-1.9.2-p320/bin:/usr/local/rvm/bin",
    'GEM_HOME' => '/usr/local/rvm/rubies/ruby-1.9.2-p320/lib/ruby/gems/1.9.1',
    'GEM_PATH' => '/usr/local/rvm/rubies/ruby-1.9.2-p320/lib/ruby/gems/1.9.1',
    'BUNDLE_PATH' => '/usr/local/rvm/bin/bundle'  
}

set :application, "testcap"
set :repository,  "git@github.com:jeffhaack/testcap.git"
set :scm, :git
#my_host = "108.166.79.19"
my_host = "108.166.95.229"

role :web, my_host                          # Your HTTP server, Apache/etc
role :app, my_host                          # This may be the same as your `Web` server
role :db,  my_host, :primary => true # This is where Rails migrations will run

set :user, "root"
set :group, "root"
set :deploy_to, "/var/www/testcap"
set :use_sudo, false

set :deploy_via, :copy
set :copy_strategy, :export


namespace :deploy do
  task :start do ; end
  task :stop do ; end
  desc "Restart the application"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end

  desc "Copy the database.yml file into the latest release"
  task :copy_in_database_yml do
    run "cp #{shared_path}/config/database.yml #{latest_release}/config/"
  end

  task :cold do       # Overriding the default deploy:cold
    update
    create_db         # Create the database
    load_schema       # My own step, replacing migrations.
    load_seeds        # Seed database
    start
  end

  task :add_database_yml, :roles => :app do
    run "cd #{shared_path}; mkdir config; touch config/database.yml"
  end  

  task :migrate_db, :roles => :app do
    run "cd #{current_path}; rake db:migrate RAILS_ENV=production"
  end  

  task :create_db, :roles => :app do
    run "cd #{current_path}; bundle exec rake db:create RAILS_ENV=production"
  end

  task :load_schema, :roles => :app do
    run "cd #{current_path}; bundle exec rake db:schema:load RAILS_ENV=production"
  end

  task :load_seeds, :roles => :app do
    run "cd #{current_path}; bundle exec rake db:seed RAILS_ENV=production"
  end
end
before "deploy:assets:precompile", "deploy:copy_in_database_yml"

after "deploy:setup", "deploy:add_database_yml"




