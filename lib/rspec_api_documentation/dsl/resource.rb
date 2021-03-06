module RspecApiDocumentation::DSL
  module Resource
    extend ActiveSupport::Concern

    module ClassMethods
      def self.define_action(method)
        define_method method do |*args, &block|
          options = if args.last.is_a?(Hash) then args.pop else {} end
          options[:method] = method
          options[:route] = args.first
          options[:api_doc_dsl] = :endpoint
          args.push(options)
          args[0] = "#{method.to_s.upcase} #{args[0]}"
          context(*args, &block)
        end
      end

      define_action :get
      define_action :post
      define_action :put
      define_action :delete
      define_action :head
      define_action :patch

      def callback(*args, &block)
        begin
          require 'webmock'
        rescue LoadError
          raise "Callbacks require webmock to be installed"
        end
        self.send(:include, WebMock::API)

        options = if args.last.is_a?(Hash) then args.pop else {} end
        options[:api_doc_dsl] = :callback
        args.push(options)

        context(*args, &block)
      end

      def parameter(name, description, options = {})
        parameters.push(options.merge(:name => name.to_s, :description => description))
      end

      def header(name, value)
        headers[name] = value
      end

      private
      def parameters
        metadata[:parameters] ||= []
        if superclass_metadata && metadata[:parameters].equal?(superclass_metadata[:parameters])
          metadata[:parameters] = Marshal.load(Marshal.dump(superclass_metadata[:parameters]))
        end
        metadata[:parameters]
      end

      def headers
        metadata[:headers] ||= {}
        if superclass_metadata && metadata[:headers].equal?(superclass_metadata[:headers])
          metadata[:headers] = Marshal.load(Marshal.dump(superclass_metadata[:headers]))
        end
        metadata[:headers]
      end

      def parameter_keys
        parameters.map { |param| param[:name] }
      end
    end

    def app
      RspecApiDocumentation.configuration.app
    end

    def client
      @client ||= RspecApiDocumentation::RackTestClient.new(self)
    end

    def no_doc(&block)
      requests = example.metadata[:requests]
      example.metadata[:requests] = []

      instance_eval &block

      example.metadata[:requests] = requests
    end
  end
end
