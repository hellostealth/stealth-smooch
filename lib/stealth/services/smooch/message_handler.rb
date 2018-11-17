# coding: utf-8
# frozen_string_literal: true

require 'stealth/services/smooch/events/message_event'
require 'stealth/services/smooch/events/postback_event'

module Stealth
  module Services
    module Smooch

      class MessageHandler < Stealth::Services::BaseMessageHandler

        attr_reader :service_message, :params, :headers,
                    :smooch_response, :smooch_message

        def initialize(params:, headers:)
          @params = params
          @headers = headers
        end

        def coordinate
          # Queue the request processing so we can respond quickly to Smooch
          # and also keep track of this message
          Stealth::Services::HandleMessageJob.perform_async('smooch', params, {})

          # Relay our acceptance
          [200, 'OK']
        end

        def process
          @service_message = ServiceMessage.new(service: 'smooch')
          @smooch_response = params
          @smooch_message = @smooch_response['messages'].first
          service_message.sender_id = get_sender_id
          service_message.timestamp = get_timestamp

          process_smooch_event

          service_message
        end

        private

          def get_sender_id
            smooch_response['appUser']['_id']
          end

          def get_timestamp
            Time.at(smooch_message['received']).to_datetime
          end

          def process_smooch_event
            if smooch_response['trigger'] == 'message:appUser'
              message_event = Stealth::Services::Smooch::MessageEvent.new(
                service_message: service_message,
                params: smooch_message
              )
            elsif smooch_response['trigger'] == 'postback'
              message_event = Stealth::Services::Smooch::PostbackEvent.new(
                service_message: service_message,
                params: smooch_response['postbacks'].first
              )
            end

            message_event.process
          end
      end

    end
  end
end
