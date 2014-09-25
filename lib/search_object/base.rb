module SearchObject
  module Base
    def self.included(base)
      base.extend ClassMethods
      base.instance_eval do
        @config = {
          defaults:  {},
          actions:   {},
          scope:     nil,
        }
      end
    end

    def initialize(options = {})
      @search = self.class.build_internal_search options
    end

    def results
      @results ||= fetch_results
    end

    def results?
      results.any?
    end

    def count
      @count ||= @search.count self
    end

    def params(additions = {})
      if additions.empty?
        @search.params
      else
        @search.params.merge Helper.stringify_keys(additions)
      end
    end

    private

    def fetch_results
      @search.query self
    end

    module ClassMethods
      def inherited(base)
        config = self.instance_variable_get "@config"

        base.instance_eval do
          @config = config.dup
        end
      end

      # :api: private
      def build_internal_search(options)
        scope  = options.fetch(:scope) { @config[:scope] && @config[:scope].call } or raise MissingScopeError
        params = @config[:defaults].merge Helper.select_keys(Helper.stringify_keys(options.fetch(:filters, {})), @config[:actions].keys)

        Search.new scope, params, @config[:actions]
      end

      def scope(&block)
        @config[:scope] = block
      end

      def option(name, default = nil, &block)
        name = name.to_s

        @config[:defaults][name] = default unless default.nil?
        @config[:actions][name]  = block || ->(scope, value) { scope.where name => value unless value.blank? }

        define_method(name) { @search.param name }
      end

      def results(*args)
        new(*args).results
      end
    end
  end
end
