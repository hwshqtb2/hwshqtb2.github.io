module Jekyll
  # Inherits a license inside a category group.
  #
  # Documents with `layout: article` that do not set `license` themselves take
  # the license of their group's root page (`order: 0`, same category). When the
  # group has no root page or the root has no license, the page is left alone and
  # _includes/license.html falls back to site.license.
  class DefaultLicenseGenerator < Generator
    safe true
    priority :low

    def generate(site)
      groups = Hash.new { |h, k| h[k] = [] }
      (site.posts.docs + site.pages).each do |doc|
        Jekyll::PluginUtils.normalize_list(doc.data['categories']).each do |cat|
          groups[cat] << doc
        end
      end

      groups.each_value do |members|
        root = members.find { |m| root_order?(m.data['order']) }
        next unless root && root.data['license']

        members.each do |doc|
          next unless doc.data['layout'] == 'article'

          doc.data['license'] ||= root.data['license']
        end
      end
    end

    def root_order?(order)
      return false if order.nil?

      order.to_s.split('.').map(&:to_i) == [0]
    end
  end
end
