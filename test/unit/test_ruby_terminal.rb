require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class TestRubyTerminal < Test::Unit::TestCase

  def test_happy_path
    with_test_dir do
      RubyTerminal.start do
        fork do
          loop { break if RubyTerminal.process }
        end
        RubyTerminal.execute(File.dirname(__FILE__) + "/test_ruby_terminal.rb", [])
        Process.wait # wait until the forked process finish, otherwize the tests folowing would be failed
      end
    end
  end

  def test_start_terminal_with_status_file_created
    with_test_dir do
      running = false
      RubyTerminal.start do
        running = File.exists?('.terminal.running')
      end
      assert running
    end
  end

  def test_should_remove_status_file_after_terminal_shutdown
    with_test_dir do
      RubyTerminal.start
      assert !File.exists?('.terminal.running')
    end
  end

  def test_process_input_and_output
    with_test_dir do
      RubyTerminal.start do
        RubyTerminal.input(File.dirname(__FILE__) + "/simple_command.rb")
        output = "output from simple command"
        assert_process_output(output)
      end
    end
  end

  def test_process_error_command
    with_test_dir do
      RubyTerminal.start do
        RubyTerminal.input(File.dirname(__FILE__) + "/not_found")
        RubyTerminal.process
        assert read_output_content
      end
    end
  end

  def test_should_remove_input_file_after_process_finished
    with_test_dir do
      File.open '.terminal.input', 'w' do |file|
        file << File.dirname(__FILE__) + '/simple_command.rb'
      end
      RubyTerminal.process
      assert !File.exists?('.terminal.input')
    end
  end

  def test_should_take_care_command_args
    with_test_dir do
      RubyTerminal.start do
        RubyTerminal.input(File.dirname(__FILE__) + "/command_with_args.rb", ["args"])
        output = "args"
        assert_process_output(output)
      end
    end
  end

  def test_output_should_include_stderr_output_too
    with_test_dir do
      RubyTerminal.start do
        RubyTerminal.input(File.dirname(__FILE__) + '/stderr_output_command.rb')
        output = "error output"
        assert_process_output(output)
      end
    end
  end

  def test_detect_terminal_runtime
    Dir.chdir('/tmp') do
      assert_nil RubyTerminal.running_dir
      RubyTerminal.start do
        assert_equal Dir.pwd, RubyTerminal.running_dir
      end
    end
  end

  def test_detect_terminal_runtime_in_parent_dir
    with_test_dir do
      Dir.mkdir 'child'
      RubyTerminal.start do
        expected = Dir.pwd
        Dir.chdir 'child' do
          assert_equal expected, RubyTerminal.running_dir
        end
      end
    end
  end

  def test_should_return_input_and_output_file_after_created_input_command_for_terminal
    with_test_dir do
      RubyTerminal.start do
        input_file = nil
        output_file = nil
        RubyTerminal.input(File.dirname(__FILE__) + '/simple_command.rb') do |input, output|
          input_file = input
          output_file = output
        end
        assert input_file
        assert output_file
        assert File.exists?(input_file.path)
        assert File.exists?(output_file.path)
      end
    end
  end

  def test_should_not_call_block_when_no_terminal_running_after_called_input
    Dir.chdir('/tmp') do
      block_called = false
      RubyTerminal.input(File.dirname(__FILE__) + '/simple_command.rb') do |input, output|
        block_called = true
      end
      assert !block_called
    end
  end

  def test_input_argv_with_blank_string
    with_test_dir do
      RubyTerminal.start do
        RubyTerminal.input(File.dirname(__FILE__) + '/command_with_args.rb', ['a r g'])
        assert_process_output("a r g")
      end
    end
  end

  def test_input_argv_with_slash_n_string
    with_test_dir do
      RubyTerminal.start do
        intput_file = RubyTerminal.input(File.dirname(__FILE__) + '/command_with_args.rb', ["a\nr\ng"])
        assert_process_output("a\nr\ng")
      end
    end
  end

  def test_different_command_should_not_mix_outputs
    with_test_dir do
      RubyTerminal.start do
        RubyTerminal.input(File.dirname(__FILE__) + '/simple_command.rb')
        RubyTerminal.input(File.dirname(__FILE__) + '/command_with_args.rb', 'output from second command')
        assert_process_output("output from second command")
      end
    end
  end

  def test_should_do_nothing_when_there_is_no_input_file_while_processing
    with_test_dir do
      RubyTerminal.start do
        RubyTerminal.process
        assert !File.exists?('.terminal.input')
        assert !File.exists?('.terminal.output')
      end
    end
  end

  def test_should_update_dollor_zero_for_process
    with_test_dir do
      RubyTerminal.start do
        RubyTerminal.input(File.dirname(__FILE__) + '/output_dollor_zero_command.rb')
        RubyTerminal.process
        assert_process_output(File.dirname(__FILE__) + "/output_dollor_zero_command.rb")
      end
    end
  end

  def assert_process_output(output)
    RubyTerminal.process
    assert_equal output, read_output_content
  end
  def read_output_content
    File.open('.terminal.output') { |file| file.read }
  end
end
