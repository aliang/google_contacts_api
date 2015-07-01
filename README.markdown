# google_contacts_api

An unofficial Google Contacts API for ruby. Might not be stable (but probably is).

## Do the tests pass?

[![Build Status](https://travis-ci.org/aliang/google_contacts_api.png)](https://travis-ci.org/aliang/google_contacts_api)

## Upgrading

Right now upgrading should just work, barring any bugs in my implementation. In the next major version I will probably drop (or at least stop maintaining) support for OAuth::AccessToken objects and depend directly on the [oauth2](https://github.com/intridea/oauth2) gem.

## Usage

You need to pass to the `GoogleContactsApi::User` constructor one of the following two objects:

* an OAuth::AccessToken from the [oauth-ruby](https://github.com/oauth/oauth-ruby) gem
* an OAuth2::AccessToken from the [oauth2](https://github.com/intridea/oauth2) gem

See their respective documentation for details on how to get this object. (I'm guessing there would be a few changes in implementation details of the GoogleContactsApi::Api class if you use another OAuth library, mostly to change how the base get/post/put/delete methods work.)

Then you can instantiate a GoogleContactsApi::Api object for direct posting and parsing, or a
GoogleContactsApi::User object for easier stuff.

```ruby
oauth_access_token_for_user
# => <OAuth2::AccessToken:0x000000029a69d36>

google_contacts_user = GoogleContactsApi::User.new(oauth_access_token_for_user)
contacts = google_contacts_user.contacts
# => <GoogleContactsApi::ContactSet: @start_index=1, @items_per_page=100000, @total_results=638>
groups = google_contacts_user.groups
# => <GoogleContactsApi::GroupSet: @start_index=1, @items_per_page=100000, @total_results=8>

# group methods
group = groups.first
# => <GoogleContactsApi::Group: System Group: My Contacts>
group.contacts
# => <GoogleContactsApi::ContactSet: @start_index=1, @items_per_page=100000, @total_results=20>

# contact methods
contact = contacts.first
# => <GoogleContactsApi::Contact: Alvin>
contact.photo
contact.title
contact.id
contact.primary_email
contact.emails
```

`ContactSet` and `GroupSet` both implement `Enumberable`.

In addition, `Contact` and `Group` are subclasses of [Hashie::Mash](https://github.com/intridea/hashie), so you can access any of the underlying data directly (for example, if Google returns new data [in their API](https://developers.google.com/google-apps/contacts/v3/)). Note that data is retrieved using Google's JSON API so the equivalent content of an XML element from the XML API is stored under the key "$t".

The easiest way to see the convenience methods I've provided is to look at the RSpec tests.

## TODO

I welcome patches and pull requests, see the guidelines below (handily auto-generated
by jeweler).

* Any missing tests! (using RSpec, please)
* Read more contact information (structured name, address, ...)
* Get single contacts and groups
* Posting/putting/deleting groups, contacts and their photos. This might require XML?
* Adapter layer for different OAuth libraries? I'm not sure there are any other widely used libraries though
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

Copyright (c) 2011-15 Alvin Liang (aliang). See LICENSE.txt for further details.

Some code based on a few bugfixes in lfittl and fraudpointer forks.

Support for Google Contacts API version 3 fields by draffensperger.