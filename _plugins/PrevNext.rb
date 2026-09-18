require 'time'
require 'cgi'

module Jekyll
  # 为标记了相同 categories 的文档计算上一篇/下一篇，并为"目录型"文档自动生成目录。
  # 规则：
  #   - 只有 front matter 显式写了 order 的文档才参与（不写的不参与）；
  #   - order 支持层级序号，如 2、2.1、2.2.1（按段逐级比较排序，如 1.10 排在 1.2 之后）；
  #   - order: 0 的文档是整组根目录页：组内其它页面会得到 data['root'] 指向它（"返回根目录"按钮），
  #     以及 data['parent'] 指向最近的上层目录文档（"返回上层目录"按钮）；
  #     根目录页本身不进入上/下一篇链，但会得到整组成员的 data['toc_html']；
  #   - 任意文档若其 order 是组内其它文档 order 的前缀（如 1 之于 1.1、1.2），
  #     也会得到由这些后代文档构成的 data['toc_html']（嵌套目录），其本身在链中的位置不变；
  #   - 组内按序号升序连成链，结果写入 data['prev'] / data['next']，
  #     由 _includes/prevnext.html 渲染；目录由布局中的 page.toc_html 渲染。
  class PrevNextGenerator < Generator
    safe true
    priority :low # 在其它 generator（如 TagsPage）之后运行，保证 site.pages 已完整

    def generate(site)
      groups = Hash.new { |h, k| h[k] = [] }
      (site.posts.docs + site.pages).each do |doc|
        Array(doc.data['categories']).each { |cat| groups[cat.to_s] << doc }
      end

      groups.each_value do |members|
        members.select! { |doc| !doc.data['order'].nil? }
        next if members.empty?

        toc = members.find { |doc| self.class.segments(doc.data['order']) == [0] }
        chain = members.reject { |doc| doc == toc }
        chain.sort_by! { |doc| self.class.segments(doc.data['order']) }

        chain.each_index do |i|
          doc = chain[i]
          doc.data['prev'] = chain[i - 1] unless i.zero?
          doc.data['next'] = chain[i + 1] if i < chain.size - 1
          doc.data['root'] = toc if toc
        end

        # 上层目录：order 的最长真前缀文档（如 1.1.1 的上层是 1.1），顶层文档没有上层目录
        chain.each do |doc|
          seg = self.class.segments(doc.data['order'])
          parent = chain.select { |m| self.class.proper_prefix?(self.class.segments(m.data['order']), seg) }
                        .max_by { |m| self.class.segments(m.data['order']).size }
          doc.data['parent'] = parent if parent
        end

        # order: 0 目录页：列出整组成员
        toc.data['toc_html'] = self.class.toc_html_of(chain) if toc

        # 任意前缀文档：order 是其它文档 order 前缀的，列出其后代构成的目录
        chain.each do |doc|
          seg = self.class.segments(doc.data['order'])
          descendants = chain.select { |m| self.class.proper_prefix?(seg, self.class.segments(m.data['order'])) }
          doc.data['toc_html'] = self.class.toc_html_of(descendants) unless descendants.empty?
        end
      end
    end

    # 把各种形态的 order 规范成整数段数组：2 -> [2]，"2.2.1" -> [2,2,1]，2.0 -> [2]
    def self.segments(order)
      value = order.is_a?(Float) && order == order.to_i ? order.to_i : order
      value.to_s.split('.').map(&:to_i)
    end

    def self.toc_html_of(docs)
      items = docs.map do |doc|
        seg = segments(doc.data['order'])
        {
          :seg     => seg,
          :display => seg.join('.'),
          :title   => CGI.escapeHTML(doc.data['title'].to_s),
          :url     => CGI.escapeHTML(doc.url)
        }
      end
      items.sort_by! { |i| i[:seg] }
      render_list(build_tree(items))
    end

    # 按段前缀把排好序的条目构造成嵌套树（父段是子段的前缀）
    def self.build_tree(items)
      root = { :seg => [], :children => [] }
      stack = [root]
      items.each do |item|
        node = {
          :seg      => item[:seg],
          :display  => item[:display],
          :title    => item[:title],
          :url      => item[:url],
          :children => []
        }
        stack.pop while stack.size > 1 && !proper_prefix?(stack.last[:seg], node[:seg])
        stack.last[:children] << node
        stack << node
      end
      root[:children]
    end

    def self.proper_prefix?(a, b)
      a.size < b.size && b[0, a.size] == a
    end

    def self.render_list(nodes)
      return '' if nodes.empty?

      html = +"<ul>"
      nodes.each do |n|
        html << "<li><a href=\"#{n[:url]}\">#{n[:display]} #{n[:title]}</a>"
        html << render_list(n[:children]) unless n[:children].empty?
        html << "</li>"
      end
      html << "</ul>"
    end
  end
end
