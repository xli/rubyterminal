module RubyTerminal
  module Reloader
    extend self

    def reload_modified_source_files
      if RubyTerminal.options[:reload_paths].nil? || RubyTerminal.options[:reload_paths].empty?
        return
      end
      reload_modified_files_in(RubyTerminal.options[:reload_paths].collect{|path| File.expand_path(path)})
    end

    # remove all files from $" inside the +reload_path_roots+
    # and then require the removed files again
    def reload_modified_files_in(reload_path_roots)
      reload_file_paths = $".select do |path|
        reload_path_roots.any? { |matcher| /^#{matcher}\// =~ path }
      end.select do |path|
        File.mtime(path) > RubyTerminal.options[:loaded_at]
      end

      $".replace($" - reload_file_paths)

      reload_file_paths.each do |file_path|
        # if Object.respond_to?(:remove_class)
          # const = file_path.split('/').last.camelize.gsub(/\.rb$/, '')
          # ActiveSupport::Dependencies.remove_constant(const)
          # Object.remove_class(const.constantize)
        # end
        require file_path
        puts "reloaded #{file_path.inspect}"
      end
    end
  end
end