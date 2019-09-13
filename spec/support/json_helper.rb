# frozen_string_literal: true

module JsonHelper
  def parse_file(file, vars = {})
    JSON.parse(read_file(file, vars))
  end

  def read_file(file, vars = {})
    File.read(Pathname.new(__dir__).join('..', 'fixtures', 'json')
      .join("#{file}.json")) % vars
  end

  # rubocop:disable Style/AccessModifierDeclarations
  module_function :read_file
  module_function :parse_file
  # rubocop:enable Style/AccessModifierDeclarations
end
