# frozen_string_literal: true
require 'openssl'

puts('Generate key pair...')
pkey = OpenSSL::PKey::RSA.new(2048)

File.open(File.join(File.dirname(__FILE__), 'public_key.pem'), 'w') do |file|
  file.puts(pkey.public_key.to_pem)
end

File.open(File.join(File.dirname(__FILE__), 'private_key.pem'), 'w') do |file|
  file.puts(pkey.to_pem)
end

puts('done.')
