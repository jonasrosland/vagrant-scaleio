#!/bin/bash
while [[ $# > 1 ]]
do
  key="$1"

  case $key in
    -o|--os)
    OS="$2"
    shift
    ;;
    -d|--device)
    DEVICE="$2"
    shift
    ;;
    -i|--installpath)
    INSTALLPATH="$2"
    shift
    ;;
    -v|--version)
    VERSION="$2"
    shift
    ;;
    -n|--packagename)
    PACKAGENAME="$2"
    shift
    ;;
    -f|--firstmdmip)
    FIRSTMDMIP="$2"
    shift
    ;;
    -s|--secondmdmip)
    SECONDMDMIP="$2"
    shift
    ;;
    -p|--password)
    PASSWORD="$2"
    shift
    ;;
    -c|--clusterinstall)
    CLUSTERINSTALL="$2"
    shift
    ;;
    *)
    # unknown option
    ;;
  esac
  shift
done
echo DEVICE  = "${DEVICE}"
echo INSTALL PATH     = "${INSTALLPATH}"
echo VERSION    = "${VERSION}"
echo OS    = "${OS}"
echo PACKAGENAME    = "${PACKAGENAME}"
echo FIRSTMDMIP    = "${FIRSTMDMIP}"
echo SECONDMDMIP    = "${SECONDMDMIP}"
echo CLUSTERINSTALL     = "${CLUSTERINSTALL}"
#echo "Number files in SEARCH PATH with EXTENSION:" $(ls -1 "${SEARCHPATH}"/*."${EXTENSION}" | wc -l)
truncate -s 100GB ${DEVICE}
yum install numactl libaio -y
yum install java-1.7.0-openjdk -y
# install docker experimental
wget -nv https://get.docker.com/rpm/1.7.0/centos-7/RPMS/x86_64/docker-engine-1.7.0-1.el7.centos.x86_64.rpm -O /tmp/docker.rpm
yum install /tmp/docker.rpm -y
systemctl stop docker
rm -Rf /var/lib/docker
wget -nv https://experimental.docker.com/builds/Linux/x86_64/docker-latest -O /bin/docker
sed -i -e "s/^OPTIONS=/#OPTIONS=/g" /etc/sysconfig/docker
systemctl restart docker
# install rexray
wget -nv https://github.com/emccode/rexraycli/releases/download/latest/rexray-Linux-x86_64 -O /bin/rexray
chmod +x /bin/rexray
echo '[Unit]
Description=Start Rex-RAY Service
Before=docker.service
[Service]
EnvironmentFile=/etc/environment
ExecStart=/bin/rexray --daemon
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=always
StartLimitInterval=0
[Install]
WantedBy=docker.service' >> /usr/lib/systemd/system/rexray.service
echo 'GOSCALEIO_ENDPOINT=https://192.168.50.12/api' >> /etc/environment
echo 'GOSCALEIO_INSECURE=true' >> /etc/environment
echo 'GOSCALEIO_USERNAME=admin' >> /etc/environment
echo 'GOSCALEIO_PASSWORD=Scaleio123' >> /etc/environment
echo 'GOSCALEIO_SYSTEM=cluster1' >> /etc/environment
echo 'GOSCALEIO_PROTECTIONDOMAIN=pdomain' >> /etc/environment
echo 'GOSCALEIO_STORAGEPOOL=pool1' >> /etc/environment
systemctl daemon-reload
systemctl start rexray.service
cd /vagrant/scaleio/ScaleIO_1.32_RHEL7_Download

# Always install ScaleIO IM
export GATEWAY_ADMIN_PASSWORD=${PASSWORD}
rpm -Uv /vagrant/scaleio/ScaleIO_1.32_Gateway_for_Linux_Download/${PACKAGENAME}-gateway-${VERSION}.noarch.rpm

if [ "${CLUSTERINSTALL}" == "True" ]; then
  rpm -Uv ${PACKAGENAME}-mdm-${VERSION}.${OS}.x86_64.rpm
  rpm -Uv ${PACKAGENAME}-sds-${VERSION}.${OS}.x86_64.rpm
  MDM_IP=${FIRSTMDMIP},${SECONDMDIP} rpm -Uv ${PACKAGENAME}-sdc-${VERSION}.${OS}.x86_64.rpm
  scli --mdm --add_primary_mdm --primary_mdm_ip ${FIRSTMDMIP} --accept_license
fi

sed -i 's/mdm.ip.addresses=/mdm.ip.addresses='${FIRSTMDMIP}','${SECONDMDMIP}'/' /opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties
service scaleio-gateway restart

if [[ -n $1 ]]; then
  echo "Last line of file specified as non-opt/last argument:"
  tail -1 $1
fi
