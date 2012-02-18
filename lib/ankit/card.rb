

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

    def match?(text)
      return :match if plain_original == text
      return :wrong if text.empty?

      hiddens = decorated_original { |m| "*"*m[1].size }.chars.to_a
      inside_essentials = to_enum(:diff_from_original, text).find do |ch|
        ch.action != "=" && hiddens[ch.old_position] == "*"
      end

      inside_essentials ? :wrong : :typo
    end

    def diff_from_original(text, &block)
      changes = Diff::LCS.sdiff(text, plain_original)
      changes.map do |ch|
        block.call(ch)
      end.join("")
    end

    def decorated_original(&block)
      decoed = original.gsub(/\[(.*?)\]/) { |t| block.call(Regexp.last_match) }
      decoed != original ? decoed : decoed.gsub(/^(.*)$/) { |t| block.call(Regexp.last_match) }
    end

    def plain_original; decorated_original { |m| m[1] }; end
  end

  module CardNaming
    def to_card_name(path) File.basename(path, ".card"); end
    def to_card_path(dir, name) File.join(dir, "#{name}.card"); end
    def card_wildcard_for(dir) File.join(dir, "*.card"); end
  end
end
