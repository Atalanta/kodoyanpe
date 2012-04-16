def find_package(arch, version)
  package_name="chef-full_0.10.6-4.solaris2.#{version}_#{arch}.solaris"
  full_path = Dir.pwd.split(File::SEPARATOR)
  (full_path.length - 1).downto(0) do |i|
    package = File.join(full_path[0..i] + [package_name])
    if File.exist?(package)
      return true
    end
  end
  false
end

