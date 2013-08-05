<?php
require_once( 'foobar/Database.php' );
require_once( 'foobar/Database/Tables/Workflow.php' );
require_once( 'foobar/Database/Exception.php' );

class Model_Workflow
{
	public static function getDataInArray($releasename, $stepname)
	{
		$db = foobar_Database::getConnection();
		$workflow = new Workflow(array('db' =>$db));
		
		try {
			$all = $workflow->fetchAll($workflow->select()->where('releasename = ?', $releasename)->where('stepname = ?', $stepname));
		} catch (foobar_Data_Exception $e) {
			echo $e->getMessage('Database issue!!');
		}
		return $all->toArray();
	}

	public static function getData($releasename)
	{
		$db = foobar_Database::getConnection();
		$workflow = new Workflow(array('db' =>$db));
		
		try {
			$all = $workflow->fetchAll($workflow->select()->where('releasename = ?', $releasename));
		} catch (foobar_Data_Exception $e) {
			echo $e->getMessage('Database issue!!');
		}
		return $all;
	}

	public static function getAllData()
	{
		$db = foobar_Database::getConnection();
		$workflow = new Workflow(array('db' => $db));

		try {
			$all = $workflow->fetchAll($workflow->select()->order("releasename DESC")->order("stepname DESC")->limit(7));
		} catch (foobar_Data_Exception $e) {
			echo $e->getMessage('Database issue!!');
		}
		
		return $all;
	}

        public static function insertWorkflow( $dataArray )
        {
                $db = foobar_Database::getConnection();
                $workflow = new Workflow(array('db' =>$db));

                try {
                        $workflow->insert( $dataArray );
                } catch (foobar_Data_Exception $e) {
                        echo $e->getMessage('Database issue!!');
                }
                return $db->lastInsertId();
        }

        public static function updateWorkflow( $data )
        {
                $db = foobar_Database::getConnection();
                $workflow = new Workflow(array('db' =>$db));

#                $where = $workflow->getAdapter()->quoteInto('releasename = ?  ', $data['releasename']);
#                $where = $workflow->getAdapter()->quoteInto('releasename = ? and stepname = ? ', $data['releasename'], $data['stepname']);
#
##########################
#
# TODO: not working yet!
# see: IndexController: createworkflowAction
#
##########################
#		$where[] = "releasename = 'test2' ";
#		$where[] = "stepname = 'Step_2' ";
#                $workflow->update($db, $data, $where);

		$where[] = "releasename = " . "'" . $data['releasename'] . "'";
		$where[] = "stepname = " . "'" . $data['stepname'] . "'";
                $workflow->update($data, $where );
        }

}


//
