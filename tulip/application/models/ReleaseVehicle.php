<?php
require_once( 'foobar/Database.php' );
require_once( 'foobar/Database/Tables/ReleaseVehicle.php' );
require_once( 'foobar/Database/Exception.php' );

class Model_ReleaseVehicle
{
	public static function getData($releaseVehicleId)
	{
		$db = foobar_Database::getConnection();
		$releaseVehicle = new ReleaseVehicle(array('db' =>$db));
		
		try {
			$row = $releaseVehicle->fetchRow($releaseVehicle->select()->where('release_vehicle_id = ?', $releaseVehicleId));
		} catch (foobar_Data_Exception $e) {
			echo $e->getMessage('Database issue!!');
		}
		return $row;
	}
	public static function getAllData()
	{
		$db = foobar_Database::getConnection();
		$releaseVehicle = new ReleaseVehicle(array('db' =>$db));
		
		try {
			$all = $releaseVehicle->fetchAll($releaseVehicle->select()->order('created DESC'));
		} catch (foobar_Data_Exception $e) {
			echo $e->getMessage('Database issue!!');
		}
		return $all;
	}
	public static function insertReleaseVehicle( $dataArray )
	{
		$db = foobar_Database::getConnection();
		
		$releaseVehicle = new ReleaseVehicle(array('db' =>$db));
		
		try {
			$releaseVehicle->insert( $dataArray );	
		} catch (foobar_Data_Exception $e) {
			echo $e->getMessage('Database issue!!');
		}
		return $db->lastInsertId();
	}
	public static function getIdList($keyword)
	{
		$db = foobar_Database::getConnection();
		$releaseVehicle = new ReleaseVehicle(array('db' =>$db));
		
		try {
			$all;
			$condition = $keyword . "%";
			if ($keyword) {
#				$all = $releaseVehicle->fetchAll($releaseVehicle->select()->where('release_vehicle_id  LIKE ?', $condition)->order('release_vehicle_id'));
				$all = $releaseVehicle->fetchAll($releaseVehicle->select()->where('release_vehicle_id  LIKE ?', $condition));
			}
		} catch (foobar_Data_Exception $e) {
			echo $e->getMessage('Database issue!!');
		}
		return $all;
	}
	public static function editReleaseVehicle($data)
	{
		$db = foobar_Database::getConnection();
		$releaseVehicle = new ReleaseVehicle(array('db' =>$db));
		$where = $releaseVehicle->getAdapter()->quoteInto('release_vehicle_id = ?', $data['release_vehicle_id']);
		$releaseVehicle->update($data, $where);
	}
	
	public static function deleteReleaseVehicle($release_vehicle_id)
	{
		$db = foobar_Database::getConnection();
		
		$releaseVehicle = new ReleaseVehicle(array('db' =>$db));
		try {
			$releaseVehicle->getAdapter()->query("delete from release_vehicle WHERE release_vehicle_id=" . $release_vehicle_id);  
		} catch (foobar_Data_Exception $e) {
			echo $e->getMessage('Database issue!!');
		}
		return 1;
	}
	public static function getCount()
	{
		$db = foobar_Database::getConnection();
		try {
			$count = $db->fetchOne("select count(*) from release_vehicle"); 
		} catch (foobar_Data_Exception $e) {
			echo $e->getMessage('Database issue!!');
		}
		return $count + 1;
	}
        public static function getPlanCreator($release_vehicle_id)
        {
                $db = foobar_Database::getConnection();
		$releaseVehicle = new ReleaseVehicle(array('db' =>$db));
                try {
                        $username = $releaseVehicle->fetchOne("select username from release_vehicle WHERE release_vehicle_id=" . $release_vehicle_id);
                } catch (foobar_Data_Exception $e) {
                        echo $e->getMessage('Database issue!!');
                }
                return $username;
        }
	public static function updateStatus($data)
	{
		$db = foobar_Database::getConnection();
		$releaseVehicle = new ReleaseVehicle(array('db' =>$db));
		$where = $releaseVehicle->getAdapter()->quoteInto('release_vehicle_id = ?', $data['release_vehicle_id']);
		$releaseVehicle->update($data, $where);
	}
}

