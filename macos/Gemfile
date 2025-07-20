source "https://rubygems.org"

gem "fastlane", "~> 2.228.0"
gem "abbrev"

# takes version from flutter (pubspec.yaml)

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
