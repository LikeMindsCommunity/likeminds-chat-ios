# LikeMinds Chat SDK for iOS

Drop-in chat for iOS apps, in Swift. Group chatrooms, 1:1 DMs, polls, voice notes and reactions,
with offline sync.

[![CocoaPods](https://img.shields.io/cocoapods/v/LikeMindsChatCore.svg)](https://cocoapods.org/pods/LikeMindsChatCore)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

**Docs:** https://docs.likeminds.io/

## What you get

Group chatrooms and 1:1 DMs with request, approve, reject, block and rate limits · emoji reactions ·
reply, edit, delete, multi-select · @-mentions · polls · voice notes · images, video, GIFs via Giphy,
PDFs and documents · link previews · chatroom topics · search · explore chatrooms · secret chatrooms
and invites · report and moderation · push notifications · offline sync.

Beyond that: a bundled **image editor** with crop, filters, draw, text and image stickers,
**in-composer voice recording**, deep-link routing, and **reply privately**, which turns a group
message into a DM.

## Install

Two pods ship from this repo:

```ruby
pod 'LikeMindsChatCore', '~> 1.9.1'   # screens, view models, integration surface
pod 'LikeMindsChatUI',   '~> 1.9.1'   # the widget library
```

Both depend on the data layer:

```ruby
pod 'LikeMindsChatData', '~> 1.9.1'
```

Source at [likeminds-chat-ios-data](https://github.com/LikeMindsCommunity/likeminds-chat-ios-data),
with a [prebuilt xcframework](https://github.com/LikeMindsCommunity/likeminds-chat-ios-data-xc) if
you would rather not build it.

## Customising

Everything is **subclass-and-register**: any component can be replaced with your own without forking.
`LikemindsChatSample` demonstrates the pattern across eight custom views.

## What is in this repo

| Directory | What it is |
|---|---|
| `LMChatCore_iOS/` | The core pod |
| `LMChatUI_iOS/` | The widget pod |
| `community-chat/` `networking-chat/` `community-hybrid-chat/` | The three product shapes |
| `ai-chat/` | Chat against an AI bot participant |

## Requirements

iOS 13.0+ · Swift 5 · CocoaPods only, no SPM

## Built on

Kingfisher · AWS S3 and Cognito · Giphy · Lottie

## Contributing

See the org-wide [contributing guide](https://github.com/LikeMindsCommunity/.github/blob/main/.github/CONTRIBUTING.md).
Security issues go to **natesh@likeminds.community**, not the issue tracker.

## License

Apache 2.0. See [LICENSE](LICENSE).
