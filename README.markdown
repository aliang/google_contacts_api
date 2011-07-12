# google_contacts_api

An unofficial Google Contacts API for ruby. Might not be stable (but probably is). In active usage at [thirsst.com](http://thirsst.com/). (Shameless plug: We help you manage your RSS and group bookmarking!)

## Usage

You need to provide an OAuth client, with access token, from an OAuth access library to this library. I've tested it with OAuth::AccessToken from the [oauth-ruby](https://github.com/oauth/oauth-ruby) gem. I'm guessing there would be a few small changes in implementation details of the GoogleContactsApi::Api class if you use another library, mostly to change how the base get/post/put/delete methods work.

Then you can instantiate a GoogleContactsApi::Api object for direct posting and parsing, or a
GoogleContactsApi::User object for easier stuff.

```ruby
google_contacts_user = GoogleContactsApi::User(oauth_access_token_for_user)
contacts = google_contacts_user.contacts
groups = google_contacts_user.groups

# group methods
group = groups[0]
group.contacts

# contact methods
contact = contacts[0]
contact.photo
contact.title
contact.id
contact.primary_email
contact.emails
```

In addition, Contacts and Groups are subclasses of [Hashie::Mash](https://github.com/intridea/hashie), so you can access any of the underlying data directly. Note that data is retrieved using Google's JSON API so the equivalent content of an XML element from the XML API is stored under the key "$t".

The easiest way to see the convenience methods I've provided is to look at the RSpec tests.

## TODO

I welcome patches and pull requests, see the guidelines below (handily auto-generated
by jeweler).

* Any missing tests! (using RSpec, please)
* Read more contact information (structured name, address, phone, ...)
* Get single contacts and groups
* Posting/putting/deleting groups, contacts and their photos. This might require XML?
* Test other OAuth libraries ([oauth2](https://github.com/intridea/oauth2) is next on my list). Does Google support OAuth 2.0 for contacts?
* Support ClientLogin (maybe not, since Google's old library covers it)

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