module MAPI
  def self.swagger_version
    '1.2'
  end

  def self.api_version 
    '0.0.1'
  end

  def self.base_path
    ENV['MAPI_BASE_PATH'] || 'http://localhost:3100/mapi'
  end

  module Services
    module Base
      def self.included(mod)
        mod.include Swagger::Blocks
        mod.extend ClassMethods
        class << mod
          alias_method :swagger_api_root_without_normalization, :swagger_api_root
          alias_method :swagger_api_root, :swagger_api_root_with_normalization
        end
      end

      module ClassMethods
        def service_root(root=nil, app)
          @service_root = root if root
          @service_app = app
        end

        def service_root_path
          @service_root
        end

        def relative_get(path, &block)
          @service_app.get(service_root_path + path, &block)
        end

        def relative_post(path, &block)
          @service_app.post(service_root_path + path, &block)
        end

        def relative_put(path, &block)
          @service_app.put(service_root_path + path, &block)
        end

        def relative_delete(path, &block)
          @service_app.delete(service_root_path + path, &block)
        end

        def swagger_api_root_with_normalization(*args, &block)
          node = swagger_api_root_without_normalization(*args, &block)
          node.key :swaggerVersion, MAPI.swagger_version
          node.key :apiVersion, MAPI.api_version
          node.key :basePath, MAPI.base_path
          node.key :resourcePath, service_root_path
          node.data[:apis].each do |api_node|
            api_node.key :path, service_root_path + api_node.data[:path]
          end
          node
        end
      end
    end
  end
end