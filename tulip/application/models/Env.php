<?php
require_once( 'foobar/Database.php' );
require_once( 'foobar/Database/Tables/Env.php' );
require_once( 'foobar/Database/Exception.php' );

class Model_Env
{
	public static function getData()
	{
		$db = foobar_Database::getConnection();
		$env = new Env(array('db' =>$db,));
		
		try {
			$all = $env->fetchAll($env->select());
		} catch (foobar_Data_Exception $e) {
			echo $e->getMessage('Database issue!!');
		}
		return $all;
	}
	
}

