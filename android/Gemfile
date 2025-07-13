source "https://rubygems.org"

gem "fastlane"
# takes version from flutter (pubspec.yaml)
gem "fastlane-plugin-flutter_version", git: "https://github.com/tianhaoz95/fastlane-plugin-flutter-version"

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
