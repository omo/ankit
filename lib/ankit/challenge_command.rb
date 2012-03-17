# -*- coding: utf-8 -*-

require 'ankit/command'
require 'ankit/challenge'

module Ankit
  class ChallengeCommand < Command
    include Challenge, RoundCounting, Coming, Finding
    include Challenge::Approaching
    available

    define_options do |spec, options| 
      spec.on("-l", "--limit N") { |n| options[:limit] = n.to_i }
    end

    DEFAULT_COUNT = 50

    def session; @session ||= Challenge::Session.make(runtime, coming_limit); end

    def execute()
      Signal.trap("INT") do
        runtime.clear_screen
        STDERR.print("Quit.\n")
        exit(0)
      end

      initial_state.keep_pumping_until { |state| state.over? }
      Signal.trap("INT", "DEFAULT")
    end

    private

    def coming_limit
      options[:limit] or DEFAULT_COUNT
    end
  end
end
