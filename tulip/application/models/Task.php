<?php
require_once( 'foobar/Database.php' );
require_once( 'foobar/Database/Tables/Task.php' );
require_once( 'foobar/Database/Exception.php' );

class Model_Task
{
	public static function getData()
	{
		$db = foobar_Database::getConnection();
		$task = new Task(array('db' =>$db,));
		
		try {
			$all = $task->fetchAll($task->select());
		} catch (foobar_Data_Exception $e) {
			echo $e->getMessage('Database issue!!');
		}
		return $all;
	}
	public static function getBackend($task_name)
	{
		$db = foobar_Database::getConnection();
		$task = new Task(array('db' =>$db,));
		
		try {
			$all = $task->fetchRow($task->select()->where('task = ?', $task_name));
		} catch (foobar_Data_Exception $e) {
			echo $e->getMessage('Database issue!!');
		}
		return $all;
	}
}

