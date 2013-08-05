<?php
require_once('models/Plan.php');
class Zend_View_Helper_Audit
{
	public function setView(Zend_View_Interface $view)
	{
		$this->view = $view;
	}

/*
	public function audit() 
	{
		$html = "";

		$html .= "<h1>hihi</h1>";  	
		return $html;
	}
*/

}


/*

                                $listhtml .= "<tr><td>".$plan[$i][step] . "</td><td>" . $plan[$i][sub_step] . "</td><td>" . $plan[$i][task] . "<br/>" . $plan[$i][components] . "</td><td>" . $plan[$i][
owner] . "</td><td>" . $html . $another_form . $audit_form . "</td></tr>";

*/

?>
