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
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`

role :web, "108.166.79.19"                          # Your HTTP server, Apache/etc
role :app, "108.166.79.19"                          # This may be the same as your `Web` server
role :db,  "108.166.79.19", :primary => true # This is where Rails migrations will run
#role :db,  "your slave db-server here"

# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
# namespace :deploy do
#   task :start do ; end
#   task :stop do ; end
#   task :restart, :roles => :app, :except => { :no_release => true } do
#     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
#   end
# end

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
    load_schema       # My own step, replacing migrations.
    load_seeds        # Seed database
    start
  end

  task :load_schema, :roles => :app do
    run "cd #{current_path}; rake db:schema:load RAILS_ENV=production"
  end

  task :load_seeds, :roles => :app do
    run "cd #{current_path}; rake db:seed RAILS_ENV=production"
  end
end
before "deploy:assets:precompile", "deploy:copy_in_database_yml"





