module Jekyll
  # 为 layout 为 article 且 front matter 未写 license 的文章，
  # 从同 categories 组内 order: 0（根目录文章）处继承 license。
  # 组内没有 order: 0 或根文章没有 license 时，保持原样（由 license.html 回退到 site.license）。
  class DefaultLicenseGenerator < Generator
    safe true
    priority :low

    def generate(site)
      groups = Hash.new { |h, k| h[k] = [] }
      (site.posts.docs + site.pages).each do |doc|
        Array(doc.data['categories']).each { |cat| groups[cat.to_s] << doc }
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
