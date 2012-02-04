

module Ankit
  class Card
    attr_reader :deckname, :source

    def self.parse(text, deckname=nil)
      lines = text.split(/\r?\n/).select { |l| !/^\#/.match(l) and !/^\s*$/.match(l) }
      return nil if lines.empty?

      params = lines.inject({}) do |a, line|
        case line
        when /^(\w+)\:(.*)/
          a[$1.downcase.to_sym] = $2.strip
        end
        a
      end

      self.new(deckname, params, text)
    end

    def initialize(deckname, params, source)
      @deckname, @params, @source = deckname, params, source
    end

    def original() @params[:o]; end
    def translation() @params[:t]; end
    def fullname() Datastore.fullname(deckname, name); end
    
    def name
      original.gsub(/\W+/, "-").gsub(/^\-/, "").gsub(/\-$/, "").downcase
    end
  end
end
