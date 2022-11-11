#!/bin/sh

if [ -z ${AWS_S3_ACCESS_KEY_ID} ] && [ -z ${AWS_S3_SECRET_ACCESS_KEY} ]; then
  echo "You need to set AWS_S3_ACCESS_KEY_ID and AWS_S3_SECRET_ACCESS_KEY environment variables. Aborting!"
  exit 1
else
  echo ${AWS_S3_ACCESS_KEY_ID}:${AWS_S3_SECRET_ACCESS_KEY} > /.passwd
  chmod 400 /.passwd
fi

if [ "${S3FS_DEBUG}" == 1 ]; then
  DEBUG_OPTS="-d -d"
fi

S3FS_ARGS="${AWS_S3_MOUNT} \
  ${DEBUG_OPTS} \
  -o passwd_file=/.passwd \
  -o nosuid \
  -o nonempty \
  -o nodev \
  -o allow_other \
  -o default_acl=${AWS_S3_ACL} \
  -o retries=5 \
  -o bucket=${AWS_S3_BUCKET}"

mkdir -p ${AWS_S3_MOUNT}
chown root:root ${AWS_S3_MOUNT}
chmod 755 ${AWS_S3_MOUNT}
addgroup ftpaccess

for user in $USERS; do
  echo $user | sed 's/:/ /g' | while read username passwd; do
    echo $username >> /etc/vsftpd.user_list
    echo -e "$passwd\n$passwd" | adduser -h "${AWS_S3_MOUNT}" -s /usr/sbin/nologin -G ftpaccess $username
  done
done

cat << EOF > /etc/vsftpd.conf
# NETWORK
listen=YES
listen_ipv6=NO
pasv_min_port=$MIN_PORT
pasv_max_port=$MAX_PORT
pasv_address=$ADDRESS
anonymous_enable=NO
pasv_enable=YES
pasv_addr_resolve=YES

# FS
local_enable=YES
write_enable=YES
local_umask=000
dirmessage_enable=YES
xferlog_enable=YES
# xferlog_file=/dev/stdout
connect_from_port_20=YES
vsftpd_log_file=/proc/1/fd/1
ftpd_banner=Hello there!
seccomp_sandbox=NO
background=NO
download_enable=NO
dirlist_enable=NO

# TLS/SSL
ssl_enable=$SSL_ENABLE
allow_anon_ssl=NO
force_local_data_ssl=YES
force_local_logins_ssl=YES
ssl_tlsv1=NO
ssl_sslv2=NO
ssl_sslv3=NO
ssl_ciphers=HIGH
require_ssl_reuse=NO
rsa_cert_file=$TLS_CERT
rsa_private_key_file=$TLS_KEY

# USERS
userlist_enable=YES
userlist_file=/etc/vsftpd.user_list
userlist_deny=NO

# DEBUG
debug_ssl=$DEBUG_SSL
log_ftp_protocol=YES
EOF

cat << EOF > /etc/supervisord.conf
[supervisord]
stdout_logfile=/dev/fd/1
stdout_logfile_maxbytes=0
pidfile=/run/supervisord.pid
nodaemon=true
user=root

[program:s3fs]
command=/usr/bin/s3fs -f ${S3FS_ARGS}
numprocs=1
autostart=true
autorestart=false
priority=1
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
redirect_stderr=true

[program:vsftpd]
command=/usr/sbin/vsftpd /etc/vsftpd.conf
numprocs=1
autostart=true
autorestart=false
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
redirect_stderr=true
EOF

/usr/bin/supervisord -c /etc/supervisord.conf
