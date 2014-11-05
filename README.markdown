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
contact.given_name # also family_name, full_name, additional_name, name_prefix, name_suffix
contact.addresses
contact.organizations
contact.websites
contact.birthday
contact.relations
contact.group_memberships
contact.deleted_group_memberships
```

Here are some other ways to retrieve contacts:
```

# Look up a single contact via a stored contact id URL
contact = google_contacts_user.get_contact(stored_contact_id)

# Query contacts (Google seems to search over a variety of fields)
contacts = google_contacts_user.query_contacts("john")
contacts = google_contacts_user.query_contacts("joe@example.com")

# Get all contacts modified after a certain time
contacts = google_contacts_user.contacts_updated_min(time_you_last_synced)

```

## Modifying contacts

You can make changes to a contact by calling the `prep_changes` method and passing in a hash with your changes, e.g.:

```
contact.prep_changes(
	given_name: 'John',
	emails: [
  	{ address: 'john@example.com', primary: true, rel: 'home' },
    { address: 'johnwork@example.com', primary: false, rel: 'work' },
   ]
)
```

At that point if you call `contact.given_name` it will still return its old value (unlike ActiveRecord objects). However, you can commit the changes to Google when you're ready by calling `contact.create_or_update()`. It will raise an error if the create/update API call fails.

## Creating contacts

You can create a new contact like this:

```
# Create empty contact associated with the API auth user
contact = GoogleContactsApi::Contact.new(nil, nil, google_contacts_user.api)

# Prep changes to its fields
contact.prep_changes(given_name: 'John', family_name: 'Doe')

# Send the API request to crate the contact.
contact.create_or_update
```

## Creating groups and assigning them to contacts

Here's an example of how to create a group and assign it to a contact:

```
# First see if there is already a group with your title
current_groups = google_contacts_user.groups
my_group = current_groups.find { |group| group.title = my_title }

# If there isn't you need to create one
unless my_group
  my_group = Group.create(title: my_title)
end

# Now use prep_add_to_group to add contact to your group if it's not in it already

contact.prep_add_to_group(my_group)

# Now save your contact to Google
contact.create_or_update
```

## Batched requests

Google Contacts also offers batch processing for contacts to speed up large numbers of updates by combining them into batches which are single HTTP requests. To make a batched request first call `contact.prep_changes(..)` then call `google_contacts_user.batch_create_or_update` with `contact` and a block that will get executed with the status for that batch item's request once the batch is sent and receives a response. You need to call `google_contacts_user.send_batched_requests` to send the requests if the batch doesn't fill up. Here's an example:

```
many_contacts.each do |contact|
  contact.prep_changes(given_name: 'John') # Rename everyone John
	google_contacts_user.batch_create_or_update do |status|
    # This block will get called when a batch is completed
    fail unless if status[:code].in?(200, 201)
  end
end

# Send request in last batch
google_contacts_user.send_batched_requests
```

To delete a contact, call `google_contacts_user.delete(contact.id, contact.etag)`.


## Other notes

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

Copyright (c) 2011-14 Alvin Liang (aliang). See LICENSE.txt for further details.

Some code based on a few bugfixes in lfittl and fraudpointer forks.

Support for Google Contacts API version 3 fields by draffensperger.