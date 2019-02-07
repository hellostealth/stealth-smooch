# coding: utf-8
# frozen_string_literal: true

module Stealth
  module Services
    module Smooch

      class ConversationStartEvent

        attr_reader :service_message, :params

        def initialize(service_message:, params:)
          @service_message = service_message
          @params = params
        end

        def process
          service_message.payload = 'conversation_start'
        end

      end

    end
  end
end
