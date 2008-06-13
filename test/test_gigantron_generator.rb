require File.join(File.dirname(__FILE__), "test_generator_helper.rb")

class TestGigantronGenerator < Test::Unit::TestCase
  include RubiGen::GeneratorTestHelper

  def setup
    bare_setup
  end
  
  def teardown
    bare_teardown
  end
  
  # Some generator-related assertions:
  #   assert_generated_file(name, &block) # block passed the file contents
  #   assert_directory_exists(name)
  #   assert_generated_class(name, &block)
  #   assert_generated_module(name, &block)
  #   assert_generated_test_for(name, &block)
  # The assert_generated_(class|module|test_for) &block is passed the body of the class/module within the file
  #   assert_has_method(body, *methods) # check that the body has a list of methods (methods with parentheses not supported yet)
  #
  # Other helper methods are:
  #   app_root_files - put this in teardown to show files generated by the test method (e.g. p app_root_files)
  #   bare_setup - place this in setup method to create the APP_ROOT folder for each test
  #   bare_teardown - place this in teardown method to destroy the TMP_ROOT or APP_ROOT folder after each test
  
  def test_generator_without_options
    run_generator('gigantron', [APP_ROOT], sources)
    assert_directory_exists "tasks/"
    assert_generated_file   "tasks/import.rake"
    assert_directory_exists "test/"
    assert_generated_file   "test/test_helper.rb"
    assert_directory_exists "test/tasks/"
    assert_generated_file   "test/tasks/test_import.rb"
    assert_directory_exists "test/models/"
    assert_directory_exists "lib/"
    assert_directory_exists "models/"
    assert_directory_exists "db/"
    assert_directory_exists "script/"
    assert_generated_file   "script/generate"
    assert_generated_file   "database.yml"
    assert_generated_file   "Rakefile"
    assert_generated_file   "initialize.rb"
  end

#=begin
  context "Generated project" do
    setup do
      run_generator('gigantron', [APP_ROOT], sources)

      GTRON_ENV = :test
      require File.join(APP_ROOT, "initialize.rb")
      require 'gigantron/migrator'

      File.open("#{APP_ROOT}/database.yml", "w") do |f|
        f.puts %Q{
:test:
  :adapter: jdbcsqlite3
  :url: jdbc:sqlite:#{GTRON_ROOT}/db/test.sqlite3
        }
      end

      get_db_conn(GTRON_ENV)
    end

    context "with migration and model" do
      setup do
        run_generator('model', ['Foo'], sources)
        if !File.exists? "#{APP_ROOT}/db/migrate/001_create_foos.rb"
          run_generator('migration', ['CreateFoos'], sources)
        end

        assert File.exists? "#{APP_ROOT}/db/migrate/001_create_foos.rb"
        File.open("#{APP_ROOT}/db/migrate/001_create_foos.rb", "w") do |f|
          f.puts %q{
class CreateFoos < ActiveRecord::Migration
  def self.up
    create_table :foos do |t|
      t.string :title
    end

    %w(Foo Bar).each do |t|
      Foo.new(:title => t).save
    end
  end

  def self.down
    drop_table :foos
  end
end
          }
        end
        get_db_conn(GTRON_ENV)
        Gigantron.migrate_dbs
      end

      should "create test db" do
        assert File.exists? "#{APP_ROOT}/db/test.sqlite3"
      end

      should "create table foos and populate" do
        assert_equal Foo.find(:all).size, 2
      end
    end
  end
#=end
  
  private
  def sources
    [RubiGen::PathSource.new(:test, File.join(File.dirname(__FILE__),"..", generator_path)),
    RubiGen::PathSource.new(:test_components, File.join(File.dirname(__FILE__),"..", "gigantron_generators"))]
  end
  
  def generator_path
    "app_generators"
  end
end
