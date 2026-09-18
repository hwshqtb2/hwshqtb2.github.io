module Jekyll
  class TagsPage < Page
    def initialize(site, base, dir, tag, docs)
      @site = site
      @base = base
      @dir = dir
      @name = tag + '.html'
      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'tags-page.html')
      self.data['tag'] = tag
      self.data['tagged'] = docs
      self.data['title'] = "拥有#{tag} tag的文章"
    end
  end

  class TagGenerator < Generator
    safe true
    def generate(site)
      return unless site.layouts.key? 'tags-page'

      # site.tags 只包含 _posts 里的文章，不包含普通页面（如 thoughts/philosophy/01-1.md），
      # 所以这里自己汇总 posts 和 pages 两边的 tags。
      tags = Hash.new { |h, k| h[k] = [] }
      (site.posts.docs + site.pages).each do |doc|
        Array(doc.data['tags']).each { |tag| tags[tag] << doc }
      end
      tags.each { |tag, docs| write_tag_index(site, 'tags', tag, docs) }
    end

    def write_tag_index(site, dir, tag, docs)
      index = TagsPage.new(site, site.source, dir, tag, docs)
      index.render(site.layouts, site.site_payload)
      index.write(site.dest)
      site.pages << index
    end
  end

end
