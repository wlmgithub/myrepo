<?php
require_once( 'foobar/Database.php' );
require_once( 'foobar/Database/Tables/User.php' );
require_once( 'foobar/Database/Exception.php' );

class Model_User
{
	public static function getData()
	{
		$db = foobar_Database::getConnection();
		$user = new User(array('db' =>$db,));
		
		try {
			$all = $user->fetchAll($user->select());
		} catch (foobar_Data_Exception $e) {
			echo $e->getMessage('Database issue!!');
		}
		return $all;
	}
	
}

