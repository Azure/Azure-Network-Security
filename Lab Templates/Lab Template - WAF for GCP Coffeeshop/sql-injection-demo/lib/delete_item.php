<?php
  require_once('connectdb.php');
  if (isset($_POST['id'])) {
    $id = $_POST['id'];
    // vulnerable...
    $query = "DELETE FROM coffee WHERE id=$id";
    $db = connectdb();
    mysqli_multi_query($db, $query);
    mysqli_close($db);
  }
  header('Location: ../index.php');
?>