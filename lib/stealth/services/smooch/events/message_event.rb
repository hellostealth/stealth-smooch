# coding: utf-8
# frozen_string_literal: true

module Stealth
  module Services
    module Smooch

      class MessageEvent

        attr_reader :service_message, :params

        def initialize(service_message:, params:)
          @service_message = service_message
          @params = params
        end

        def process
          fetch_message
          fetch_location
          fetch_attachments
        end

        private

          def fetch_message
            service_message.message = params['text']
          end

          def fetch_location
            if params['type'] == 'location'
              service_message.location = {
                lat: params['coordinates']['lat'],
                lng: params['coordinates']['lng']
              }
            end
          end

          def fetch_attachments
            if params['type'] == 'image'
              service_message.attachments << {
                type: 'image',
                url: params['mediaUrl']
              }
            elsif params['type'] == 'file'
              service_message.attachments << {
                type: params['mediaType'],
                url: params['mediaUrl']
              }
            end
          end

      end

    end
  end
end
