# wunder/fuzzy-alpine-devshell
#
# VERSION v7.0.12-2
#
FROM quay.io/wunder/fuzzy-alpine-php-dev:v7.0.12
MAINTAINER aleksi.johansson@wunder.io

# Set versions.
ENV COMPOSER_VERSION=1.3.1
ENV PRESTISSIMO_VERSION=0.3.5
ENV DRUPAL_CONSOLE_VERSION=1.0.0-rc14
ENV PLATFORMSH_CLI_VERSION=3.12.0
ENV DRUSH_VERSION=8.1.9

## Global

### Common developer tools
RUN apk --no-cache add \
curl \
docker \
wget \
git \
vim \
zsh \
tar \
gzip \
p7zip \
py-yaml \
xz \
nodejs \
sudo \
openssh \
openssl \
ansible \
rsync && \
rm -rf /tmp/* && \
rm -rf /var/cache/apk/*
ADD etc/sudoers.d/app_nopasswd /etc/sudoers.d/app_nopasswd

### PHP and MySQL
RUN apk --no-cache add \
mysql-client \
postgresql-client \
php7-ast \
php7-openssl \
php7-pear \
php7-phar \
php7-zlib && \
ln -s /usr/bin/php7 /usr/bin/php && \
rm -rf /tmp/* && \
rm -rf /var/cache/apk/*
ADD etc/php7/conf.d/WK_date.ini /etc/php7/conf.d/WK_date.ini

### Common theming tools
RUN npm install -g gulp grunt

### Composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
php composer-setup.php --install-dir=/usr/local/bin --filename=composer --version=${COMPOSER_VERSION} && \
php -r "unlink('composer-setup.php');" && \
composer global require "hirak/prestissimo:${PRESTISSIMO_VERSION}"

## App user specific

USER app

### Drush
RUN composer global require drush/drush:${DRUSH_VERSION}

### Drupal Console
# @TODO this should be built using composer. Composer builds currently fail, so we simulate it
# RUN composer global require drupal/console:${DRUPAL_CONSOLE_VERSION} --stability dev
#
RUN cd /tmp && \
echo ${DRUPAL_CONSOLE_VERSION} && \
wget https://github.com/hechoendrupal/DrupalConsole/archive/${DRUPAL_CONSOLE_VERSION}.tar.gz && \
tar -zxf ${DRUPAL_CONSOLE_VERSION}.tar.gz && \
mv /tmp/drupal-console-${DRUPAL_CONSOLE_VERSION}/bin/drupal /app/.composer/vendor/bin/ && \
mv /tmp/drupal-console-${DRUPAL_CONSOLE_VERSION}/bin/drupal.php /app/.composer/vendor/bin/ && \
cd && \
rm -rf /tmp/drupal-console-${DRUPAL_CONSOLE_VERSION}

### Drupal 8
# Prepare composer caches for Drupal 8 project creation and init Drupal Console.
RUN composer create-project drupal-composer/drupal-project:8.x-dev /tmp/tmp_drupal8 --stability dev --no-interaction && \
export PATH=$HOME/.composer/vendor/bin:$PATH && \
cd /tmp/tmp_drupal8 && \
composer install && \
# drupal init --override --no-interaction && \
mkdir -p ~/.config/fish/completions && \
ln -s ~/.console/drupal.fish ~/.config/fish/completions/drupal.fish && \
rm -rf /tmp/tmp_drupal8
ADD app/.console/phpcheck.yml /app/.console/phpcheck.yml

### PlatformSH CLI
# @TODO this should be built using composer. Composer builds currently fail, so we simulate it
# RUN composer global require platformsh/cli:${PLATFORMSH_CLI_VERSION}
#
RUN wget -O /app/.composer/vendor/bin/platform https://github.com/platformsh/platformsh-cli/releases/download/v${PLATFORMSH_CLI_VERSION}/platform.phar && \
chmod a+x /app/.composer/vendor/bin/platform

### oh-my-zsh
RUN git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
ADD app/.zshrc /app/.zshrc
ADD app/.zshrc.d /app/.zshrc.d

USER root

RUN chown -R app:app /app

## Config

USER app
WORKDIR /app
ENTRYPOINT ["/usr/bin/ssh-agent","/bin/zsh"]
