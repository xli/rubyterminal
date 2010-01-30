require File.expand_path(File.dirname(__FILE__) + '/../test_helper')
require 'terminal'

class TestTerminal < Test::Unit::TestCase

  def test_start_terminal_with_status_file_created
    with_test_dir do
      Terminal.start do
        assert File.exists?('.terminal.running')
      end
    end
  end

  def test_should_remove_status_file_after_terminal_shutdown
    with_test_dir do
      Terminal.start
      assert !File.exists?('.terminal.running')
    end
  end

  def test_process_input_and_output
    with_test_dir do
      Terminal.start do
        Terminal.input(File.dirname(__FILE__) + "/simple_command.rb")
        output = "output from simple command"
        assert_process_output(output)
      end
    end
  end

  def test_process_error_command
    with_test_dir do
      Terminal.start do
        Terminal.input(File.dirname(__FILE__) + "/not_found")
        Terminal.process
        assert read_output_content
      end
    end
  end

  def test_should_remove_input_file_after_process_finished
    with_test_dir do
      File.open '.terminal.input', 'w' do |file|
        file << File.dirname(__FILE__) + '/simple_command.rb'
      end
      Terminal.process
      assert !File.exists?('.terminal.input')
    end
  end

  def test_should_take_care_command_args
    with_test_dir do
      Terminal.start do
        Terminal.input(File.dirname(__FILE__) + "/command_with_args.rb", ["args"])
        output = "args"
        assert_process_output(output)
      end
    end
  end

  def test_output_should_include_stderr_output_too
    with_test_dir do
      Terminal.start do
        Terminal.input(File.dirname(__FILE__) + '/stderr_output_command.rb')
        output = "error output"
        assert_process_output(output)
      end
    end
  end

  def test_detect_terminal_runtime
    Dir.chdir('/tmp') do
      assert_nil Terminal.running_dir
      Terminal.start do
        assert_equal Dir.pwd, Terminal.running_dir
      end
    end
  end

  def test_detect_terminal_runtime_in_parent_dir
    with_test_dir do
      Dir.mkdir 'child'
      Terminal.start do
        expected = Dir.pwd
        Dir.chdir 'child' do
          assert_equal expected, Terminal.running_dir
        end
      end
    end
  end

  def test_should_return_input_and_output_file_after_created_input_command_for_terminal
    with_test_dir do
      Terminal.start do
        input_file = nil
        output_file = nil
        Terminal.input(File.dirname(__FILE__) + '/simple_command.rb') do |input, output|
          input_file = input
          output_file = output
        end
        assert input_file
        assert output_file
        assert File.exists?(input_file.path)
        assert File.exists?(output_file.path)
        assert_equal "", output_file.read
      end
    end
  end

  def test_should_not_call_block_when_no_terminal_running_after_called_input
    Dir.chdir('/tmp') do
      block_called = false
      Terminal.input(File.dirname(__FILE__) + '/simple_command.rb') do |input, output|
        block_called = true
      end
      assert !block_called
    end
  end

  def test_input_argv_with_blank_string
    with_test_dir do
      Terminal.start do
        Terminal.input(File.dirname(__FILE__) + '/command_with_args.rb', ['a r g'])
        assert_process_output("a r g")
      end
    end
  end

  def test_input_argv_with_slash_n_string
    with_test_dir do
      Terminal.start do
        intput_file = Terminal.input(File.dirname(__FILE__) + '/command_with_args.rb', ["a\nr\ng"])
        assert_process_output("a\nr\ng")
      end
    end
  end

  def test_different_command_should_not_mix_outputs
    with_test_dir do
      Terminal.start do
        Terminal.input(File.dirname(__FILE__) + '/simple_command.rb')
        Terminal.input(File.dirname(__FILE__) + '/command_with_args.rb', 'output from second command')
        assert_process_output("output from second command")
      end
    end
  end

  def test_should_do_nothing_when_there_is_no_input_file_while_processing
    with_test_dir do
      Terminal.start do
        Terminal.process
        assert !File.exists?('.terminal.input')
        assert !File.exists?('.terminal.output')
      end
    end
  end

  def test_should_update_dollor_zero_for_process
    with_test_dir do
      Terminal.start do
        Terminal.input(File.dirname(__FILE__) + '/output_dollor_zero_command.rb')
        Terminal.process
        assert_process_output(File.dirname(__FILE__) + "/output_dollor_zero_command.rb")
      end
    end
  end

  def test_should_yield_block_for_process_in_sub_process
    with_test_dir do
      Terminal.start do
        Terminal.input(File.dirname(__FILE__) + '/simple_command.rb')
        Terminal.process do
          puts "process block"
        end
        assert_process_output("process block\noutput from simple command")
      end
    end
  end

  # TODO: do we need this?
  # def test_should_be_able_to_input_while_inside_terminal_sub_process
  #   with_test_dir do
  #     Terminal.start do
  #       Terminal.input(File.dirname(__FILE__) + '/simple_command.rb')
  #       Terminal.process do
  #         Terminal.input(File.dirname(__FILE__) + '/simple_command.rb')
  #       end
  #       assert_process_output("output from simple command")
  #     end
  #   end
  # end

  def assert_process_output(output)
    Terminal.process
    assert_equal output, read_output_content
  end
  def read_output_content
    File.open('.terminal.output') { |file| file.read }
  end
end
