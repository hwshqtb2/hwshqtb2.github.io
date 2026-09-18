module Jekyll
  class MainPart < Generator
    safe true
    def generate(site)
      arr = Hash.new

      site.pages.each do |page|
        if page.data["main_part"]
          arr.store(page.data["main_part"], page)
        end
      end
      sorted = arr.sort_by { |key, value| -key }
      if sorted.size > 0
        site.data["main_part_page"] = []
        for (key, value) in sorted
          site.data["main_part_page"] << value
        end
      end
    end
  end

end
