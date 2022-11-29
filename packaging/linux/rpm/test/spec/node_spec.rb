require "docker-api"
require "json"
require "serverspec"

package = JSON.parse(File.read('../../../../package.json'))

if package.has_key?('dependencies')
  describe "node.js" do
    before(:all) do
      File.rename("Dockerfile.custom", "Dockerfile") if File.exist?("Dockerfile.custom")
      image = Docker::Image.build_from_dir('.')

      set :os, family: :debian
      set :backend, :docker
      set :docker_image, image.id
    end

    describe file("/opt/seal/#{ENV['PACKAGE_NAME']}/node") do
      it { should exist }
      it { should be_owned_by "root" }
      it { should be_grouped_into "root" }
    end

    describe command("/opt/seal/#{ENV['PACKAGE_NAME']}/node --version") do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should contain("v#{ENV['NODE_VERSION']}") }
    end

    describe file("/opt/seal/#{ENV['PACKAGE_NAME']}/package.json") do
      it { should exist }
      it { should be_owned_by "root" }
      it { should be_grouped_into "root" }
    end

    describe file("/opt/seal/#{ENV['PACKAGE_NAME']}/bin/app.js") do
      it { should exist }
      it { should be_owned_by "root" }
      it { should be_grouped_into "root" }
    end

    describe file("/opt/seal/#{ENV['PACKAGE_NAME']}/lib") do
      it { should exist }
      it { should be_directory }
      it { should be_owned_by "root" }
      it { should be_grouped_into "root" }
    end
  end
end
