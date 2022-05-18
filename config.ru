$LOAD_PATH << '../'

require 'rack'
require './app'

run SyncService
