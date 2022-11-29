# spec/Dockerfile_spec.rb

require "serverspec"
require "docker-api"

describe "Dockerfile" do
  before(:all) do
    image = Docker::Image.build_from_dir('.')

    set :os, family: :debian
    set :backend, :docker
    set :docker_image, image.id
  end

  describe file("/code/package.json") do
    it { should exist }
  end

  describe command("node --version") do
    its(:stdout) { should contain("v#{ENV['NODE_VERSION']}") }
  end

  describe command("ls -la /code | wc -l") do
    its(:stdout) { should contain("7") }
  end

  describe file("/code/bin/app.js") do
    it { should exist }
  end

  describe file("/code/node_modules") do
    it { should exist }
    it { should be_directory }
  end

  describe file("/var/log/seal/") do
    it { should_not exist }
  end
end
