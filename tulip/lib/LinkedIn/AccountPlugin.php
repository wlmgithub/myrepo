<?php
require_once('Zend/Controller/Plugin/Abstract.php');
require_once('Zend/Registry.php');

class AccountPlugin extends Zend_Controller_Plugin_Abstract {

	function preDispatch() {
		$url = Zend_Registry::get('foobarconfig')->url->web."/login";
		// Discover what action is being requested
		$action = $this->_request->getActionName();
		
		// Create a list of actions which allow unauthenticated access
		$exclusions = array("login","result");
		if(!in_array($action, $exclusions)) {
			 if (Zend_Registry::get( 'foobarSession' )->user == '' ) {
	            $this->getRequest()->setModuleName('default');
				$this->getRequest()->setControllerName("login");
				$this->getRequest()->setActionName("index");
			}
		}

	}
}
