# frozen_string_literal: true

require_relative 'lib/legion/extensions/acp/version'

Gem::Specification.new do |spec|
  spec.name                  = 'lex-acp'
  spec.version               = Legion::Extensions::Acp::VERSION
  spec.authors               = ['Esity']
  spec.email                 = ['matthewdiverson@gmail.com']

  spec.summary               = 'LEX::Acp'
  spec.description           = 'Agent Client Protocol (ACP) adapter for LegionIO'
  spec.homepage              = 'https://github.com/LegionIO/lex-acp'
  spec.license               = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']          = spec.homepage
  spec.metadata['source_code_uri']       = 'https://github.com/LegionIO/lex-acp'
  spec.metadata['documentation_uri']     = 'https://github.com/LegionIO/lex-acp'
  spec.metadata['changelog_uri']         = 'https://github.com/LegionIO/lex-acp'
  spec.metadata['bug_tracker_uri']       = 'https://github.com/LegionIO/lex-acp/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.require_paths = ['lib']

  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-rspec'
end
