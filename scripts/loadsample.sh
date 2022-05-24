if ! [ -f sampledata.archive ]; then
  curl -L -o sampledata.archive https://atlas-education.s3.amazonaws.com/sampledata.archive
fi
docker exec -i mongo1 sh -c 'mongorestore --archive' < sampledata.archive
