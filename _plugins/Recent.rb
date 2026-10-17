require 'time'

module Jekyll
  # Builds the "Recently updated" list: posts plus pages with an `article` or
  # `post` layout, ordered by modified_date / date (documents with neither are
  # skipped) and limited to five entries.
  #
  # The result is stored in site.data['recent'] and rendered by
  # _includes/latest.html.
  class RecentGenerator < Generator
    safe true
    priority :low

    def generate(site)
      items = site.posts.docs.filter_map { |doc| t = recency(doc); [t, doc] if t }
      site.pages.each do |page|
        next unless %w[article post].include?(page.data['layout'])

        t = recency(page)
        items << [t, page] if t
      end
      items.sort_by! { |time, _| time }.reverse!
      site.data['recent'] = items.first(5).map { |_, doc| doc }
    end

    # modified_date wins over date; documents with neither are skipped.
    def recency(doc)
      d = doc.data['modified_date']
      d = doc.data['date'] if d.nil? || d.to_s.strip.empty?
      return nil if d.nil? || d.to_s.strip.empty?

      d.respond_to?(:strftime) ? Time.at(d.strftime('%s').to_i) : Time.parse(d.to_s)
    rescue StandardError
      nil
    end
  end
end
