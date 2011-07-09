# google_contacts_api

An unofficial Google Contacts API for ruby. Might not be stable (but probably is). In active usage at thirsst.com.

## Usage

You need to provide an OAuth access token from one of the major OAuth libraries to this library.
Then you can instantiate a GoogleContactsApi::Api object for direct posting and parsing, or a
GoogleContactsApi::User object for easier stuff.

```ruby
google_contacts_user = GoogleContactsApi::User(oauth_access_token_for_user)
contacts = google_contacts_user.contacts
groups = google_contacts_user.groups
groups.first.contacts
contacts.first.photo
contacts.first.title
contacts.first.id
```

## TODO

I welcome patches and pull requests, see the guidelines below (handily auto-generated
by jeweler).

* Tests! (using RSpec, please)
* Posting/putting/deleting groups, contacts and their photos
* Support ClientLogin

## Contributing to google_contacts_api
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2011 Alvin Liang. See LICENSE.txt for further details.