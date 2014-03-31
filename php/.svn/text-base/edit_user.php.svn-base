<?php

// initialize redis
require 'Predis.php';
$redis = new Predis\Client();

// get parameters
$name = htmlspecialchars($_GET["name"]);

// from apikey.sh
//	key=$(redis-cli get users:${1}:key)
//	apis=$(redis-cli smembers key:${key}:api-list)
//	blocked=$(redis-cli get key:${key}:blocked)
//	referer=$(redis-cli get key:${key}:security:referer)
//	skey=$(redis-cli get key:${key}:security:key)
//	stimeout=$(redis-cli get key:${key}:security:timeout)
//	msg "user-name: ${1}"
//	msg "apikey: ${key}"
//	msg "api list:"
//	msg ${apis}
//	msg "blocked: ${blocked}"
//	msg "referer: ${referer}"
//	msg "security-key: ${skey}"
//	msg "security-timeout: ${stimeout}"

// issue redis commands
$key = $redis->get("users:$name:key");
$apis = $redis->smembers("key:$key:api-list");
$blocked = $redis->get("key:$key:blocked");
$referer = $redis->get("key:$key:security:referer");
$skey = $redis->get("key:$key:security:key");
$stimeout = $redis->get("key:$key:security:timeout");
?> 

<html>
 <head>
  <title>Api manager DEMO</title>
 </head>
 <body>

<a href="index.php">Main page</a>

<hr>

<p>
User Parameters:<br><br>
<?php

echo "user-name: $name<br>";
echo "apikey: $key<br>";

echo "api list: ";
foreach ($apis as $i => $api) {
    echo "<a href=\"delete_api.php?user=$name&apiname=$api\">$api</a> ";
}
echo "<br>";

echo "blocked: $blocked<br>";
echo "referer: $referer<br>";
echo "security-key: $skey<br>";
echo "security-timeout: $stimeout<br>";
?> 
</p>

<hr>

<p>
Add Api:
<form action="add_api.php" method="get">
<input type="hidden" name="user" value="<?= $name ?>"/>
Api name: <input type="text" name="apiname" /><br>
<input type="submit" />
</form>
</p>

 </body>
</html>

