<?php

function setup()
{
  if (session_status() == PHP_SESSION_NONE) {
    session_start();
  }
  if (!isset($_SESSION['user_id'])) return false;
  require_once('connectdb.php');
  return true;
}

function current_user()
{
  if (!setup()) return false;
  $user_id = $_SESSION['user_id'];
  // don't do it like that in productive systems
  // session variables can be changed and thus sql
  // injection is possible here aswell!
  $query = "SELECT * from users WHERE id=$user_id";
  $db = connectdb();
  $result = mysqli_multi_query($db, $query);
  if ($result) {
    $result = mysqli_use_result($db);
  }
  if ($result) {
    $user = mysqli_fetch_array($result, MYSQLI_ASSOC);
    mysqli_close($db);
    return $user;
  }
  mysqli_close($db);
  return false;
}

function logged_in()
{
  return setup();
}

function is_admin()
{
  if (!setup()) return false;
  $user_id = $_SESSION['user_id'];
  // don't do it like that in productive systems
  // session variables can be changed and thus sql
  // injection is possible here aswell!
  $query = "SELECT * from users WHERE id=$user_id";
  $db = connectdb();
  $result = mysqli_multi_query($db, $query);
  if ($result) {
    $result = mysqli_use_result($db);
  }
  if ($result) {
    $user = mysqli_fetch_array($result, MYSQLI_ASSOC);
    mysqli_close($db);
    return $user['role'] == 'admin';
  }
  mysqli_close($db);
  return false;
}
