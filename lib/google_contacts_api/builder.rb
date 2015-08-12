module GoogleContactsApi
  class Builder
    def initialize(data)
      @builder = Nokogiri::XML::Builder.new do |xml|
        @xml = xml
        data.each_pair do |key, value|
          if value.kind_of? Hash
            build_node key, value
          else
            xml.method_missing key, value
          end
        end
      end
    end

    def to_xml
      @builder.to_xml
    end

    private
    def build_node(name, data)
      attributes, children = data.partition { |key, value| value.kind_of? Hash }
      attributes = Hash[attributes].with_indifferent_access
      @xml.method_missing name, attributes.delete('$t'), attributes do
        children.each do |key, value|
          build_node key, value
        end
      end
    end
  end
end