require 'nokogiri'

module GoogleContactsApi
  module XMLUtil
    class Nokogiri::XML::Node
      def namespaced_name
        if namespace.nil? || namespace.prefix.nil? || namespace.prefix.strip.empty?
          namespaced = name
        else
          namespaced = "#{namespace.prefix}$#{name}"
        end
        namespaced.sub(':', '$')
      end
    end

    module_function

    def parse_as_if_alt_json(xml)
      parse(Nokogiri::XML(xml))
    end

    def parse(node)
      return node.text.strip if node.is_a?(Nokogiri::XML::Text)
      return node.value.strip if node.is_a?(Nokogiri::XML::Attr)

      elements_more_than_once = %w(entry author link category gd$email gd$phoneNumber gd$organization gd$structuredPostalAddress gContact$groupMembershipInfo gContact$relation gContact$website gd$when gd$where gd$reminder)

      element_children = node.children.select {|n| n.element? }

      child_groups = {}
      element_children.each do |child|
        if child_groups[child.namespaced_name]
          child_groups[child.namespaced_name] << child
        else
          child_groups[child.namespaced_name] = [child]
        end
      end

      parts = {}

      if node.is_a?(Nokogiri::XML::Element)
        text_children = node.children.select {|n| n.text? && n.text=~/\S/ }
        if text_children.size > 0
          parts['$t'] = parse(text_children[0])
        end

        unless node.attributes.empty?
          node.attribute_nodes.each do |a|
            parts[a.namespaced_name] = a.value
          end
        end
      end

      child_groups.each do |namespaced_name, child_group|
        if child_group.size == 1 && !elements_more_than_once.include?(namespaced_name)
          parts[namespaced_name] = parse(child_group[0])
        else
          parts[namespaced_name] = child_group.map { |child| parse(child) }
        end
      end

      parts
    end
  end
end