# coding: utf-8
# frozen_string_literal: true

require 'stealth/services/smooch/message_handler'
require 'stealth/services/smooch/reply_handler'
require 'stealth/services/smooch/setup'

module Stealth
  module Services
    module Smooch

      class Client < Stealth::Services::BaseClient

        attr_reader :reply

        def initialize(reply:, endpoint: 'messages')
          @reply = reply
          @smooch = SmoochApi::ConversationApi.new
        end

        def transmit
          response = @smooch.send(
            reply[:reply_type],
            Stealth.config.smooch.app_id,
            reply[:recipient_id],
            reply[:message]
          )

          if response.present?
            Stealth::Logger.l(topic: "smooch", message: "Message #{response.message._id} successfully sent.")
          end
        end

        def self.generate_jwt_token
          payload = { scope: 'app' }
          jwtHeader = { kid: Stealth.config.smooch.key_id }
          token = JWT.encode(payload, Stealth.config.smooch.secret, 'HS256', jwtHeader)

          puts "Your Smooch token is below. Please set the value `jwt_token` to the token in services.yml."
          puts token
        end

        def self.register_webhooks(endpoint:)
          smooch_webhook_api = SmoochApi::WebhookApi.new
          webhook_create_body = SmoochApi::WebhookCreate.new(
            target: endpoint,
            triggers: ['message:appUser', 'postback']
          )

          response = smooch_webhook_api.create_webhook(
            Stealth.config.smooch.app_id,
            webhook_create_body
          )

          puts "Your Smooch webhooks have been registered to: #{endpoint}"
        end
      end

    end
  end
end
