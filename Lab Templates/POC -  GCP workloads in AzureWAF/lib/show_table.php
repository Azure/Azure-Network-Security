<?php
function show_table($blend_name)
{
  if (session_status() == PHP_SESSION_NONE) {
    session_start();
  }
  require_once('helpers.php');
  $logged_in = logged_in();
  $admin = is_admin();
  ?>
  <table class="table border">
    <tr>
      <th>ID</th>
      <th>BlendName</th>
      <th>Origin</th>
      <th>Variety</th>
      <th>Notes</th>
      <th>Intensifier</th>
      <th>Price</th>
      <?php
      if ($logged_in) {
        echo ("<th>Shop</th>");
      }
      if ($admin) {
        echo ("<th>Löschen</th>");
      }
      ?>
    </tr>
    <?php
    require_once('connectdb.php');
    // vulnerability to sql injection
    $query = "SELECT * FROM coffee WHERE blend_name LIKE '%$blend_name%';";
    ?>
    <br>
    <div class="card">
      <div class="card-body">
        Query: <code>
          <?php
          echo ($query);
          ?>
        </code>
      </div>
    </div>
    <br>
    <h3>Kaffee</h3>
    <?php
    $db = connectdb();
    // mysqli_multi_query is required to demonstrate all possible
    // sql-injection variants. With mysqli_query only the first
    // query statement is performed to prevent sql injection...
    $result = mysqli_multi_query($db, $query);
    if ($result) {
      $result = mysqli_use_result($db);
    }
    if ($result) {
      while ($coffee = mysqli_fetch_array($result, MYSQLI_ASSOC)) {
        echo ('<tr>');
        foreach ($coffee as $attr) {
          echo ('<td>' . $attr . '</td>');
        }
        if ($logged_in) {
          $id = $coffee['id'];
          echo ("
            <td>
              <form action=\"lib/add_to_cart.php\" method=\"post\">
                <button name=\"item\" value=\"$id\" type=\"submit\" class=\"btn px-1 py-0\">
                  🛒
                </button>
              </form>
            </td>
          ");
        }
        if ($admin) {
          $id = $coffee['id'];
          echo ("
            <th>
              <form class=\"form-inline mr-3\" action=\"lib/delete_item.php\" method=\"post\">
                <button name=\"id\" value=\"$id\" type=\"submit\" class=\"btn btn-danger px-1 py-0\">
                  &times;
                </button>
              </form>
            </th>
          ");
        }
        echo ('</tr>');
      }
    } else {
      echo ('ERROR: ' . mysqli_error($db));
    }
    mysqli_close($db);
    ?>
  </table>
<?php
}
?>