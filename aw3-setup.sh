#!/bin/bash
#
#color codes
CYANBG='\033[0;96m'
GREEN='\033[0;92m'
YELLOW='\033[0;33m'
ORANGE='\033[38;5;208m'
NC='\033[0m' # No Color

function getReleaseVersion() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" |
    grep '"tag_name":' |
    sed -E 's/.*"([^"]+)".*/\1/'
}

function getReleaseVersion2() {
  curl --silent "https://github.com/$1/releases/latest" |
    grep '\/tag\/\(.*\)"' |
    sed -E 's/.*\/tag\/([^"]+)".*/\1/'
}

function installAw2(){
    
	printf "${CYANBG}Please enter REDIS_DATABASE_GLOBAL_CACHE number.${NC}\n"
    read redis_db_no
    wp config set REDIS_DATABASE_GLOBAL_CACHE $redis_db_no --add=true --type=constant --allow-root
    
    printf "${CYANBG}Please enter REDIS_DATABASE_SESSION_CACHE number.${NC}\n"
    read redis_db_no
    wp config set REDIS_DATABASE_SESSION_CACHE $redis_db_no --add=true --type=constant --allow-root
    wp config set REDIS_HOST 127.0.0.1 --add=true --type=constant --allow-root
    wp config set REDIS_PORT 6379 --add=true --type=constant --allow-root
    
	wp config set AWESOME_PATH /var/www/awesome-enterprise --add=true --type=constant --allow-root
	wp config set SITE_URL "x" --add=true --type=constant --allow-root
    wp config set HOME_URL "x" --add=true --type=constant --allow-root
	
	wp config set WP_POST_REVISIONS 100 --allow-root
	
	printf "${GREEN}Info:${YELLOW} Installing Monomyth Enterprise latest version\n${NC}";
    #aw2_theme_version=$(getReleaseVersion 'WPoets/awesome-enterprise');
    #wp theme install https://github.com/WPoets/monomyth-enterprise/archive/$aw2_theme_version.zip --activate --allow-root
    wp theme install https://github.com/WPoets/monomyth-enterprise/archive/master.zip --activate --allow-root --quiet

    aw2_plugin_version=$(getReleaseVersion2 'WPoets/awesome-enterprise-wp');
    printf "${GREEN}Info:${YELLOW} Installing Awesome Enterprise WP version $aw2_plugin_version${NC}\n";

    wp plugin install https://github.com/WPoets/awesome-enterprise-wp/archive/$(getReleaseVersion2 'WPoets/awesome-enterprise-wp').zip --activate --allow-root --quiet
   
   
    wp plugin install advanced-custom-fields --activate --allow-root --quiet
    wp plugin install custom-post-type-ui --activate --allow-root --quiet
    wp plugin install wordpress-importer --activate --allow-root --quiet
    wp plugin install classic-editor --activate --allow-root --quiet
    wp plugin install wp-google-authenticator --allow-root --quiet
    wp plugin install google-apps-login --allow-root --quiet
    
    wp rewrite structure '/%postname%/' --allow-root --quiet
	
	printf "${GREEN}Info:${YELLOW} Importing Basic Apps & Core Services ${NC}\n";

    
    wget -O /tmp/core.xml https://raw.githubusercontent.com/WPoets/aw-setup/master/code/core.xml /tmp
	wget -O /tmp/basic-apps.xml https://raw.githubusercontent.com/WPoets/aw-setup/master/code/basic-apps.xml /tmp
	
	wp import /tmp/basic-apps.xml --authors=skip --allow-root --quiet
    wp import /tmp/core.xml --authors=skip --allow-root --quiet
	wp eval '\aw2\global_cache\flush(null,null,null);\aw2\session_cache\flush(null,null,"");' --allow-root --quiet
	
	wp post-type list --fields=name --allow-root
	
    wget -O /tmp/common-apps.xml https://raw.githubusercontent.com/WPoets/aw-setup/master/code/common-apps.xml /tmp
    wget -O /tmp/common-services.xml https://raw.githubusercontent.com/WPoets/aw-setup/master/code/common-services.xml /tmp
    
	wp import /tmp/common-apps.xml --authors=skip --allow-root --quiet
    wp import /tmp/common-services.xml --authors=skip --allow-root --quiet
   
  

  
    #import all data again to import the posts whose post type is registered by the above command
    
    #to change the file permission of all new installed plugins to www-data user
    chown -R www-data:www-data wp-content/uploads/*
    
	wp config set SITE_URL "(\$_SERVER['HTTPS'] ? 'https://' : 'http://') . \$_SERVER['HTTP_HOST']" --raw --add=true --type=constant --allow-root
    wp config set HOME_URL "(\$_SERVER['HTTPS'] ? 'https://' : 'http://') . \$_SERVER['HTTP_HOST']" --raw --add=true --type=constant --allow-root
  
	
    printf "\n\n\n\n\n"
}

function createWpUser(){
    read -p "Please provide user-login = " ul
    read -p "Please provide user-email = " ue
    read -p "Please provide user-pass = " up
    echo "creating wp user"
    if op=$(! wp user create $ul $ue --role=administrator --user_pass=$up --allow-root); then
        while true; do
            read -p "Failed to create new user do you want to create it again.[y/n]" yn
            case $yn in
                [Yy]* ) createWpUser $1; break;;
                [Nn]* ) break;;
                * ) echo "Please answer y or n.";;
            esac
        done
    fi
    
    printf "${GREEN}Info:${YELLOW} Adding capablility for Developer Awesome UI${NC}\n";
    wp user add-cap $ul develop_for_awesomeui --allow-root
}

function createWpUserPrompt(){
    while true; do
        read -p "Do you wish to create new admin user? [y/n]" yn
        case $yn in
            [Yy]* ) createWpUser $1; break;;
            [Nn]* ) break;;
            * ) echo "Please answer y or n.";;
        esac
    done
}

if [ -z "$1" ]; then
    echo "Please mention site name!!!"
    exit
fi

echo 'Checking WordOps...'
if op=$(! wo); then
    printf 'WordOps not installed!!!'
    exit
fi

echo 'Checking site...'
if op=$(! wo site info $1); then
    echo "Site does not exists"
    exit
else
    cd /var/www/$1/htdocs
    installAw2 $1
    createWpUserPrompt $1
fi

printf "${ORANGE}Site Successfully configured... ✌ \n${NC}"