<?php
require_once( 'Zend/Db/Table/Abstract.php' );

class Env extends Zend_Db_Table_Abstract
{
    protected   $_name = 'env_name';
}