<?php
function connectdb($database = "inject_demodb")
{
  if ($database == '') {
    $database = NULL;
  }
  if (isset($_ENV['DATABASE_URL'])) {
    //  http://username:password@hostname:9090/path
    $db_props = parse_url($_ENV['DATABASE_URL']);
    $host = $db_props['host'];
    $port = $db_props['port'];
    $username = $db_props['user'];
    $password = $db_props['pass'];
    //$database = substr($db_props['path'], 1); // remove the slash from '/path'
  } else {
    //$host = isset($_ENV['SQL_INJECTION_DB_HOST']) ? $_ENV['SQL_INJECTION_DB_HOST'] : 'localhost';
    $port = isset($_ENV['SQL_INJECTION_DB_PORT']) ? $_ENV['SQL_INJECTION_DB_PORT'] : 3306;
    $username = isset($_ENV['SQL_INJECTION_DB_USERNAME']) ? $_ENV['SQL_INJECTION_DB_USERNAME'] : 'sql_injection';
    $password = isset($_ENV['SQL_INJECTION_DB_PASSWORD']) ? $_ENV['SQL_INJECTION_DB_PASSWORD'] : 'foobar';
  }
  $db = mysqli_connect(null, $username, $password, $database, null,"/cloudsql/sampleappgcp:us-west2:coffeeshop");
  if (!$db) {
    echo ("Connection failed: " . mysqli_connect_error());
  }
  return $db;
}
