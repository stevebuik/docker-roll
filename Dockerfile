FROM clojure:lein-2.7.1

# add Boot since Mach/Roll use it

ENV BOOT_VERSION=2.7.2
ENV BOOT_INSTALL=/usr/local/bin/

WORKDIR /tmp

# NOTE: BOOT_VERSION tells the boot.sh script which version of boot to install
# on its first run. We always download version 2.7.2 of boot.sh because it is
# just the installer script. When/if the boot project releases a new installer
# script we will update this to use it.
RUN mkdir -p $BOOT_INSTALL \
  && wget -q https://github.com/boot-clj/boot-bin/releases/download/2.7.2/boot.sh \
  && echo "Comparing installer checksum..." \
  && echo "f717ef381f2863a4cad47bf0dcc61e923b3d2afb *boot.sh" | sha1sum -c - \
  && mv boot.sh $BOOT_INSTALL/boot \
  && chmod 0755 $BOOT_INSTALL/boot

ENV PATH=$PATH:$BOOT_INSTALL
ENV BOOT_AS_ROOT=yes

RUN boot

# Lumo v1.7 needs Node v8 so install that instead of the default stable alpine version
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash
RUN apt-get install -y nodejs

# mach will install Lumo v1.7
RUN npm install -g @juxt/mach --unsafe-perm

# run mach once to ensure it has downloaded all it's requirements
RUN echo '{main (println "Success!")}' > Machfile.edn \
  && mach && rm Machfile.edn

# install AWS CLI so that Roll can upload
RUN apt-get -y install awscli

# install Terraform for AWS Roll deployment
ENV TERRAFORM=terraform_0.10.7_linux_amd64.zip
ENV TERRAFORM_URL=https://releases.hashicorp.com/terraform/0.10.7/$TERRAFORM
RUN wget -q $TERRAFORM_URL \
    && unzip $TERRAFORM \
    && rm $TERRAFORM

RUN mv terraform /usr/bin
