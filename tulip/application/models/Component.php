<?php
require_once( 'foobar/Database.php' );
require_once( 'foobar/Database/Tables/Env.php' );
require_once( 'foobar/Database/Tables/Component.php' );
require_once( 'foobar/Database/Exception.php' );

class Model_Component
{
	public static function getData()
	{
		$db = foobar_Database::getConnection();
		$component = new Component(array('db' =>$db,));
		
		try {
			$all = $component->fetchAll($component->select());
		} catch (foobar_Data_Exception $e) {
			echo $e->getMessage('Database issue!!');
		}
		return $all;
	}
	
}

