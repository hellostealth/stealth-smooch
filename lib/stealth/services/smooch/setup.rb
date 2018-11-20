# coding: utf-8
# frozen_string_literal: true

require 'stealth/services/smooch/client'

module Stealth
  module Services
    module Smooch

      class Setup

        class << self
          def trigger
            SmoochApi.configure do |config|
              config.api_key['Authorization'] = Stealth.config.smooch.jwt_token
              config.api_key_prefix['Authorization'] = 'Bearer'
            end

            reply_handler = Stealth::Services::Smooch::ReplyHandler.new
            menu = reply_handler.persistent_menu
            Stealth::Services::Smooch::Client.set_persistent_menu(menu)

            if ENV['SMOOCH_ENDPOINT'].present?
              Stealth::Services::Smooch::Client.register_webhooks(endpoint: ENV['SMOOCH_ENDPOINT'])
            else
              puts '[ERROR] Please set SMOOCH_ENDPOINT to the endpoint that will receive Smooch webhooks.'
            end
          end
        end

      end

    end
  end
end
