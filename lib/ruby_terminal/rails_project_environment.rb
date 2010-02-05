
module RubyTerminal
  module RailsProjectEnvironment
    extend self

    # reload before sub process start
    def reload
      action_controller_dispatcher.reload_application
    end

    # cleanup rails environment for terminal process
    # we'll mark all reloadable const (Module/Class) unload,
    # so that sub process could start with fresh one
    def cleanup
      RubyTerminal.options[:reload_paths] << "app" << "lib" << "test"
      RubyTerminal.with_reload_paths do |paths|
        mark_const_unloadable_in(paths)
      end
      action_controller_dispatcher.cleanup_application
    end

    def action_controller_dispatcher
      ActionController::Dispatcher.respond_to?(:cleanup_application) ? ActionController::Dispatcher : ActionController::Dispatcher.new(StringIO.new)
    end

    def mark_const_unloadable_in(reload_path_roots)
      reload_file_paths = dependencies.loaded.select do |path|
        reload_path_roots.any? { |matcher| /^#{matcher}\// =~ path }
      end.uniq.sort

      # must remove reload_file_paths from $", otherwize we'll get wild exception
      # for rails may load all ruby files inside project as cache, so we need find
      # out all files need to be unload instead of searching from +reload_file_paths+,
      # which is based on active support const missing.
      paths = $".select { |path| reload_path_roots.any? { |matcher| /^#{matcher}\// =~ path }}
      $".replace($" - paths)

      reload_file_paths.each do |file_path|
        const_desc = to_const_desc(file_path)
        
        if valid_const_desc?(const_desc)
          unloadable(const_desc)
        end
      end
    end

    def valid_const_desc?(const_desc)
      eval("defined? #{const_desc}")
    rescue Exception
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

    # todo: remove this method, it seems, change mechanism does not help, and causes reload class
    # problem
    def setup_dependencies_mechanism_as_load
      dependencies.mechanism = :load
    end
    def dependencies
      defined?(Dependencies) ? Dependencies : ActiveSupport::Dependencies
    end
  end
end
