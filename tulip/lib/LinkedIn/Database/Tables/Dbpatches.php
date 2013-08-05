<?php
require_once( 'Zend/Db/Table/Abstract.php' );

class DbPatches extends Zend_Db_Table_Abstract
{
    protected   $_name = 'db_patches';
}