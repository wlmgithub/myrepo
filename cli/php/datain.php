<?php
/********************************************
*
* lwang: The purpose of this script is to update dbs: 
*          app_name
*          host_name
*          manifest
*
*        when manifest file is changed
*
/*******************************************/
#echo 'hello ... doing data input';

$dbhost = 'localhost';
$db = 'roller';
$user = '';
$pwd = '';

/*******************************************/
$progname = __FILE__;

$opts = getopt("e:");

if ( $opts["e"] == ""  ) {
  echo "\n";
  echo  "usage: $progname  -e <env>\n";
  echo "    e.g., $progname  -e stg \n";
  echo "\n";
  exit;
}

$envname = $opts["e"];
$lc_envname = strtolower($envname);

// get ITOPS_HOME
$itops_home = getenv('ITOPS_HOME');

$manif_dir = "$itops_home" . "/" . "manif";
$filename_manifest = "$manif_dir/manifest_$lc_envname";


$link = mysql_connect($dbhost, $user, $pwd) or die('Could not connect: ' . mysql_error() );
echo "Connected successfully\n";

if (! mysql_select_db($db, $link) ) {
  echo 'Could not select database: $db';
  exit;
}; 


//
// function get_apps_array
//
function get_apps_array( $filename ) {
   
  $apps_string_non_trimmed = `cat $filename | cut -f1`;
  
  $apps_string = trim($apps_string_non_trimmed);
  
  #===== $apps_array stores the array of apps
  $apps_array = split("\n", $apps_string);

  return $apps_array;
}

//
// function  get_hosts_array
//
function get_hosts_array(  $filename ) {

  #===== get a list of hosts
  $hosts_string_non_trimmed = `cat $filename | cut -f2`;
  
  $hosts_string = trim($hosts_string_non_trimmed);
  
  $hosts_array_raw = split("\n", $hosts_string);
  
  #print_r($hosts_array_raw);
  
  $hosts_array = array();
  
  foreach ($hosts_array_raw as $str) {
    if ( preg_match("/\s+/", $str) ) {
      $tmp_array = split(" ",$str);
      foreach (  $tmp_array as $a ) {
        array_push($hosts_array, $a);
      }
    } 
    else {
      array_push($hosts_array, $str);
    }
  }

  sort ($hosts_array);

  return $hosts_array;
  
}

//
// function get_app_hosts_hash
//
function get_app_hosts_hash( $filename ) {

  $fp = fopen("$filename", "r");
  
  while ( ! feof($fp) ) {
    $line = fgets($fp);
//    echo $line;
    if ( preg_match( "/^(.*)\t(.*)/ ", $line, $matches  ) ) {
      $app = $matches[1];
      $hosts_string = $matches[2];
//      echo "match 1: " . $app . "\t";
//      echo "match 2: " . $hosts_string . "\n";
      
#      $hosts_array = split(" ", $hosts_string);
      $hosts_array = preg_split("/\s+/", trim($hosts_string) );
      $app_hosts_hash[$app] = $hosts_array;

    }
  }
  
  fclose($fp);
  
  return $app_hosts_hash;;
}



/********************
$apps_array = get_apps_array( $filename_manifest );
echo "\napps_array:\n";
print_r($apps_array);


$hosts_array = get_hosts_array( $filename_manifest );
$hosts_array_uniq = array_unique($hosts_array);
echo "\nhosts_array_uniq:\n";
print_r($hosts_array_uniq);
*********************/

// 
$app_hosts_hash = get_app_hosts_hash( $filename_manifest );
#print_r($app_hosts_hash);

$apps_all = array_keys($app_hosts_hash);

$hosts_all = array();
foreach ( $app_hosts_hash as $app => $hosts ) {
  foreach ( $hosts as $h ) {
    array_push( $hosts_all,  $h );
  }
}

/***** for debugging

echo "apps_all:\n";
print_r( $apps_all ) ;
echo "hosts_all:\n";
print_r( $hosts_all);

********/

//
// dealing with table apps
// if an app in manifest exists in table, say "already in db"
// if it's not in db, insert it in table
//
foreach ( $apps_all as $app ) {
  
  $result = mysql_query("SELECT app_name  FROM app_name where app_name = '$app' ");

  // something wrong querying db
  if (!$result) {
    echo "DB Error, could not query the database: $db\n";
    echo 'MySQL Error: ' . mysql_error();
    exit;
  }

//  echo "Doing app: $app\n";

  // otherwise, query the db, and see if app is in the db
  $row = mysql_fetch_assoc($result);
//  echo "=====".$row['appname'] . "=====\n";
  // already in db
  if ( $row['app_name'] == "$app" ) {
    echo "$app already in db\n";
  } 
  // insert into db
  else {
    // inserting...
    $sql = "INSERT INTO app_name(app_name) VALUES('$app')";
    if (! mysql_query($sql, $link) ) {
      die ("Error inserting $app into $db" . mysql_error());
    }
    echo "successfully inserted  $app into db.\n";
  } 

  mysql_free_result($result);

}

//
// dealing with table hosts
// if a host in manifest exists in table, say "already in db"
// if it's not in db, insert it in table
//
foreach ( $hosts_all  as $host ) {
  
  $result = mysql_query("SELECT host_name  FROM host_name  where host_name = '$host' ");

  if (!$result) {
    echo "DB Error, could not query the database: $db\n";
    echo 'MySQL Error: ' . mysql_error();
    exit;
  }

  $row = mysql_fetch_assoc($result);

  if ( $row['host_name'] == "$host" ) {
    echo "$host already in db\n";
  } 
  // insert into db
  else {
    // inserting...
    $sql = "INSERT INTO host_name(host_name) VALUES('$host')";
    if (! mysql_query($sql, $link) ) {
      die ("Error inserting $host into $db" . mysql_error());
    }
    echo "successfully inserted  $host into db.\n";
  }

  mysql_free_result($result);

}

//
// dealing with table apphosts
// if an app and a host in manifest exists in table, say "already in db"
// if not  insert into table
//
foreach ( $app_hosts_hash  as $app => $hosts_of_app ) {
  
  foreach ( $hosts_of_app as $host ) {

    $result = mysql_query("SELECT manif_app_id, manif_host_id  FROM manifest  where manif_app_id  = (  SELECT app_name_id FROM app_name WHERE app_name = '$app' ) and manif_host_id = ( SELECT host_name_id FROM host_name WHERE host_name = '$host'  )  ");
  
    if (!$result) {
      echo "DB Error, could not query the database: $db\n";
      echo 'MySQL Error: ' . mysql_error();
      exit;
    }
  
    
    $row = mysql_fetch_assoc($result);
  
  //  echo "rrrrr:".$row['app_id']." ".$row['host_id']."\n";
  
    if ( $row['manif_app_id'] != '' && $row['manif_host_id'] != ''  ) {
      echo "$app and $host already in db\n";
    } 
    // insert into db
    else {
      // find the appid and hostid
  
      $res = mysql_query("SELECT app_name_id  FROM app_name  where app_name = '$app' ");
      $r = mysql_fetch_assoc($res);
      $appid = $r['app_name_id'];
      
      $res = mysql_query("SELECT host_name_id  FROM host_name  where host_name = '$host' ");
      $r = mysql_fetch_assoc($res);
      $hostid = $r['host_name_id'];
      
      // inserting...
      $sql = "INSERT INTO manifest(manif_app_id, manif_host_id) VALUES($appid, $hostid) ";
      if (! mysql_query($sql, $link) ) {
        die ("Error inserting $app and $host into $db" . mysql_error());
      }
      echo "successfully inserted  $app and $host into db.\n";
    }
  
    mysql_free_result($result);

  }

}

###############
exit;
?>
