def build_constants_module(module_name:, path_attributes:)
  Object.const_set(module_name, Module.new)
  constants_module = Object.const_get(module_name)
  Dir.glob(File.join(*path_attributes)).each do |filepath|
    constant_name = filepath.split("/").last.split(".").first
    file_contents = JSON.parse(File.read(filepath))

    # Access via hash (i.e. Constants::BENEFIT_TYPES["compensation"]) to access keys.
    constants_module.const_set(constant_name.to_s, file_contents)

    # Access via methods (i.e. Constants.BENEFIT_TYPES.compensation) to throw errors
    # when incorrectly addressing constants.
    constants_module.define_singleton_method(constant_name) { Subconstant.new(file_contents) }
  end
end

# https://stackoverflow.com/questions/26809848/convert-hash-to-object
class Subconstant
  def initialize(hash)
    hash.each do |k, v|
      define_singleton_method(k) { v.is_a?(Hash) ? Subconstant.new(v) : v }
    end
  end

  def to_h
    h = {}
    singleton_methods.each do |m|
      val = singleton_method(m).call
      h[m] = val.is_a?(Subconstant) ? val.to_h : val
    end
    h
  end
end

build_constants_module(module_name: "Constants", path_attributes: [Rails.root, "client", "constants", "*"])
build_constants_module(module_name: "FakeConstants", path_attributes: [Rails.root, "lib", "fakes", "constants", "*"])
