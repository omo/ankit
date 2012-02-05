
require 'date'
require 'json'

module Ankit
  class Envelope < Struct.new(:at, :round)
    def to_json(*a)
      { at: self.at.rfc3339, round: self.round }.to_json(*a)
    end

    def self.from_hash(hash)
      Envelope.new(DateTime.rfc3339(hash["at"]), hash["round"])
    end

    def self.parse(text) from_hash(JSON.parse(text)); end
    def self.fresh(round=0); self.new(DateTime.new, round); end
  end

  class Event
    attr_reader :envelope, :values

    def verb() @values["verb"]; end
    def verb=(val) @values["verb"] = val; end
    def name() @values["name"]; end
    def type() @values["type"]; end
    def maturity() @values["maturity"] || 0; end
    def card?() type == "card"; end
    def round() @envelope.round or 0; end
    def next_round() round + 2**maturity; end

    def initialize(env, values)
      @envelope, @values = env, values
    end

    def ==(other)
      @values == other.values && @envelope == other.envelope
    end
    
    def to_json(*a) { envelope: @envelope, values: @values }.to_json(*a); end

    def to_passed(env)
      Event.new(env, @values.merge({ "verb" => "passed", "maturity" => maturity + 1 }))
    end

    def to_failed(env)
      Event.new(env, @values.merge({ "verb" => "failed", "maturity" => 0 }))
    end

    def self.for_card(name, verb, env)
      self.new(env, { "type" => "card", "verb" => verb, "name" => name, "maturity" => 0 })
    end

    def self.from_hash(hash) Event.new(Envelope.from_hash(hash["envelope"]), hash["values"]); end
    def self.parse(text) from_hash(JSON.parse(text)); end
  end

  module EventFormatting
    def format_as_score(event)
      "verb:#{event.verb}, round:#{event.round}, maturity:#{event.maturity}"
    end
  end
end
