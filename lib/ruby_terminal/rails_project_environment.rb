require 'ruby_terminal/reloader'

module RubyTerminal
  module RailsProjectEnvironment
    extend self

    def reload
      reload_action_controller
    end

    def reload_action_controller
      ::ActionController::Routing::Routes.reload
    end

  end
end
