module RubyTerminal
  module Reloader
    extend self

    def reload_source_files
      if RubyTerminal.options[:reload_paths].nil? || RubyTerminal.options[:reload_paths].empty?
        return
      end
      reload_files_in(RubyTerminal.options[:reload_paths].collect{|path| File.expand_path(path)})
    end

    # remove all files from $" inside the +reload_path_roots+
    # and then require the removed files again
    def reload_files_in(reload_path_roots)
      unload_files_in(reload_path_roots).each { |file_path| require file_path }
    end
    def unload_files_in(unload_path_roots)
      unload_file_paths = $".select do |path|
        unload_path_roots.any? { |matcher| /^#{matcher}\// =~ path }
      end

      $".replace($" - unload_file_paths)
      unload_file_paths
    end
  end
end