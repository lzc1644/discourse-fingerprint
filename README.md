# discourse-fingerprint

Discourse Fingerprint comes as a tool to community managers in their combat with [internet trolls](https://en.wikipedia.org/wiki/Internet_troll). It works by computing a unique identifier (a fingerprint) of each registered user, by taking into consideration over 20 browser characteristics such as user agent, screen resolution, timezone, device memory, etc.

## Installation

Follow [Install a Plugin](https://meta.discourse.org/t/install-a-plugin/19157) guide, using `git clone https://github.com/discourse/discourse-fingerprint.git` as the plugin command.

## Usage

The plugin creates a dashboard that can be accessed by administrators by going to **Settings** > **Plugins** and selecting **Fingerprint** from the left side.

Staff may check individual users by typing in their name or by looking over the latest discovered matches.

Administrators can hide a fingerprint, silence matching accounts, or select **Suspend** to add an automatic suspension rule. Rules apply to browser fingerprints and, when cookie fingerprinting is enabled, the plugin's `fp` cookie. A matching account is suspended indefinitely and logged out the next time it reports its fingerprint; existing matches are not suspended immediately. Suspension takes precedence if a silencing rule also matches. Existing silencing rules keep their original behavior.

Select **Remove suspension rule** to stop future automatic suspensions. This does not unsuspend accounts already affected; unsuspend those accounts separately in user administration. Check matches carefully before enabling a rule, because shared devices and similar browser configurations can produce false positives.

When upgrading an existing installation, run the normal Discourse plugin rebuild/migration process to add the suspension-rule database column before using the new version.

## Feedback

If you have issues or suggestions for the plugin, please bring them up on [Discourse Meta](https://meta.discourse.org/t/discourse-fingerprint-browser-fingerprinting-plugin/114890).
