require "docker-api"
require "serverspec"

describe "#{ENV['PACKAGE_TYPE']} package" do
  before(:all) do
    File.rename("Dockerfile.custom", "Dockerfile") if File.exist?("Dockerfile.custom")
    image = Docker::Image.build_from_dir('.')

    set :os, family: :debian
    set :backend, :docker
    set :docker_image, image.id
  end

  describe file("/opt/seal/#{ENV['PACKAGE_NAME']}/#{ENV['PACKAGE_NAME']}.service") do
    it { should exist }
  end

  describe file("/usr/lib/systemd/system/#{ENV['PACKAGE_NAME']}.service") do
    it { should exist }
  end

  describe command("rpm -qa | grep #{ENV['PACKAGE_NAME']}") do
    its(:stdout) { should contain("#{ENV['PACKAGE_NAME']}-#{ENV['PACKAGE_VERSION']}-") }
  end

  describe file("/opt/seal/#{ENV['PACKAGE_NAME']}/") do
    it { should be_directory }
    it { should be_owned_by "root" }
    it { should be_grouped_into "root" }
  end

  describe file("/var/log/seal/") do
    it { should be_directory }
    it { should be_owned_by "seal" }
    it { should be_grouped_into "seal" }
  end
end
