#!/usr/bin/env bash
# Provision WordPress Stable with a set of preinstalled plugins

DOMAIN=`get_primary_host "${VVV_SITE_NAME}".test`
DOMAINS=`get_hosts "${DOMAIN}"`
SITE_TITLE=`get_config_value 'site_title' "${DOMAIN}"`
WP_VERSION=`get_config_value 'wp_version' 'latest'`
WP_TYPE=`get_config_value 'wp_type' "single"`
DB_NAME=`get_config_value 'db_name' "${VVV_SITE_NAME}"`
DB_NAME=${DB_NAME//[\\\/\.\<\>\:\"\'\|\?\!\*-]/}

# Create database if it doesn't exist yet
echo -e "\nCreating database '${DB_NAME}' (if it does not exist yet)"
mysql -u root --password=root -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME}"
mysql -u root --password=root -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO wp@localhost IDENTIFIED BY 'wp';"
echo -e "\nDB operations complete.\n\n"

# Create Nginx log files
echo -e "Creating Nginx log files"
mkdir -p ${VVV_PATH_TO_SITE}/log
touch ${VVV_PATH_TO_SITE}/log/error.log
touch ${VVV_PATH_TO_SITE}/log/access.log
echo -e "\nLog files created\n\n"

# Install and configure WordPress
if [[ ! -f "${VVV_PATH_TO_SITE}/publc_html/wp-load.php" ]]; then
  echo  "Downloading WordPress (${WP_VERSION})..."
  noroot wp core download --version="${WP_VERSION}"
fi

if [[ ! -f "${VVV_PATH_TO_SITE}/public_html/wp-config.php" ]]; then
  echo "Configuring WordPress (${WP_VERSION})..."
  noroot wp core config --dbname="${DB_NAME}" --dbuser=wp --dbpass=wp --quiet
fi

if ! $(noroot wp core is-installed); then
  echo "Installing WordPress (${WP_VERSION})..."
  noroot wp core install --url="${DOMAIN}" --quiet --title="${SITE_TITLE}" --admin_name=admin --admin_email="admin@local.test" --admin_password="password"
else
  echo "Updating WordPress (${WP_VERSION})..."
  cd ${VVV_PATH_TO_SITE}/public_html
  noroot wp core update --version="${WP_VERSION}"
fi

# Install WordPress Plugins
echo -e "\nInstalling plugins..."
noroot wp plugin install wordpress-importer --activate
noroot wp plugin install developer
noroot wp plugin install query-monitor --activate
noroot wp plugin install wordpress-seo --activate
noroot wp plugin install admin-menu-editor --activate
noroot wp plugin install advanced-custom-fields --activate
echo -e "\nPlugins installed"

cp -f "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf.tmpl" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
sed -i "s#{{DOMAINS_HERE}}#${DOMAINS}#" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"