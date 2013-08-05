<?php

require_once( 'Zend/Log.php' );
require_once( 'Zend/Registry.php' );
require_once( 'Zend/Log/Writer/Stream.php' );
require_once( 'foobar/Log/Exception.php' );

/**
 * foobar_Log
 *
 * Logs all messages to a log file
 * path to log file defined in configs
 *
 */
class foobar_Log extends Zend_Log
{

	private static $loggerinstance;

	private static $lnlog;


	public static function getInstance()
	{
		if (foobar_Log::$loggerinstance === NULL)
		{
			foobar_Log::$loggerinstance = new foobar_Log();
			if (isset(Zend_Registry::get( 'foobarconfig' )->log->path)) {
				$logFile = Zend_Registry::get( 'foobarconfig' )->log->path . '/' . date( 'Ymd') . '_' . Zend_Registry::get( 'foobarconfig' )->log->file;
				$writer = new Zend_Log_Writer_Stream($logFile);
				self::$lnlog = new Zend_Log( $writer );
			}
			
		}
return true;
		//return foobar_Log::$loggerinstance;
	}


	/**
	 * Logs messages to log file
	 *
	 * @param string $message
	 * @param string $level
	 */
	public function writeLog($message, $level = Zend_Log::INFO)
	{
		self::$lnlog->log($message, $level);
	}

	public function __construct()
	{
	}
}