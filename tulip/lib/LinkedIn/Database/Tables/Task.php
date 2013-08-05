<?php
require_once( 'Zend/Db/Table/Abstract.php' );

class Task extends Zend_Db_Table_Abstract
{
    protected   $_name = 'task';
}