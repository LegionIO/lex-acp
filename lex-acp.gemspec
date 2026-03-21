# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'legion/extensions/acp/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-acp'
  spec.version       = Legion::Extensions::Acp::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']
  spec.summary       = 'ACP agent protocol adapter for LegionIO'
  spec.description   = 'Bidirectional Agent Communication Protocol adapter — exposes Legion agents via ACP and consumes external ACP agents'
  spec.homepage      = 'https://github.com/LegionIO/lex-acp'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']          = spec.homepage
  spec.metadata['source_code_uri']       = 'https://github.com/LegionIO/lex-acp'
  spec.metadata['documentation_uri']     = 'https://github.com/LegionIO/lex-acp'
  spec.metadata['changelog_uri']         = 'https://github.com/LegionIO/lex-acp'
  spec.metadata['bug_tracker_uri']       = 'https://github.com/LegionIO/lex-acp/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files         = Dir.glob('{lib,spec}/**/*') + %w[lex-acp.gemspec Gemfile]
  spec.require_paths = ['lib']
end
