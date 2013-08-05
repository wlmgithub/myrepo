<?php
require_once( 'Zend/Db/Table/Abstract.php' );

class User extends Zend_Db_Table_Abstract
{
    protected   $_name = 'user';
}