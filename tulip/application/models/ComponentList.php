<?php
require_once( 'foobar/Database.php' );
require_once( 'foobar/Database/Tables/Componentlist.php' );
require_once( 'foobar/Database/Exception.php' );

class Model_ComponentList
{
	public static function getData($releaseVehicleId)
	{
		$db = foobar_Database::getConnection();
		$componentList = new ComponentList(array('db' =>$db));
		
		try {
			$all = $componentList->fetchAll($componentList->select()->where('release_vehicle_id = ?', $releaseVehicleId));
		} catch (foobar_Data_Exception $e) {
			echo $e->getMessage('Database issue!!');
		}
		return $all;
	}
	public static function insertComponentList( $componentArray )
	{
		$db = foobar_Database::getConnection();
		
		$componentList = new ComponentList(array('db' =>$db));
		
		try {
			$componentList->insert( $componentArray );	
		} catch (foobar_Data_Exception $e) {
			echo $e->getMessage('Database issue!!');
		}
		return $db->lastInsertId();
	}
	public static function deleteComponentList($release_vehicle_id)
	{
		$db = foobar_Database::getConnection();
		
		$componentList = new ComponentList(array('db' =>$db));
		
		try {
			$componentList->getAdapter()->query("delete from component_list WHERE release_vehicle_id='" . $release_vehicle_id ."'");  
		} catch (foobar_Data_Exception $e) {
			echo $e->getMessage('Database issue!!');
		}
		return 1;
	}

        public static function getCount($release_vehicle_id)
        {
                $db = foobar_Database::getConnection();
                try {
                        $count = $db->fetchOne("select count(*) from component_list WHERE release_vehicle_id='" . $release_vehicle_id ."'"); 
                } catch (foobar_Data_Exception $e) {
                        echo $e->getMessage('Database issue!!');
                }
                return $count;
        }
}

