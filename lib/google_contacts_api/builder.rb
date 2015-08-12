require 'nokogiri'

module GoogleContactsApi
  class Builder
    def initialize(data)
      data = data.with_indifferent_access
      @builder = Nokogiri::XML::Builder.new data.slice('encoding') do |xml|
        @xml = xml
        build_node 'root', data.except('version', 'encoding')
      end
    end

    def to_xml
      @builder.to_xml
    end

    private
    def build_node(name, data)
      children, attributes = data.partition { |key, value| value.kind_of?(Hash) || value.kind_of?(Array) }
      attributes = Hash[attributes].with_indifferent_access
      @xml.method_missing name, attributes.delete('$t'), attributes do
        children.each do |key, value|
          if value.kind_of? Array
            value.each do |v|
              build_node key, v
            end
          else
            build_node key, value
          end
        end
      end
    end
  end
end