<?php
//dev settings
//ini_set('include_path',ini_get('include_path').'.:/usr/local/ZendFramework:/usr/local/Deployment/config:/usr/local/Deployment/lib:/usr/local/Deployment/application:/usr/local/Zend/Core/share/pear');

//staging settings
//ini_set('include_path',ini_get('include_path').':.:/usr/local/ZendFramework:/usr/local/Deployment-dev/config:/usr/local/Deployment-dev/lib:/usr/local/Deployment-dev/application');

//production  settings
ini_set('include_path',ini_get('include_path').':.:/usr/local/ZendFramework:/usr/local/Deployment/config:/usr/local/Deployment/lib:/usr/local/Deployment/application');

require_once('Zend/Controller/Plugin/ErrorHandler.php');
require_once('Zend/Config/Ini.php');
require_once('Zend/Registry.php');
require_once('Zend/Controller/Front.php');
require_once('Zend/Session.php');
require_once('foobar/AccountPlugin.php');

$config = new Zend_Config_Ini('foobar.ini','production');


error_reporting($config->error);
//push config to Registry
Zend_Registry::set('foobarconfig', $config);


$sessionConfig = new Zend_Config_Ini('foobar_session.ini','production');





Zend_Session::setOptions($sessionConfig->toArray());
Zend_Session::start();
$session = new Zend_Session_Namespace('foobar');
Zend_Registry::set('foobarSession', $session);

//instantiate the front controller
$front = Zend_Controller_Front::getInstance();

//register error handler



//get config from Registry
$appPath = Zend_Registry::get('foobarconfig')->application->path;
//$appPath = $config->application->path;

$front->setControllerDirectory(array('default' => $appPath . '/application/controllers'));

$front->registerPlugin(new Zend_Controller_Plugin_ErrorHandler());
$front->registerPlugin(new AccountPlugin());

$front->dispatch();
