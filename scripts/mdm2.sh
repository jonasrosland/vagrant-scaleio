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
    -t|--tbip)
    TBIP="$2"
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
echo TBIP    = "${TBIP}"
echo PASSWORD    = "${PASSWORD}"
echo CLUSTERINSTALL   =  "${CLUSTERINSTALL}"
#echo "Number files in SEARCH PATH with EXTENSION:" $(ls -1 "${SEARCHPATH}"/*."${EXTENSION}" | wc -l)
truncate -s 100GB ${DEVICE}
yum install numactl libaio -y
# install docker experimental
wget -nv https://get.docker.com/rpm/1.7.0/centos-7/RPMS/x86_64/docker-engine-1.7.0-1.el7.centos.x86_64.rpm -O /tmp/docker.rpm
yum install /tmp/docker.rpm -y
wget -nv https://experimental.docker.com/builds/Linux/x86_64/docker-latest -O /bin/docker
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
Restart=on-failure
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
cd /vagrant/scaleio/ScaleIO_1.32_RHEL7_Download

if [ "${CLUSTERINSTALL}" == "True" ]; then
  rpm -Uv ${PACKAGENAME}-mdm-${VERSION}.${OS}.x86_64.rpm
  rpm -Uv ${PACKAGENAME}-sds-${VERSION}.${OS}.x86_64.rpm
  MDM_IP=${FIRSTMDMIP},${SECONDMDIP} rpm -Uv ${PACKAGENAME}-sdc-${VERSION}.${OS}.x86_64.rpm

  scli --login --mdm_ip ${FIRSTMDMIP} --username admin --password admin
  scli --mdm_ip ${FIRSTMDMIP} --set_password --old_password admin --new_password ${PASSWORD}
  scli --mdm_ip ${FIRSTMDMIP} --login --username admin --password ${PASSWORD}
  scli --add_secondary_mdm --mdm_ip ${FIRSTMDMIP} --secondary_mdm_ip ${SECONDMDMIP}
  scli --add_tb --mdm_ip ${FIRSTMDMIP} --tb_ip ${TBIP}
  scli --switch_to_cluster_mode --mdm_ip ${FIRSTMDMIP}
  scli --add_protection_domain --mdm_ip ${FIRSTMDMIP} --protection_domain_name pdomain
  scli --add_storage_pool --mdm_ip ${FIRSTMDMIP} --protection_domain_name pdomain --storage_pool_name pool1
  scli --add_sds --mdm_ip ${FIRSTMDMIP} --sds_ip ${FIRSTMDMIP} --device_path ${DEVICE} --sds_name sds1 --protection_domain_name pdomain --storage_pool_name pool1
  scli --add_sds --mdm_ip ${FIRSTMDMIP} --sds_ip ${SECONDMDMIP} --device_path ${DEVICE} --sds_name sds2 --protection_domain_name pdomain --storage_pool_name pool1
  scli --add_sds --mdm_ip ${FIRSTMDMIP} --sds_ip ${TBIP} --device_path ${DEVICE} --sds_name sds3 --protection_domain_name pdomain --storage_pool_name pool1
  echo "Waiting for 30 seconds to make sure the SDSs are created"
  sleep 30
  scli --add_volume --mdm_ip ${FIRSTMDMIP} --size_gb 8 --volume_name vol1 --protection_domain_name pdomain --storage_pool_name pool1
  scli --map_volume_to_sdc --mdm_ip ${FIRSTMDMIP} --volume_name vol1 --sdc_ip ${FIRSTMDMIP} --allow_multi_map
  scli --map_volume_to_sdc --mdm_ip ${FIRSTMDMIP} --volume_name vol1 --sdc_ip ${SECONDMDMIP} --allow_multi_map
  scli --map_volume_to_sdc --mdm_ip ${FIRSTMDMIP} --volume_name vol1 --sdc_ip ${TBIP} --allow_multi_map
  scli --mdm_ip ${FIRSTMDMIP} --rename_system --new_name cluster1
fi

systemctl restart rexray.service
if [[ -n $1 ]]; then
  echo "Last line of file specified as non-opt/last argument:"
  tail -1 $1
fi
