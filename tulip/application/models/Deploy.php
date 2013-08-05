<?php
require_once( 'foobar/Database.php' );
require_once( 'foobar/Database/Tables/Deploy.php' );
require_once( 'foobar/Database/Exception.php' );

class Model_Deploy
{
	public static function getData($releaseVehicleId, $machine, $task)
	{
		$db = foobar_Database::getConnection();
		$deploy = new Deploy(array('db' =>$db));
		
		try {
			$all = $deploy->fetchRow($deploy->select()->where('release_vehicle_id = ?', $releaseVehicleId)->where('machine = ?', $machine)->where('task = ?', $task));
		} catch (foobar_Data_Exception $e) {
			echo $e->getMessage('Database issue!!');
		}
		return $all;
	}
	public static function insertValues( $inputArray )
	{
		$db = foobar_Database::getConnection();
		
		$deploy = new Deploy(array('db' =>$db));
		
		try {
			$deploy->insert( $inputArray );	
		} catch (foobar_Data_Exception $e) {
			echo $e->getMessage('Database issue!!');
		}
		return $db->lastInsertId();
	}
}

