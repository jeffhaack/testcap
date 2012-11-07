require 'bundler/capistrano'

# ====================================================================== #
# Guide
# Configure the essential configurations below and do the following:
#  
#   Initial Deployment:
#     cap deploy:setup
#     cap deploy:cold
#     cap deploy:gems:install
#     cap deploy:db:create
#     cap deploy:db:migrate
#     cap deploy:passenger:restart
#
#     * or run "cap deploy:initial" do run all of these
#     
#   Then For Every Update Just Do:
#     git add .
#     git commit -am "some other commit"
#     git push origin master
#     cap deploy
# ====================================================================== #


# =================================== #
# START CONFIGURATION                 #
# =================================== #
set :default_environment, {
    'PATH' => "/usr/local/bin:/bin:/usr/bin:/bin:/usr/local/rvm/gems/ruby-1.9.2-p320/bin:/usr/local/rvm/bin",
    'GEM_HOME' => '/usr/local/rvm/rubies/ruby-1.9.2-p320/lib/ruby/gems/1.9.1',
    'GEM_PATH' => '/usr/local/rvm/rubies/ruby-1.9.2-p320/lib/ruby/gems/1.9.1',
    'BUNDLE_PATH' => '/usr/local/rvm/bin/bundle'  
}

set :application, "realEstate"
set :repository,  "git@github.com:jeffhaack/testcap.git"
set :scm, :git
#my_host = "108.166.79.19"
my_host = "108.166.95.229"

role :web, my_host
role :app, my_host
role :db,  my_host, :primary => true

set :user, "root"
set :group, "root"
set :deploy_to, "/var/www/testcap"
set :use_sudo, false

set :deploy_via, :copy
set :copy_strategy, :export
# =================================== #
# END CONFIGURATION                   #
# =================================== #


namespace :deploy do
  task :start do ; end
  task :stop do ; end

  desc "Restart the application"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end

  #desc "Copy the database.yml file into the latest release"
  #task :copy_in_database_yml do
  #  run "cp #{shared_path}/config/database.yml #{latest_release}/config/"
  #end

  task :cold do       # Overriding the default deploy:cold
    system 'cap deploy:update_code'
    system 'cap deploy:db:create'
    system 'cap deploy:db:schema:load'
    system 'cap deploy:db:seed'
    #system 'cap deploy:assets:precompile'
    
    #system 'cap deploy:custom:setup'
    #system 'cap deploy:whenever:update_crontab'
    start
  end

  task :say_hi, :roles => :app do
    puts "JUST SAYING HI"
  end  

  task :add_database_yml, :roles => :app do
    run "cd #{shared_path}; mkdir config; touch config/database.yml"
  end  

  namespace :db do
    task :migrate, :roles => :app do
      run "cd #{current_path}; rake db:migrate RAILS_ENV=production"
    end  

    task :create, :roles => :app do
      run "cd #{current_path}; bundle exec rake db:create RAILS_ENV=production"
    end

    namespace :schema do
      task :load, :roles => :app do
        run "cd #{current_path}; bundle exec rake db:schema:load RAILS_ENV=production"
      end
    end

    task :seed, :roles => :app do
      run "cd #{current_path}; bundle exec rake db:seed RAILS_ENV=production"
    end
  end

  namespace :whenever do
    task :update_crontab, :roles => :app do
      run "cd #{current_path}; whenever --update-crontab data_updates;"
    end
  end

  namespace :custom do
    task :setup, :roles => :app do
      # Make necessary dirs
      run "cd #{current_path}; mkdir public/assets/listing_images; mkdir public/assets/listing_images/temp;"
    end
  end

  task :get_listings, :roles => :app do
    run "cd #{current_path}; rake update_listings RAILS_ENV=production;"
  end

  task :setup_db, :roles => :app do
   copy_in_database_yml
   run "cd #{latest_release}; bundle exec rake db:create RAILS_ENV=production"
   run "cd #{latest_release}; bundle exec rake db:schema:load RAILS_ENV=production"
   run "cd #{latest_release}; bundle exec rake db:seed RAILS_ENV=production"
  end
  
end

after "deploy:update_code", "deploy:say_hi"

#before "deploy:assets:precompile", "deploy:setup_db"

#after "deploy:setup", "deploy:add_database_yml"



