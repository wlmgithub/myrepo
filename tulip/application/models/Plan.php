<?php
require_once( 'foobar/Database.php' );
require_once( 'foobar/Database/Tables/Plan.php' );
require_once( 'foobar/Database/Exception.php' );

class Model_Plan
{
	public static function getDataInArray($releaseVehicleId)
	{
		$db = foobar_Database::getConnection();
		$plan = new Plan(array('db' =>$db));
		
		try {
			$all = $plan->fetchAll($plan->select()->where('release_vehicle_id = ?', $releaseVehicleId));
		} catch (foobar_Data_Exception $e) {
			echo $e->getMessage('Database issue!!');
		}
		return $all->toArray();
	}
	public static function getData($releaseVehicleId)
	{
		$db = foobar_Database::getConnection();
		$plan = new Plan(array('db' =>$db));
		
		try {
			$all = $plan->fetchAll($plan->select()->where('release_vehicle_id = ?', $releaseVehicleId));
		} catch (foobar_Data_Exception $e) {
			echo $e->getMessage('Database issue!!');
		}
		return $all;
	}
	public static function insertPlanList( $planArray )
	{
		$db = foobar_Database::getConnection();
		
		$plan = new Plan(array('db' =>$db));
		
		try {
			$plan->insert( $planArray );	
		} catch (foobar_Data_Exception $e) {
			echo $e->getMessage('Database issue!!');
		}
		return $db->lastInsertId();
	}
	public static function deletePlanList($release_vehicle_id)
	{
		$db = foobar_Database::getConnection();
		$plan = new Plan(array('db' =>$db));
		try {
			$plan->getAdapter()->query("delete from rollout_plan WHERE release_vehicle_id='" . $release_vehicle_id ."'");  
		} catch (foobar_Data_Exception $e) {
			echo $e->getMessage('Database issue!!');
		}
		return 1;
	}
	public static function updateStatus($data)
	{
		$db = foobar_Database::getConnection();
		$plan = new Plan(array('db' =>$db));
		$where = $plan->getAdapter()->quoteInto('id = ?', $data['id']);
		$plan->update($data, $where);
	}
}




//
