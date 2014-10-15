require 'dm-migrations'


desc "auto migrates the database"
task :migrate do
  require './main'
  DataMapper.auto_migrate!
end

desc "auto upgrades the database"
task :upgrade do
  require './main'
  DataMapper.auto_upgrade! 
end