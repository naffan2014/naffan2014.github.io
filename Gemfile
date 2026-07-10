source "https://rubygems.org"
ruby RUBY_VERSION

# Hello! This is where you manage which Jekyll version is used to run.
# When you want to use a different version, change it below, save the
# file and run `bundle install`. Run Jekyll with `bundle exec`, like so:
#
#     bundle exec jekyll serve
#
# This will help ensure the proper Jekyll version is running.
# Happy Jekylling!
gem "jekyll", "3.9"
gem "liquid", "~> 4.0", ">= 4.0.4" # 4.0.3 在 Ruby 3.2+ 上调用已删除的 tainted?
gem "webrick"
gem "logger" # Ruby 4.0 移除了 default logger,jekyll 3.9 仍依赖
gem "csv"    # Ruby 3.4+ 移除了 default csv,jekyll 3.9 仍依赖
gem "base64" # safe_yaml 等依赖
gem "bigdecimal"
gem "benchmark"
gem "pathname"
gem "mutex_m"
gem "drb"
gem "connection_pool"
gem "ruby2_keywords"

# This is the default theme for new Jekyll sites. You may change this to anything you like.
#gem "minima", "~> 2.0"

# If you want to use GitHub Pages, remove the "gem "jekyll"" above and
# uncomment the line below. To upgrade, run `bundle update github-pages`.
# gem "github-pages", group: :jekyll_plugins

# If you have any plugins, put them here!
group :jekyll_plugins do
#   gem "jekyll-paginate", "~> 1.1.0"
   #gem "nokogiri", "~> 1.6.8.1"
   gem "jekyll-seo-tag"
   gem "jekyll-sitemap", ">= 1.4.0"
   gem "jekyll-paginate-v2"
   gem "jekyll-feed"
   gem "kramdown-parser-gfm"
   #gem "github-pages", ">= 104"
   gem "nokogiri"
end
