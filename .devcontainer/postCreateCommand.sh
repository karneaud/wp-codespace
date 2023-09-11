#! /bin/bash
# Create Wordpress Folder
# Check if the "./wordpress" directory exists
if [ ! -d "$PWD/wordpress" ]; then
  echo "Creating the $PWD/wordpress directory..."
  mkdir "$PWD/wordpress"
fi

# Start Mysql
echo "Setup MYSQL..."
sudo service mysql start 
sudo mysqladmin create $MYSQL_DATABASE
sudo mysqladmin create wordpress
sudo mysqladmin --host=localhost password $MYSQL_USER_PASSWORD
sudo mysql -hlocalhost -uroot -p$MYSQL_USER_PASSWORD -e "CREATE USER '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_USER_PASSWORD'; GRANT ALL PRIVILEGES ON wordpress.* TO '$MYSQL_USER'@'localhost'; GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'localhost'; GRANT ALL PRIVILEGES ON wordpress.* TO '$MYSQL_USER'@'localhost'; FLUSH PRIVILEGES;"

# Apache
sudo chmod 777 /etc/apache2/sites-available/000-default.conf
sudo sed "s@.*DocumentRoot.*@\tDocumentRoot $PWD/wordpress@" .devcontainer/000-default.conf > /etc/apache2/sites-available/000-default.conf
update-rc.d apache2 defaults 
sudo a2enmod rewrite
sudo a2enmod ssl
sudo service apache2 restart

LOCALE="en_US"

# WordPress Core install
echo "Setup $WORDPRESS_TITLE"
wp core download --locale=$LOCALE --path=wordpress

if [  ! -f "./wordpress/wp-config.php" ]; then
  echo "Create wp-config.php"
  wp config create --dbname=$MYSQL_DATABASE --dbuser=$MYSQL_USER --dbpass=$MYSQL_USER_PASSWORD --dbhost=$MYSQL_HOST --path=./wordpress
  LINE_NUMBER=`grep -n -o 'Add any custom values between this line' ./wordpress/wp-config.php | cut -d ':' -f 1`
  sed -i "${LINE_NUMBER}r ./.devcontainer/wp-config-addendum.txt" ./wordpress/wp-config.php
  echo "Install with user ${WORDPRESS_USER:-$GITHUB_USER}"
  wp core install --url="" --title="$WORDPRESS_TITLE" --admin_user=${WORDPRESS_USER:-$GITHUB_USER} --admin_password=$WORDPRESS_USER_PASSWORD --admin_email=$WORDPRESS_USER_EMAIL --path=./wordpress
  # Install some essential WP plugins
  wp plugin install query-monitor --activate --path=./wordpress
  wp plugin install woocommerce --activate --path=./wordpress
fi
