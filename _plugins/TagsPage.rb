module Jekyll
  # Generates one tag index page per tag (at /tags/<tag>.html).
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
      self.data['title'] = "Pages tagged “#{tag}”"
    end
  end

  class TagGenerator < Generator
    safe true
    def generate(site)
      return unless site.layouts.key? 'tags-page'

      # site.tags only covers documents in _posts, not regular pages (such as
      # guides/getting-started.md), so collect tags from both posts and pages.
      tags = Hash.new { |h, k| h[k] = [] }
      (site.posts.docs + site.pages).each do |doc|
        Jekyll::PluginUtils.normalize_list(doc.data['tags']).each { |tag| tags[tag] << doc }
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
