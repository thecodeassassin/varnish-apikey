<?php

// initialize redis
require 'Predis.php';
$redis = new Predis\Client();

// get parameters
$user = htmlspecialchars($_GET["user"]);
$apiname = htmlspecialchars($_GET["apiname"]);

// from apikey.sh
//	key=$(redis-cli get users:${1}:key)
//	redis-cli del key:${key}:api:${2}
//	redis-cli srem key:${key}:api-list ${2}

// issue redis commands
$key = $redis->get("users:$user:key");
$redis->del("key:$key:api:$apiname",1);
$redis->srem("key:$key:api-list",$apiname);

// redirect to index
header( "Location: edit_user.php?name=$user" ) ;
?>

