require 'time'

module Jekyll
  # 生成"最近更新"列表：posts + layout 为 article/post 的页面，按
  # modified_date / date 倒序（两者皆无的文档不参与）取前 5，
  # 存入 site.data['recent']，由 _includes/latest.html 渲染。
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

    # 先看 modified_date，再看 date；两者皆无返回 nil（不参与"最近更新"）
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
