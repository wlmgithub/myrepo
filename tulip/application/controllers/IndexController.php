<?php
require_once('Zend/Controller/Action.php');
require_once('Zend/Registry.php');
require_once('Zend/Debug.php');
require_once('models/Env.php');
require_once('models/Type.php');
require_once('models/Component.php');

require_once('models/ReleaseVehicle.php');
require_once('models/DbPatches.php');
require_once('models/ComponentList.php');
require_once('models/Plan.php');
require_once('models/Deploy.php');
require_once('models/User.php');
require_once('models/Task.php');
require_once('models/Workflow.php');

require_once('models/Admin.php');
class IndexController extends Zend_Controller_Action 
{
	public function indexAction()
	{
		$this->view->urlHome = Zend_Registry::get('foobarconfig')->url->web;
		$this->view->pageTitle = Zend_Registry::get('foobarconfig')->index->title;
		$allRollOuts = Model_ReleaseVehicle::getAllData();
		$this->view->allRollOuts = $allRollOuts;
		
		$admins = Model_Admin::getData();
		$username = Zend_Registry::get( 'foobarSession' )->user ;
		
		$adminArray = array();
		$this->view->value = 0;

		foreach ($admins as $admin)  {
			array_push($adminArray,$admin->user_name);
		}
		if (in_array($username,$adminArray)) {
				$this->view->value = 1;
		}
	
	}
	public function searchAction()
	{
		$request = $this->getRequest();
		if ($request->getParam('form_submitted') == 1) {
			$id = $request->getParam('keyword');
			$id = trim($id);
			$this->view->keyword = $id;
			$rollout = Model_ReleaseVehicle::getData($id);
			$idList = Model_ReleaseVehicle::getIdList($id);
		}
		$this->view->heading = "Search Results:";
		$this->view->pageTitle = Zend_Registry::get('foobarconfig')->application->title;
		$this->view->urlHome = Zend_Registry::get('foobarconfig')->url->web;
		$this->view->rollout = $rollout;
		$this->view->idList  = $idList;
		
		
		$admins = Model_Admin::getData();
		$username = Zend_Registry::get( 'foobarSession' )->user ;
		
		$adminArray = array();
		$this->view->value = 0;

		foreach ($admins as $admin)  {
			array_push($adminArray,$admin->user_name);
		}
		if (in_array($username,$adminArray)) {
				$this->view->value = 1;
		}
	}
	public function newAction()
	{
		$this->view->urlHome = Zend_Registry::get('foobarconfig')->url->web;
		$this->view->pageTitle = Zend_Registry::get('foobarconfig')->index->title;
		
		$count = Model_ReleaseVehicle::getCount();
		$this->view->count = $count;
		
		$env = Model_Env::getData();
		$this->view->env = $env;
		
		$type = Model_Type::getData();
		$this->view->type = $type;
		
		$component = Model_Component::getData();
		$this->view->component = $component;

                // GLU changes build dir, we need to change accordingly
                $this_release = $_REQUEST['this_release'];
		

                if ( $this_release ) {
                        $this->view->action = "new";
        //              $build_dir_path =  Zend_Registry::get('foobarconfig')->build . "/R" . "123";
                        $build_dir_path =  Zend_Registry::get('foobarconfig')->build . "/R" . $this_release;
                        // get dir handle

                        if ( ! file_exists( $build_dir_path ) ) {
                                die("Rlease $this_release is not valid.") ;
                        }
                        $build_dir_handle = opendir($build_dir_path) or die("Cannot open $build_dir_path");

                        while ( $file = readdir($build_dir_handle) )
                        {
                          if ( stristr( $file, "build-") == TRUE )
                          {
                            $builds[] = $file;
                          }
                        }

	/*		
			// webapps need special treatmenet
			$build_dir_path_webapps = "$build_dir_path/deploy";
			$build_dir_path_webapps_handle = opendir($build_dir_path_webapps) or die("Cannot open $build_dir_path_webapps");

			while ( $file = readdir($build_dir_path_webapps_handle) )
			{
			  if ( stristr( $file, '-build-') === FALSE )
			  {
			    $builds_webapps[] = $file;
			  }
			}

			// merge into $builds
			$builds = array_merge( $builds, $builds_webapps );
	*/

			arsort($builds);
			$this->view->builds = $builds;
		}
	}
	public function ajaxAction()
	{
		$this->view->urlHome = Zend_Registry::get('foobarconfig')->url->web;
		$this->_helper->viewRenderer->setNoRender();
		$this_release = $_REQUEST['this_release'];
		$build_dir = $_REQUEST['build'];
                if ( $this_release && $build_dir)       {
//                      $build_dir_path =  Zend_Registry::get('foobarconfig')->build."/".$build_dir;
                        $build_dir_path =  Zend_Registry::get('foobarconfig')->build."/R". $this_release . "/" . $build_dir;
//echo "<option> $build_dir_path </option> ";

			// get dir handle
			$build_dir_handle = opendir($build_dir_path) or die("Cannot open $build_dir_path");

			while ( $file = readdir($build_dir_handle) )
			{
				  if ( ! ( $file == "." ||  $file == ".." )  )
				  {
						$builds[] = ereg_replace("-war", "", $file);
				  }
			}

                        // webapps need special treatment
                        $build_dir_path_webapps = "$build_dir_path/deploy";
                        if ( file_exists( $build_dir_path_webapps) ) {
                                $build_dir_path_webapps_handle = opendir($build_dir_path_webapps) or die("Cannot open $build_dir_path_webapps");

                                while ( $file = readdir($build_dir_path_webapps_handle) )
                                {
                                        if ( ( ! ( $file == "." ||  $file == ".." ) ) && stristr( $file, '-build-') === FALSE )
                                        {
                                                $builds_webapps[] = $file;
                                        }
                                }

                                // merge into $builds
                                $builds = array_merge( $builds, $builds_webapps );
                        }

			asort( $builds );
			$uniq = array_unique( $builds) ;
			foreach ($uniq as $build)
			{
			  	echo "<option> $build </option>";
			}
		}else{
			echo "<option>Please select valid build no.</option>";
		}
	}

        public function ajax2Action()
        {
                $this->view->urlHome = Zend_Registry::get('foobarconfig')->url->web;
                $this->_helper->viewRenderer->setNoRender();
                $release_dir = $_REQUEST['this_release'];
                if ($release_dir) {
                        $build_dir_path =  Zend_Registry::get('foobarconfig')->build."/R".$release_dir;

                        // get dir handle
                        if ( ! file_exists( $build_dir_path ) ) {
                                die("Release number $release_dir is not valid.");

                        }
                        $build_dir_handle = opendir($build_dir_path) or die("Cannot open $build_dir_path");

                        while ( $file = readdir($build_dir_handle) )
                        {
                                  if ( ( ! ( $file == "." ||  $file == ".." ) )  && ! ( strpos( $file, 'build-') === false  ) )
                                  {
                                                $builds[] = $file;
                                  }
                        }

/*
                        // webapps need special treatment
                        $build_dir_path_webapps = "$build_dir_path/deploy";
                        $build_dir_path_webapps_handle = opendir($build_dir_path_webapps) or die("Cannot open $build_dir_path_webapps");

                        while ( $file = readdir($build_dir_path_webapps_handle) )
                        {
                                if ( ( ! ( $file == "." ||  $file == ".." ) ) && stristr( $file, '-build-') === FALSE )
                                {
                                        $builds_webapps[] = $file;
                                }
                        }

                        // merge into $builds
                        $builds = array_merge( $builds, $builds_webapps );
*/

                        asort( $builds );
                        $uniq = array_unique( $builds) ;
                        foreach ($uniq as $build)
                        {
                                echo "<option value='$build'> $build </option>";
                        }
                }else{
                        echo "<option>Please type a valid release no. first.</option>";
                }
        }

	public function ajax3Action() 
	{
                $this->view->urlHome = Zend_Registry::get('foobarconfig')->url->web;
                $this->_helper->viewRenderer->setNoRender();
                $this_release = $_REQUEST['this_release'];

		if ($this_release ) {

//			$master_bom_file = Zend_Registry::get('foobarconfig')->build."/R". $this_release . "/" . "LEGACY-MASTER.BOM";
			$master_bom_file = Zend_Registry::get('foobarconfig')->build."/R". $this_release . "/" . "RELEASE.BOM";

			$apps = array();
			$app_to_build_mapping = array();


			//  parse bom file to get app_to_build_mapping

			$fh = fopen($master_bom_file, "r") or die("cannot open file: $master_bom_file");
			while( !feof($fh) ) 
			{
			//  echo fgets($fh) ;
			  $line = fgets($fh);

//			  echo $line;

			  if ( ! preg_match("/^#/", $line)  )
			  {
			    preg_match("/(.*)=(.*)/", $line, $matches);
			//    echo $matches[1] . " : " . $matches[2] . "\n";
			    $app = $matches[1];
			    $build = $matches[2];
			    $app_to_build_mapping[$app] = $build;
			    if ( $app ) {
			      array_push($apps, $app) ;
			    }
			  }

			}

			fclose($fh);
			

			asort($apps);
			$uniq = array_unique( $apps );
			foreach ($uniq as $app )
			{
				echo "<option value='$app'> $app = $app_to_build_mapping[$app]  </option>";
			}
		}
		else {
			echo "<option>Please provide a valid release no.</option>";
		}

	}

	public function createAction($action)
	{
		$this->_helper->viewRenderer->setNoRender();
		$request = $this->getRequest();
		$release_vehicle_id = $request->getPost('release_vehicle_id');
		if ($request->getPost('form_submitted') == 1 && $release_vehicle_id) {
			$env = $request->getPost('env');
			$build_no = $request->getPost('build_no');
			// for GLU, we are not capturing build_no...
			// let's use a placeholder: GLU
			$build_no = 'GLU';
			$username = Zend_Registry::get( 'foobarSession' )->user ;
			$date = date('Y-m-d H:i:s');
			$inputArray = array(
					'env' => $env,
					'release_vehicle_id' => $release_vehicle_id,
					'build_no' => $build_no,
					'username' => $username,
					'created' => $date
				);
				
			//insert into release_vehicle
			$result = Model_ReleaseVehicle::insertReleaseVehicle( $inputArray );
			
			// insert into db_patches
			$array = explode(",", $request->getPost('db_patches'));
			foreach ($array as $patch) {
				$dbArray = array(
					'release_vehicle_id' => $request->getPost('release_vehicle_id'),
					'db_patch' => trim($patch)
				);
				$dbPatches = Model_DbPatches::insertDbPatches( $dbArray );
			}
			

			//delete existing component_list
			$delete1 = Model_ComponentList::deleteComponentList($release_vehicle_id);
			// insert into component_list
			for( $i = 0; $i < count($_POST['component_name']); $i++ ) {
				$compArray = array(
					'release_vehicle_id' => $request->getPost('release_vehicle_id'),
					'component_name' => $_POST['component_name'][$i]
				);

				$componentList = Model_ComponentList::insertComponentList( $compArray );
			}
		}
		if($action) {
			$edit_from = $request->getPost('edit_from');
			$redirectUrl =  Zend_Registry::get('foobarconfig')->url->web . "/index/copyrollout?id=" . $release_vehicle_id . "&edit_from=" . $edit_from ;
		} else {
			$redirectUrl =  Zend_Registry::get('foobarconfig')->url->web . "/index/rollout?id=" . $release_vehicle_id;
		}
		$this->_redirect($redirectUrl);
	}
	public function rolloutAction()
	{
		$this->view->urlHome = Zend_Registry::get('foobarconfig')->url->web;
		$this->view->pageTitle = Zend_Registry::get('foobarconfig')->index->title;
		$this->view->id = $_REQUEST['id'];
		$components = Model_ComponentList::getData($_REQUEST['id']);
		$this->view->components = $components;
		
		$dbpatches = Model_DbPatches::getData($_REQUEST['id']);
		$this->view->dbpatches = $dbpatches;
		
		$user = Model_User::getData();
		$this->view->user = $user;
		
		$task = Model_Task::getData();
		$this->view->task = $task;
	}
	
	public function editrolloutAction($from)
	{
		$this->view->urlHome = Zend_Registry::get('foobarconfig')->url->web;
		$this->view->pageTitle = Zend_Registry::get('foobarconfig')->index->title;
		
		$releaseVehicle = Model_ReleaseVehicle::getData($_REQUEST['edit_from']);

//TODO
		// lwang: per Noy, let an admin be able to edit rollout  even after started executing
		$yes_admin = 0;
                $admins = Model_Admin::getData();
                $username = Zend_Registry::get( 'foobarSession' )->user ;

                $adminArray = array();
                $this->view->value = 0;

                foreach ($admins as $admin)  {
                        array_push($adminArray,$admin->user_name);
                }
                if (in_array($username,$adminArray)) {
                                $yes_admin= 1;
                }
	

		if ($from == "copy" || $yes_admin  || $releaseVehicle->executed != 2) {
			$plan = Model_Plan::getData($_REQUEST['edit_from']);
			$this->view->plan = $plan;
			
			$components = Model_ComponentList::getData($_REQUEST['id']);
			$this->view->components = $components;
			
			$dbpatches = Model_DbPatches::getData($_REQUEST['id']);
			$this->view->dbpatches = $dbpatches;
			
			$this->view->id = $_REQUEST['id'];
			
			$user = Model_User::getData();
			$this->view->user = $user;
			
			$task = Model_Task::getData();
			$this->view->task = $task;
		}else {
			$this->view->message = "You have started executing this plan already. You can't edit it anymore";
		}
	}
	public function copyrolloutAction()
	{
		$this->editrolloutAction("copy");
	}
	public function autocompleteAction()
	{
		$this->view->urlHome = Zend_Registry::get('foobarconfig')->url->web;
		$this->_helper->viewRenderer->setNoRender();
		$keyword = $_REQUEST['q'];
		if ($keyword)	{
			$idList = Model_ReleaseVehicle::getIdList($keyword);
			$listhtml = "";
			if (count($idList)) {
				foreach ($idList as $id)  {
					$listhtml .= $id->release_vehicle_id . "\n";
				}
			} else {
			   $listhtml .= "";
			}
			echo $listhtml;
		}
	}
	public function planAction()
	{
		$this->_helper->viewRenderer->setNoRender();
		$request = $this->getRequest();
		if ($request->getPost('form_submitted') == 1) {
			// delete existing plan
			$release_vehicle_id = $request->getPost('release_vehicle_id');
			$delete = Model_Plan::deletePlanList($release_vehicle_id);
			
			for( $i = 0; $i < count($_POST['step']) ; $i++ ) {
				   $components = $_POST['components'][$i] == "Select options" ? "" : $_POST['components'][$i];
				   $status = $_POST['status'][$i]  ?  $_POST['status'][$i] : 0;
					$sqlArray = array(
						'release_vehicle_id' => $release_vehicle_id,
						'step' => $_POST['step'][$i],
						'sub_step' => $_POST['sub_step'][$i],
						'task' => $_POST['task'][$i],
						'owner' => $_POST['owner'][$i],
						'components' => $components,
						'no_start' => $_POST['no_start'][$i],
						'notes' => $_POST['notes'][$i],
						'status' => $status,
					);
					$sql = Model_Plan::insertPlanList($sqlArray);
				}
			//$date = date('Y-m-d H:i:s');
		}
		$redirectUrl =  Zend_Registry::get('foobarconfig')->url->web . "/index/execute?id=" . $release_vehicle_id;
		$this->_redirect($redirectUrl);
	}
	public function executeAction()
	{
		$this->view->urlHome = Zend_Registry::get('foobarconfig')->url->web;
		$this->view->pageTitle = Zend_Registry::get('foobarconfig')->index->title;
		$plan = Model_Plan::getDataInArray($_REQUEST['id']);
		$this->view->plan = $plan;
		$this->view->id = $_REQUEST['id'];
		$username = Zend_Registry::get( 'foobarSession' )->user ;
		$this->view->username = $username;
		
		$release_head = Model_ReleaseVehicle::getData( $_REQUEST['id']);
		$this->view->head = $release_head->username;

		// get admin
                $is_admin = 0;
                $admins = Model_Admin::getData();

                $adminArray = array();

                foreach ($admins as $admin)  {
                        array_push($adminArray,$admin->user_name);
                }
                if (in_array($username,$adminArray)) {
                                $is_admin= 1;
                }
		$this->view->is_admin = $is_admin;

		$user = Model_User::getData();
                $this->view->user = $user;

	}
	 public function editpageAction()
    {
        $this->view->urlHome = Zend_Registry::get('foobarconfig')->url->web;
        $this->view->pageTitle = Zend_Registry::get('foobarconfig')->index->title;
        if ($_REQUEST['id']){
            $releaseVehicle = Model_ReleaseVehicle::getData($_REQUEST['id']);
            $this->view->releaseVehicle = $releaseVehicle;
            $dbpatches = Model_DbPatches::getData($_REQUEST['id']);
            $arr = array();
            foreach ($dbpatches as $dbpatch)  {
            	array_push($arr,$dbpatch->db_patch);
            }
            $this->view->dbpatch = implode(',',$arr);
   
			$env = Model_Env::getData();
			$this->view->env = $env;
			
			$type = Model_Type::getData();
			$this->view->type = $type;
			
			$component = Model_Component::getData();
			asort($component);
			$this->view->component = $component;
			
			
			$selectedComponents = Model_ComponentList::getData($_REQUEST['id']);
			asort($selectedComponents);
			$this->view->selectedComponents = $selectedComponents;
			
			$count = Model_ReleaseVehicle::getCount();
			$this->view->count = $count;
			
                        // get release number, e.g.,123, as $match[0][1]
                        preg_match_all("/^R(\d+)-.*/", $releaseVehicle->release_vehicle_id, $match, PREG_SET_ORDER);
                        $this->view->release = $match[0][1];

//                      $build_dir_path =  Zend_Registry::get('foobarconfig')->build;
                        $build_dir_path =  Zend_Registry::get('foobarconfig')->build . "/R" . $match[0][1];

			// get dir handle
			$build_dir_handle = opendir($build_dir_path) or die("Cannot open $build_dir_path");
			
			while ( $file = readdir($build_dir_handle) )
			{
			  if ( stristr( $file, "build-") == TRUE )
			  {
			    $builds[] = $file;
			  }
			}
			arsort($builds);
			$this->view->builds = array_unique($builds);
		 }

    }
    public function copypageAction()
    {
        $this->editpageAction();
    }
    public function copysaveAction()
    {
        $this->createAction("copy");
    }
    public function editsaveAction()
	{
		$this->_helper->viewRenderer->setNoRender();
		$request = $this->getRequest();
		if ($request->getPost('form_submitted') == 1) {
			$env = $request->getPost('env');
			$release_vehicle_id = $request->getPost('release_vehicle_id');
			$build_no = $request->getPost('build_no');
			$username = Zend_Registry::get( 'foobarSession' )->user ;
			//$date = date('Y-m-d H:i:s');
			$inputArray = array(
					'env' => $env,
					'release_vehicle_id' => $release_vehicle_id,
					'build_no' => $build_no,
					'username' => $username
				);
				
			//insert into release_vehicle
			$result = Model_ReleaseVehicle::editReleaseVehicle($inputArray);
			
			//delete existing db_patches
			$delete = Model_DbPatches::deleteDbPatches($release_vehicle_id);
			// insert into db_patches
			$array = explode(",", $request->getPost('db_patches'));
			foreach ($array as $patch) {
				$dbArray = array(
					'release_vehicle_id' => $request->getPost('release_vehicle_id'),
					'db_patch' => trim($patch)
				);
				$dbPatches = Model_DbPatches::insertDbPatches( $dbArray );
			}
			//delete existing component_list
			$delete1 = Model_ComponentList::deleteComponentList($release_vehicle_id);
			// insert into component_list
			for( $i = 0; $i < count($_POST['component_name']); $i++ ) {
asort($_POST['component_name'][$i]);
				$compArray = array(
					'release_vehicle_id' => $request->getPost('release_vehicle_id'),
					'component_name' => $_POST['component_name'][$i]
				);

				$componentList = Model_ComponentList::insertComponentList( $compArray );
			} 
		}
		$redirectUrl =  Zend_Registry::get('foobarconfig')->url->web . "/index/editrollout?id=" . $release_vehicle_id . "&edit_from=" . $release_vehicle_id ;
		$this->_redirect($redirectUrl);
	}
	/*
    public function deletepageAction()
	{
		$this->view->urlHome = Zend_Registry::get('foobarconfig')->url->web;
		$this->_helper->viewRenderer->setNoRender();
		$release_vehicle_id = $_REQUEST['id'];
		if ($release_vehicle_id)	{
			$result = Model_ReleaseVehicle::deleteReleaseVehicle($release_vehicle_id);
			//delete from plan & db_patches & components
		}
	} */
	public function mainAction()
	{
		$request = $this->getRequest();
		$this->view->urlHome = Zend_Registry::get('foobarconfig')->url->web;
		if ($request->getPost('form_submitted') == 1) {
			$components = explode(',',$request->getPost('components'));
			$task = $request->getPost('task');
			$id = $request->getPost('id');
			$array = array();
			foreach ($components as $component) { 
				$check = Model_Deploy::getData($id,$component,$task);
				$array{$component} = $check->status;
			}
			
			$this->view->components = $array;
			$this->view->id = $id;
			$this->view->owner = $request->getPost('owner');
			$this->view->task = $task;
		}
	}
	public function sshAction()
	{
		$request = $this->getRequest();
		$this->view->urlHome = Zend_Registry::get('foobarconfig')->url->web;
		if ($request->getPost('form_submitted') == 1) {
			$task = $request->getPost('task');
			$component = $request->getPost('component');
			$machine = $request->getPost('machine');
			$id = $request->getPost('release_vehicle_id');
			$owner = Zend_Registry::get( 'foobarSession' )->user ;
			$inputArray = array(
					'task' => $task,
					'component' => $component,
					'owner' => $owner,
					'machine' => $machine,
					'status' => 1,
					'release_vehicle_id' => $id
				);
			$result = Model_Deploy::insertValues($inputArray);
			
	
			// set the executed status in release vehicle 
			$release_vehicle_id = $id;
			$data = array(
					'release_vehicle_id' => $release_vehicle_id,
					'executed' => 2
				);
			$result = Model_ReleaseVehicle::updateStatus($data);
			$this->view->machine = $machine;
			$this->view->task = $task;
			$this->view->urlHttps = Zend_Registry::get('foobarconfig')->url->https;
		}
	}
	/*public function otherAction()
	{
		$this->_helper->viewRenderer->setNoRender();
		$request = $this->getRequest();
		//set the status in rollout
		$id = $request->getPost('id');
		$inputArray = array(
				'id' => $id,
				'status' => 2
			);
		$result = Model_Plan::updateStatus($inputArray);
		
		// set the executed status in release vehicle 
		$release_vehicle_id = $request->getPost('release_vehicle_id');
		$data = array(
				'release_vehicle_id' => $release_vehicle_id,
				'executed' => 2
			);
		$result = Model_ReleaseVehicle::updateStatus($data);
		$redirectUrl =  Zend_Registry::get('foobarconfig')->url->web . "/index/execute?id=" . $request->getPost('release_vehicle_id');
		$this->_redirect($redirectUrl);
	}	*/
	public function auditAction()
	{


                $this->view->urlHome = Zend_Registry::get('foobarconfig')->url->web ;
                $this->view->pageTitle = Zend_Registry::get('foobarconfig')->index->title;
                $plan = Model_Plan::getDataInArray($_REQUEST['id']);
                $this->view->plan = $plan;
                $this->view->id = $_REQUEST['id'];
		$this->view->release_vehicle_id = $_REQUEST['release_vehicle_id'];
                $this->view->components = $_REQUEST['components'];

		// check /usr/local/Deployment/application/views/helpers/ExecuteList.php
		$this->view->step = $_REQUEST['step'];
		$this->view->sub_step = $_REQUEST['sub_step'];

		// 
		//$this->view->components_lines =  preg_replace("/, /", "\n", $this->view->components);

		$items = preg_split("/-/", $this->view->release_vehicle_id);

		// release_vehicle_id is not formatted as :  R938-MR-stg-RC-10-13
		$this->view->release = $items[0];
		$this->view->env = $items[2];
		$this->view->rcnumber = $items[4];


                $username = Zend_Registry::get( 'foobarSession' )->user ;
                $this->view->username = $username;

                $release_head = Model_ReleaseVehicle::getData( $_REQUEST['id']);
                $this->view->head = $release_head->username;

	}
	public function otherAction()
        {
                $request = $this->getRequest();
                $this->view->urlHome = Zend_Registry::get('foobarconfig')->url->web;
                if ($request->getPost('form_submitted') == 1) {
                        $components = explode(',',$request->getPost('components'));
                        $task = $request->getPost('task');
                        $id = $request->getPost('id');
                        $actiondone = $request->getPost('actiondone');
                        if ($actiondone == "Start"){
                                $status = 1;
                        }elseif ($actiondone == "Complete"){
                                $status = 2;
                        }
                        $inputArray = array(
                                        'id' => $id,
                                        'status' => $status
                                );
                        $result = Model_Plan::updateStatus($inputArray);

                        // set the executed status in release vehicle
                        $release_vehicle_id = $request->getPost('release_vehicle_id');
                        $data = array(
                                        'release_vehicle_id' => $release_vehicle_id,
                                        'executed' => 2
                                );
                        $result = Model_ReleaseVehicle::updateStatus($data);
// per Noy, let's not go to a separate page... rather refresh the execute page
// 	NOTE: 	this nullifies the previous logic that "audit" should show an instruction page, see: other.phtml
//		we'll have to revisit that part of the logic if we want to treat "audit" separately
		
                                $redirectUrl =  Zend_Registry::get('foobarconfig')->url->web . "/index/execute?id=" . $release_vehicle_id;
                                $this->_redirect($redirectUrl);
/*
                        if ($actiondone == "Complete") {
                                $redirectUrl =  Zend_Registry::get('foobarconfig')->url->web . "/index/execute?id=" . $release_vehicle_id;
                                $this->_redirect($redirectUrl);

                        }else{
                                $this->view->components = $components;
                                $this->view->id = $id;
                                $this->view->owner = $request->getPost('owner');
                                $this->view->task = $task;
                                $this->view->release_vehicle_id = $release_vehicle_id;
                                $this->view->env = Model_ReleaseVehicle::getData($release_vehicle_id)->env;
                        }
*/
                }
        }

	public function demoAction() {

                $request = $this->getRequest();
                $this->view->urlHome = Zend_Registry::get('foobarconfig')->url->web;
	}

        public function manifestAction() {

                $request = $this->getRequest();
                $this->view->urlHome = Zend_Registry::get('foobarconfig')->url->web;

        }


        public function gluconsoleAction() {

                $request = $this->getRequest();
                $this->view->urlHome = Zend_Registry::get('foobarconfig')->url->web;

        }

	public function metricsAction() {

                $request = $this->getRequest();
                $this->view->urlHome = Zend_Registry::get('foobarconfig')->url->web;

		$idList = Model_ReleaseVehicle::getIdList('R');
		$this->view->idList = $idList;

/*------------------ ok, shut it down for now
//		$components = Model_ComponentList::getData($_REQUEST['id']);
		$componentMetricsMap = array();  # hash : release_vehicle_id => count 
  		foreach ( $idList as $id ) {
			$i = $id->release_vehicle_id ;  # $i is the real release vehicle id
			$count = Model_ComponentList::getCount( $i );
			$componentMetricsMap[$i] = $count;

		}	

		$this->view->componentMetricsMap = $componentMetricsMap;
-----------------------*/

	}


	public function workflowAction() {

                $request = $this->getRequest();
                $this->view->urlHome = Zend_Registry::get('foobarconfig')->url->web;
//TODO

                $this->view->pageTitle = Zend_Registry::get('foobarconfig')->index->title;

                $allWorkflow = Model_Workflow::getAllData();
                $this->view->allWorkflow = $allWorkflow;


                $admins = Model_Admin::getData();
                $username = Zend_Registry::get( 'foobarSession' )->user ;

                $adminArray = array();
                $this->view->value = 0;

                foreach ($admins as $admin)  {
                        array_push($adminArray,$admin->user_name);
                }
                if (in_array($username,$adminArray)) {
                                $this->view->value = 1;
                }

	}

	public function newworkflowAction() {

//                $request = $this->getRequest();
                $this->view->urlHome = Zend_Registry::get('foobarconfig')->url->web;

/*
		$releasename = $_REQUEST['txt_Release'];
		$this->view->releasename = $releasename;

		$stenamep = $_REQUEST['sel_Step'];
		$this->view->stepname = $stepname;
*/

//TODO
/*
                if($action) {
                        $edit_from = $request->getPost('edit_from');
                        $redirectUrl =  Zend_Registry::get('foobarconfig')->url->web . "/index/copyrollout?id=" . $release_vehicle_id . "&edit_from=" . $edit_from ;
                } else {
                        $redirectUrl =  Zend_Registry::get('foobarconfig')->url->web . "/index/rollout?id=" . $release_vehicle_id;
                }

		$redirectUrl =  Zend_Registry::get('foobarconfig')->url->web . "/index/newworkflow";
                $this->_redirect($redirectUrl);
*/


	}

	public function createworkflowAction() {


//                $this->_helper->viewRenderer->setNoRender();
                $request = $this->getRequest();
                $txt_release = $request->getPost('txt_Release');
                $txt_status = $request->getPost('txt_Status');
                if ($request->getPost('form_workflow_submitted') == 1 && $txt_release) {
                        $sel_step = $request->getPost('sel_Step');
                        $notes = $request->getPost('txtarea_Notes');
                        $username = Zend_Registry::get( 'foobarSession' )->user ;
                        $date = date('Y-m-d H:i:s');
                        $inputArray = array(
                                        'releasename' => $txt_release,
                                        'stepname' => $sel_step,
                                        'notes' => $notes,
                                        'status' => $txt_status,
                                        'created' => $date,
                                        'username' => $username
                                );


			$query = Model_Workflow::getDataInArray($txt_release, $sel_step);
			
			if ( count($query)  != 0 ) 
			{
			  Model_Workflow::updateWorkflow( $inputArray );
			}
			else {
			   Model_Workflow::insertWorkflow( $inputArray );

			}

#                        $result = Model_Workflow::insertWorkflow( $inputArray );
#                        $result = Model_Workflow::updateWorkflow( $inputArray );

                }

		$redirectUrl =  Zend_Registry::get('foobarconfig')->url->web . "/index/newworkflow";
                $this->_redirect($redirectUrl);

	}

	public function cfg2Action() {

		$request = $this->getRequest();
                $this->view->urlHome = Zend_Registry::get('foobarconfig')->url->web;

	}

}
