require 'ruby_terminal/reloader'

module RubyTerminal
  module RailsProjectEnvironment
    extend Reloader
    extend self

    def reload
      reload_files_in(find_reload_path_roots)
      reload_action_controller
    end

    def reload_action_controller
      if ActionController::Dispatcher.respond_to?(:reload_application)
        ActionController::Dispatcher.reload_application
      else
        ActionController::Dispatcher.new(StringIO.new).reload_application
      end
    end

    def find_reload_path_roots
      if defined?(RELOAD_PATHS) && RELOAD_PATHS.is_a?(Array) && RELOAD_PATHS.any?
        RELOAD_PATHS
      else
        default_reload_path_roots
      end
    end

    def default_reload_path_roots
      %w(app lib)
    end
  end
end
