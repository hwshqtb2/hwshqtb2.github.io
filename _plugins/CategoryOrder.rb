require 'time'
require 'cgi'

module Jekyll
  # Orders pages inside a category and renders chapter navigation.
  #
  # Pages that share a category and declare an `order` in their front matter are
  # put into one sequence (posts keep Jekyll's own date based neighbours, see
  # _layouts/post.html):
  #   - `order` accepts hierarchical numbers such as 2, 2.1, 2.2.1; segments are
  #     compared one by one, so 1.10 sorts after 1.2;
  #   - a document with `order: 0` is the chapter root: every other member gets
  #     data['root'] pointing at it (the "Back to category" link) and
  #     data['parent'] pointing at its nearest ancestor (the "Back to parent"
  #     link). The root itself is not part of the prev/next chain but receives
  #     data['toc_html'] for the whole chapter;
  #   - a document whose order is a prefix of other members' orders (1 for 1.1,
  #     1.2) also receives a nested data['toc_html'] for those descendants; its
  #     own position in the chain is unchanged;
  #   - members are chained in ascending order into data['prev'] / data['next'],
  #     rendered by _includes/page-nav.html; the table of contents is rendered by
  #     the layouts from page.toc_html.
  #
  # Category pages also use the order when listing their members, see
  # _plugins/CategoryList.rb.
  class CategoryOrderGenerator < Generator
    safe true
    priority :low # after other generators (TagsPage etc.) so site.pages is complete

    def generate(site)
      groups = Hash.new { |h, k| h[k] = [] }
      site.pages.each do |doc|
        Jekyll::PluginUtils.normalize_list(doc.data['categories']).each do |cat|
          groups[cat] << doc
        end
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

        # Parent link: the longest proper prefix of this order (1.1.1 -> 1.1).
        # Top-level documents have no parent link.
        chain.each do |doc|
          seg = self.class.segments(doc.data['order'])
          parent = chain.select { |m| self.class.proper_prefix?(self.class.segments(m.data['order']), seg) }
                        .max_by { |m| self.class.segments(m.data['order']).size }
          doc.data['parent'] = parent if parent
        end

        # order: 0 root page: list every chapter member.
        toc.data['toc_html'] = self.class.toc_html_of(chain) if toc

        # Any prefix document: list the descendants it contains.
        chain.each do |doc|
          seg = self.class.segments(doc.data['order'])
          descendants = chain.select { |m| self.class.proper_prefix?(seg, self.class.segments(m.data['order'])) }
          doc.data['toc_html'] = self.class.toc_html_of(descendants) unless descendants.empty?
        end
      end
    end

    # Normalise an order value into integer segments:
    # 2 -> [2], "2.2.1" -> [2, 2, 1], 2.0 -> [2].
    def self.segments(order)
      Jekyll::PluginUtils.order_segments(order)
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

    # Build a nested tree from sorted items (a parent segment is a prefix of its
    # children's segments).
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
