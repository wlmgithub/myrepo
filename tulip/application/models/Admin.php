<?php
require_once( 'foobar/Database.php' );
require_once( 'foobar/Database/Tables/Admin.php' );
require_once( 'foobar/Database/Exception.php' );

class Model_Admin
{
	public static function getData()
	{
		$db = foobar_Database::getConnection();
		$admin = new Admin(array('db' =>$db,));
		
		try {
			$all = $admin->fetchAll($admin->select());
		} catch (foobar_Data_Exception $e) {
			echo $e->getMessage('Database issue!!');
		}
		return $all;
	}
	
}

