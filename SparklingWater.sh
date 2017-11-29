#!/usr/bin/env bash

echo
echo "=== https://h2o-release.s3.amazonaws.com/sparkling-water/rel-2.2/3/index.html ==="
echo

function exit_badly {
  echo $1
  exit 1
}

me="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"

[[ $(lsb_release -rs) == "17.10" ]] || exit_badly "This script is for Ubuntu 17.10 only, aborting (if you know what you are doing, delete this check)."
[[ $(id -u) -eq 0 ]] || exit_badly "Please re-run as root (e.g. sudo $me)"

export DEBIAN_FRONTEND=noninteractive

apt-get -o Acquire::ForceIPv4=true update && apt-get upgrade -y

apt-get install -y language-pack-en moreutils unattended-upgrades ack-grep
apt-get install -y git default-jre
apt install -y unzip

mkdir /usr/local/src
pushd /usr/local/src

wget https://h2o-release.s3.amazonaws.com/sparkling-water/rel-2.2/3/sparkling-water-2.2.3.zip
unzip sparkling-water-2.2.3.zip
ln -s sparkling-water-2.2.3 sparkling-water

wget http://download.nextag.com/apache/spark/spark-2.2.0/spark-2.2.0-bin-hadoop2.7.tgz
gzip -dc spark-2.2.0-bin-hadoop2.7.tgz | tar -xvf-
ln -s spark-2.2.0-bin-hadoop2.7 spark

wget https://s3.amazonaws.com/steam-release/steam-1.1.6-linux-amd64.tar.gz
gzip -dc steam-1.1.6-linux-amd64.tar.gz | tar -xvf-
ln -s steam-1.1.6-linux-amd64 steam

export SPARK_HOME="/usr/local/src/spark"
export MASTER="local[*]"
echo "SPARK_HOME=\"/usr/local/src/sparkling-water\"" | tee -a ~/.profile
echo "MASTER=\"local[*]\"" | tee -a ~/.profile

echo "JAVA_HOME=$(which java)" | sudo tee -a /etc/environment

export JAVA_HOME=/usr
cd /usr/local/src/sparkling-water
wget https://raw.githubusercontent.com/h2oai/sparkling-water/ad99cd47fb26b6a1de663936492ed6fc6e3ac7b9/examples/scripts/StrataAirlines.script.scala

echo
echo "================================================================================="
echo "=== To start this in the future, run /usr/bin/sparkling-water                 ==="
echo "================================================================================="
echo ""
echo "NOTE: watch for the URLS"
echo "You may also run steam in the /usr/local/src/steam dir"
echo "see: https://www.h2o.ai/steam/"
echo "================================================================================="
echo

cat << EOF > /usr/local/src/sparkling-water/start.scala
import org.apache.spark.h2o._
val h2oContext = H2OContext.getOrCreate(spark)
import h2oContext._
EOF

cat << EOF > /usr/bin/sparkling-water
#!/usr/bin/env bash
export JAVA_HOME=/usr
export SPARK_HOME="/usr/local/src/spark"
export MASTER="local[*]"
cd /usr/local/src/sparkling-water
echo
echo "================================================================================="
echo "NOTE: watch for the URLS"
echo "You may also run steam in the /usr/local/src/steam dir"
echo "see: https://www.h2o.ai/steam/"
echo "================================================================================="
echo
bin/sparkling-shell --conf "spark.executor.memory=1g" -i /usr/local/src/sparkling-water/start.scala
EOF

chmod +x /usr/bin/sparkling-water

bin/sparkling-shell --conf "spark.executor.memory=1g" -i /usr/local/src/sparkling-water/start.scala





