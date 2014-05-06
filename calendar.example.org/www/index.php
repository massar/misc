<?php
/* From: https://github.com/massar/misc/calendar.example.org/ */

/* Let the server live in UTC, gives the least issues with DST changes etc */
date_default_timezone_set('UTC');

/* Database */
$pdo = new \PDO('sqlite:/www/calendar.example.org/data/calendars.sqlite');
$pdo->setAttribute(PDO::ATTR_ERRMODE,PDO::ERRMODE_EXCEPTION);

//Mapping PHP errors to exceptions
function exception_error_handler($errno, $errstr, $errfile, $errline ) {
    throw new \ErrorException($errstr, 0, $errno, $errfile, $errline);
}
set_error_handler("exception_error_handler");

// Autoloader
function __autoload($class_name) {
	$m = array(
		"VObject"	=> "sabre-vobject",
		"HTTP"		=> "sabre-http",
		"Event"		=> "sabre-event",
	);

	$c = str_replace("\\", "/", $class_name);
	$p = explode("/",$c);

	$d = "sabre-dav";

	if ($p[0] == "Sabre" && isset($m[$p[1]])) $d = $m[$p[1]];

	// error_log("AUTO: ".$class_name." - ".$c." - ".$p[1]." - ".$d);

	$c = $d."/lib/".$c;

	require_once("../inc/".$c.".php");
}

// Backends
$authBackend      = new \Sabre\DAV\Auth\Backend\PDO($pdo);
$calendarBackend  = new \Sabre\CalDAV\Backend\PDO($pdo);
$carddavBackend   = new \Sabre\CardDAV\Backend\PDO($pdo);
$principalBackend = new \Sabre\DAVACL\PrincipalBackend\PDO($pdo);

// Directory structure 
$tree = array(
    new \Sabre\CalDAV\Principal\Collection($principalBackend),
    new \Sabre\CalDAV\CalendarRootNode($principalBackend, $calendarBackend),
    new \Sabre\CardDAV\AddressBookRoot($principalBackend, $carddavBackend),
);

/* Disable version output */
\Sabre\DAV\Server::$exposeVersion = false;

$server = new \Sabre\DAV\Server($tree);

$server->setBaseUri('/');

/* Server Plugins */
$server->addPlugin(new \Sabre\DAV\Auth\Plugin($authBackend,'calendar'));
$server->addPlugin(new \Sabre\DAVACL\Plugin());
$server->addPlugin(new \Sabre\CalDAV\Plugin());
$server->addPlugin(new \Sabre\CardDAV\Plugin());
$server->addPlugin(new \Sabre\DAV\Browser\Plugin());

// And off we go!
$server->exec();
?>
