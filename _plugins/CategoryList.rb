require "cgi"

module Jekyll
  # Automatic member lists for category pages.
  #
  # A site-root category page (<category>.md, for example author.md or guides.md)
  # gets a list appended to its content at render time. A category page lists:
  #   - every page under <category>/ (author content mirrored by Authors.rb plus
  #     pages committed directly in that directory), following the chapter
  #     `order` when present and sorted by path otherwise;
  #   - every post whose `categories` include <category>, newest first.
  # Each item shows the page title (or the filename when there is no title) and
  # links to the page.
  #
  # Opt out for a single page with `category_list: false` in its front matter, or
  # place {% category_list %} / {% category_list guides %} manually to control
  # where the list appears (the automatic append is then skipped).
  module CategoryList
    class << self
      # :pages, :pre_render hook: append the list tag to category pages.
      def inject(page)
        return if page.nil?
        return if page.data["category_list"] == false
        return if page.content.to_s.include?("category_list")

        rel = relative_path(page)
        return if rel.include?("/") # only site-root category pages

        category = File.basename(rel, File.extname(rel))
        return if category.empty?

        site = page.respond_to?(:site) ? page.site : nil
        return if site.nil?
        return if members(site, category, page).empty?

        page.content = "#{page.content}\n\n{% category_list %}\n"
      end

      def render(page, site, explicit = nil)
        return "" if site.nil?

        category = category_for(page, site, explicit)
        return "" if category.nil?

        docs = members(site, category, page)
        return "" if docs.empty?

        items = docs.map do |doc|
          url = doc_url(site, doc)
          %(<li><a href="#{CGI.escapeHTML(url)}">#{CGI.escapeHTML(display_name(doc))}</a></li>)
        end
        %(<ul class="category-list">#{items.join}</ul>)
      end

      private

      # Category of the current page: explicit argument -> front matter
      # categories/category -> inferred from the path.
      def category_for(page, site, explicit = nil)
        value = explicit.to_s.strip
        return value unless value.empty?
        return nil if page.nil?

        data = page.respond_to?(:data) ? page.data : page
        categories = Jekyll::PluginUtils.normalize_list(data["categories"])
        return categories.first unless categories.empty?

        single = Jekyll::PluginUtils.normalize_list(data["category"]).first
        return single unless single.nil?

        rel = relative_path(page)
        if rel.include?("/")
          rel.split("/").first
        else
          base = File.basename(rel, File.extname(rel))
          base.empty? ? nil : base
        end
      end

      # Pages under <category>/ first (by path), then posts in that category
      # (newest first). The current page and duplicate URLs are skipped.
      def members(site, category, current = nil)
        prefix = "#{category}/"
        current_path = current.nil? ? nil : relative_path(current)

        pages = site.pages.select do |doc|
          rel = relative_path(doc)
          rel.start_with?(prefix) && rel != current_path
        end
        pages.sort_by! { |doc| page_sort_key(doc) }

        posts = site.posts.docs.select do |doc|
          next false if current_path && relative_path(doc) == current_path

          Jekyll::PluginUtils.normalize_list(doc.data["categories"]).include?(category)
        end
        posts.sort_by! { |doc| post_date(doc) || Time.at(0) }
        posts.reverse!

        seen = {}
        (pages + posts).select do |doc|
          url = doc_url(site, doc)
          next false if seen[url]

          seen[url] = true
        end
      end

      # Pages follow the chapter `order` when present (ordered pages first, in
      # ascending order); the path keeps the remaining entries deterministic.
      def page_sort_key(doc)
        segments = Jekyll::PluginUtils.order_segments(doc.data["order"])
        segments.nil? ? [1, [], relative_path(doc)] : [0, segments, relative_path(doc)]
      end

      def post_date(doc)
        value = doc.respond_to?(:date) ? doc.date : doc["date"]
        return nil if value.nil?
        return value if value.respond_to?(:strftime)

        Jekyll::Utils.parse_date(value.to_s)
      rescue StandardError
        nil
      end

      def relative_path(doc)
        rel = doc.respond_to?(:relative_path) ? doc.relative_path : doc["path"]
        rel.to_s.tr("\\", "/").delete_prefix("/")
      end

      # Display name: front matter title first, filename (without extension) as
      # the fallback.
      def display_name(doc)
        data = doc.respond_to?(:data) ? doc.data : doc
        title = data["title"].to_s.strip
        return title unless title.empty?

        File.basename(relative_path(doc), File.extname(relative_path(doc)))
      end

      def doc_url(site, doc)
        url = doc.respond_to?(:url) ? doc.url : doc["url"]
        url = url.to_s
        base = site.respond_to?(:baseurl) ? site.baseurl.to_s : ""
        url = "#{base}#{url}" unless base.empty? || url.start_with?(base)
        Jekyll::URL.escape_path(url)
      end
    end

    class Tag < Liquid::Tag
      def initialize(tag_name, markup, tokens)
        super
        @category = markup.to_s.strip
      end

      def render(context)
        Jekyll::CategoryList.render(
          context.registers[:page],
          context.registers[:site],
          @category
        )
      end
    end
  end
end

Liquid::Template.register_tag("category_list", Jekyll::CategoryList::Tag)

Jekyll::Hooks.register :pages, :pre_render do |page, _payload|
  Jekyll::CategoryList.inject(page)
end
