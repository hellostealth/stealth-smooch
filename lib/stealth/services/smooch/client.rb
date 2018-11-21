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

        def initialize(reply:)
          @reply = reply
          @smooch = SmoochApi::ConversationApi.new
        end

        def transmit
          begin
            response = @smooch.send(
              reply[:reply_type],
              Stealth.config.smooch.app_id,
              reply[:recipient_id],
              reply[:message]
            )
          rescue SmoochApi::ApiError => e
            msg = Stealth::Logger.colorize('[Error]', color: :red) + " #{e.code}: #{e.response_body}"
            Stealth::Logger.l(topic: 'smooch', message: msg)
            raise Stealth::Errors::ServiceError
          end

          if response.present?
            Stealth::Logger.l(topic: "smooch", message: "Message #{response.message._id} successfully sent.")
          end
        end

        def self.generate_jwt_token
          payload = { scope: 'app' }
          jwtHeader = { kid: Stealth.config.smooch.key_id }
          token = JWT.encode(payload, Stealth.config.smooch.secret, 'HS256', jwtHeader)

          puts "#{Stealth::Logger.colorize('[JWT Token]', color: :green)} Your Smooch token is below. Please set the value `jwt_token` to the token in services.yml."
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

          puts "#{Stealth::Logger.colorize('[Web Hooks]', color: :green)} Your Smooch webhooks have been registered to: #{endpoint}"
        end

        def self.set_persistent_menu(menu)
          smooch_api = SmoochApi::IntegrationApi.new
          response = smooch_api.list_integrations(Stealth.config.smooch.app_id)
          response.integrations.each do |integration|
            begin
              smooch_api.update_integration_menu(Stealth.config.smooch.app_id, integration._id, menu)
              puts "#{Stealth::Logger.colorize('[Persistent Menu]', color: :green)} set for #{integration.type} integration."
            rescue SmoochApi::ApiError
              # Not all integrations support the persistent menu
              puts "#{Stealth::Logger.colorize('[Persistent Menu]', color: :red)} Skipping #{integration.type} integration. Persistent Menu is not supported."
              next
            end
          end
        end
      end

    end
  end
end
