
install:
	rbenv install -s
	- gem install bundler -v 2.3.10 && rbenv rehash
	bundle _2.3.10_ install --jobs 1

run:
	bundle exec puma

