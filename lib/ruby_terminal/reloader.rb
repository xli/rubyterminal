module RubyTerminal
  # Not sure we need this module for non-rails project
  module Reloader
    extend self

    def reload_modified_source_files
      RubyTerminal.with_reload_paths do |paths|
        reload_modified_files_in(paths)
      end
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
        load file_path
        puts "reloaded #{file_path.inspect}"
      end
    end
  end
end