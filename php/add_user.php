<?php

// initialize redis
require 'Predis.php';
$redis = new Predis\Client();

// get parameters
$name = htmlspecialchars($_GET["name"]);
$apikey = htmlspecialchars($_GET["apikey"]);

// from apikey.sh
//	redis-cli rpush users "${1}"
//	redis-cli set users:${1}:key ${2}
//	redis-cli set key:${2} 1
//	redis-cli set key:${2}:name ${1}

// issue redis commands
$redis->rpush('users',$name);
$redis->set("users:$name:key",$apikey);
$redis->set("key:$apikey",1);
$redis->set("key:$apikey:name",$name);

// redirect to index
header( 'Location: index.php' ) ;
?>

