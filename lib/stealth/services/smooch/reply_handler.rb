# coding: utf-8
# frozen_string_literal: true

module Stealth
  module Services
    module Smooch

      class ReplyHandler < Stealth::Services::BaseReplyHandler

        attr_reader :recipient_id, :reply

        def initialize(recipient_id: nil, reply: nil)
          @recipient_id = recipient_id
          @reply = reply
        end

        def text
          message = SmoochApi::MessagePost.new(
            role: 'appMaker',
            type: 'text',
            text: reply['text']
          )

          if reply['suggestions'].present?
            smooch_suggestions = generate_suggestions(suggestions: reply['suggestions'])
            message.actions = smooch_suggestions
          end

          if reply['buttons'].present?
            smooch_buttons = generate_buttons(buttons: reply['buttons'])
            message.actions = smooch_buttons
          end

          message_template(action: 'post_message', message: message)
        end

        def image
          check_if_arguments_are_valid!(
            suggestions: reply['suggestions'],
            buttons: reply['buttons']
          )

          message = SmoochApi::MessagePost.new(
            role: 'appMaker',
            type: 'image',
            mediaUrl: reply['image_url']
          )

          if reply['suggestions'].present?
            smooch_suggestions = generate_suggestions(suggestions: reply['suggestions'])
            message.actions = smooch_suggestions
          end

          message_template(action: 'post_message', message: message)
        end

        def audio
          check_if_arguments_are_valid!(
            suggestions: reply['suggestions'],
            buttons: reply['buttons']
          )

          message = SmoochApi::MessagePost.new(
            role: 'appMaker',
            type: 'file',
            text: reply['text'],
            mediaUrl: reply['audio_url']
          )

          if reply['suggestions'].present?
            smooch_suggestions = generate_suggestions(suggestions: reply['suggestions'])
            message.actions = smooch_suggestions
          end

          message_template(action: 'post_message', message: message)
        end

        def video
          check_if_arguments_are_valid!(
            suggestions: reply['suggestions'],
            buttons: reply['buttons']
          )

          message = SmoochApi::MessagePost.new(
            role: 'appMaker',
            type: 'file',
            text: reply['text'],
            mediaUrl: reply['video_url']
          )

          if reply['suggestions'].present?
            smooch_suggestions = generate_suggestions(suggestions: reply['suggestions'])
            message.actions = smooch_suggestions
          end

          message_template(action: 'post_message', message: message)
        end

        def file
          check_if_arguments_are_valid!(
            suggestions: reply['suggestions'],
            buttons: reply['buttons']
          )

          message = SmoochApi::MessagePost.new(
            role: 'appMaker',
            type: 'file',
            text: reply['text'],
            mediaUrl: reply['file_url']
          )

          if reply['suggestions'].present?
            smooch_suggestions = generate_suggestions(suggestions: reply['suggestions'])
            message.actions = smooch_suggestions
          end

          message_template(action: 'post_message', message: message)
        end

        def cards
          message = SmoochApi::MessagePost.new(
            role: 'appMaker',
            type: 'carousel'
          )

          smooch_items = generate_card_items(elements: reply["elements"])
          message.items = smooch_items

          message_template(action: 'post_message', message: message)
        end

        def list
          message = SmoochApi::MessagePost.new(
            role: 'appMaker',
            type: 'list'
          )

          smooch_items = generate_list_items(elements: reply["elements"])
          message.items = smooch_items

          if reply['buttons'].present?
            if reply["buttons"].size > 1
              raise(ArgumentError, "Smooch lists support a single button attached to the list itsef.")
            end

            smooch_buttons = generate_buttons(buttons: reply['buttons'])
            message.actions = smooch_buttons
          end

          message_template(action: 'post_message', message: message)
        end

        def enable_typing_indicator
          message = SmoochApi::TypingActivityTrigger.new(
            role: 'appMaker',
            type: 'typing:start'
          )

          message_template(action: 'trigger_typing_activity', message: message)
        end

        def disable_typing_indicator
          message = SmoochApi::TypingActivityTrigger.new(
            role: 'appMaker',
            type: 'typing:stop'
          )

          message_template(action: 'trigger_typing_activity', message: message)
        end

        def delay
          enable_typing_indicator
        end

        def persistent_menu
          smooch_menu = SmoochApi::Menu.new

          smooch_menu_items = generate_buttons(buttons: Stealth.config.smooch.setup.persistent_menu)
          smooch_menu.items = smooch_menu_items

          smooch_menu
        end

        private

          def message_template(action:, message:)
            {
              recipient_id: recipient_id,
              reply_type: action,
              message: message
            }
          end

          def generate_card_items(elements:)
            if elements.size > 10
              raise(ArgumentError, "Smooch cards can have at most 10 cards.")
            end

            smooch_items = elements.collect do |element|
              smooch_item = item_template(element_type: 'card', element: element)
            end

            smooch_items
          end

          def generate_list_items(elements:)
            if elements.size < 2 || elements.size > 4
              raise(ArgumentError, "Smooch lists must have 2-4 elements.")
            end

            smooch_items = elements.collect do |element|
              smooch_item = item_template(element_type: 'list', element: element)
            end

            smooch_items
          end

          def item_template(element_type:, element:)
            unless element["title"].present?
              raise(ArgumentError, "Smooch card and list elements must have a 'title' attribute.")
            end

            smooch_item = SmoochApi::MessageItem.new

            smooch_item.title = element['title']

            if element["subtitle"].present?
              smooch_item.description = element["subtitle"]
            end

            if element["image_url"].present?
              smooch_item.media_url = element["image_url"]
            end

            if element["default_action"].present?
              smooch_item.default = true
            end

            if element["buttons"].present?
              if element_type == 'card' && element["buttons"].size > 3
                raise(ArgumentError, "Smooch card elements only support 3 buttons.")
              end

              if element_type == 'list' && element["buttons"].size > 1
                raise(ArgumentError, "Smooch list elements only support 1 button.")
              end

              smooch_buttons = generate_buttons(buttons: element['buttons'])
              smooch_item.actions = smooch_buttons
            end

            smooch_item
          end

          def generate_suggestions(suggestions:)
            quick_replies = suggestions.collect do |suggestion|
              quick_reply = SmoochApi::Action.new(type: 'reply')

              case suggestion["type"]
              when 'location'
                quick_reply.type = 'locationRequest'
                quick_reply.text = suggestion["text"]
              when 'phone'
                quick_reply.text = suggestion["text"]
              when 'email'
                quick_reply.text = suggestion["text"]
              else
                quick_reply.text = suggestion["text"]

                if suggestion["payload"].present?
                  quick_reply.payload = suggestion["payload"]
                else
                  quick_reply.payload = suggestion["text"]
                end

                if suggestion["image_url"].present?
                  quick_reply.icon_url = suggestion["image_url"]
                end
              end

              quick_reply
            end

            quick_replies
          end

          def generate_buttons(buttons:)
            smooch_buttons = buttons.collect do |button|
              case button['type']
              when 'url'
                smooch_button = SmoochApi::Action.new(type: 'webview')
                smooch_button.uri = smooch_button.fallback = button["url"]
                smooch_button.text = smooch_button.fallback = button["text"]

                if button["webview_height"].present?
                  smooch_button.size = button["webview_height"]
                end

              when 'payload'
                smooch_button = SmoochApi::Action.new(type: 'postback')
                smooch_button.payload = button["payload"]
                smooch_button.text = button["text"]

              else
                raise(Stealth::Errors::ServiceImpaired, "Sorry, we don't yet support #{button["type"]} buttons yet!")
              end

              smooch_button
            end

            smooch_buttons
          end

          def check_if_arguments_are_valid!(suggestions:, buttons:)
            if suggestions.present? && buttons.present?
              raise(ArgumentError, "A reply cannot have buttons and suggestions!")
            end
          end
      end

    end
  end
end
