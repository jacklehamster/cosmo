<?php
   header("Content-Type:text/plain");
   define("MEMDIR", "memoku");
   $action = $_REQUEST['action'];

   switch($action) {
      case "destroy":
          $room = $_REQUEST['room'];
          if($room) {
             $channel = md5($room);
             $channeldir = MEMDIR."/$channel";
             destroy($channeldir,true);
          }
          break;
      case "enter":
         $room = $_REQUEST['room'];
         $channel = md5($room);
         $channeldir = MEMDIR."/$channel";
         if(!file_exists($channeldir) || !file_exists("$channeldir/data.json")) {
                if(!file_exists(MEMDIR)) {
                    mkdir(MEMDIR);
                }
                if(!file_exists($channeldir)) {
                    mkdir($channeldir);
                }
                if(!file_exists("$channeldir/1.json"))
                    file_put_contents("$channeldir/1.json","");
                if(!file_exists("$channeldir/data.json"))
                    file_put_contents("$channeldir/data.json","1,{\"room\":\"$room\"}");
         }
         echo $_SERVER["HTTP_HOST"]."/$channeldir";
         break;
      case "get":
         $channel = $_REQUEST['channel'];
         $count = $_REQUEST['count'];
         $channeldir = MEMDIR."/$channel";

         $next = max(2,$count+1);
         $now = time();
         while(!file_exists("$channeldir/$next.json")) {
            usleep(50);
            if(time()-$now>10) {
                echo "";
                exit();
            }
         }
         echo file_get_contents("$channeldir/$count.json",stripslashes($data));
         break;
      case "post":
         $channel = $_REQUEST['channel'];
         if($channel && ctype_alnum($channel)) {
             $data = $_REQUEST['data'];
             $count = $_REQUEST['count'];
             $channeldir = MEMDIR."/$channel";
             $filename = "$channeldir/data.json";
             if($data) {
                if(!file_exists("$channeldir/$count.json")) {
                  $fp = fopen($filename,"c+");
                  $size = filesize($filename);
                  $consolidate = flock($fp, LOCK_EX | LOCK_NB);
                  $str = $size ? fread($fp, filesize($filename)) : "";
                  if($str=="") {
                     $str = "1,{}";
                  }
                  $countstart =  substr($str,0,strpos($str,","));
                  $count = $countstart;
                }

                $next = max(2,$count+1);
                while(file_exists("$channeldir/$next.json")) {
                   $next++;
                }
                $count = $next-1;
                if($_REQUEST["timestamp"]) {
                   $array = explode("%TIMESTAMP%",$data);
                   $now = number_format(microtime(true)*1000,0,'.','');
                   $data = implode("$now",$array);
                }
                file_put_contents("$channeldir/$count.json",stripslashes($data));
                file_put_contents("$channeldir/$next.json","");
                echo $count;
             }
             
             if(!$fp) {
                 $fp = fopen($filename,"c+");
                 $consolidate = flock($fp, LOCK_EX | LOCK_NB);
             }

             if($consolidate) {
                if(!$str) {
                    $size = filesize($filename);
                    $str = $size ? fread($fp, filesize($filename)) : "";
                    if($str=="") {
                        $str = "1,{}";
                    }
                    $countstart =  substr($str,0,strpos($str,","));
                }
                ob_start();
                echo "[$str";
                for($i = $countstart; file_exists("$channeldir/$i.json"); $i++) {
                    $content = file_get_contents("$channeldir/$i.json");
                    if($content != "") {
                        echo ",$content";
                        if(!$fileage && file_exists("$channeldir/".($i-1).".json")) {
                             $fileage = time()-filemtime("$channeldir/".($i-1).".json");
                        }
                    }
                }
                echo "]";
                $topcount = $i-1;
                $str = ob_get_contents(); // get the complete string
                ob_end_clean();
                $obj = json_decode($str,true);
                $start = $obj[0];
                $len = count($obj);
                for($i = 2;$i<$len;$i++) {
                   if($obj[$i]) {
                     list($access,$value) = $obj[$i];
                     $access = explode('.',$access);
                     $leaf = &$obj[1];
                     $accesslen = count($access);
                     for($p=0;$p<$accesslen;$p++) {
                          $leafname = $access[$p];
                          if($p<$accesslen-1) {
                               if(!is_array($leaf[$leafname])) {
                                    $leaf[$leafname] = array();
                               }
                               $leaf = &$leaf[$leafname];
                          }
                     }
                     if(is_null($value)) {
                          if(isset($leaf[$leafname])) {
                               if(array_values($leaf) === $leaf)
                                    array_splice($leaf,$leafname,1);
                               else
                                    unset($leaf[$leafname]);
                          }
                     }
                     else {
                          if($leafname=="" && array_values($leaf) === $leaf)
                               $leaf[] = $value;
                          else
                               $leaf[$leafname] = $value;
                     }
                   }
                }
                $obj = $obj[1];
                $str = "$topcount,".json_encode($obj);
                fseek($fp,0);
                fwrite($fp,$str);
                fflush($fp);
                ftruncate($fp, ftell($fp));
                flock($fp, LOCK_UN);
                if($fileage>60) { //delete files older than 1 min
                    for($i = $countstart-1; $i>0 && file_exists("$channeldir/$i.json"); $i--) {
                        if(file_exists("$channeldir/$i.json"))
                           unlink("$channeldir/$i.json");
                    }
                }
            }
            fclose($fp);

         }
         break;
         default:
            echo "Cosmo - Real time communication in space";
   }
   

   function timeslot() {
       $now = microtime(true);
       return (int)($now*10) % 1000;
   }

   function destroy($folder,$destroyself) {
       if(!file_exists($folder)) {
           return;
       }
       foreach(scandir($folder) as $file) {
          if (is_dir("$folder/$file")) {
             if($file!='..' && $file!='.')
                destroy("$folder/$file",true);
          }
          else {
             unlink("$folder/$file");
          }
       }
       if($destroyself)
          rmdir ($folder);
   }
   exit();
?>