
  <?php
  session_start();

  $_SESSION = array();

  // also force session in cookie to expire
  if (isset($_COOKIE[session_name()]))
  {
    $cookie_expires  = time() - date('Z') - 3600;
    setcookie(session_name(), '', $cookie_expires, '/');
  }
  session_destroy();
  header('Location: ../index.php');  
  ?>
