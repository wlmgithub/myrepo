<?php
require_once( 'foobar/Database.php' );
require_once( 'foobar/Database/Tables/Type.php' );
require_once( 'foobar/Database/Exception.php' );

class Model_Type
{
	public static function getData()
	{
		$db = foobar_Database::getConnection();
		$type = new Type(array('db' =>$db,));
		
		try {
			$all = $type->fetchAll($type->select());
		} catch (foobar_Data_Exception $e) {
			echo $e->getMessage('Database issue!!');
		}
		return $all;
	}
	
}

