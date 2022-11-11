# s3fs + ftp as a -service- single container

Yet another one attempt to create a combined solution for this stuff.

## Setup

```bash
docker build -t s3ftp:latest .
docker-compose up -d
```

Dont' forget to open ports `21, 21000-21010` in iptables / security groups!

## Used stuff:

* https://github.com/s3fs-fuse/s3fs-fuse
* https://security.appspot.com/vsftpd.html
