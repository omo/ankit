

module Ankit
  class Card
    attr_reader :deckname, :source

    def self.parse(text)
      lines = text.split(/\r?\n/).select { |l| !/^\#/.match(l) and !/^\s*$/.match(l) }
      return nil if lines.empty?

      params = lines.inject({}) do |a, line|
        case line
        when /^(\w+)\:(.*)/
          a[$1.downcase.to_sym] = $2.strip
        end
        a
      end

      self.new(params)
    end

    def initialize(params)
      @params = params
    end

    def original() @params[:o]; end
    def translation() @params[:t]; end
    
    def name
      original.gsub(/\W+/, "-").gsub(/^\-/, "").gsub(/\-$/, "").downcase
    end

    def plain_original; original.gsub(/\[(.*?)\]/) { |t| $1 }; end

    # FIXME: Needs tests.
    def match?(text)
      plain_original == text
    end
  end

  module CardNaming
    def to_card_name(path) File.basename(path, ".card"); end
    def to_card_path(dir, name) File.join(dir, "#{name}.card"); end
    def card_wildcard_for(dir) File.join(dir, "*.card"); end
  end
end
