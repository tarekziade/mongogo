.phony: build-slides run-stack populate-mongo gen-certs install run-stack-ent-search delete-all

run-stack:
	cd scripts; ./runstack.sh

run-connector:
	rbenv exec ruby connector_app.rb

mongo-writes:
	rbenv exec ruby scripts/mongo_writer.rb

run-stack-ent-search:
	cd scripts; ./runstack-enterprise-search.sh

populate-mongo:
	cd scripts; ./loadsample.sh

kill-docker:
	docker stop `docker ps -qa`
	docker rm `docker ps -qa`

gen-certs:
	rbenv exec ruby ./certs/generate_keys.rb

install:
	rbenv install -s
	- rbenv exec gem install bundler -v 2.3.10 && rbenv rehash
	rbenv exec bundle install --jobs 1

run-kibanana:
	rbenv exec bundle exec puma

build-slides:
	npx @marp-team/marp-cli@latest slides/slides.md -o slides/output.html

delete-all:
	./scripts/delete-all.sh
	- cd scripts; ./loadsample.sh
