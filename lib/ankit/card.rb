

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
  end
end
