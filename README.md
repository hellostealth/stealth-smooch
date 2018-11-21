# Stealth Smooch

This integration adds support for [Smooch](https://smooch.io) powered bots within [Stealth](https://github.com/hellostealth/stealth). It can be used as a drop-in replacement for `stealth-facebook` with the exception of some specialized quick reply buttons (such as Email & Phone).

[![Gem Version](https://badge.fury.io/rb/stealth-smooch.svg)](https://badge.fury.io/rb/stealth-smooch)

## Create Your Smooch App

Via the Smooch interface, create a new Smooch app for your Stealth bot. Once you do, you'll be given your `SMOOCH_APP_ID`.

Follow the instructions on the [smooch-api Ruby](https://github.com/smooch/smooch-ruby) page to generate your secret keys. This will get you your
`SMOOCH_KEY_ID` and `SMOOCH_SECRET`.

The last thing you will need is the `SMOOCH_JWT_TOKEN` which can be generated using this gem. After you have set the above creds to your `services.yml` file, from your bot's console, run:

```ruby
Stealth::Services::Smooch::Client.generate_jwt_token
```

It will output the JWT token based on the `app_id`, `key_id`, and `secret` from your `services.yml` file.

## Configure the Integration

```yaml
default: &default
  smooch:
    app_id: <%= ENV['SMOOCH_APP_ID'] %>
    key_id: <%= ENV['SMOOCH_KEY_ID'] %>
    secret: <%= ENV['SMOOCH_SECRET'] %>
    jwt_token: <%= ENV['SMOOCH_JWT_TOKEN'] %>
    setup:
      persistent_menu:
        - type: 'url'
          url: 'https://mywebsite.com'
          text: 'About Us'
        - type: 'payload'
          payload: 'contact_support'
          text: 'Contact Support'

production:
  <<: *default

development:
  <<: *default

test:
  <<: *default
```

Additionally, you will need to create an initializer called `smooch.rb` in `config/initializers`:

```ruby
  SmoochApi.configure do |config|
  config.api_key['Authorization'] = Stealth.config.smooch.jwt_token
  config.api_key_prefix['Authorization'] = 'Bearer'
end
```

As with all Stealth integrations, integrations can be specified by environment.

These are the supported setup options:

### persistent_menu

The persistent menu is not supported by all integrations. For a complete list, please check out the [Smooch Pesistent Menu Docs](https://docs.smooch.io/rest/#persistent-menus).

Setting the persistent menu is identical to creating buttons in text replies. Please see those docs for more info.

### Webhooks

In order for your bot to receive messages from the Smooch app, we'll need to register our webhooks.

Set `SMOOCH_ENDPOINT` to the endpoint that will be receiving the hooks. It's configured as an ENV variable so you can specify different endpoints for each of your environments.

After you have set `SMOOCH_ENDPOINT`, running setup below will register your webhooks.

### Running Setup

This will set the persistent menu (if available) and register your webhooks.

```
stealth setup smooch
```

## Replies

Here are the supported replies for the Smooch integration:

### text

These are standard text replies.

```yaml
- reply_type: text
  text: Hello World!
```

Text replies can also include suggestions, which will be rendered as quick replies:

```yaml
- reply_type: text
  text: What is your favorite color?
  suggestions:
    - text: Blue
    - text: Red
```

Although not as common, text replies can also include buttons:

```yaml
- reply_type: text
  text: Would you like to give us a call?
  buttons:
    - type: payload
      text: 'Yes'
      payload: 'Yes'
    - type: payload
      text: 'No'
      payload: 'No'
```

### suggestions

Though suggestions are not a reply type on their own, they are frequently used to optimize the accuracy and speed of your bot. In the `text` reply type above, we used simple labels for our suggestions. Smooch supports a few special types of quick replies, however.

#### Location

You can ask a user for their location:

```yaml
- reply_type: text
  text: "Where are you located?"
  suggestions:
    - type: location
```

If the user chooses to share their location, the `lat` and `lng` will be available via `current_message.location`:

```ruby
current_message.location[:lat]
current_message.location[:lng]
```

#### Images

While images are not a special quick reply type, you can include and `image_url` for a quick reply as way of adding an icon to a quick reply button:

```yaml
- reply_type: text
  text: "What is your favorite color?"
  suggestions:
    - text: Red
      image_url: "http://example.com/img/red.png"
    - text: Blue
      image_url: "http://example.com/img/blue.png"
```

More info [here](https://docs.smooch.io/rest/#reply).

### buttons

As with `suggestions`, `buttons` are not a reply type of their own but are used to make your bot more efficient. Smooch supports a few button types and these are the ones currently supported by this integration:

#### payload

This is the most common button type. When a user presses a button that is `payload` type, that payload string will be sent to your bot. For example:

```yaml
- reply_type: text
  text: Please press the button below
  buttons:
    - type: payload
      text: 'Press me!'
      payload: 'button pressed'

```

When a user presses the button labeled "Press me!", the payload `button pressed` will be accessible in bot via `current_message.payload`.

#### url

The `url` button is useful when sharing a link to a website. By default, it will open up within Facebook Messenger.

```yaml
- reply_type: text
  text: Find out more via our website
  buttons:
    - type: url
      text: 'Visit website'
      url: 'https://example.org'

```

### Delay

Delays are a very important part of bot design. They introduce a pause between text replies to give the user a chance to read each reply. With this integration, in addition to introducing a delay, we will also send a typing indicator to the user to indicate another reply is forthcoming. To insert a delay in your bot:

```yaml
- reply_type: delay
  duration: 2
```

This will add a `2` second delay (with typing indicator). The `duration` can be specified as any floating point value, in seconds.

### Cards

Smooch distinguishes between a single card and a carousel of cards. This integration does not, however. You can send a single card the same way you would send 10 cards (the current maximum).

```yaml
- reply_type: cards
  elements:
    - title: My App
      subtitle: Download our app below or visit our website for more info.
      image_url: "https://my-app.com/app-image.png"
      buttons:
        - type: url
          url: "https://my-app.com"
          text: 'View'
          webview_height: 'tall'
        - type: url
          url: "https://itunes.apple.com/us/app/my-app"
          text: 'Download iOS App'
```

The above is a single card with two buttons. If you want to include more cards, though, you would just need to specify another listing under the `elements` heading.

More info about Smooch cards [here](https://docs.smooch.io/rest/#carousel).

### List

A Smooch list is useful for displaying things like a news feed. You can find more info about Smooch lists [here](https://docs.smooch.io/rest/#list).

To generate a list:

```yaml
- reply_type: list
  buttons:
    - type: payload
      text: View More
      payload: view_more
  elements:
    - title: Your Daily News Update
      subtitle: The following stories have been curated just for you.
      image_url: "https://picsum.photos/320/240"
      buttons:
        - type: url
          url: "https://news-articles.com/199"
          text: 'View'
    - title: Breakthrough in AI
      subtitle: Major breakthrough in the AI space.
      image_url: "https://picsum.photos/320/320"
      buttons:
        - type: url
          url: "https://news-articles.com/201"
          text: 'View'
```

The list itself supports having a single button that will be rendered on the bottom of the list. Each individual list item supports having one button as well. List items should have between 2-4 elements.

More info about Smooch lists [here](https://docs.smooch.io/rest/#list).

### Images

To send an image:

```yaml
- reply_type: image
  image_url: 'https://example.org/image.png'
```

The `image_url` should be set to URL where the image has been uploaded.

Image replies support buttons and suggestions like text replies.

### Files

To send a file:

```yaml
- reply_type: file
  file_url: 'https://example.org/some.pdf'
```

The `file_url` should be set to URL where the file has been uploaded.

File replies support buttons and suggestions like text replies.

### Video

To send a video:

```yaml
- reply_type: video
  video_url: 'https://example.org/cool_video.mp4'
```

The `video_url` should be set to URL where the video has been uploaded.

Video replies support buttons and suggestions like text replies.

### Audio

To send an audio clip:

```yaml
- reply_type: audio
  audio_url: 'https://example.org/podcast.mp3'
```

The `audio_url` should be set to URL where the video has been uploaded.

Audio replies support buttons and suggestions like text replies.

## Development

When adding features to this library, you might find it helpful to get a full printout of the HTTP requests and responses from Smooch.

In order to configure your bot to show the debug output, modify your `smooch.rb` initializer like so:

```ruby
class SmoochLogger

  def self.debug(msg)
    Stealth::Logger.l(topic: 'smooch', message: msg)
  end

end

SmoochApi.configure do |config|
  config.logger = SmoochLogger
  config.debugging = true
  config.api_key['Authorization'] = Stealth.config.smooch.jwt_token
  config.api_key_prefix['Authorization'] = 'Bearer'
end
```
