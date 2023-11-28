<?php  
  session_start();
  require_once('helpers.php');
  if (!logged_in()) {
    header('Location: ../index.php');
    exit;
  }
  $id = $_POST['id'];
  if (!isset($_SESSION['cart_items'])) {
    $_SESSION['cart_items'] = array();
  }
  array_push($_SESSION['cart_items'], $id);
  header('Location: ../index.php');
?>