FROM ubuntu:trusty
MAINTAINER Martin Yrjölä <martin.yrjola@gmail.com> & Tobias Kaatz <info@kaatz.io>

ENV DEBIAN_FRONTEND noninteractive

# Avoid ERROR: invoke-rc.d: policy-rc.d denied execution of start.
RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d

VOLUME ["/var/lib/samba", "/etc/samba"]

RUN \
      apt-get update && \
      apt-get upgrade -y && \      
      apt-get install -y \
            # Install ssh and supervisord
            openssh-server supervisor \       
            # Install bind9 dns server
            bind9 dnsutils \
            # Install samba and dependencies to make it an Active Directory Domain Controller
            build-essential libacl1-dev libattr1-dev \
            libblkid-dev libgnutls-dev libreadline-dev python-dev libpam0g-dev \
            python-dnspython gdb pkg-config libpopt-dev libldap2-dev \
            dnsutils libbsd-dev attr krb5-user docbook-xsl libcups2-dev acl python-xattr \
            samba smbclient krb5-kdc \
            # Install utilities needed for setup
            expect pwgen \
            # Install rsyslog to get better logging of ie. bind9
            rsyslog \
            # Install sssd for UNIX logins to AD
            sssd sssd-tools && \
      # Setup sshd + supervisor
      mkdir -p /var/run/sshd && \
      mkdir -p /var/log/supervisor && \
      sed -ri 's/PermitRootLogin without-password/PermitRootLogin Yes/g' /etc/ssh/sshd_config && \            
      # Create run directory for bind9
      mkdir -p /var/run/named && \
      chown -R bind:bind /var/run/named

# Install bind9 dns server
ADD named.conf.options /etc/bind/named.conf.options

# Install utilities needed for setup
ADD kdb5_util_create.expect kdb5_util_create.expect

# Install sssd for UNIX logins to AD
ADD sssd.conf /etc/sssd/sssd.conf
RUN chmod 0600 /etc/sssd/sssd.conf

# Add custom script
ADD custom.sh /usr/local/bin/custom.sh
RUN chmod +x /usr/local/bin/custom.sh

# Add supervisord and init
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf
ADD init.sh /init.sh
RUN chmod 755 /init.sh
EXPOSE 22 53 389 88 135 139 138 445 464 3268 3269
ENTRYPOINT ["/init.sh"]
CMD ["app:setup_start"]
