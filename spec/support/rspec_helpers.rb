module RspecHelpers
  def load_file(filename)
    f = File.open(File.join(File.dirname(__FILE__), '../fixtures', filename))
    json = f.read
    f.close
    json
  end

  def contact_json
    load_file("contact.json")
  end

  def contact_set_json
    load_file("contact_set.json")
  end

  def group_set_json
    load_file("group_set.json")
  end

  def empty_contact_set_json
    load_file("empty_contact_set.json")
  end

  def empty_group_set_json
    load_file("empty_group_set.json")
  end

  def contact_json_hash
    Hashie::Mash.new(JSON.parse(contact_set_json)).feed.entry.first
  end

  def contact_no_emails_json_hash
    Hashie::Mash.new(JSON.parse(contact_set_json)).feed.entry[1]
  end

  def contact_no_primary_email_json_hash
    Hashie::Mash.new(JSON.parse(contact_set_json)).feed.entry[2]
  end

  def group_json_hash
    Hashie::Mash.new(JSON.parse(group_set_json)).feed.entry.first
  end

  def group_not_system_json_hash
    Hashie::Mash.new(JSON.parse(group_set_json)).feed.entry.last
  end
end

RSpec.configure do |config|
  config.include RspecHelpers
end
