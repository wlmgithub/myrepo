<?php
require_once( 'Zend/Registry.php' );
require_once( 'Zend/Session.php' );
require_once('Zend/Controller/Action.php');
require_once('Zend/Config/Ini.php');
class LogoutController extends Zend_Controller_Action 
{
	public function indexAction()
	{
		//Set view renderer to nothing here,
		$this->_helper->viewRenderer->setNoRender(true);

		//clear session
		Zend_Registry::get( 'foobarSession' )->user = '';
		Zend_Registry::get( 'foobarSession' )->isLoggedIn = false;

		$url = Zend_Registry::get('foobarconfig')->url->web."/index";
		$this->_redirect($url);	
	}
}