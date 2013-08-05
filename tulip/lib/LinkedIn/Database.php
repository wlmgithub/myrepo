<?php
/**
 * foobar Database connection class
 */
require_once( 'Zend/Registry.php' );
require_once( 'Zend/Db/Adapter/Mysqli.php' );
require_once( 'Zend/Debug.php' );
require_once( 'foobar/Database/Exception.php' );
require_once( 'foobar/Log.php' );

class foobar_Database
{

	/**
	 * Singleton
	 *
	 * @var mixed
	 */
	private static $dbConnection;

	/**
	 * We make sure that only one instance of the database is passed around
	 *
	 * @return mixed
	 */

	public static function getConnection()
	{
		if (foobar_Database::$dbConnection === NULL) {


			try {
				$dbhost = Zend_Registry::get('foobarconfig')->database->host;
				$dbname = Zend_Registry::get('foobarconfig')->database->name;
				$dbuser = Zend_Registry::get('foobarconfig')->database->user;
				$dbpass = Zend_Registry::get('foobarconfig')->database->pass;
				$dbParams = array(
            	'host' => $dbhost,
               'dbname' => $dbname,
               'username' => $dbuser,
               'password' => $dbpass,
            );

				foobar_Database::$dbConnection = new Zend_Db_Adapter_Mysqli($dbParams);

			} catch (Zend_Db_Adapter_Exception $e) {
				// perhaps a failed login credential, or perhaps the RDBMS is not
				foobar_Log::getInstance()->writeLog($e->getMessage(), Zend_Log::ERR );
				//throw new foobar_Data_Exception();
				//echo $e->getMessage();


			} catch (Zend_Exception $e) {
				// perhaps factory() failed to load the specified Adapter class
				foobar_Log::getInstance()->writeLog($e->getMessage(), Zend_Log::ERR );
				//throw new foobar_Data_Exception();
				//echo $e->getMessage();

			}
		}

		return foobar_Database::$dbConnection;
	}
}