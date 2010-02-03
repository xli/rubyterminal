require File.expand_path(File.dirname(__FILE__) + '/../test_helper')
require File.dirname(__FILE__) + '/../../lib/ruby_terminal/rails_project_environment'
require 'rubygems'
require 'active_support'

class TestRailsProjectEnvironment < Test::Unit::TestCase
  include RubyTerminal::RailsProjectEnvironment
  def test_file_path_to_const_desc
    $:.unshift('/a/b/c')
    assert_equal '::D::E', to_const_desc('/a/b/c/d/e')
    assert_equal '::D::E', to_const_desc('/a/b/c/d/e.rb')
  end
end
