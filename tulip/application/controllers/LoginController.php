<?php
require_once('Zend/Controller/Action.php');
require_once('Zend/Registry.php');
require_once ('Zend/Ldap.php');
require_once('Zend/Config/Ini.php');
require_once ('Zend/Debug.php');


class LoginController extends Zend_Controller_Action 
{
	public function indexAction()
	{
		$this->view->urlHome = Zend_Registry::get('foobarconfig')->url->web;
		$this->view->urlHttps = Zend_Registry::get('foobarconfig')->url->https;
		$this->_flashMessenger = $this->_helper->getHelper('FlashMessenger');
        $msg = $this->_flashMessenger->getMessages(); 
        $this->view->message = $msg[0];
	}
	public function resultAction()
	{
		$this->view->urlHome = Zend_Registry::get('foobarconfig')->url->web;
		$this->_helper->viewRenderer->setNoRender();
		$request = $this->getRequest();
		$message;
		if ($request->getPost('form_submitted') == 1) {
			$username = $request->getPost('username');
			$password = $request->getPost('password');
			if (!$username || !$password) {
				$url = Zend_Registry::get('foobarconfig')->url->web."/login";
				$message = "The username and password are incorrect.";
				$this->_helper->flashMessenger->addMessage($message);
				 
			}
			$hostname = Zend_Registry::get('foobarconfig')->hostname;
			$username = $username . "@foobar.biz";
			$host = "$hostname"."://oslo.foobar.biz";
			$ad = ldap_connect($host);
			if (!$ad){
				$url = Zend_Registry::get('foobarconfig')->url->web."/login";
				$message = "We couldn't authenticate your username and password currently. Please try again later.";
				$this->_helper->flashMessenger->addMessage($message);
			}
			// Set version number
			#ldap_set_option($ad, LDAP_OPT_PROTOCOL_VERSION, 3)
			#     or die ("Could not set ldap protocol");
			     
			#ldap_set_option($ad, LDAP_OPT_REFERRALS, 0);      
			
			// Binding to ldap server
			$bd = ldap_bind($ad, $username, $password);
			if ($bd) {
				Zend_Registry::get( 'foobarSession' )->user = $request->getPost('username');
				Zend_Registry::get( 'foobarSession' )->isLoggedIn = true;
				$url = Zend_Registry::get('foobarconfig')->url->web."/index";
				//$message = "success";
			}else {
				$url = Zend_Registry::get('foobarconfig')->url->web."/login";
				$message = "The username and password are incorrect.";
				$this->_helper->flashMessenger->addMessage($message);

			}
			
			$this->_redirect($url);	
			ldap_unbind($ad);
		}
	}
}
		