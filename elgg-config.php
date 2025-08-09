<?php
/**
 * Elgg configuration
 */
return [
    'dbuser' => 'admin',
    'dbpass' => 'admin1234',
    'dbname' => 'elggdb',
    'dbhost' => getenv('ELGG_DB_HOST') ? : 'localhost',
    'dbprefix' => 'elgg_',
    'dataroot' => '/var/www/html/elgg/data',
    'wwwroot' => 'http://4.222.233.171/elgg',
    'path' => '/var/www/html/elgg',
    'siteemail' => 'oussamabitaa10@gmail.com',
    'sitename' => 'Marjane News',
    'memcache' => false,
    'redis' => false,
];
