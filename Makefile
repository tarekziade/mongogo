.phony: run-stack populate-mongo gen-certs install run

run-stack:
	cd scripts; ./runstack.sh

populate-mongo:
	cd scripts; ./loadsample.sh

gen-certs:
	rbenv exec ruby ./certs/generate_keys.rb

install:
	rbenv install -s
	- rbenv exec gem install bundler -v 2.3.10 && rbenv rehash
	rbenv exec bundle install --jobs 1

run:
	rbenv exec bundle exec puma
