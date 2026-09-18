# frozen_string_literal: true

source "https://rubygems.org"
# gemspec

gem "jekyll", ">= 4", "< 5.0"
gem "kramdown-parser-gfm" if ENV["JEKYLL_VERSION"] == "~> 3.9"
gem "jekyll-feed", "~> 0.9"
gem "jekyll-seo-tag", "~> 2.1"

platforms :windows, :jruby do
  gem "tzinfo", ">= 1", "< 3"
  gem "tzinfo-data"
end

gem "wdm", "~> 0.1", :platforms => [:windows]
