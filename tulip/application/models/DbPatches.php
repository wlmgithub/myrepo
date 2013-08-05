<?php
require_once( 'foobar/Database.php' );
require_once( 'foobar/Database/Tables/Dbpatches.php' );
require_once( 'foobar/Database/Exception.php' );

class Model_DbPatches
{
	public static function getData($releaseVehicleId)
	{
		$db = foobar_Database::getConnection();
		$dbpatches = new DbPatches(array('db' =>$db));
		
		try {
			$all = $dbpatches->fetchAll($dbpatches->select()->where('release_vehicle_id = ?', $releaseVehicleId));
		} catch (foobar_Data_Exception $e) {
			echo $e->getMessage('Database issue!!');
		}
		return $all;
	}
	public static function insertDbPatches( $dbArray )
	{
		$db = foobar_Database::getConnection();
		
		$dbpatches = new DbPatches(array('db' =>$db));
		
		try {
			$dbpatches->insert( $dbArray );	
		} catch (foobar_Data_Exception $e) {
			echo $e->getMessage('Database issue!!');
		}
		return $db->lastInsertId();
	}
	public static function deleteDbPatches($release_vehicle_id)
	{
		$db = foobar_Database::getConnection();
		
		$dbpatches = new DbPatches(array('db' =>$db));
		
		try {
			$dbpatches->getAdapter()->query("delete from db_patches WHERE release_vehicle_id='". $release_vehicle_id . "'");  
		} catch (foobar_Data_Exception $e) {
			echo $e->getMessage('Database issue!!');
		}
		return 1;
	}
}

