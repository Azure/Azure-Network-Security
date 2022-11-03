<?php
  require_once('connectdb.php');
  $db = connectdb('');
  mysqli_query($db, "CREATE DATABASE IF NOT EXISTS inject_demodb;");
  // coffee table
  $drop_sql = 'DROP TABLE IF EXISTS coffee;';
  $create_sql = file_get_contents('../sql/create_db.sql');
  $data_sql = file_get_contents('../sql/coffee_data.sql');



  $db = connectdb();
  $result = mysqli_query($db, $drop_sql);
  if (!$result) {
    die("ERROR: " . mysqli_error($db));
  }
  $result = mysqli_query($db, $create_sql);
  if (!$result) {
    die("ERROR: " . mysqli_error($db));
  }
  $result = mysqli_query($db, $data_sql);
  if (!$result) {
    die("ERROR: " . mysqli_error($db));
  }

  // user table
  $recreate_users = file_get_contents('../sql/users.sql');
  $result = mysqli_multi_query($db, $recreate_users);
  if (!$result) {
    die("ERROR: " . mysqli_error($db));
  }
  mysqli_close($db);
  header('Location: ../index.php');
?>