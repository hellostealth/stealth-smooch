# coding: utf-8
# frozen_string_literal: true

module Stealth
  module Services
    module Smooch

      class PostbackEvent

        attr_reader :service_message, :params

        def initialize(service_message:, params:)
          @service_message = service_message
          @params = params
        end

        def process
          fetch_payload
        end

        private

          def fetch_payload
            service_message.payload = params['action']['payload']
          end

      end

    end
  end
end
