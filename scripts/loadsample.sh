if ! [ -f sampledata.archive ]; then
  curl -L -o sampledata.archive https://atlas-education.s3.amazonaws.com/sampledata.archive
fi
docker exec -i test-mongo sh -c 'mongorestore --archive' < sampledata.archive
