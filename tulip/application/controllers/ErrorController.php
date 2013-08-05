<?php
require_once('Zend/Controller/Action.php');
require_once('Zend/Registry.php');

class ErrorController extends Zend_Controller_Action 
{
	public function errorAction()
    {
        $errors = $this->_getParam('error_handler');
		$exception = $errors->exception;
		$errormsg = $exception->getMessage();
		$content = "";
        switch ($errors->type) {
            case Zend_Controller_Plugin_ErrorHandler::EXCEPTION_NO_CONTROLLER:
            case Zend_Controller_Plugin_ErrorHandler::EXCEPTION_NO_ACTION:
                // 404 error -- controller or action not found
                $this->getResponse()->setRawHeader('HTTP/1.1 404 Not Found');
				$content = "Page Not Found... Go Away";
                // ... get some output to display...
                break;
            default:
                // application error; display error page, but don't change
                // status code
                $content  = "Unexpected... I don't know what is going on";
               
                break;
        }
        $content .= $errormsg;
        $this->getResponse()->clearBody();
        $this->view->content = $content;
    }
    
}