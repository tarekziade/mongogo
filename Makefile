
install:
	rbenv install -s
	- rbenv exec gem install bundler -v 2.3.10 && rbenv rehash
	rbenv exec bundle install --jobs 1

run:
	rbenv exec bundle exec puma

