<!DOCTYPE html>
<html>

<head>
  <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.2.1/css/bootstrap.min.css" integrity="sha384-GJzZqFGwb1QTTN6wy59ffF1BuGJpLSa9DkKMp0DgiMDm4iYMj70gZWKYbI706tWS" crossorigin="anonymous">
</head>

<body>
  <?php
  session_start();
  require_once('lib/helpers.php');
  $filter = array_key_exists('blend', $_GET) ? $_GET['blend'] : '';
  ?>
  <nav class="navbar navbar-dark bg-dark justify-content-end">
    <?php
    if (isset($_SESSION['cart_items'])) {
      ?>
      <form class="form-inline mr-3" action="" method="get">
        <button class="btn btn-primary btn-sm"><?php echo (count($_SESSION['cart_items'])); ?>🛒</button>
      </form>
    <?php
  }
  if (logged_in()) {
    $user = current_user();
    ?>
      <form class="form-inline mr-0" action="lib/logout.php" method="post">
        <h5 class="mr-2 mt-1"><span class="badge badge-primary"><?php echo ($user['name']); ?></span></h5>
        <button class="btn btn-outline-success my-2 btn-sm my-sm-0" type="submit">Logout</button>
      </form>
    <?php
  } else {
    ?>
      <form class="form-inline" action="lib/login.php" method="post">
        <input class="form-control mr-sm-2" type="text" placeholder="Username" name="username">
        <input class="form-control mr-sm-2" type="password" placeholder="Password" name="password">
        <button class="btn btn-outline-success my-2 my-sm-0" type="submit">Login</button>
      </form>
    <?php
  }
  ?>
  </nav>
  <?php
  if (isset($_SESSION['login_error'])) {
    unset($_SESSION['login_error']);
    ?>
    <div class="alert alert-danger" role="alert">
      Login Failed. Your Username or Password may be wrong.
    </div>
  <?php
}
?>
  <h1>Onlineshop CoffeeShop</h1>
  <form action="index.php" method="get">
    <div class="form-group">
      <label for="blendFilter">Blend Name</label>
      <input type="text" class="form-control" id="blendFilter" name="blend" placeholder="Filter Blend Names" value=<?php echo ('"' . $filter . '"'); ?>>
    </div>
    <button type="submit" class="btn btn-primary">Filter</button>
  </form>
  <?php
  require_once('lib/show_table.php');
  show_table($filter);
  ?>
  <form action="lib/recreate_and_seed_db.php" method="post">
    <button type="submit" class="btn btn-danger btn-sm">Recreate Table</button>
  </form>
</body>

</html>
