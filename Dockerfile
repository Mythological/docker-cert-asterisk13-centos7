FROM centos:latest
MAINTAINER Sergei Levin <sergey8888@inbox.ru>

RUN yum update -y
RUN yum install which automake patch binutils-devel gtk2-devel dmidecode wget speex-devel epel-release subversion git bzip2 kernel-headers gcc gcc-c++ cpp ncurses ncurses-devel libxml2 libxml2-devel sqlite sqlite-devel openssl-devel newt-devel jansson-devel kernel-devel libuuid-devel net-snmp-devel xinetd tar make git -y 

WORKDIR /usr/src

# Download asterisk.
RUN wget http://downloads.asterisk.org/pub/telephony/certified-asterisk/asterisk-certified-13.8-current.tar.gz
RUN tar xvfz asterisk-certified-13.8-current.tar.gz 1> /dev/null
WORKDIR /usr/src/asterisk-certified-13.8-cert3

# make asterisk.
RUN ./contrib/scripts/install_prereq install
RUN ./contrib/scripts/get_mp3_source.sh 1> /dev/null

# Configure
RUN ./configure --libdir=/usr/lib64 --with-pjproject-bundled  1> /dev/null  

# Remove the native build option
RUN make menuselect.makeopts
RUN menuselect/menuselect \
  --enable format_mp3 \
  --enable chan_sip \
  --enable res_snmp \
  --enable res_http_websocket \
  --enable cdr_mysql \
  --enable app_mysql \
  menuselect.makeopts

# Continue with a standard make.
RUN make 1> /dev/null
RUN make install 1> /dev/null
RUN make samples 1> /dev/null
RUN make config 1> /dev/null
WORKDIR /

# Create and configure asterisk for running asterisk user.
RUN useradd -m asterisk -s /sbin/nologin
RUN chown asterisk:asterisk /var/run/asterisk
RUN chown -R asterisk:asterisk /etc/asterisk/
RUN chown -R asterisk:asterisk /var/{lib,log,spool}/asterisk
RUN chown -R asterisk:asterisk /usr/lib64/asterisk/

RUN yum -y autoremove 

RUN yum erase -y patch subversion git bzip2 net-snmp-devel tar make && sed 's/20000/10500/' /etc/asterisk/rtp.conf

# Running asterisk with user asterisk.
CMD /usr/sbin/asterisk -f -U asterisk -G asterisk -vvvg -c
