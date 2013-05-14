require 'zendesk_apps_support'

Given /^an app directory "(.*?)" exists$/ do |app_dir|
  @app_dir = app_dir
  FileUtils.rm_rf(@app_dir)
  FileUtils.mkdir_p(@app_dir)
end

Given /^an app is created in directory "(.*?)"$/ do |app_dir|
  steps %Q{
    Given an app directory "#{app_dir}" exists
    And I run "zat new" command with the following details:
      | author name  | John Citizen      |
      | author email | john@example.com  |
      | app name     | John Test App     |
      | app locations | ticket_sidebar   |
  }
end

When /^I run "(.*?)" command with the following details:$/ do |cmd, table|
  IO.popen(cmd, "w+") do |pipe|
    key = table.rows_hash

    pipe.puts key["author name"]
    pipe.puts key["author email"]
    pipe.puts key["app name"]

    ZendeskAppsSupport::Validations::Manifest::LOCATIONS_AVAILABLE.each do |location|
      if key["app locations"][location]
        pipe.puts 'y'
      else
        pipe.puts 'n'
      end
    end

    pipe.puts @app_dir
    pipe.close_write
    @output = pipe.readlines
    @output.each {|line| puts line}
  end
end

When /^I run the command "(.*?)" to (validate|package|clean) the app$/ do |cmd, action|
  IO.popen(cmd, "w+") do |pipe|
    pipe.puts "\n"
    pipe.close_write
    @output = pipe.readlines
    @output.each {|line| puts line}
  end
end

Then /^the app file "(.*?)" is created with:$/ do |file, content|
  File.read(file).chomp.gsub(' ', '').should == content.gsub(' ', '')
end


Then /^the zip file should exist in directory "(.*?)"$/ do |path|
  Dir[path + '/app-*.zip'].size.should == 1
end

Given /^I remove file "(.*?)"$/ do |file|
  File.delete(file)
end

Then /^the zip file in "(.*?)" folder should not exist$/ do |path|
  Dir[path + '/app-*.zip'].size.should == 0
end

Then /^it should pass the validation$/ do
  @output.last.should =~ /OK/
  $?.should == 0
end

Then /^the command output should contain "(.*?)"$/ do |output|
  @output.join.should =~ /#{output}/
end
