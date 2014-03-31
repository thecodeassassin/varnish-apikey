<?php

// initialize redis
require 'Predis.php';
$redis = new Predis\Client();

// issue redis commands
$users = $redis->lrange('users',0,-1);
?> 

<html>
 <head>
  <title>Api manager DEMO</title>
 </head>
 <body>

<p>
List of users:
<?php
foreach ($users as $i => $user) {
    echo "<a href=\"edit_user.php?name=$user\">$user</a>\n";
}
?> 
</p>

<hr>

<p>
Add User:
<form action="add_user.php" method="get">
User name: <input type="text" name="name" /><br>
Api key: <input type="text" name="apikey" /><br>
<input type="submit" />
</form>
</p>

 </body>
</html>

