#1 /bin/bash
# store pwd in a variable
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd scripts/go
go build -o ./bin/differential-testing
chmod +x ./bin/differential-testing
cd $DIR