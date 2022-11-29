# require "docker-api"
# require "json"
# require "serverspec"
#
# package = JSON.parse(File.read('../../../../package.json'))
#
# if package['plossys']['packaging'].has_key?('firewallExceptions')
#   describe "ports" do
#     before(:all) do
#       File.rename("Dockerfile.custom", "Dockerfile") if File.exist?("Dockerfile.custom")
#       image = Docker::Image.build_from_dir('.')
#
#       set :os, family: :debian
#       set :backend, :docker
#       set :docker_image, image.id
#     end
#
#     describe command("sleep 30") do
#       its(:exit_status) { should eq 0 }
#     end
#
#     package['plossys']['packaging']['firewallExceptions'].each do |firewall_exception|
#       if firewall_exception['port'].to_i > 1024
#         describe port(firewall_exception['port'].to_i) do
#           it { should be_listening }
#         end
#       end
#     end
#   end
# end
