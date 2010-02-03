
module RubyTerminal
  module RailsProjectEnvironment
    extend self

    def reload
      setup_dependencies_mechanism_as_load
      RubyTerminal.with_reload_paths do |paths|
        reload_modified_files_in(paths)
      end
    end

    def to_const_desc(file_path)
      load_path = detect_closest_load_path(file_path)
      file_path.gsub(/^#{load_path}/, '').gsub(/\.rb$/, '').camelize
    end

    def detect_closest_load_path(path)
      path = File.dirname(path)
      if $:.include?(path) || path == File.dirname(path)
        path
      else
        detect_closest_load_path(path)
      end
    end

    def reload_modified_files_in(reload_path_roots)
      reload_file_paths = $".select do |path|
        reload_path_roots.any? { |matcher| /^#{matcher}\// =~ path }
      end.select do |path|
        File.mtime(path) > RubyTerminal.options[:loaded_at]
      end

      reload_file_paths.each do |file_path|
        const_desc = to_const_desc(file_path)
        if unloadable(const_desc)
          #todo: only output in debug mode
          puts "RubyTerminal marked #{const_desc} as unloadable"
        end
      end

      dispatcher = ActionController::Dispatcher.respond_to?(:cleanup_application) ? ActionController::Dispatcher : ActionController::Dispatcher.new(StringIO.new)

      dispatcher.cleanup_application
      dispatcher.reload_application
    end

    def setup_dependencies_mechanism_as_load
      dependencies = defined?(Dependencies) ? Dependencies : ActiveSupport::Dependencies
      dependencies.mechanism = :load
    end
  end
end
